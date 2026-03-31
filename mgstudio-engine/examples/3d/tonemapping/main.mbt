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
/// The Bevy resource/component/system structure is preserved here.
/// The scene-2 custom material path remains unavailable because
/// mgstudio still lacks Bevy-equivalent custom 3D material APIs.

///|
const PI : Float = 3.141592653589793F

///|
const PARAMETER_COUNT : Int = 4

///|
struct CameraTransform {
  transform : @transform.Transform
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
  settings : @hashmap.HashMap[
    @post_process.Tonemapping,
    @post_process.ColorGrading,
  ]
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
impl Default for CameraTransform with default() {
  {
    transform: @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
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
fn method_name(tonemapper : @post_process.Tonemapping) -> String {
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
fn tonemapping_methods() -> Array[@post_process.Tonemapping] {
  [
    @post_process.Tonemapping::None,
    @post_process.Tonemapping::Reinhard,
    @post_process.Tonemapping::ReinhardLuminance,
    @post_process.Tonemapping::AcesFitted,
    @post_process.Tonemapping::AgX,
    @post_process.Tonemapping::SomewhatBoringDisplayTransform,
    @post_process.Tonemapping::TonyMcMapface,
    @post_process.Tonemapping::BlenderFilmic,
  ]
}

///|
fn PerMethodSettings::basic_scene_recommendation(
  tonemapper : @post_process.Tonemapping,
) -> @post_process.ColorGrading {
  match tonemapper {
    Reinhard | ReinhardLuminance =>
      @post_process.ColorGrading::{
        ..@post_process.ColorGrading::default(),
        global: @post_process.ColorGradingGlobal::{
          ..@post_process.ColorGradingGlobal::default(),
          exposure: 0.5F,
        },
      }
    AcesFitted =>
      @post_process.ColorGrading::{
        ..@post_process.ColorGrading::default(),
        global: @post_process.ColorGradingGlobal::{
          ..@post_process.ColorGradingGlobal::default(),
          exposure: 0.35F,
        },
      }
    AgX =>
      @post_process.ColorGrading::with_identical_sections(
        @post_process.ColorGradingGlobal::{
          ..@post_process.ColorGradingGlobal::default(),
          exposure: -0.2F,
          post_saturation: 1.1F,
        },
        @post_process.ColorGradingSection::{
          ..@post_process.ColorGradingSection::default(),
          saturation: 1.1F,
        },
      )
    _ => @post_process.ColorGrading::default()
  }
}

///|
impl Default for PerMethodSettings with default() {
  let settings : @hashmap.HashMap[
    @post_process.Tonemapping,
    @post_process.ColorGrading,
  ] = @hashmap.HashMap::new()
  for tonemapper in tonemapping_methods() {
    settings.set(
      tonemapper,
      PerMethodSettings::basic_scene_recommendation(tonemapper),
    )
  }
  { settings, }
}

///|
fn[D : @ecs.QueryData, F : @ecs.QueryFilter] first_entity(
  query : @ecs.Query[D, F],
) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  try! query.view(fn(entity, _component) {
    if result.val is None {
      result.val = Some(entity)
    }
  })
  result.val
}

///|
fn[A : @ecs.Component, B : @ecs.Component] first2(
  query : @ecs.Query[(@ecs.Comp[A], @ecs.Comp[B]), @ecs.All],
) -> (@core.Entity, A, B)? {
  let result : Ref[(@core.Entity, A, B)?] = Ref::new(None)
  try! query.view(fn(entity, data) {
    let (first, second) = data
    if result.val is None {
      result.val = Some((entity, first.value(), second.value()))
    }
  })
  result.val
}

///|
fn[A : @ecs.Component, B : @ecs.Component, C : @ecs.Component] first3(
  query : @ecs.Query[(@ecs.Comp[A], @ecs.Comp[B], @ecs.Comp[C]), @ecs.All],
) -> (@core.Entity, A, B, C)? {
  let result : Ref[(@core.Entity, A, B, C)?] = Ref::new(None)
  try! query.view(fn(entity, data) {
    let (first, second, third) = data
    if result.val is None {
      result.val = Some((entity, first.value(), second.value(), third.value()))
    }
  })
  result.val
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
fn ui_text_content(
  scene : Int,
  tonemapping : @post_process.Tonemapping,
  color_grading : @post_process.ColorGrading,
  selected_parameter : Int,
) -> String {
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
    selected_marker(tonemapping == @post_process.Tonemapping::None) +
    "Disabled\n" +
    "(2) " +
    selected_marker(tonemapping == @post_process.Tonemapping::Reinhard) +
    "Reinhard\n" +
    "(3) " +
    selected_marker(tonemapping == @post_process.Tonemapping::ReinhardLuminance) +
    "Reinhard Luminance\n" +
    "(4) " +
    selected_marker(tonemapping == @post_process.Tonemapping::AcesFitted) +
    "ACES Fitted\n" +
    "(5) " +
    selected_marker(tonemapping == @post_process.Tonemapping::AgX) +
    "AgX\n" +
    "(6) " +
    selected_marker(
      tonemapping == @post_process.Tonemapping::SomewhatBoringDisplayTransform,
    ) +
    "SomewhatBoringDisplayTransform\n" +
    "(7) " +
    selected_marker(tonemapping == @post_process.Tonemapping::TonyMcMapface) +
    "TonyMcMapface\n" +
    "(8) " +
    selected_marker(tonemapping == @post_process.Tonemapping::BlenderFilmic) +
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
fn set_ui_text(text_value : @text.Text, content : String) -> Unit {
  text_value.content = content
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  camera_transform : @app.Res[CameraTransform],
) -> Unit {
  let camera = commands.spawn(
    @pbr.Camera3dBundle::new(
      @sprite.Camera::default(),
      camera_transform.get().transform,
    )
    .with_color_grading(Some(@post_process.ColorGrading::default()))
    .with_distance_fog(
      Some(
        @pbr.DistanceFog::new(
          @sprite.Color::srgb(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F),
          @pbr.FogFalloff3d::linear(1.0F, 8.0F),
        ),
      ),
    ),
  )
  commands
  .entity(camera)
  .insert(
    (
      @pbr.Hdr::default(),
      @pbr.EnvironmentMapLight::new(
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
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
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

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(12.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @text.Text::new(""),
        @text.TextFont::default().with_font(font).with_font_size(15.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
        TonemappingUiText::{  },
      ),
    ),
  )
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
            @gltf.GltfAssetLabel::Scene(0).from_asset(
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
            @gltf.GltfAssetLabel::Scene(0).from_asset(
              "models/FlightHelmet/FlightHelmet.gltf",
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.5F, 0.0F, -0.5F).with_rotation(
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
        @pbr.DirectionalLight::new(@sprite.Color::white(), 15_000.0F, true).with_cascade_shadow_config_builder(
          @pbr.CascadeShadowConfigBuilder::default()
          .with_maximum_distance(3.0F)
          .with_first_cascade_far_bound(0.9F),
        ),
        @transform.Transform::from_rotation(
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
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  camera_transform : @app.Res[CameraTransform],
  ui_root_query : @ecs.Query[@ecs.Comp[TonemappingUiRoot], @ecs.All],
) -> Unit {
  let mesh_handle = mesh_assets.get_ref().val.add(
    @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::rectangle(1.0F, 1.0F)),
  )
  let material_handle = material_assets.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_unlit(true),
  )

  let transform = camera_transform.get().transform
  transform.translation = transform.translation.add(transform.forward())

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(mesh_handle),
        @pbr.MeshMaterial3d::new(material_handle),
        transform,
        @visibility.Visibility::Hidden,
        SceneNumber::{ value: 3 },
        HDRViewer::{  },
      ),
    ),
  )

  guard first_entity(ui_root_query) is Some(root) else { return }
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::{
          ..@ui.Node::default(),
          align_self: @ui.AlignSelf::Center,
          margin: @ui.UiRect::all(@ui.Val::Auto),
        },
        @text.Text::new("Drag and drop an HDR or EXR file"),
        @text.TextFont::default()
        .with_font(asset_server.get().load_font("fonts/FiraSans-Bold.ttf"))
        .with_font_size(36.0F),
        @text.TextColor::new(@sprite.Color::black()),
        @text.TextLayout::new_with_justify(@text.Justify::Center),
        SceneNumber::{ value: 3 },
        @visibility.Visibility::Hidden,
      ),
    ),
  )
}

///|
fn toggle_scene(
  keys : @input.ButtonInput[@window.KeyCode],
  visibility_query : @ecs.Query[@ecs.Mut[@visibility.Visibility], @ecs.All],
  current_scene : @app.ResMut[CurrentScene],
  scene_query : @ecs.Query[@ecs.Comp[SceneNumber], @ecs.All],
) -> Unit {
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
  current_scene.get_ref().val.value = scene

  try! scene_query.view(fn(entity, scene_number) {
    let visibility = if scene_number.value().value == scene {
      @visibility.Visibility::Inherited
    } else {
      @visibility.Visibility::Hidden
    }
    if (visibility_query.get(entity) catch { _ => None }) is Some(component) {
      component.get_ref().val = visibility
    }
  })
}

///|
fn toggle_tonemapping_method(
  keys : @input.ButtonInput[@window.KeyCode],
  tonemapping_query : @ecs.Query[@ecs.Mut[@post_process.Tonemapping], @ecs.All],
  color_grading_query : @ecs.Query[
    @ecs.Mut[@post_process.ColorGrading],
    @ecs.All,
  ],
  per_method_settings : @app.Res[PerMethodSettings],
) -> Unit {
  let next_method = if keys.just_pressed(Digit1) {
    Some(@post_process.Tonemapping::None)
  } else if keys.just_pressed(Digit2) {
    Some(@post_process.Tonemapping::Reinhard)
  } else if keys.just_pressed(Digit3) {
    Some(@post_process.Tonemapping::ReinhardLuminance)
  } else if keys.just_pressed(Digit4) {
    Some(@post_process.Tonemapping::AcesFitted)
  } else if keys.just_pressed(Digit5) {
    Some(@post_process.Tonemapping::AgX)
  } else if keys.just_pressed(Digit6) {
    Some(@post_process.Tonemapping::SomewhatBoringDisplayTransform)
  } else if keys.just_pressed(Digit7) {
    Some(@post_process.Tonemapping::TonyMcMapface)
  } else if keys.just_pressed(Digit8) {
    Some(@post_process.Tonemapping::BlenderFilmic)
  } else {
    None
  }
  guard first_entity(tonemapping_query) is Some(camera) else { return }
  guard (tonemapping_query.get(camera) catch { _ => None })
    is Some(initial_tonemapping) else {
    return
  }

  let mut current_tonemapping = initial_tonemapping.value()
  if next_method is Some(tonemapper) {
    if (tonemapping_query.get(camera) catch { _ => None }) is Some(component) {
      component.get_ref().val = tonemapper
      current_tonemapping = tonemapper
    }
  }

  guard per_method_settings.get().settings.get(current_tonemapping)
    is Some(color_grading) else {
    return
  }
  if (color_grading_query.get(camera) catch { _ => None }) is Some(component) {
    component.get_ref().val = color_grading
  }
}

///|
fn update_color_grading_settings(
  keys : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
  per_method_settings : @app.ResMut[PerMethodSettings],
  tonemapping_query : @ecs.Query[@ecs.Mut[@post_process.Tonemapping], @ecs.All],
  current_scene : @app.Res[CurrentScene],
  selected_parameter : @app.ResMut[SelectedParameter],
) -> Unit {
  guard first_entity(tonemapping_query) is Some(camera) else { return }
  guard (tonemapping_query.get(camera) catch { _ => None })
    is Some(current_method) else {
    return
  }
  let current_method = current_method.value()

  if keys.just_pressed(ArrowDown) {
    selected_parameter.get_ref().val.next()
  }
  if keys.just_pressed(ArrowUp) {
    selected_parameter.get_ref().val.prev()
  }

  let mut delta = time.get().delta_seconds() * 0.25F
  if keys.pressed(ArrowLeft) {
    delta = -delta
  } else if !keys.pressed(ArrowRight) {
    delta = 0.0F
  }

  if delta != 0.0F {
    let next = per_method_settings.get_ref().val.settings
      .get(current_method)
      .unwrap_or(@post_process.ColorGrading::default())
    match selected_parameter.get_ref().val.value {
      0 => next.global.exposure = next.global.exposure + delta
      1 =>
        for section in next.all_sections_mut() {
          section.gamma = section.gamma + delta
        }
      2 =>
        for section in next.all_sections_mut() {
          section.saturation = section.saturation + delta
        }
      _ => next.global.post_saturation = next.global.post_saturation + delta
    }
    per_method_settings.get_ref().val.settings.set(current_method, next)
  }

  if keys.just_pressed(Space) {
    for tonemapper in tonemapping_methods() {
      per_method_settings.get_ref().val.settings.set(
        tonemapper,
        @post_process.ColorGrading::default(),
      )
    }
  }

  if keys.just_pressed(Enter) && current_scene.get().value == 1 {
    for tonemapper in tonemapping_methods() {
      per_method_settings.get_ref().val.settings.set(
        tonemapper,
        PerMethodSettings::basic_scene_recommendation(tonemapper),
      )
    }
  }
}

///|
fn drag_drop_image(
  image_material_query : @ecs.Query[
    (@ecs.Comp[HDRViewer], @ecs.Comp[@pbr.MeshMaterial3d]),
    @ecs.All,
  ],
  image_viewer_text_query : @ecs.Query[
    (@ecs.Comp[@text.Text], @ecs.Comp[SceneNumber]),
    @ecs.All,
  ],
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  drag_and_drop_reader : @ecs.MessageReader[@window.FileDragAndDrop],
  asset_server : @app.Res[@asset.AssetServer],
  commands : @app.Commands,
) -> Unit {
  let mut new_image : @asset.Handle[@asset.Image]? = None
  for event in (try! drag_and_drop_reader.read()) {
    match event {
      DroppedFile(_window, path) =>
        new_image = Some(asset_server.get().load(path))
      _ => ()
    }
  }
  guard new_image is Some(image) else { return }
  guard first2(image_material_query)
    is Some((_viewer_entity, _viewer, viewer_material)) else {
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

  if first2(image_viewer_text_query)
    is Some((text_entity, _text, _scene_number)) {
    commands.entity(text_entity).despawn()
  }
}

///|
fn resize_image(
  image_mesh_query : @ecs.Query[
    (
      @ecs.Comp[HDRViewer],
      @ecs.Comp[@pbr.MeshMaterial3d],
      @ecs.Comp[@pbr.Mesh3d],
    ),
    @ecs.All,
  ],
  image_event_reader : @ecs.MessageReader[@asset.AssetEvent[@asset.Image]],
  material_assets : @app.Res[@asset.Assets[@pbr.StandardMaterial]],
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
  guard first3(image_mesh_query)
    is Some((_viewer_entity, _viewer, viewer_material, viewer_mesh)) else {
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
  current_scene : @app.Res[CurrentScene],
  selected_parameter : @app.Res[SelectedParameter],
  settings_query : @ecs.Query[
    (
      @ecs.Comp[@post_process.Tonemapping],
      @ecs.Comp[@post_process.ColorGrading],
    ),
    @ecs.All,
  ],
  ui_text_query : @ecs.Query[
    (@ecs.Comp[@text.Text], @ecs.Comp[TonemappingUiText]),
    @ecs.All,
  ],
  hide_ui : @app.Local[Bool],
) -> Unit {
  if keys.just_pressed(KeyH) {
    hide_ui.get_ref().val = !hide_ui.get()
  }
  guard first2(ui_text_query) is Some((_entity, ui_text, _marker)) else {
    return
  }
  if hide_ui.get() {
    set_ui_text(ui_text, "")
    return
  }
  guard first2(settings_query) is Some((_camera, tonemapping, color_grading)) else {
    return
  }
  set_ui_text(
    ui_text,
    ui_text_content(
      current_scene.get().value,
      tonemapping,
      color_grading,
      selected_parameter.get().value,
    ),
  )
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
    @app.system(@app.system_param6(setup_image_viewer_scene)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param6(drag_drop_image)))
  .add_systems(@app.Update, @app.system(@app.system_param4(resize_image)))
  .add_systems(@app.Update, @app.system(@app.system_param4(toggle_scene)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(toggle_tonemapping_method)),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param6(update_color_grading_settings)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param6(update_ui)))
  .run()
}
