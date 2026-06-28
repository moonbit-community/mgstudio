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
// Bevy source: `bevy/crates/bevy_pbr/src/extended_material.rs`.

///|
pub type ExtendedMaterialMetadata3d = @material.ExtendedMaterialMetadata3d

///|
pub type ExtendedMaterialMetadata = ExtendedMaterialMetadata3d

///|
pub type ForwardDecalMaterialExt = @material.ForwardDecalMaterialExt

///|
pub struct MaterialExtensionPipeline {
  use_prepass : Bool
  use_shadows : Bool
}

///|
pub type MaterialExtensionPipeline3d = MaterialExtensionPipeline

///|
pub fn MaterialExtensionPipeline::MaterialExtensionPipeline() -> MaterialExtensionPipeline {
  MaterialExtensionPipeline::{ use_prepass: true, use_shadows: true }
}

///|
pub fn MaterialExtensionPipeline::with_prepass(
  self : MaterialExtensionPipeline,
  use_prepass : Bool,
) -> MaterialExtensionPipeline {
  MaterialExtensionPipeline::{ ..self, use_prepass, }
}

///|
pub fn MaterialExtensionPipeline::with_shadows(
  self : MaterialExtensionPipeline,
  use_shadows : Bool,
) -> MaterialExtensionPipeline {
  MaterialExtensionPipeline::{ ..self, use_shadows, }
}

///|
pub struct MaterialExtensionKey[E] {
  mesh_key : UInt64
  bind_group_data : E
}

///|
pub type MaterialExtensionKey3d[E] = MaterialExtensionKey[E]

///|
pub fn[E] MaterialExtensionKey::new(
  mesh_key : UInt64,
  bind_group_data : E,
) -> MaterialExtensionKey[E] {
  MaterialExtensionKey::{ mesh_key, bind_group_data }
}

///|
pub fn[E] MaterialExtensionKey::mesh_key(
  self : MaterialExtensionKey[E],
) -> UInt64 {
  self.mesh_key
}

///|
pub fn[E] MaterialExtensionKey::bind_group_data(
  self : MaterialExtensionKey[E],
) -> E {
  self.bind_group_data
}

///|
pub(open) trait MaterialExtension {
  fn extension_tag(Self) -> Int
  fn vertex_shader(Self) -> String?
  fn fragment_shader(Self) -> String?
  fn prepass_vertex_shader(Self) -> String?
  fn prepass_fragment_shader(Self) -> String?
  fn deferred_vertex_shader(Self) -> String?
  fn deferred_fragment_shader(Self) -> String?
  fn alpha_mode(Self) -> @material.AlphaMode3d?
  fn opaque_render_method(Self) -> @material.OpaqueRendererMethod?
  fn enable_prepass(Self) -> Bool
  fn enable_shadows(Self) -> Bool
  fn specialize(Self) -> @material.UserSpecializeFn?
  fn bind_group_layout_entries(Self) -> Array[
    @render_resource.BindGroupLayoutEntry,
  ]
  fn bind_group_bindings(Self) -> Array[@material.MaterialExtensionBinding3d]
}

///|
pub fn[T : MaterialExtension] material_extension_metadata_from_extension(
  extension : T,
) -> ExtendedMaterialMetadata3d {
  @material.ExtendedMaterialMetadata3d::ExtendedMaterialMetadata3d()
  .with_extension_tag(extension.extension_tag())
  .with_vertex_shader_path(extension.vertex_shader())
  .with_fragment_shader_path(extension.fragment_shader())
  .with_prepass_vertex_shader_path(extension.prepass_vertex_shader())
  .with_prepass_fragment_shader_path(extension.prepass_fragment_shader())
  .with_deferred_vertex_shader_path(extension.deferred_vertex_shader())
  .with_deferred_fragment_shader_path(extension.deferred_fragment_shader())
  .with_alpha_mode_override(extension.alpha_mode())
  .with_opaque_render_method_override(extension.opaque_render_method())
  .with_disable_shadows(!extension.enable_shadows())
  .with_prepass_enabled(extension.enable_prepass())
  .with_user_specialize(extension.specialize())
  .with_extension_bind_group_layout_entries(
    extension.bind_group_layout_entries(),
  )
  .with_extension_bind_group_bindings(extension.bind_group_bindings())
}

///|
pub type ExtendedMaterial3d[B, E] = ExtendedMaterial[B, E]

///|
pub struct ExtendedMaterial[B, E] {
  base : B
  extension : E
}

///|
pub fn[B : Default, E : Default] ExtendedMaterial::ExtendedMaterial() -> ExtendedMaterial[
  B,
  E,
] {
  ExtendedMaterial::{ base: B::default(), extension: E::default() }
}

///|
pub fn[B, E] ExtendedMaterial::new(
  base : B,
  extension : E,
) -> ExtendedMaterial[B, E] {
  ExtendedMaterial::{ base, extension }
}

///|
pub fn[B, E] ExtendedMaterial::base(self : ExtendedMaterial[B, E]) -> B {
  self.base
}

///|
pub fn[B, E] ExtendedMaterial::extension(self : ExtendedMaterial[B, E]) -> E {
  self.extension
}

///|
pub fn[B, E] ExtendedMaterial::with_base(
  self : ExtendedMaterial[B, E],
  base : B,
) -> ExtendedMaterial[B, E] {
  ExtendedMaterial::{ ..self, base, }
}

///|
pub fn[B, E] ExtendedMaterial::with_extension(
  self : ExtendedMaterial[B, E],
  extension : E,
) -> ExtendedMaterial[B, E] {
  ExtendedMaterial::{ ..self, extension, }
}

///|
pub fn[B, E : MaterialExtension] ExtendedMaterial::metadata(
  self : ExtendedMaterial[B, E],
) -> ExtendedMaterialMetadata3d {
  material_extension_metadata_from_extension(self.extension)
}

///|
pub fn[B, E : MaterialExtension] ExtendedMaterial::material_pipeline_support(
  self : ExtendedMaterial[B, E],
  pipeline : MaterialExtensionPipeline3d,
) -> Bool {
  let metadata = self.metadata()
  let prepass_supported = if metadata.requires_depth_prepass {
    pipeline.use_prepass
  } else {
    true
  }
  let shadow_supported = if metadata.disable_shadows {
    true
  } else {
    pipeline.use_shadows
  }
  prepass_supported && shadow_supported
}

///|
pub type ForwardDecalMaterialExtension3d = ForwardDecalMaterialExtension

///|
pub struct ForwardDecalMaterialExtension {
  ext : ForwardDecalMaterialExt
}

///|
pub fn ForwardDecalMaterialExtension::ForwardDecalMaterialExtension() -> ForwardDecalMaterialExtension {
  ForwardDecalMaterialExtension::{ ext: ForwardDecalMaterialExt() }
}

///|
pub fn ForwardDecalMaterialExtension::new(
  ext : ForwardDecalMaterialExt,
) -> ForwardDecalMaterialExtension {
  ForwardDecalMaterialExtension::{ ext, }
}

///|
pub fn ForwardDecalMaterialExtension::ext(
  self : ForwardDecalMaterialExtension,
) -> ForwardDecalMaterialExt {
  self.ext
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn extension_tag(
  _self,
) {
  1
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn vertex_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn fragment_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn prepass_vertex_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn prepass_fragment_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn deferred_vertex_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn deferred_fragment_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn alpha_mode(
  _self,
) {
  Some(@material.AlphaMode3d::Blend)
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn opaque_render_method(
  _self,
) {
  Some(@material.OpaqueRendererMethod::Forward)
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn enable_prepass(
  _self,
) {
  true
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn enable_shadows(
  _self,
) {
  false
}

///|
fn forward_decal_specialize(
  _pipeline : String,
  descriptor : @material.RenderPipelineDescriptor,
  layout : @material.MaterialMeshVertexLayout,
  _key : @material.ErasedMaterialPipelineKey,
) -> @material.RenderPipelineDescriptor raise @material.SpecializedMeshPipelineError {
  if layout.index() < 0 {
    raise @material.missing_vertex_attribute_error("forward decal mesh layout")
  }
  let vertex_shader_defs = descriptor.vertex.shader_defs.copy()
  vertex_shader_defs.push(@render_resource.ShaderDefVal::Flag("FORWARD_DECAL"))
  let depth_stencil = match descriptor.depth_stencil {
    Some(depth_stencil) =>
      Some(
        @render_resource.DepthStencilState::new(
          depth_stencil.format,
          depth_stencil.depth_write_enabled,
          @wgpu.COMPARE_FUNCTION_ALWAYS,
        )
        .with_bias_constant(depth_stencil.bias_constant)
        .with_bias_slope_scale(depth_stencil.bias_slope_scale)
        .with_bias_clamp(depth_stencil.bias_clamp),
      )
    None => None
  }
  let vertex = @render_resource.VertexState::new(
    descriptor.vertex.shader,
    vertex_shader_defs,
    descriptor.vertex.entry_point,
    descriptor.vertex.buffers,
  )
  let fragment = match descriptor.fragment {
    Some(fragment) => {
      let fragment_shader_defs = fragment.shader_defs.copy()
      fragment_shader_defs.push(
        @render_resource.ShaderDefVal::Flag("FORWARD_DECAL"),
      )
      Some(
        @render_resource.FragmentState::new(
          fragment.shader,
          fragment_shader_defs,
          fragment.entry_point,
          fragment.targets,
        ),
      )
    }
    None => None
  }
  let label = match descriptor.label {
    Some(label) => Some(@pbr_decal.pbr_forward_decal_specialized_label(label))
    None => None
  }
  descriptor
  .with_label(label)
  .with_vertex(vertex)
  .with_fragment(fragment)
  .with_depth_stencil(depth_stencil)
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn specialize(
  _self,
) {
  Some(forward_decal_specialize)
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn bind_group_layout_entries(
  _self,
) {
  []
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn bind_group_bindings(
  _self,
) {
  []
}

///|
pub fn extended_material_metadata_default() -> ExtendedMaterialMetadata3d {
  @material.ExtendedMaterialMetadata3d::ExtendedMaterialMetadata3d()
}

///|
pub fn extended_material_metadata_new(
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::new(extension_tag)
}

///|
pub fn forward_decal_material_ext_default() -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt()
}

///|
pub fn forward_decal_material_ext_new(
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::new(depth_fade_factor)
}

///|
pub fn forward_decal_material_extension_metadata(
  ext : ForwardDecalMaterialExt,
) -> ExtendedMaterialMetadata3d {
  material_extension_metadata_from_extension(
    ForwardDecalMaterialExtension::new(ext),
  )
}

///|
pub fn pbr_extended_material_metadata_default() -> ExtendedMaterialMetadata3d {
  extended_material_metadata_default()
}

///|
pub fn pbr_extended_material_metadata_new(
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  extended_material_metadata_new(extension_tag)
}

///|
pub fn pbr_forward_decal_material_ext_default() -> ForwardDecalMaterialExt {
  forward_decal_material_ext_default()
}

///|
pub fn pbr_forward_decal_material_ext_new(
  depth_fade_factor : Float,
) -> ForwardDecalMaterialExt {
  forward_decal_material_ext_new(depth_fade_factor)
}

///|
pub fn pbr_forward_decal_material_extension_metadata(
  ext : ForwardDecalMaterialExt,
) -> ExtendedMaterialMetadata3d {
  forward_decal_material_extension_metadata(ext)
}
