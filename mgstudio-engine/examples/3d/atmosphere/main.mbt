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
const SHADER_ASSET_PATH : String = "shaders/water_material.wgsl"

///|
const PI : Float = 3.141592653589793F

///|
const BASE_EXPOSURE_EV100 : Float = 13.0F

///|
struct GameState {
  mut paused : Bool
}

///|
fn GameState::GameState() -> GameState {
  { paused: false }
}

///|
let game_state_resource_key : @ecs.ResourceKey[GameState] = @ecs.register_resource(
  debug_name="mgstudio_examples::atmosphere::GameState",
)

///|
impl @app.Resource for GameState with fn resource() {
  game_state_resource_key
}

///|
struct AtmospherePresets {
  earth : @asset.Handle[@pbr.ScatteringMedium]
  mars : @asset.Handle[@pbr.ScatteringMedium]
}

///|
let atmosphere_presets_resource_key : @ecs.ResourceKey[AtmospherePresets] = @ecs.register_resource(
  debug_name="mgstudio_examples::atmosphere::AtmospherePresets",
)

///|
impl @app.Resource for AtmospherePresets with fn resource() {
  atmosphere_presets_resource_key
}

///|
struct Terrain {}

///|
let terrain_component_key : @ecs.ComponentKey[Terrain] = @ecs.register_component(
  debug_name="mgstudio_examples::atmosphere::Terrain",
)

///|
impl @ecs.Component for Terrain with fn component() {
  terrain_component_key
}

///|
struct WaterSettings {
  octave_vectors : Array[@math.Vec4]
  octave_scales : @math.Vec4
  octave_strengths : @math.Vec4
}

///|
fn WaterSettings::WaterSettings() -> WaterSettings {
  WaterSettings::{
    octave_vectors: [
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    ],
    octave_scales: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
    octave_strengths: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
  }
}

///|
struct Water {
  normals : @asset.Handle[@asset.Image]
  settings : WaterSettings
}

///|
fn Water::Water() -> Water {
  Water::{
    normals: @asset.Handle::new(0),
    settings: WaterSettings::WaterSettings(),
  }
}

///|
type WaterMaterial = @pbr.ExtendedMaterial[@pbr.StandardMaterial, Water]

///|
let water_material_asset_resource_keys : @asset.AssetResourceKeys[WaterMaterial] = @asset.register_asset_resource_keys(
  "mgstudio_examples::atmosphere::ExtendedMaterial<StandardMaterial, Water>",
)

///|
let water_material_keys : @pbr.MaterialKeys[WaterMaterial] = @pbr.register_material_keys(
  "mgstudio_examples::atmosphere::ExtendedMaterial<StandardMaterial, Water>",
)

///|
pub impl @pbr.StandardMaterialExtension for Water with fn extended_material_asset_debug_name() {
  "mgstudio_examples::atmosphere::ExtendedMaterial<StandardMaterial, Water>"
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn extended_material_asset_keys() {
  water_material_asset_resource_keys
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn extended_material_keys() {
  water_material_keys
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn vertex_shader_ref() {
  @pbr.standard_material_extension_default_vertex_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn fragment_shader_ref() {
  @pbr.standard_material_extension_default_fragment_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn prepass_vertex_shader_ref() {
  @pbr.standard_material_extension_default_prepass_vertex_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn prepass_fragment_shader_ref() {
  @pbr.standard_material_extension_default_prepass_fragment_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn deferred_vertex_shader_ref() {
  @pbr.standard_material_extension_default_deferred_vertex_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn deferred_fragment_shader_ref() {
  Some(SHADER_ASSET_PATH)
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn meshlet_fragment_shader_ref() {
  @pbr.standard_material_extension_default_meshlet_fragment_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn meshlet_prepass_fragment_shader_ref() {
  @pbr.standard_material_extension_default_meshlet_prepass_fragment_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn meshlet_deferred_fragment_shader_ref() {
  @pbr.standard_material_extension_default_meshlet_deferred_fragment_shader_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn enable_prepass_ref() {
  @pbr.standard_material_extension_default_enable_prepass_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn enable_shadows_ref() {
  @pbr.standard_material_extension_default_enable_shadows_ref()
}

///|
pub impl @pbr.StandardMaterialExtension for Water with fn specialize_ref() {
  @pbr.standard_material_extension_default_specialize_ref()
}

///|
fn atmosphere_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn atmosphere_push_f32(words : Array[UInt], value : Float) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn atmosphere_push_vec4(words : Array[UInt], value : @math.Vec4) -> Unit {
  atmosphere_push_f32(words, value.x)
  atmosphere_push_f32(words, value.y)
  atmosphere_push_f32(words, value.z)
  atmosphere_push_f32(words, value.w)
}

///|
fn WaterSettings::as_uniform_bytes(self : WaterSettings) -> Bytes {
  let words : Array[UInt] = []
  for vector in self.octave_vectors {
    atmosphere_push_vec4(words, vector)
  }
  atmosphere_push_vec4(words, self.octave_scales)
  atmosphere_push_vec4(words, self.octave_strengths)
  atmosphere_u32le_pack(words)
}

///|
pub impl @pbr.MaterialExtension for Water with fn extension_tag(_self) {
  82
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
fn print_controls() -> Unit {
  println("Atmosphere Example Controls:")
  println("    1          - Switch to lookup texture rendering method")
  println("    2          - Switch to raymarched rendering method")
  println("    3          - Switch to Earth atmosphere")
  println("    4          - Switch to Mars atmosphere")
  println("    Enter      - Pause/Resume sun motion")
  println("    Up/Down    - Increase/Decrease exposure")
}

///|
fn setup_camera_fog(
  commands : @app.Commands,
  scattering_mediums : @app.ResMut[@asset.Assets[@pbr.ScatteringMedium]],
  asset_server_resource : @app.Res[@asset.AssetServer],
) -> Unit {
  let earth_medium = scattering_mediums.modify(fn(assets) {
    assets.add(@pbr.ScatteringMedium::earth(256, 256))
  })
  let mars_phase = asset_server_resource
    .get()
    .load("textures/mars_mie_phase.ktx2")
  let mars_medium = scattering_mediums.modify(fn(assets) {
    assets.add(@pbr.ScatteringMedium::mars(256, 256, mars_phase))
  })
  commands.insert_resource(AtmospherePresets::{
    earth: earth_medium,
    mars: mars_medium,
  })
  ignore(commands.spawn_component(@pbr.Atmosphere::earth(earth_medium)))
  let camera = commands.spawn(
    @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera().with_clear_color(@color.Color::black()),
      @transform.Transform::from_xyz(-2.8F, 0.045F, 0.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_atmosphere_settings(
      Some(@pbr.AtmosphereSettings::AtmosphereSettings()),
    )
    .with_volumetric_fog(
      Some(@pbr.VolumetricFog::VolumetricFog().with_ambient_intensity(0.0F)),
    )
    .with_exposure(Some(@pbr.Exposure::new(BASE_EXPOSURE_EV100)))
    .with_screen_space_reflections(
      Some(
        @post_process.ScreenSpaceReflections::ScreenSpaceReflections().with_min_perceptual_roughness(
          0.0F, 0.0F,
        ),
      ),
    )
    .with_tonemapping(Some(@post_process.Tonemapping::AcesFitted))
    .with_bloom(Some(@post_process.Bloom::natural())),
  )
  commands
  .entity(camera)
  .insert(
    (
      @pbr.AtmosphereEnvironmentMapLight::AtmosphereEnvironmentMapLight(),
      @pbr.Msaa::Off,
      @post_process.TemporalAntiAliasing::TemporalAntiAliasing(),
    ),
  )
}

///|
fn setup_terrain_scene(
  commands : @app.Commands,
  asset_server_resource : @app.Res[@asset.AssetServer],
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  water_material_assets : @app.ResMut[@asset.Assets[WaterMaterial]],
) -> Unit {
  let asset_server = asset_server_resource.get()

  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::new(@color.Color::white(), 130_000.0F, true),
        @transform.Transform::from_xyz(1.0F, 0.4F, 0.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.VolumetricLight::VolumetricLight(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.FogVolume::FogVolume(),
        @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F).with_scale(
          @math.Vec3::new(10.0F, 1.0F, 10.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        Terrain::{  },
        @scene.WorldAssetRoot::new(
          @scene.scene_load_gltf_scene(
            asset_server,
            @gltf.GltfAssetLabel::Scene(0).from_asset(
              "models/terrain/terrain.glb",
            ),
          ),
        ),
        @transform.Transform::from_xyz(-1.0F, 0.0F, -0.5F)
        .with_scale(@math.Vec3::splat(0.5F))
        .with_rotation(@math.Quat::from_rotation_y(PI / 2.0F)),
      ),
    ),
  )

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
  let water_base_material = @pbr.StandardMaterial::from_color(
    @color.Color::black(),
  ).with_perceptual_roughness(0.0F)
  let water_extension = Water::{
    normals: water_normals,
    settings: WaterSettings::{
      octave_vectors: [
        @math.Vec4::new(0.080F, 0.059F, 0.073F, -0.062F),
        @math.Vec4::new(0.153F, 0.138F, -0.149F, -0.195F),
      ],
      octave_scales: @math.Vec4::new(1.0F, 2.1F, 7.9F, 14.9F).mul_scalar(500.0F),
      octave_strengths: @math.Vec4::new(0.16F, 0.18F, 0.093F, 0.044F).mul_scalar(
        0.2F,
      ),
    },
  }
  let water_material = water_material_assets.modify(fn(assets) {
    assets.add(@pbr.ExtendedMaterial::new(water_base_material, water_extension))
  })
  let water_mesh = mesh_assets.peek()
    |> @pbr.add_mesh(
      @mesh_primitives_dim3.PlaneMeshBuilder::from_size(@math.Vec2::splat(1.0F)).build(),
    )
  let water_mesh_material = @pbr.MeshMaterial3dTyped::new(water_material)
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(water_mesh),
        water_mesh_material,
        @transform.Transform::identity().with_scale(@math.Vec3::splat(100.0F)),
      ),
    ),
  )
}

///|
fn atmosphere_controls(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  planet_atmosphere : @ecs.Query[
    (@ecs.Write[@pbr.Atmosphere], @ecs.Write[@transform.Transform]),
    @ecs.All,
  ],
  camera_settings : @ecs.Query[
    @ecs.Write[@pbr.AtmosphereSettings],
    @ecs.With[@camera.Camera3d],
  ],
  atmosphere_presets : @app.Res[AtmospherePresets],
  game_state : @app.ResMut[GameState],
  camera_exposure : @ecs.Query[
    @ecs.Write[@pbr.Exposure],
    @ecs.With[@camera.Camera3d],
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    let presets = atmosphere_presets.get()
    try! planet_atmosphere.view(fn(_entity, item) {
      let atmosphere = @pbr.Atmosphere::earth(presets.earth)
      item.0.set(atmosphere)
      item.1.modify(fn(transform) {
        transform.translation = @math.Vec3::new(
          0.0F,
          -atmosphere.inner_radius,
          0.0F,
        )
      })
    })
    println("Switched to Earth atmosphere")
  }

  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    let presets = atmosphere_presets.get()
    try! planet_atmosphere.view(fn(_entity, item) {
      let atmosphere = @pbr.Atmosphere::mars(presets.mars)
      item.0.set(atmosphere)
      item.1.modify(fn(transform) {
        transform.translation = @math.Vec3::new(
          0.0F,
          -atmosphere.inner_radius,
          0.0F,
        )
      })
    })
    println("Switched to Mars atmosphere")
  }

  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    try! camera_settings.view(fn(_entity, settings) {
      settings.set(
        settings
        .value()
        .with_rendering_method(@pbr.AtmosphereMode::LookupTexture),
      )
    })
    println("Switched to lookup texture rendering method")
  }

  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    try! camera_settings.view(fn(_entity, settings) {
      settings.set(
        settings.value().with_rendering_method(@pbr.AtmosphereMode::Raymarched),
      )
    })
    println("Switched to raymarched rendering method")
  }

  if @input.key_just_pressed(@window.KeyCode::Enter) {
    game_state.modify(fn(state) { state.paused = !state.paused })
  }

  let delta = time.get().delta_seconds()
  let exposure_delta = if keyboard_input.pressed(@window.KeyCode::ArrowUp) {
    -delta * 2.0F
  } else if keyboard_input.pressed(@window.KeyCode::ArrowDown) {
    delta * 2.0F
  } else {
    0.0F
  }
  if exposure_delta != 0.0F {
    try! camera_exposure.view(fn(_entity, exposure) {
      let current = exposure.value()
      exposure.set(current.with_ev100(current.ev100 + exposure_delta))
    })
  }
}

///|
fn dynamic_scene(
  suns : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@pbr.DirectionalLight],
  ],
  time : @app.Res[@time.Time[Unit]],
  sun_motion_state : @app.Res[GameState],
) -> Unit {
  if !sun_motion_state.get().paused {
    try! suns.view(fn(_entity, transform) {
      transform.modify(fn(value) {
        value.rotate(
          @math.Quat::from_rotation_x(-time.get().delta_seconds() * PI / 10.0F),
        )
      })
    })
  }
}

///|
fn setup_instructions(_commands : @app.Commands) -> Unit {
  print_controls()
}

///|
fn main {
  let water_material_plugin : @pbr.MaterialPlugin[WaterMaterial] = @pbr.MaterialPlugin::MaterialPlugin().with_asset_init(fn() {
      @pbr.ExtendedMaterial::new(
        @pbr.StandardMaterial::StandardMaterial(),
        Water::Water(),
      )
    },
  )
  @app.App::new(@ecs.World::new())
  .insert_world_resource(
    @pbr.ecs_key_default_opaque_renderer_method,
    @pbr.DefaultOpaqueRendererMethod::deferred(),
  )
  .insert_resource(@pbr.GlobalAmbientLight::new(@color.Color::white(), 0.0F))
  .insert_resource(@camera.ClearColor::new(@color.Color::black()))
  .insert_resource(GameState::GameState())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(water_material_plugin)
  .add_systems_param3(@app.Startup, setup_camera_fog)
  .add_systems_param4(@app.Startup, setup_terrain_scene)
  .add_systems_param(@app.Startup, setup_instructions)
  .add_systems_param7(@app.Update, atmosphere_controls)
  .add_systems_param3(@app.Update, dynamic_scene)
  .run()
}
