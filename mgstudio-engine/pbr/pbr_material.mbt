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
pub type AlphaMode3d = @material.AlphaMode3d

///|
pub type Face3d = @material.Face3d

///|
pub type OpaqueRendererMethod = @material.OpaqueRendererMethod

///|
pub type DefaultOpaqueRendererMethod = @material.DefaultOpaqueRendererMethod

///|
pub type StandardMaterial = @material.StandardMaterial

///|
const STANDARD_MATERIAL_PLUGIN_NAME : String = "mgstudio.pbr.MaterialPlugin<StandardMaterial>"

///|
pub const STANDARD_MATERIAL_KEY_CULL_FRONT : UInt64 = 0x000001UL

///|
pub const STANDARD_MATERIAL_KEY_CULL_BACK : UInt64 = 0x000002UL

///|
pub const STANDARD_MATERIAL_KEY_NORMAL_MAP : UInt64 = 0x000004UL

///|
pub const STANDARD_MATERIAL_KEY_RELIEF_MAPPING : UInt64 = 0x000008UL

///|
pub const STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION : UInt64 = 0x000010UL

///|
pub const STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION : UInt64 = 0x000020UL

///|
pub const STANDARD_MATERIAL_KEY_CLEARCOAT : UInt64 = 0x000040UL

///|
pub const STANDARD_MATERIAL_KEY_CLEARCOAT_NORMAL_MAP : UInt64 = 0x000080UL

///|
pub const STANDARD_MATERIAL_KEY_ANISOTROPY : UInt64 = 0x000100UL

///|
pub const STANDARD_MATERIAL_KEY_BASE_COLOR_TEXTURE : UInt64 = 0x000200UL

///|
pub const STANDARD_MATERIAL_KEY_EMISSIVE_TEXTURE : UInt64 = 0x000400UL

///|
pub const STANDARD_MATERIAL_KEY_METALLIC_ROUGHNESS_TEXTURE : UInt64 = 0x000800UL

///|
pub const STANDARD_MATERIAL_KEY_OCCLUSION_TEXTURE : UInt64 = 0x001000UL

///|
pub const STANDARD_MATERIAL_KEY_DEPTH_BIAS_MASK : UInt64 = 0xffffffff00000000UL

///|
pub const STANDARD_MATERIAL_KEY_DEPTH_BIAS_SHIFT : Int = 32

///|
pub struct StandardMaterialKey {
  bits : UInt64
} derive(Eq, Debug)

///|
pub fn StandardMaterialKey::empty() -> StandardMaterialKey {
  StandardMaterialKey::{ bits: 0UL }
}

///|
pub fn StandardMaterialKey::from_bits(bits : UInt64) -> StandardMaterialKey {
  StandardMaterialKey::{ bits, }
}

///|
pub fn StandardMaterialKey::bits(self : StandardMaterialKey) -> UInt64 {
  self.bits
}

///|
pub fn StandardMaterialKey::contains(
  self : StandardMaterialKey,
  flag : UInt64,
) -> Bool {
  (self.bits & flag) != 0UL
}

///|
pub fn StandardMaterialKey::with_flag(
  self : StandardMaterialKey,
  flag : UInt64,
) -> StandardMaterialKey {
  StandardMaterialKey::{ bits: self.bits | flag }
}

///|
pub fn StandardMaterialKey::without_flag(
  self : StandardMaterialKey,
  flag : UInt64,
) -> StandardMaterialKey {
  StandardMaterialKey::{ bits: self.bits & (0xffffffffffffffffUL ^ flag) }
}

///|
pub fn StandardMaterialKey::with_depth_bias(
  self : StandardMaterialKey,
  depth_bias : UInt,
) -> StandardMaterialKey {
  let bias_bits = (
      depth_bias.to_uint64() << STANDARD_MATERIAL_KEY_DEPTH_BIAS_SHIFT
    ) &
    STANDARD_MATERIAL_KEY_DEPTH_BIAS_MASK
  StandardMaterialKey::{
    bits: (
      self.bits & (0xffffffffffffffffUL ^ STANDARD_MATERIAL_KEY_DEPTH_BIAS_MASK)
    ) |
    bias_bits,
  }
}

///|
pub fn StandardMaterialKey::depth_bias(self : StandardMaterialKey) -> UInt {
  let value = (self.bits & STANDARD_MATERIAL_KEY_DEPTH_BIAS_MASK) >>
    STANDARD_MATERIAL_KEY_DEPTH_BIAS_SHIFT
  value.to_uint()
}

///|
pub fn standard_material_key_from_material(
  material : StandardMaterial,
) -> StandardMaterialKey {
  let mut bits : UInt64 = 0UL
  match material.cull_mode {
    Some(Face3d::Front) => bits = bits | STANDARD_MATERIAL_KEY_CULL_FRONT
    Some(Face3d::Back) => bits = bits | STANDARD_MATERIAL_KEY_CULL_BACK
    None => ()
  }
  if material.normal_map_texture is Some(_) {
    bits = bits | STANDARD_MATERIAL_KEY_NORMAL_MAP
  }
  match material.parallax_mapping_method {
    @material.ParallaxMappingMethod::Relief(_) =>
      bits = bits | STANDARD_MATERIAL_KEY_RELIEF_MAPPING
    _ => ()
  }
  if material.diffuse_transmission > 0.0F {
    bits = bits | STANDARD_MATERIAL_KEY_DIFFUSE_TRANSMISSION
  }
  if material.specular_transmission > 0.0F {
    bits = bits | STANDARD_MATERIAL_KEY_SPECULAR_TRANSMISSION
  }
  if material.clearcoat > 0.0F {
    bits = bits | STANDARD_MATERIAL_KEY_CLEARCOAT
  }
  if material.clearcoat_normal_texture is Some(_) {
    bits = bits | STANDARD_MATERIAL_KEY_CLEARCOAT_NORMAL_MAP
  }
  if material.anisotropy_strength != 0.0F {
    bits = bits | STANDARD_MATERIAL_KEY_ANISOTROPY
  }
  if material.base_color_texture is Some(_) {
    bits = bits | STANDARD_MATERIAL_KEY_BASE_COLOR_TEXTURE
  }
  if material.emissive_texture is Some(_) {
    bits = bits | STANDARD_MATERIAL_KEY_EMISSIVE_TEXTURE
  }
  if material.metallic_roughness_texture is Some(_) {
    bits = bits | STANDARD_MATERIAL_KEY_METALLIC_ROUGHNESS_TEXTURE
  }
  if material.occlusion_texture is Some(_) {
    bits = bits | STANDARD_MATERIAL_KEY_OCCLUSION_TEXTURE
  }
  let depth_bias_bits = (
      material.depth_bias.to_int().to_uint64() <<
      STANDARD_MATERIAL_KEY_DEPTH_BIAS_SHIFT
    ) &
    STANDARD_MATERIAL_KEY_DEPTH_BIAS_MASK
  bits = bits | depth_bias_bits
  StandardMaterialKey::{ bits, }
}

///|
// Bevy source:
// `bevy/crates/bevy_pbr/src/pbr_material.rs::impl Material for StandardMaterial`.
// `reads_view_transmission_texture()` checks only `specular_transmission > 0.0`.
pub fn standard_material_reads_view_transmission_texture(
  material : StandardMaterial,
) -> Bool {
  material.specular_transmission > 0.0F
}

///|
// Bevy source:
// `bevy/crates/bevy_pbr/src/pbr_material.rs::opaque_render_method()`.
// `Auto + diffuse_transmission` forces `Forward` before resolving runtime default.
pub fn standard_material_opaque_render_method(
  material : StandardMaterial,
  default_opaque_renderer_method : OpaqueRendererMethod,
) -> OpaqueRendererMethod {
  let material_opaque_method = match material.opaque_render_method {
    OpaqueRendererMethod::Auto if material.diffuse_transmission > 0.0F =>
      OpaqueRendererMethod::Forward
    opaque_method => opaque_method
  }
  material_opaque_method.resolve_runtime(default_opaque_renderer_method)
}

///|
// Bevy source:
// `bevy/crates/bevy_pbr/src/material.rs` render-phase selection:
// transparent alpha modes first, then transmissive, then opaque/alpha-mask.
pub fn standard_material_render_phase_type(
  material : StandardMaterial,
) -> @material.RenderPhaseType {
  match material.alpha_mode {
    @material.AlphaMode3d::Blend => @material.RenderPhaseType::Transparent
    @material.AlphaMode3d::Premultiplied =>
      @material.RenderPhaseType::Transparent
    @material.AlphaMode3d::Add => @material.RenderPhaseType::Transparent
    @material.AlphaMode3d::Multiply => @material.RenderPhaseType::Transparent
    _ =>
      if standard_material_reads_view_transmission_texture(material) {
        @material.RenderPhaseType::Transmissive
      } else {
        match material.alpha_mode {
          @material.AlphaMode3d::Opaque => @material.RenderPhaseType::Opaque
          @material.AlphaMode3d::AlphaToCoverage =>
            @material.RenderPhaseType::Opaque
          @material.AlphaMode3d::Mask(_) => @material.RenderPhaseType::AlphaMask
          _ => @material.RenderPhaseType::Opaque
        }
      }
  }
}

///|
pub(all) struct StandardMaterialPlugin {
  prepass_enabled : Bool
  debug_flags : @render.RenderDebugFlags
}

///|
pub fn StandardMaterialPlugin::StandardMaterialPlugin() -> StandardMaterialPlugin {
  StandardMaterialPlugin::{
    prepass_enabled: true,
    debug_flags: @render.RenderDebugFlags::RenderDebugFlags(),
  }
}

///|
pub fn StandardMaterialPlugin::with_prepass_enabled(
  self : StandardMaterialPlugin,
  prepass_enabled : Bool,
) -> StandardMaterialPlugin {
  StandardMaterialPlugin::{ ..self, prepass_enabled, }
}

///|
pub fn StandardMaterialPlugin::with_debug_flags(
  self : StandardMaterialPlugin,
  debug_flags : @render.RenderDebugFlags,
) -> StandardMaterialPlugin {
  StandardMaterialPlugin::{ ..self, debug_flags, }
}

///|
pub fn StandardMaterialPlugin::debug_flags(
  self : StandardMaterialPlugin,
) -> @render.RenderDebugFlags {
  self.debug_flags
}

///|
pub struct StandardMaterialPluginPlan {
  prepass_enabled : Bool
  debug_flags : @render.RenderDebugFlags
  shadows_enabled : Bool
  main_world_steps : Array[String]
  post_update_steps : Array[String]
  render_startup_steps : Array[String]
  extract_schedule_steps : Array[String]
}

///|
pub fn StandardMaterialPluginPlan::prepass_enabled(
  self : StandardMaterialPluginPlan,
) -> Bool {
  self.prepass_enabled
}

///|
pub fn StandardMaterialPluginPlan::debug_flags(
  self : StandardMaterialPluginPlan,
) -> @render.RenderDebugFlags {
  self.debug_flags
}

///|
pub fn StandardMaterialPluginPlan::shadows_enabled(
  self : StandardMaterialPluginPlan,
) -> Bool {
  self.shadows_enabled
}

///|
pub fn StandardMaterialPluginPlan::main_world_steps(
  self : StandardMaterialPluginPlan,
) -> Array[String] {
  self.main_world_steps
}

///|
pub fn StandardMaterialPluginPlan::post_update_steps(
  self : StandardMaterialPluginPlan,
) -> Array[String] {
  self.post_update_steps
}

///|
pub fn StandardMaterialPluginPlan::render_startup_steps(
  self : StandardMaterialPluginPlan,
) -> Array[String] {
  self.render_startup_steps
}

///|
pub fn StandardMaterialPluginPlan::extract_schedule_steps(
  self : StandardMaterialPluginPlan,
) -> Array[String] {
  self.extract_schedule_steps
}

///|
pub fn standard_material_plugin_plan(
  plugin : StandardMaterialPlugin,
) -> StandardMaterialPluginPlan {
  StandardMaterialPluginPlan::{
    prepass_enabled: plugin.prepass_enabled,
    debug_flags: plugin.debug_flags,
    shadows_enabled: true,
    main_world_steps: [
      "init_asset<StandardMaterial>", "register_type<MeshMaterial3d<StandardMaterial>>",
      "init_resource<EntitiesNeedingSpecialization<StandardMaterial>>", "add_plugin<ErasedRenderAssetPlugin<MeshMaterial3d<StandardMaterial>>>",
    ],
    post_update_steps: [
      "mark_meshes_as_changed_if_their_materials_changed<StandardMaterial>", "check_entities_needing_specialization<StandardMaterial>",
      "check_light_entities_needing_specialization<StandardMaterial>",
    ],
    render_startup_steps: [
      "add_material_bind_group_allocator<StandardMaterial>",
    ],
    extract_schedule_steps: [
      "extract_mesh_materials<StandardMaterial>", "early_sweep_material_instances<StandardMaterial>",
      "extract_entities_needs_specialization<StandardMaterial>", "sweep_entities_needing_specialization<StandardMaterial>",
    ],
  }
}

///|
pub struct StandardMaterialPluginState {
  prepass_enabled : Bool
  debug_flags : @render.RenderDebugFlags
  plan : StandardMaterialPluginPlan
}

///|
pub fn StandardMaterialPluginState::from_plugin(
  plugin : StandardMaterialPlugin,
) -> StandardMaterialPluginState {
  StandardMaterialPluginState::{
    prepass_enabled: plugin.prepass_enabled,
    debug_flags: plugin.debug_flags,
    plan: standard_material_plugin_plan(plugin),
  }
}

///|
pub fn StandardMaterialPluginState::debug_flags(
  self : StandardMaterialPluginState,
) -> @render.RenderDebugFlags {
  self.debug_flags
}

///|
pub fn StandardMaterialPluginState::plan(
  self : StandardMaterialPluginState,
) -> StandardMaterialPluginPlan {
  self.plan
}

///|
pub let ecs_key_standard_material_plugin_state : @ecs.ResourceKey[
  StandardMaterialPluginState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::StandardMaterialPluginState",
)

///|
pub impl @app.Plugin for StandardMaterialPlugin with fn name(_self) {
  STANDARD_MATERIAL_PLUGIN_NAME
}

///|
pub impl @app.Plugin for StandardMaterialPlugin with fn build(self, app) {
  standard_material_plugin_with(app, self)
}

///|
fn add_standard_material_bind_group_allocator(world : @ecs.World) -> Unit {
  if world.get_resource(ecs_key_material_bind_group_allocators) is None {
    world.insert_resource(
      ecs_key_material_bind_group_allocators,
      MaterialBindGroupAllocators::MaterialBindGroupAllocators(),
    )
  }
  guard world.get_resource_mut(ecs_key_material_bind_group_allocators)
    is Some(allocators) else {
    return
  }
  let bindless_supported = match
    world.get_resource(@render.render_device_resource_key) {
    Some(render_device) => standard_material_bindless_supported(render_device)
    None => false
  }
  allocators.modify(fn(value) {
    ignore(
      value.install_standard_material(
        bindless_supported,
        standard_material_bindless_slot_count(),
      ),
    )
  })
}

///|
pub fn standard_material_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  standard_material_plugin_with(
    app,
    StandardMaterialPlugin::StandardMaterialPlugin(),
  )
}

///|
pub fn standard_material_plugin_with(
  app : @app.App[@ecs.World],
  plugin : StandardMaterialPlugin,
) -> @app.App[@ecs.World] {
  let app = app.insert_world_resource(
    ecs_key_standard_material_plugin_state,
    StandardMaterialPluginState::from_plugin(plugin),
  )
  @render.try_with_render_app(app, fn(sub_app) {
    sub_app.add_systems(
      @render.render_startup_schedule_stage(),
      @app.system(add_standard_material_bind_group_allocator).named(
        "mgstudio_pbr::add_material_bind_group_allocator<StandardMaterial>",
      ),
    )
  })
}

///|
pub fn standard_material_prepass_enabled(world : @ecs.World) -> Bool {
  match world.get_resource(ecs_key_standard_material_plugin_state) {
    Some(state) => state.prepass_enabled
    None => true
  }
}

///|
pub fn pbr_standard_material_add(
  material : StandardMaterial,
) -> @asset.Handle[StandardMaterial] {
  @material.standard_material_add(material)
}

///|
pub fn pbr_standard_material_get(
  handle : @asset.Handle[StandardMaterial],
) -> StandardMaterial? {
  @material.standard_material_get(handle)
}

///|
pub fn pbr_standard_material_set(
  handle : @asset.Handle[StandardMaterial],
  material : StandardMaterial,
) -> Bool {
  @material.standard_material_set(handle, material)
}

///|
pub fn pbr_mesh_material3d_new(
  material : @asset.Handle[StandardMaterial],
) -> @material.MeshMaterial3d {
  @material.MeshMaterial3d::new(material)
}

///|
pub fn pbr_mesh_material3d_with_extended_metadata(
  mesh_material : @material.MeshMaterial3d,
  extended_material : @material.ExtendedMaterialMetadata3d?,
) -> @material.MeshMaterial3d {
  mesh_material.with_extended_material(extended_material)
}

///|
pub fn pbr_mesh_material3d_with_extension_tag(
  mesh_material : @material.MeshMaterial3d,
  extension_tag : Int,
) -> @material.MeshMaterial3d {
  mesh_material.with_extension_tag(extension_tag)
}

///|
pub fn pbr_mesh_material3d_with_extension_vertex_shader_path(
  mesh_material : @material.MeshMaterial3d,
  shader_path : String?,
) -> @material.MeshMaterial3d {
  mesh_material.with_extension_vertex_shader_path(shader_path)
}

///|
pub fn pbr_mesh_material3d_with_extension_fragment_shader_path(
  mesh_material : @material.MeshMaterial3d,
  shader_path : String?,
) -> @material.MeshMaterial3d {
  mesh_material.with_extension_fragment_shader_path(shader_path)
}

///|
pub fn pbr_material_forward_decal_material_ext_default() -> @material.ForwardDecalMaterialExt {
  @material.ForwardDecalMaterialExt::ForwardDecalMaterialExt()
}

///|
pub fn pbr_material_forward_decal_material_ext_new(
  depth_fade_factor : Float,
) -> @material.ForwardDecalMaterialExt {
  @material.ForwardDecalMaterialExt::new(depth_fade_factor)
}

///|
pub fn pbr_default_opaque_renderer_method_forward() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::forward()
}

///|
pub fn pbr_default_opaque_renderer_method_deferred() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::deferred()
}
