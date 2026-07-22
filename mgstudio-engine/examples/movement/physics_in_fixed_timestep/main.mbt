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
extend DidFixedTimestepRunThisFrame with @app.Resource::{resource}

///|
const PLAYER_SPEED : Float = 4.0F

///|
const SPHERE_DISTANCE : Float = 3.0F

///|
const SPHERES_IN_X : Int = 6

///|
const SPHERES_IN_Y : Int = 4

///|
const SPHERES_IN_Z : Int = 10

///|
const CAMERA_PITCH_LIMIT : Float = 1.5607963267948966F

///|
const SET_ROTATE_CAMERA : @app.SystemSet = "examples.movement.physics_fixed.rotate_camera"

///|
const SET_ACCUMULATE_INPUT : @app.SystemSet = "examples.movement.physics_fixed.accumulate_input"

///|
const SET_CLEAR_INPUT : @app.SystemSet = "examples.movement.physics_fixed.clear_input"

///|
const SET_INTERPOLATE_TRANSFORM : @app.SystemSet = "examples.movement.physics_fixed.interpolate_transform"

///|
const SET_TRANSLATE_CAMERA : @app.SystemSet = "examples.movement.physics_fixed.translate_camera"

///|
struct AccumulatedInput {
  mut movement : @math.Vec2
}

///|
struct Velocity {
  mut value : @math.Vec3
}

///|
struct PhysicalTranslation {
  mut value : @math.Vec3
}

///|
struct PreviousPhysicalTranslation {
  mut value : @math.Vec3
}

///|
struct CameraSensitivity {
  x : Float
  y : Float
}

///|
struct DidFixedTimestepRunThisFrame {
  mut value : Bool
}

///|
let accumulated_input_key : @ecs.ComponentKey[AccumulatedInput] = @ecs.register_component(
  debug_name="examples.movement.physics_in_fixed_timestep.AccumulatedInput",
)

///|
let velocity_key : @ecs.ComponentKey[Velocity] = @ecs.register_component(
  debug_name="examples.movement.physics_in_fixed_timestep.Velocity",
)

///|
let physical_translation_key : @ecs.ComponentKey[PhysicalTranslation] = @ecs.register_component(
  debug_name="examples.movement.physics_in_fixed_timestep.PhysicalTranslation",
)

///|
let previous_physical_translation_key : @ecs.ComponentKey[
  PreviousPhysicalTranslation,
] = @ecs.register_component(
  debug_name="examples.movement.physics_in_fixed_timestep.PreviousPhysicalTranslation",
)

///|
let camera_sensitivity_key : @ecs.ComponentKey[CameraSensitivity] = @ecs.register_component(
  debug_name="examples.movement.physics_in_fixed_timestep.CameraSensitivity",
)

///|
let fixed_frame_flag_key : @ecs.ResourceKey[DidFixedTimestepRunThisFrame] = @ecs.register_resource(
  debug_name="examples.movement.physics_in_fixed_timestep.DidFixedTimestepRunThisFrame",
)

///|
impl @ecs.Component for AccumulatedInput with fn component() {
  accumulated_input_key
}

///|
impl @ecs.Component for Velocity with fn component() {
  velocity_key
}

///|
impl @ecs.Component for PhysicalTranslation with fn component() {
  physical_translation_key
}

///|
impl @ecs.Component for PreviousPhysicalTranslation with fn component() {
  previous_physical_translation_key
}

///|
impl @ecs.Component for CameraSensitivity with fn component() {
  camera_sensitivity_key
}

///|
impl @app.Resource for DidFixedTimestepRunThisFrame with fn resource() {
  fixed_frame_flag_key
}

///|
fn AccumulatedInput::AccumulatedInput() -> AccumulatedInput {
  { movement: @math.Vec2::zero() }
}

///|
fn Velocity::Velocity() -> Velocity {
  { value: @math.Vec3::zero() }
}

///|
fn PhysicalTranslation::PhysicalTranslation() -> PhysicalTranslation {
  { value: @math.Vec3::zero() }
}

///|
fn PreviousPhysicalTranslation::PreviousPhysicalTranslation() -> PreviousPhysicalTranslation {
  { value: @math.Vec3::zero() }
}

///|
fn CameraSensitivity::CameraSensitivity() -> CameraSensitivity {
  { x: 0.003F, y: 0.002F }
}

///|
fn DidFixedTimestepRunThisFrame::DidFixedTimestepRunThisFrame() -> DidFixedTimestepRunThisFrame {
  { value: false }
}

///|
fn spawn_text(commands : @app.Commands) -> Unit {
  let overlay_camera = commands.spawn(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(1).with_clear_color_none(),
      @ui.IsDefaultUiCamera::IsDefaultUiCamera(),
    ),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
      @ui.UiTargetCamera::new(overlay_camera),
    ),
  )

  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::Node()
      .with_position_type(Absolute)
      .with_bottom(Px(12.0F))
      .with_left(Px(12.0F))
      .with_flex_direction(Column),
    ),
  )

  let font = @text.TextFont::TextFont().with_font_size(25.0F)
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(panel),
        @ui.Node::Node(),
        @text.Text::new("Move the player with WASD"),
        font,
        @text.TextColor::new(@color.Color::white()),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(panel),
        @ui.Node::Node(),
        @text.Text::new("Rotate the camera with the mouse"),
        font,
        @text.TextColor::new(@color.Color::white()),
      ),
    ),
  )
}

///|
fn spawn_player(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::identity(),
        CameraSensitivity::CameraSensitivity(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Player"),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(0.3F)),
        AccumulatedInput::AccumulatedInput(),
        Velocity::Velocity(),
        PhysicalTranslation::PhysicalTranslation(),
        PreviousPhysicalTranslation::PreviousPhysicalTranslation(),
      ),
    ),
  )
}

///|
fn spawn_environment(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let sphere_mesh = meshes.modify(fn(meshes) {
    meshes |> @pbr.add_mesh(@math.Sphere::new(0.3F))
  })
  let sphere_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::srgb(0.73F, 0.86F, 0.95F)),
    )

  for x in 0..<SPHERES_IN_X {
    for y in 0..<SPHERES_IN_Y {
      for z in 0..<SPHERES_IN_Z {
        let translation = @math.Vec3::new(
          Float::from_int(x) * SPHERE_DISTANCE -
          (Float::from_int(SPHERES_IN_X) - 1.0F) * SPHERE_DISTANCE / 2.0F,
          Float::from_int(y) * SPHERE_DISTANCE -
          (Float::from_int(SPHERES_IN_Y) - 1.0F) * SPHERE_DISTANCE / 2.0F,
          Float::from_int(z) * SPHERE_DISTANCE -
          (Float::from_int(SPHERES_IN_Z) - 1.0F) * SPHERE_DISTANCE / 2.0F,
        )
        ignore(
          commands.spawn(
            (
              @ecs.Name::new("Sphere"),
              @transform.Transform::from_translation(translation),
              @mesh.Mesh3d::new(sphere_mesh),
              @pbr.MeshMaterial3dTyped::new(sphere_material),
            ),
          ),
        )
      }
    }
  }

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::DirectionalLight(),
        @transform.Transform::identity().looking_to(
          @math.Vec3::new(-1.0F, -3.0F, 0.5F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn clear_fixed_timestep_flag(
  did_run : @app.ResMut[DidFixedTimestepRunThisFrame],
) -> Unit {
  did_run.modify(fn(value) { value.value = false })
}

///|
fn set_fixed_time_step_flag(
  did_run : @app.ResMut[DidFixedTimestepRunThisFrame],
) -> Unit {
  did_run.modify(fn(value) { value.value = true })
}

///|
fn rotate_camera(
  accumulated_mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  camera : @app.Single[
    (@ecs.Write[@transform.Transform], @ecs.Read[CameraSensitivity]),
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  let delta = accumulated_mouse_motion.get().delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }

  let (transform, sensitivity) = camera.get()
  let delta_yaw = -delta.x * sensitivity.value().x
  let delta_pitch = -delta.y * sensitivity.value().y
  transform.modify(fn(value) {
    let (yaw, pitch, roll) = value.rotation.to_euler(YXZ)
    let next_pitch = clamp_float(
      pitch + delta_pitch,
      -CAMERA_PITCH_LIMIT,
      CAMERA_PITCH_LIMIT,
    )
    value.rotation = @math.Quat::from_euler(
      YXZ,
      yaw + delta_yaw,
      next_pitch,
      roll,
    )
  })
}

///|
fn accumulate_input(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  player : @app.Single[
    (@ecs.Write[AccumulatedInput], @ecs.Write[Velocity]),
    @ecs.All,
  ],
  camera : @app.Single[
    @ecs.Read[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  let camera_transform = camera.get().value()
  let (input, velocity) = player.get()
  input.modify(fn(value) {
    value.movement = @math.Vec2::zero()
    if keyboard_input.pressed(KeyW) {
      value.movement.y = value.movement.y + 1.0F
    }
    if keyboard_input.pressed(KeyS) {
      value.movement.y = value.movement.y - 1.0F
    }
    if keyboard_input.pressed(KeyA) {
      value.movement.x = value.movement.x - 1.0F
    }
    if keyboard_input.pressed(KeyD) {
      value.movement.x = value.movement.x + 1.0F
    }
  })
  let movement = input.value().movement
  let velocity_from_input = camera_transform
    .right()
    .mul_scalar(movement.x)
    .add(camera_transform.forward().mul_scalar(movement.y))
  velocity.modify(fn(value) {
    value.value = vec3_clamp_length_max(velocity_from_input, 1.0F).mul_scalar(
      PLAYER_SPEED,
    )
  })
}

///|
fn did_fixed_timestep_run_this_frame(world : @ecs.World) -> Bool {
  match world.get_resource(DidFixedTimestepRunThisFrame::resource()) {
    Some(flag) => flag.value
    None => false
  }
}

///|
fn clear_input(
  players : @ecs.Query[@ecs.Write[AccumulatedInput], @ecs.All],
) -> Unit {
  try! players.view(fn(_entity, input) {
    input.modify(fn(value) { value.movement = @math.Vec2::zero() })
  })
}

///|
fn advance_physics(
  players : @ecs.Query[
    (
      @ecs.Write[PhysicalTranslation],
      @ecs.Write[PreviousPhysicalTranslation],
      @ecs.Read[Velocity],
    ),
    @ecs.All,
  ],
) -> Unit {
  let delta_seconds = @time.time_fixed_delta_seconds()
  try! players.view(fn(_entity, data) {
    let (current_translation, previous_translation, velocity) = data
    let previous_value = current_translation.value().value
    previous_translation.modify(fn(value) { value.value = previous_value })
    current_translation.modify(fn(value) {
      value.value = value.value.add(
        velocity.value().value.mul_scalar(delta_seconds),
      )
    })
  })
}

///|
fn interpolate_rendered_transform(
  players : @ecs.Query[
    (
      @ecs.Read[PreviousPhysicalTranslation],
      @ecs.Read[PhysicalTranslation],
      @ecs.Write[@transform.Transform],
    ),
    @ecs.All,
  ],
) -> Unit {
  let alpha = @time.time_fixed_overstep_fraction()
  try! players.view(fn(_entity, data) {
    let (previous_translation, current_translation, transform) = data
    transform.modify(fn(value) {
      value.translation = previous_translation.value().value.interpolate(
        current_translation.value().value,
        alpha,
      )
    })
  })
}

///|
fn translate_camera(
  player : @app.Single[
    @ecs.Read[@transform.Transform],
    (@ecs.With[AccumulatedInput], @ecs.Without[@camera.Camera3d]),
  ],
  camera : @app.Single[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  let player_transform = player.get().value()
  let camera_transform = camera.get()
  camera_transform.modify(fn(value) {
    value.translation = player_transform.translation
  })
}

///|
fn vec3_clamp_length_max(value : @math.Vec3, max_length : Float) -> @math.Vec3 {
  let length = value.length()
  if length > max_length && length > 0.0F {
    value.mul_scalar(max_length / length)
  } else {
    value
  }
}

///|
fn clamp_float(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    return min_value
  }
  if value > max_value {
    return max_value
  }
  value
}

///|
fn main {
  let fixed_main_loop_set = @app.run_fixed_main_loop_system_set_name(
    FixedMainLoop,
  )
  let spawn_text_system : @app.SystemConfig[@ecs.World] = @app.system_config_param(
    spawn_text,
  )
  let spawn_player_system : @app.SystemConfig[@ecs.World] = @app.system_config_param(
    spawn_player,
  )
  let spawn_environment_system : @app.SystemConfig[@ecs.World] = @app.system_config_param3(
    spawn_environment,
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .init_resource(fn() {
    DidFixedTimestepRunThisFrame::DidFixedTimestepRunThisFrame()
  })
  .add_systems(Startup, spawn_text_system)
  .add_systems(Startup, spawn_player_system)
  .add_systems(Startup, spawn_environment_system)
  .add_systems_param(PreUpdate, clear_fixed_timestep_flag)
  .add_systems_param(FixedPreUpdate, set_fixed_time_step_flag)
  .add_systems_param(FixedUpdate, advance_physics)
  .add_run_fixed_main_loop_system_config(
    @app.system_config_param2(rotate_camera)
    .in_set(SET_ROTATE_CAMERA)
    .before(SET_ACCUMULATE_INPUT)
    .before(fixed_main_loop_set),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system_config_param3(accumulate_input)
    .in_set(SET_ACCUMULATE_INPUT)
    .before(fixed_main_loop_set),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system_config_param(clear_input)
    .run_if(did_fixed_timestep_run_this_frame)
    .in_set(SET_CLEAR_INPUT)
    .after(fixed_main_loop_set)
    .before(SET_INTERPOLATE_TRANSFORM),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system_config_param(interpolate_rendered_transform)
    .in_set(SET_INTERPOLATE_TRANSFORM)
    .after(fixed_main_loop_set)
    .before(SET_TRANSLATE_CAMERA),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system_config_param2(translate_camera)
    .in_set(SET_TRANSLATE_CAMERA)
    .after(fixed_main_loop_set),
  )
  .run()
}
