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
}

///|
pub(all) enum DisplayedBase {
  Water
  Metallic
  RedPlane
}

///|
priv struct SsrState {
  mut ssr_on : Bool
  mut displayed_model : DisplayedModel
  mut displayed_base : DisplayedBase
  mut min_roughness_start : Float
  mut min_roughness_end : Float
  mut max_roughness_start : Float
  mut max_roughness_end : Float
  mut edge_fadeout_start : Float
  mut edge_fadeout_end : Float
  mut thickness : Float
  mut linear_steps : Int
  mut bisection_steps : Int
  mut linear_march_exponent : Float
  mut use_secant : Bool
  mut camera_radius : Float
  mut camera_theta : Float
  mut camera : @core.Entity?
  mut cube_model : @core.Entity?
  mut flight_helmet_model : @core.Entity?
  capsule_models : Array[@core.Entity]
  mut metallic_base : @core.Entity?
  mut red_plane_base : @core.Entity?
  mut water_base : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let ssr_state : Ref[SsrState] = Ref({
  ssr_on: true,
  displayed_model: DisplayedModel::Cube,
  displayed_base: DisplayedBase::Water,
  min_roughness_start: 0.0F,
  min_roughness_end: 0.01F,
  max_roughness_start: 0.99F,
  max_roughness_end: 1.0F,
  edge_fadeout_start: 0.0F,
  edge_fadeout_end: 0.0F,
  thickness: 0.25F,
  linear_steps: 10,
  bisection_steps: 5,
  linear_march_exponent: 1.0F,
  use_secant: true,
  camera_radius: 4.67F,
  camera_theta: -0.2709468503F,
  camera: None,
  cube_model: None,
  flight_helmet_model: None,
  capsule_models: [],
  metallic_base: None,
  red_plane_base: None,
  water_base: None,
  help_text: None,
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
fn model_name(model : DisplayedModel) -> String {
  match model {
    Cube => "Cube"
    FlightHelmet => "Flight Helmet"
    Capsules => "Capsules"
  }
}

///|
fn base_name(base : DisplayedBase) -> String {
  match base {
    Water => "Water"
    Metallic => "Metallic"
    RedPlane => "Red Plane"
  }
}

///|
fn on_off_label(value : Bool) -> String {
  if value {
    "On"
  } else {
    "Off"
  }
}

///|
fn ssr_ui_text() -> String {
  let state = ssr_state.val
  "SSR Example (upstream-aligned scene flow, adapted render path)\n\nSSR: 1=On 2=Off | Current: \{on_off_label(state.ssr_on)}\nModel: 3=Cube 4=FlightHelmet 5=Capsules | Current: \{model_name(state.displayed_model)}\nBase: 6=Water Q=Metallic E=RedPlane | Current: \{base_name(state.displayed_base)}\n\nCamera: W/S zoom, A/D orbit, Mouse Wheel zoom\n\nMin Roughness Start: J-/U+ = \{state.min_roughness_start}\nMin Roughness End:   K-/I+ = \{state.min_roughness_end}\nMax Roughness Start: N-/M+ = \{state.max_roughness_start}\nMax Roughness End: ,-/ .+ = \{state.max_roughness_end}\nEdge Fadeout Start: R-/T+ = \{state.edge_fadeout_start}\nEdge Fadeout End:   F-/G+ = \{state.edge_fadeout_end}\n"
}

///|
fn update_help_text() -> Unit {
  if ssr_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, ssr_ui_text())
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
  let model = ssr_state.val.displayed_model
  let base = ssr_state.val.displayed_base

  set_entity_visibility(world, ssr_state.val.cube_model, model is Cube)
  set_entity_visibility(
    world,
    ssr_state.val.flight_helmet_model,
    model is FlightHelmet,
  )
  for capsule in ssr_state.val.capsule_models {
    set_entity_visibility(world, Some(capsule), model is Capsules)
  }

  set_entity_visibility(world, ssr_state.val.water_base, base is Water)
  set_entity_visibility(world, ssr_state.val.metallic_base, base is Metallic)
  set_entity_visibility(world, ssr_state.val.red_plane_base, base is RedPlane)
}

///|
fn apply_camera_transform(world : @ecs.World) -> Unit {
  if ssr_state.val.camera is Some(camera) {
    let x = @math.sin(ssr_state.val.camera_theta) * ssr_state.val.camera_radius
    let z = @math.cos(ssr_state.val.camera_theta) * ssr_state.val.camera_radius
    try! (world.replace(
      camera,
      @transform.ecs_key_transform,
      @transform.Transform::from_xyz(x, CAMERA_HEIGHT, z).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    |> ignore)
  }
}

///|
fn sanitize_ssr_ranges() -> Unit {
  let (min_start, min_end) = ordered_unit_range(
    ssr_state.val.min_roughness_start,
    ssr_state.val.min_roughness_end,
  )
  ssr_state.val.min_roughness_start = min_start
  ssr_state.val.min_roughness_end = min_end

  let (max_start, max_end) = ordered_unit_range(
    ssr_state.val.max_roughness_start,
    ssr_state.val.max_roughness_end,
  )
  ssr_state.val.max_roughness_start = max_start
  ssr_state.val.max_roughness_end = max_end

  let (edge_start, edge_end) = ordered_unit_range(
    ssr_state.val.edge_fadeout_start,
    ssr_state.val.edge_fadeout_end,
  )
  ssr_state.val.edge_fadeout_start = edge_start
  ssr_state.val.edge_fadeout_end = edge_end

  ssr_state.val.thickness = clampf(ssr_state.val.thickness, 0.0F, 5.0F)
  ssr_state.val.linear_steps = if ssr_state.val.linear_steps <= 0 {
    1
  } else {
    ssr_state.val.linear_steps
  }
  ssr_state.val.bisection_steps = if ssr_state.val.bisection_steps < 0 {
    0
  } else {
    ssr_state.val.bisection_steps
  }
  ssr_state.val.linear_march_exponent = clampf(
    ssr_state.val.linear_march_exponent,
    0.1F,
    4.0F,
  )
}

///|
fn build_ssr_settings() -> @post_process.ScreenSpaceReflections {
  @post_process.ScreenSpaceReflections::ScreenSpaceReflections()
  .with_min_perceptual_roughness(
    ssr_state.val.min_roughness_start,
    ssr_state.val.min_roughness_end,
  )
  .with_max_perceptual_roughness(
    ssr_state.val.max_roughness_start,
    ssr_state.val.max_roughness_end,
  )
  .with_edge_fadeout(
    ssr_state.val.edge_fadeout_start,
    ssr_state.val.edge_fadeout_end,
  )
  .with_thickness(ssr_state.val.thickness)
  .with_linear_steps(ssr_state.val.linear_steps)
  .with_bisection_steps(ssr_state.val.bisection_steps)
  .with_linear_march_exponent(ssr_state.val.linear_march_exponent)
  .with_use_secant(ssr_state.val.use_secant)
}

///|
fn apply_ssr_settings(world : @ecs.World) -> Unit {
  sanitize_ssr_ranges()
  if ssr_state.val.camera is Some(camera) {
    if ssr_state.val.ssr_on {
      if !(try! world.replace(
          camera,
          @post_process.ecs_key_screen_space_reflections,
          build_ssr_settings(),
        )) {
        try! world.set_by_key(
          camera,
          @post_process.ecs_key_screen_space_reflections,
          build_ssr_settings(),
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
  ssr_state.val.cube_model = Some(cube)
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
  ssr_state.val.flight_helmet_model = Some(entity)
}

///|
fn spawn_capsules(world : @ecs.World) -> Unit {
  ssr_state.val.capsule_models.clear()
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
  ssr_state.val.capsule_models.push(parent)
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
    ssr_state.val.capsule_models.push(entity)
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
  ssr_state.val.metallic_base = Some(metallic)

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
  ssr_state.val.red_plane_base = Some(red)

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
  ssr_state.val.water_base = Some(water)
}

///|
fn setup_camera_and_lights(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let camera = @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      @transform.Transform::from_xyz(-1.25F, CAMERA_HEIGHT, 4.5F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_screen_space_reflections(Some(build_ssr_settings()))
    .spawn(world)
  ssr_state.val.camera = Some(camera)

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
fn setup_text() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(ssr_ui_text()),
      @text.TextFont::TextFont().with_font(font).with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(790.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@color.Color::white()))
    .spawn()

  ssr_state.val.help_text = Some(handle)
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

  if ssr_state.val.cube_model is Some(cube) {
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

  if ssr_state.val.flight_helmet_model is Some(helmet) {
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
fn adjust_camera_controls(world : @ecs.World) -> Bool {
  let mut changed = false

  if @input.key_pressed(@window.KeyCode::KeyW) {
    ssr_state.val.camera_radius = clampf(
      ssr_state.val.camera_radius - CAMERA_KEYBOARD_ZOOM_SPEED,
      CAMERA_MIN_RADIUS,
      CAMERA_MAX_RADIUS,
    )
    changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    ssr_state.val.camera_radius = clampf(
      ssr_state.val.camera_radius + CAMERA_KEYBOARD_ZOOM_SPEED,
      CAMERA_MIN_RADIUS,
      CAMERA_MAX_RADIUS,
    )
    changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyA) {
    ssr_state.val.camera_theta = ssr_state.val.camera_theta +
      CAMERA_KEYBOARD_ORBIT_SPEED
    changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    ssr_state.val.camera_theta = ssr_state.val.camera_theta -
      CAMERA_KEYBOARD_ORBIT_SPEED
    changed = true
  }

  if @input.mouse_wheel_delta_opt() is Some(wheel) {
    ssr_state.val.camera_radius = clampf(
      ssr_state.val.camera_radius - wheel.y * CAMERA_MOUSE_WHEEL_ZOOM_SPEED,
      CAMERA_MIN_RADIUS,
      CAMERA_MAX_RADIUS,
    )
    changed = true
  }

  if changed {
    apply_camera_transform(world)
  }
  changed
}

///|
fn control_system(world : @ecs.World) -> Unit {
  let mut settings_changed = false
  let mut visibility_changed = false

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    ssr_state.val.ssr_on = true
    settings_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    ssr_state.val.ssr_on = false
    settings_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    ssr_state.val.displayed_model = DisplayedModel::Cube
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    ssr_state.val.displayed_model = DisplayedModel::FlightHelmet
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    ssr_state.val.displayed_model = DisplayedModel::Capsules
    visibility_changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Digit6) {
    ssr_state.val.displayed_base = DisplayedBase::Water
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    ssr_state.val.displayed_base = DisplayedBase::Metallic
    visibility_changed = true
  }
  if @input.key_just_pressed(@window.KeyCode::KeyE) {
    ssr_state.val.displayed_base = DisplayedBase::RedPlane
    visibility_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyU) {
    ssr_state.val.min_roughness_start = ssr_state.val.min_roughness_start +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyJ) {
    ssr_state.val.min_roughness_start = ssr_state.val.min_roughness_start -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyI) {
    ssr_state.val.min_roughness_end = ssr_state.val.min_roughness_end +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyK) {
    ssr_state.val.min_roughness_end = ssr_state.val.min_roughness_end -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyM) {
    ssr_state.val.max_roughness_start = ssr_state.val.max_roughness_start +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyN) {
    ssr_state.val.max_roughness_start = ssr_state.val.max_roughness_start -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::Period) {
    ssr_state.val.max_roughness_end = ssr_state.val.max_roughness_end +
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::Comma) {
    ssr_state.val.max_roughness_end = ssr_state.val.max_roughness_end -
      RANGE_STEP_ROUGHNESS
    settings_changed = true
  }

  if @input.key_pressed(@window.KeyCode::KeyT) {
    ssr_state.val.edge_fadeout_start = ssr_state.val.edge_fadeout_start +
      RANGE_STEP_EDGE
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyR) {
    ssr_state.val.edge_fadeout_start = ssr_state.val.edge_fadeout_start -
      RANGE_STEP_EDGE
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyG) {
    ssr_state.val.edge_fadeout_end = ssr_state.val.edge_fadeout_end +
      RANGE_STEP_EDGE
    settings_changed = true
  }
  if @input.key_pressed(@window.KeyCode::KeyF) {
    ssr_state.val.edge_fadeout_end = ssr_state.val.edge_fadeout_end -
      RANGE_STEP_EDGE
    settings_changed = true
  }

  let camera_changed = adjust_camera_controls(world)

  if settings_changed {
    apply_ssr_settings(world)
  }
  if visibility_changed {
    apply_model_and_base_visibility(world)
  }

  if settings_changed || visibility_changed || camera_changed {
    update_help_text()
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_default_opaque_renderer_method,
    @pbr.DefaultOpaqueRendererMethod::deferred(),
  )

  ssr_state.val.ssr_on = true
  ssr_state.val.displayed_model = DisplayedModel::Cube
  ssr_state.val.displayed_base = DisplayedBase::Water
  ssr_state.val.min_roughness_start = 0.0F
  ssr_state.val.min_roughness_end = 0.01F
  ssr_state.val.max_roughness_start = 0.99F
  ssr_state.val.max_roughness_end = 1.0F
  ssr_state.val.edge_fadeout_start = 0.0F
  ssr_state.val.edge_fadeout_end = 0.0F
  ssr_state.val.thickness = 0.25F
  ssr_state.val.linear_steps = 10
  ssr_state.val.bisection_steps = 5
  ssr_state.val.linear_march_exponent = 1.0F
  ssr_state.val.use_secant = true
  ssr_state.val.camera_radius = 4.67F
  ssr_state.val.camera_theta = -0.2709468503F
  ssr_state.val.camera = None
  ssr_state.val.cube_model = None
  ssr_state.val.flight_helmet_model = None
  ssr_state.val.capsule_models.clear()
  ssr_state.val.metallic_base = None
  ssr_state.val.red_plane_base = None
  ssr_state.val.water_base = None
  ssr_state.val.help_text = None

  let asset_server = @asset.AssetServer::new()

  spawn_cube(world, asset_server)
  spawn_flight_helmet(world, asset_server)
  spawn_capsules(world)
  spawn_bases(world, asset_server)
  setup_camera_and_lights(world)
  setup_text()

  apply_ssr_settings(world)
  apply_model_and_base_visibility(world)
  apply_camera_transform(world)
  update_help_text()
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_world(@app.Startup, setup)
  .add_systems_world(@app.Update, control_system)
  .add_systems_world(@app.Update, rotate_models)
  .run()
}
