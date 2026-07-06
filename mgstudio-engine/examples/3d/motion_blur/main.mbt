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
let camera_mode_resource_key : @ecs.ResourceKey[CameraMode] = @ecs.register_resource(
  debug_name="examples.3d.motion_blur.CameraMode",
)

///|
impl @app.Resource for CameraMode with fn resource() {
  camera_mode_resource_key
}

///|
priv struct Moves {
  phase : Float
}

///|
let moves_component_key : @ecs.ComponentKey[Moves] = @ecs.register_component(
  debug_name="examples.3d.motion_blur.Moves",
)

///|
impl @ecs.Component for Moves with fn component() {
  moves_component_key
}

///|
priv struct CameraTracked {}

///|
let camera_tracked_component_key : @ecs.ComponentKey[CameraTracked] = @ecs.register_component(
  debug_name="examples.3d.motion_blur.CameraTracked",
)

///|
impl @ecs.Component for CameraTracked with fn component() {
  camera_tracked_component_key
}

///|
priv struct Rotates {}

///|
let rotates_component_key : @ecs.ComponentKey[Rotates] = @ecs.register_component(
  debug_name="examples.3d.motion_blur.Rotates",
)

///|
impl @ecs.Component for Rotates with fn component() {
  rotates_component_key
}

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
fn toggle_camera_mode(world : @ecs.World) -> Unit {
  let mode_ref = match world.get_resource_mut(CameraMode::resource()) {
    Some(value) => value
    None => return
  }
  mode_ref.set(
    match mode_ref.peek() {
      Track => Chase
      Chase => Track
    },
  )
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
fn help_shutter_text(shutter_angle : Float) -> String {
  "Shutter angle: \{float_text_2(shutter_angle)}\n"
}

///|
fn help_samples_text(samples : UInt) -> String {
  "Samples: \{samples}\n"
}

///|
fn first_text_entity(world : @ecs.World) -> @core.Entity? {
  let mut text_entity : @core.Entity? = None
  try! world
  .query_entities_filtered(@ecs.With::new(@text.ecs_key_text))
  .view(fn(_query_entity, entity) {
    if text_entity is None {
      text_entity = Some(entity)
    }
  })
  text_entity
}

///|
fn first_motion_blur_entity(world : @ecs.World) -> @core.Entity? {
  let mut camera : @core.Entity? = None
  try! world
  .query_entities_filtered(@ecs.With::new(@pbr.ecs_key_motion_blur))
  .view(fn(_query_entity, entity) {
    if camera is None {
      camera = Some(entity)
    }
  })
  camera
}

///|
fn first_camera_entity(world : @ecs.World) -> @core.Entity? {
  let mut camera : @core.Entity? = None
  try! world
  .query_entities_filtered(
    (
      @ecs.With::new(@camera.Camera::component()),
      @ecs.With::new(@camera.ecs_key_camera3d),
      @ecs.Without::new(CameraTracked::component()),
    ),
  )
  .view(fn(_query_entity, entity) {
    if camera is None {
      camera = Some(entity)
    }
  })
  camera
}

///|
fn first_tracked_entity(world : @ecs.World) -> @core.Entity? {
  let mut tracked : @core.Entity? = None
  try! world
  .query_entities_filtered(@ecs.With::new(CameraTracked::component()))
  .view(fn(_query_entity, entity) {
    if tracked is None {
      tracked = Some(entity)
    }
  })
  tracked
}

///|
fn update_help_text(world : @ecs.World, motion_blur : @pbr.MotionBlur) -> Unit {
  guard first_text_entity(world) is Some(help_text) else { return }
  let writer = @ui.TextUiWriter::new(world)
  writer.set_text(help_text, 1, help_shutter_text(motion_blur.shutter_angle))
  |> ignore
  writer.set_text(help_text, 2, help_samples_text(motion_blur.samples))
  |> ignore
}

///|
fn set_global_ambient_light(world : @ecs.World, brightness : Float) -> Unit {
  let value = @pbr.GlobalAmbientLight::new(@color.Color::white(), brightness)
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
fn setup_camera(world : @ecs.World) -> Unit {
  let camera = @camera.Camera3dBundle::new(
    @camera_camera.Camera::Camera(),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_motion_blur,
    @pbr.MotionBlur::new(1.0F, 2U),
  )
}

///|
fn mesh3d_from_geometry(
  meshes : @ecs.ResourceMut[@asset.Assets[@mesh.Mesh]],
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(
    meshes.modify(fn(assets) {
      assets.add(@mesh.Mesh::from_3d_geometry(geometry))
    }),
  )
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
fn setup_ui(world : @ecs.World) -> Unit {
  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)

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
    @pbr.MeshMaterial3dTyped::new(car_material),
    @transform.Transform::identity().with_scale(
      @math.Vec3::new(0.5F, 0.5F, 0.5F),
    ),
  ).spawn(world)
  try! world.set_by_key(body, Moves::component(), Moves::{ phase, })
  if tracked {
    try! world.set_by_key(body, CameraTracked::component(), CameraTracked::{  })
  }

  let cabin = @pbr.MeshMaterial3dBundle::new(
    body_mesh,
    @pbr.MeshMaterial3dTyped::new(car_material),
    @transform.Transform::from_xyz(0.0F, 0.08F, 0.03F).with_scale(
      @math.Vec3::new(1.0F, 1.0F, 0.5F),
    ),
  ).spawn(world)
  try! world.set_by_key(
    cabin,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(body),
  )

  let wheel_offsets = [
    @math.Vec3::new(0.14F, -0.045F, 0.15F),
    @math.Vec3::new(0.14F, -0.045F, -0.15F),
    @math.Vec3::new(-0.14F, -0.045F, 0.15F),
    @math.Vec3::new(-0.14F, -0.045F, -0.15F),
  ]
  for offset in wheel_offsets {
    let wheel = @pbr.MeshMaterial3dBundle::new(
      wheel_mesh,
      @pbr.MeshMaterial3dTyped::new(wheel_material),
      @transform.Transform::from_xyz(offset.x, offset.y, offset.z)
      .with_scale(@math.Vec3::new(0.15F, 0.04F, 0.15F))
      .with_rotation(@math.Quat::from_rotation_z(@math.pi_half())),
    ).spawn(world)
    try! world.set_by_key(
      wheel,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(body),
    )
    try! world.set_by_key(wheel, Rotates::component(), Rotates::{  })
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
        @pbr.MeshMaterial3dTyped::new(material),
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
        @pbr.MeshMaterial3dTyped::new(leaves_material),
        @transform.Transform::from_xyz(pos.x, -0.3F, pos.y).with_scale(
          @math.Vec3::splat(0.3F),
        ),
      ).spawn(world)
      |> ignore
      @pbr.MeshMaterial3dBundle::new(
        trunk_mesh,
        @pbr.MeshMaterial3dTyped::new(trunk_material),
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
  world.insert_resource(CameraMode::resource(), CameraMode::Chase)
  let mesh_assets = @pbr.mesh_assets_mut_or_abort()
  let image_assets_ref : @ecs.ResourceMut[@asset.Assets[@asset.Image]] = @asset.asset_assets_ref_mut_or_abort()
  let image_assets = image_assets_ref.peek()

  let directional_light = world.spawn_empty()
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@color.Color::white(), 3000.0F, true),
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
    @pbr.StandardMaterial::from_color(@color.Color::new(0.1F, 0.6F, 1.0F, 1.0F)).with_unlit(
      true,
    ),
  )
  @pbr.MeshMaterial3dBundle::new(
    sphere_mesh,
    @pbr.MeshMaterial3dTyped::new(sky_material),
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
    @pbr.StandardMaterial::from_color(@color.Color::white())
    .with_perceptual_roughness(1.0F)
    .with_base_color_texture(Some(motion_blur_uv_debug_texture(image_assets))),
  )
  @pbr.MeshMaterial3dBundle::new(
    mesh3d_from_geometry(mesh_assets, ground_geometry),
    @pbr.MeshMaterial3dTyped::new(ground_material),
    @transform.Transform::from_xyz(0.0F, -0.65F, 0.0F).with_scale(
      @math.Vec3::splat(80.0F),
    ),
  ).spawn(world)
  |> ignore

  let car_colors : Array[@color.Color] = [
    @color.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    @color.Color::new(1.0F, 1.0F, 0.0F, 1.0F),
    @color.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    @color.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    @color.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    @color.Color::new(1.0F, 0.0F, 1.0F, 1.0F),
    @color.Color::new(0.5F, 0.5F, 0.0F, 1.0F),
    @color.Color::new(1.0F, 0.5F, 0.0F, 1.0F),
  ]
  let car_materials : Array[@asset.Handle[@pbr.StandardMaterial]] = []
  for color in car_colors {
    car_materials.push(
      @pbr.standard_material_add(@pbr.StandardMaterial::from_color(color)),
    )
  }
  let wheel_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@color.Color::white()).with_base_color_texture(
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
      @color.Color::srgb(1.0F, 87.0F / 255.0F, 51.0F / 255.0F),
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
    @pbr.StandardMaterial::from_color(@color.Color::new(0.0F, 1.0F, 0.0F, 1.0F)),
  )
  let trunk_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@color.Color::new(0.4F, 0.2F, 0.2F, 1.0F)),
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
fn setup_scene_system(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  spawn_scene(world, asset_server)
}

///|
fn keyboard_inputs(world : @ecs.World) -> Unit {
  guard first_motion_blur_entity(world) is Some(camera) else { return }
  guard (try! world.get_by_key(camera, @pbr.ecs_key_motion_blur))
    is Some(motion_blur) else {
    return
  }
  let mut shutter_angle = motion_blur.shutter_angle
  let mut samples = motion_blur.samples.reinterpret_as_int()
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    shutter_angle = shutter_angle - 0.25F
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    shutter_angle = shutter_angle + 0.25F
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    samples = samples - 1
  } else if @input.key_just_pressed(@window.KeyCode::Digit4) {
    samples = samples + 1
  } else if @input.key_just_pressed(@window.KeyCode::Space) {
    toggle_camera_mode(world)
  }

  shutter_angle = clampf(shutter_angle, 0.0F, 1.0F)
  if samples < 0 {
    samples = 0
  } else if samples > 64 {
    samples = 64
  }
  let next_motion_blur = @pbr.MotionBlur::new(
    shutter_angle,
    samples.reinterpret_as_uint(),
  )

  try! (world.replace(camera, @pbr.ecs_key_motion_blur, next_motion_blur)
  |> ignore)
  update_help_text(world, next_motion_blur)
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
  let now = world_time(world).elapsed_seconds() * 0.25F
  let car_entities : Array[@core.Entity] = []
  try! world
  .query_entities_filtered(@ecs.With::new(Moves::component()))
  .view(fn(_query_entity, entity) { car_entities.push(entity) })
  for car_entity in car_entities {
    guard (try! world.get_by_key(car_entity, Moves::component())) is Some(moves) else {
      continue
    }
    guard (try! world.get_by_key(car_entity, @transform.ecs_key_transform))
      is Some(current_transform) else {
      continue
    }
    let t0 = now + 0.5F * moves.phase
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
      car_entity, @transform.ecs_key_transform, next_transform,
    )
    |> ignore)

    let distance = delta.length()
    guard (try! world.get_by_key(car_entity, @hierarchy.ecs_key_children))
      is Some(children) else {
      continue
    }
    for wheel_entity in children.entities() {
      if !(try! world.contains_by_key(wheel_entity, Rotates::component())) {
        continue
      }
      if (try! world.contains_by_key(wheel_entity, Moves::component())) {
        continue
      }
      guard (try! world.get_by_key(wheel_entity, @transform.ecs_key_transform))
        is Some(wheel_transform) else {
        continue
      }
      let radius = wheel_transform.scale.x
      if radius <= 1.0e-6F {
        continue
      }
      let circumference = TWO_PI * radius
      let angle = distance / circumference * TWO_PI
      let next_wheel_transform = wheel_transform
      next_wheel_transform.rotate_local_y(angle)
      try! (world.replace(
        wheel_entity, @transform.ecs_key_transform, next_wheel_transform,
      )
      |> ignore)
    }
  }
}

///|
fn move_camera(world : @ecs.World) -> Unit {
  guard first_camera_entity(world) is Some(camera_entity) else { return }
  guard first_tracked_entity(world) is Some(tracked_entity) else { return }
  guard (try! world.get_by_key(tracked_entity, @transform.ecs_key_transform))
    is Some(tracked_transform) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(current_camera_transform) else {
    return
  }
  let up = @math.Vec3::new(0.0F, 1.0F, 0.0F)
  let camera_mode = match world.get_resource(CameraMode::resource()) {
    Some(value) => value
    None => CameraMode::Chase
  }
  match camera_mode {
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
  .add_systems(
    @app.Startup,
    (
      @app.system_config_world(setup_camera),
      @app.system_config_world(setup_scene_system),
      @app.system_config_world(setup_ui),
    )
    |> @app.chain(),
  )
  .add_systems(
    @app.Update,
    (
      @app.system_config_world(keyboard_inputs),
      @app.system_config_world(move_cars),
      @app.system_config_world(move_camera),
    )
    |> @app.chain(),
  )
  .run()
}
