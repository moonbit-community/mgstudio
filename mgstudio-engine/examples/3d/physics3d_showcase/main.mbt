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
/// Physics3D showcase:
/// - Dynamic rigid body stacks.
/// - Kinematic velocity-based body sweeping the arena.
/// - Sensor events + collision event reporting.
/// - Runtime spawning (mouse click / Space / hold F).
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_fixed_update_system(physics3d_showcase_kinematic_motion_fixed)
  .add_plugins(plugins)
  .add_startup_system(physics3d_showcase_setup)
  .add_system(physics3d_showcase_camera_controls)
  .add_system(physics3d_showcase_overlay_system)
  .add_system(physics3d_showcase_spawn_controls)
  .add_system(physics3d_showcase_events_and_stats)
  .run()
}

///|
priv struct Physics3dShowcaseState {
  mut projectile_material : @asset.Handle[@render3d.StandardMaterial]?
  mut overlay_font : @asset.Handle[@asset.Font]?
  mut overlay_spawned : Bool
  mut kinematic_bar : @core.Entity?
  mut sensor_zone : @core.Entity?
  mut camera_entity : @core.Entity?
  mut camera_position : @math.Vec3
  mut camera_yaw : Float
  mut camera_pitch : Float
  mut camera_last_cursor : @math.Vec2?
  mut next_auto_fire_time : Float
  mut spawn_serial : Int
  mut collision_started : Int
  mut sensor_entered : Int
  mut sensor_left : Int
  mut last_stats_print_time : Float
}

///|
let physics3d_showcase_state : Ref[Physics3dShowcaseState] = Ref::new({
  projectile_material: None,
  overlay_font: None,
  overlay_spawned: false,
  kinematic_bar: None,
  sensor_zone: None,
  camera_entity: None,
  camera_position: @math.Vec3::new(0.0F, 180.0F, 860.0F),
  camera_yaw: 0.0F,
  camera_pitch: 0.0F,
  camera_last_cursor: None,
  next_auto_fire_time: 0.0,
  spawn_serial: 0,
  collision_started: 0,
  sensor_entered: 0,
  sensor_left: 0,
  last_stats_print_time: 0.0,
})

const CAMERA_MOVE_SPEED : Float = 360.0F

const CAMERA_LOOK_SENSITIVITY : Float = 0.0075F

const CAMERA_PITCH_LIMIT : Float = 1.45F

///|
fn clamp_float(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn physics3d_showcase_camera_forward(yaw : Float, pitch : Float) -> @math.Vec3 {
  @math.Vec3::new(
    @math.sin(yaw) * @math.cos(pitch),
    @math.sin(pitch),
    -@math.cos(yaw) * @math.cos(pitch),
  )
  .normalize_or_zero()
}

///|
fn physics3d_showcase_reset_camera_pose() -> Unit {
  let position = @math.Vec3::new(0.0F, 180.0F, 860.0F)
  let target = @math.Vec3::new(0.0F, 20.0F, 0.0F)
  let forward = target.sub(position).normalize_or_zero()
  let horizontal = @math.sqrt(forward.x * forward.x + forward.z * forward.z)
  physics3d_showcase_state.val.camera_position = position
  physics3d_showcase_state.val.camera_yaw = @math.atan2(forward.x, -forward.z)
  physics3d_showcase_state.val.camera_pitch = @math.atan2(forward.y, horizontal)
}

///|
fn entity_eq(lhs : @core.Entity, rhs : @core.Entity) -> Bool {
  lhs.id == rhs.id && lhs.generation == rhs.generation
}

///|
fn spawn_fixed_cuboid(
  world : @ecs_world.World,
  tick : Int,
  half_extents : @math.Vec3,
  transform : @math.Transform,
  material : @asset.Handle[@render3d.StandardMaterial],
  sensor : Bool,
) -> @core.Entity {
  let entity = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(
      half_extents.x * 2.0F,
      half_extents.y * 2.0F,
      half_extents.z * 2.0F,
    ),
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  let rigid_body_store = world.get_rigid_body3d_store()
  let collider_store = world.get_collider3d_store()
  rigid_body_store.insert(entity, @physics3d.RigidBody3d::fixed(), tick)
  collider_store.insert(
    entity,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(
        half_extents.x,
        half_extents.y,
        half_extents.z,
      ),
    ).sensor(sensor),
    tick,
  )
  entity
}

///|
fn spawn_dynamic_crate(
  world : @ecs_world.World,
  material : @asset.Handle[@render3d.StandardMaterial],
  translation : @math.Vec3,
  half_extent : Float,
  linear_velocity : @math.Vec3,
  angular_velocity : @math.Vec3,
) -> Unit {
  let tick = world.read_change_tick()
  let entity = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(
      half_extent * 2.0F,
      half_extent * 2.0F,
      half_extent * 2.0F,
    ),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(translation.x, translation.y, translation.z),
  ).spawn(world)
  world
  .get_rigid_body3d_store()
  .insert(entity, @physics3d.RigidBody3d::dynamic(), tick)
  world
  .get_collider3d_store()
  .insert(
    entity,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(half_extent, half_extent, half_extent),
    ),
    tick,
  )
  world
  .get_velocity3d_store()
  .insert(
    entity,
    @physics3d.Velocity3d::new(linear_velocity, angular_velocity),
    tick,
  )
}

///|
fn spawn_dynamic_bouncer(
  world : @ecs_world.World,
  material : @asset.Handle[@render3d.StandardMaterial],
  translation : @math.Vec3,
  radius : Float,
  linear_velocity : @math.Vec3,
  angular_velocity : @math.Vec3,
) -> Unit {
  let tick = world.read_change_tick()
  let entity = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_tetrahedron(radius * 2.2F),
    @render3d.MeshMaterial3d::new(material),
    @math.Transform::from_xyz(translation.x, translation.y, translation.z),
  ).spawn(world)
  world
  .get_rigid_body3d_store()
  .insert(entity, @physics3d.RigidBody3d::dynamic(), tick)
  world
  .get_collider3d_store()
  .insert(
    entity,
    @physics3d.Collider3d::new(@physics3d.ColliderShape3d::ball(radius)),
    tick,
  )
  world
  .get_velocity3d_store()
  .insert(
    entity,
    @physics3d.Velocity3d::new(linear_velocity, angular_velocity),
    tick,
  )
}

///|
fn spawn_impact_body(world : @ecs_world.World) -> Unit {
  guard physics3d_showcase_state.val.projectile_material is Some(material) else {
    return
  }
  let serial = physics3d_showcase_state.val.spawn_serial
  let serial_f = Float::from_int(serial)
  let spawn_x = @math.sin(serial_f * 0.71F) * 220.0F
  let spawn_z = @math.cos(serial_f * 0.53F) * 220.0F
  let position = @math.Vec3::new(spawn_x, 420.0F, spawn_z)
  let velocity = @math.Vec3::new(-spawn_x * 0.5F, -120.0F, -spawn_z * 0.5F)
  let angular = @math.Vec3::new(1.4F + serial_f * 0.1F, 2.2F, 0.8F)
  spawn_dynamic_bouncer(world, material, position, 16.0F, velocity, angular)
  physics3d_showcase_state.val.spawn_serial = serial + 1
}

///|
fn physics3d_showcase_setup(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()
  let asset_server = @asset.AssetServer::new()
  physics3d_showcase_state.val.overlay_font = Some(
    asset_server.load_font("fonts/FiraSans-Bold.ttf"),
  )
  physics3d_showcase_reset_camera_pose()

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(100),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
  @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::new(980.0F, 176.0F)),
    @render2d.ColorMaterial::new(@render2d.Color::new(0.04F, 0.05F, 0.08F, 0.78F)),
    @math.Transform::from_xyz(0.0F, 286.0F, 32.0F),
  ).spawn(world)
  |> ignore
  println(
    "physics3d_showcase controls: RightMouse look, WASD move, Q/E up/down, R reset, LeftClick/Space spawn, Hold F auto spawn",
  )

  let config_resource = world.get_physics3d_config_resource()
  if config_resource.get_ref_mut(tick) is Some(config_ref) {
    config_ref.val = @physics3d.Physics3dConfig::new(
      @math.Vec3::new(0.0F, -980.0F, 0.0F),
    )
  }

  let floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.15F, 0.17F, 0.22F, 1.0F),
    ),
  )
  let wall_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.24F, 0.27F, 0.34F, 1.0F),
    ),
  )
  let crate_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.85F, 0.55F, 0.2F, 1.0F),
    ),
  )
  let bouncer_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.93F, 0.25F, 0.3F, 1.0F),
    ),
  )
  let kinematic_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.2F, 0.85F, 0.8F, 1.0F),
    ),
  )
  let sensor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.1F, 0.75F, 0.95F, 0.35F),
    ),
  )
  physics3d_showcase_state.val.projectile_material = Some(bouncer_material)

  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(ambient_ref) {
    ambient_ref.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.35F,
    )
  }

  let directional_light = world.spawn_empty()
  world
  .get_directional_light_store()
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(
      @render2d.Color::new(1.0F, 0.95F, 0.9F, 1.0F),
      20000.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    directional_light,
    @math.Transform::from_xyz(260.0F, 420.0F, 220.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let point_light = world.spawn_empty()
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::new(
      @render2d.Color::white(),
      160000.0F,
      1800.0F,
      false,
    ),
    tick,
  )
  world
  .get_transform_store()
  .insert(
    point_light,
    @math.Transform::from_xyz(-260.0F, 320.0F, -240.0F),
    tick,
  )

  let floor_half_extents = @math.Vec3::new(560.0F, 18.0F, 560.0F)
  spawn_fixed_cuboid(
    world,
    tick,
    floor_half_extents,
    @math.Transform::from_xyz(0.0F, -220.0F, 0.0F),
    floor_material,
    false,
  )
  |> ignore

  let wall_half_extents = @math.Vec3::new(20.0F, 220.0F, 560.0F)
  spawn_fixed_cuboid(
    world,
    tick,
    wall_half_extents,
    @math.Transform::from_xyz(-560.0F, 0.0F, 0.0F),
    wall_material,
    false,
  )
  |> ignore
  spawn_fixed_cuboid(
    world,
    tick,
    wall_half_extents,
    @math.Transform::from_xyz(560.0F, 0.0F, 0.0F),
    wall_material,
    false,
  )
  |> ignore

  let back_wall_half_extents = @math.Vec3::new(560.0F, 220.0F, 20.0F)
  spawn_fixed_cuboid(
    world,
    tick,
    back_wall_half_extents,
    @math.Transform::from_xyz(0.0F, 0.0F, -560.0F),
    wall_material,
    false,
  )
  |> ignore
  spawn_fixed_cuboid(
    world,
    tick,
    back_wall_half_extents,
    @math.Transform::from_xyz(0.0F, 0.0F, 560.0F),
    wall_material,
    false,
  )
  |> ignore

  let ramp_rotation = @math.Quat::from_rotation_z(-0.35F)
  spawn_fixed_cuboid(
    world,
    tick,
    @math.Vec3::new(180.0F, 14.0F, 120.0F),
    @math.Transform::new(
      @math.Vec3::new(180.0F, -110.0F, -140.0F),
      ramp_rotation,
      @math.Vec3::new(1.0F, 1.0F, 1.0F),
    ),
    wall_material,
    false,
  )
  |> ignore

  let sensor_entity = spawn_fixed_cuboid(
    world,
    tick,
    @math.Vec3::new(190.0F, 55.0F, 120.0F),
    @math.Transform::from_xyz(-120.0F, -80.0F, 180.0F),
    sensor_material,
    true,
  )
  physics3d_showcase_state.val.sensor_zone = Some(sensor_entity)

  let kinematic_entity = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(260.0F, 24.0F, 120.0F),
    @render3d.MeshMaterial3d::new(kinematic_material),
    @math.Transform::from_xyz(0.0F, 80.0F, 0.0F),
  ).spawn(world)
  world
  .get_rigid_body3d_store()
  .insert(
    kinematic_entity,
    @physics3d.RigidBody3d::kinematic_velocity_based(),
    tick,
  )
  world
  .get_collider3d_store()
  .insert(
    kinematic_entity,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(130.0F, 12.0F, 60.0F),
    ),
    tick,
  )
  world
  .get_velocity3d_store()
  .insert(
    kinematic_entity,
    @physics3d.Velocity3d::new(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 0.6F, 0.0F),
    ),
    tick,
  )
  physics3d_showcase_state.val.kinematic_bar = Some(kinematic_entity)

  for layer_index in 0..<7 {
    let layer_f = Float::from_int(layer_index)
    let rows = 7 - layer_index
    for column_index in 0..<rows {
      let column_f = Float::from_int(column_index)
      let row_span_f = Float::from_int(rows - 1)
      let x = (column_f - row_span_f * 0.5F) * 56.0F - 200.0F
      let y = -190.0F + layer_f * 56.0F
      let z = -40.0F + layer_f * 18.0F
      spawn_dynamic_crate(
        world,
        crate_material,
        @math.Vec3::new(x, y, z),
        24.0F,
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
      )
    }
  }

  for bouncer_index in 0..<10 {
    let bouncer_f = Float::from_int(bouncer_index)
    let x = -80.0F + bouncer_f * 18.0F
    let z = 160.0F + @math.sin(bouncer_f * 0.5F) * 70.0F
    spawn_dynamic_bouncer(
      world,
      bouncer_material,
      @math.Vec3::new(x, 260.0F + bouncer_f * 14.0F, z),
      14.0F,
      @math.Vec3::new(40.0F, -20.0F, -45.0F),
      @math.Vec3::new(0.0F, 1.3F, 0.4F),
    )
  }

  let camera_entity = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(
      physics3d_showcase_state.val.camera_position.x,
      physics3d_showcase_state.val.camera_position.y,
      physics3d_showcase_state.val.camera_position.z,
    ).looking_at(
      physics3d_showcase_state.val.camera_position.add(
        physics3d_showcase_camera_forward(
          physics3d_showcase_state.val.camera_yaw,
          physics3d_showcase_state.val.camera_pitch,
        ),
      ),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  physics3d_showcase_state.val.camera_entity = Some(camera_entity)
}

///|
fn physics3d_showcase_kinematic_motion_fixed(world : @ecs_world.World) -> Unit {
  guard physics3d_showcase_state.val.kinematic_bar is Some(kinematic_entity) else {
    return
  }
  let time_now = @time.time_elapsed_seconds()
  let linear_velocity = @math.Vec3::new(
    @math.sin(time_now * 1.3F) * 240.0F,
    0.0F,
    @math.cos(time_now * 0.9F) * 140.0F,
  )
  let angular_velocity = @math.Vec3::new(0.0F, 0.9F, 0.0F)
  let next_velocity = @physics3d.Velocity3d::new(
    linear_velocity, angular_velocity,
  )
  let tick = world.read_change_tick()
  let velocity_store = world.get_velocity3d_store()
  if velocity_store.contains(kinematic_entity) {
    velocity_store.set(kinematic_entity, next_velocity, tick) |> ignore
  } else {
    velocity_store.insert(kinematic_entity, next_velocity, tick)
  }
}

///|
fn physics3d_showcase_camera_controls(world : @ecs_world.World) -> Unit {
  guard physics3d_showcase_state.val.camera_entity is Some(camera_entity) else {
    return
  }

  let mut yaw = physics3d_showcase_state.val.camera_yaw
  let mut pitch = physics3d_showcase_state.val.camera_pitch
  if @input.mouse_position() is Some(cursor) {
    if @input.mouse_button_pressed(@window.MouseButton::Right) {
      if physics3d_showcase_state.val.camera_last_cursor is Some(last_cursor) {
        let delta = cursor.sub(last_cursor)
        yaw = yaw + delta.x * CAMERA_LOOK_SENSITIVITY
        pitch = clamp_float(
          pitch - delta.y * CAMERA_LOOK_SENSITIVITY,
          -CAMERA_PITCH_LIMIT,
          CAMERA_PITCH_LIMIT,
        )
      }
    }
    physics3d_showcase_state.val.camera_last_cursor = Some(cursor)
  } else {
    physics3d_showcase_state.val.camera_last_cursor = None
  }

  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    physics3d_showcase_reset_camera_pose()
    yaw = physics3d_showcase_state.val.camera_yaw
    pitch = physics3d_showcase_state.val.camera_pitch
  }

  let forward = physics3d_showcase_camera_forward(yaw, pitch)
  let forward_flat = @math.Vec3::new(forward.x, 0.0F, forward.z).normalize_or_zero()
  let right = @math.Vec3::new(@math.cos(yaw), 0.0F, @math.sin(yaw)).normalize_or_zero()
  let mut move_direction = @math.Vec3::zero()
  if @input.key_pressed(@window.KeyCode::KeyW) ||
    @input.key_pressed(@window.KeyCode::ArrowUp) {
    move_direction = move_direction.add(forward_flat)
  }
  if @input.key_pressed(@window.KeyCode::KeyS) ||
    @input.key_pressed(@window.KeyCode::ArrowDown) {
    move_direction = move_direction.sub(forward_flat)
  }
  if @input.key_pressed(@window.KeyCode::KeyA) ||
    @input.key_pressed(@window.KeyCode::ArrowLeft) {
    move_direction = move_direction.sub(right)
  }
  if @input.key_pressed(@window.KeyCode::KeyD) ||
    @input.key_pressed(@window.KeyCode::ArrowRight) {
    move_direction = move_direction.add(right)
  }
  if @input.key_pressed(@window.KeyCode::KeyE) {
    move_direction = move_direction.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if @input.key_pressed(@window.KeyCode::KeyQ) {
    move_direction = move_direction.sub(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }

  let mut position = physics3d_showcase_state.val.camera_position
  if move_direction.length_squared() > 0.000001F {
    let delta_seconds = clamp_float(@time.time_delta_seconds(), 0.0F, 0.05F)
    let delta = move_direction
      .normalize_or_zero()
      .mul_scalar(CAMERA_MOVE_SPEED * delta_seconds)
    position = position.add(delta)
  }

  let transform = @math.Transform::from_xyz(position.x, position.y, position.z).looking_at(
    position.add(forward),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let tick = world.read_change_tick()
  world.get_transform_store().insert(camera_entity, transform, tick)

  physics3d_showcase_state.val.camera_position = position
  physics3d_showcase_state.val.camera_yaw = yaw
  physics3d_showcase_state.val.camera_pitch = pitch
}

///|
fn physics3d_showcase_overlay_system(_world : @ecs_world.World) -> Unit {
  if physics3d_showcase_state.val.overlay_spawned {
    return
  }
  guard physics3d_showcase_state.val.overlay_font is Some(font) else { return }
  if @asset.asset_font_read_bytes(font) is None {
    return
  }
  if @text.font_rasterize_glyph(
      font,
      20.0F,
      'A'.to_int(),
      @text.FontSmoothing::AntiAliased,
    )
    is None ||
    @text.font_rasterize_glyph(
      font,
      20.0F,
      'a'.to_int(),
      @text.FontSmoothing::AntiAliased,
    )
    is None ||
    @text.font_rasterize_glyph(
      font,
      20.0F,
      '0'.to_int(),
      @text.FontSmoothing::AntiAliased,
    )
    is None {
    return
  }
  let content = "Physics3D Showcase Controls\nRight Mouse: Look around\nW/A/S/D or Arrow Keys: Move camera\nQ/E: Move down/up   R: Reset camera\nLeft Click / Space: Spawn impact body\nHold F: Auto spawn stream\nKinematic sweeper + sensor stats active"
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(20.0F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-470.0F, 330.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=40.0F,
    ),
  )
  .with_anchor(@render2d.Anchor::top_left())
  .with_bounds(@text.TextBounds::new_horizontal(920.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .with_color(
    @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore
  physics3d_showcase_state.val.overlay_spawned = true
}

///|
fn physics3d_showcase_spawn_controls(world : @ecs_world.World) -> Unit {
  if @input.mouse_button_just_pressed(@window.MouseButton::Left) ||
    @input.key_just_pressed(@window.KeyCode::Space) {
    spawn_impact_body(world)
  }

  if @input.key_pressed(@window.KeyCode::KeyF) {
    let time_now = @time.time_elapsed_seconds()
    if time_now >= physics3d_showcase_state.val.next_auto_fire_time {
      spawn_impact_body(world)
      physics3d_showcase_state.val.next_auto_fire_time = time_now + 0.12F
    }
  }
}

///|
fn physics3d_showcase_events_and_stats(world : @ecs_world.World) -> Unit {
  let sensor_zone = physics3d_showcase_state.val.sensor_zone
  let events_resource = world.get_physics3d_events_resource()
  if events_resource.get_ref() is Some(events_ref) {
    for event in events_ref.val.collisions {
      match event {
        @physics3d.CollisionEvent3d::Started(entity_a, entity_b, is_sensor) => {
          physics3d_showcase_state.val.collision_started = physics3d_showcase_state.val.collision_started +
            1
          if is_sensor && sensor_zone is Some(sensor_entity) {
            if entity_eq(entity_a, sensor_entity) ||
              entity_eq(entity_b, sensor_entity) {
              physics3d_showcase_state.val.sensor_entered = physics3d_showcase_state.val.sensor_entered +
                1
              println(
                "sensor enter: a=" +
                entity_a.id.to_string() +
                ", b=" +
                entity_b.id.to_string(),
              )
            }
          }
        }
        @physics3d.CollisionEvent3d::Stopped(entity_a, entity_b, is_sensor) =>
          if is_sensor && sensor_zone is Some(sensor_entity) {
            if entity_eq(entity_a, sensor_entity) ||
              entity_eq(entity_b, sensor_entity) {
              physics3d_showcase_state.val.sensor_left = physics3d_showcase_state.val.sensor_left +
                1
            }
          }
      }
    }
  }

  let time_now = @time.time_elapsed_seconds()
  if time_now - physics3d_showcase_state.val.last_stats_print_time >= 1.0F {
    physics3d_showcase_state.val.last_stats_print_time = time_now
    println(
      "physics3d_showcase stats: spawned=" +
      physics3d_showcase_state.val.spawn_serial.to_string() +
      ", started=" +
      physics3d_showcase_state.val.collision_started.to_string() +
      ", sensor_entered=" +
      physics3d_showcase_state.val.sensor_entered.to_string() +
      ", sensor_left=" +
      physics3d_showcase_state.val.sensor_left.to_string(),
    )
  }
}
