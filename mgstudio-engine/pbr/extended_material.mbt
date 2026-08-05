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
  { use_prepass: true, use_shadows: true }
}

///|
pub fn MaterialExtensionPipeline::with_prepass(
  self : MaterialExtensionPipeline,
  use_prepass : Bool,
) -> MaterialExtensionPipeline {
  { ..self, use_prepass, }
}

///|
pub fn MaterialExtensionPipeline::with_shadows(
  self : MaterialExtensionPipeline,
  use_shadows : Bool,
) -> MaterialExtensionPipeline {
  { ..self, use_shadows, }
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
  { mesh_key, bind_group_data }
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
pub(open) trait StandardMaterialExtension {
  fn extended_material_asset_debug_name() -> String
  fn extended_material_asset_keys() -> @asset.AssetResourceKeys[
    ExtendedMaterial[StandardMaterial, Self],
  ]
  fn extended_material_keys() -> MaterialKeys[
    ExtendedMaterial[StandardMaterial, Self],
  ]
  fn vertex_shader_ref() -> String?
  fn fragment_shader_ref() -> String?
  fn prepass_vertex_shader_ref() -> String?
  fn prepass_fragment_shader_ref() -> String?
  fn deferred_vertex_shader_ref() -> String?
  fn deferred_fragment_shader_ref() -> String?
  fn meshlet_fragment_shader_ref() -> String?
  fn meshlet_prepass_fragment_shader_ref() -> String?
  fn meshlet_deferred_fragment_shader_ref() -> String?
  fn enable_prepass_ref() -> Bool
  fn enable_shadows_ref() -> Bool
  fn specialize_ref() -> @material.UserSpecializeFn?
}

///|
pub fn standard_material_extension_default_vertex_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_fragment_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_prepass_vertex_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_prepass_fragment_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_deferred_vertex_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_deferred_fragment_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_meshlet_fragment_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_meshlet_prepass_fragment_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_meshlet_deferred_fragment_shader_ref() -> String? {
  None
}

///|
pub fn standard_material_extension_default_enable_prepass_ref() -> Bool {
  true
}

///|
pub fn standard_material_extension_default_enable_shadows_ref() -> Bool {
  true
}

///|
pub fn standard_material_extension_default_specialize_ref() -> @material.UserSpecializeFn? {
  None
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_asset_debug_name(
  _witness : E?,
) -> String {
  E::extended_material_asset_debug_name()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_vertex_shader_ref(
  _witness : E?,
) -> String? {
  E::vertex_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_fragment_shader_ref(
  _witness : E?,
) -> String? {
  E::fragment_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_prepass_vertex_shader_ref(
  _witness : E?,
) -> String? {
  E::prepass_vertex_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_prepass_fragment_shader_ref(
  _witness : E?,
) -> String? {
  E::prepass_fragment_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_deferred_vertex_shader_ref(
  _witness : E?,
) -> String? {
  E::deferred_vertex_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_deferred_fragment_shader_ref(
  _witness : E?,
) -> String? {
  E::deferred_fragment_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_meshlet_fragment_shader_ref(
  _witness : E?,
) -> String? {
  E::meshlet_fragment_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_meshlet_prepass_fragment_shader_ref(
  _witness : E?,
) -> String? {
  E::meshlet_prepass_fragment_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_meshlet_deferred_fragment_shader_ref(
  _witness : E?,
) -> String? {
  E::meshlet_deferred_fragment_shader_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_enable_prepass(
  _witness : E?,
) -> Bool {
  E::enable_prepass_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_enable_shadows(
  _witness : E?,
) -> Bool {
  E::enable_shadows_ref()
}

///|
fn[E : StandardMaterialExtension] standard_material_extension_specialize(
  _witness : E?,
) -> @material.UserSpecializeFn? {
  E::specialize_ref()
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
  { base: B::default(), extension: E::default() }
}

///|
pub fn[B, E] ExtendedMaterial::new(
  base : B,
  extension : E,
) -> ExtendedMaterial[B, E] {
  { base, extension }
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
  { ..self, base, }
}

///|
pub fn[B, E] ExtendedMaterial::with_extension(
  self : ExtendedMaterial[B, E],
  extension : E,
) -> ExtendedMaterial[B, E] {
  { ..self, extension, }
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
fn extended_material_shader_override(
  extension_shader : String?,
  base_shader : String?,
) -> String? {
  match extension_shader {
    Some(_) => extension_shader
    None => base_shader
  }
}

///|
fn extended_material_standard_vertex_shader() -> String? {
  material_default_vertex_shader()
}

///|
fn extended_material_standard_fragment_shader() -> String? {
  Some(PBR_MESH_FRAGMENT_SHADER_PATH)
}

///|
fn extended_material_standard_prepass_vertex_shader() -> String? {
  material_default_vertex_shader()
}

///|
fn extended_material_standard_prepass_fragment_shader() -> String? {
  Some(PBR_MESH_PREPASS_FRAGMENT_SHADER_PATH)
}

///|
fn extended_material_standard_deferred_vertex_shader() -> String? {
  material_default_vertex_shader()
}

///|
fn extended_material_standard_deferred_fragment_shader() -> String? {
  Some(PBR_MESH_FRAGMENT_SHADER_PATH)
}

///|
fn extended_material_standard_meshlet_fragment_shader() -> String? {
  Some(PBR_MESH_FRAGMENT_SHADER_PATH)
}

///|
fn extended_material_standard_meshlet_prepass_fragment_shader() -> String? {
  Some(PBR_MESH_PREPASS_FRAGMENT_SHADER_PATH)
}

///|
fn extended_material_standard_meshlet_deferred_fragment_shader() -> String? {
  Some(PBR_MESH_FRAGMENT_SHADER_PATH)
}

///|
fn extended_material_binding_from_extension_binding(
  binding : @material.MaterialExtensionBinding3d,
) -> MaterialBinding {
  match binding.resource() {
    Texture(image) => MaterialBinding::texture(binding.binding(), Some(image))
    Sampler(image) => MaterialBinding::sampler(binding.binding(), Some(image))
    Uniform(bytes) => MaterialBinding::uniform(binding.binding(), bytes)
  }
}

///|
fn[E : MaterialExtension] extended_material_standard_bind_group(
  material : ExtendedMaterial[StandardMaterial, E],
  context : MaterialBindGroupContext,
) -> MaterialBindGroup {
  let base_bind_group = standard_material_generic_bind_group(
    material.base,
    context,
  )
  let bindings : Array[MaterialBinding] = []
  for binding in base_bind_group.bindings {
    bindings.push(binding)
  }
  for binding in material.extension.bind_group_bindings() {
    bindings.push(extended_material_binding_from_extension_binding(binding))
  }
  MaterialBindGroup::new(bindings)
}

///|
pub impl[E : StandardMaterialExtension] @asset.Asset for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn asset_debug_name() {
  E::extended_material_asset_debug_name()
}

///|
pub impl[E : StandardMaterialExtension] @asset.Asset for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn asset_as_image(_self) {
  None
}

///|
pub impl[E : StandardMaterialExtension] @asset.Asset for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn asset_resource_keys() {
  E::extended_material_asset_keys()
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn material_debug_name() {
  let witness : E? = None
  standard_material_extension_asset_debug_name(witness)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn material_keys() {
  StandardMaterialExtension::extended_material_keys()
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn vertex_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_vertex_shader_ref(witness),
    extended_material_standard_vertex_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn fragment_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_fragment_shader_ref(witness),
    extended_material_standard_fragment_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn prepass_vertex_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_prepass_vertex_shader_ref(witness),
    extended_material_standard_prepass_vertex_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn prepass_fragment_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_prepass_fragment_shader_ref(witness),
    extended_material_standard_prepass_fragment_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn deferred_vertex_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_deferred_vertex_shader_ref(witness),
    extended_material_standard_deferred_vertex_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn deferred_fragment_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_deferred_fragment_shader_ref(witness),
    extended_material_standard_deferred_fragment_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn meshlet_fragment_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_meshlet_fragment_shader_ref(witness),
    extended_material_standard_meshlet_fragment_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn meshlet_prepass_fragment_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_meshlet_prepass_fragment_shader_ref(witness),
    extended_material_standard_meshlet_prepass_fragment_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn meshlet_deferred_fragment_shader() {
  let witness : E? = None
  extended_material_shader_override(
    standard_material_extension_meshlet_deferred_fragment_shader_ref(witness),
    extended_material_standard_meshlet_deferred_fragment_shader(),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn register_shader_sources() {
  true
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn alpha_mode(self) {
  match MaterialExtension::alpha_mode(self.extension) {
    Some(value) => value
    None => self.base.alpha_mode
  }
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn opaque_render_method(self) {
  standard_material_unresolved_opaque_render_method(self.base)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn depth_bias(self) {
  self.base.depth_bias
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn reads_view_transmission_texture(self) {
  standard_material_reads_view_transmission_texture(self.base)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn draw_data(self) {
  Standard(self.base)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn material_extension_metadata(self) {
  Some(self.metadata())
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn enable_prepass() {
  let witness : E? = None
  standard_material_extension_enable_prepass(witness)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn enable_shadows() {
  let witness : E? = None
  standard_material_extension_enable_shadows(witness)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn bindless_supported(render_device) {
  standard_material_bindless_supported(render_device)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn bindless_slot_count() {
  standard_material_bindless_slot_count()
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn bind_group(self, context) {
  extended_material_standard_bind_group(self, context)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn bind_group_layout_descriptor(self, context) {
  let base = standard_material_bind_group_layout_descriptor(
    features=context.standard_material_texture_features(),
  )
  let extension_entries = MaterialExtension::bind_group_layout_entries(
    self.extension,
  )
  let witness : E? = None
  extended_material_bind_group_layout_descriptor(
    base,
    extension_entries,
    standard_material_extension_asset_debug_name(witness),
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn bind_group_data(self, context) {
  extended_material_standard_bind_group(self, context).bind_group_data()
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn renderer_extra_bind_group_data(self, _context) {
  let entries : Array[@render_resource.MaterialBindGroupResolvedEntry] = []
  for binding in MaterialExtension::bind_group_bindings(self.extension) {
    let material_binding = extended_material_binding_from_extension_binding(
      binding,
    )
    entries.push(material_binding_to_resolved_entry(material_binding))
  }
  @render_resource.MaterialBindGroupResolvedData::new(entries)
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn material_key(self, context) {
  let witness : E? = None
  @material.ErasedMaterialKey::new(
    Material::bind_group_data(self, context).hash64(),
    "MaterialExtensionBindGroupData<\{standard_material_extension_asset_debug_name(witness)}>",
  )
}

///|
pub impl[E : MaterialExtension + StandardMaterialExtension] Material for ExtendedMaterial[
  StandardMaterial,
  E,
] with fn specialize(descriptor, layout, key) {
  ignore(layout)
  let base_key : MaterialPipelineKey[StandardMaterial] = MaterialPipelineKey::new(
    key.mesh_key(),
    key.bind_group_layout_key(),
    key.bind_group_data(),
    material_key=key.material_key(),
  )
  let base_descriptor = pbr_specialize_standard_material_descriptor_for_key(
    descriptor,
    @material.ErasedMaterialPipelineKey::new(
      base_key.mesh_key(),
      base_key.material_key(),
      "StandardMaterial",
    ),
  )
  let witness : E? = None
  match standard_material_extension_specialize(witness) {
    Some(user_specialize) =>
      user_specialize(
        standard_material_extension_asset_debug_name(witness),
        base_descriptor,
        layout,
        @material.ErasedMaterialPipelineKey::new(
          key.mesh_key(),
          key.material_key(),
          standard_material_extension_asset_debug_name(witness),
        ),
      )
    None => base_descriptor
  }
}

///|
pub type ForwardDecalMaterialExtension3d = ForwardDecalMaterialExtension

///|
pub struct ForwardDecalMaterialExtension {
  ext : ForwardDecalMaterialExt
}

///|
pub fn ForwardDecalMaterialExtension::ForwardDecalMaterialExtension() -> ForwardDecalMaterialExtension {
  { ext: ForwardDecalMaterialExt() }
}

///|
pub fn ForwardDecalMaterialExtension::new(
  ext : ForwardDecalMaterialExt,
) -> ForwardDecalMaterialExtension {
  { ext, }
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
  Some(Blend)
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn opaque_render_method(
  _self,
) {
  Some(Forward)
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
  vertex_shader_defs.push(Flag("FORWARD_DECAL"))
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
      fragment_shader_defs.push(Flag("FORWARD_DECAL"))
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
// Bevy source: `bevy_pbr/src/decal/forward.rs`
// `#[uniform(200, ForwardDecalMaterialExtUniform)]`.
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn bind_group_layout_entries(
  _self,
) {
  [
    @render_resource.BindGroupLayoutEntry::new(
      200,
      @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
      BufferBinding(Uniform, false, 4UL),
    ),
  ]
}

///|
pub impl MaterialExtension for ForwardDecalMaterialExtension with fn bind_group_bindings(
  self,
) {
  let uniform = @pbr_decal.pbr_forward_decal_material_ext_uniform(
    self.ext.depth_fade_factor,
  )
  let bits = uniform.inv_depth_fade_factor.reinterpret_as_int()
  let bytes = Bytes::makei(4, i => ((bits >> (8 * i)) & 0xFF).to_byte())
  [@material.MaterialExtensionBinding3d::uniform(200, bytes)]
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/decal/forward.rs` — the
// `ForwardDecalMaterial` alias instantiates `ExtendedMaterial` with this
// extension; the registrations below make that instantiation a live
// `Material` (Bevy adds `MaterialPlugin::<ForwardDecalMaterial>` in
// `ForwardDecalPlugin::build`).
let forward_decal_extended_material_asset_keys : @asset.AssetResourceKeys[
  ExtendedMaterial[StandardMaterial, ForwardDecalMaterialExtension],
] = @asset.register_asset_resource_keys("mgstudio_pbr::ForwardDecalMaterial")

///|
let forward_decal_extended_material_keys : MaterialKeys[
  ExtendedMaterial[StandardMaterial, ForwardDecalMaterialExtension],
] = register_material_keys("mgstudio_pbr::ForwardDecalMaterial")

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn extended_material_asset_debug_name() {
  "mgstudio_pbr::ForwardDecalMaterial"
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn extended_material_asset_keys() {
  forward_decal_extended_material_asset_keys
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn extended_material_keys() {
  forward_decal_extended_material_keys
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn vertex_shader_ref() {
  standard_material_extension_default_vertex_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn fragment_shader_ref() {
  standard_material_extension_default_fragment_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn prepass_vertex_shader_ref() {
  standard_material_extension_default_prepass_vertex_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn prepass_fragment_shader_ref() {
  standard_material_extension_default_prepass_fragment_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn deferred_vertex_shader_ref() {
  standard_material_extension_default_deferred_vertex_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn deferred_fragment_shader_ref() {
  standard_material_extension_default_deferred_fragment_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn meshlet_fragment_shader_ref() {
  standard_material_extension_default_meshlet_fragment_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn meshlet_prepass_fragment_shader_ref() {
  standard_material_extension_default_meshlet_prepass_fragment_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn meshlet_deferred_fragment_shader_ref() {
  standard_material_extension_default_meshlet_deferred_fragment_shader_ref()
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn enable_prepass_ref() {
  standard_material_extension_default_enable_prepass_ref()
}

///|
// Bevy: `ForwardDecalMaterialExt::enable_shadows() -> false`.
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn enable_shadows_ref() {
  false
}

///|
pub impl StandardMaterialExtension for ForwardDecalMaterialExtension with fn specialize_ref() {
  Some(forward_decal_specialize)
}

///|
pub fn extended_material_metadata_default() -> ExtendedMaterialMetadata3d {
  ExtendedMaterialMetadata3d()
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
