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
pub fn MaterialExtensionPipeline::default() -> MaterialExtensionPipeline {
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
  extension_tag(Self) -> Int
  vertex_shader(Self) -> String?
  fragment_shader(Self) -> String?
  prepass_vertex_shader(Self) -> String?
  prepass_fragment_shader(Self) -> String?
  deferred_vertex_shader(Self) -> String?
  deferred_fragment_shader(Self) -> String?
  alpha_mode(Self) -> @material.AlphaMode3d?
  opaque_render_method(Self) -> @material.OpaqueRendererMethod?
  enable_prepass(Self) -> Bool
  enable_shadows(Self) -> Bool
}

///|
pub fn[T : MaterialExtension] material_extension_metadata_from_extension(
  extension : T,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::default()
  .with_extension_tag(extension.extension_tag())
  .with_vertex_shader_path(extension.vertex_shader())
  .with_fragment_shader_path(extension.fragment_shader())
  .with_prepass_vertex_shader_path(extension.prepass_vertex_shader())
  .with_prepass_fragment_shader_path(extension.prepass_fragment_shader())
  .with_deferred_vertex_shader_path(extension.deferred_vertex_shader())
  .with_deferred_fragment_shader_path(extension.deferred_fragment_shader())
  .with_alpha_mode_override(extension.alpha_mode())
  .with_opaque_render_method_override(extension.opaque_render_method())
  .with_requires_depth_prepass(extension.enable_prepass())
  .with_requires_deferred_prepass(extension.enable_prepass())
  .with_disable_shadows(!extension.enable_shadows())
}

///|
pub type ExtendedMaterial3d[B, E] = ExtendedMaterial[B, E]

///|
pub struct ExtendedMaterial[B, E] {
  base : B
  extension : E
}

///|
pub fn[B : Default, E : Default] ExtendedMaterial::default() -> ExtendedMaterial[
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
pub fn ForwardDecalMaterialExtension::default() -> ForwardDecalMaterialExtension {
  ForwardDecalMaterialExtension::{ ext: ForwardDecalMaterialExt::default() }
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
pub impl MaterialExtension for ForwardDecalMaterialExtension with extension_tag(
  _self,
) {
  1
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with vertex_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fragment_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with prepass_vertex_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with prepass_fragment_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with deferred_vertex_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with deferred_fragment_shader(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with alpha_mode(
  _self,
) {
  None
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with opaque_render_method(
  _self,
) {
  Some(@material.OpaqueRendererMethod::Forward)
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with enable_prepass(
  _self,
) {
  true
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with enable_shadows(
  _self,
) {
  false
}

///|
pub fn extended_material_metadata_default() -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::default()
}

///|
pub fn extended_material_metadata_new(
  extension_tag : Int,
) -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d::new(extension_tag)
}

///|
pub fn forward_decal_material_ext_default() -> ForwardDecalMaterialExt {
  ForwardDecalMaterialExt::default()
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
