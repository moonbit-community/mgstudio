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
/// Material-facing API boundary aligned with Bevy's `bevy_material` crate.
/// Runtime implementation is owned by this package and consumed by `pbr`.

///|
pub(all) enum AlphaMode3d {
  Opaque
  Mask(Float)
  Blend
  Premultiplied
  AlphaToCoverage
  Add
  Multiply
}

///|
pub type AlphaMode = AlphaMode3d

///|
pub fn AlphaMode3d::default() -> AlphaMode3d {
  AlphaMode3d::Opaque
}

///|
pub impl Default for AlphaMode3d with default() {
  AlphaMode3d::default()
}

///|
pub(all) enum Face3d {
  Front
  Back
}

///|
pub(all) enum ParallaxMappingMethod {
  Occlusion
  Relief(Int)
} derive(Eq, Debug)

///|
pub fn ParallaxMappingMethod::default() -> ParallaxMappingMethod {
  Occlusion
}

///|
pub fn ParallaxMappingMethod::relief_default() -> ParallaxMappingMethod {
  Relief(5)
}

///|
pub fn ParallaxMappingMethod::max_steps(self : ParallaxMappingMethod) -> Int {
  match self {
    Occlusion => 0
    Relief(max_steps) => if max_steps <= 0 { 1 } else { max_steps }
  }
}

///|
/// Opaque render path preference aligned with Bevy's `OpaqueRendererMethod`.
pub(all) enum OpaqueRendererMethod {
  Forward
  Deferred
  Auto
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn OpaqueRendererMethod::default() -> OpaqueRendererMethod {
  OpaqueRendererMethod::Forward
}

///|
pub impl Default for OpaqueRendererMethod with default() {
  OpaqueRendererMethod::default()
}

///|
pub const MATERIAL_VERTEX_SHADER_LABEL : ShaderLabel = "MaterialVertexShader"

///|
pub const MATERIAL_FRAGMENT_SHADER_LABEL : ShaderLabel = "MaterialFragmentShader"

///|
pub const PREPASS_VERTEX_SHADER_LABEL : ShaderLabel = "PrepassVertexShader"

///|
pub const PREPASS_FRAGMENT_SHADER_LABEL : ShaderLabel = "PrepassFragmentShader"

///|
pub const DEFERRED_VERTEX_SHADER_LABEL : ShaderLabel = "DeferredVertexShader"

///|
pub const DEFERRED_FRAGMENT_SHADER_LABEL : ShaderLabel = "DeferredFragmentShader"

///|
pub struct DefaultOpaqueRendererMethod {
  renderer_method : OpaqueRendererMethod
} derive(ToJson, FromJson)

///|
pub fn DefaultOpaqueRendererMethod::default() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{
    renderer_method: OpaqueRendererMethod::Forward,
  }
}

///|
pub impl Default for DefaultOpaqueRendererMethod with default() {
  DefaultOpaqueRendererMethod::default()
}

///|
pub fn DefaultOpaqueRendererMethod::new(
  renderer_method : OpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{ renderer_method, }
}

///|
pub fn DefaultOpaqueRendererMethod::forward() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{
    renderer_method: OpaqueRendererMethod::Forward,
  }
}

///|
pub fn DefaultOpaqueRendererMethod::deferred() -> DefaultOpaqueRendererMethod {
  DefaultOpaqueRendererMethod::{
    renderer_method: OpaqueRendererMethod::Deferred,
  }
}

///|
pub fn DefaultOpaqueRendererMethod::with_method(
  self : DefaultOpaqueRendererMethod,
  renderer_method : OpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  self |> ignore
  DefaultOpaqueRendererMethod::{ renderer_method, }
}

///|
pub fn DefaultOpaqueRendererMethod::set_to_forward(
  self : DefaultOpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  self.with_method(OpaqueRendererMethod::Forward)
}

///|
pub fn DefaultOpaqueRendererMethod::set_to_deferred(
  self : DefaultOpaqueRendererMethod,
) -> DefaultOpaqueRendererMethod {
  self.with_method(OpaqueRendererMethod::Deferred)
}

///|
pub fn DefaultOpaqueRendererMethod::renderer_method(
  self : DefaultOpaqueRendererMethod,
) -> OpaqueRendererMethod {
  self.renderer_method
}

///|
pub fn OpaqueRendererMethod::resolve_runtime(
  self : OpaqueRendererMethod,
  default_renderer_method : OpaqueRendererMethod,
) -> OpaqueRendererMethod {
  match self {
    OpaqueRendererMethod::Auto => default_renderer_method
    _ => self
  }
}

///|
pub struct MaterialProperties {
  render_method : OpaqueRendererMethod
  alpha_mode : AlphaMode3d
  mesh_pipeline_key_bits : ErasedMeshPipelineKey
  depth_bias : Float
  reads_view_transmission_texture : Bool
  render_phase_type : RenderPhaseType
  material_layout : BindGroupLayoutDescriptor?
  draw_functions : Array[(InternedDrawFunctionLabel, DrawFunctionId)]
  shaders : Array[(InternedShaderLabel, String)]
  bindless : Bool
  base_specialize : BaseSpecializeFn?
  prepass_specialize : PrepassSpecializeFn?
  user_specialize : UserSpecializeFn?
  material_key : ErasedMaterialKey
  shadows_enabled : Bool
  prepass_enabled : Bool
}

///|
pub fn MaterialProperties::default() -> MaterialProperties {
  MaterialProperties::{
    render_method: OpaqueRendererMethod::Forward,
    alpha_mode: AlphaMode3d::Opaque,
    mesh_pipeline_key_bits: ErasedMeshPipelineKey::default(),
    depth_bias: 0.0F,
    reads_view_transmission_texture: false,
    render_phase_type: RenderPhaseType::Opaque,
    material_layout: None,
    draw_functions: [],
    shaders: [],
    bindless: false,
    base_specialize: None,
    prepass_specialize: None,
    user_specialize: None,
    material_key: ErasedMaterialKey::default(),
    shadows_enabled: false,
    prepass_enabled: false,
  }
}

///|
pub impl Default for MaterialProperties with default() {
  MaterialProperties::default()
}

///|
pub fn MaterialProperties::get_shader(
  self : MaterialProperties,
  label : ShaderLabel,
) -> String? {
  for shader in self.shaders {
    let (entry_label, entry_shader) = shader
    if entry_label == label {
      return Some(entry_shader)
    }
  }
  None
}

///|
pub fn MaterialProperties::add_shader(
  self : MaterialProperties,
  label : ShaderLabel,
  shader : String,
) -> MaterialProperties {
  let shaders = self.shaders
  shaders.push((label, shader))
  MaterialProperties::{ ..self, shaders, }
}

///|
pub fn MaterialProperties::get_draw_function(
  self : MaterialProperties,
  label : DrawFunctionLabel,
) -> DrawFunctionId? {
  for draw_function in self.draw_functions {
    let (entry_label, entry_draw_function) = draw_function
    if entry_label == label {
      return Some(entry_draw_function)
    }
  }
  None
}

///|
pub fn MaterialProperties::add_draw_function(
  self : MaterialProperties,
  label : DrawFunctionLabel,
  draw_function : DrawFunctionId,
) -> MaterialProperties {
  let draw_functions = self.draw_functions
  draw_functions.push((label, draw_function))
  MaterialProperties::{ ..self, draw_functions, }
}

///|
pub fn MaterialProperties::with_render_method(
  self : MaterialProperties,
  render_method : OpaqueRendererMethod,
) -> MaterialProperties {
  MaterialProperties::{ ..self, render_method, }
}

///|
pub fn MaterialProperties::with_alpha_mode(
  self : MaterialProperties,
  alpha_mode : AlphaMode3d,
) -> MaterialProperties {
  MaterialProperties::{ ..self, alpha_mode, }
}

///|
pub fn MaterialProperties::with_mesh_pipeline_key_bits(
  self : MaterialProperties,
  mesh_pipeline_key_bits : ErasedMeshPipelineKey,
) -> MaterialProperties {
  MaterialProperties::{ ..self, mesh_pipeline_key_bits, }
}

///|
pub fn MaterialProperties::with_depth_bias(
  self : MaterialProperties,
  depth_bias : Float,
) -> MaterialProperties {
  MaterialProperties::{ ..self, depth_bias, }
}

///|
pub fn MaterialProperties::with_reads_view_transmission_texture(
  self : MaterialProperties,
  reads_view_transmission_texture : Bool,
) -> MaterialProperties {
  MaterialProperties::{ ..self, reads_view_transmission_texture, }
}

///|
pub fn MaterialProperties::with_render_phase_type(
  self : MaterialProperties,
  render_phase_type : RenderPhaseType,
) -> MaterialProperties {
  MaterialProperties::{ ..self, render_phase_type, }
}

///|
pub fn MaterialProperties::with_material_layout(
  self : MaterialProperties,
  material_layout : BindGroupLayoutDescriptor?,
) -> MaterialProperties {
  MaterialProperties::{ ..self, material_layout, }
}

///|
pub fn MaterialProperties::with_bindless(
  self : MaterialProperties,
  bindless : Bool,
) -> MaterialProperties {
  MaterialProperties::{ ..self, bindless, }
}

///|
pub fn MaterialProperties::with_material_key(
  self : MaterialProperties,
  material_key : ErasedMaterialKey,
) -> MaterialProperties {
  MaterialProperties::{ ..self, material_key, }
}

///|
pub fn MaterialProperties::with_base_specialize(
  self : MaterialProperties,
  base_specialize : BaseSpecializeFn?,
) -> MaterialProperties {
  MaterialProperties::{ ..self, base_specialize, }
}

///|
pub fn MaterialProperties::with_prepass_specialize(
  self : MaterialProperties,
  prepass_specialize : PrepassSpecializeFn?,
) -> MaterialProperties {
  MaterialProperties::{ ..self, prepass_specialize, }
}

///|
pub fn MaterialProperties::with_user_specialize(
  self : MaterialProperties,
  user_specialize : UserSpecializeFn?,
) -> MaterialProperties {
  MaterialProperties::{ ..self, user_specialize, }
}

///|
pub fn MaterialProperties::with_shadows_enabled(
  self : MaterialProperties,
  shadows_enabled : Bool,
) -> MaterialProperties {
  MaterialProperties::{ ..self, shadows_enabled, }
}

///|
pub fn MaterialProperties::with_prepass_enabled(
  self : MaterialProperties,
  prepass_enabled : Bool,
) -> MaterialProperties {
  MaterialProperties::{ ..self, prepass_enabled, }
}

///|
pub struct StandardMaterial {
  base_color : @sprite.Color
  base_color_texture : @asset.Handle[@asset.Image]?
  uv_transform : @transform.Affine2
  normal_map_texture : @asset.Handle[@asset.Image]?
  flip_normal_map_y : Bool
  depth_map : @asset.Handle[@asset.Image]?
  parallax_depth_scale : Float
  max_parallax_layer_count : Float
  parallax_mapping_method : ParallaxMappingMethod
  clearcoat : Float
  clearcoat_perceptual_roughness : Float
  clearcoat_texture : @asset.Handle[@asset.Image]?
  clearcoat_roughness_texture : @asset.Handle[@asset.Image]?
  clearcoat_normal_texture : @asset.Handle[@asset.Image]?
  anisotropy_strength : Float
  anisotropy_rotation : Float
  anisotropy_texture : @asset.Handle[@asset.Image]?
  emissive : @sprite.Color
  emissive_exposure_weight : Float
  emissive_texture : @asset.Handle[@asset.Image]?
  metallic : Float
  metallic_roughness_texture : @asset.Handle[@asset.Image]?
  perceptual_roughness : Float
  reflectance : Float
  diffuse_transmission : Float
  specular_transmission : Float
  thickness : Float
  ior : Float
  attenuation_color : @sprite.Color
  attenuation_distance : Float
  specular_tint : @sprite.Color
  specular_tint_texture : @asset.Handle[@asset.Image]?
  occlusion_texture : @asset.Handle[@asset.Image]?
  alpha_mode : AlphaMode3d
  depth_bias : Float
  fog_enabled : Bool
  lightmap_exposure : Float
  deferred_lighting_pass_id : Int
  opaque_render_method : OpaqueRendererMethod
  unlit : Bool
  cull_mode : Face3d?
}

///|
pub(open) trait IntoStandardMaterialAsset {
  into_standard_material_asset(Self) -> StandardMaterial
}

///|
pub fn StandardMaterial::default() -> StandardMaterial {
  StandardMaterial::{
    base_color: @sprite.Color::white(),
    base_color_texture: None,
    uv_transform: @transform.Affine2::identity(),
    normal_map_texture: None,
    flip_normal_map_y: false,
    depth_map: None,
    parallax_depth_scale: 0.1F,
    max_parallax_layer_count: 16.0F,
    parallax_mapping_method: ParallaxMappingMethod::Occlusion,
    clearcoat: 0.0F,
    clearcoat_perceptual_roughness: 0.5F,
    clearcoat_texture: None,
    clearcoat_roughness_texture: None,
    clearcoat_normal_texture: None,
    anisotropy_strength: 0.0F,
    anisotropy_rotation: 0.0F,
    anisotropy_texture: None,
    emissive: @sprite.Color::new(0.0F, 0.0F, 0.0F, 1.0F),
    emissive_exposure_weight: 0.0F,
    emissive_texture: None,
    metallic: 0.0F,
    metallic_roughness_texture: None,
    perceptual_roughness: 0.5F,
    reflectance: 0.5F,
    diffuse_transmission: 0.0F,
    specular_transmission: 0.0F,
    thickness: 0.0F,
    ior: 1.5F,
    attenuation_color: @sprite.Color::white(),
    attenuation_distance: 1.0F / 0.0F,
    specular_tint: @sprite.Color::white(),
    specular_tint_texture: None,
    occlusion_texture: None,
    alpha_mode: AlphaMode3d::Opaque,
    depth_bias: 0.0F,
    fog_enabled: true,
    lightmap_exposure: 1.0F,
    deferred_lighting_pass_id: 1,
    opaque_render_method: OpaqueRendererMethod::Auto,
    unlit: false,
    cull_mode: Some(Face3d::Back),
  }
}

///|
pub fn StandardMaterial::from_color(color : @sprite.Color) -> StandardMaterial {
  let alpha_mode = if color.a < 1.0F {
    AlphaMode3d::Blend
  } else {
    AlphaMode3d::Opaque
  }
  let default_value = StandardMaterial::default()
  StandardMaterial::{
    base_color: color,
    base_color_texture: default_value.base_color_texture,
    uv_transform: default_value.uv_transform,
    normal_map_texture: default_value.normal_map_texture,
    flip_normal_map_y: default_value.flip_normal_map_y,
    depth_map: default_value.depth_map,
    parallax_depth_scale: default_value.parallax_depth_scale,
    max_parallax_layer_count: default_value.max_parallax_layer_count,
    parallax_mapping_method: default_value.parallax_mapping_method,
    clearcoat: default_value.clearcoat,
    clearcoat_perceptual_roughness: default_value.clearcoat_perceptual_roughness,
    clearcoat_texture: default_value.clearcoat_texture,
    clearcoat_roughness_texture: default_value.clearcoat_roughness_texture,
    clearcoat_normal_texture: default_value.clearcoat_normal_texture,
    anisotropy_strength: default_value.anisotropy_strength,
    anisotropy_rotation: default_value.anisotropy_rotation,
    anisotropy_texture: default_value.anisotropy_texture,
    emissive: default_value.emissive,
    emissive_exposure_weight: default_value.emissive_exposure_weight,
    emissive_texture: default_value.emissive_texture,
    metallic: default_value.metallic,
    metallic_roughness_texture: default_value.metallic_roughness_texture,
    perceptual_roughness: default_value.perceptual_roughness,
    reflectance: default_value.reflectance,
    diffuse_transmission: default_value.diffuse_transmission,
    specular_transmission: default_value.specular_transmission,
    thickness: default_value.thickness,
    ior: default_value.ior,
    attenuation_color: default_value.attenuation_color,
    attenuation_distance: default_value.attenuation_distance,
    specular_tint: default_value.specular_tint,
    specular_tint_texture: default_value.specular_tint_texture,
    occlusion_texture: default_value.occlusion_texture,
    alpha_mode,
    depth_bias: default_value.depth_bias,
    fog_enabled: default_value.fog_enabled,
    lightmap_exposure: default_value.lightmap_exposure,
    deferred_lighting_pass_id: default_value.deferred_lighting_pass_id,
    opaque_render_method: default_value.opaque_render_method,
    unlit: default_value.unlit,
    cull_mode: default_value.cull_mode,
  }
}

///|
fn standard_material_flip_horizontal_uv_transform() -> @transform.Affine2 {
  @transform.Affine2::from_scale_translation(
    @math.Vec2::new(-1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
  )
}

///|
fn standard_material_flip_vertical_uv_transform() -> @transform.Affine2 {
  @transform.Affine2::from_scale_translation(
    @math.Vec2::new(1.0F, -1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  )
}

///|
pub fn StandardMaterial::flip(
  self : StandardMaterial,
  horizontal : Bool,
  vertical : Bool,
) -> StandardMaterial {
  let mut uv_transform = self.uv_transform
  if horizontal {
    // Keep Bevy's left-multiplication order for composed UV transforms.
    uv_transform = standard_material_flip_horizontal_uv_transform().mul(
      uv_transform,
    )
  }
  if vertical {
    uv_transform = standard_material_flip_vertical_uv_transform().mul(
      uv_transform,
    )
  }
  StandardMaterial::{ ..self, uv_transform, }
}

///|
pub fn StandardMaterial::flipped(
  self : StandardMaterial,
  horizontal : Bool,
  vertical : Bool,
) -> StandardMaterial {
  self.flip(horizontal, vertical)
}

///|
pub impl IntoStandardMaterialAsset for @sprite.Color with into_standard_material_asset(
  self,
) {
  StandardMaterial::from_color(self)
}

///|
pub impl IntoStandardMaterialAsset for @asset.Handle[@asset.Image] with into_standard_material_asset(
  self,
) {
  StandardMaterial::default().with_base_color_texture(Some(self))
}

///|
pub fn[S : IntoStandardMaterialAsset] add(
  assets : @asset.Assets[StandardMaterial],
  value : S,
) -> @asset.Handle[StandardMaterial] {
  assets.add(value.into_standard_material_asset())
}

///|
pub fn StandardMaterial::with_base_color(
  self : StandardMaterial,
  color : @sprite.Color,
) -> StandardMaterial {
  StandardMaterial::{ ..self, base_color: color }
}

///|
pub fn StandardMaterial::with_alpha_mode(
  self : StandardMaterial,
  alpha_mode : AlphaMode3d,
) -> StandardMaterial {
  StandardMaterial::{ ..self, alpha_mode, }
}

///|
pub fn StandardMaterial::with_depth_bias(
  self : StandardMaterial,
  depth_bias : Float,
) -> StandardMaterial {
  StandardMaterial::{ ..self, depth_bias, }
}

///|
pub fn StandardMaterial::with_opaque_render_method(
  self : StandardMaterial,
  opaque_render_method : OpaqueRendererMethod,
) -> StandardMaterial {
  StandardMaterial::{ ..self, opaque_render_method, }
}

///|
pub fn StandardMaterial::with_base_color_texture(
  self : StandardMaterial,
  base_color_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, base_color_texture, }
}

///|
pub fn StandardMaterial::with_uv_transform(
  self : StandardMaterial,
  uv_transform : @transform.Affine2,
) -> StandardMaterial {
  StandardMaterial::{ ..self, uv_transform, }
}

///|
pub fn StandardMaterial::with_normal_map_texture(
  self : StandardMaterial,
  normal_map_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, normal_map_texture, }
}

///|
pub fn StandardMaterial::with_flip_normal_map_y(
  self : StandardMaterial,
  flip_normal_map_y : Bool,
) -> StandardMaterial {
  StandardMaterial::{ ..self, flip_normal_map_y, }
}

///|
pub fn StandardMaterial::with_depth_map(
  self : StandardMaterial,
  depth_map : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, depth_map, }
}

///|
pub fn StandardMaterial::with_parallax_depth_scale(
  self : StandardMaterial,
  parallax_depth_scale : Float,
) -> StandardMaterial {
  let safe_parallax_depth_scale = if parallax_depth_scale < 0.0F {
    0.0F
  } else {
    parallax_depth_scale
  }
  StandardMaterial::{ ..self, parallax_depth_scale: safe_parallax_depth_scale }
}

///|
pub fn StandardMaterial::with_max_parallax_layer_count(
  self : StandardMaterial,
  max_parallax_layer_count : Float,
) -> StandardMaterial {
  let safe_max_parallax_layer_count = if max_parallax_layer_count < 0.0F {
    0.0F
  } else {
    max_parallax_layer_count
  }
  StandardMaterial::{
    ..self,
    max_parallax_layer_count: safe_max_parallax_layer_count,
  }
}

///|
pub fn StandardMaterial::with_parallax_mapping_method(
  self : StandardMaterial,
  parallax_mapping_method : ParallaxMappingMethod,
) -> StandardMaterial {
  StandardMaterial::{ ..self, parallax_mapping_method, }
}

///|
pub fn StandardMaterial::with_clearcoat(
  self : StandardMaterial,
  clearcoat : Float,
) -> StandardMaterial {
  let safe_clearcoat = if clearcoat < 0.0F {
    0.0F
  } else if clearcoat > 1.0F {
    1.0F
  } else {
    clearcoat
  }
  StandardMaterial::{ ..self, clearcoat: safe_clearcoat }
}

///|
pub fn StandardMaterial::with_clearcoat_perceptual_roughness(
  self : StandardMaterial,
  clearcoat_perceptual_roughness : Float,
) -> StandardMaterial {
  let safe_clearcoat_perceptual_roughness = if clearcoat_perceptual_roughness <
    0.0F {
    0.0F
  } else if clearcoat_perceptual_roughness > 1.0F {
    1.0F
  } else {
    clearcoat_perceptual_roughness
  }
  StandardMaterial::{
    ..self,
    clearcoat_perceptual_roughness: safe_clearcoat_perceptual_roughness,
  }
}

///|
pub fn StandardMaterial::with_clearcoat_texture(
  self : StandardMaterial,
  clearcoat_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, clearcoat_texture, }
}

///|
pub fn StandardMaterial::with_clearcoat_roughness_texture(
  self : StandardMaterial,
  clearcoat_roughness_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, clearcoat_roughness_texture, }
}

///|
pub fn StandardMaterial::with_clearcoat_normal_texture(
  self : StandardMaterial,
  clearcoat_normal_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, clearcoat_normal_texture, }
}

///|
pub fn StandardMaterial::with_anisotropy_strength(
  self : StandardMaterial,
  anisotropy_strength : Float,
) -> StandardMaterial {
  let safe_anisotropy_strength = if anisotropy_strength < 0.0F {
    0.0F
  } else if anisotropy_strength > 1.0F {
    1.0F
  } else {
    anisotropy_strength
  }
  StandardMaterial::{ ..self, anisotropy_strength: safe_anisotropy_strength }
}

///|
pub fn StandardMaterial::with_anisotropy_rotation(
  self : StandardMaterial,
  anisotropy_rotation : Float,
) -> StandardMaterial {
  StandardMaterial::{ ..self, anisotropy_rotation, }
}

///|
pub fn StandardMaterial::with_anisotropy_texture(
  self : StandardMaterial,
  anisotropy_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, anisotropy_texture, }
}

///|
pub fn StandardMaterial::with_emissive(
  self : StandardMaterial,
  emissive : @sprite.Color,
) -> StandardMaterial {
  StandardMaterial::{ ..self, emissive, }
}

///|
pub fn StandardMaterial::with_emissive_texture(
  self : StandardMaterial,
  emissive_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, emissive_texture, }
}

///|
pub fn StandardMaterial::with_metallic(
  self : StandardMaterial,
  metallic : Float,
) -> StandardMaterial {
  let safe_metallic = if metallic < 0.0F {
    0.0F
  } else if metallic > 1.0F {
    1.0F
  } else {
    metallic
  }
  StandardMaterial::{ ..self, metallic: safe_metallic }
}

///|
pub fn StandardMaterial::with_perceptual_roughness(
  self : StandardMaterial,
  perceptual_roughness : Float,
) -> StandardMaterial {
  let safe_perceptual_roughness = if perceptual_roughness < 0.0F {
    0.0F
  } else if perceptual_roughness > 1.0F {
    1.0F
  } else {
    perceptual_roughness
  }
  StandardMaterial::{ ..self, perceptual_roughness: safe_perceptual_roughness }
}

///|
pub fn StandardMaterial::with_reflectance(
  self : StandardMaterial,
  reflectance : Float,
) -> StandardMaterial {
  let safe_reflectance = if reflectance < 0.0F { 0.0F } else { reflectance }
  StandardMaterial::{ ..self, reflectance: safe_reflectance }
}

///|
pub fn StandardMaterial::with_diffuse_transmission(
  self : StandardMaterial,
  diffuse_transmission : Float,
) -> StandardMaterial {
  let safe_diffuse_transmission = if diffuse_transmission < 0.0F {
    0.0F
  } else if diffuse_transmission > 1.0F {
    1.0F
  } else {
    diffuse_transmission
  }
  StandardMaterial::{ ..self, diffuse_transmission: safe_diffuse_transmission }
}

///|
pub fn StandardMaterial::with_specular_transmission(
  self : StandardMaterial,
  specular_transmission : Float,
) -> StandardMaterial {
  let safe_specular_transmission = if specular_transmission < 0.0F {
    0.0F
  } else if specular_transmission > 1.0F {
    1.0F
  } else {
    specular_transmission
  }
  StandardMaterial::{
    ..self,
    specular_transmission: safe_specular_transmission,
  }
}

///|
pub fn StandardMaterial::with_thickness(
  self : StandardMaterial,
  thickness : Float,
) -> StandardMaterial {
  let safe_thickness = if thickness < 0.0F { 0.0F } else { thickness }
  StandardMaterial::{ ..self, thickness: safe_thickness }
}

///|
pub fn StandardMaterial::with_ior(
  self : StandardMaterial,
  ior : Float,
) -> StandardMaterial {
  let safe_ior = if ior < 1.0F { 1.0F } else { ior }
  StandardMaterial::{ ..self, ior: safe_ior }
}

///|
pub fn StandardMaterial::with_specular_tint(
  self : StandardMaterial,
  specular_tint : @sprite.Color,
) -> StandardMaterial {
  StandardMaterial::{ ..self, specular_tint, }
}

///|
pub fn StandardMaterial::with_specular_tint_texture(
  self : StandardMaterial,
  specular_tint_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, specular_tint_texture, }
}

///|
pub fn StandardMaterial::with_metallic_roughness_texture(
  self : StandardMaterial,
  metallic_roughness_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, metallic_roughness_texture, }
}

///|
pub fn StandardMaterial::with_occlusion_texture(
  self : StandardMaterial,
  occlusion_texture : @asset.Handle[@asset.Image]?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, occlusion_texture, }
}

///|
pub fn StandardMaterial::with_unlit(
  self : StandardMaterial,
  unlit : Bool,
) -> StandardMaterial {
  StandardMaterial::{ ..self, unlit, }
}

///|
pub fn StandardMaterial::with_cull_mode(
  self : StandardMaterial,
  cull_mode : Face3d?,
) -> StandardMaterial {
  StandardMaterial::{ ..self, cull_mode, }
}

///|
pub fn StandardMaterial::with_double_sided(
  self : StandardMaterial,
  double_sided : Bool,
) -> StandardMaterial {
  let cull_mode : Face3d? = if double_sided { None } else { Some(Face3d::Back) }
  StandardMaterial::{ ..self, cull_mode, }
}

///|
fn material_current_world_or_abort() -> @ecs.World {
  match @app.current_world() {
    Some(world) => @render.render_source_world(world)
    None =>
      abort(
        "material asset helpers require an active app world; use the world-owned Assets<T> resources directly outside scheduled systems",
      )
  }
}

///|
fn[T] material_asset_store_or_abort() -> @asset.Assets[T] {
  let world = material_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) => assets
    None =>
      abort(
        "material asset resource is missing; Render3dPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
fn[T] material_asset_store_mut_or_abort() -> @ecs.ResourceMut[@asset.Assets[T]] {
  let world = material_current_world_or_abort()
  let key : @ecs.ResourceKey[@asset.Assets[T]] = @asset.assets_resource_key()
  match (try! world.get_resource_mut(key)) {
    Some(assets) => assets
    None =>
      abort(
        "material asset resource is missing; Render3dPlugin must initialize the required Assets<T> resource before use",
      )
  }
}

///|
pub fn standard_material_add(
  material : StandardMaterial,
) -> @asset.Handle[StandardMaterial] {
  let assets = material_asset_store_mut_or_abort()
  assets.set_changed()
  assets.peek().add(material)
}

///|
pub fn standard_material_get(
  handle : @asset.Handle[StandardMaterial],
) -> StandardMaterial? {
  material_asset_store_or_abort().get(handle)
}

///|
pub fn standard_material_set(
  handle : @asset.Handle[StandardMaterial],
  material : StandardMaterial,
) -> Bool {
  let assets = material_asset_store_mut_or_abort()
  assets.set_changed()
  assets.peek().set(handle, material)
}

///|
/// Metadata-only hook aligned with Bevy's `ExtendedMaterial`.
///
/// Runtime can consume this metadata to select an alternative mesh3d shader
/// path while keeping the same draw contract.
pub struct ExtendedMaterialMetadata3d {
  extension_tag : Int
  vertex_shader_path : String?
  fragment_shader_path : String?
  prepass_vertex_shader_path : String?
  prepass_fragment_shader_path : String?
  deferred_vertex_shader_path : String?
  deferred_fragment_shader_path : String?
  alpha_mode_override : AlphaMode3d?
  opaque_render_method_override : OpaqueRendererMethod?
  requires_depth_prepass : Bool
  requires_deferred_prepass : Bool
  disable_shadows : Bool
}

///|
pub fn ExtendedMaterialMetadata3d::default() -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    extension_tag: 0,
    vertex_shader_path: None,
    fragment_shader_path: None,
    prepass_vertex_shader_path: None,
    prepass_fragment_shader_path: None,
    deferred_vertex_shader_path: None,
    deferred_fragment_shader_path: None,
    alpha_mode_override: None,
    opaque_render_method_override: None,
    requires_depth_prepass: false,
    requires_deferred_prepass: false,
    disable_shadows: false,
  }
}

///|
pub fn ExtendedMaterialMetadata3d::new(
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::default().with_extension_tag(extension_tag)
}

///|
pub fn ExtendedMaterialMetadata3d::with_extension_tag(
  self : ExtendedMaterialMetadata3d,
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  let safe_tag = if extension_tag < 0 { 0 } else { extension_tag }
  ExtendedMaterialMetadata3d::{ ..self, extension_tag: safe_tag }
}

///|
fn normalize_material_shader_path(shader_path : String?) -> String? {
  match shader_path {
    Some(path) => if path == "" { None } else { Some(path) }
    None => None
  }
}

///|
pub fn ExtendedMaterialMetadata3d::with_vertex_shader_path(
  self : ExtendedMaterialMetadata3d,
  shader_path : String?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    ..self,
    vertex_shader_path: normalize_material_shader_path(shader_path),
  }
}

///|
pub fn ExtendedMaterialMetadata3d::with_fragment_shader_path(
  self : ExtendedMaterialMetadata3d,
  shader_path : String?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    ..self,
    fragment_shader_path: normalize_material_shader_path(shader_path),
  }
}

///|
pub fn ExtendedMaterialMetadata3d::with_prepass_vertex_shader_path(
  self : ExtendedMaterialMetadata3d,
  shader_path : String?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    ..self,
    prepass_vertex_shader_path: normalize_material_shader_path(shader_path),
  }
}

///|
pub fn ExtendedMaterialMetadata3d::with_prepass_fragment_shader_path(
  self : ExtendedMaterialMetadata3d,
  shader_path : String?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    ..self,
    prepass_fragment_shader_path: normalize_material_shader_path(shader_path),
  }
}

///|
pub fn ExtendedMaterialMetadata3d::with_deferred_vertex_shader_path(
  self : ExtendedMaterialMetadata3d,
  shader_path : String?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    ..self,
    deferred_vertex_shader_path: normalize_material_shader_path(shader_path),
  }
}

///|
pub fn ExtendedMaterialMetadata3d::with_deferred_fragment_shader_path(
  self : ExtendedMaterialMetadata3d,
  shader_path : String?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{
    ..self,
    deferred_fragment_shader_path: normalize_material_shader_path(shader_path),
  }
}

///|
pub fn ExtendedMaterialMetadata3d::with_alpha_mode_override(
  self : ExtendedMaterialMetadata3d,
  alpha_mode_override : AlphaMode3d?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, alpha_mode_override, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_opaque_render_method_override(
  self : ExtendedMaterialMetadata3d,
  opaque_render_method_override : OpaqueRendererMethod?,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, opaque_render_method_override, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_requires_depth_prepass(
  self : ExtendedMaterialMetadata3d,
  requires_depth_prepass : Bool,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, requires_depth_prepass, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_requires_deferred_prepass(
  self : ExtendedMaterialMetadata3d,
  requires_deferred_prepass : Bool,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, requires_deferred_prepass, }
}

///|
pub fn ExtendedMaterialMetadata3d::with_disable_shadows(
  self : ExtendedMaterialMetadata3d,
  disable_shadows : Bool,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::{ ..self, disable_shadows, }
}

///|
pub struct MeshMaterial3d {
  material : @asset.Handle[StandardMaterial]
  extended_material : ExtendedMaterialMetadata3d?
}

///|
pub fn MeshMaterial3d::new(
  material : @asset.Handle[StandardMaterial],
) -> MeshMaterial3d {
  MeshMaterial3d::{ material, extended_material: None }
}

///|
pub impl ToJson for MeshMaterial3d with to_json(self) {
  self.material.id().to_json()
}

///|
pub impl @json.FromJson for MeshMaterial3d with from_json(json, path) {
  let material_id : Int = @json.from_json(json, path~)
  MeshMaterial3d::new(@asset.Handle::new(material_id))
}

///|
pub fn MeshMaterial3d::with_extended_material(
  self : MeshMaterial3d,
  extended_material : ExtendedMaterialMetadata3d?,
) -> MeshMaterial3d {
  MeshMaterial3d::{ ..self, extended_material, }
}

///|
pub fn MeshMaterial3d::with_extension_tag(
  self : MeshMaterial3d,
  extension_tag : Int,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(extension.with_extension_tag(extension_tag)),
  }
}

///|
pub fn MeshMaterial3d::with_extension_vertex_shader_path(
  self : MeshMaterial3d,
  shader_path : String?,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(extension.with_vertex_shader_path(shader_path)),
  }
}

///|
pub fn MeshMaterial3d::with_extension_fragment_shader_path(
  self : MeshMaterial3d,
  shader_path : String?,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(extension.with_fragment_shader_path(shader_path)),
  }
}

///|
pub fn MeshMaterial3d::with_extension_alpha_mode(
  self : MeshMaterial3d,
  alpha_mode_override : AlphaMode3d?,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_alpha_mode_override(alpha_mode_override),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_opaque_renderer_method(
  self : MeshMaterial3d,
  opaque_render_method_override : OpaqueRendererMethod?,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_opaque_render_method_override(
        opaque_render_method_override,
      ),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_requires_depth_prepass(
  self : MeshMaterial3d,
  requires_depth_prepass : Bool,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_requires_depth_prepass(requires_depth_prepass),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_requires_deferred_prepass(
  self : MeshMaterial3d,
  requires_deferred_prepass : Bool,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(
      extension.with_requires_deferred_prepass(requires_deferred_prepass),
    ),
  }
}

///|
pub fn MeshMaterial3d::with_extension_disable_shadows(
  self : MeshMaterial3d,
  disable_shadows : Bool,
) -> MeshMaterial3d {
  let extension = match self.extended_material {
    Some(value) => value
    None => ExtendedMaterialMetadata3d::default()
  }
  MeshMaterial3d::{
    ..self,
    extended_material: Some(extension.with_disable_shadows(disable_shadows)),
  }
}

///|
fn forward_decal_depth_fade_factor_safe(depth_fade_factor : Float) -> Float {
  if depth_fade_factor < 0.001F {
    0.001F
  } else {
    depth_fade_factor
  }
}

///|
/// Forward decal material-extension parameters aligned with Bevy's
/// `ForwardDecalMaterialExt`.
pub struct ForwardDecalMaterialExt {
  depth_fade_factor : Float
} derive(ToJson, FromJson)

///|
pub fn ForwardDecalMaterialExt::default() -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::{ depth_fade_factor: 8.0F }
}

///|
pub fn ForwardDecalMaterialExt::new(
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::{
    depth_fade_factor: forward_decal_depth_fade_factor_safe(depth_fade_factor),
  }
}

///|
pub fn ForwardDecalMaterialExt::with_depth_fade_factor(
  self : ForwardDecalMaterialExt,
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExt {
  self |> ignore
  ForwardDecalMaterialExt::{
    depth_fade_factor: forward_decal_depth_fade_factor_safe(depth_fade_factor),
  }
}

///|
pub let ecs_key_mesh_material3d : @ecs.ComponentKey[MeshMaterial3d] = @ecs.register_component(
  debug_name="render3d.mesh_material3d",
)

///|
pub let ecs_key_forward_decal_material_ext : @ecs.ComponentKey[
  ForwardDecalMaterialExt,
] = @ecs.register_component(debug_name="render3d.forward_decal_material_ext")

///|
pub let ecs_key_default_opaque_renderer_method : @ecs.ResourceKey[
  DefaultOpaqueRendererMethod,
] = @ecs.register_resource(debug_name="render3d.default_opaque_renderer_method")

///|
pub impl @ecs.Component for MeshMaterial3d with component() {
  ecs_key_mesh_material3d
}

///|
pub impl @ecs.Component for ForwardDecalMaterialExt with component() {
  ecs_key_forward_decal_material_ext
}

///|
pub fn get_default_opaque_renderer_method_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DefaultOpaqueRendererMethod] {
  world.resource(ecs_key_default_opaque_renderer_method)
}
