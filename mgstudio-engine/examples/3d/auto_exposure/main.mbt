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
/// Bevy source: `bevy/examples/3d/auto_exposure.rs`.

///|
struct ExampleDisplay {}

///|
struct MeteringMaskOverlay {}

///|
struct ExampleResources {
  basic_compensation_curve : @asset.Handle[@pbr.AutoExposureCompensationCurve]
  basic_metering_mask : @asset.Handle[@asset.Image]
}

///|
let example_display_component_key : @ecs.ComponentKey[ExampleDisplay] = @ecs.register_component(
  debug_name="examples.3d.auto_exposure.ExampleDisplay",
)

///|
let metering_mask_overlay_component_key : @ecs.ComponentKey[MeteringMaskOverlay] = @ecs.register_component(
  debug_name="examples.3d.auto_exposure.MeteringMaskOverlay",
)

///|
let example_resources_resource_key : @ecs.ResourceKey[ExampleResources] = @ecs.register_resource(
  debug_name="examples.3d.auto_exposure.ExampleResources",
)

///|
impl @ecs.Component for ExampleDisplay with fn component() {
  example_display_component_key
}

///|
impl @ecs.Component for MeteringMaskOverlay with fn component() {
  metering_mask_overlay_component_key
}

///|
impl @app.Resource for ExampleResources with fn resource() {
  example_resources_resource_key
}

///|
fn auto_exposure_curve_error_message(
  err : @pbr.AutoExposureCompensationCurveError,
) -> String {
  match err {
    @pbr.InvalidCurve => "invalid curve"
    @pbr.DiscontinuityFound => "discontinuity found"
    @pbr.NotMonotonic => "not monotonic"
  }
}

///|
fn asset_server_or_abort(world : @ecs.World) -> @asset.AssetServer {
  match world.get_resource(@asset.asset_server_resource_key) {
    Some(asset_server) => asset_server
    None =>
      abort(
        "auto_exposure requires the world-owned AssetServer resource; add AssetPlugin before the example startup system runs",
      )
  }
}

///|
fn auto_exposure_curve_assets_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[@asset.Assets[@pbr.AutoExposureCompensationCurve]] {
  let key : @ecs.ResourceKey[@asset.Assets[@pbr.AutoExposureCompensationCurve]] = @asset.assets_resource_key()
  match world.get_resource_mut(key) {
    Some(assets) => assets
    None =>
      abort(
        "Missing Assets<AutoExposureCompensationCurve> resource in auto_exposure example",
      )
  }
}

///|
fn build_basic_compensation_curve(
  world : @ecs.World,
) -> @asset.Handle[@pbr.AutoExposureCompensationCurve] {
  let curve = @pbr.AutoExposureCompensationCurve::from_curve(
    @math.LinearSpline::new([
      @math.Vec2::new(-4.0F, -2.0F),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(2.0F, 0.0F),
      @math.Vec2::new(4.0F, 2.0F),
    ]),
  ) catch {
    err =>
      abort(
        "Failed to build auto exposure compensation curve in example: \{auto_exposure_curve_error_message(err)}",
      )
  }
  auto_exposure_curve_assets_or_abort(world).modify(fn(assets) {
    assets.add(curve)
  })
}

///|
fn[T] handle_matches(
  handle : @asset.Handle[T]?,
  expected : @asset.Handle[T],
) -> Bool {
  match handle {
    Some(value) => value.id() == expected.id()
    None => false
  }
}

///|
fn[T] toggle_handle(
  handle : @asset.Handle[T]?,
  expected : @asset.Handle[T],
) -> @asset.Handle[T]? {
  if handle_matches(handle, expected) {
    None
  } else {
    Some(expected)
  }
}

///|
fn first_auto_exposure_camera(world : @ecs.World) -> @core.Entity? {
  let mut camera : @core.Entity? = None
  try! world
  .query_entities_filtered(
    (
      @ecs.With::new(@camera.Camera::component()),
      @ecs.With::new(@camera.ecs_key_camera3d),
      @ecs.With::new(@pbr.ecs_key_auto_exposure),
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
fn first_example_display(world : @ecs.World) -> @core.Entity? {
  let mut display : @core.Entity? = None
  try! world
  .query_entities_filtered(@ecs.With::new(ExampleDisplay::component()))
  .view(fn(_query_entity, entity) {
    if display is None {
      display = Some(entity)
    }
  })
  display
}

///|
fn first_metering_mask_overlay(world : @ecs.World) -> @core.Entity? {
  let mut overlay : @core.Entity? = None
  try! world
  .query_entities_filtered(@ecs.With::new(MeteringMaskOverlay::component()))
  .view(fn(_query_entity, entity) {
    if overlay is None {
      overlay = Some(entity)
    }
  })
  overlay
}

///|
fn example_resources_or_abort(world : @ecs.World) -> ExampleResources {
  match world.get_resource(ExampleResources::resource()) {
    Some(resources) => resources
    None => abort("Missing ExampleResources in auto_exposure example")
  }
}

///|
fn camera_auto_exposure_or_default(
  world : @ecs.World,
  camera : @core.Entity,
) -> @pbr.AutoExposure {
  match (try! world.get_by_key(camera, @pbr.ecs_key_auto_exposure)) {
    Some(auto_exposure) => auto_exposure
    None => @pbr.AutoExposure::AutoExposure()
  }
}

///|
fn update_display_text(world : @ecs.World) -> Unit {
  guard first_example_display(world) is Some(display) else { return }
  guard first_auto_exposure_camera(world) is Some(camera) else { return }
  let resources = example_resources_or_abort(world)
  let auto_exposure = camera_auto_exposure_or_default(world, camera)
  let compensation_label = if handle_matches(
      auto_exposure.compensation_curve,
      resources.basic_compensation_curve,
    ) {
    "Enabled"
  } else {
    "Disabled"
  }
  let metering_label = if handle_matches(
      auto_exposure.metering_mask,
      resources.basic_metering_mask,
    ) {
    "Enabled"
  } else {
    "Disabled"
  }
  try! (world.replace(
    display,
    @text.ecs_key_text,
    @text.Text::new(
      "Compensation Curve: \{compensation_label}\nMetering Mask: \{metering_label}",
    ),
  )
  |> ignore)
}

///|
fn spawn_wall_panel(
  world : @ecs.World,
  wall_mesh : @asset.Handle[@mesh.Mesh],
  side : @math.Vec3,
  level : Int,
) -> Unit {
  let level_f = Float::from_double(level.to_double())
  let height = @math.Vec3::new(0.0F, level_f, 0.0F)
  let position = side.mul_scalar(2.0F).add(height)
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @color.Color::srgb(
        0.5F + side.x * 0.5F,
        0.75F - level_f * 0.25F,
        0.5F + side.z * 0.5F,
      ),
    ),
  )

  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(wall_mesh),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(position.x, position.y, position.z).looking_at(
      height,
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_walls(world : @ecs.World) -> Unit {
  let wall_mesh = @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
    @pbr.add_mesh(
      assets,
      @math.Plane3d::new(
        @math.Vec3::new(0.0F, 0.0F, -1.0F),
        @math.Vec2::new(2.0F, 0.5F),
      ),
    )
  })
  for level in [-1, 0, 1] {
    for
      side in [
        @math.Vec3::new(-1.0F, 0.0F, 0.0F),
        @math.Vec3::new(1.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 0.0F, -1.0F),
        @math.Vec3::new(0.0F, 0.0F, 1.0F),
      ] {
      if level == 0 && side.z == 1.0F {
        continue
      }
      spawn_wall_panel(world, wall_mesh, side, level)
    }
  }
}

///|
fn spawn_mask_overlay(
  world : @ecs.World,
  metering_mask : @asset.Handle[@asset.Image],
) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @ui.ecs_key_image_node,
    @ui.ImageNode::new(metering_mask),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_display(@ui.Display::None),
  )
  try! world.set_by_key(entity, MeteringMaskOverlay::component(), MeteringMaskOverlay::{

  })
}

///|
fn spawn_instruction_text(world : @ecs.World) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text,
    @text.Text::new(
      "Left / Right - Rotate Camera\nC - Toggle Compensation Curve\nM - Toggle Metering Mask\nV - Visualize Metering Mask",
    ),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont(),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::TextColor(),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::TextLayout(),
  )
}

///|
fn spawn_display_text(world : @ecs.World) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_right(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::Text())
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont(),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::TextColor(),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::TextLayout(),
  )
  try! world.set_by_key(entity, ExampleDisplay::component(), ExampleDisplay::{

  })
}

///|
fn set_global_ambient_light(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@color.Color::white(), 0.0F),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = asset_server_or_abort(world)
  let metering_mask = asset_server.load("textures/basic_metering_mask.png")
  let basic_compensation_curve = build_basic_compensation_curve(world)

  let camera = @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      @transform.Transform::from_xyz(1.0F, 0.0F, 0.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_auto_exposure(
      Some(
        @pbr.AutoExposure::AutoExposure().with_metering_mask(
          Some(metering_mask),
        ),
      ),
    )
    .spawn(world)
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      100_000.0F,
    ),
  )

  world.insert_resource(ExampleResources::resource(), ExampleResources::{
    basic_compensation_curve,
    basic_metering_mask: metering_mask,
  })

  spawn_walls(world)
  set_global_ambient_light(world)

  let point_light = world.spawn_empty()
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@color.Color::white(), 2_000.0F, 20.0F, false),
  )
  try! world.set_by_key(
    point_light,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )

  spawn_mask_overlay(world, metering_mask)
  spawn_instruction_text(world)
  spawn_display_text(world)
  update_display_text(world)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match world.get_resource(@time.default_time_resource_key) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in auto_exposure example")
  }
}

///|
fn update_camera_rotation(
  world : @ecs.World,
  camera : @core.Entity,
  rotation : Float,
) -> Unit {
  guard rotation != 0.0F else { return }
  guard (try! world.get_by_key(camera, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  transform.rotate_around(
    @math.Vec3::zero(),
    @math.Quat::from_rotation_y(rotation),
  )
  try! (world.replace(camera, @transform.ecs_key_transform, transform) |> ignore)
}

///|
fn update_auto_exposure_toggles(
  world : @ecs.World,
  camera : @core.Entity,
  resources : ExampleResources,
) -> Unit {
  let auto_exposure = camera_auto_exposure_or_default(world, camera)
  let mut next = auto_exposure
  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    next = next.with_compensation_curve(
      toggle_handle(next.compensation_curve, resources.basic_compensation_curve),
    )
  }
  if @input.key_just_pressed(@window.KeyCode::KeyM) {
    next = next.with_metering_mask(
      toggle_handle(next.metering_mask, resources.basic_metering_mask),
    )
  }
  try! (world.replace(camera, @pbr.ecs_key_auto_exposure, next) |> ignore)
}

///|
fn update_metering_mask_overlay(world : @ecs.World) -> Unit {
  guard first_metering_mask_overlay(world) is Some(overlay) else { return }
  guard (try! world.get_by_key(overlay, @ui.ecs_key_node)) is Some(node) else {
    return
  }
  let next_display = if @input.key_pressed(@window.KeyCode::KeyV) {
    @ui.Display::Flex
  } else {
    @ui.Display::None
  }
  if node.display != next_display {
    try! (world.replace(
      overlay,
      @ui.ecs_key_node,
      node.with_display(next_display),
    )
    |> ignore)
  }
}

///|
fn example_control_system(world : @ecs.World) -> Unit {
  guard first_auto_exposure_camera(world) is Some(camera) else { return }
  let delta = world_time(world).delta_seconds()
  let rotation = if @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta
  } else if @input.key_pressed(@window.KeyCode::ArrowRight) {
    -delta
  } else {
    0.0F
  }
  let resources = example_resources_or_abort(world)
  update_camera_rotation(world, camera, rotation)
  update_auto_exposure_toggles(world, camera, resources)
  update_metering_mask_overlay(world)
  update_display_text(world)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_world(@app.Startup, setup)
  .add_systems_world(@app.Update, example_control_system)
  .run()
}
