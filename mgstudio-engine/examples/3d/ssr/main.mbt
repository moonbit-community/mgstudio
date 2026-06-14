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
/// Baseline parity: deferred SSR controls and upstream scene interaction flow are
/// mapped to mgstudio APIs.

///|
const SHADER_ASSET_PATH : String = "shaders/water_material.wgsl"

///|
const CAMERA_HEIGHT : Float = 2.25F

///|
const CAMERA_KEYBOARD_ZOOM_SPEED : Float = 0.1F

///|
const CAMERA_KEYBOARD_ORBIT_SPEED : Float = 0.02F

///|
const CAMERA_MOUSE_WHEEL_ZOOM_SPEED : Float = 0.25F

///|
const CAMERA_MIN_RADIUS : Float = 2.0F

///|
const CAMERA_MAX_RADIUS : Float = 12.0F

///|
const RANGE_STEP_ROUGHNESS : Float = 0.005F

///|
const RANGE_STEP_EDGE : Float = 0.001F

///|
struct WaterSettings {
  octave_vectors : Array[@math.Vec4]
  octave_scales : @math.Vec4
  octave_strengths : @math.Vec4
}

///|
struct Water {
  normals : @asset.Handle[@asset.Image]
  settings : WaterSettings
}

///|
fn ssr_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn ssr_push_f32(words : Array[UInt], value : Float) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn ssr_push_vec4(words : Array[UInt], value : @math.Vec4) -> Unit {
  ssr_push_f32(words, value.x)
  ssr_push_f32(words, value.y)
  ssr_push_f32(words, value.z)
  ssr_push_f32(words, value.w)
}

///|
fn WaterSettings::as_uniform_bytes(self : WaterSettings) -> Bytes {
  let words : Array[UInt] = []
  for vector in self.octave_vectors {
    ssr_push_vec4(words, vector)
  }
  ssr_push_vec4(words, self.octave_scales)
  ssr_push_vec4(words, self.octave_strengths)
  ssr_u32le_pack(words)
}

///|
pub impl @pbr.MaterialExtension for Water with fn extension_tag(_self) {
  81
}

///|
pub impl @pbr.MaterialExtension for Water with fn vertex_shader(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn fragment_shader(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn prepass_vertex_shader(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn prepass_fragment_shader(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn deferred_vertex_shader(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn deferred_fragment_shader(
  _self,
) {
  Some(SHADER_ASSET_PATH)
}

///|
pub impl @pbr.MaterialExtension for Water with fn alpha_mode(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn opaque_render_method(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn enable_prepass(_self) {
  true
}

///|
pub impl @pbr.MaterialExtension for Water with fn enable_shadows(_self) {
  true
}

///|
pub impl @pbr.MaterialExtension for Water with fn specialize(_self) {
  None
}

///|
pub impl @pbr.MaterialExtension for Water with fn bind_group_layout_entries(
  _self,
) {
  let fragment = @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
  [
    @render_resource.BindGroupLayoutEntry::new(
      100,
      fragment,
      @render_resource.BindingType::TextureBinding(
        @render_resource.TextureSampleType::Float(true),
        @render_resource.TextureViewDimension::D2,
        false,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      101,
      fragment,
      @render_resource.BindingType::SamplerBinding(
        @render_resource.SamplerBindingType::Filtering,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      102,
      fragment,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        64UL,
      ),
    ),
  ]
}

///|
pub impl @pbr.MaterialExtension for Water with fn bind_group_bindings(self) {
  [
    @material.MaterialExtensionBinding3d::texture(100, self.normals),
    @material.MaterialExtensionBinding3d::sampler(101, self.normals),
    @material.MaterialExtensionBinding3d::uniform(
      102,
      self.settings.as_uniform_bytes(),
    ),
  ]
}

///|
pub(all) enum DisplayedModel {
  Cube
  FlightHelmet
  Capsules
} derive(Eq)

///|
pub(all) enum DisplayedBase {
  Water
  Metallic
  RedPlane
} derive(Eq)

///|
priv enum ExampleSetting {
  Ssr(Bool)
  Model(DisplayedModel)
  Base(DisplayedBase)
  MinRoughnessStart(Adjustment)
  MinRoughnessEnd(Adjustment)
  MaxRoughnessStart(Adjustment)
  MaxRoughnessEnd(Adjustment)
  EdgeFadeoutStart(Adjustment)
  EdgeFadeoutEnd(Adjustment)
}

///|
priv enum Adjustment {
  Increase
  Decrease
}

///|
impl @widgets_lib.WidgetValue for ExampleSetting with fn widget_debug_name() {
  "examples.3d.ssr.ExampleSetting"
}

///|
let example_setting_widget_click_event_key : @ecs.MessageKey[
  @widgets_lib.WidgetClickEvent[ExampleSetting],
] = @ecs.register_message(
  debug_name="examples.helpers.widgets_lib.WidgetClickEvent<examples.3d.ssr.ExampleSetting>",
)

///|
impl @widgets_lib.WidgetValue for ExampleSetting with fn widget_click_event_key() {
  example_setting_widget_click_event_key
}

///|
let example_setting_widget_click_sender_key : @ecs.ComponentKey[
  @widgets_lib.WidgetClickSender[ExampleSetting],
] = @ecs.register_component(
  debug_name="examples.helpers.widgets_lib.WidgetClickSender<examples.3d.ssr.ExampleSetting>",
)

///|
impl @widgets_lib.WidgetValue for ExampleSetting with fn widget_click_sender_key() {
  example_setting_widget_click_sender_key
}

///|
priv enum RangeValueText {
  MinRoughnessStart
  MinRoughnessEnd
  MaxRoughnessStart
  MaxRoughnessEnd
  EdgeFadeoutStart
  EdgeFadeoutEnd
}

///|
let range_value_text_key : @ecs.ComponentKey[RangeValueText] = @ecs.register_component(
  debug_name="examples.3d.ssr.RangeValueText",
)

///|
impl @ecs.Component for RangeValueText with fn component() {
  range_value_text_key
}

///|
priv struct AppSettings {
  mut ssr_on : Bool
  mut displayed_model : DisplayedModel
  mut displayed_base : DisplayedBase
  mut min_roughness_start : Float
  mut min_roughness_end : Float
  mut max_roughness_start : Float
  mut max_roughness_end : Float
  mut edge_fadeout_start : Float
  mut edge_fadeout_end : Float
}

///|
let app_settings_resource_key : @ecs.ResourceKey[AppSettings] = @ecs.register_resource(
  debug_name="examples.3d.ssr.AppSettings",
)

///|
impl @app.Resource for AppSettings with fn resource() {
  app_settings_resource_key
}

///|
fn AppSettings::AppSettings() -> AppSettings {
  AppSettings::{
    ssr_on: true,
    displayed_model: DisplayedModel::Cube,
    displayed_base: DisplayedBase::Water,
    min_roughness_start: 0.0F,
    min_roughness_end: 0.01F,
    max_roughness_start: 0.99F,
    max_roughness_end: 1.0F,
    edge_fadeout_start: 0.0F,
    edge_fadeout_end: 0.0F,
  }
}

///|
priv struct SsrSceneEntities {
  mut thickness : Float
  mut linear_steps : Int
  mut bisection_steps : Int
  mut linear_march_exponent : Float
  mut use_secant : Bool
  mut camera : @core.Entity?
  mut cube_model : @core.Entity?
  mut flight_helmet_model : @core.Entity?
  capsule_models : Array[@core.Entity]
  mut metallic_base : @core.Entity?
  mut red_plane_base : @core.Entity?
  mut water_base : @core.Entity?
}

///|
let ssr_scene_entities : Ref[SsrSceneEntities] = Ref({
  thickness: 0.25F,
  linear_steps: 10,
  bisection_steps: 5,
  linear_march_exponent: 1.0F,
  use_secant: true,
  camera: None,
  cube_model: None,
  flight_helmet_model: None,
  capsule_models: [],
  metallic_base: None,
  red_plane_base: None,
  water_base: None,
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
fn clamp01(value : Float) -> Float {
  clampf(value, 0.0F, 1.0F)
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn ordered_unit_range(start : Float, end_ : Float) -> (Float, Float) {
  let safe_start = clamp01(start)
  let safe_end = clamp01(end_)
  if safe_start <= safe_end {
    (safe_start, safe_end)
  } else {
    (safe_end, safe_start)
  }
}

///|
fn set_entity_visibility(
  world : @ecs.World,
  entity : @core.Entity?,
  visible : Bool,
) -> Unit {
  if entity is Some(value) {
    try! (world.replace(
      value,
      @visibility.ecs_key_visibility,
      if visible {
        @visibility.Visibility::Inherited
      } else {
        @visibility.Visibility::Hidden
      },
    )
    |> ignore)
  }
}

///|
fn apply_model_and_base_visibility(world : @ecs.World) -> Unit {
  let settings = match world.get_resource(AppSettings::resource()) {
    Some(value) => value
    None => AppSettings::AppSettings()
  }
  let model = settings.displayed_model
  let base = settings.displayed_base

  set_entity_visibility(world, ssr_scene_entities.val.cube_model, model is Cube)
  set_entity_visibility(
    world,
    ssr_scene_entities.val.flight_helmet_model,
    model is FlightHelmet,
  )
  for capsule in ssr_scene_entities.val.capsule_models {
    set_entity_visibility(world, Some(capsule), model is Capsules)
  }

  set_entity_visibility(world, ssr_scene_entities.val.water_base, base is Water)
  set_entity_visibility(
    world,
    ssr_scene_entities.val.metallic_base,
    base is Metallic,
  )
  set_entity_visibility(
    world,
    ssr_scene_entities.val.red_plane_base,
    base is RedPlane,
  )
}

///|
fn sanitize_ssr_ranges(settings : AppSettings) -> Unit {
  let (min_start, min_end) = ordered_unit_range(
    settings.min_roughness_start,
    settings.min_roughness_end,
  )
  settings.min_roughness_start = min_start
  settings.min_roughness_end = min_end

  let (max_start, max_end) = ordered_unit_range(
    settings.max_roughness_start,
    settings.max_roughness_end,
  )
  settings.max_roughness_start = max_start
  settings.max_roughness_end = max_end

  let (edge_start, edge_end) = ordered_unit_range(
    settings.edge_fadeout_start,
    settings.edge_fadeout_end,
  )
  settings.edge_fadeout_start = edge_start
  settings.edge_fadeout_end = edge_end

  ssr_scene_entities.val.thickness = clampf(
    ssr_scene_entities.val.thickness,
    0.0F,
    5.0F,
  )
  ssr_scene_entities.val.linear_steps = if ssr_scene_entities.val.linear_steps <=
    0 {
    1
  } else {
    ssr_scene_entities.val.linear_steps
  }
  ssr_scene_entities.val.bisection_steps = if ssr_scene_entities.val.bisection_steps <
    0 {
    0
  } else {
    ssr_scene_entities.val.bisection_steps
  }
  ssr_scene_entities.val.linear_march_exponent = clampf(
    ssr_scene_entities.val.linear_march_exponent,
    0.1F,
    4.0F,
  )
}

///|
fn build_ssr_settings(
  settings : AppSettings,
) -> @post_process.ScreenSpaceReflections {
  @post_process.ScreenSpaceReflections::ScreenSpaceReflections()
  .with_min_perceptual_roughness(
    settings.min_roughness_start,
    settings.min_roughness_end,
  )
  .with_max_perceptual_roughness(
    settings.max_roughness_start,
    settings.max_roughness_end,
  )
  .with_edge_fadeout(settings.edge_fadeout_start, settings.edge_fadeout_end)
  .with_thickness(ssr_scene_entities.val.thickness)
  .with_linear_steps(ssr_scene_entities.val.linear_steps)
  .with_bisection_steps(ssr_scene_entities.val.bisection_steps)
  .with_linear_march_exponent(ssr_scene_entities.val.linear_march_exponent)
  .with_use_secant(ssr_scene_entities.val.use_secant)
}

///|
fn apply_ssr_settings(world : @ecs.World, settings : AppSettings) -> Unit {
  sanitize_ssr_ranges(settings)
  if ssr_scene_entities.val.camera is Some(camera) {
    if settings.ssr_on {
      if !(try! world.replace(
          camera,
          @post_process.ecs_key_screen_space_reflections,
          build_ssr_settings(settings),
        )) {
        try! world.set_by_key(
          camera,
          @post_process.ecs_key_screen_space_reflections,
          build_ssr_settings(settings),
        )
      }
    } else {
      try! (world.take(camera, @post_process.ecs_key_screen_space_reflections)
      |> ignore)
    }
  }
}

///|
fn spawn_cube(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@color.Color::white())
    .with_base_color_texture(Some(asset_server.load("branding/icon.png")))
    .with_perceptual_roughness(0.08F)
    .with_metallic(0.0F),
  )
  let cube = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
      }),
    ),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  ).spawn(world)
  ssr_scene_entities.val.cube_model = Some(cube)
}

///|
fn spawn_flight_helmet(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/FlightHelmet/FlightHelmet.gltf",
        ),
      ),
    ),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity().with_scale(@math.Vec3::splat(2.5F)),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
  ssr_scene_entities.val.flight_helmet_model = Some(entity)
}

///|
fn spawn_capsules(world : @ecs.World) -> Unit {
  ssr_scene_entities.val.capsule_models.clear()
  let capsule_mesh = @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets |> @pbr.add_mesh(@math.Capsule3d::new(0.4F, 0.5F))
    }),
  )
  let parent = world.spawn_empty()
  try! world.set_by_key(
    parent,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
  )
  try! world.set_by_key(
    parent,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
  ssr_scene_entities.val.capsule_models.push(parent)
  for i in 0..<5 {
    let roughness = clampf(float_from_int(i) * 0.25F, 0.08F, 1.0F)
    let material = @pbr.standard_material_add(
      @pbr.StandardMaterial::from_color(@color.Color::black())
      .with_perceptual_roughness(roughness)
      .with_metallic(0.0F),
    )
    let entity = @pbr.MeshMaterial3dBundle::new(
      capsule_mesh,
      @pbr.MeshMaterial3d::new(material),
      @transform.Transform::from_xyz(
        float_from_int(i) * 1.1F - 2.2F,
        0.5F,
        0.0F,
      ),
    ).spawn(world)

    try! (world.replace(
      entity,
      @visibility.ecs_key_visibility,
      @visibility.Visibility::Hidden,
    )
    |> ignore)
    @transform.set_parent_in_place(world, entity, parent)
    ssr_scene_entities.val.capsule_models.push(entity)
  }
}

///|
fn spawn_bases(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let metallic_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @color.Color::new(0.25F, 0.25F, 0.25F, 1.0F),
    )
    .with_metallic(1.0F)
    .with_perceptual_roughness(0.3F),
  )
  let metallic = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(100.0F, 100.0F),
          ).build(),
        )
      }),
    ),
    @pbr.MeshMaterial3d::new(metallic_material),
    @transform.Transform::identity(),
  ).spawn(world)
  try! (world.replace(
    metallic,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
  |> ignore)
  ssr_scene_entities.val.metallic_base = Some(metallic)

  let red_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @color.Color::new(0.85F, 0.12F, 0.12F, 1.0F),
    )
    .with_metallic(0.0F)
    .with_perceptual_roughness(0.2F),
  )
  let red = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(100.0F, 100.0F),
          ).build(),
        )
      }),
    ),
    @pbr.MeshMaterial3d::new(red_material),
    @transform.Transform::identity(),
  ).spawn(world)
  try! (world.replace(
    red,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Hidden,
  )
  |> ignore)
  ssr_scene_entities.val.red_plane_base = Some(red)

  let water_normals = asset_server.load_with_settings(
    "textures/water_normals.png",
    fn(settings) {
      settings.is_srgb = false
      settings.sampler = @asset.ImageSampler::Descriptor(
        @asset.ImageSamplerDescriptor::linear().set_address_mode(
          @asset.ImageAddressMode::Repeat,
        ),
      )
    },
  )
  let water_extension = Water::{
    normals: water_normals,
    settings: WaterSettings::{
      octave_vectors: [
        @math.Vec4::new(0.080F, 0.059F, 0.073F, -0.062F),
        @math.Vec4::new(0.153F, 0.138F, -0.149F, -0.195F),
      ],
      octave_scales: @math.Vec4::new(5.0F, 10.5F, 39.5F, 74.5F),
      octave_strengths: @math.Vec4::new(0.16F, 0.18F, 0.093F, 0.044F),
    },
  }
  let water_base_material = @pbr.StandardMaterial::from_color(
    @color.Color::black(),
  ).with_perceptual_roughness(0.09F)
  let water_material = @pbr.standard_material_add(water_base_material)
  let water_mesh_material = @pbr.MeshMaterial3d::new(water_material).with_extended_material(
    Some(
      @pbr.ExtendedMaterial::new(water_base_material, water_extension).metadata(),
    ),
  )
  let water = @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
        assets
        |> @pbr.add_mesh(
          @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
            @math.Vec2::new(100.0F, 100.0F),
          ).build(),
        )
      }),
    ),
    water_mesh_material,
    @transform.Transform::identity(),
  ).spawn(world)
  ssr_scene_entities.val.water_base = Some(water)
}

///|
fn setup_camera_and_lights(
  world : @ecs.World,
  app_settings : AppSettings,
) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let camera = @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      @transform.Transform::from_xyz(-1.25F, CAMERA_HEIGHT, 4.5F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_screen_space_reflections(Some(build_ssr_settings(app_settings)))
    .spawn(world)
  ssr_scene_entities.val.camera = Some(camera)

  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::Hdr())
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_anti_aliasing,
    @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
  )
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_anti_aliasing,
    @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
  )
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_screen_space_ambient_occlusion,
    @post_process.ScreenSpaceAmbientOcclusion::ScreenSpaceAmbientOcclusion(),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      5000.0F,
    ),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      5000.0F,
    ),
  )

  let directional = world.spawn_empty()
  try! world.set_by_key(
    directional,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@color.Color::white(), 15_000.0F, true),
  )
  try! world.set_by_key(
    directional,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(2.5F, 5.5F, 2.8F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let point = world.spawn_empty()
  try! world.set_by_key(
    point,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(
      @color.Color::new(1.0F, 0.98F, 0.96F, 1.0F),
      200_000.0F,
      30.0F,
      true,
    ),
  )
  try! world.set_by_key(
    point,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-3.0F, 3.5F, 2.0F),
  )

  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@color.Color::white(), 0.03F),
  )
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match world.get_resource(@time.default_time_resource_key) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in ssr example")
  }
}

///|
fn rotate_models(world : @ecs.World) -> Unit {
  let rotation = @math.Quat::from_rotation_y(
    world_time(world).elapsed_seconds(),
  )

  if ssr_scene_entities.val.cube_model is Some(cube) {
    if (try! world.get_by_key(cube, @transform.ecs_key_transform))
      is Some(transform) {
      try! (world.replace(
        cube,
        @transform.ecs_key_transform,
        transform.with_rotation(rotation),
      )
      |> ignore)
    }
  }

  if ssr_scene_entities.val.flight_helmet_model is Some(helmet) {
    if (try! world.get_by_key(helmet, @transform.ecs_key_transform))
      is Some(transform) {
      try! (world.replace(
        helmet,
        @transform.ecs_key_transform,
        transform.with_rotation(rotation),
      )
      |> ignore)
    }
  }
}

///|
fn format_range_value(value : Float) -> String {
  let scaled = (value * 100.0F + 0.5F).to_int()
  let whole = scaled / 100
  let fractional = (scaled % 100).to_string().pad_start(2, '0')
  "\{whole}.\{fractional}"
}

///|
fn adjust(value : Float, adjustment : Adjustment, amount : Float) -> Float {
  match adjustment {
    Increase => (value + amount).min(1.0F)
    Decrease => (value - amount).max(0.0F)
  }
}

///|
fn app_setting_selected(
  setting : ExampleSetting,
  settings : AppSettings,
) -> Bool {
  match setting {
    Ssr(on) => settings.ssr_on == on
    Model(model) => settings.displayed_model == model
    Base(base) => settings.displayed_base == base
    _ => false
  }
}

///|
fn range_value(settings : AppSettings, marker : RangeValueText) -> Float {
  match marker {
    MinRoughnessStart => settings.min_roughness_start
    MinRoughnessEnd => settings.min_roughness_end
    MaxRoughnessStart => settings.max_roughness_start
    MaxRoughnessEnd => settings.max_roughness_end
    EdgeFadeoutStart => settings.edge_fadeout_start
    EdgeFadeoutEnd => settings.edge_fadeout_end
  }
}

///|
fn spawn_range_controls(
  commands : @app.Commands,
  parent : @core.Entity,
  value : Float,
  marker : RangeValueText,
  decrease_setting : ExampleSetting,
  increase_setting : ExampleSetting,
) -> Unit {
  let row = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node().with_align_items(@ui.AlignItems::Center),
    ),
  )
  ignore(@widgets_lib.spawn_action_button(commands, row, decrease_setting, "<"))
  let (text, text_font, text_color) = @widgets_lib.ui_text(
    format_range_value(value),
    @color.Color::black(),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @ui.Node::Node()
        .with_width(@ui.Val::Px(50.0F))
        .with_height(@ui.Val::Px(33.0F))
        .with_justify_content(@ui.JustifyContent::Center)
        .with_align_items(@ui.AlignItems::Center),
        @ui.BackgroundColor::new(@color.Color::white()),
        marker,
        text,
        text_font,
        text_color,
      ),
    ),
  )
  ignore(@widgets_lib.spawn_action_button(commands, row, increase_setting, ">"))
}

///|
fn spawn_range_row(
  commands : @app.Commands,
  parent : @core.Entity,
  title : String,
  start_value : Float,
  end_value : Float,
  start_marker : RangeValueText,
  end_marker : RangeValueText,
  start_decrease : ExampleSetting,
  start_increase : ExampleSetting,
  end_decrease : ExampleSetting,
  end_increase : ExampleSetting,
) -> Unit {
  let row = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node().with_align_items(@ui.AlignItems::Center),
    ),
  )
  let (title_text, title_font, title_color) = @widgets_lib.ui_text(
    title,
    @color.Color::white(),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @ui.Node::Node().with_width(@ui.Val::Px(150.0F)),
        title_text,
        title_font,
        title_color,
      ),
    ),
  )
  spawn_range_controls(
    commands, row, start_value, start_marker, start_decrease, start_increase,
  )
  let (to_text, to_font, to_color) = @widgets_lib.ui_text(
    "to",
    @color.Color::white(),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(row),
        @ui.Node::Node().with_margin(
          @ui.UiRect::new(
            @ui.Val::Px(10.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(10.0F),
            @ui.Val::Px(0.0F),
          ),
        ),
        to_text,
        to_font,
        to_color,
      ),
    ),
  )
  spawn_range_controls(
    commands, row, end_value, end_marker, end_decrease, end_increase,
  )
}

///|
fn spawn_buttons(commands : @app.Commands, app_settings : AppSettings) -> Unit {
  let ui_camera = commands.spawn(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  commands
  .entity(ui_camera)
  .insert_component(@ui.IsDefaultUiCamera::IsDefaultUiCamera())
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  let panel = commands.spawn(
    (@hierarchy.Parent::new(root), @widgets_lib.main_ui_node()),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(
      commands,
      panel,
      "SSR",
      [(Ssr(true), "On"), (Ssr(false), "Off")],
      if app_settings.ssr_on {
        0
      } else {
        1
      },
    ),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(
      commands,
      panel,
      "Model",
      [
        (Model(Cube), "Cube"),
        (Model(FlightHelmet), "Flight Helmet"),
        (Model(Capsules), "Capsules"),
      ],
      match app_settings.displayed_model {
        Cube => 0
        FlightHelmet => 1
        Capsules => 2
      },
    ),
  )
  ignore(
    @widgets_lib.spawn_option_buttons(
      commands,
      panel,
      "Base",
      [
        (Base(Water), "Water"),
        (Base(Metallic), "Metallic"),
        (Base(RedPlane), "Red Plane"),
      ],
      match app_settings.displayed_base {
        Water => 0
        Metallic => 1
        RedPlane => 2
      },
    ),
  )
  spawn_range_row(
    commands,
    panel,
    "Min Roughness",
    app_settings.min_roughness_start,
    app_settings.min_roughness_end,
    MinRoughnessStart,
    MinRoughnessEnd,
    MinRoughnessStart(Decrease),
    MinRoughnessStart(Increase),
    MinRoughnessEnd(Decrease),
    MinRoughnessEnd(Increase),
  )
  spawn_range_row(
    commands,
    panel,
    "Max Roughness",
    app_settings.max_roughness_start,
    app_settings.max_roughness_end,
    MaxRoughnessStart,
    MaxRoughnessEnd,
    MaxRoughnessStart(Decrease),
    MaxRoughnessStart(Increase),
    MaxRoughnessEnd(Decrease),
    MaxRoughnessEnd(Increase),
  )
  spawn_range_row(
    commands,
    panel,
    "Edge Fadeout",
    app_settings.edge_fadeout_start,
    app_settings.edge_fadeout_end,
    EdgeFadeoutStart,
    EdgeFadeoutEnd,
    EdgeFadeoutStart(Decrease),
    EdgeFadeoutStart(Increase),
    EdgeFadeoutEnd(Decrease),
    EdgeFadeoutEnd(Increase),
  )
}

///|
fn handle_widget_interactions(
  interactions : @ecs.Query[
    (
      @ecs.Read[@ui.Interaction],
      @ecs.Read[@widgets_lib.WidgetClickSender[ExampleSetting]],
    ),
    @ecs.With[@ui.Button],
  ],
  widget_click_events : @ecs.MessageWriter[
    @widgets_lib.WidgetClickEvent[ExampleSetting],
  ],
) -> Unit {
  @widgets_lib.handle_ui_interactions(interactions, widget_click_events)
}

///|
fn update_radio_buttons(
  radio_buttons : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[ExampleSetting]],
      @ecs.Write[@ui.BackgroundColor],
    ),
    @ecs.With[@widgets_lib.RadioButton],
  ],
  radio_button_texts : @ecs.Query[
    (
      @ecs.Read[@widgets_lib.WidgetClickSender[ExampleSetting]],
      @ecs.Write[@text.TextColor],
    ),
    @ecs.With[@widgets_lib.RadioButtonText],
  ],
  app_settings : @app.Res[AppSettings],
) -> Unit {
  let settings = app_settings.get()
  try! radio_buttons.view(fn(_entity, data) {
    let (sender, background_color) = data
    @widgets_lib.update_ui_radio_button(
      background_color,
      app_setting_selected(sender.value().get(), settings),
    )
  })
  try! radio_button_texts.view(fn(_entity, data) {
    let (sender, text_color) = data
    @widgets_lib.update_ui_radio_button_text(
      text_color,
      app_setting_selected(sender.value().get(), settings),
    )
  })
}

///|
fn update_range_value_text(
  range_values : @ecs.Query[
    (@ecs.Read[RangeValueText], @ecs.Write[@text.Text]),
    @ecs.All,
  ],
  app_settings : @app.Res[AppSettings],
) -> Unit {
  let settings = app_settings.get()
  try! range_values.view(fn(_entity, data) {
    let (marker, text) = data
    text.set(
      @text.Text::new(format_range_value(range_value(settings, marker.value()))),
    )
  })
}

///|
fn adjust_app_settings(
  events : @ecs.MessageReader[@widgets_lib.WidgetClickEvent[ExampleSetting]],
  app_settings : @app.ResMut[AppSettings],
) -> Unit {
  let mut any_changes = false
  app_settings.modify(fn(settings) {
    for event in events.read() {
      any_changes = true
      match event.get() {
        Ssr(on) => settings.ssr_on = on
        Model(model) => settings.displayed_model = model
        Base(base) => settings.displayed_base = base
        MinRoughnessStart(adjustment) =>
          settings.min_roughness_start = adjust(
            settings.min_roughness_start,
            adjustment,
            RANGE_STEP_ROUGHNESS,
          )
        MinRoughnessEnd(adjustment) =>
          settings.min_roughness_end = adjust(
            settings.min_roughness_end,
            adjustment,
            RANGE_STEP_ROUGHNESS,
          )
        MaxRoughnessStart(adjustment) =>
          settings.max_roughness_start = adjust(
            settings.max_roughness_start,
            adjustment,
            RANGE_STEP_ROUGHNESS,
          )
        MaxRoughnessEnd(adjustment) =>
          settings.max_roughness_end = adjust(
            settings.max_roughness_end,
            adjustment,
            RANGE_STEP_ROUGHNESS,
          )
        EdgeFadeoutStart(adjustment) =>
          settings.edge_fadeout_start = adjust(
            settings.edge_fadeout_start,
            adjustment,
            RANGE_STEP_EDGE,
          )
        EdgeFadeoutEnd(adjustment) =>
          settings.edge_fadeout_end = adjust(
            settings.edge_fadeout_end,
            adjustment,
            RANGE_STEP_EDGE,
          )
      }
    }
    if any_changes {
      sanitize_ssr_ranges(settings)
    }
  })
  ignore(any_changes)
}

///|
fn apply_app_settings(world : @ecs.World) -> Unit {
  let settings = match world.get_resource(AppSettings::resource()) {
    Some(value) => value
    None => return
  }
  apply_model_and_base_visibility(world)
  apply_ssr_settings(world, settings)
}

///|
fn move_camera(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  mouse_wheel_reader : @ecs.MessageReader[@input.MouseWheel],
  cameras : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera_camera.Camera],
  ],
) -> Unit {
  let mut distance_delta = 0.0F
  let mut theta_delta = 0.0F
  if keyboard_input.pressed(@window.KeyCode::KeyW) {
    distance_delta = distance_delta - CAMERA_KEYBOARD_ZOOM_SPEED
  }
  if keyboard_input.pressed(@window.KeyCode::KeyS) {
    distance_delta = distance_delta + CAMERA_KEYBOARD_ZOOM_SPEED
  }
  if keyboard_input.pressed(@window.KeyCode::KeyA) {
    theta_delta = theta_delta + CAMERA_KEYBOARD_ORBIT_SPEED
  }
  if keyboard_input.pressed(@window.KeyCode::KeyD) {
    theta_delta = theta_delta - CAMERA_KEYBOARD_ORBIT_SPEED
  }
  for mouse_wheel in mouse_wheel_reader.read() {
    distance_delta = distance_delta -
      mouse_wheel.y * CAMERA_MOUSE_WHEEL_ZOOM_SPEED
  }

  if distance_delta == 0.0F && theta_delta == 0.0F {
    return
  }

  try! cameras.view(fn(_entity, camera_transform) {
    camera_transform.modify(fn(transform) {
      let local_z = transform.local_z().normalize_or_zero()
      if distance_delta != 0.0F {
        transform.translation = local_z.mul_scalar(
          clampf(
            transform.translation.length() + distance_delta,
            CAMERA_MIN_RADIUS,
            CAMERA_MAX_RADIUS,
          ),
        )
      }
      if theta_delta != 0.0F {
        transform.translate_around(
          @math.Vec3::zero(),
          @math.Quat::from_axis_angle(
            @math.Vec3::new(0.0F, 1.0F, 0.0F),
            theta_delta,
          ),
        )
        let next = transform.looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        )
        transform.rotation = next.rotation
      }
    })
  })
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_default_opaque_renderer_method,
    @pbr.DefaultOpaqueRendererMethod::deferred(),
  )

  ssr_scene_entities.val.thickness = 0.25F
  ssr_scene_entities.val.linear_steps = 10
  ssr_scene_entities.val.bisection_steps = 5
  ssr_scene_entities.val.linear_march_exponent = 1.0F
  ssr_scene_entities.val.use_secant = true
  ssr_scene_entities.val.camera = None
  ssr_scene_entities.val.cube_model = None
  ssr_scene_entities.val.flight_helmet_model = None
  ssr_scene_entities.val.capsule_models.clear()
  ssr_scene_entities.val.metallic_base = None
  ssr_scene_entities.val.red_plane_base = None
  ssr_scene_entities.val.water_base = None

  let asset_server = @asset.AssetServer::new()
  let app_settings = match world.get_resource(AppSettings::resource()) {
    Some(value) => value
    None => AppSettings::AppSettings()
  }

  spawn_cube(world, asset_server)
  spawn_flight_helmet(world, asset_server)
  spawn_capsules(world)
  spawn_bases(world, asset_server)
  setup_camera_and_lights(world, app_settings)

  apply_model_and_base_visibility(world)
}

///|
fn setup_buttons(
  commands : @app.Commands,
  app_settings : @app.Res[AppSettings],
) -> Unit {
  spawn_buttons(commands, app_settings.get())
}

///|
fn main {
  let widget_click_message_key : @ecs.MessageKey[
    @widgets_lib.WidgetClickEvent[ExampleSetting],
  ] = @widgets_lib.widget_click_event_key()
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(AppSettings::AppSettings())
  .add_message(widget_click_message_key)
  .add_systems_world(@app.Startup, setup)
  .add_systems_param2(@app.Startup, setup_buttons)
  .add_systems_param2(@app.Update, handle_widget_interactions)
  .add_systems_param2(@app.Update, adjust_app_settings)
  .add_systems_world(@app.Update, apply_app_settings)
  .add_systems_param3(@app.Update, update_radio_buttons)
  .add_systems_param2(@app.Update, update_range_value_text)
  .add_systems_param3(@app.Update, move_camera)
  .add_systems_world(@app.Update, rotate_models)
  .run()
}
