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
/// Port of `bevy/examples/3d/tonemapping.rs`.
///
/// The Bevy resource/component/system structure is preserved here.
/// The scene-2 custom material path remains blocked by `bd-iqd` because
/// mgstudio still lacks Bevy-equivalent custom 3D material APIs.

///|
const PI : Float = 3.141592653589793F

///|
const PARAMETER_COUNT : Int = 4

///|
struct CameraTransform {
  transform : @math.Transform
}

///|
struct CurrentScene {
  mut value : Int
}

///|
struct SelectedParameter {
  mut value : Int
  max : Int
}

///|
struct PerMethodSettings {
  settings : @hashmap.HashMap[@render3d.Tonemapping, @render3d.ColorGrading]
}

///|
struct SceneNumber {
  value : Int
}

///|
struct HDRViewer {}

///|
struct TonemappingUiRoot {}

///|
struct TonemappingUiText {}

///|
struct ImageViewerText {}

///|
let camera_transform_resource_key : @ecs.ResourceKey[CameraTransform] = @ecs.register_resource(
  debug_name="examples.3d.tonemapping.CameraTransform",
)

///|
let current_scene_resource_key : @ecs.ResourceKey[CurrentScene] = @ecs.register_resource(
  debug_name="examples.3d.tonemapping.CurrentScene",
)

///|
let selected_parameter_resource_key : @ecs.ResourceKey[SelectedParameter] = @ecs.register_resource(
  debug_name="examples.3d.tonemapping.SelectedParameter",
)

///|
let per_method_settings_resource_key : @ecs.ResourceKey[PerMethodSettings] = @ecs.register_resource(
  debug_name="examples.3d.tonemapping.PerMethodSettings",
)

///|
let scene_number_component_key : @ecs.ComponentKey[SceneNumber] = @ecs.register_component(
  debug_name="examples.3d.tonemapping.SceneNumber",
)

///|
let hdr_viewer_component_key : @ecs.ComponentKey[HDRViewer] = @ecs.register_component(
  debug_name="examples.3d.tonemapping.HDRViewer",
)

///|
let tonemapping_ui_root_component_key : @ecs.ComponentKey[TonemappingUiRoot] = @ecs.register_component(
  debug_name="examples.3d.tonemapping.TonemappingUiRoot",
)

///|
let tonemapping_ui_text_component_key : @ecs.ComponentKey[TonemappingUiText] = @ecs.register_component(
  debug_name="examples.3d.tonemapping.TonemappingUiText",
)

///|
let image_viewer_text_component_key : @ecs.ComponentKey[ImageViewerText] = @ecs.register_component(
  debug_name="examples.3d.tonemapping.ImageViewerText",
)

///|
impl @app.Resource for CameraTransform with resource() {
  camera_transform_resource_key
}

///|
impl @app.Resource for CurrentScene with resource() {
  current_scene_resource_key
}

///|
impl @app.Resource for SelectedParameter with resource() {
  selected_parameter_resource_key
}

///|
impl @app.Resource for PerMethodSettings with resource() {
  per_method_settings_resource_key
}

///|
impl @ecs.Component for SceneNumber with component() {
  scene_number_component_key
}

///|
impl @ecs.Component for HDRViewer with component() {
  hdr_viewer_component_key
}

///|
impl @ecs.Component for TonemappingUiRoot with component() {
  tonemapping_ui_root_component_key
}

///|
impl @ecs.Component for TonemappingUiText with component() {
  tonemapping_ui_text_component_key
}

///|
impl @ecs.Component for ImageViewerText with component() {
  image_viewer_text_component_key
}

///|
impl Default for CameraTransform with default() {
  {
    transform: @math.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  }
}

///|
impl Default for CurrentScene with default() {
  { value: 1 }
}

///|
impl Default for SelectedParameter with default() {
  { value: 0, max: PARAMETER_COUNT }
}

///|
fn SelectedParameter::next(self : SelectedParameter) -> Unit {
  self.value = (self.value + 1) % self.max
}

///|
fn SelectedParameter::prev(self : SelectedParameter) -> Unit {
  self.value = (self.value + self.max - 1) % self.max
}

///|
fn method_name(tonemapper : @render3d.Tonemapping) -> String {
  match tonemapper {
    None => "Disabled"
    Reinhard => "Reinhard"
    ReinhardLuminance => "Reinhard Luminance"
    AcesFitted => "ACES Fitted"
    AgX => "AgX"
    SomewhatBoringDisplayTransform => "SomewhatBoringDisplayTransform"
    TonyMcMapface => "TonyMcMapface"
    BlenderFilmic => "Blender Filmic"
  }
}

///|
fn tonemapping_methods() -> Array[@render3d.Tonemapping] {
  [
    @render3d.Tonemapping::None,
    @render3d.Tonemapping::Reinhard,
    @render3d.Tonemapping::ReinhardLuminance,
    @render3d.Tonemapping::AcesFitted,
    @render3d.Tonemapping::AgX,
    @render3d.Tonemapping::SomewhatBoringDisplayTransform,
    @render3d.Tonemapping::TonyMcMapface,
    @render3d.Tonemapping::BlenderFilmic,
  ]
}

///|
fn PerMethodSettings::basic_scene_recommendation(
  tonemapper : @render3d.Tonemapping,
) -> @render3d.ColorGrading {
  match tonemapper {
    Reinhard | ReinhardLuminance =>
      @render3d.ColorGrading::{
        ..@render3d.ColorGrading::default(),
        global: @render3d.ColorGradingGlobal::{
          ..@render3d.ColorGradingGlobal::default(),
          exposure: 0.5F,
        },
      }
    AcesFitted =>
      @render3d.ColorGrading::{
        ..@render3d.ColorGrading::default(),
        global: @render3d.ColorGradingGlobal::{
          ..@render3d.ColorGradingGlobal::default(),
          exposure: 0.35F,
        },
      }
    AgX =>
      @render3d.ColorGrading::with_identical_sections(
        @render3d.ColorGradingGlobal::{
          ..@render3d.ColorGradingGlobal::default(),
          exposure: -0.2F,
          post_saturation: 1.1F,
        },
        @render3d.ColorGradingSection::{
          ..@render3d.ColorGradingSection::default(),
          saturation: 1.1F,
        },
      )
    _ => @render3d.ColorGrading::default()
  }
}

///|
impl Default for PerMethodSettings with default() {
  let settings : @hashmap.HashMap[@render3d.Tonemapping, @render3d.ColorGrading] = @hashmap.HashMap::new()
  for tonemapper in tonemapping_methods() {
    settings.set(
      tonemapper,
      PerMethodSettings::basic_scene_recommendation(tonemapper),
    )
  }
  { settings, }
}

///|
fn tonemapping_world() -> @ecs.World? {
  @app.current_world()
}

///|
fn[T] first_marked_entity(
  world : @ecs.World,
  component_key : @ecs.ComponentKey[T],
) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(@ecs.With::new(component_key))
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
  result.val
}

///|
fn tonemapping_camera_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world, @render3d.ecs_key_camera3d)
}

///|
fn tonemapping_ui_root_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world, TonemappingUiRoot::component())
}

///|
fn tonemapping_ui_text_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world, TonemappingUiText::component())
}

///|
fn image_viewer_text_entity(world : @ecs.World) -> @core.Entity? {
  first_marked_entity(world, ImageViewerText::component())
}

///|
fn current_scene_value(world : @ecs.World) -> Int {
  match (try! world.get_resource(CurrentScene::resource())) {
    Some(current_scene) => current_scene.value
    None => 1
  }
}

///|
fn selected_parameter_value(world : @ecs.World) -> Int {
  match (try! world.get_resource(SelectedParameter::resource())) {
    Some(selected_parameter) => selected_parameter.value
    None => 0
  }
}

///|
fn current_tonemapping(world : @ecs.World) -> @render3d.Tonemapping {
  guard tonemapping_camera_entity(world) is Some(camera) else {
    return @render3d.Tonemapping::default()
  }
  match world.component(@render3d.ecs_key_tonemapping).get(camera) {
    Some(tonemapping) => tonemapping
    None => @render3d.Tonemapping::default()
  }
}

///|
fn current_color_grading(world : @ecs.World) -> @render3d.ColorGrading {
  guard tonemapping_camera_entity(world) is Some(camera) else {
    return @render3d.ColorGrading::default()
  }
  match world.component(@render3d.ecs_key_color_grading).get(camera) {
    Some(color_grading) => color_grading
    None => @render3d.ColorGrading::default()
  }
}

///|
fn selected_marker(selected : Bool) -> String {
  if selected {
    "> "
  } else {
    ""
  }
}

///|
fn ui_text_content(world : @ecs.World) -> String {
  let scene = current_scene_value(world)
  let tonemapping = current_tonemapping(world)
  let color_grading = current_color_grading(world)
  let selected_parameter = selected_parameter_value(world)

  let mut content = "(H) Hide UI\n\n" +
    "Test Scene:\n" +
    "(Q) " +
    selected_marker(scene == 1) +
    "Basic Scene\n" +
    "(W) " +
    selected_marker(scene == 2) +
    "Color Sweep\n" +
    "(E) " +
    selected_marker(scene == 3) +
    "Image Viewer\n\n" +
    "Tonemapping Method:\n" +
    "(1) " +
    selected_marker(tonemapping == @render3d.Tonemapping::None) +
    "Disabled\n" +
    "(2) " +
    selected_marker(tonemapping == @render3d.Tonemapping::Reinhard) +
    "Reinhard\n" +
    "(3) " +
    selected_marker(tonemapping == @render3d.Tonemapping::ReinhardLuminance) +
    "Reinhard Luminance\n" +
    "(4) " +
    selected_marker(tonemapping == @render3d.Tonemapping::AcesFitted) +
    "ACES Fitted\n" +
    "(5) " +
    selected_marker(tonemapping == @render3d.Tonemapping::AgX) +
    "AgX\n" +
    "(6) " +
    selected_marker(
      tonemapping == @render3d.Tonemapping::SomewhatBoringDisplayTransform,
    ) +
    "SomewhatBoringDisplayTransform\n" +
    "(7) " +
    selected_marker(tonemapping == @render3d.Tonemapping::TonyMcMapface) +
    "TonyMcMapface\n" +
    "(8) " +
    selected_marker(tonemapping == @render3d.Tonemapping::BlenderFilmic) +
    "Blender Filmic\n\n" +
    "Color Grading:\n" +
    "(arrow keys)\n" +
    selected_marker(selected_parameter == 0) +
    "Exposure: \{color_grading.global.exposure}\n" +
    selected_marker(selected_parameter == 1) +
    "Gamma: \{color_grading.shadows.gamma}\n" +
    selected_marker(selected_parameter == 2) +
    "PreSaturation: \{color_grading.shadows.saturation}\n" +
    selected_marker(selected_parameter == 3) +
    "PostSaturation: \{color_grading.global.post_saturation}\n" +
    "(Space) Reset all to default\n"

  if scene == 1 {
    content = content + "(Enter) Reset all to scene recommendation\n"
  }

  content + "\nActive Method: " + method_name(tonemapping)
}

///|
fn set_ui_text(world : @ecs.World, content : String) -> Unit {
  guard tonemapping_ui_text_entity(world) is Some(entity) else { return }
  guard world.component(@ui.ecs_key_ui_text).get(entity) is Some(ui_text) else {
    return
  }
  @text.text_set_content(ui_text.handle, content)
}

///|
fn apply_scene_visibility(world : @ecs.World) -> Unit {
  let scene = current_scene_value(world)
  let tick = world.increment_change_tick()
  let visibility_store = world.component(@visibility.ecs_key_visibility)
  world
  .component(SceneNumber::component())
  .for_each(fn(entity, scene_number) {
    let visibility = if scene_number.value == scene {
      @visibility.Visibility::Inherited
    } else {
      @visibility.Visibility::Hidden
    }
    if visibility_store.contains(entity) {
      visibility_store.set(entity, visibility, tick) |> ignore
    } else {
      visibility_store.insert(entity, visibility, tick)
    }
  })
}

///|
fn apply_current_method_color_grading(world : @ecs.World) -> Unit {
  guard tonemapping_camera_entity(world) is Some(camera) else { return }
  guard (try! world.get_resource(PerMethodSettings::resource()))
    is Some(per_method_settings) else {
    return
  }
  let tonemapping = current_tonemapping(world)
  guard per_method_settings.settings.get(tonemapping) is Some(color_grading) else {
    return
  }
  let tick = world.increment_change_tick()
  let color_grading_store = world.component(@render3d.ecs_key_color_grading)
  if color_grading_store.contains(camera) {
    color_grading_store.set(camera, color_grading, tick) |> ignore
  } else {
    color_grading_store.insert(camera, color_grading, tick)
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  camera_transform : @app.Res[CameraTransform],
) -> Unit {
  let camera = commands.spawn(
    @render3d.Camera3dBundle::new(
      @render2d.Camera::default(),
      camera_transform.get().transform,
    )
    .with_color_grading(Some(@render3d.ColorGrading::default()))
    .with_distance_fog(
      Some(
        @render3d.DistanceFog::new(
          @render2d.Color::srgb(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F),
          @render3d.FogFalloff3d::linear(1.0F, 8.0F),
        ),
      ),
    ),
  )
  commands
  .entity(camera)
  .insert(
    (
      @render3d.Hdr::default(),
      @render3d.EnvironmentMapLight::new(
        Some(
          asset_server
          .get()
          .load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
        ),
        Some(
          asset_server
          .get()
          .load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
        ),
        2000.0F,
      ),
    ),
  )

  let overlay_camera = commands.spawn(
    @render2d.Camera2dBundle::new(
      @render2d.Camera::default().with_order(100).with_clear_color_none(),
      @math.Transform::identity(),
    ),
  )
  commands
  .entity(overlay_camera)
  .insert_component(@ui.IsDefaultUiCamera::default())

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      TonemappingUiRoot::{  },
    ),
  )

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default().with_font(font).with_font_size(15.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@render2d.Color::white()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .spawn()

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @ui.UiText::new(text_handle),
        TonemappingUiText::{  },
      ),
    ),
  )
}

///|
fn initialize_tonemapping(world : @ecs.World) -> Unit {
  apply_current_method_color_grading(world)
  apply_scene_visibility(world)
  set_ui_text(world, ui_text_content(world))
}

///|
fn setup_basic_scene(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server.get(),
            @scene.GltfAssetLabel::Scene(0).from_asset(
              "models/TonemappingTest/TonemappingTest.gltf",
            ),
          ),
        ),
        SceneNumber::{ value: 1 },
        @visibility.Visibility::Inherited,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @scene.SceneRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server.get(),
            @scene.GltfAssetLabel::Scene(0).from_asset(
              "models/FlightHelmet/FlightHelmet.gltf",
            ),
          ),
        ),
        @math.Transform::from_xyz(0.5F, 0.0F, -0.5F).with_rotation(
          @math.Quat::from_rotation_y(-0.15F * PI),
        ),
        SceneNumber::{ value: 1 },
        @visibility.Visibility::Inherited,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @render3d.DirectionalLight::new(
          @render2d.Color::white(),
          15_000.0F,
          true,
        ).with_cascade_shadow_config_builder(
          @render3d.CascadeShadowConfigBuilder::default()
          .with_maximum_distance(3.0F)
          .with_first_cascade_far_bound(0.9F),
        ),
        @math.Transform::from_rotation(
          @math.Quat::from_euler(
            @math.EulerRot::ZYX,
            0.0F,
            PI * -0.15F,
            PI * -0.15F,
          ),
        ),
        SceneNumber::{ value: 1 },
        @visibility.Visibility::Inherited,
      ),
    ),
  )
}

///|
fn setup_color_gradient_scene(_world : @ecs.World) -> Unit {
  ()
}

///|
fn setup_image_viewer_scene(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  material_assets : @app.ResMut[@asset.Assets[@render3d.StandardMaterial]],
  camera_transform : @app.Res[CameraTransform],
) -> Unit {
  let mesh_handle = mesh_assets.get_ref().val.add(
    @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::rectangle(1.0F, 1.0F)),
  )
  let material_handle = material_assets.get_ref().val.add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()).with_unlit(
      true,
    ),
  )

  let transform = camera_transform.get().transform
  transform.translation = transform.translation.add(transform.forward())

  ignore(
    commands.spawn(
      (
        @render3d.Mesh3d::new(mesh_handle),
        @render3d.MeshMaterial3d::new(material_handle),
        transform,
        @visibility.Visibility::Hidden,
        SceneNumber::{ value: 3 },
        HDRViewer::{  },
      ),
    ),
  )

  guard tonemapping_world() is Some(world) else { return }
  guard tonemapping_ui_root_entity(world) is Some(root) else { return }
  let prompt_handle = @text.Text2dBundle::new(
      @text.Text2d::new("Drag and drop an HDR or EXR file"),
      @text.TextFont::default()
      .with_font(asset_server.get().load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(36.0F),
      @math.Transform::identity(),
    )
    .with_color(@text.TextColor::new(@render2d.Color::black()))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
    .spawn()
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::{
          ..@ui.Node::default(),
          align_self: @ui.AlignSelf::Center,
          margin: @ui.UiRect::all(@ui.Val::Auto),
        },
        @ui.UiText::new(prompt_handle),
        SceneNumber::{ value: 3 },
        @visibility.Visibility::Hidden,
        ImageViewerText::{  },
      ),
    ),
  )
}

///|
fn toggle_scene(keys : @input.ButtonInput[@window.KeyCode]) -> Unit {
  let next_scene = if keys.just_pressed(KeyQ) {
    Some(1)
  } else if keys.just_pressed(KeyW) {
    Some(2)
  } else if keys.just_pressed(KeyE) {
    Some(3)
  } else {
    None
  }
  guard next_scene is Some(scene) else { return }
  guard tonemapping_world() is Some(world) else { return }
  let tick = world.increment_change_tick()
  guard (try! world.get_resource_ref_mut(CurrentScene::resource(), tick))
    is Some(current_scene) else {
    return
  }
  current_scene.val.value = scene
  apply_scene_visibility(world)
}

///|
fn toggle_tonemapping_method(
  keys : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  let next_method = if keys.just_pressed(Digit1) {
    Some(@render3d.Tonemapping::None)
  } else if keys.just_pressed(Digit2) {
    Some(@render3d.Tonemapping::Reinhard)
  } else if keys.just_pressed(Digit3) {
    Some(@render3d.Tonemapping::ReinhardLuminance)
  } else if keys.just_pressed(Digit4) {
    Some(@render3d.Tonemapping::AcesFitted)
  } else if keys.just_pressed(Digit5) {
    Some(@render3d.Tonemapping::AgX)
  } else if keys.just_pressed(Digit6) {
    Some(@render3d.Tonemapping::SomewhatBoringDisplayTransform)
  } else if keys.just_pressed(Digit7) {
    Some(@render3d.Tonemapping::TonyMcMapface)
  } else if keys.just_pressed(Digit8) {
    Some(@render3d.Tonemapping::BlenderFilmic)
  } else {
    None
  }
  guard next_method is Some(tonemapper) else { return }
  guard tonemapping_world() is Some(world) else { return }
  guard tonemapping_camera_entity(world) is Some(camera) else { return }
  let tick = world.increment_change_tick()
  let tonemapping_store = world.component(@render3d.ecs_key_tonemapping)
  if tonemapping_store.contains(camera) {
    tonemapping_store.set(camera, tonemapper, tick) |> ignore
  } else {
    tonemapping_store.insert(camera, tonemapper, tick)
  }
  apply_current_method_color_grading(world)
}

///|
fn update_color_grading_settings(
  keys : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  guard tonemapping_world() is Some(world) else { return }

  let tick = world.increment_change_tick()
  guard (try! world.get_resource_ref_mut(SelectedParameter::resource(), tick))
    is Some(selected_parameter) else {
    return
  }
  if keys.just_pressed(ArrowDown) {
    selected_parameter.val.next()
  }
  if keys.just_pressed(ArrowUp) {
    selected_parameter.val.prev()
  }

  let mut delta = time.get().delta_seconds() * 0.25F
  if keys.pressed(ArrowLeft) {
    delta = -delta
  } else if !keys.pressed(ArrowRight) {
    delta = 0.0F
  }

  guard (try! world.get_resource_ref_mut(PerMethodSettings::resource(), tick))
    is Some(per_method_settings) else {
    return
  }

  let current_method = current_tonemapping(world)
  if delta != 0.0F {
    let current = per_method_settings.val.settings
      .get(current_method)
      .unwrap_or(@render3d.ColorGrading::default())
    let next = match selected_parameter.val.value {
      0 =>
        @render3d.ColorGrading::{
          ..current,
          global: @render3d.ColorGradingGlobal::{
            ..current.global,
            exposure: current.global.exposure + delta,
          },
        }
      1 =>
        @render3d.ColorGrading::{
          ..current,
          shadows: @render3d.ColorGradingSection::{
            ..current.shadows,
            gamma: current.shadows.gamma + delta,
          },
          midtones: @render3d.ColorGradingSection::{
            ..current.midtones,
            gamma: current.midtones.gamma + delta,
          },
          highlights: @render3d.ColorGradingSection::{
            ..current.highlights,
            gamma: current.highlights.gamma + delta,
          },
        }
      2 =>
        @render3d.ColorGrading::{
          ..current,
          shadows: @render3d.ColorGradingSection::{
            ..current.shadows,
            saturation: current.shadows.saturation + delta,
          },
          midtones: @render3d.ColorGradingSection::{
            ..current.midtones,
            saturation: current.midtones.saturation + delta,
          },
          highlights: @render3d.ColorGradingSection::{
            ..current.highlights,
            saturation: current.highlights.saturation + delta,
          },
        }
      _ =>
        @render3d.ColorGrading::{
          ..current,
          global: @render3d.ColorGradingGlobal::{
            ..current.global,
            post_saturation: current.global.post_saturation + delta,
          },
        }
    }
    per_method_settings.val.settings.set(current_method, next)
    apply_current_method_color_grading(world)
  }

  if keys.just_pressed(Space) {
    for tonemapper in tonemapping_methods() {
      per_method_settings.val.settings.set(
        tonemapper,
        @render3d.ColorGrading::default(),
      )
    }
    apply_current_method_color_grading(world)
  }

  if keys.just_pressed(Enter) && current_scene_value(world) == 1 {
    for tonemapper in tonemapping_methods() {
      per_method_settings.val.settings.set(
        tonemapper,
        PerMethodSettings::basic_scene_recommendation(tonemapper),
      )
    }
    apply_current_method_color_grading(world)
  }
}

///|
fn drag_drop_image(
  drag_and_drop_reader : @ecs.MessageReader[@input.FileDragAndDrop],
  asset_server : @app.Res[@asset.AssetServer],
  material_assets : @app.ResMut[@asset.Assets[@render3d.StandardMaterial]],
  commands : @app.Commands,
) -> Unit {
  let mut new_image : @asset.Handle[@asset.Image]? = None
  for event in (try! drag_and_drop_reader.read()) {
    match event {
      DroppedFile(path) => new_image = Some(asset_server.get().load(path))
      _ => ()
    }
  }
  guard new_image is Some(image) else { return }
  guard tonemapping_world() is Some(world) else { return }

  guard first_marked_entity(world, HDRViewer::component())
    is Some(viewer_entity) else {
    return
  }
  guard world.component(@render3d.ecs_key_mesh_material3d).get(viewer_entity)
    is Some(viewer_material) else {
    return
  }
  guard material_assets.get_ref().val.get(viewer_material.material)
    is Some(material) else {
    return
  }
  ignore(
    material_assets.get_ref().val.set(
      viewer_material.material,
      material.with_base_color_texture(Some(image)),
    ),
  )

  if image_viewer_text_entity(world) is Some(text_entity) {
    commands.entity(text_entity).despawn()
  }
}

///|
fn resize_image(
  image_event_reader : @ecs.MessageReader[@asset.AssetEvent[@asset.Image]],
  material_assets : @app.Res[@asset.Assets[@render3d.StandardMaterial]],
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  let updated_images : Array[@asset.Handle[@asset.Image]] = []
  for event in (try! image_event_reader.read()) {
    match event {
      Added(handle) => updated_images.push(handle)
      Modified(handle) => updated_images.push(handle)
      _ => ()
    }
  }
  if updated_images.length() == 0 {
    return
  }
  guard tonemapping_world() is Some(world) else { return }
  guard first_marked_entity(world, HDRViewer::component())
    is Some(viewer_entity) else {
    return
  }
  guard world.component(@render3d.ecs_key_mesh_material3d).get(viewer_entity)
    is Some(viewer_material) else {
    return
  }
  guard world.component(@render3d.ecs_key_mesh3d).get(viewer_entity)
    is Some(viewer_mesh) else {
    return
  }
  guard material_assets.get().get(viewer_material.material) is Some(material) else {
    return
  }
  guard material.base_color_texture is Some(texture) else { return }

  let mut image_changed = false
  for handle in updated_images {
    if handle.id() == texture.id() {
      image_changed = true
    }
  }
  if !image_changed {
    return
  }

  let size = @math.Vec2::new(
      Float::from_int(@asset.asset_texture_width(texture)),
      Float::from_int(@asset.asset_texture_height(texture)),
    )
    .normalize_or_zero()
    .mul_scalar(1.4F)

  ignore(
    mesh_assets.get_ref().val.insert(
      viewer_mesh.mesh,
      @mesh.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::rectangle(size.x, size.y),
      ),
    ),
  )
}

///|
fn update_ui(
  keys : @input.ButtonInput[@window.KeyCode],
  hide_ui : @app.Local[Bool],
) -> Unit {
  if keys.just_pressed(KeyH) {
    hide_ui.get_ref().val = !hide_ui.get()
  }
  guard tonemapping_world() is Some(world) else { return }
  if hide_ui.get() {
    set_ui_text(world, "")
    return
  }
  set_ui_text(world, ui_text_content(world))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .insert_resource(CameraTransform::default())
  .insert_resource(PerMethodSettings::default())
  .insert_resource(CurrentScene::default())
  .insert_resource(SelectedParameter::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup_basic_scene)))
  .add_systems(@app.Startup, @app.system(setup_color_gradient_scene))
  .add_systems(
    @app.Startup,
    @app.system(@app.system_param5(setup_image_viewer_scene)),
  )
  .add_systems(@app.Startup, @app.system(initialize_tonemapping))
  .add_systems(@app.Update, @app.system(@app.system_param4(drag_drop_image)))
  .add_systems(@app.Update, @app.system(@app.system_param3(resize_image)))
  .add_systems(@app.Update, @app.system(@app.system_param(toggle_scene)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(toggle_tonemapping_method)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(update_color_grading_settings)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(update_ui)))
  .run()
}
