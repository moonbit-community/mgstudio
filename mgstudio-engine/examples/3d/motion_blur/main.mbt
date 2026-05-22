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
///
/// Parity target: keep upstream camera controls (`shutter_angle`, `samples`),
/// camera-mode switching, scene geometry, generated ground texture, and
/// sampler behavior aligned with Bevy's `examples/3d/motion_blur.rs`.

///|
const TWO_PI : Float = 6.283185307179586F

///|
const N_CARS : Int = 20

///|
const N_CONES : Int = 100

///|
const N_TREES : Int = 30

///|
const TEXTURE_SIZE : Int = 7

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
  mut help_text : @core.Entity?
  car_bodies : Array[CarBody]
  wheels : Array[WheelState]
  mut camera_mode : CameraMode
  mut shutter_angle : Float
  mut samples : Int
}

///|
let motion_blur_state : Ref[MotionBlurExampleState] = Ref({
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
  let rounded = (value * 100.0F).round().to_int()
  let whole = rounded / 100
  let fractional = rounded.abs() % 100
  let prefix = if fractional < 10 { "0" } else { "" }
  "\{whole}.\{prefix}\{fractional}"
}

///|
fn byte_from_int(value : Int) -> Byte {
  value.to_byte()
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
fn help_shutter_text() -> String {
  "Shutter angle: \{float_text_2(motion_blur_state.val.shutter_angle)}\n"
}

///|
fn help_samples_text() -> String {
  "Samples: \{motion_blur_state.val.samples}\n"
}

///|
fn update_help_text(world : @ecs.World) -> Unit {
  guard motion_blur_state.val.help_text is Some(help_text) else { return }
  let writer = @ui.TextUiWriter::new(world)
  writer.set_text(help_text, 1, help_shutter_text()) |> ignore
  writer.set_text(help_text, 2, help_samples_text()) |> ignore
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
  guard (try! world.get_by_key(camera_entity, @pbr.ecs_key_projection))
    is Some(current) else {
    return
  }
  let next_projection = match current {
    Perspective(p) => {
      p.fov = fov
      Some(@camera.Projection::Perspective(p))
    }
    Orthographic(_) => None
    Custom(_) => None
  }
  guard next_projection is Some(projection) else { return }
  try! (world.replace(camera_entity, @pbr.ecs_key_projection, projection)
  |> ignore)
}

///|
fn apply_motion_blur_settings(world : @ecs.World) -> Unit {
  guard motion_blur_state.val.camera is Some(camera) else { return }
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_motion_blur,
    @pbr.MotionBlur::new(
      motion_blur_state.val.shutter_angle,
      motion_blur_state.val.samples,
    ),
  )
}

///|
fn spawn_camera(world : @ecs.World) -> Unit {
  let camera = @camera.Camera3dBundle::new(
    @sprite.Camera::Camera(),
    @transform.Transform::identity(),
  ).spawn(world)
  motion_blur_state.val.camera = Some(camera)
}

///|
fn mesh3d_from_geometry(
  meshes : @asset.Assets[@mesh.Mesh],
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(meshes.add(@mesh.Mesh::from_3d_geometry(geometry)))
}

///|
fn motion_blur_uv_debug_texture(
  images : @asset.Assets[@asset.Image],
) -> @asset.Handle[@asset.Image] {
  let palette : Array[Byte] = [
    byte_from_int(164),
    byte_from_int(164),
    byte_from_int(164),
    byte_from_int(255),
    byte_from_int(168),
    byte_from_int(168),
    byte_from_int(168),
    byte_from_int(255),
    byte_from_int(153),
    byte_from_int(153),
    byte_from_int(153),
    byte_from_int(255),
    byte_from_int(139),
    byte_from_int(139),
    byte_from_int(139),
    byte_from_int(255),
    byte_from_int(153),
    byte_from_int(153),
    byte_from_int(153),
    byte_from_int(255),
    byte_from_int(177),
    byte_from_int(177),
    byte_from_int(177),
    byte_from_int(255),
    byte_from_int(159),
    byte_from_int(159),
    byte_from_int(159),
    byte_from_int(255),
  ]
  let texture_data : Array[Byte] = []
  for _y in 0..<TEXTURE_SIZE {
    for i in 0..<palette.length() {
      texture_data.push(palette[i])
    }
    let tail : Array[Byte] = []
    for i in (palette.length() - 12)..<palette.length() {
      tail.push(palette[i])
    }
    let mut index = palette.length() - 1
    while index >= 12 {
      palette[index] = palette[index - 12]
      index = index - 1
    }
    for i in 0..<tail.length() {
      palette[i] = tail[i]
    }
  }
  let image = @asset.Image::new(
    TEXTURE_SIZE,
    TEXTURE_SIZE,
    Bytes::from_array(texture_data),
  ).with_format(Rgba8UnormSrgb)
  let handle = images.add(image)
  let sampler = @asset.ImageSamplerDescriptor::linear()
  sampler.address_mode_u = @asset.ImageAddressMode::Repeat
  sampler.address_mode_v = @asset.ImageAddressMode::MirrorRepeat
  sampler.mag_filter = @asset.ImageFilterMode::Nearest
  @asset.asset_set_texture_sampler(
    handle,
    @asset.ImageSampler::Descriptor(sampler),
  )
  handle
}

///|
fn spawn_help_text_span(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
) -> @core.Entity {
  let span_entity = world.spawn_empty()
  try! world.set_by_key(
    span_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    span_entity,
    @text.ecs_key_text_span,
    @text.TextSpan::new(content),
  )
  span_entity
}

///|
fn spawn_help_text(world : @ecs.World) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::Camera().with_order(100).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::UiRoot())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(text_entity, @text.ecs_key_text, @text.Text::Text())
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont(),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::TextColor(),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::TextLayout(),
  )
  motion_blur_state.val.help_text = Some(text_entity)
  spawn_help_text_span(world, text_entity, "") |> ignore
  spawn_help_text_span(world, text_entity, "") |> ignore
  spawn_help_text_span(
    world, text_entity, "1/2: -/+ shutter angle (blur amount)\n",
  )
  |> ignore
  spawn_help_text_span(
    world, text_entity, "3/4: -/+ sample count (blur quality)\n",
  )
  |> ignore
  spawn_help_text_span(world, text_entity, "Spacebar: cycle camera\n") |> ignore
}

///|
fn spawn_car(
  world : @ecs.World,
  body_mesh : @mesh.Mesh3d,
  wheel_mesh : @mesh.Mesh3d,
  car_material : @asset.Handle[@pbr.StandardMaterial],
  wheel_material : @asset.Handle[@pbr.StandardMaterial],
  phase : Float,
  tracked : Bool,
) -> Unit {
  let body = @pbr.MeshMaterial3dBundle::new(
    body_mesh,
    @pbr.MeshMaterial3d::new(car_material),
    @transform.Transform::identity().with_scale(
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
  try! world.set_by_key(
    cabin,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(body),
  )

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
    try! world.set_by_key(
      wheel,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(body),
    )
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
  mesh : @mesh.Mesh3d,
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
  leaves_mesh : @mesh.Mesh3d,
  trunk_mesh : @mesh.Mesh3d,
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
  let mesh_assets = @pbr.mesh_assets_mut_or_abort().val
  let image_assets_ref : @ecs.ResourceMut[@asset.Assets[@asset.Image]] = @asset.asset_assets_ref_mut_or_abort()
  let image_assets = image_assets_ref.peek()

  let directional_light = world.spawn_empty()
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 3000.0F, true),
  )
  try! world.set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).looking_at(
      @math.Vec3::new(-1.0F, -0.7F, -1.0F),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
    ),
  )

  let sphere_mesh = mesh3d_from_geometry(
    mesh_assets,
    @mesh_primitives_dim3.SphereMeshBuilder::SphereMeshBuilder().build(),
  )
  let sky_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.1F, 0.6F, 1.0F, 1.0F),
    ).with_unlit(true),
  )
  @pbr.MeshMaterial3dBundle::new(
    sphere_mesh,
    @pbr.MeshMaterial3d::new(sky_material),
    @transform.Transform::identity().with_scale(@math.Vec3::splat(-4000.0F)),
  ).spawn(world)
  |> ignore

  let ground_geometry = @mesh_primitives_dim3.PlaneMeshBuilder::PlaneMeshBuilder().build()
  ignore(
    ground_geometry.replace_uvs([
      @math.Vec2::new(4000.0F, 0.0F),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(0.0F, 4000.0F),
      @math.Vec2::new(4000.0F, 4000.0F),
    ]),
  )
  let ground_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_perceptual_roughness(1.0F)
    .with_base_color_texture(Some(motion_blur_uv_debug_texture(image_assets))),
  )
  @pbr.MeshMaterial3dBundle::new(
    mesh3d_from_geometry(mesh_assets, ground_geometry),
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

  let car_body_mesh = mesh3d_from_geometry(
    mesh_assets,
    @mesh_primitives_dim3.CuboidMeshBuilder::new(0.3F, 0.15F, 0.55F).build(),
  )
  let wheel_mesh = mesh3d_from_geometry(
    mesh_assets,
    @mesh_primitives_dim3.CylinderMeshBuilder::CylinderMeshBuilder().build(),
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
      @sprite.Color::srgb(1.0F, 87.0F / 255.0F, 51.0F / 255.0F),
    ).with_reflectance(1.0F),
  )
  spawn_barriers(
    world,
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.Capsule3dMeshBuilder::Capsule3dMeshBuilder().build(),
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
  let leaves_mesh = mesh3d_from_geometry(
    mesh_assets,
    @mesh_primitives_dim3.SphereMeshBuilder::SphereMeshBuilder().build(),
  )
  let trunk_mesh = mesh3d_from_geometry(
    mesh_assets,
    @mesh_primitives_dim3.Capsule3dMeshBuilder::Capsule3dMeshBuilder().build(),
  )
  spawn_trees(world, leaves_mesh, trunk_mesh, leaves_material, trunk_material)
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
  spawn_help_text(world)
  apply_motion_blur_settings(world)
  update_help_text(world)
}

///|
fn keyboard_inputs(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    motion_blur_state.val.shutter_angle = motion_blur_state.val.shutter_angle -
      0.25F
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    motion_blur_state.val.shutter_angle = motion_blur_state.val.shutter_angle +
      0.25F
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    motion_blur_state.val.samples = motion_blur_state.val.samples - 1
  } else if @input.key_just_pressed(@window.KeyCode::Digit4) {
    motion_blur_state.val.samples = motion_blur_state.val.samples + 1
  } else if @input.key_just_pressed(@window.KeyCode::Space) {
    toggle_camera_mode()
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

  apply_motion_blur_settings(world)
  update_help_text(world)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match world.get_resource(@time.default_time_resource_key) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in motion_blur example")
  }
}

///|
fn move_cars(world : @ecs.World) -> Unit {
  if motion_blur_state.val.car_bodies.length() == 0 {
    return
  }
  let now = world_time(world).elapsed_seconds() * 0.25F
  for car in motion_blur_state.val.car_bodies {
    guard (try! world.get_by_key(car.entity, @transform.ecs_key_transform))
      is Some(current_transform) else {
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
      next_transform = next_transform.looking_to(
        delta,
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      )
    }
    try! (world.replace(
      car.entity,
      @transform.ecs_key_transform,
      next_transform,
    )
    |> ignore)

    let distance = delta.length()
    for i in car.wheel_start..<(car.wheel_start + car.wheel_count) {
      let wheel = motion_blur_state.val.wheels[i]
      guard (try! world.get_by_key(wheel.entity, @transform.ecs_key_transform))
        is Some(wheel_transform) else {
        continue
      }
      if wheel.radius <= 1.0e-6F {
        continue
      }
      let angle = distance / wheel.radius
      let next_rotation = wheel_transform.rotation
        .mul(@math.Quat::from_rotation_y(angle))
        .normalize()
      try! (world.replace(
        wheel.entity,
        @transform.ecs_key_transform,
        wheel_transform.with_rotation(next_rotation),
      )
      |> ignore)
    }
  }
}

///|
fn move_camera(world : @ecs.World) -> Unit {
  guard motion_blur_state.val.camera is Some(camera_entity) else { return }
  guard motion_blur_state.val.tracked_car is Some(tracked_entity) else {
    return
  }
  guard (try! world.get_by_key(tracked_entity, @transform.ecs_key_transform))
    is Some(tracked_transform) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(current_camera_transform) else {
    return
  }
  let up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  match motion_blur_state.val.camera_mode {
    Track => {
      let next_transform = current_camera_transform
        .looking_at(tracked_transform.translation, up)
        .with_translation(@math.Vec3::new(15.0F, -0.5F, 0.0F))
      try! (world.replace(
        camera_entity, @transform.ecs_key_transform, next_transform,
      )
      |> ignore)
      set_camera_fov(world, camera_entity, 0.05F)
    }
    Chase => {
      let next_transform = current_camera_transform
        .with_translation(
          tracked_transform.translation
          .add(@math.Vec3::new(0.0F, 0.15F, 0.0F))
          .add(tracked_transform.back().mul_scalar(0.6F)),
        )
        .looking_to(tracked_transform.forward(), up)
      try! (world.replace(
        camera_entity, @transform.ecs_key_transform, next_transform,
      )
      |> ignore)
      set_camera_fov(world, camera_entity, 1.0F)
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@dev_tools_ci_testing.CiTestingPlugin::CiTestingPlugin())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    (
      @app.system(keyboard_inputs),
      @app.system(move_cars),
      @app.system(move_camera),
    )
    |> @app.chain(),
  )
  .run()
}
