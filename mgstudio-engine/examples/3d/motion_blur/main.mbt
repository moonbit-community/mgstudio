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
/// Port of `bevy/examples/3d/motion_blur.rs`.
///
/// Parity target: keep Bevy camera controls (`shutter_angle`, `samples`,
/// camera-mode switching) and enforce the same MSAA-off compatibility path used
/// by Bevy for web constraints.

///|
const TWO_PI : Float = 6.283185307179586F

///|
const N_CARS : Int = 20

///|
const N_CONES : Int = 100

///|
const N_TREES : Int = 30

///|
pub(all) enum CameraMode {
  Track
  Chase
}

///|
priv struct CarBody {
  entity : @core.Entity
  phase : Float
  wheel_start : Int
  wheel_count : Int
}

///|
priv struct WheelState {
  entity : @core.Entity
  radius : Float
}

///|
priv struct MotionBlurExampleState {
  mut camera : @core.Entity?
  mut tracked_car : @core.Entity?
  mut help_text : @text.TextHandle?
  car_bodies : Array[CarBody]
  wheels : Array[WheelState]
  mut camera_mode : CameraMode
  mut shutter_angle : Float
  mut samples : Int
}

///|
let motion_blur_state : Ref[MotionBlurExampleState] = Ref::new({
  camera: None,
  tracked_car: None,
  help_text: None,
  car_bodies: [],
  wheels: [],
  camera_mode: CameraMode::Chase,
  shutter_angle: 1.0F,
  samples: 2,
})

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn float_text_2(value : Float) -> String {
  let rounded = (value * 100.0F).round() / 100.0F
  "\{rounded}"
}

///|
fn camera_mode_text(mode : CameraMode) -> String {
  match mode {
    Track => "Track"
    Chase => "Chase"
  }
}

///|
fn toggle_camera_mode() -> Unit {
  motion_blur_state.val.camera_mode = match motion_blur_state.val.camera_mode {
    Track => Chase
    Chase => Track
  }
}

///|
fn race_track_pos(offset : Float, t : Float) -> @math.Vec2 {
  let x_tweak = 2.0F
  let y_tweak = 3.0F
  let scale = 8.0F
  let x0 = @math.sin(x_tweak * t)
  let y0 = @math.cos(y_tweak * t)
  let dx = x_tweak * @math.cos(x_tweak * t)
  let dy = y_tweak * -@math.sin(y_tweak * t)
  let dl = @math.sqrt(dx * dx + dy * dy)
  if dl <= 1.0e-6F {
    return @math.Vec2::new(x0 * scale, y0 * scale)
  }
  let x = x0 + offset * dy / dl
  let y = y0 - offset * dx / dl
  @math.Vec2::new(x * scale, y * scale)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn transform_forward(transform : @transform.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
fn help_text_content() -> String {
  "Shutter angle: \{float_text_2(motion_blur_state.val.shutter_angle)}\n" +
  "Samples: \{motion_blur_state.val.samples}\n" +
  "Camera mode: \{camera_mode_text(motion_blur_state.val.camera_mode)}\n" +
  "MSAA: Off (Bevy web compatibility path)\n" +
  "1/2: -/+ shutter angle (blur amount)\n" +
  "3/4: -/+ sample count (blur quality)\n" +
  "Spacebar: cycle camera\n"
}

///|
fn update_help_text() -> Unit {
  guard motion_blur_state.val.help_text is Some(help_text) else { return }
  @text.text_set_content(help_text, help_text_content())
}

///|
fn set_global_ambient_light(world : @ecs.World, brightness : Float) -> Unit {
  let value = @pbr.GlobalAmbientLight::new(@sprite.Color::white(), brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, value)
}

///|
fn set_camera_fov(
  world : @ecs.World,
  camera_entity : @core.Entity,
  fov : Float,
) -> Unit {
  let projection_store = world.component(@pbr.ecs_key_projection)
  guard projection_store.get(camera_entity) is Some(current) else { return }
  let next_projection = match current {
    Perspective(p) => {
      p.fov = fov
      Some(@pbr.Projection::Perspective(p))
    }
    Orthographic(_) => None
    Custom(_) => None
  }
  guard next_projection is Some(projection) else { return }
  projection_store.set(camera_entity, projection, world.read_sequence())
  |> ignore
}

///|
fn apply_motion_blur_settings(world : @ecs.World) -> Unit {
  guard motion_blur_state.val.camera is Some(camera_entity) else { return }
  let tick = world.read_sequence()
  let motion_blur = @post_process.MotionBlur::new(
    motion_blur_state.val.shutter_angle,
    motion_blur_state.val.samples,
  )
  let store = world.component(@post_process.ecs_key_motion_blur)
  if store.contains(camera_entity) {
    store.set(camera_entity, motion_blur, tick) |> ignore
  } else {
    store.insert(camera_entity, motion_blur, tick)
  }
}

///|
fn spawn_camera(world : @ecs.World) -> Unit {
  let camera = @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(15.0F, -0.5F, 0.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_motion_blur(
      Some(
        @post_process.MotionBlur::new(
          motion_blur_state.val.shutter_angle,
          motion_blur_state.val.samples,
        ),
      ),
    )
    .spawn(world)
  world
  .component(@pbr.ecs_key_msaa)
  .insert(camera, @pbr.Msaa::Off, world.read_sequence())
  motion_blur_state.val.camera = Some(camera)
}

///|
fn spawn_help_text(asset_server : @asset.AssetServer) -> Unit {
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  motion_blur_state.val.help_text = Some(handle)
}

///|
fn spawn_car(
  world : @ecs.World,
  body_mesh : @pbr.Mesh3d,
  wheel_mesh : @pbr.Mesh3d,
  car_material : @asset.Handle[@pbr.StandardMaterial],
  wheel_material : @asset.Handle[@pbr.StandardMaterial],
  phase : Float,
  tracked : Bool,
) -> Unit {
  let tick = world.read_sequence()
  let body = @pbr.MeshMaterial3dBundle::new(
    body_mesh,
    @pbr.MeshMaterial3d::new(car_material),
    @transform.Transform::from_xyz(0.0F, -0.59F, 0.0F).with_scale(
      @math.Vec3::new(0.5F, 0.5F, 0.5F),
    ),
  ).spawn(world)

  let cabin = @pbr.MeshMaterial3dBundle::new(
    body_mesh,
    @pbr.MeshMaterial3d::new(car_material),
    @transform.Transform::from_xyz(0.0F, 0.08F, 0.03F).with_scale(
      @math.Vec3::new(1.0F, 1.0F, 0.5F),
    ),
  ).spawn(world)
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(cabin, @hierarchy.Parent::new(body), tick)

  let wheel_start = motion_blur_state.val.wheels.length()
  let wheel_offsets = [
    @math.Vec3::new(0.14F, -0.045F, 0.15F),
    @math.Vec3::new(0.14F, -0.045F, -0.15F),
    @math.Vec3::new(-0.14F, -0.045F, 0.15F),
    @math.Vec3::new(-0.14F, -0.045F, -0.15F),
  ]
  for offset in wheel_offsets {
    let wheel = @pbr.MeshMaterial3dBundle::new(
      wheel_mesh,
      @pbr.MeshMaterial3d::new(wheel_material),
      @transform.Transform::from_xyz(offset.x, offset.y, offset.z)
      .with_scale(@math.Vec3::new(0.15F, 0.04F, 0.15F))
      .with_rotation(@math.Quat::from_rotation_z(@math.pi_half())),
    ).spawn(world)
    world
    .component(@hierarchy.ecs_key_parent)
    .insert(wheel, @hierarchy.Parent::new(body), tick)
    motion_blur_state.val.wheels.push({ entity: wheel, radius: 0.15F })
  }

  motion_blur_state.val.car_bodies.push({
    entity: body,
    phase,
    wheel_start,
    wheel_count: 4,
  })
  if tracked {
    motion_blur_state.val.tracked_car = Some(body)
  }
}

///|
fn spawn_barriers(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
) -> Unit {
  for side in [0, 1] {
    let offset = if side == 0 { 0.04F } else { -0.04F }
    for i in 0..<N_CONES {
      let t = Float::from_double(i.to_double()) /
        Float::from_double(N_CONES.to_double()) *
        TWO_PI
      let pos = race_track_pos(offset, t)
      @pbr.MeshMaterial3dBundle::new(
        mesh,
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(pos.x, -0.65F, pos.y).with_scale(
          @math.Vec3::splat(0.07F),
        ),
      ).spawn(world)
      |> ignore
    }
  }
}

///|
fn spawn_trees(
  world : @ecs.World,
  leaves_mesh : @pbr.Mesh3d,
  trunk_mesh : @pbr.Mesh3d,
  leaves_material : @asset.Handle[@pbr.StandardMaterial],
  trunk_material : @asset.Handle[@pbr.StandardMaterial],
) -> Unit {
  for side in [0, 1] {
    let offset = if side == 0 { 0.07F } else { -0.07F }
    for i in 0..<N_TREES {
      let t = Float::from_double(i.to_double()) /
        Float::from_double(N_TREES.to_double()) *
        TWO_PI
      let pos = race_track_pos(offset, t)
      @pbr.MeshMaterial3dBundle::new(
        leaves_mesh,
        @pbr.MeshMaterial3d::new(leaves_material),
        @transform.Transform::from_xyz(pos.x, -0.3F, pos.y).with_scale(
          @math.Vec3::splat(0.3F),
        ),
      ).spawn(world)
      |> ignore
      @pbr.MeshMaterial3dBundle::new(
        trunk_mesh,
        @pbr.MeshMaterial3d::new(trunk_material),
        @transform.Transform::from_xyz(pos.x, -0.5F, pos.y).with_scale(
          @math.Vec3::new(0.05F, 0.3F, 0.05F),
        ),
      ).spawn(world)
      |> ignore
    }
  }
}

///|
fn spawn_scene(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  set_global_ambient_light(world, 300.0F)
  let tick = world.read_sequence()

  let directional_light = world.spawn_empty()
  world
  .component(@pbr.ecs_key_directional_light)
  .insert(
    directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 3000.0F, true),
    tick,
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(
    directional_light,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).looking_at(
      @math.Vec3::new(-1.0F, -0.7F, -1.0F),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
    ),
    tick,
  )

  let cube_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F)),
    ),
  )
  let sky_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.1F, 0.6F, 1.0F, 1.0F),
    ).with_unlit(true),
  )
  @pbr.MeshMaterial3dBundle::new(
    cube_mesh,
    @pbr.MeshMaterial3d::new(sky_material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_scale(
      @math.Vec3::splat(-4000.0F),
    ),
  ).spawn(world)
  |> ignore

  let icon = asset_server.load("branding/icon.png")
  let ground_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_perceptual_roughness(1.0F)
    .with_base_color_texture(Some(icon))
    .with_uv_transform(
      @transform.Affine2::from_scale(@math.Vec2::new(250.0F, 250.0F)),
    ),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(1.0F, 1.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(ground_material),
    @transform.Transform::from_xyz(0.0F, -0.65F, 0.0F).with_scale(
      @math.Vec3::splat(80.0F),
    ),
  ).spawn(world)
  |> ignore

  let car_colors : Array[@sprite.Color] = [
    @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    @sprite.Color::new(1.0F, 1.0F, 0.0F, 1.0F),
    @sprite.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    @sprite.Color::new(1.0F, 0.0F, 1.0F, 1.0F),
    @sprite.Color::new(0.5F, 0.5F, 0.0F, 1.0F),
    @sprite.Color::new(1.0F, 0.5F, 0.0F, 1.0F),
  ]
  let car_materials : Array[@asset.Handle[@pbr.StandardMaterial]] = []
  for color in car_colors {
    car_materials.push(
      @pbr.standard_material_add(@pbr.StandardMaterial::from_color(color)),
    )
  }
  let wheel_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_base_color_texture(
      Some(asset_server.load("branding/icon.png")),
    ),
  )

  let car_body_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @pbr.mesh3d_geometry_cuboid(0.3F, 0.15F, 0.55F),
      ),
    ),
  )
  let wheel_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F)),
    ),
  )
  for i in 0..<N_CARS {
    let material = car_materials[i % car_materials.length()]
    spawn_car(
      world,
      car_body_mesh,
      wheel_mesh,
      material,
      wheel_material,
      Float::from_double(i.to_double()) * 2.0F,
      i == 0,
    )
  }

  let barrier_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 87.0F / 255.0F, 51.0F / 255.0F, 1.0F),
    ).with_reflectance(1.0F),
  )
  spawn_barriers(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    barrier_material,
  )

  let leaves_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    ),
  )
  let trunk_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.4F, 0.2F, 0.2F, 1.0F),
    ),
  )
  let tree_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F)),
    ),
  )
  spawn_trees(world, tree_mesh, tree_mesh, leaves_material, trunk_material)
}

///|
fn setup(world : @ecs.World) -> Unit {
  motion_blur_state.val.camera = None
  motion_blur_state.val.tracked_car = None
  motion_blur_state.val.help_text = None
  motion_blur_state.val.car_bodies.clear()
  motion_blur_state.val.wheels.clear()
  motion_blur_state.val.camera_mode = CameraMode::Chase
  motion_blur_state.val.shutter_angle = 1.0F
  motion_blur_state.val.samples = 2

  let asset_server = @asset.AssetServer::new()
  spawn_camera(world)
  spawn_scene(world, asset_server)
  spawn_help_text(asset_server)
  apply_motion_blur_settings(world)
  update_help_text()
}

///|
fn keyboard_inputs(world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    motion_blur_state.val.shutter_angle = motion_blur_state.val.shutter_angle -
      0.25F
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    motion_blur_state.val.shutter_angle = motion_blur_state.val.shutter_angle +
      0.25F
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    motion_blur_state.val.samples = motion_blur_state.val.samples - 1
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Digit4) {
    motion_blur_state.val.samples = motion_blur_state.val.samples + 1
    changed = true
  } else if @input.key_just_pressed(@window.KeyCode::Space) {
    toggle_camera_mode()
    changed = true
  }

  motion_blur_state.val.shutter_angle = clampf(
    motion_blur_state.val.shutter_angle,
    0.0F,
    1.0F,
  )
  if motion_blur_state.val.samples < 0 {
    motion_blur_state.val.samples = 0
  } else if motion_blur_state.val.samples > 64 {
    motion_blur_state.val.samples = 64
  }

  if changed {
    apply_motion_blur_settings(world)
    update_help_text()
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in motion_blur example")
  }
}

///|
fn move_cars(world : @ecs.World) -> Unit {
  if motion_blur_state.val.car_bodies.length() == 0 {
    return
  }
  let tick = world.read_sequence()
  let transform_store = world.component(@transform.ecs_key_transform)
  let now = world_time(world).elapsed_seconds() * 0.25F
  for car in motion_blur_state.val.car_bodies {
    guard transform_store.get(car.entity) is Some(current_transform) else {
      continue
    }
    let t0 = now + 0.5F * car.phase
    let dx = @math.cos(t0)
    let dz = -@math.sin(3.0F * t0)
    let speed_variation = @math.sqrt(dx * dx + dz * dz) * 0.15F
    let t = t0 + speed_variation
    let pos = race_track_pos(0.0F, t)
    let next_translation = @math.Vec3::new(pos.x, -0.59F, pos.y)
    let delta = next_translation.sub(current_transform.translation)
    let mut next_transform = current_transform.with_translation(
      next_translation,
    )
    if delta.length_squared() > 1.0e-8F {
      next_transform = next_transform.looking_at(
        next_translation.add(delta),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      )
    }
    transform_store.set(car.entity, next_transform, tick) |> ignore

    let distance = delta.length()
    for i in car.wheel_start..<(car.wheel_start + car.wheel_count) {
      let wheel = motion_blur_state.val.wheels[i]
      guard transform_store.get(wheel.entity) is Some(wheel_transform) else {
        continue
      }
      if wheel.radius <= 1.0e-6F {
        continue
      }
      let angle = distance / wheel.radius
      let next_rotation = wheel_transform.rotation
        .mul(@math.Quat::from_rotation_y(angle))
        .normalize()
      transform_store.set(
        wheel.entity,
        wheel_transform.with_rotation(next_rotation),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn move_camera(world : @ecs.World) -> Unit {
  guard motion_blur_state.val.camera is Some(camera_entity) else { return }
  guard motion_blur_state.val.tracked_car is Some(tracked_entity) else {
    return
  }
  let transform_store = world.component(@transform.ecs_key_transform)
  guard transform_store.get(tracked_entity) is Some(tracked_transform) else {
    return
  }
  guard transform_store.get(camera_entity) is Some(current_camera_transform) else {
    return
  }
  let tick = world.read_sequence()
  let up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  match motion_blur_state.val.camera_mode {
    Track => {
      let next_transform = current_camera_transform
        .with_translation(@math.Vec3::new(15.0F, -0.5F, 0.0F))
        .looking_at(tracked_transform.translation, up)
      transform_store.set(camera_entity, next_transform, tick) |> ignore
      set_camera_fov(world, camera_entity, 0.05F)
    }
    Chase => {
      let forward = transform_forward(tracked_transform)
      let next_transform = current_camera_transform
        .with_translation(
          tracked_transform.translation
          .add(@math.Vec3::new(0.0F, 0.15F, 0.0F))
          .sub(forward.mul_scalar(0.6F)),
        )
        .looking_at(tracked_transform.translation.add(forward), up)
      transform_store.set(camera_entity, next_transform, tick) |> ignore
      set_camera_fov(world, camera_entity, 1.0F)
    }
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(keyboard_inputs))
  .add_systems(@app.Update, @app.system(move_cars))
  .add_systems(@app.Update, @app.system(move_camera))
  .run()
}
