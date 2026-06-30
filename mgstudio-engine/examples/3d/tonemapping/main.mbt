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
const PI : Float = 3.141592653589793F

///|
const PARAMETER_COUNT : Int = 4

///|
const SHADER_ASSET_PATH : String = "shaders/tonemapping_test_patterns.wgsl"

///|
struct CameraTransform {
  transform : @transform.Transform
}

///|
struct CurrentScene {
  value : Int
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
struct ColorGradientMaterial {}

///|
fn ColorGradientMaterial::ColorGradientMaterial() -> ColorGradientMaterial {
  ColorGradientMaterial::{  }
}

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
let color_gradient_material_asset_keys : @asset.AssetResourceKeys[
  ColorGradientMaterial,
] = @asset.register_asset_resource_keys(
  ColorGradientMaterial::asset_debug_name(),
)

///|
let color_gradient_material_keys : @pbr.MaterialKeys[ColorGradientMaterial] = @pbr.register_material_keys(
  ColorGradientMaterial::asset_debug_name(),
)

///|
impl @app.Resource for CameraTransform with fn resource() {
  camera_transform_resource_key
}

///|
impl @app.Resource for CurrentScene with fn resource() {
  current_scene_resource_key
}

///|
impl @app.Resource for SelectedParameter with fn resource() {
  selected_parameter_resource_key
}

///|
impl @app.Resource for PerMethodSettings with fn resource() {
  per_method_settings_resource_key
}

///|
impl @ecs.Component for SceneNumber with fn component() {
  scene_number_component_key
}

///|
impl @ecs.Component for HDRViewer with fn component() {
  hdr_viewer_component_key
}

///|
impl @asset.Asset for ColorGradientMaterial with fn asset_debug_name() {
  "mgstudio_examples::ColorGradientMaterial"
}

///|
impl @asset.Asset for ColorGradientMaterial with fn asset_as_image(_self) {
  None
}

///|
impl @asset.Asset for ColorGradientMaterial with fn asset_resource_keys() {
  color_gradient_material_asset_keys
}

///|
impl @pbr.Material for ColorGradientMaterial with fn material_debug_name() {
  ColorGradientMaterial::asset_debug_name()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn material_keys() {
  color_gradient_material_keys
}

///|
impl @pbr.Material for ColorGradientMaterial with fn vertex_shader() {
  @pbr.material_default_vertex_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn fragment_shader() {
  Some(SHADER_ASSET_PATH)
}

///|
impl @pbr.Material for ColorGradientMaterial with fn prepass_vertex_shader() {
  @pbr.material_default_vertex_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn prepass_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn deferred_vertex_shader() {
  @pbr.material_default_vertex_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn deferred_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn meshlet_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn meshlet_prepass_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn meshlet_deferred_fragment_shader() {
  @pbr.material_default_fragment_shader()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn alpha_mode(self) {
  ignore(self)
  @pbr.material_default_alpha_mode()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn opaque_render_method(self) {
  ignore(self)
  @pbr.material_default_opaque_render_method()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn depth_bias(self) {
  ignore(self)
  @pbr.material_default_depth_bias()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn reads_view_transmission_texture(
  self,
) {
  ignore(self)
  @pbr.material_default_reads_view_transmission_texture()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn enable_prepass() {
  @pbr.material_default_enable_prepass()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn enable_shadows() {
  @pbr.material_default_enable_shadows()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn bindless_supported(
  render_device,
) {
  @pbr.material_default_bindless_supported(render_device)
}

///|
impl @pbr.Material for ColorGradientMaterial with fn bindless_slot_count() {
  @pbr.material_default_bindless_slot_count()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn bind_group(self) {
  ignore(self)
  @pbr.material_default_bind_group()
}

///|
impl @pbr.Material for ColorGradientMaterial with fn bind_group_layout_descriptor(
  self,
) {
  @pbr.material_default_bind_group_layout_descriptor(self)
}

///|
impl @pbr.Material for ColorGradientMaterial with fn specialize(
  descriptor,
  layout,
  key,
) {
  @pbr.material_default_specialize(descriptor, layout, key)
}

///|
fn CameraTransform::CameraTransform() -> CameraTransform {
  {
    transform: @transform.Transform::from_xyz(0.7F, 0.7F, 1.0F).looking_at(
      @math.Vec3::new(0.0F, 0.3F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  }
}

///|
fn CurrentScene::CurrentScene() -> CurrentScene {
  { value: 1 }
}

///|
fn SelectedParameter::SelectedParameter() -> SelectedParameter {
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
    PbrNeutral => "PBR Neutral"
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
    @post_process.Tonemapping::PbrNeutral,
  ]
}

///|
fn PerMethodSettings::basic_scene_recommendation(
  tonemapper : @post_process.Tonemapping,
) -> @post_process.ColorGrading {
  match tonemapper {
    Reinhard | ReinhardLuminance =>
      @post_process.ColorGrading::{
        ..@post_process.ColorGrading::ColorGrading(),
        global: @post_process.ColorGradingGlobal::{
          ..@post_process.ColorGradingGlobal::ColorGradingGlobal(),
          exposure: 0.5F,
        },
      }
    AcesFitted =>
      @post_process.ColorGrading::{
        ..@post_process.ColorGrading::ColorGrading(),
        global: @post_process.ColorGradingGlobal::{
          ..@post_process.ColorGradingGlobal::ColorGradingGlobal(),
          exposure: 0.35F,
        },
      }
    AgX =>
      @post_process.ColorGrading::with_identical_sections(
        @post_process.ColorGradingGlobal::{
          ..@post_process.ColorGradingGlobal::ColorGradingGlobal(),
          exposure: -0.2F,
          post_saturation: 1.1F,
        },
        @post_process.ColorGradingSection::{
          ..@post_process.ColorGradingSection::ColorGradingSection(),
          saturation: 1.1F,
        },
      )
    _ => @post_process.ColorGrading::ColorGrading()
  }
}

///|
fn PerMethodSettings::PerMethodSettings() -> PerMethodSettings {
  let settings : @hashmap.HashMap[
    @post_process.Tonemapping,
    @post_process.ColorGrading,
  ] = @hashmap.HashMap([])
  for tonemapper in tonemapping_methods() {
    settings.set(
      tonemapper,
      PerMethodSettings::basic_scene_recommendation(tonemapper),
    )
  }
  { settings, }
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
  let some_marker = selected_marker(
    tonemapping == @post_process.Tonemapping::SomewhatBoringDisplayTransform,
  )
  let mut content = "(H) Hide UI\n\nTest Scene:\n(Q) \{selected_marker(scene == 1)}Basic Scene\n(W) \{selected_marker(scene == 2)}Color Sweep\n(E) \{selected_marker(scene == 3)}Image Viewer\n\nTonemapping Method:\n(1) \{selected_marker(tonemapping == @post_process.Tonemapping::None)}Disabled\n(2) \{selected_marker(tonemapping == @post_process.Tonemapping::Reinhard)}Reinhard\n(3) \{selected_marker(tonemapping == @post_process.Tonemapping::ReinhardLuminance)}Reinhard Luminance\n(4) \{selected_marker(tonemapping == @post_process.Tonemapping::AcesFitted)}ACES Fitted\n(5) \{selected_marker(tonemapping == @post_process.Tonemapping::AgX)}AgX\n(6) \{some_marker}SomewhatBoringDisplayTransform\n(7) \{selected_marker(tonemapping == @post_process.Tonemapping::TonyMcMapface)}TonyMcMapface\n(8) \{selected_marker(tonemapping == @post_process.Tonemapping::BlenderFilmic)}Blender Filmic\n(9) \{selected_marker(tonemapping == @post_process.Tonemapping::PbrNeutral)}PBR Neutral\n\nColor Grading:\n(arrow keys)\n\{selected_marker(selected_parameter == 0)}Exposure: \{color_grading.global.exposure}\n\{selected_marker(selected_parameter == 1)}Gamma: \{color_grading.shadows.gamma}\n\{selected_marker(selected_parameter == 2)}PreSaturation: \{color_grading.shadows.saturation}\n\{selected_marker(selected_parameter == 3)}PostSaturation: \{color_grading.global.post_saturation}\n(Space) Reset all to default\n"

  if scene == 1 {
    content = "\{content}(Enter) Reset all to scene recommendation\n"
  }

  "\{content}\nActive Method: \{method_name(tonemapping)}"
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  camera_transform : @app.Res[CameraTransform],
) -> Unit {
  let camera = commands.spawn(
    @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      camera_transform.get().transform,
    )
    .with_color_grading(Some(@post_process.ColorGrading::ColorGrading()))
    .with_distance_fog(
      Some(
        @pbr.DistanceFog::new(
          @color.Color::srgb(43.0F / 255.0F, 44.0F / 255.0F, 47.0F / 255.0F),
          @pbr.FogFalloff3d::linear(1.0F, 8.0F),
        ),
      ),
    ),
  )
  commands
  .entity(camera)
  .insert(
    (
      @pbr.Hdr::Hdr(),
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

  ignore(
    commands.spawn(
      (
        @text.Text::Text(),
        @ui.Node::Node()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.px(12.0F))
        .with_left(@ui.px(12.0F)),
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
        @scene.WorldAssetRoot::new(
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
        @scene.WorldAssetRoot::new(
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
        @pbr.DirectionalLight::new(@color.Color::white(), 15_000.0F, true),
        @pbr.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
        .with_maximum_distance(3.0F)
        .with_first_cascade_far_bound(0.9F)
        .build(),
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
fn setup_color_gradient_scene(
  commands : @app.Commands,
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  material_assets : @app.ResMut[@asset.Assets[ColorGradientMaterial]],
  camera_transform : @app.Res[CameraTransform],
) -> Unit {
  let mesh_handle = mesh_assets
    .peek()
    .add(
      @mesh.Mesh::from_3d_geometry(@mesh_primitives.rectangle_mesh(0.7F, 0.7F)),
    )
  let material_handle = material_assets
    .peek()
    .add(ColorGradientMaterial::ColorGradientMaterial())

  let transform = camera_transform.get().transform
  transform.translation = transform.translation.add(transform.forward())

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh_handle),
        @pbr.MeshMaterial3dTyped::new(material_handle),
        transform,
        @visibility.Visibility::Hidden,
        SceneNumber::{ value: 2 },
      ),
    ),
  )
}

///|
fn setup_image_viewer_scene(
  commands : @app.Commands,
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  camera_transform : @app.Res[CameraTransform],
) -> Unit {
  let mesh_handle = mesh_assets
    .peek()
    .add(
      @mesh.Mesh::from_3d_geometry(@mesh_primitives.rectangle_mesh(1.0F, 1.0F)),
    )
  let material_handle = material_assets
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::white()).with_unlit(true),
    )

  let transform = camera_transform.get().transform
  transform.translation = transform.translation.add(transform.forward())

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh_handle),
        @pbr.MeshMaterial3d::new(material_handle),
        transform,
        @visibility.Visibility::Hidden,
        SceneNumber::{ value: 3 },
        HDRViewer::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ui.Node::{
          ..@ui.Node(),
          align_self: @ui.AlignSelf::Center,
          margin: @ui.UiRect::all(@ui.Val::Auto),
        },
        @text.Text::new("Drag and drop an HDR or EXR file"),
        @text.TextFont::TextFont().with_font_size(36.0F),
        @text.TextColor::new(@color.Color::black()),
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
  visibility_query : @ecs.Query[@ecs.Write[@visibility.Visibility], @ecs.All],
  current_scene : @app.ResMut[CurrentScene],
  scene_query : @ecs.Query[@ecs.Read[SceneNumber], @ecs.All],
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
  current_scene.set(CurrentScene::{ value: scene })

  try! scene_query.view(fn(entity, scene_number) {
    let visibility = if scene_number.value().value == scene {
      @visibility.Visibility::Inherited
    } else {
      @visibility.Visibility::Hidden
    }
    if (visibility_query.get(entity) catch { _ => None }) is Some(component) {
      component.set(visibility)
    }
  })
}

///|
fn toggle_tonemapping_method(
  keys : @input.ButtonInput[@window.KeyCode],
  tonemapping : @app.Single[@ecs.Write[@post_process.Tonemapping], @ecs.All],
  color_grading : @app.Single[@ecs.Write[@post_process.ColorGrading], @ecs.All],
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
  } else if keys.just_pressed(Digit9) {
    Some(@post_process.Tonemapping::PbrNeutral)
  } else {
    None
  }
  let tonemapping = tonemapping.get()
  let mut current_tonemapping = tonemapping.value()
  if next_method is Some(tonemapper) {
    tonemapping.set(tonemapper)
    current_tonemapping = tonemapper
  }

  guard per_method_settings.get().settings.get(current_tonemapping)
    is Some(setting_color_grading) else {
    return
  }
  color_grading.get().set(setting_color_grading)
}

///|
fn update_color_grading_settings(
  keys : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
  per_method_settings : @app.ResMut[PerMethodSettings],
  tonemapping : @app.Single[@ecs.Read[@post_process.Tonemapping], @ecs.All],
  current_scene : @app.Res[CurrentScene],
  selected_parameter : @app.ResMut[SelectedParameter],
) -> Unit {
  let current_method = tonemapping.get().value()

  if keys.just_pressed(ArrowDown) {
    selected_parameter.modify(fn(value) { value.next() })
  }
  if keys.just_pressed(ArrowUp) {
    selected_parameter.modify(fn(value) { value.prev() })
  }

  let mut delta = time.get().delta_seconds() * 0.25F
  if keys.pressed(ArrowLeft) {
    delta = -delta
  } else if !keys.pressed(ArrowRight) {
    delta = 0.0F
  }

  if delta != 0.0F {
    let selected_value = selected_parameter.get().value
    per_method_settings.modify(fn(value) {
      let next = value.settings
        .get(current_method)
        .unwrap_or(@post_process.ColorGrading::ColorGrading())
      match selected_value {
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
      value.settings.set(current_method, next)
    })
  }

  if keys.just_pressed(Space) {
    per_method_settings.modify(fn(value) {
      for tonemapper in tonemapping_methods() {
        value.settings.set(
          tonemapper,
          @post_process.ColorGrading::ColorGrading(),
        )
      }
    })
  }

  if keys.just_pressed(Enter) && current_scene.get().value == 1 {
    per_method_settings.modify(fn(value) {
      for tonemapper in tonemapping_methods() {
        value.settings.set(
          tonemapper,
          PerMethodSettings::basic_scene_recommendation(tonemapper),
        )
      }
    })
  }
}

///|
fn drag_drop_image(
  image_material_query : @ecs.Query[
    @ecs.Read[@pbr.MeshMaterial3d],
    @ecs.With[HDRViewer],
  ],
  image_viewer_text_query : @ecs.Query[
    @core.Entity,
    (@ecs.With[@text.Text], @ecs.With[SceneNumber]),
  ],
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  drag_and_drop_reader : @ecs.MessageReader[@window.FileDragAndDrop],
  asset_server : @app.Res[@asset.AssetServer],
  commands : @app.Commands,
) -> Unit {
  let mut new_image : @asset.Handle[@asset.Image]? = None
  for event in drag_and_drop_reader.read() {
    match event {
      DroppedFile(_window, path) =>
        new_image = Some(asset_server.get().load(path))
      _ => ()
    }
  }
  guard new_image is Some(image) else { return }
  try! image_material_query.view(fn(_entity, viewer_material) {
    guard material_assets.peek().get(viewer_material.value().material)
      is Some(material) else {
      return
    }
    ignore(
      material_assets
      .peek()
      .set(
        viewer_material.value().material,
        material.with_base_color_texture(Some(image)),
      ),
    )
  })

  if (image_viewer_text_query.single() catch { _ => None }) is Some(text_entity) {
    commands.entity(text_entity).despawn()
  }
}

///|
fn resize_image(
  image_mesh_query : @ecs.Query[
    (@ecs.Read[@pbr.MeshMaterial3d], @ecs.Read[@mesh.Mesh3d]),
    @ecs.With[HDRViewer],
  ],
  image_event_reader : @ecs.MessageReader[@asset.AssetEvent[@asset.Image]],
  material_assets : @app.Res[@asset.Assets[@pbr.StandardMaterial]],
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  images : @app.Res[@asset.Assets[@asset.Image]],
) -> Unit {
  for event in image_event_reader.read() {
    let changed_image = match event {
      Added(handle) => Some(handle)
      Modified(handle) => Some(handle)
      _ => None
    }
    guard changed_image is Some(changed_image) else { continue }
    try! image_mesh_query.view(fn(_entity, data) {
      let (viewer_material, viewer_mesh) = data
      guard material_assets.get().get(viewer_material.value().material)
        is Some(material) else {
        return
      }
      guard material.base_color_texture is Some(texture) else { return }
      if changed_image.id() != texture.id() {
        return
      }
      guard images.get().get(changed_image) is Some(image) else { return }
      let size = @math.Vec2::new(
          Float::from_int(image.width()),
          Float::from_int(image.height()),
        )
        .normalize_or_zero()
        .mul_scalar(1.4F)
      ignore(
        mesh_assets
        .peek()
        .insert(
          viewer_mesh.value().mesh,
          @mesh.Mesh::from_3d_geometry(
            @mesh_primitives.rectangle_mesh(size.x, size.y),
          ),
        ),
      )
    })
  }
}

///|
fn update_ui(
  keys : @input.ButtonInput[@window.KeyCode],
  current_scene : @app.Res[CurrentScene],
  selected_parameter : @app.Res[SelectedParameter],
  settings : @app.Single[
    (
      @ecs.Read[@post_process.Tonemapping],
      @ecs.Read[@post_process.ColorGrading],
    ),
    @ecs.All,
  ],
  text_query : @app.Single[@ecs.Write[@text.Text], @ecs.Without[SceneNumber]],
  hide_ui : @app.Local[Bool],
) -> Unit {
  if keys.just_pressed(KeyH) {
    hide_ui.set(!hide_ui.get())
  }
  let text = text_query.get()
  if hide_ui.get() {
    if text.value().content != "" {
      text.set(@text.Text::Text())
    }
    return
  }
  let (tonemapping, color_grading) = settings.get()
  let content = ui_text_content(
    current_scene.get().value,
    tonemapping.value(),
    color_grading.value(),
    selected_parameter.get().value,
  )
  if text.value().content != content {
    text.set(@text.Text::new(content))
  }
}

///|
fn main {
  let color_gradient_material_plugin : @pbr.MaterialPlugin[
    ColorGradientMaterial,
  ] = @pbr.MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
    ColorGradientMaterial::ColorGradientMaterial()
  })
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(
      @asset.AssetPlugin::AssetPlugin().with_unapproved_path_mode(
        @asset.UnapprovedPathMode::Allow,
      ),
    ),
  )
  .add_plugins(color_gradient_material_plugin)
  .insert_resource(CameraTransform::CameraTransform())
  .insert_resource(PerMethodSettings::PerMethodSettings())
  .insert_resource(CurrentScene::CurrentScene())
  .insert_resource(SelectedParameter::SelectedParameter())
  .add_systems_param3(@app.Startup, setup)
  .add_systems_param2(@app.Startup, setup_basic_scene)
  .add_systems_param4(@app.Startup, setup_color_gradient_scene)
  .add_systems_param4(@app.Startup, setup_image_viewer_scene)
  .add_systems_param6(@app.Update, drag_drop_image)
  .add_systems_param5(@app.Update, resize_image)
  .add_systems_param4(@app.Update, toggle_scene)
  .add_systems_param4(@app.Update, toggle_tonemapping_method)
  .add_systems_param6(@app.Update, update_color_grading_settings)
  .add_systems_param6(@app.Update, update_ui)
  .run()
}
