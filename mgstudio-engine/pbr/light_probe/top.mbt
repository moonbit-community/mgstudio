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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/mod.rs`.

///|
const LIGHT_PROBE_PLUGIN_NAME : String = "mgstudio.pbr.light_probe.LightProbePlugin"

///|
pub const MAX_VIEW_LIGHT_PROBES : Int = 8

///|
pub const STANDARD_MATERIAL_FRAGMENT_SHADER_MIN_TEXTURE_BINDINGS : Int = 16

///|
pub const LIGHT_PROBES_UNIFORM_SIZE_BYTES : Int = 2048

///|
pub fn max_view_light_probes() -> Int {
  MAX_VIEW_LIGHT_PROBES
}

///|
pub struct LightProbePlugin {}

///|
pub fn LightProbePlugin::LightProbePlugin() -> LightProbePlugin {
  LightProbePlugin::{  }
}

///|
pub impl @app.Plugin for LightProbePlugin with fn name(_self) {
  LIGHT_PROBE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LightProbePlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  light_probe_plugin_with(app, self)
}

///|
pub struct LightProbePluginState {
  binding_arrays_supported : Bool
  extracted_probe_count : Int
}

///|
pub fn LightProbePluginState::LightProbePluginState() -> LightProbePluginState {
  LightProbePluginState::{
    binding_arrays_supported: true,
    extracted_probe_count: 0,
  }
}

///|
pub fn light_probe_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  light_probe_plugin_with(app, LightProbePlugin::LightProbePlugin())
}

///|
pub fn light_probe_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : LightProbePlugin,
) -> @app.App[@ecs.World] {
  let app = app.init_resource(fn() {
    LightProbePluginState::LightProbePluginState()
  })
  @render.try_with_render_app(app, fn(render_app) {
    render_app
    .add_systems(
      @render.render_startup_schedule_stage(),
      @app.system(init_light_probes_buffer).named(
        "mgstudio_pbr::init_light_probes_buffer",
      ),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(upload_light_probes)
      .named("mgstudio_pbr::upload_light_probes")
      .in_set(@render.render_system_set_prepare_resources),
    )
  })
}

///|
pub fn init_light_probes_buffer(world : @ecs.World) -> Unit {
  if world.resource(ecs_key_light_probes_buffer).is_present() {
    return
  }
  world.insert_resource(
    ecs_key_light_probes_buffer,
    LightProbesBuffer::LightProbesBuffer(),
  )
}

///|
pub fn light_probe_plugin_state_with_extracted_probe_count(
  state : LightProbePluginState,
  extracted_probe_count : Int,
) -> LightProbePluginState {
  LightProbePluginState::{
    ..state,
    extracted_probe_count: if extracted_probe_count < 0 {
      0
    } else {
      extracted_probe_count
    },
  }
}

///|
pub struct RenderLightProbe {
  light_from_world_transposed : Array[@math.Vec4]
  falloff : @math.Vec3
  bounding_sphere_radius : Float
  parallax_correction_bounds : @math.Vec3
  world_position : @math.Vec3
  texture_index : Int
  intensity : Float
  flags : Int
}

///|
pub fn RenderLightProbe::RenderLightProbe() -> RenderLightProbe {
  RenderLightProbe::{
    light_from_world_transposed: [
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    ],
    falloff: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    bounding_sphere_radius: 0.0F,
    parallax_correction_bounds: @math.Vec3::zero(),
    world_position: @math.Vec3::zero(),
    texture_index: -1,
    intensity: 1.0F,
    flags: 0,
  }
}

///|
pub const RENDER_LIGHT_PROBE_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE : Int = 1

///|
pub const RENDER_LIGHT_PROBE_FLAG_ENABLE_PARALLAX_CORRECTION : Int = 2

///|
pub fn render_light_probe_flags_insert(flags : Int, flag : Int) -> Int {
  flags | flag
}

///|
pub fn render_light_probe_flags_contains(flags : Int, flag : Int) -> Bool {
  (flags & flag) != 0
}

///|
pub struct LightProbeTextureId {
  diffuse : @asset.Handle[@asset.Image]?
  specular : @asset.Handle[@asset.Image]?
}

///|
pub fn LightProbeTextureId::environment_map(
  diffuse : @asset.Handle[@asset.Image],
  specular : @asset.Handle[@asset.Image],
) -> LightProbeTextureId {
  LightProbeTextureId::{ diffuse: Some(diffuse), specular: Some(specular) }
}

///|
pub fn LightProbeTextureId::irradiance_volume(
  texture : @asset.Handle[@asset.Image],
) -> LightProbeTextureId {
  LightProbeTextureId::{ diffuse: Some(texture), specular: Some(texture) }
}

///|
pub fn LightProbeTextureId::missing() -> LightProbeTextureId {
  LightProbeTextureId::{ diffuse: None, specular: None }
}

///|
fn light_probe_texture_key(texture : LightProbeTextureId) -> (Int, Int) {
  let diffuse_id = match texture.diffuse {
    Some(handle) => handle.id()
    None => -1
  }
  let specular_id = match texture.specular {
    Some(handle) => handle.id()
    None => -1
  }
  (diffuse_id, specular_id)
}

///|
pub struct RenderViewLightProbes {
  binding_index_to_textures : Array[LightProbeTextureId]
  cubemap_to_binding_index : @hashmap.HashMap[(Int, Int), Int]
  render_light_probes : Array[RenderLightProbe]
  main_entity_to_render_light_probe_index : Map[UInt64, UInt]
  view_light_probe_info : EnvironmentMapViewLightProbeInfo?
}

///|
pub struct LightProbeInfo {
  main_entity : @render.MainEntity
  light_from_world : Array[@math.Vec4]
  falloff : @math.Vec3
  parallax_correction_bounds : @math.Vec3
  world_position : @math.Vec3
  bounding_sphere_radius : Float
  texture : LightProbeTextureId
  intensity : Float
  flags : Int
}

///|
pub fn LightProbeInfo::new(
  main_entity : @render.MainEntity,
  texture : @asset.Handle[@asset.Image]?,
) -> LightProbeInfo {
  let texture_id = match texture {
    Some(handle) => LightProbeTextureId::irradiance_volume(handle)
    None => LightProbeTextureId::missing()
  }
  LightProbeInfo::{
    main_entity,
    light_from_world: [
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    ],
    falloff: @math.Vec3::zero(),
    parallax_correction_bounds: @math.Vec3::zero(),
    world_position: @math.Vec3::zero(),
    bounding_sphere_radius: 0.0F,
    texture: texture_id,
    intensity: 1.0F,
    flags: 0,
  }
}

///|
fn light_probe_image_is_loaded(image : @asset.Handle[@asset.Image]?) -> Bool {
  match image {
    Some(handle) => @render.asset_is_texture_loaded(texture_id=handle.id())
    None => false
  }
}

///|
fn light_probe_entity_affine(
  world : @ecs.World,
  entity : @core.Entity,
) -> @math.Affine3 {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global_transform) => global_transform.affine()
    None =>
      match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
        Some(transform) =>
          @math.Affine3::from_scale_rotation_translation(
            transform.scale,
            transform.rotation,
            transform.translation,
          )
        None => @math.Affine3::identity()
      }
  }
}

///|
fn light_probe_parallax_bounds(
  parallax_correction : @light.ParallaxCorrection?,
) -> @math.Vec3 {
  match parallax_correction {
    Some(@light.ParallaxCorrection::Auto) => @math.Vec3::splat(0.5F)
    Some(@light.ParallaxCorrection::Custom(bounds)) => bounds
    Some(@light.ParallaxCorrection::None) | None => @math.Vec3::zero()
  }
}

///|
fn environment_map_light_probe_flags(
  environment_map_light : @light.EnvironmentMapLight,
  parallax_correction : @light.ParallaxCorrection?,
) -> Int {
  let mut flags = 0
  if environment_map_light.affects_lightmapped_mesh_diffuse {
    flags = render_light_probe_flags_insert(
      flags,
      RENDER_LIGHT_PROBE_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE,
    )
  }
  match parallax_correction {
    Some(@light.ParallaxCorrection::Auto)
    | Some(@light.ParallaxCorrection::Custom(_)) =>
      flags = render_light_probe_flags_insert(
        flags,
        RENDER_LIGHT_PROBE_FLAG_ENABLE_PARALLAX_CORRECTION,
      )
    Some(@light.ParallaxCorrection::None) | None => ()
  }
  flags
}

///|
fn irradiance_volume_light_probe_flags(
  irradiance_volume : @light.IrradianceVolume,
) -> Int {
  if irradiance_volume.affects_lightmapped_meshes {
    render_light_probe_flags_insert(
      0,
      RENDER_LIGHT_PROBE_FLAG_AFFECTS_LIGHTMAPPED_MESH_DIFFUSE,
    )
  } else {
    0
  }
}

///|
fn light_probe_info_from_world_from_light(
  main_entity : @render.MainEntity,
  world_from_light : @math.Affine3,
  light_probe : @light.LightProbe,
  texture : LightProbeTextureId,
  parallax_correction_bounds : @math.Vec3,
  intensity : Float,
  flags : Int,
) -> LightProbeInfo {
  let light_from_world = world_from_light.inverse()
  LightProbeInfo::{
    main_entity,
    light_from_world: [
      @math.Vec4::new(
        light_from_world.matrix3.x_axis.x,
        light_from_world.matrix3.y_axis.x,
        light_from_world.matrix3.z_axis.x,
        light_from_world.translation.x,
      ),
      @math.Vec4::new(
        light_from_world.matrix3.x_axis.y,
        light_from_world.matrix3.y_axis.y,
        light_from_world.matrix3.z_axis.y,
        light_from_world.translation.y,
      ),
      @math.Vec4::new(
        light_from_world.matrix3.x_axis.z,
        light_from_world.matrix3.y_axis.z,
        light_from_world.matrix3.z_axis.z,
        light_from_world.translation.z,
      ),
    ],
    falloff: light_probe.falloff,
    parallax_correction_bounds,
    world_position: world_from_light.translation,
    bounding_sphere_radius: world_from_light.matrix3
    .mul_vec3(@math.Vec3::splat(1.0F))
    .length(),
    texture,
    intensity,
    flags,
  }
}

///|
pub fn LightProbeInfo::from_environment_map_light(
  world : @ecs.World,
  main_entity : @render.MainEntity,
  light_probe : @light.LightProbe,
  environment_map_light : @light.EnvironmentMapLight,
) -> LightProbeInfo? {
  guard light_probe_image_is_loaded(environment_map_light.diffuse_map) &&
    light_probe_image_is_loaded(environment_map_light.specular_map) else {
    return None
  }
  guard environment_map_light.diffuse_map is Some(diffuse) else { return None }
  guard environment_map_light.specular_map is Some(specular) else {
    return None
  }
  let entity = main_entity.id()
  let world_from_light = light_probe_entity_affine(world, entity).mul_rotation_translation(
    environment_map_light.rotation,
    @math.Vec3::zero(),
  )
  let parallax_correction = try! world.get_by_key(
    entity, @light.ecs_key_parallax_correction,
  )
  Some(
    light_probe_info_from_world_from_light(
      main_entity,
      world_from_light,
      light_probe,
      LightProbeTextureId::environment_map(diffuse, specular),
      light_probe_parallax_bounds(parallax_correction),
      environment_map_light.intensity,
      environment_map_light_probe_flags(
        environment_map_light, parallax_correction,
      ),
    ),
  )
}

///|
pub fn LightProbeInfo::from_irradiance_volume(
  world : @ecs.World,
  main_entity : @render.MainEntity,
  light_probe : @light.LightProbe,
  irradiance_volume : @light.IrradianceVolume,
) -> LightProbeInfo? {
  guard light_probe_image_is_loaded(irradiance_volume.voxels) else {
    return None
  }
  guard irradiance_volume.voxels is Some(voxels) else { return None }
  Some(
    light_probe_info_from_world_from_light(
      main_entity,
      light_probe_entity_affine(world, main_entity.id()),
      light_probe,
      LightProbeTextureId::irradiance_volume(voxels),
      @math.Vec3::zero(),
      irradiance_volume.intensity,
      irradiance_volume_light_probe_flags(irradiance_volume),
    ),
  )
}

///|
pub struct RenderViewEnvironmentMapLightProbes {
  probes : RenderViewLightProbes
}

///|
pub struct RenderViewIrradianceVolumeLightProbes {
  probes : RenderViewLightProbes
}

///|
pub fn RenderViewLightProbes::RenderViewLightProbes() -> RenderViewLightProbes {
  RenderViewLightProbes::{
    binding_index_to_textures: [],
    cubemap_to_binding_index: @hashmap.HashMap([]),
    render_light_probes: [],
    main_entity_to_render_light_probe_index: {},
    view_light_probe_info: None,
  }
}

///|
pub fn RenderViewLightProbes::get_or_insert_texture(
  self : RenderViewLightProbes,
  texture : LightProbeTextureId,
) -> Int {
  let texture_key = light_probe_texture_key(texture)
  match self.cubemap_to_binding_index.get(texture_key) {
    Some(index) => return index
    None => ()
  }
  let index = self.binding_index_to_textures.length()
  self.binding_index_to_textures.push(texture)
  self.cubemap_to_binding_index.set(texture_key, index)
  index
}

///|
pub fn RenderViewLightProbes::push_probe(
  self : RenderViewLightProbes,
  probe : RenderLightProbe,
) -> Unit {
  if self.render_light_probes.length() >= MAX_VIEW_LIGHT_PROBES {
    return
  }
  self.render_light_probes.push(probe)
}

///|
fn render_light_probe_from_info(
  info : LightProbeInfo,
  texture_index : Int,
) -> RenderLightProbe {
  RenderLightProbe::{
    light_from_world_transposed: info.light_from_world,
    falloff: info.falloff,
    bounding_sphere_radius: info.bounding_sphere_radius,
    parallax_correction_bounds: info.parallax_correction_bounds,
    world_position: info.world_position,
    texture_index,
    intensity: info.intensity,
    flags: info.flags,
  }
}

///|
pub fn RenderViewLightProbes::maybe_gather_light_probes(
  self : RenderViewLightProbes,
  light_probes : Array[LightProbeInfo],
) -> Unit {
  for light_probe in light_probes {
    if self.render_light_probes.length() >= MAX_VIEW_LIGHT_PROBES {
      break
    }
    let texture_index = self.get_or_insert_texture(light_probe.texture)
    let render_light_probe_index = self.render_light_probes
      .length()
      .reinterpret_as_uint()
    self.main_entity_to_render_light_probe_index.set(
      light_probe.main_entity.id().to_bits(),
      render_light_probe_index,
    )
    self.render_light_probes.push(
      render_light_probe_from_info(light_probe, texture_index),
    )
  }
}

///|
pub fn RenderViewLightProbes::push_probe_for_main_entity(
  self : RenderViewLightProbes,
  main_entity : @render.MainEntity,
  probe : RenderLightProbe,
) -> Unit {
  if self.render_light_probes.length() >= MAX_VIEW_LIGHT_PROBES {
    return
  }
  let index = self.render_light_probes.length().reinterpret_as_uint()
  self.render_light_probes.push(probe)
  self.main_entity_to_render_light_probe_index.set(
    main_entity.id().to_bits(),
    index,
  )
}

///|
pub fn RenderViewLightProbes::add_to_uniform_reflection_probes(
  self : RenderViewLightProbes,
  uniform : LightProbesUniform,
) -> Unit {
  let count = if self.render_light_probes.length() < MAX_VIEW_LIGHT_PROBES {
    self.render_light_probes.length()
  } else {
    MAX_VIEW_LIGHT_PROBES
  }
  for index in 0..<count {
    uniform.reflection_probes[index] = self.render_light_probes[index]
  }
  uniform.reflection_probe_count = count
}

///|
pub fn RenderViewLightProbes::add_to_uniform_irradiance_volumes(
  self : RenderViewLightProbes,
  uniform : LightProbesUniform,
) -> Unit {
  let count = if self.render_light_probes.length() < MAX_VIEW_LIGHT_PROBES {
    self.render_light_probes.length()
  } else {
    MAX_VIEW_LIGHT_PROBES
  }
  for index in 0..<count {
    uniform.irradiance_volumes[index] = self.render_light_probes[index]
  }
  uniform.irradiance_volume_count = count
}

///|
pub fn RenderViewLightProbes::is_empty(self : RenderViewLightProbes) -> Bool {
  self.render_light_probes.length() == 0 && self.view_light_probe_info is None
}

///|
pub fn RenderViewLightProbes::render_light_probe_index(
  self : RenderViewLightProbes,
  main_entity : @render.MainEntity,
) -> UInt? {
  self.main_entity_to_render_light_probe_index.get(main_entity.id().to_bits())
}

///|
pub fn RenderViewLightProbes::texture_count(
  self : RenderViewLightProbes,
) -> Int {
  self.binding_index_to_textures.length()
}

///|
pub fn RenderViewLightProbes::probe_count(self : RenderViewLightProbes) -> Int {
  self.render_light_probes.length()
}

///|
pub fn RenderViewEnvironmentMapLightProbes::new(
  probes : RenderViewLightProbes,
) -> RenderViewEnvironmentMapLightProbes {
  RenderViewEnvironmentMapLightProbes::{ probes, }
}

///|
pub fn RenderViewEnvironmentMapLightProbes::probe_count(
  self : RenderViewEnvironmentMapLightProbes,
) -> Int {
  self.probes.probe_count()
}

///|
pub fn RenderViewEnvironmentMapLightProbes::probes(
  self : RenderViewEnvironmentMapLightProbes,
) -> RenderViewLightProbes {
  self.probes
}

///|
pub fn RenderViewIrradianceVolumeLightProbes::new(
  probes : RenderViewLightProbes,
) -> RenderViewIrradianceVolumeLightProbes {
  RenderViewIrradianceVolumeLightProbes::{ probes, }
}

///|
pub fn RenderViewIrradianceVolumeLightProbes::probe_count(
  self : RenderViewIrradianceVolumeLightProbes,
) -> Int {
  self.probes.probe_count()
}

///|
pub fn RenderViewIrradianceVolumeLightProbes::probes(
  self : RenderViewIrradianceVolumeLightProbes,
) -> RenderViewLightProbes {
  self.probes
}

///|
pub let ecs_key_light_probe_plugin_state : @ecs.ResourceKey[
  LightProbePluginState,
] = @ecs.register_resource(debug_name="mgstudio.pbr.light_probe.plugin_state")

///|
pub let ecs_key_render_view_light_probes : @ecs.ComponentKey[
  RenderViewLightProbes,
] = @ecs.register_component(
  debug_name="mgstudio.pbr.light_probe.render_view_light_probes",
)

///|
pub let ecs_key_render_view_environment_map_light_probes : @ecs.ComponentKey[
  RenderViewEnvironmentMapLightProbes,
] = @ecs.register_component(
  debug_name="mgstudio.pbr.light_probe.render_view_environment_map_light_probes",
)

///|
pub let ecs_key_render_view_irradiance_volume_light_probes : @ecs.ComponentKey[
  RenderViewIrradianceVolumeLightProbes,
] = @ecs.register_component(
  debug_name="mgstudio.pbr.light_probe.render_view_irradiance_volume_light_probes",
)

///|
pub struct LightProbesUniform {
  reflection_probes : Array[RenderLightProbe]
  irradiance_volumes : Array[RenderLightProbe]
  mut reflection_probe_count : Int
  mut irradiance_volume_count : Int
  view_cubemap_index : Int
  smallest_specular_mip_level_for_view : Int
  view_rotation : @math.Quat
  intensity_for_view : Float
  view_environment_map_affects_lightmapped_mesh_diffuse : Bool
}

///|
pub fn LightProbesUniform::LightProbesUniform() -> LightProbesUniform {
  LightProbesUniform::{
    reflection_probes: Array::make(
      MAX_VIEW_LIGHT_PROBES,
      RenderLightProbe::RenderLightProbe(),
    ),
    irradiance_volumes: Array::make(
      MAX_VIEW_LIGHT_PROBES,
      RenderLightProbe::RenderLightProbe(),
    ),
    reflection_probe_count: 0,
    irradiance_volume_count: 0,
    view_cubemap_index: -1,
    smallest_specular_mip_level_for_view: 0,
    view_rotation: @math.Quat::identity(),
    intensity_for_view: 1.0F,
    view_environment_map_affects_lightmapped_mesh_diffuse: true,
  }
}

///|
pub fn LightProbesUniform::reflection_probe_capacity(
  self : LightProbesUniform,
) -> Int {
  self.reflection_probes.length()
}

///|
pub fn LightProbesUniform::irradiance_volume_capacity(
  self : LightProbesUniform,
) -> Int {
  self.irradiance_volumes.length()
}

///|
pub fn LightProbesUniform::view_cubemap_index(self : LightProbesUniform) -> Int {
  self.view_cubemap_index
}

///|
fn light_probe_push_f32(words : Array[UInt], value : Float) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn light_probe_push_i32(words : Array[UInt], value : Int) -> Unit {
  words.push(value.reinterpret_as_uint())
}

///|
fn light_probe_push_render_light_probe(
  words : Array[UInt],
  probe : RenderLightProbe,
) -> Unit {
  let first = probe.light_from_world_transposed[0]
  let second = probe.light_from_world_transposed[1]
  let third = probe.light_from_world_transposed[2]
  light_probe_push_f32(words, first.x)
  light_probe_push_f32(words, first.y)
  light_probe_push_f32(words, first.z)
  light_probe_push_f32(words, first.w)
  light_probe_push_f32(words, second.x)
  light_probe_push_f32(words, second.y)
  light_probe_push_f32(words, second.z)
  light_probe_push_f32(words, second.w)
  light_probe_push_f32(words, third.x)
  light_probe_push_f32(words, third.y)
  light_probe_push_f32(words, third.z)
  light_probe_push_f32(words, third.w)
  light_probe_push_f32(words, probe.falloff.x)
  light_probe_push_f32(words, probe.falloff.y)
  light_probe_push_f32(words, probe.falloff.z)
  light_probe_push_f32(words, probe.bounding_sphere_radius)
  light_probe_push_f32(words, probe.parallax_correction_bounds.x)
  light_probe_push_f32(words, probe.parallax_correction_bounds.y)
  light_probe_push_f32(words, probe.parallax_correction_bounds.z)
  light_probe_push_f32(words, probe.intensity)
  light_probe_push_f32(words, probe.world_position.x)
  light_probe_push_f32(words, probe.world_position.y)
  light_probe_push_f32(words, probe.world_position.z)
  light_probe_push_i32(words, probe.texture_index)
  words.push(probe.flags.reinterpret_as_uint())
  words.push(0U)
  words.push(0U)
  words.push(0U)
}

///|
fn light_probe_push_empty_render_light_probe(words : Array[UInt]) -> Unit {
  for _ in 0..<28 {
    words.push(0U)
  }
}

///|
fn light_probe_pack_u32le(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, index => {
    let word = words[index / 4]
    ((word >> (index % 4 * 8)) & 0xFF).to_byte()
  })
}

///|
pub fn LightProbesUniform::to_bytes(self : LightProbesUniform) -> Bytes {
  let words : Array[UInt] = []
  for index in 0..<MAX_VIEW_LIGHT_PROBES {
    if index < self.reflection_probe_count {
      light_probe_push_render_light_probe(words, self.reflection_probes[index])
    } else {
      light_probe_push_empty_render_light_probe(words)
    }
  }
  for index in 0..<MAX_VIEW_LIGHT_PROBES {
    if index < self.irradiance_volume_count {
      light_probe_push_render_light_probe(words, self.irradiance_volumes[index])
    } else {
      light_probe_push_empty_render_light_probe(words)
    }
  }
  words.push(self.reflection_probe_count.reinterpret_as_uint())
  words.push(self.irradiance_volume_count.reinterpret_as_uint())
  light_probe_push_i32(words, self.view_cubemap_index)
  words.push(self.smallest_specular_mip_level_for_view.reinterpret_as_uint())
  light_probe_push_f32(words, self.view_rotation.x)
  light_probe_push_f32(words, self.view_rotation.y)
  light_probe_push_f32(words, self.view_rotation.z)
  light_probe_push_f32(words, self.view_rotation.w)
  light_probe_push_f32(words, self.intensity_for_view)
  words.push(
    if self.view_environment_map_affects_lightmapped_mesh_diffuse {
      1U
    } else {
      0U
    },
  )
  while words.length() < LIGHT_PROBES_UNIFORM_SIZE_BYTES / 4 {
    words.push(0U)
  }
  light_probe_pack_u32le(words)
}

///|
pub fn LightProbesUniform::from_render_view_light_probes(
  render_view_environment_maps : RenderViewEnvironmentMapLightProbes?,
  render_view_irradiance_volumes : RenderViewIrradianceVolumeLightProbes?,
) -> LightProbesUniform {
  let uniform = LightProbesUniform::LightProbesUniform()
  match render_view_environment_maps {
    Some(environment_maps) =>
      environment_maps.probes().add_to_uniform_reflection_probes(uniform)
    None => ()
  }
  match render_view_irradiance_volumes {
    Some(irradiance_volumes) =>
      irradiance_volumes.probes().add_to_uniform_irradiance_volumes(uniform)
    None => ()
  }
  uniform
}

///|
pub struct LightProbesBuffer {
  uniform_bytes : Array[Bytes]
  mut gpu_buffer : @wgpu.Buffer?
  mut gpu_capacity : UInt64
}

///|
pub fn LightProbesBuffer::LightProbesBuffer() -> LightProbesBuffer {
  LightProbesBuffer::{ uniform_bytes: [], gpu_buffer: None, gpu_capacity: 0UL }
}

///|
pub fn LightProbesBuffer::clear(self : LightProbesBuffer) -> Unit {
  self.uniform_bytes.clear()
}

///|
pub fn LightProbesBuffer::push_uniform_bytes(
  self : LightProbesBuffer,
  uniform_bytes : Bytes,
) -> UInt {
  let offset = self.uniform_bytes.length() * LIGHT_PROBES_UNIFORM_SIZE_BYTES
  self.uniform_bytes.push(uniform_bytes)
  offset.reinterpret_as_uint()
}

///|
pub fn LightProbesBuffer::uniform_count(self : LightProbesBuffer) -> Int {
  self.uniform_bytes.length()
}

///|
pub fn LightProbesBuffer::uniform_bytes_at(
  self : LightProbesBuffer,
  index : Int,
) -> Bytes? {
  if index < 0 || index >= self.uniform_bytes.length() {
    None
  } else {
    Some(self.uniform_bytes[index])
  }
}

///|
fn light_probes_buffer_non_zero_u64(value : UInt64) -> UInt64 {
  if value == 0UL {
    4UL
  } else {
    value
  }
}

///|
fn LightProbesBuffer::light_probes_buffer_bytes(
  self : LightProbesBuffer,
) -> Bytes {
  let out : Array[Byte] = []
  for uniform in self.uniform_bytes {
    for byte in uniform {
      out.push(byte)
    }
  }
  Bytes::from_array(out)
}

///|
pub fn LightProbesBuffer::write_buffer(
  self : LightProbesBuffer,
  device : @wgpu.Device,
  queue : @wgpu.Queue,
) -> Unit {
  let bytes = self.light_probes_buffer_bytes()
  if bytes.length() == 0 {
    return
  }
  let required_size = light_probes_buffer_non_zero_u64(
    bytes.length().to_uint64(),
  )
  let buffer = match self.gpu_buffer {
    Some(existing) if self.gpu_capacity >= required_size => existing
    Some(existing) => {
      existing.release()
      let next = device.create_buffer(
        size=required_size,
        usage=@wgpu.BufferUsage::from_u64(
          @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
        ),
      )
      next.set_label("light probes buffer")
      self.gpu_capacity = required_size
      next
    }
    None => {
      let next = device.create_buffer(
        size=required_size,
        usage=@wgpu.BufferUsage::from_u64(
          @wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST,
        ),
      )
      next.set_label("light probes buffer")
      self.gpu_capacity = required_size
      next
    }
  }
  queue.write_buffer(buffer, 0UL, bytes)
  self.gpu_buffer = Some(buffer)
}

///|
pub fn LightProbesBuffer::binding(self : LightProbesBuffer) -> @wgpu.Buffer? {
  self.gpu_buffer
}

///|
pub fn LightProbesBuffer::gpu_capacity(self : LightProbesBuffer) -> UInt64 {
  self.gpu_capacity
}

///|
fn light_probes_buffer_or_insert(world : @ecs.World) -> LightProbesBuffer {
  match world.get_resource(ecs_key_light_probes_buffer) {
    Some(value) => value
    None => {
      let value = LightProbesBuffer::LightProbesBuffer()
      world.insert_resource(ecs_key_light_probes_buffer, value)
      value
    }
  }
}

///|
pub fn upload_light_probes(world : @ecs.World) -> Unit {
  let view_entities : Array[@core.Entity] = []
  world.for_each_component(@render_view.ExtractedView::component(), fn(
    entity,
    _view,
  ) {
    view_entities.push(entity)
  })
  if view_entities.length() == 0 {
    return
  }

  let light_probes_buffer = light_probes_buffer_or_insert(world)
  light_probes_buffer.clear()
  for view_entity in view_entities {
    let render_view_environment_maps = world.get_by_key(
      view_entity,
      RenderViewEnvironmentMapLightProbes::component(),
    ) catch {
      _ => None
    }
    let render_view_irradiance_volumes = world.get_by_key(
      view_entity,
      RenderViewIrradianceVolumeLightProbes::component(),
    ) catch {
      _ => None
    }
    let light_probes_uniform = LightProbesUniform::from_render_view_light_probes(
      render_view_environment_maps, render_view_irradiance_volumes,
    )
    let uniform_offset = light_probes_buffer.push_uniform_bytes(
      light_probes_uniform.to_bytes(),
    )
    try! world.set_by_key(
      view_entity,
      ViewLightProbesUniformOffset::component(),
      ViewLightProbesUniformOffset::new(uniform_offset),
    )
  }
}

///|
pub let ecs_key_light_probes_buffer : @ecs.ResourceKey[LightProbesBuffer] = @ecs.register_resource(
  debug_name="mgstudio.pbr.light_probe.buffer",
)

///|
pub struct ViewLightProbesUniformOffset {
  offset : UInt
}

///|
pub fn ViewLightProbesUniformOffset::ViewLightProbesUniformOffset() -> ViewLightProbesUniformOffset {
  ViewLightProbesUniformOffset::{ offset: 0U }
}

///|
pub fn ViewLightProbesUniformOffset::new(
  offset : UInt,
) -> ViewLightProbesUniformOffset {
  ViewLightProbesUniformOffset::{ offset, }
}

///|
pub fn ViewLightProbesUniformOffset::offset(
  self : ViewLightProbesUniformOffset,
) -> UInt {
  self.offset
}

///|
pub let ecs_key_view_light_probes_uniform_offset : @ecs.ComponentKey[
  ViewLightProbesUniformOffset,
] = @ecs.register_component(
  debug_name="mgstudio.pbr.light_probe.uniform_offset",
)

///|
pub impl @app.Resource for LightProbePluginState with fn resource() {
  ecs_key_light_probe_plugin_state
}

///|
pub impl @ecs.Component for RenderViewLightProbes with fn component() {
  ecs_key_render_view_light_probes
}

///|
pub impl @ecs.Component for RenderViewEnvironmentMapLightProbes with fn component() {
  ecs_key_render_view_environment_map_light_probes
}

///|
pub impl @ecs.Component for RenderViewIrradianceVolumeLightProbes with fn component() {
  ecs_key_render_view_irradiance_volume_light_probes
}

///|
pub impl @app.Resource for LightProbesBuffer with fn resource() {
  ecs_key_light_probes_buffer
}

///|
pub impl @ecs.Component for ViewLightProbesUniformOffset with fn component() {
  ecs_key_view_light_probes_uniform_offset
}
