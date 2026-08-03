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
extend CameraRig with @ecs.Component::{component}

///|
extend DespawningPoint with @ecs.Component::{component}

///|
extend FireflyLights with @ecs.Component::{component}

///|
extend InstructionText with @app.Resource::{resource}

///|
extend MousePressed with @app.Resource::{resource}

///|
extend PointCounter with @app.Resource::{resource}

///|
extend PointMaterial with @app.Resource::{resource}

///|
extend PointMesh with @app.Resource::{resource}

///|
extend RandomSource with @app.Resource::{resource}

///|
extend SampledShapes with @app.Resource::{resource}

///|
extend SamplePoint with @ecs.Component::{component}

///|
extend SamplingMode with @app.Resource::{resource}

///|
extend SpawningMode with @app.Resource::{resource}

///|
extend SpawningPoint with @ecs.Component::{component}

///|
extend SpawnQueue with @app.Resource::{resource}

///|
const MAX_CAMERA_DISTANCE : Float = 12.0F

///|
const MIN_CAMERA_DISTANCE : Float = 1.0F

///|
const MAX_POINTS : Int = 3000

///|
const POINTS_PER_FRAME : Int = 3

///|
const ANIMATION_TIME : Float = 1.0F

///|
const SMALL_3D : Float = 0.5F

///|
const BIG_3D : Float = 1.0F

///|
fn distance_between_shapes() -> @math.Vec3 {
  @math.Vec3::new(2.0F, 0.0F, 0.0F)
}

///|
fn inside_point_color() -> @color.Color {
  @color.Color::srgba(0.855F, 1.1F, 0.01F, 1.0F)
}

///|
fn sky_color() -> @color.Color {
  @color.Color::srgb(0.02F, 0.06F, 0.15F)
}

///|
fn cuboid_shape() -> @math.Cuboid {
  { half_size: @math.Vec3::new(SMALL_3D, BIG_3D, SMALL_3D) }
}

///|
fn sphere_shape() -> @math.Sphere {
  { radius: 1.5F * SMALL_3D }
}

///|
fn triangle_shape() -> @math.Triangle3d {
  {
    vertices: [
      @math.Vec3::new(BIG_3D, -BIG_3D * 0.5F, 0.0F),
      @math.Vec3::new(0.0F, BIG_3D, 0.0F),
      @math.Vec3::new(-BIG_3D, -BIG_3D * 0.5F, 0.0F),
    ],
  }
}

///|
fn capsule_shape() -> @math.Capsule3d {
  { radius: SMALL_3D, half_length: SMALL_3D }
}

///|
fn cylinder_shape() -> @math.Cylinder {
  { radius: SMALL_3D, half_height: SMALL_3D }
}

///|
fn tetrahedron_shape() -> @math.Tetrahedron {
  {
    vertices: [
      @math.Vec3::new(-BIG_3D, -BIG_3D * 0.67F, BIG_3D * 0.5F),
      @math.Vec3::new(BIG_3D, -BIG_3D * 0.67F, BIG_3D * 0.5F),
      @math.Vec3::new(0.0F, -BIG_3D * 0.67F, -BIG_3D * 1.17F),
      @math.Vec3::new(0.0F, BIG_3D, 0.0F),
    ],
  }
}

///|
pub(all) enum SamplingMode {
  Interior
  Boundary
} derive(Eq, Debug)

///|
pub(all) enum SpawningMode {
  Manual
  Automatic
} derive(Eq, Debug)

///|
pub(all) enum Shape {
  Cuboid
  Sphere
  Capsule
  Cylinder
  Tetrahedron
  Triangle
} derive(Eq, Debug)

///|
struct SpawnQueue {
  mut count : Int
}

///|
struct PointCounter {
  mut count : Int
}

///|
struct RandomSource {
  rng : @random.Rand
}

///|
struct SampledShape {
  shape : Shape
  translation : @math.Vec3
}

///|
struct SampledShapes {
  shapes : Array[SampledShape]
}

///|
struct PointMesh {
  mesh : @mesh.Mesh3d
}

///|
struct PointMaterial {
  interior : @asset.Handle[@pbr.StandardMaterial]
  boundary : @asset.Handle[@pbr.StandardMaterial]
}

///|
struct MousePressed {
  mut value : Bool
}

///|
struct InstructionText {
  entity : @core.Entity
}

///|
struct SamplePoint {}

///|
struct SpawningPoint {
  mut progress : Float
}

///|
struct DespawningPoint {
  mut progress : Float
}

///|
struct FireflyLights {}

///|
struct CameraRig {
  mut yaw : Float
  mut pitch : Float
  mut distance : Float
  mut target : @math.Vec3
}

///|
let sampling_mode_key : @ecs.ResourceKey[SamplingMode] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.SamplingMode",
)

///|
let spawning_mode_key : @ecs.ResourceKey[SpawningMode] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.SpawningMode",
)

///|
let spawn_queue_key : @ecs.ResourceKey[SpawnQueue] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.SpawnQueue",
)

///|
let point_counter_key : @ecs.ResourceKey[PointCounter] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.PointCounter",
)

///|
let random_source_key : @ecs.ResourceKey[RandomSource] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.RandomSource",
)

///|
let sampled_shapes_key : @ecs.ResourceKey[SampledShapes] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.SampledShapes",
)

///|
let point_mesh_key : @ecs.ResourceKey[PointMesh] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.PointMesh",
)

///|
let point_material_key : @ecs.ResourceKey[PointMaterial] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.PointMaterial",
)

///|
let mouse_pressed_key : @ecs.ResourceKey[MousePressed] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.MousePressed",
)

///|
let instruction_text_key : @ecs.ResourceKey[InstructionText] = @ecs.register_resource(
  debug_name="examples.math.sampling_primitives.InstructionText",
)

///|
let sample_point_key : @ecs.ComponentKey[SamplePoint] = @ecs.register_component(
  debug_name="examples.math.sampling_primitives.SamplePoint",
)

///|
let spawning_point_key : @ecs.ComponentKey[SpawningPoint] = @ecs.register_component(
  debug_name="examples.math.sampling_primitives.SpawningPoint",
)

///|
let despawning_point_key : @ecs.ComponentKey[DespawningPoint] = @ecs.register_component(
  debug_name="examples.math.sampling_primitives.DespawningPoint",
)

///|
let firefly_lights_key : @ecs.ComponentKey[FireflyLights] = @ecs.register_component(
  debug_name="examples.math.sampling_primitives.FireflyLights",
)

///|
let camera_rig_key : @ecs.ComponentKey[CameraRig] = @ecs.register_component(
  debug_name="examples.math.sampling_primitives.CameraRig",
)

///|
impl @app.Resource for SamplingMode with fn resource() {
  sampling_mode_key
}

///|
impl @app.Resource for SpawningMode with fn resource() {
  spawning_mode_key
}

///|
impl @app.Resource for SpawnQueue with fn resource() {
  spawn_queue_key
}

///|
impl @app.Resource for PointCounter with fn resource() {
  point_counter_key
}

///|
impl @app.Resource for RandomSource with fn resource() {
  random_source_key
}

///|
impl @app.Resource for SampledShapes with fn resource() {
  sampled_shapes_key
}

///|
impl @app.Resource for PointMesh with fn resource() {
  point_mesh_key
}

///|
impl @app.Resource for PointMaterial with fn resource() {
  point_material_key
}

///|
impl @app.Resource for MousePressed with fn resource() {
  mouse_pressed_key
}

///|
impl @app.Resource for InstructionText with fn resource() {
  instruction_text_key
}

///|
impl @ecs.Component for SamplePoint with fn component() {
  sample_point_key
}

///|
impl @ecs.Component for SpawningPoint with fn component() {
  spawning_point_key
}

///|
impl @ecs.Component for DespawningPoint with fn component() {
  despawning_point_key
}

///|
impl @ecs.Component for FireflyLights with fn component() {
  firefly_lights_key
}

///|
impl @ecs.Component for CameraRig with fn component() {
  camera_rig_key
}

///|
fn current_world_or_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None => abort("sampling_primitives systems require an active app world")
  }
}

///|
fn default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  let time : @time.Time[Unit]? = world.get_resource(
    @time.default_time_resource_key,
  )
  match time {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in sampling_primitives example")
  }
}

///|
fn sampled_shapes_new() -> SampledShapes {
  let shapes : Array[Shape] = [
    Cuboid,
    Sphere,
    Capsule,
    Cylinder,
    Tetrahedron,
    Triangle,
  ]
  let entries : Array[SampledShape] = []
  let center = Float::from_int(shapes.length()) / 2.0F
  let spacing = distance_between_shapes()
  for i in 0..<shapes.length() {
    entries.push({
      shape: shapes[i],
      translation: @math.Vec3::new(
        (Float::from_int(i) - center) * spacing.x,
        0.0F,
        0.0F,
      ),
    })
  }
  { shapes: entries }
}

///|
fn shape_sample_interior(shape : Shape, rng : @random.Rand) -> @math.Vec3 {
  match shape {
    Cuboid => cuboid_shape().sample_interior(rng)
    Sphere => sphere_shape().sample_interior(rng)
    Capsule => capsule_shape().sample_interior(rng)
    Cylinder => cylinder_shape().sample_interior(rng)
    Tetrahedron => tetrahedron_shape().sample_interior(rng)
    Triangle => triangle_shape().sample_interior(rng)
  }
}

///|
fn shape_sample_boundary(shape : Shape, rng : @random.Rand) -> @math.Vec3 {
  match shape {
    Cuboid => cuboid_shape().sample_boundary(rng)
    Sphere => sphere_shape().sample_boundary(rng)
    Capsule => capsule_shape().sample_boundary(rng)
    Cylinder => cylinder_shape().sample_boundary(rng)
    Tetrahedron => tetrahedron_shape().sample_boundary(rng)
    Triangle => triangle_shape().sample_boundary(rng)
  }
}

///|
fn[P : @pbr.IntoPbrMeshAsset] mesh3d_from_mesh_asset(value : P) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets |> @pbr.add_mesh(value)
    }),
  )
}

///|
fn shape_mesh(shape : Shape) -> @mesh.Mesh3d {
  match shape {
    Cuboid => mesh3d_from_mesh_asset(@math.Cuboid::new(1.0F, 2.0F, 1.0F))
    Sphere => mesh3d_from_mesh_asset(sphere_shape())
    Capsule => mesh3d_from_mesh_asset(capsule_shape())
    Cylinder => mesh3d_from_mesh_asset(cylinder_shape())
    Tetrahedron => mesh3d_from_mesh_asset(tetrahedron_shape())
    Triangle => mesh3d_from_mesh_asset(triangle_shape())
  }
}

///|
fn sample_point_material(
  mode : SamplingMode,
  materials : PointMaterial,
) -> @asset.Handle[@pbr.StandardMaterial] {
  match mode {
    Interior => materials.interior
    Boundary => materials.boundary
  }
}

///|
fn camera_translation(rig : CameraRig) -> @math.Vec3 {
  let cos_pitch = @math.cos(rig.pitch)
  let looking_direction = @math.Vec3::new(
    -@math.sin(rig.yaw) * cos_pitch,
    -@math.sin(rig.pitch),
    @math.cos(rig.yaw) * cos_pitch,
  )
  rig.target.sub(looking_direction.mul_scalar(rig.distance))
}

///|
fn spawn_instructions(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let overlay_camera = try! world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(1).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  try! world.set_by_key(
    overlay_camera,
    @ui.IsDefaultUiCamera::component(),
    IsDefaultUiCamera(),
  )

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, UiRoot())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::Node().with_width(Percent(100.0F)).with_height(Percent(100.0F)),
  )

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(Absolute)
    .with_top(Px(12.0F))
    .with_left(Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(
      "Controls:\nM: Toggle between sampling boundary and interior.\nA: Toggle automatic spawning & despawning of points.\nR: Restart (erase all samples).\nS: Add one random sample.\nD: Add 100 random samples.\nRotate camera by holding left mouse and panning.\nZoom camera by scrolling via mouse or +/-.\nMove camera by L/R arrow keys.\nTab: Toggle this text",
    ),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(Absolute)
    .with_top(Px(12.0F))
    .with_left(Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(
      "Controls:\nM: Toggle between sampling boundary and interior.\nA: Toggle automatic spawning & despawning of points.\nR: Restart (erase all samples).\nS: Add one random sample.\nD: Add 100 random samples.\nRotate camera by holding left mouse and panning.\nZoom camera by scrolling via mouse or +/-.\nMove camera by L/R arrow keys.\nTab: Toggle this text",
    ),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(Left),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(Absolute)
    .with_top(Px(12.0F))
    .with_left(Px(12.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(
      "Controls:\nM: Toggle between sampling boundary and interior.\nA: Toggle automatic spawning & despawning of points.\nR: Restart (erase all samples).\nS: Add one random sample.\nD: Add 100 random samples.\nRotate camera by holding left mouse and panning.\nZoom camera by scrolling via mouse or +/-.\nMove camera by L/R arrow keys.\nTab: Toggle this text",
    ),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font(font).with_font_size(20.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::white()),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(Left),
  )
  try! world.set_by_key(
    text_entity,
    @visibility.Visibility::component(),
    Visible,
  )
  world.insert_resource(InstructionText::resource(), { entity: text_entity })
}

///|
#warnings("-unnecessary_annotation")
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let world = current_world_or_abort()

  world.insert_resource(RandomSource::resource(), {
    rng: @random.Rand::chacha8(seed=b"bevy-sampling-primitives-seed-04"),
  })
  world.insert_resource(SampledShapes::resource(), sampled_shapes_new())
  world.insert_resource(SpawnQueue::resource(), { count: 0 })
  world.insert_resource(PointCounter::resource(), { count: 0 })
  world.insert_resource(SamplingMode::resource(), Interior)
  world.insert_resource(SpawningMode::resource(), Automatic)
  world.insert_resource(MousePressed::resource(), { value: false })

  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(20.0F, 20.0F),
          ).build(),
        )
      }),
    ),
    @pbr.MeshMaterial3dTyped::new(
      materials
      .peek()
      .add(
        @pbr.StandardMaterial::from_color(@color.Color::srgb(0.3F, 0.5F, 0.3F))
        .with_perceptual_roughness(0.95F)
        .with_metallic(0.0F),
      ),
    ),
    @transform.Transform::from_xyz(0.0F, -2.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let shape_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(
        @color.Color::srgba(0.2F, 0.1F, 0.6F, 0.3F),
      )
      .with_reflectance(0.0F)
      .with_alpha_mode(Blend)
      .with_cull_mode(None),
    )

  guard world.get_resource(SampledShapes::resource()) is Some(sampled_shapes) else {
    return
  }
  for sampled_shape in sampled_shapes.shapes {
    @pbr.MeshMaterial3dBundle::new(
      shape_mesh(sampled_shape.shape),
      @pbr.MeshMaterial3dTyped::new(shape_material),
      @transform.Transform::from_translation(sampled_shape.translation),
    ).spawn(world)
    |> ignore

    let firefly_light = world.spawn_empty()
    try! world.set_by_key(
      firefly_light,
      @pbr.PointLight::component(),
      @pbr.PointLight::PointLight()
      .with_range(4.0F)
      .with_radius(0.6F)
      .with_intensity(1.0F)
      .with_shadow_maps_enabled(false)
      .with_color(inside_point_color()),
    )
    try! world.set_by_key(
      firefly_light,
      @transform.Transform::component(),
      @transform.Transform::from_translation(sampled_shape.translation),
    )
    try! world.set_by_key(firefly_light, FireflyLights::component(), FireflyLights::{

    })
  }

  let global_light = world.spawn_empty()
  try! world.set_by_key(
    global_light,
    @pbr.PointLight::component(),
    @pbr.PointLight::PointLight()
    .with_color(sky_color())
    .with_intensity(2_000.0F)
    .with_shadow_maps_enabled(false),
  )
  try! world.set_by_key(
    global_light,
    @transform.Transform::component(),
    @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
  )

  let camera_entity = @pbr.Camera3dBundle::new(
      @camera_camera.Camera::Camera().with_clear_color(sky_color()),
      @transform.Transform::from_xyz(-2.0F, 3.0F, 5.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_tonemapping(Some(TonyMcMapface))
    .with_bloom(Some(Bloom()))
    .spawn(world)
  try! world.set_by_key(camera_entity, CameraRig::component(), {
    yaw: 0.56F,
    pitch: 0.45F,
    distance: 8.0F,
    target: @math.Vec3::zero(),
  })

  world.insert_resource(PointMesh::resource(), {
    mesh: @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.SphereMeshBuilder::new(
            0.03F,
            @mesh_primitives_dim3.SphereKind::ico(1),
          ).build(),
        )
      }),
    ),
  })
  world.insert_resource(PointMaterial::resource(), {
    interior: materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::black())
      .with_reflectance(0.05F)
      .with_emissive(@color.Color::srgba(2.1375F, 2.75F, 0.025F, 1.0F)),
    ),
    boundary: materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::black())
      .with_reflectance(0.05F)
      .with_emissive(@color.Color::srgba(0.12F, 0.3F, 1.35F, 1.0F)),
    ),
  })

  spawn_instructions(world, asset_server.get())
}

///|
#warnings("-unnecessary_annotation")
fn spawn_sample_point(
  world : @ecs.World,
  point_mesh : PointMesh,
  point_material : PointMaterial,
  mode : SamplingMode,
  sample : @math.Vec3,
) -> Unit {
  let entity = @pbr.MeshMaterial3dBundle::new(
    point_mesh.mesh,
    @pbr.MeshMaterial3dTyped::new(sample_point_material(mode, point_material)),
    @transform.Transform::from_translation(sample).with_scale(
      @math.Vec3::zero(),
    ),
  ).spawn(world)
  try! world.set_by_key(entity, SamplePoint::component(), SamplePoint::{  })
  try! world.set_by_key(entity, SpawningPoint::component(), { progress: 0.0F })
}

///|
fn handle_keypress(keyboard : @input.ButtonInput[@window.KeyCode]) -> Unit {
  let world = current_world_or_abort()

  if keyboard.just_pressed(KeyR) {
    let sample_entities : Array[@core.Entity] = []
    world.for_each_component(SamplePoint::component(), fn(entity, _sample) {
      sample_entities.push(entity)
    })
    for entity in sample_entities {
      try! world.despawn(entity)
    }
    let tick = world.increment_change_tick()
    ignore(tick)
    if world.get_resource_mut(PointCounter::resource()) is Some(counter) {
      counter.modify(fn(value) { value.count = 0 })
    }
  }

  let tick = world.increment_change_tick()
  ignore(tick)
  guard world.get_resource_mut(SamplingMode::resource()) is Some(mode) else {
    return
  }
  guard world.get_resource_mut(SpawningMode::resource()) is Some(spawn_mode) else {
    return
  }
  guard world.get_resource_mut(SpawnQueue::resource()) is Some(spawn_queue) else {
    return
  }
  guard world.get_resource(InstructionText::resource()) is Some(instruction) else {
    return
  }
  guard world.get_resource(SampledShapes::resource()) is Some(sampled_shapes) else {
    return
  }

  if keyboard.just_pressed(KeyS) {
    spawn_queue.modify(fn(value) { value.count = value.count + 1 })
  }
  if keyboard.just_pressed(KeyD) {
    spawn_queue.modify(fn(value) { value.count = value.count + 100 })
  }
  if keyboard.just_pressed(KeyM) {
    mode.update(fn(value) {
      match value {
        Interior => Boundary
        Boundary => Interior
      }
    })
  }
  if keyboard.just_pressed(KeyA) {
    spawn_mode.update(fn(value) {
      match value {
        Manual => Automatic
        Automatic => Manual
      }
    })
  }
  if keyboard.just_pressed(Tab) {
    let current_visibility = match
      (try! world.get_by_key(
        instruction.entity,
        @visibility.Visibility::component(),
      )) {
      Some(visibility) => visibility
      None => Visible
    }
    let next_visibility = match current_visibility {
      Hidden => @visibility.Visibility::Visible
      _ => Hidden
    }
    try! world.set_by_key(
      instruction.entity,
      @visibility.Visibility::component(),
      next_visibility,
    )
  }

  let mut camera_entity : @core.Entity? = None
  world.for_each_component(CameraRig::component(), fn(entity, _rig) {
    if camera_entity is None {
      camera_entity = Some(entity)
    }
  })
  guard camera_entity is Some(camera_entity) else { return }
  guard (try! world.get_by_key(camera_entity, CameraRig::component()))
    is Some(rig) else {
    return
  }

  if keyboard.just_pressed(NumpadSubtract) || keyboard.just_pressed(Minus) {
    let next_rig = rig
    next_rig.distance = if rig.distance + MAX_CAMERA_DISTANCE / 15.0F >
      MAX_CAMERA_DISTANCE {
      MAX_CAMERA_DISTANCE
    } else {
      rig.distance + MAX_CAMERA_DISTANCE / 15.0F
    }
    ignore(try! world.replace(camera_entity, CameraRig::component(), next_rig))
  }
  if keyboard.just_pressed(NumpadAdd) {
    let next_rig = rig
    next_rig.distance = if rig.distance - MAX_CAMERA_DISTANCE / 15.0F <
      MIN_CAMERA_DISTANCE {
      MIN_CAMERA_DISTANCE
    } else {
      rig.distance - MAX_CAMERA_DISTANCE / 15.0F
    }
    ignore(try! world.replace(camera_entity, CameraRig::component(), next_rig))
  }

  let left = keyboard.just_pressed(ArrowLeft)
  let right = keyboard.just_pressed(ArrowRight)
  if left || right {
    let mut closest = 0
    let mut closest_distance = 1_000_000_000.0F
    for i in 0..<sampled_shapes.shapes.length() {
      let distance = sampled_shapes.shapes[i].translation
        .sub(rig.target)
        .length()
      if distance < closest_distance {
        closest = i
        closest_distance = distance
      }
    }
    let next_rig = rig
    if left && closest > 0 {
      next_rig.target = sampled_shapes.shapes[closest - 1].translation
      ignore(
        try! world.replace(camera_entity, CameraRig::component(), next_rig),
      )
    } else if right && closest + 1 < sampled_shapes.shapes.length() {
      next_rig.target = sampled_shapes.shapes[closest + 1].translation
      ignore(
        try! world.replace(camera_entity, CameraRig::component(), next_rig),
      )
    }
  }
}

///|
fn handle_mouse(
  accumulated_mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  accumulated_mouse_scroll : @app.Res[@input.AccumulatedMouseScroll],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
) -> Unit {
  let world = current_world_or_abort()
  let tick = world.increment_change_tick()
  ignore(tick)

  guard world.get_resource_mut(MousePressed::resource()) is Some(mouse_pressed) else {
    return
  }
  mouse_pressed.modify(fn(value) { value.value = mouse_buttons.pressed(Left) })

  let mut camera_entity : @core.Entity? = None
  world.for_each_component(CameraRig::component(), fn(entity, _rig) {
    if camera_entity is None {
      camera_entity = Some(entity)
    }
  })
  guard camera_entity is Some(camera_entity) else { return }
  guard (try! world.get_by_key(camera_entity, CameraRig::component()))
    is Some(rig) else {
    return
  }

  let next_rig = rig
  let scroll_delta = accumulated_mouse_scroll.get().delta
  if scroll_delta.x != 0.0F || scroll_delta.y != 0.0F {
    let next_distance = rig.distance -
      scroll_delta.y / 15.0F * MAX_CAMERA_DISTANCE
    next_rig.distance = if next_distance < MIN_CAMERA_DISTANCE {
      MIN_CAMERA_DISTANCE
    } else if next_distance > MAX_CAMERA_DISTANCE {
      MAX_CAMERA_DISTANCE
    } else {
      next_distance
    }
  }

  if mouse_pressed.peek().value {
    let displacement = accumulated_mouse_motion.get().delta
    if displacement.x != 0.0F || displacement.y != 0.0F {
      next_rig.yaw = rig.yaw + displacement.x / 90.0F
      let next_pitch = rig.pitch + displacement.y / 90.0F
      let pitch_limit = @math.pi() / 2.01F
      next_rig.pitch = if next_pitch < -pitch_limit {
        -pitch_limit
      } else if next_pitch > pitch_limit {
        pitch_limit
      } else {
        next_pitch
      }
    }
  }
  ignore(try! world.replace(camera_entity, CameraRig::component(), next_rig))
}

///|
fn spawn_points(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  ignore(tick)
  guard world.get_resource(SpawningMode::resource()) is Some(spawn_mode) else {
    return
  }
  guard world.get_resource_mut(SpawnQueue::resource()) is Some(spawn_queue) else {
    return
  }
  guard world.get_resource_mut(PointCounter::resource()) is Some(point_counter) else {
    return
  }
  guard world.get_resource_mut(RandomSource::resource()) is Some(random_source) else {
    return
  }
  guard world.get_resource(SamplingMode::resource()) is Some(mode) else {
    return
  }
  guard world.get_resource(SampledShapes::resource()) is Some(sampled_shapes) else {
    return
  }
  guard world.get_resource(PointMesh::resource()) is Some(point_mesh) else {
    return
  }
  guard world.get_resource(PointMaterial::resource()) is Some(point_material) else {
    return
  }

  if spawn_mode is Automatic {
    spawn_queue.modify(fn(value) {
      value.count = value.count + POINTS_PER_FRAME
    })
  }
  if spawn_queue.peek().count <= 0 || sampled_shapes.shapes.length() == 0 {
    return
  }

  for _ in 0..<1000 {
    if spawn_queue.peek().count <= 0 {
      break
    }
    spawn_queue.modify(fn(value) { value.count = value.count - 1 })
    point_counter.modify(fn(value) { value.count = value.count + 1 })

    let sampled_index = random_source.modify(fn(value) {
      value.rng.int(limit=sampled_shapes.shapes.length())
    })
    let sampled_shape = sampled_shapes.shapes[sampled_index]
    let sample_offset = random_source.modify(fn(value) {
      match mode {
        Interior => shape_sample_interior(sampled_shape.shape, value.rng)
        Boundary => shape_sample_boundary(sampled_shape.shape, value.rng)
      }
    })
    let sample = sampled_shape.translation.add(sample_offset)
    spawn_sample_point(world, point_mesh, point_material, mode, sample)
  }
}

///|
fn despawn_points(world : @ecs.World) -> Unit {
  guard world.get_resource(SpawningMode::resource()) is Some(spawn_mode) else {
    return
  }
  if spawn_mode is Manual {
    return
  }
  let tick = world.increment_change_tick()
  ignore(tick)
  guard world.get_resource_mut(PointCounter::resource()) is Some(point_counter) else {
    return
  }
  if point_counter.peek().count < MAX_POINTS {
    return
  }
  guard world.get_resource_mut(RandomSource::resource()) is Some(random_source) else {
    return
  }

  let sample_entities : Array[@core.Entity] = []
  world.for_each_component(SamplePoint::component(), fn(entity, _sample) {
    sample_entities.push(entity)
  })
  if sample_entities.length() == 0 {
    return
  }

  let skip = random_source.modify(fn(value) {
    value.rng.int(limit=sample_entities.length())
  })
  let point_count = point_counter.peek().count
  let despawn_amount = if point_count - MAX_POINTS < 100 {
    point_count - MAX_POINTS
  } else {
    100
  }

  let mut removed = 0
  for i in skip..<sample_entities.length() {
    if removed >= despawn_amount {
      break
    }
    let entity = sample_entities[i]
    try! world.set_by_key(entity, DespawningPoint::component(), {
      progress: 0.0F,
    })
    try! (world.take(entity, SamplePoint::component()) |> ignore)
    try! (world.take(entity, SpawningPoint::component()) |> ignore)
    removed = removed + 1
  }
  point_counter.modify(fn(value) { value.count = value.count - removed })
}

///|
fn animate_spawning(world : @ecs.World) -> Unit {
  let delta = default_time_or_default(world).delta_secs()
  let tick = world.increment_change_tick()
  ignore(tick)
  let entities : Array[@core.Entity] = []
  world.for_each_component(SpawningPoint::component(), fn(entity, _spawning) {
    entities.push(entity)
  })

  for entity in entities {
    guard (try! world.get_by_key(entity, SpawningPoint::component()))
      is Some(spawning_point) else {
      continue
    }
    guard (try! world.get_by_key(entity, @transform.Transform::component()))
      is Some(transform) else {
      continue
    }
    let next_point = spawning_point
    next_point.progress = next_point.progress + delta / ANIMATION_TIME
    let next_transform = transform.with_scale(
      @math.Vec3::splat(
        if next_point.progress < 1.0F {
          next_point.progress
        } else {
          1.0F
        },
      ),
    )
    ignore(
      try! world.replace(
        entity,
        @transform.Transform::component(),
        next_transform,
      ),
    )
    if next_point.progress >= 1.0F {
      try! (world.take(entity, SpawningPoint::component()) |> ignore)
    } else {
      ignore(try! world.replace(entity, SpawningPoint::component(), next_point))
    }
  }
}

///|
fn animate_despawning(world : @ecs.World) -> Unit {
  let delta = default_time_or_default(world).delta_secs()
  let tick = world.increment_change_tick()
  ignore(tick)
  let entities : Array[@core.Entity] = []
  world.for_each_component(DespawningPoint::component(), fn(
    entity,
    _despawning,
  ) {
    entities.push(entity)
  })

  for entity in entities {
    guard (try! world.get_by_key(entity, DespawningPoint::component()))
      is Some(despawning_point) else {
      continue
    }
    guard (try! world.get_by_key(entity, @transform.Transform::component()))
      is Some(transform) else {
      continue
    }
    let next_point = despawning_point
    next_point.progress = next_point.progress + delta / ANIMATION_TIME
    let minimum_progress = 1.0F - transform.scale.x
    if next_point.progress < minimum_progress {
      next_point.progress = minimum_progress
    }
    let next_scale = if 1.0F - next_point.progress > 0.0F {
      1.0F - next_point.progress
    } else {
      0.0F
    }
    ignore(
      try! world.replace(
        entity,
        @transform.Transform::component(),
        transform.with_scale(@math.Vec3::splat(next_scale)),
      ),
    )
    if next_point.progress >= 1.0F {
      try! world.despawn(entity)
    } else {
      ignore(
        try! world.replace(entity, DespawningPoint::component(), next_point),
      )
    }
  }
}

///|
fn update_camera(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  ignore(tick)
  let camera_entities : Array[@core.Entity] = []
  world.for_each_component(CameraRig::component(), fn(entity, _rig) {
    camera_entities.push(entity)
  })
  for entity in camera_entities {
    guard (try! world.get_by_key(entity, CameraRig::component())) is Some(rig) else {
      continue
    }
    ignore(
      try! world.replace(
        entity,
        @transform.Transform::component(),
        @transform.Transform::from_translation(camera_translation(rig)).looking_at(
          rig.target,
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    )
  }
}

///|
fn update_lights(world : @ecs.World) -> Unit {
  guard world.get_resource(PointCounter::resource()) is Some(counter) else {
    return
  }
  let saturation = if Float::from_int(counter.count) /
    Float::from_int(MAX_POINTS) <
    2.0F {
    Float::from_int(counter.count) / Float::from_int(MAX_POINTS)
  } else {
    2.0F
  }
  let intensity = 40_000.0F * saturation
  let tick = world.increment_change_tick()
  ignore(tick)
  let firefly_entities : Array[@core.Entity] = []
  world.for_each_component(FireflyLights::component(), fn(entity, _marker) {
    firefly_entities.push(entity)
  })
  for entity in firefly_entities {
    guard (try! world.get_by_key(entity, @pbr.PointLight::component()))
      is Some(light) else {
      continue
    }
    let next_intensity = light.intensity + (intensity - light.intensity) * 0.04F
    ignore(
      try! world.replace(
        entity,
        @pbr.PointLight::component(),
        light.with_intensity(next_intensity),
      ),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .add_systems_param(Update, handle_keypress)
  .add_systems_param3(Update, handle_mouse)
  .add_systems_world(Update, spawn_points)
  .add_systems_world(Update, despawn_points)
  .add_systems_world(Update, animate_spawning)
  .add_systems_world(Update, animate_despawning)
  .add_systems_world(Update, update_camera)
  .add_systems_world(Update, update_lights)
  .run()
}
