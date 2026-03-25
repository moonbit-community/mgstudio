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
  value : @math.Vec3
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
impl @ecs.Component for AccumulatedInput with component() {
  accumulated_input_key
}

///|
impl @ecs.Component for Velocity with component() {
  velocity_key
}

///|
impl @ecs.Component for PhysicalTranslation with component() {
  physical_translation_key
}

///|
impl @ecs.Component for PreviousPhysicalTranslation with component() {
  previous_physical_translation_key
}

///|
impl @ecs.Component for CameraSensitivity with component() {
  camera_sensitivity_key
}

///|
impl @app.Resource for DidFixedTimestepRunThisFrame with resource() {
  fixed_frame_flag_key
}

///|
fn AccumulatedInput::default() -> AccumulatedInput {
  { movement: @math.Vec2::zero() }
}

///|
fn Velocity::default() -> Velocity {
  { value: @math.Vec3::zero() }
}

///|
fn PhysicalTranslation::default() -> PhysicalTranslation {
  { value: @math.Vec3::zero() }
}

///|
fn PreviousPhysicalTranslation::default() -> PreviousPhysicalTranslation {
  { value: @math.Vec3::zero() }
}

///|
fn CameraSensitivity::default() -> CameraSensitivity {
  { x: 0.003F, y: 0.002F }
}

///|
fn DidFixedTimestepRunThisFrame::default() -> DidFixedTimestepRunThisFrame {
  { value: false }
}

///|
fn spawn_text(commands : @app.Commands) -> Unit {
  let overlay_camera = commands.spawn(
    (
      @sprite.Camera2d::default(),
      @sprite.Camera::default().with_order(1).with_clear_color_none(),
      @ui.IsDefaultUiCamera::default(),
    ),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.UiTargetCamera::new(overlay_camera),
    ),
  )

  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_bottom(@ui.Val::Px(12.0F))
      .with_left(@ui.Val::Px(12.0F))
      .with_flex_direction(@ui.FlexDirection::Column),
    ),
  )

  let font = @text.TextFont::default().with_font_size(25.0F)
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(panel),
        @ui.Node::default(),
        @text.Text::new("Move the player with WASD"),
        font,
        @text.TextColor::new(@sprite.Color::white()),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(panel),
        @ui.Node::default(),
        @text.Text::new("Rotate the camera with the mouse"),
        font,
        @text.TextColor::new(@sprite.Color::white()),
      ),
    ),
  )
}

///|
fn spawn_player(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::identity(),
        CameraSensitivity::default(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Player"),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(0.3F)),
        AccumulatedInput::default(),
        Velocity::default(),
        PhysicalTranslation::default(),
        PreviousPhysicalTranslation::default(),
      ),
    ),
  )
}

///|
fn spawn_environment(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let sphere_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_sphere(0.3F)),
  )
  let sphere_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.73F, 0.86F, 0.95F)),
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
              @pbr.Mesh3d::new(sphere_mesh),
              @pbr.MeshMaterial3d::new(sphere_material),
            ),
          ),
        )
      }
    }
  }

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::default(),
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
  did_run.get_ref().val.value = false
}

///|
fn set_fixed_time_step_flag(
  did_run : @app.ResMut[DidFixedTimestepRunThisFrame],
) -> Unit {
  did_run.get_ref().val.value = true
}

///|
fn rotate_camera(
  accumulated_mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  cameras : @ecs.Query[
    (@ecs.Comp[CameraSensitivity], @ecs.Mut[@transform.Transform]),
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  let delta = accumulated_mouse_motion.get().delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }

  try! cameras.view(fn(_entity, data) {
    let (sensitivity, transform) = data
    let transform_ref = transform.get_ref()
    let delta_yaw = -delta.x * sensitivity.value().x
    let delta_pitch = -delta.y * sensitivity.value().y
    let (yaw, pitch, roll) = transform_ref.val.rotation.to_euler(
      @math.EulerRot::YXZ,
    )
    let next_pitch = clamp_float(
      pitch + delta_pitch,
      -CAMERA_PITCH_LIMIT,
      CAMERA_PITCH_LIMIT,
    )
    transform_ref.val.rotation = @math.Quat::from_euler(
      @math.EulerRot::YXZ,
      yaw + delta_yaw,
      next_pitch,
      roll,
    )
  })
}

///|
fn accumulate_input(
  commands : @app.Commands,
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  players : @ecs.Query[
    (@ecs.Comp[AccumulatedInput], @ecs.Mut[Velocity]),
    @ecs.All,
  ],
  cameras : @ecs.Query1Filtered[
    @transform.Transform,
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  guard (try! cameras.single()) is Some(camera_transform) else { return }

  try! players.view(fn(entity, data) {
    let (input, velocity) = data
    let next_input = input.value()
    next_input.movement = @math.Vec2::zero()
    if keyboard_input.pressed(@window.KeyCode::KeyW) {
      next_input.movement.y = next_input.movement.y + 1.0F
    }
    if keyboard_input.pressed(@window.KeyCode::KeyS) {
      next_input.movement.y = next_input.movement.y - 1.0F
    }
    if keyboard_input.pressed(@window.KeyCode::KeyA) {
      next_input.movement.x = next_input.movement.x - 1.0F
    }
    if keyboard_input.pressed(@window.KeyCode::KeyD) {
      next_input.movement.x = next_input.movement.x + 1.0F
    }

    let velocity_ref = velocity.get_ref()
    let velocity_from_input = camera_transform
      .right()
      .mul_scalar(next_input.movement.x)
      .add(camera_transform.forward().mul_scalar(next_input.movement.y))
    velocity_ref.val.value = vec3_clamp_length_max(velocity_from_input, 1.0F).mul_scalar(
      PLAYER_SPEED,
    )
    commands.entity(entity).insert_component(next_input)
  })
}

///|
fn did_fixed_timestep_run_this_frame(world : @ecs.World) -> Bool {
  match (try! world.get_resource(DidFixedTimestepRunThisFrame::resource())) {
    Some(flag) => flag.value
    None => false
  }
}

///|
fn clear_input(
  players : @ecs.Query[@ecs.Mut[AccumulatedInput], @ecs.All],
) -> Unit {
  try! players.view(fn(_entity, input) {
    let input_ref = input.get_ref()
    input_ref.val.movement = @math.Vec2::zero()
  })
}

///|
fn advance_physics(
  commands : @app.Commands,
  players : @ecs.Query[
    (
      @ecs.Comp[PreviousPhysicalTranslation],
      @ecs.Comp[Velocity],
      @ecs.Mut[PhysicalTranslation],
    ),
    @ecs.All,
  ],
) -> Unit {
  let delta_seconds = @time.time_fixed_delta_seconds()
  try! players.view(fn(entity, data) {
    let (_previous_translation, velocity, current_translation) = data
    let previous_value = current_translation.get_ref().val.value
    commands
    .entity(entity)
    .insert_component(PreviousPhysicalTranslation::{ value: previous_value })

    let current_ref = current_translation.get_ref()
    current_ref.val.value = current_ref.val.value.add(
      velocity.value().value.mul_scalar(delta_seconds),
    )
  })
}

///|
fn interpolate_rendered_transform(
  players : @ecs.Query[
    (
      @ecs.Comp[PreviousPhysicalTranslation],
      @ecs.Comp[PhysicalTranslation],
      @ecs.Mut[@transform.Transform],
    ),
    @ecs.All,
  ],
) -> Unit {
  let alpha = @time.time_fixed_overstep_fraction()
  try! players.view(fn(_entity, data) {
    let (previous_translation, current_translation, transform) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.translation = previous_translation.value().value.interpolate(
      current_translation.value().value,
      alpha,
    )
  })
}

///|
fn translate_camera(
  players : @ecs.Query1Filtered[
    @transform.Transform,
    @ecs.With[AccumulatedInput],
  ],
  cameras : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  guard (try! players.single()) is Some(player_transform) else { return }

  try! cameras.view(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.translation = player_transform.translation
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
    @app.RunFixedMainLoopSystems::FixedMainLoop,
  )
  let spawn_text_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(spawn_text),
  )
  let spawn_player_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param(spawn_player),
  )
  let spawn_environment_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(spawn_environment),
  )

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(DidFixedTimestepRunThisFrame::default)
  .add_systems(@app.Startup, spawn_text_system)
  .add_systems(@app.Startup, spawn_player_system)
  .add_systems(@app.Startup, spawn_environment_system)
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param(clear_fixed_timestep_flag)),
  )
  .add_systems(
    @app.FixedPreUpdate,
    @app.system(@app.system_param(set_fixed_time_step_flag)),
  )
  .add_systems(
    @app.FixedUpdate,
    @app.system(@app.system_param2(advance_physics)),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(@app.system_param2(rotate_camera))
    .in_set(SET_ROTATE_CAMERA)
    .before(SET_ACCUMULATE_INPUT)
    .before(fixed_main_loop_set),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(@app.system_param4(accumulate_input))
    .in_set(SET_ACCUMULATE_INPUT)
    .before(fixed_main_loop_set),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(@app.system_param(clear_input))
    .run_if(did_fixed_timestep_run_this_frame)
    .in_set(SET_CLEAR_INPUT)
    .after(fixed_main_loop_set)
    .before(SET_INTERPOLATE_TRANSFORM),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(@app.system_param(interpolate_rendered_transform))
    .in_set(SET_INTERPOLATE_TRANSFORM)
    .after(fixed_main_loop_set)
    .before(SET_TRANSLATE_CAMERA),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(@app.system_param2(translate_camera))
    .in_set(SET_TRANSLATE_CAMERA)
    .after(fixed_main_loop_set),
  )
  .run()
}
