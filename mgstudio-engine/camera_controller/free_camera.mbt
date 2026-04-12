// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
const FREE_CAMERA_RADIANS_PER_DOT : Float = 0.005555555555555556F

///|
pub struct FreeCamera {
  sensitivity : Float
  key_forward : @window.KeyCode
  key_back : @window.KeyCode
  key_left : @window.KeyCode
  key_right : @window.KeyCode
  key_up : @window.KeyCode
  key_down : @window.KeyCode
  key_run : @window.KeyCode
  mouse_key_cursor_grab : @window.MouseButton
  keyboard_key_toggle_cursor_grab : @window.KeyCode
  walk_speed : Float
  run_speed : Float
  scroll_factor : Float
  friction : Float
} derive(ToJson, FromJson)

///|
pub fn FreeCamera::default() -> FreeCamera {
  FreeCamera::{
    sensitivity: 0.2F,
    key_forward: @window.KeyCode::KeyW,
    key_back: @window.KeyCode::KeyS,
    key_left: @window.KeyCode::KeyA,
    key_right: @window.KeyCode::KeyD,
    key_up: @window.KeyCode::KeyE,
    key_down: @window.KeyCode::KeyQ,
    key_run: @window.KeyCode::ShiftLeft,
    mouse_key_cursor_grab: @window.MouseButton::Left,
    keyboard_key_toggle_cursor_grab: @window.KeyCode::KeyM,
    walk_speed: 5.0F,
    run_speed: 15.0F,
    scroll_factor: 0.5F,
    friction: 40.0F,
  }
}

///|
pub struct FreeCameraState {
  enabled : Bool
  initialized : Bool
  pitch : Float
  yaw : Float
  speed_multiplier : Float
  velocity : @math.Vec3
} derive(ToJson, FromJson)

///|
pub fn FreeCameraState::default() -> FreeCameraState {
  FreeCameraState::{
    enabled: true,
    initialized: false,
    pitch: 0.0F,
    yaw: 0.0F,
    speed_multiplier: 1.0F,
    velocity: @math.Vec3::zero(),
  }
}

///|
pub let ecs_key_free_camera : @ecs.ComponentKey[FreeCamera] = @ecs.register_component(
  debug_name="camera_controller.free_camera",
)

///|
pub let ecs_key_free_camera_state : @ecs.ComponentKey[FreeCameraState] = @ecs.register_component(
  debug_name="camera_controller.free_camera_state",
)

///|
pub impl @ecs.Component for FreeCamera with component() {
  ecs_key_free_camera
}

///|
pub impl @ecs.Component for FreeCameraState with component() {
  ecs_key_free_camera_state
}

///|
priv struct FreeCameraSystemState {
  toggle_cursor_grab : Bool
  mouse_cursor_grab : Bool
  last_mouse_position : @math.Vec2?
}

///|
let free_camera_system_state : Ref[FreeCameraSystemState] = Ref::new(FreeCameraSystemState::{
  toggle_cursor_grab: false,
  mouse_cursor_grab: false,
  last_mouse_position: None,
})

///|
fn free_camera_angles_from_transform(
  transform : @transform.Transform,
) -> (Float, Float) {
  let forward = @pbr_render.render3d_transform_forward(transform)
  let horizontal = @math.sqrt(forward.x * forward.x + forward.z * forward.z)
  let pitch = @math.atan2(forward.y, horizontal)
  let yaw = @math.atan2(-forward.x, -forward.z)
  (yaw, pitch)
}

///|
fn free_camera_clamp_pitch(pitch : Float) -> Float {
  let half_pi = @math.pi_half()
  if pitch < -half_pi {
    -half_pi
  } else if pitch > half_pi {
    half_pi
  } else {
    pitch
  }
}

///|
fn free_camera_exp_decay(rate : Float, delta_seconds : Float) -> Float {
  if rate <= 0.0F || delta_seconds <= 0.0F {
    return 1.0F
  }
  @math.pow(2.718281828459045F, -rate * delta_seconds)
}

///|
pub fn run_freecamera_controller(world : @ecs.World) -> Unit {
  let delta_seconds = @pbr_render.render3d_default_time_or_default(world).delta_seconds()
  let mut system_state = free_camera_system_state.val
  let controlled_entities : Array[@core.Entity] = []
  world.for_each_component(ecs_key_free_camera, fn(entity, _config) {
    if (try! world.get_by_key(entity, @sprite.ecs_key_camera)) is None ||
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) is None {
      return
    }
    controlled_entities.push(entity)
  })
  if controlled_entities.length() != 1 {
    return
  }
  let controlled_entity = controlled_entities[0]
  guard (try! world.get_by_key(controlled_entity, ecs_key_free_camera))
    is Some(config) else {
    return
  }
  guard (try! world.get_by_key(controlled_entity, @transform.ecs_key_transform))
    is Some(initial_transform) else {
    return
  }
  let mut transform = initial_transform
  let mut state = match
    (try! world.get_by_key(controlled_entity, ecs_key_free_camera_state)) {
    Some(existing) => existing
    None => {
      let default_state = FreeCameraState::default()
      try! world.set_by_key(
        controlled_entity, ecs_key_free_camera_state, default_state,
      )
      default_state
    }
  }
  if !state.initialized {
    let (yaw, pitch) = free_camera_angles_from_transform(transform)
    state = FreeCameraState::{ ..state, initialized: true, pitch, yaw }
  }
  if !state.enabled {
    if system_state.toggle_cursor_grab || system_state.mouse_cursor_grab {
      system_state = FreeCameraSystemState::{
        toggle_cursor_grab: false,
        mouse_cursor_grab: false,
        last_mouse_position: None,
      }
      @window.window_set_cursor_grab_mode(mode=@window.CursorGrabMode::GrabNone)
      @window.window_set_cursor_visible(visible=true)
    }
    free_camera_system_state.val = system_state
    try! (world.replace(controlled_entity, ecs_key_free_camera_state, state)
    |> ignore)
    return
  }
  let wheel = @input.mouse_wheel_delta()
  let mut speed_multiplier = state.speed_multiplier +
    wheel.y * config.scroll_factor
  if speed_multiplier < 0.0F {
    speed_multiplier = 0.0F
  }
  state = FreeCameraState::{ ..state, speed_multiplier, }
  let mut axis_input = @math.Vec3::zero()
  if @input.key_pressed(config.key_forward) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  }
  if @input.key_pressed(config.key_back) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 0.0F, -1.0F))
  }
  if @input.key_pressed(config.key_right) {
    axis_input = axis_input.add(@math.Vec3::new(1.0F, 0.0F, 0.0F))
  }
  if @input.key_pressed(config.key_left) {
    axis_input = axis_input.add(@math.Vec3::new(-1.0F, 0.0F, 0.0F))
  }
  if @input.key_pressed(config.key_up) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if @input.key_pressed(config.key_down) {
    axis_input = axis_input.add(@math.Vec3::new(0.0F, -1.0F, 0.0F))
  }
  let mut cursor_grab_change = false
  if @input.key_just_pressed(config.keyboard_key_toggle_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      toggle_cursor_grab: !system_state.toggle_cursor_grab,
    }
    cursor_grab_change = true
  }
  if @input.mouse_button_just_pressed(config.mouse_key_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      mouse_cursor_grab: true,
    }
    cursor_grab_change = true
  }
  if @input.mouse_button_just_released(config.mouse_key_cursor_grab) {
    system_state = FreeCameraSystemState::{
      ..system_state,
      mouse_cursor_grab: false,
    }
    cursor_grab_change = true
  }
  let cursor_grab = system_state.toggle_cursor_grab ||
    system_state.mouse_cursor_grab
  let mut velocity = state.velocity
  if axis_input.length_squared() > 0.0F {
    let base_speed = if @input.key_pressed(config.key_run) {
      config.run_speed
    } else {
      config.walk_speed
    }
    velocity = axis_input
      .normalize_or_zero()
      .mul_scalar(base_speed * state.speed_multiplier)
  } else {
    let friction = if config.friction < 0.0F { 0.0F } else { config.friction }
    let decay = free_camera_exp_decay(friction, delta_seconds)
    velocity = velocity.mul_scalar(decay)
    if velocity.length_squared() < 1.0e-6F {
      velocity = @math.Vec3::zero()
    }
  }
  state = FreeCameraState::{ ..state, velocity, }
  if velocity.length_squared() > 0.0F {
    let forward = @pbr_render.render3d_transform_forward(transform)
    let right = @pbr_render.quat_rotate_vec3(
      transform.rotation,
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
    ).normalize_or_zero()
    let movement = right
      .mul_scalar(velocity.x * delta_seconds)
      .add(
        @math.Vec3::new(0.0F, 1.0F, 0.0F).mul_scalar(velocity.y * delta_seconds),
      )
      .add(forward.mul_scalar(velocity.z * delta_seconds))
    transform = transform.with_translation(transform.translation.add(movement))
  }
  if cursor_grab_change {
    if cursor_grab {
      @window.window_set_cursor_grab_mode(
        mode=@window.CursorGrabMode::GrabLocked,
      )
      @window.window_set_cursor_visible(visible=false)
    } else {
      @window.window_set_cursor_grab_mode(mode=@window.CursorGrabMode::GrabNone)
      @window.window_set_cursor_visible(visible=true)
    }
  }
  if cursor_grab {
    match @input.mouse_position() {
      Some(mouse_position) => {
        let mouse_delta = match system_state.last_mouse_position {
          Some(last_position) => mouse_position.sub(last_position)
          None => @math.Vec2::new(0.0F, 0.0F)
        }
        system_state = FreeCameraSystemState::{
          ..system_state,
          last_mouse_position: Some(mouse_position),
        }
        if mouse_delta.x != 0.0F || mouse_delta.y != 0.0F {
          let pitch = free_camera_clamp_pitch(
            state.pitch -
            mouse_delta.y * FREE_CAMERA_RADIANS_PER_DOT * config.sensitivity,
          )
          let yaw = state.yaw -
            mouse_delta.x * FREE_CAMERA_RADIANS_PER_DOT * config.sensitivity
          let rotation = @math.Quat::from_rotation_y(yaw)
            .mul(@math.Quat::from_rotation_x(pitch))
            .normalize()
          transform = transform.with_rotation(rotation)
          state = FreeCameraState::{ ..state, pitch, yaw }
        }
      }
      None =>
        system_state = FreeCameraSystemState::{
          ..system_state,
          last_mouse_position: None,
        }
    }
  } else {
    system_state = FreeCameraSystemState::{
      ..system_state,
      last_mouse_position: None,
    }
  }
  free_camera_system_state.val = system_state
  try! (world.replace(
    controlled_entity, @transform.ecs_key_transform, transform,
  )
  |> ignore)
  try! (world.replace(controlled_entity, ecs_key_free_camera_state, state)
  |> ignore)
}

///|
pub fn free_camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_pre_update_system(run_freecamera_controller)
}

///|
pub fn run_free_camera_controller(world : @ecs.World) -> Unit {
  run_freecamera_controller(world)
}
