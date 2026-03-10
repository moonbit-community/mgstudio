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
/// Port of `bevy/examples/math/random_sampling.rs`.

///|
pub(all) enum Mode {
  Interior
  Boundary
} derive(Eq, Show)

///|
struct SampledShape {
  shape : @math.Cuboid
}

///|
struct RandomSource {
  rng : @random.Rand
}

///|
struct PointMesh {
  mesh : @pbr.Mesh3d
}

///|
struct PointMaterial {
  handle : @asset.Handle[@pbr.StandardMaterial]
}

///|
struct SamplePoint {}

///|
struct MousePressed {
  mut value : Bool
}

///|
let mode_key : @ecs.ResourceKey[Mode] = @ecs.register_resource(
  debug_name="examples.math.random_sampling.Mode",
)

///|
let sampled_shape_key : @ecs.ResourceKey[SampledShape] = @ecs.register_resource(
  debug_name="examples.math.random_sampling.SampledShape",
)

///|
let random_source_key : @ecs.ResourceKey[RandomSource] = @ecs.register_resource(
  debug_name="examples.math.random_sampling.RandomSource",
)

///|
let point_mesh_key : @ecs.ResourceKey[PointMesh] = @ecs.register_resource(
  debug_name="examples.math.random_sampling.PointMesh",
)

///|
let point_material_key : @ecs.ResourceKey[PointMaterial] = @ecs.register_resource(
  debug_name="examples.math.random_sampling.PointMaterial",
)

///|
let mouse_pressed_key : @ecs.ResourceKey[MousePressed] = @ecs.register_resource(
  debug_name="examples.math.random_sampling.MousePressed",
)

///|
let sample_point_key : @ecs.ComponentKey[SamplePoint] = @ecs.register_component(
  debug_name="examples.math.random_sampling.SamplePoint",
)

///|
impl @app.Resource for Mode with resource() {
  mode_key
}

///|
impl @app.Resource for SampledShape with resource() {
  sampled_shape_key
}

///|
impl @app.Resource for RandomSource with resource() {
  random_source_key
}

///|
impl @app.Resource for PointMesh with resource() {
  point_mesh_key
}

///|
impl @app.Resource for PointMaterial with resource() {
  point_material_key
}

///|
impl @app.Resource for MousePressed with resource() {
  mouse_pressed_key
}

///|
impl @ecs.Component for SamplePoint with component() {
  sample_point_key
}

///|
fn current_world_or_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None => abort("random_sampling systems require an active app world")
  }
}

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let world = current_world_or_abort()
  let tick = world.read_change_tick()
  let shape = @math.Cuboid::from_length(2.9F)

  world.insert_resource(RandomSource::resource(), RandomSource::{
    rng: @random.Rand::chacha8(seed=b"RANDOM_SAMPLING_19878367467712!!"),
  })
  world.insert_resource(SampledShape::resource(), SampledShape::{ shape, })
  world.insert_resource(Mode::resource(), Mode::Interior)
  world.insert_resource(MousePressed::resource(), MousePressed::{ value: false })

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_plane(12.0F, 12.0F),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.5F, 0.3F)),
      ),
    ),
    @math.Transform::from_xyz(0.0F, -2.5F, 0.0F),
  ).spawn(world)
  |> ignore

  let shape_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::srgba(0.2F, 0.1F, 0.6F, 0.3F),
    )
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_cull_mode(None),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::from_cuboid(2.9F, 2.9F, 2.9F),
    @pbr.MeshMaterial3d::new(shape_material),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@pbr.PointLight::component())
  .insert(
    light,
    @pbr.PointLight::default().with_shadow_maps_enabled(true),
    tick,
  )
  world
  .component(@math.Transform::component())
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 3.0F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore

  world.insert_resource(PointMesh::resource(), PointMesh::{
    mesh: @pbr.Mesh3d::from_icosphere(0.03F, 3),
  })
  world.insert_resource(PointMaterial::resource(), PointMaterial::{
    handle: materials.get_ref().val.add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(1.0F, 0.8F, 0.8F)).with_metallic(
        0.8F,
      ),
    ),
  })

  spawn_instructions(world, asset_server.get(), tick)
}

///|
fn spawn_instructions(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
  tick : Int,
) -> Unit {
  let overlay_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(1).with_clear_color_none(),
    @math.Transform::identity(),
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

  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(
        "Controls:\nM: Toggle between sampling boundary and interior.\nR: Restart (erase all samples).\nS: Add one random sample.\nD: Add 100 random samples.\nRotate camera by holding left mouse and panning left/right.",
      ),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(20.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn sample_once(
  mode : Mode,
  shape : @math.Cuboid,
  rng : @random.Rand,
) -> @math.Vec3 {
  match mode {
    Interior => shape.sample_interior(rng)
    Boundary => shape.sample_boundary(rng)
  }
}

///|
fn sample_many(
  mode : Mode,
  shape : @math.Cuboid,
  rng : @random.Rand,
  count : Int,
) -> Array[@math.Vec3] {
  match mode {
    Interior => shape.interior_dist().sample_iter(rng).take(count).collect()
    Boundary => shape.boundary_dist().sample_iter(rng).take(count).collect()
  }
}

///|
fn spawn_sample_point(
  world : @ecs.World,
  point_mesh : PointMesh,
  point_material : PointMaterial,
  sample : @math.Vec3,
) -> Unit {
  let tick = world.read_change_tick()
  let entity = @pbr.MeshMaterial3dBundle::new(
    point_mesh.mesh,
    @pbr.MeshMaterial3d::new(point_material.handle),
    @math.Transform::from_translation(sample),
  ).spawn(world)
  world
  .component(SamplePoint::component())
  .insert(entity, SamplePoint::{  }, tick)
}

///|
fn clear_sample_points(world : @ecs.World) -> Unit {
  let points : Array[@core.Entity] = []
  world
  .component(SamplePoint::component())
  .for_each(fn(entity, _sample_point) { points.push(entity) })
  for entity in points {
    try! world.despawn(entity)
  }
}

///|
fn handle_keypress(
  keyboard : @input.ButtonInput[@window.KeyCode],
  mode : @app.ResMut[Mode],
) -> Unit {
  let world = current_world_or_abort()
  let mode_ref = mode.get_ref()

  if keyboard.just_pressed(KeyR) {
    clear_sample_points(world)
  }

  guard (try! world.get_resource(SampledShape::resource()))
    is Some(sampled_shape) else {
    return
  }
  guard (try! world.get_resource(PointMesh::resource())) is Some(point_mesh) else {
    return
  }
  guard (try! world.get_resource(PointMaterial::resource()))
    is Some(point_material) else {
    return
  }
  let tick = world.increment_change_tick()
  guard (try! world.get_resource_ref_mut(RandomSource::resource(), tick))
    is Some(random_source_ref) else {
    return
  }

  if keyboard.just_pressed(KeyS) {
    let sample = sample_once(
      mode_ref.val,
      sampled_shape.shape,
      random_source_ref.val.rng,
    )
    spawn_sample_point(world, point_mesh, point_material, sample)
  }

  if keyboard.just_pressed(KeyD) {
    let samples = sample_many(
      mode_ref.val,
      sampled_shape.shape,
      random_source_ref.val.rng,
      100,
    )
    for sample in samples {
      spawn_sample_point(world, point_mesh, point_material, sample)
    }
  }

  if keyboard.just_pressed(KeyM) {
    mode_ref.val = match mode_ref.val {
      Interior => Boundary
      Boundary => Interior
    }
  }
}

///|
fn handle_mouse(
  accumulated_mouse_motion : @app.Res[@input.AccumulatedMouseMotion],
  mouse_buttons : @input.ButtonInput[@window.MouseButton],
) -> Unit {
  let world = current_world_or_abort()
  let tick = world.increment_change_tick()
  guard (try! world.get_resource_ref_mut(MousePressed::resource(), tick))
    is Some(mouse_pressed_ref) else {
    return
  }
  mouse_pressed_ref.val.value = mouse_buttons.pressed(Left)

  if !mouse_pressed_ref.val.value {
    return
  }

  let delta = accumulated_mouse_motion.get().delta
  if delta.x == 0.0F && delta.y == 0.0F {
    return
  }

  let mut camera_entity : @core.Entity? = None
  world
  .component(@pbr.Camera3d::component())
  .for_each(fn(entity, _camera) {
    if camera_entity is None {
      camera_entity = Some(entity)
    }
  })
  guard camera_entity is Some(camera_entity) else { return }

  let transform_store = world.component(@math.Transform::component())
  guard transform_store.get(camera_entity) is Some(camera_transform) else {
    return
  }
  let next_transform = camera_transform
  next_transform.rotate_around(
    @math.Vec3::zero(),
    @math.Quat::from_rotation_y(-delta.x / 150.0F),
  )
  ignore(transform_store.set(camera_entity, next_transform, tick))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(handle_keypress)))
  .add_systems(@app.Update, @app.system(@app.system_param2(handle_mouse)))
  .run()
}
