// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_camera_controller/src/pan_camera.rs`.

///|
const PAN_CAMERA_SCROLL_UNIT_CONVERSION_FACTOR : Float = 16.0F

///|
const PAN_CAMERA_PLUGIN_NAME : String = "mgstudio.camera_controller.PanCameraPlugin"

///|
pub struct PanCamera {
  enabled : Bool
  mut zoom_factor : Float
  min_zoom : Float
  max_zoom : Float
  zoom_speed : Float
  key_zoom_in : @window.KeyCode?
  key_zoom_out : @window.KeyCode?
  pan_speed : Float
  key_up : @window.KeyCode?
  key_down : @window.KeyCode?
  key_left : @window.KeyCode?
  key_right : @window.KeyCode?
  rotation_speed : Float
  key_rotate_ccw : @window.KeyCode?
  key_rotate_cw : @window.KeyCode?
} derive(ToJson, FromJson)

///|
pub fn PanCamera::default() -> PanCamera {
  PanCamera::{
    enabled: true,
    zoom_factor: 1.0F,
    min_zoom: 0.1F,
    max_zoom: 5.0F,
    zoom_speed: 0.1F,
    key_zoom_in: Some(@window.KeyCode::Equal),
    key_zoom_out: Some(@window.KeyCode::Minus),
    pan_speed: 500.0F,
    key_up: Some(@window.KeyCode::KeyW),
    key_down: Some(@window.KeyCode::KeyS),
    key_left: Some(@window.KeyCode::KeyA),
    key_right: Some(@window.KeyCode::KeyD),
    rotation_speed: 3.141592653589793F,
    key_rotate_ccw: Some(@window.KeyCode::KeyQ),
    key_rotate_cw: Some(@window.KeyCode::KeyE),
  }
}

///|
fn pan_camera_key_to_string(key : @window.KeyCode?) -> String {
  match key {
    Some(value) => value.to_json().to_string()
    None => "None"
  }
}

///|
pub impl Show for PanCamera with output(self, logger) {
  logger.write_string(
    "\nPanCamera Controls:\n  Move Up / Down    - \{pan_camera_key_to_string(self.key_up)} / \{pan_camera_key_to_string(self.key_down)}\n  Move Left / Right - \{pan_camera_key_to_string(self.key_left)} / \{pan_camera_key_to_string(self.key_right)}\n  Rotate CCW / CW   - \{pan_camera_key_to_string(self.key_rotate_ccw)} / \{pan_camera_key_to_string(self.key_rotate_cw)}\n  Zoom              - Mouse Scroll + \{pan_camera_key_to_string(self.key_zoom_in)} / \{pan_camera_key_to_string(self.key_zoom_out)}\n",
  )
}

///|
pub let ecs_key_pan_camera : @ecs.ComponentKey[PanCamera] = @ecs.register_component(
  debug_name="camera_controller.pan_camera",
)

///|
pub impl @ecs.Component for PanCamera with component() {
  ecs_key_pan_camera
}

///|
fn pan_camera_press_if_pressed(
  key_input : @input.ButtonInput[@window.KeyCode],
  key : @window.KeyCode?,
) -> Unit {
  if key is Some(value) && @input.key_pressed(value) {
    key_input.press(value)
  }
}

///|
fn pan_camera_key_input_snapshot(
  controller : PanCamera,
) -> @input.ButtonInput[@window.KeyCode] {
  let key_input : @input.ButtonInput[@window.KeyCode] = @input.ButtonInput::new()
  pan_camera_press_if_pressed(key_input, controller.key_zoom_in)
  pan_camera_press_if_pressed(key_input, controller.key_zoom_out)
  pan_camera_press_if_pressed(key_input, controller.key_up)
  pan_camera_press_if_pressed(key_input, controller.key_down)
  pan_camera_press_if_pressed(key_input, controller.key_left)
  pan_camera_press_if_pressed(key_input, controller.key_right)
  pan_camera_press_if_pressed(key_input, controller.key_rotate_ccw)
  pan_camera_press_if_pressed(key_input, controller.key_rotate_cw)
  key_input
}

///|
fn pan_camera_zoom_bounds(controller : PanCamera) -> (Float, Float) {
  let safe_min = if controller.min_zoom <= 0.0F {
    0.0001F
  } else {
    controller.min_zoom
  }
  let safe_max = if controller.max_zoom >= safe_min {
    controller.max_zoom
  } else {
    safe_min
  }
  (safe_min, safe_max)
}

///|
fn pan_camera_scroll_delta(scroll : @input.AccumulatedMouseScroll) -> Float {
  match scroll.unit {
    @input.MouseScrollUnit::Line => scroll.delta.y
    @input.MouseScrollUnit::Pixel =>
      scroll.delta.y / PAN_CAMERA_SCROLL_UNIT_CONVERSION_FACTOR
  }
}

///|
fn pan_camera_step(
  transform : @transform.Transform,
  controller : PanCamera,
  delta_seconds : Float,
  key_input : @input.ButtonInput[@window.KeyCode],
  accumulated_mouse_scroll : @input.AccumulatedMouseScroll,
) -> (@transform.Transform, PanCamera) {
  let next_transform = transform
  let next_controller = controller
  if !next_controller.enabled {
    return (next_transform, next_controller)
  }
  let movement = @math.Vec2::zero()
  if next_controller.key_left is Some(key) && key_input.pressed(key) {
    movement.x = movement.x - 1.0F
  }
  if next_controller.key_right is Some(key) && key_input.pressed(key) {
    movement.x = movement.x + 1.0F
  }
  if next_controller.key_down is Some(key) && key_input.pressed(key) {
    movement.y = movement.y - 1.0F
  }
  if next_controller.key_up is Some(key) && key_input.pressed(key) {
    movement.y = movement.y + 1.0F
  }
  if movement.length_squared() > 0.0F {
    let right = next_transform.right()
    let up = next_transform.up()
    let delta = right
      .mul_scalar(movement.x)
      .add(up.mul_scalar(movement.y))
      .normalize_or_zero()
      .mul_scalar(next_controller.pan_speed * delta_seconds)
    next_transform.translation = next_transform.translation.add(
      @math.Vec3::new(delta.x, delta.y, 0.0F),
    )
  }
  if next_controller.key_rotate_ccw is Some(key) && key_input.pressed(key) {
    next_transform.rotate_z(next_controller.rotation_speed * delta_seconds)
  }
  if next_controller.key_rotate_cw is Some(key) && key_input.pressed(key) {
    next_transform.rotate_z(-next_controller.rotation_speed * delta_seconds)
  }
  let mut zoom_amount = 0.0F
  if next_controller.key_zoom_in is Some(key) && key_input.pressed(key) {
    zoom_amount = zoom_amount - next_controller.zoom_speed
  }
  if next_controller.key_zoom_out is Some(key) && key_input.pressed(key) {
    zoom_amount = zoom_amount + next_controller.zoom_speed
  }
  zoom_amount = zoom_amount +
    pan_camera_scroll_delta(accumulated_mouse_scroll) *
    next_controller.zoom_speed
  let (safe_min_zoom, safe_max_zoom) = pan_camera_zoom_bounds(next_controller)
  next_controller.zoom_factor = if next_controller.zoom_factor - zoom_amount <
    safe_min_zoom {
    safe_min_zoom
  } else if next_controller.zoom_factor - zoom_amount > safe_max_zoom {
    safe_max_zoom
  } else {
    next_controller.zoom_factor - zoom_amount
  }
  next_transform.scale = @math.Vec3::splat(next_controller.zoom_factor)
  (next_transform, next_controller)
}

///|
fn pan_camera_world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in pancamera controller")
  }
}

///|
pub fn run_pancamera_controller(world : @ecs.World) -> Unit {
  let delta_seconds = pan_camera_world_time(world).delta_seconds()
  let accumulated_mouse_scroll = match
    (try! world.get_resource(@input.AccumulatedMouseScroll::resource())) {
    Some(value) => value
    None => @input.AccumulatedMouseScroll::new()
  }
  let controlled_entities : Array[@core.Entity] = []
  world.for_each_component(ecs_key_pan_camera, fn(entity, _controller) {
    if (try! world.get_by_key(entity, @sprite.ecs_key_camera)) is Some(_) &&
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) is Some(_) {
      controlled_entities.push(entity)
    }
  })
  for controlled_entity in controlled_entities {
    guard (try! world.get_by_key(controlled_entity, ecs_key_pan_camera))
      is Some(controller) else {
      continue
    }
    guard (try! world.get_by_key(
        controlled_entity, @transform.ecs_key_transform,
      ))
      is Some(transform) else {
      continue
    }
    let key_input = pan_camera_key_input_snapshot(controller)
    let (next_transform, next_controller) = pan_camera_step(
      transform, controller, delta_seconds, key_input, accumulated_mouse_scroll,
    )
    try! (world.replace(
      controlled_entity, @transform.ecs_key_transform, next_transform,
    )
    |> ignore)
    try! (world.replace(controlled_entity, ecs_key_pan_camera, next_controller)
    |> ignore)
  }
}

///|
pub fn pan_camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_systems(
    @app.RunFixedMainLoop,
    @app.system(run_pancamera_controller).in_set(
      @app.run_fixed_main_loop_system_set_name(
        @app.RunFixedMainLoopSystems::BeforeFixedMainLoop,
      ),
    ),
  )
}

///|
pub struct PanCameraPlugin {}

///|
pub fn PanCameraPlugin::default() -> PanCameraPlugin {
  PanCameraPlugin::{  }
}

///|
pub impl @app.Plugin for PanCameraPlugin with name(_self) {
  PAN_CAMERA_PLUGIN_NAME
}

///|
pub impl @app.Plugin for PanCameraPlugin with build(_self, app) {
  pan_camera_plugin(app)
}

///|
pub fn run_pan_camera_controller(world : @ecs.World) -> Unit {
  run_pancamera_controller(world)
}
