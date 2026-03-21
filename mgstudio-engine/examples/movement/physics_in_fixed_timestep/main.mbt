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
/// Port of `bevy/examples/movement/physics_in_fixed_timestep.rs`.

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
fn spawn_text(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  let overlay_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(1).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  world
  .component(@ui.IsDefaultUiCamera::component())
  .insert(overlay_camera, @ui.IsDefaultUiCamera::default(), tick)

  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_target_camera)
  .insert(root, @ui.UiTargetCamera::new(overlay_camera), tick)

  let panel = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(panel, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    panel,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_bottom(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F))
    .with_flex_direction(@ui.FlexDirection::Column),
    tick,
  )

  let font = @text.TextFont::default().with_font_size(25.0F)
  let line_one = @text.Text2dBundle::new(
      @text.Text2d::new("Move the player with WASD"),
      font,
      @transform.Transform::identity(),
    )
    .with_anchor(@sprite.Anchor::center_left())
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .spawn()

  let line_one_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(line_one_entity, @hierarchy.Parent::new(panel), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(line_one_entity, @ui.Node::default(), tick)
  world
  .component(@ui.ecs_key_ui_text)
  .insert(line_one_entity, @ui.UiText::new(line_one), tick)

  let line_two = @text.Text2dBundle::new(
      @text.Text2d::new("Rotate the camera with the mouse"),
      font,
      @transform.Transform::identity(),
    )
    .with_anchor(@sprite.Anchor::center_left())
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .spawn()

  let line_two_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(line_two_entity, @hierarchy.Parent::new(panel), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(line_two_entity, @ui.Node::default(), tick)
  world
  .component(@ui.ecs_key_ui_text)
  .insert(line_two_entity, @ui.UiText::new(line_two), tick)
}

///|
fn spawn_player(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  let camera = @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  world
  .component(CameraSensitivity::component())
  .insert(camera, CameraSensitivity::default(), tick)

  let player = world.spawn_empty()
  world
  .component(@ecs.Name::component())
  .insert(player, @ecs.Name::new("Player"), tick)
  world
  .component(@transform.Transform::component())
  .insert(
    player,
    @transform.Transform::identity().with_scale(@math.Vec3::splat(0.3F)),
    tick,
  )
  world
  .component(AccumulatedInput::component())
  .insert(player, AccumulatedInput::default(), tick)
  world
  .component(Velocity::component())
  .insert(player, Velocity::default(), tick)
  world
  .component(PhysicalTranslation::component())
  .insert(player, PhysicalTranslation::default(), tick)
  world
  .component(PreviousPhysicalTranslation::component())
  .insert(player, PreviousPhysicalTranslation::default(), tick)
}

///|
fn spawn_environment(world : @ecs.World) -> Unit {
  let sphere_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_sphere(0.3F)),
    ),
  )
  let sphere_material = @pbr.standard_material_add(
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
        @pbr.MeshMaterial3dBundle::new(
          sphere_mesh,
          @pbr.MeshMaterial3d::new(sphere_material),
          @transform.Transform::from_translation(translation),
        ).spawn(world)
        |> ignore
      }
    }
  }

  let light = world.spawn_empty()
  let tick = world.read_change_tick()
  world
  .component(@pbr.DirectionalLight::component())
  .insert(light, @pbr.DirectionalLight::default(), tick)
  world
  .component(@transform.Transform::component())
  .insert(
    light,
    @transform.Transform::identity().looking_to(
      @math.Vec3::new(-1.0F, -3.0F, 0.5F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
}

///|
fn clear_fixed_timestep_flag(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  guard (try! world.get_resource_ref_mut(
      DidFixedTimestepRunThisFrame::resource(),
      tick,
    ))
    is Some(flag) else {
    return
  }
  flag.val.value = false
}

///|
fn set_fixed_time_step_flag(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  guard (try! world.get_resource_ref_mut(
      DidFixedTimestepRunThisFrame::resource(),
      tick,
    ))
    is Some(flag) else {
    return
  }
  flag.val.value = true
}

///|
fn rotate_camera(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(@input.AccumulatedMouseMotion::resource()))
    is Some(motion) else {
    return
  }

  let delta = motion.delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }

  let tick = world.increment_change_tick()
  let transform_store = world.component(@transform.Transform::component())
  let camera3d_store = world.component(@camera.Camera3d::component())
  let sensitivity_store = world.component(CameraSensitivity::component())
  sensitivity_store.for_each(fn(entity, sensitivity) {
    guard camera3d_store.get(entity) is Some(_) else { return }
    guard transform_store.get(entity) is Some(transform) else { return }

    let delta_yaw = -delta.x * sensitivity.x
    let delta_pitch = -delta.y * sensitivity.y
    let (yaw, pitch, roll) = transform.rotation.to_euler(@math.EulerRot::YXZ)
    let next_pitch = clamp_float(
      pitch + delta_pitch,
      -CAMERA_PITCH_LIMIT,
      CAMERA_PITCH_LIMIT,
    )
    let next_transform = transform
    next_transform.rotation = @math.Quat::from_euler(
      @math.EulerRot::YXZ,
      yaw + delta_yaw,
      next_pitch,
      roll,
    )
    ignore(transform_store.set(entity, next_transform, tick))
  })
}

///|
fn first_camera_transform(world : @ecs.World) -> @transform.Transform? {
  let result : Ref[@transform.Transform?] = Ref::new(None)
  let transform_store = world.component(@transform.Transform::component())
  world
  .query_entities_filtered(
    (
      @ecs.With::new(@camera.Camera3d::component()),
      @ecs.With::new(@transform.Transform::component()),
    ),
  )
  .view(fn(entity) {
    if result.val is Some(_) {
      return
    }
    if transform_store.get(entity) is Some(transform) {
      result.val = Some(transform)
    }
  })
  result.val
}

///|
fn accumulate_input(world : @ecs.World) -> Unit {
  guard first_camera_transform(world) is Some(camera_transform) else { return }

  let movement = @math.Vec2::zero()
  if @input.key_pressed(@window.KeyCode::KeyW) {
    movement.y = movement.y + 1.0F
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    movement.y = movement.y - 1.0F
  }
  if @input.key_pressed(@window.KeyCode::KeyA) {
    movement.x = movement.x - 1.0F
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    movement.x = movement.x + 1.0F
  }

  let tick = world.increment_change_tick()
  let accumulated_input_store = world.component(AccumulatedInput::component())
  let velocity_store = world.component(Velocity::component())
  accumulated_input_store.for_each(fn(entity, input) {
    guard velocity_store.get(entity) is Some(existing_velocity) else { return }
    let next_input = input
    next_input.movement = movement
    let next_velocity = existing_velocity
    let velocity_from_input = camera_transform
      .right()
      .mul_scalar(next_input.movement.x)
      .add(camera_transform.forward().mul_scalar(next_input.movement.y))
    next_velocity.value = vec3_clamp_length_max(velocity_from_input, 1.0F).mul_scalar(
      PLAYER_SPEED,
    )
    ignore(accumulated_input_store.set(entity, next_input, tick))
    ignore(velocity_store.set(entity, next_velocity, tick))
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
fn clear_input(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  let input_store = world.component(AccumulatedInput::component())
  input_store.for_each(fn(entity, input) {
    let next_input = input
    next_input.movement = @math.Vec2::zero()
    ignore(input_store.set(entity, next_input, tick))
  })
}

///|
fn advance_physics(world : @ecs.World) -> Unit {
  let delta_seconds = @time.time_fixed_delta_seconds()
  let tick = world.increment_change_tick()
  let current_store = world.component(PhysicalTranslation::component())
  let previous_store = world.component(PreviousPhysicalTranslation::component())
  let velocity_store = world.component(Velocity::component())
  current_store.for_each(fn(entity, current_translation) {
    guard previous_store.get(entity) is Some(previous_translation) else {
      return
    }
    guard velocity_store.get(entity) is Some(velocity) else { return }

    let next_previous = previous_translation
    next_previous.value = current_translation.value
    ignore(previous_store.set(entity, next_previous, tick))

    let next_current = current_translation
    next_current.value = current_translation.value.add(
      velocity.value.mul_scalar(delta_seconds),
    )
    ignore(current_store.set(entity, next_current, tick))
  })
}

///|
fn interpolate_rendered_transform(world : @ecs.World) -> Unit {
  let alpha = @time.time_fixed_overstep_fraction()
  let tick = world.increment_change_tick()
  let current_store = world.component(PhysicalTranslation::component())
  let previous_store = world.component(PreviousPhysicalTranslation::component())
  let transform_store = world.component(@transform.Transform::component())
  current_store.for_each(fn(entity, current_translation) {
    guard previous_store.get(entity) is Some(previous_translation) else {
      return
    }
    guard transform_store.get(entity) is Some(transform) else { return }
    let next_transform = transform
    next_transform.translation = previous_translation.value.interpolate(
      current_translation.value,
      alpha,
    )
    ignore(transform_store.set(entity, next_transform, tick))
  })
}

///|
fn first_player_translation(world : @ecs.World) -> @math.Vec3? {
  let result : Ref[@math.Vec3?] = Ref::new(None)
  let transform_store = world.component(@transform.Transform::component())
  world
  .query_entities_filtered(
    (
      @ecs.With::new(AccumulatedInput::component()),
      @ecs.With::new(@transform.Transform::component()),
    ),
  )
  .view(fn(entity) {
    if result.val is Some(_) {
      return
    }
    if transform_store.get(entity) is Some(transform) {
      result.val = Some(transform.translation)
    }
  })
  result.val
}

///|
fn translate_camera(world : @ecs.World) -> Unit {
  guard first_player_translation(world) is Some(player_translation) else {
    return
  }
  let tick = world.increment_change_tick()
  let transform_store = world.component(@transform.Transform::component())
  world
  .query_entities_filtered(
    (
      @ecs.With::new(@camera.Camera3d::component()),
      @ecs.With::new(@transform.Transform::component()),
    ),
  )
  .view(fn(entity) {
    guard transform_store.get(entity) is Some(transform) else { return }
    let next_transform = transform
    next_transform.translation = player_translation
    ignore(transform_store.set(entity, next_transform, tick))
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
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .init_resource(DidFixedTimestepRunThisFrame::default)
  .add_startup_system(spawn_text)
  .add_startup_system(spawn_player)
  .add_startup_system(spawn_environment)
  .add_pre_update_system(clear_fixed_timestep_flag)
  .add_fixed_pre_update_system(set_fixed_time_step_flag)
  .add_fixed_update_system(advance_physics)
  .add_run_fixed_main_loop_system_config(
    @app.system(rotate_camera)
    .in_set(SET_ROTATE_CAMERA)
    .before(SET_ACCUMULATE_INPUT)
    .before(fixed_main_loop_set),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(accumulate_input)
    .in_set(SET_ACCUMULATE_INPUT)
    .before(fixed_main_loop_set),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(clear_input)
    .run_if(did_fixed_timestep_run_this_frame)
    .in_set(SET_CLEAR_INPUT)
    .after(fixed_main_loop_set)
    .before(SET_INTERPOLATE_TRANSFORM),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(interpolate_rendered_transform)
    .in_set(SET_INTERPOLATE_TRANSFORM)
    .after(fixed_main_loop_set)
    .before(SET_TRANSLATE_CAMERA),
  )
  .add_run_fixed_main_loop_system_config(
    @app.system(translate_camera)
    .in_set(SET_TRANSLATE_CAMERA)
    .after(fixed_main_loop_set),
  )
  .run()
}
