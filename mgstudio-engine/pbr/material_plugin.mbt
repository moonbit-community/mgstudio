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
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs`.

///|
pub(all) enum MaterialBindingValue {
  Uniform(Bytes)
  Texture(
    @asset.Handle[@asset.Image]?,
    MaterialTextureSampleType,
    MaterialTextureViewDimension
  )
  Sampler(@asset.Handle[@asset.Image]?)
}

///|
pub(all) enum MaterialTextureSampleType {
  Float
  UInt
} derive(Eq, Debug)

///|
pub(all) enum MaterialTextureViewDimension {
  D2
  D2Array
  Cube
  CubeArray
  D3
} derive(Eq, Debug)

///|
fn material_texture_sample_type_key(
  sample_type : MaterialTextureSampleType,
) -> String {
  match sample_type {
    Float => "float"
    UInt => "uint"
  }
}

///|
fn material_texture_view_dimension_key(
  view_dimension : MaterialTextureViewDimension,
) -> String {
  match view_dimension {
    D2 => "2d"
    D2Array => "2d_array"
    Cube => "cube"
    CubeArray => "cube_array"
    D3 => "3d"
  }
}

///|
fn material_texture_sample_type_to_render_resource(
  sample_type : MaterialTextureSampleType,
) -> @render_resource.TextureSampleType {
  match sample_type {
    Float => @render_resource.TextureSampleType::Float(true)
    UInt => @render_resource.TextureSampleType::UInt
  }
}

///|
fn material_texture_view_dimension_to_render_resource(
  view_dimension : MaterialTextureViewDimension,
) -> @render_resource.TextureViewDimension {
  match view_dimension {
    D2 => @render_resource.TextureViewDimension::D2
    D2Array => @render_resource.TextureViewDimension::D2Array
    Cube => @render_resource.TextureViewDimension::Cube
    CubeArray => @render_resource.TextureViewDimension::CubeArray
    D3 => @render_resource.TextureViewDimension::D3
  }
}

///|
pub struct MaterialBinding {
  binding : Int
  value : MaterialBindingValue
}

///|
pub fn MaterialBinding::uniform(
  binding : Int,
  bytes : Bytes,
) -> MaterialBinding {
  MaterialBinding::{ binding, value: Uniform(bytes) }
}

///|
pub fn MaterialBinding::texture(
  binding : Int,
  texture : @asset.Handle[@asset.Image]?,
) -> MaterialBinding {
  MaterialBinding::{
    binding,
    value: Texture(texture, MaterialTextureSampleType::Float, D2),
  }
}

///|
pub fn MaterialBinding::texture_with_layout(
  binding : Int,
  texture : @asset.Handle[@asset.Image]?,
  sample_type : MaterialTextureSampleType,
  view_dimension : MaterialTextureViewDimension,
) -> MaterialBinding {
  MaterialBinding::{
    binding,
    value: Texture(texture, sample_type, view_dimension),
  }
}

///|
pub fn MaterialBinding::sampler(
  binding : Int,
  texture : @asset.Handle[@asset.Image]?,
) -> MaterialBinding {
  MaterialBinding::{ binding, value: Sampler(texture) }
}

///|
fn material_binding_layout_kind_key(value : MaterialBindingValue) -> String {
  match value {
    Uniform(_) => "uniform"
    Texture(_, sample_type, view_dimension) =>
      "texture(\{material_texture_sample_type_key(sample_type)},\{material_texture_view_dimension_key(view_dimension)})"
    Sampler(_) => "sampler"
  }
}

///|
fn material_binding_data_key(value : MaterialBindingValue) -> String {
  match value {
    Uniform(bytes) => "uniform(\{material_bytes_bind_group_data(bytes)})"
    Texture(texture, sample_type, view_dimension) => {
      let texture_id = match texture {
        Some(value) => value.id().to_string()
        None => "none"
      }
      "texture(\{texture_id},\{material_texture_sample_type_key(sample_type)},\{material_texture_view_dimension_key(view_dimension)})"
    }
    Sampler(texture) => {
      let texture_id = match texture {
        Some(value) => value.id().to_string()
        None => "none"
      }
      "sampler(\{texture_id})"
    }
  }
}

///|
fn material_bytes_bind_group_data(bytes : Bytes) -> String {
  let mut data = "len=\{bytes.length().to_string()}:"
  for i in 0..<bytes.length() {
    if i > 0 {
      data = "\{data},"
    }
    data = "\{data}\{bytes[i].to_int().to_string()}"
  }
  data
}

///|
fn material_binding_to_layout_entry(
  binding : MaterialBinding,
) -> @render_resource.BindGroupLayoutEntry {
  let visibility = (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
  let kind = match binding.value {
    Uniform(_) =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        0UL,
      )
    Texture(_, sample_type, view_dimension) =>
      @render_resource.BindingType::TextureBinding(
        material_texture_sample_type_to_render_resource(sample_type),
        material_texture_view_dimension_to_render_resource(view_dimension),
        false,
      )
    Sampler(_) =>
      @render_resource.BindingType::SamplerBinding(
        @render_resource.SamplerBindingType::Filtering,
      )
  }
  @render_resource.BindGroupLayoutEntry::new(binding.binding, visibility, kind)
}

///|
fn material_binding_to_resolved_entry(
  binding : MaterialBinding,
) -> @render_resource.MaterialBindGroupResolvedEntry {
  match binding.value {
    Uniform(bytes) =>
      @render_resource.MaterialBindGroupResolvedEntry::uniform(
        binding.binding,
        bytes,
      )
    Texture(texture, _, _) =>
      @render_resource.MaterialBindGroupResolvedEntry::texture(
        binding.binding,
        match texture {
          Some(value) => value.id()
          None => -1
        },
      )
    Sampler(texture) =>
      @render_resource.MaterialBindGroupResolvedEntry::sampler(
        binding.binding,
        match texture {
          Some(value) => value.id()
          None => -1
        },
      )
  }
}

///|
pub struct MaterialBindGroup {
  bindings : Array[MaterialBinding]
}

///|
pub fn MaterialBindGroup::new(
  bindings : Array[MaterialBinding],
) -> MaterialBindGroup {
  let normalized = bindings.copy()
  normalized.sort_by(fn(a, b) {
    if a.binding < b.binding {
      -1
    } else if a.binding > b.binding {
      1
    } else {
      0
    }
  })
  for i in 1..<normalized.length() {
    if normalized[i - 1].binding == normalized[i].binding {
      abort(
        "duplicate Material bind-group binding \{normalized[i].binding.to_string()}",
      )
    }
  }
  MaterialBindGroup::{ bindings: normalized }
}

///|
pub fn MaterialBindGroup::MaterialBindGroup() -> MaterialBindGroup {
  MaterialBindGroup::new([])
}

///|
pub fn MaterialBindGroup::binding(
  self : MaterialBindGroup,
  binding : Int,
) -> MaterialBinding? {
  for entry in self.bindings {
    if entry.binding == binding {
      return Some(entry)
    }
  }
  None
}

///|
pub fn MaterialBindGroup::layout_key(self : MaterialBindGroup) -> String {
  let mut data = ""
  for i in 0..<self.bindings.length() {
    let binding = self.bindings[i]
    if i > 0 {
      data = "\{data};"
    }
    data = "\{data}\{binding.binding.to_string()}:\{material_binding_layout_kind_key(binding.value)}"
  }
  data
}

///|
pub fn MaterialBindGroup::bind_group_data(self : MaterialBindGroup) -> String {
  let mut data = ""
  for i in 0..<self.bindings.length() {
    let binding = self.bindings[i]
    if i > 0 {
      data = "\{data};"
    }
    data = "\{data}\{binding.binding.to_string()}:\{material_binding_data_key(binding.value)}"
  }
  data
}

///|
pub fn MaterialBindGroup::layout_descriptor(
  self : MaterialBindGroup,
  label : String,
) -> @render_resource.BindGroupLayoutDescriptor {
  let entries : Array[@render_resource.BindGroupLayoutEntry] = []
  for binding in self.bindings {
    entries.push(material_binding_to_layout_entry(binding))
  }
  @render_resource.BindGroupLayoutDescriptor::new(label, entries)
}

///|
pub fn MaterialBindGroup::resolved_data(
  self : MaterialBindGroup,
) -> @render_resource.MaterialBindGroupResolvedData {
  let entries : Array[@render_resource.MaterialBindGroupResolvedEntry] = []
  for binding in self.bindings {
    entries.push(material_binding_to_resolved_entry(binding))
  }
  @render_resource.MaterialBindGroupResolvedData::new(entries)
}

///|
pub struct MaterialPipelineKey[_] {
  mesh_key : @material.ErasedMeshPipelineKey
  bind_group_layout_key : String
  bind_group_data : String
}

///|
pub fn[M] MaterialPipelineKey::new(
  mesh_key : @material.ErasedMeshPipelineKey,
  bind_group_layout_key : String,
  bind_group_data : String,
) -> MaterialPipelineKey[M] {
  MaterialPipelineKey::{ mesh_key, bind_group_layout_key, bind_group_data }
}

///|
pub fn[M] MaterialPipelineKey::mesh_key(
  self : MaterialPipelineKey[M],
) -> @material.ErasedMeshPipelineKey {
  self.mesh_key
}

///|
pub fn[M] MaterialPipelineKey::bind_group_data(
  self : MaterialPipelineKey[M],
) -> String {
  self.bind_group_data
}

///|
pub fn[M] MaterialPipelineKey::bind_group_layout_key(
  self : MaterialPipelineKey[M],
) -> String {
  self.bind_group_layout_key
}

///|
pub struct MaterialPipeline[M] {
  vertex_shader : String?
  fragment_shader : String?
  prepass_vertex_shader : String?
  prepass_fragment_shader : String?
  deferred_vertex_shader : String?
  deferred_fragment_shader : String?
  meshlet_fragment_shader : String?
  meshlet_prepass_fragment_shader : String?
  meshlet_deferred_fragment_shader : String?
  marker : M?
}

///|
pub fn[M] MaterialPipeline::MaterialPipeline() -> MaterialPipeline[M] {
  MaterialPipeline::{
    vertex_shader: None,
    fragment_shader: None,
    prepass_vertex_shader: None,
    prepass_fragment_shader: None,
    deferred_vertex_shader: None,
    deferred_fragment_shader: None,
    meshlet_fragment_shader: None,
    meshlet_prepass_fragment_shader: None,
    meshlet_deferred_fragment_shader: None,
    marker: None,
  }
}

///|
pub fn[M] MaterialPipeline::new(
  vertex_shader : String?,
  fragment_shader : String?,
  prepass_vertex_shader : String?,
  prepass_fragment_shader : String?,
  deferred_vertex_shader : String?,
  deferred_fragment_shader : String?,
  meshlet_fragment_shader : String?,
  meshlet_prepass_fragment_shader : String?,
  meshlet_deferred_fragment_shader : String?,
) -> MaterialPipeline[M] {
  MaterialPipeline::{
    vertex_shader,
    fragment_shader,
    prepass_vertex_shader,
    prepass_fragment_shader,
    deferred_vertex_shader,
    deferred_fragment_shader,
    meshlet_fragment_shader,
    meshlet_prepass_fragment_shader,
    meshlet_deferred_fragment_shader,
    marker: None,
  }
}

///|
pub struct MeshMaterial3dTyped[M] {
  handle : @asset.Handle[M]
}

///|
pub fn[M] MeshMaterial3dTyped::new(
  material : @asset.Handle[M],
) -> MeshMaterial3dTyped[M] {
  MeshMaterial3dTyped::{ handle: material }
}

///|
pub fn[M] MeshMaterial3dTyped::handle(
  self : MeshMaterial3dTyped[M],
) -> @asset.Handle[M] {
  self.handle
}

///|
pub impl[M : Material] @ecs.Component for MeshMaterial3dTyped[M] with fn component() {
  M::material_keys().mesh_material_component
}

///|
fn[M] encode_mesh_material3d_typed(material : MeshMaterial3dTyped[M]) -> Json {
  material.handle.to_json()
}

///|
fn[M] decode_mesh_material3d_typed(json : Json) -> MeshMaterial3dTyped[M] {
  let handle : @asset.Handle[M] = try! @json.from_json(json)
  MeshMaterial3dTyped::new(handle)
}

///|
pub impl[M] ToJson for MeshMaterial3dTyped[M] with fn to_json(self) {
  encode_mesh_material3d_typed(self)
}

///|
pub impl[M] @json.FromJson for MeshMaterial3dTyped[M] with fn from_json(
  json,
  _path,
) {
  decode_mesh_material3d_typed(json)
}

///|
pub struct RenderMaterial3dInstances[M] {
  instances : @hashmap.HashMap[(Int, Int), @asset.Handle[M]]
}

///|
fn material_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

///|
pub fn[M] RenderMaterial3dInstances::new() -> RenderMaterial3dInstances[M] {
  RenderMaterial3dInstances::{ instances: @hashmap.HashMap([]) }
}

///|
pub fn[M] RenderMaterial3dInstances::get(
  self : RenderMaterial3dInstances[M],
  entity : @core.Entity,
) -> @asset.Handle[M]? {
  self.instances.get(material_entity_key(entity))
}

///|
pub fn[M] RenderMaterial3dInstances::set(
  self : RenderMaterial3dInstances[M],
  entity : @core.Entity,
  material : @asset.Handle[M],
) -> Unit {
  self.instances.set(material_entity_key(entity), material)
}

///|
pub fn[M] RenderMaterial3dInstances::clear(
  self : RenderMaterial3dInstances[M],
) -> Unit {
  self.instances.clear()
}

///|
pub struct MaterialKeys[M] {
  mesh_material_component : @ecs.ComponentKey[MeshMaterial3dTyped[M]]
  render_material_instances : @ecs.ResourceKey[RenderMaterial3dInstances[M]]
  material_pipeline : @ecs.ResourceKey[MaterialPipeline[M]]
  prepared_render_asset : @render.RenderAssetResourceKeys[PreparedMaterial[M]]
}

///|
pub fn[M] register_material_keys(
  material_debug_name : String,
) -> MaterialKeys[M] {
  MaterialKeys::{
    mesh_material_component: @ecs.register_component(
      debug_name="mgstudio_pbr::MeshMaterial3d<\{material_debug_name}>",
    ),
    render_material_instances: @ecs.register_resource(
      debug_name="mgstudio_pbr::RenderMaterialInstances<\{material_debug_name}>",
    ),
    material_pipeline: @ecs.register_resource(
      debug_name="mgstudio_pbr::MaterialPipeline<\{material_debug_name}>",
    ),
    prepared_render_asset: @render.register_render_asset_resource_keys(
      "mgstudio_pbr::PreparedMaterial<\{material_debug_name}>",
    ),
  }
}

///|
pub(open) trait Material {
  fn material_debug_name() -> String
  fn material_keys() -> MaterialKeys[Self]
  fn vertex_shader() -> String?
  fn fragment_shader() -> String?
  fn prepass_vertex_shader() -> String?
  fn prepass_fragment_shader() -> String?
  fn deferred_vertex_shader() -> String?
  fn deferred_fragment_shader() -> String?
  fn meshlet_fragment_shader() -> String?
  fn meshlet_prepass_fragment_shader() -> String?
  fn meshlet_deferred_fragment_shader() -> String?
  fn alpha_mode(self : Self) -> @material.AlphaMode3d
  fn opaque_render_method(self : Self) -> @material.OpaqueRendererMethod
  fn depth_bias(self : Self) -> Float
  fn reads_view_transmission_texture(self : Self) -> Bool
  fn enable_prepass() -> Bool
  fn enable_shadows() -> Bool
  fn bind_group(self : Self) -> MaterialBindGroup
  fn specialize(
    descriptor : @render.RenderPipelineDescriptor,
    layout : @mesh.MeshVertexBufferLayoutRef,
    key : MaterialPipelineKey[Self],
  ) -> @render.RenderPipelineDescriptor
}

///|
pub fn material_default_vertex_shader() -> String? {
  None
}

///|
pub fn material_default_fragment_shader() -> String? {
  None
}

///|
pub fn material_default_alpha_mode() -> @material.AlphaMode3d {
  @material.AlphaMode3d::Opaque
}

///|
pub fn material_default_opaque_render_method() -> @material.OpaqueRendererMethod {
  @material.OpaqueRendererMethod::Forward
}

///|
pub fn material_default_depth_bias() -> Float {
  0.0F
}

///|
pub fn material_default_reads_view_transmission_texture() -> Bool {
  false
}

///|
pub fn material_default_enable_prepass() -> Bool {
  true
}

///|
pub fn material_default_enable_shadows() -> Bool {
  true
}

///|
pub fn material_default_bind_group() -> MaterialBindGroup {
  MaterialBindGroup::MaterialBindGroup()
}

///|
pub fn[M] material_default_specialize(
  descriptor : @render.RenderPipelineDescriptor,
  _layout : @mesh.MeshVertexBufferLayoutRef,
  _key : MaterialPipelineKey[M],
) -> @render.RenderPipelineDescriptor {
  descriptor
}

///|
pub fn[M : Material] material_pipeline_resource_key_of(
  _probe : @asset.Handle[M],
) -> @ecs.ResourceKey[MaterialPipeline[M]] {
  ignore(_probe)
  M::material_keys().material_pipeline
}

///|
pub impl[M : Material] @app.Resource for MaterialPipeline[M] with fn resource() {
  M::material_keys().material_pipeline
}

///|
pub impl[M : Material] @app.Resource for RenderMaterial3dInstances[M] with fn resource() {
  M::material_keys().render_material_instances
}

///|
fn[M : Material] material_render_phase_type(
  material : M,
) -> @material.RenderPhaseType {
  match material.alpha_mode() {
    @material.AlphaMode3d::Blend => @material.RenderPhaseType::Transparent
    @material.AlphaMode3d::Premultiplied =>
      @material.RenderPhaseType::Transparent
    @material.AlphaMode3d::Add => @material.RenderPhaseType::Transparent
    @material.AlphaMode3d::Multiply => @material.RenderPhaseType::Transparent
    _ =>
      if material.reads_view_transmission_texture() {
        @material.RenderPhaseType::Transmissive
      } else {
        match material.alpha_mode() {
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
fn[M : Material] material_mesh_pipeline_key(
  material : M,
) -> @material.ErasedMeshPipelineKey {
  let transmission_bits = if material.reads_view_transmission_texture() {
    MESH_PIPELINE_KEY_READS_VIEW_TRANSMISSION_TEXTURE
  } else {
    0UL
  }
  let bits = alpha_mode_pipeline_key(material.alpha_mode()) | transmission_bits
  @material.ErasedMeshPipelineKey::new(bits, "MeshPipelineKey")
}

///|
fn material_properties_add_shader(
  properties : @material.MaterialProperties,
  label : @material.ShaderLabel,
  shader : String?,
) -> @material.MaterialProperties {
  match shader {
    Some(path) => properties.add_shader(label, path)
    None => properties
  }
}

///|
pub struct PreparedMaterial[M] {
  source : @asset.Handle[M]
  bind_group : MaterialBindGroup
  bind_group_data : @render_resource.MaterialBindGroupResolvedData
  key : MaterialPipelineKey[M]
  properties : @material.MaterialProperties
}

///|
pub struct Render3dResolvedMaterial {
  material : StandardMaterial
  material_properties : @material.MaterialProperties
  material_bind_group_data : @render_resource.MaterialBindGroupResolvedData
}

///|
pub fn Render3dResolvedMaterial::new(
  material : StandardMaterial,
  material_properties : @material.MaterialProperties,
  material_bind_group_data : @render_resource.MaterialBindGroupResolvedData,
) -> Render3dResolvedMaterial {
  Render3dResolvedMaterial::{
    material,
    material_properties,
    material_bind_group_data,
  }
}

///|
pub fn Render3dResolvedMaterial::material(
  self : Render3dResolvedMaterial,
) -> StandardMaterial {
  self.material
}

///|
pub fn Render3dResolvedMaterial::material_properties(
  self : Render3dResolvedMaterial,
) -> @material.MaterialProperties {
  self.material_properties
}

///|
pub fn Render3dResolvedMaterial::material_bind_group_data(
  self : Render3dResolvedMaterial,
) -> @render_resource.MaterialBindGroupResolvedData {
  self.material_bind_group_data
}

///|
pub impl[M : Material] @render.RenderAssetResource for PreparedMaterial[M] with fn render_asset_resource_debug_name() {
  "mgstudio_pbr::PreparedMaterial<\{M::material_debug_name()}>"
}

///|
pub impl[M : Material] @render.RenderAssetResource for PreparedMaterial[M] with fn render_asset_resource_keys() {
  M::material_keys().prepared_render_asset
}

///|
pub fn[M : Material] PreparedMaterial::from_material(
  source : @asset.Handle[M],
  material : M,
  pipeline : MaterialPipeline[M],
) -> PreparedMaterial[M] {
  let bind_group = material.bind_group()
  let key = MaterialPipelineKey::new(
    material_mesh_pipeline_key(material),
    bind_group.layout_key(),
    bind_group.bind_group_data(),
  )
  let render_method = material
    .opaque_render_method()
    .resolve_runtime(@material.OpaqueRendererMethod::Forward)
  let mut properties = @material.MaterialProperties::MaterialProperties()
    .with_render_method(render_method)
    .with_alpha_mode(material.alpha_mode())
    .with_mesh_pipeline_key_bits(key.mesh_key())
    .with_depth_bias(material.depth_bias())
    .with_reads_view_transmission_texture(
      material.reads_view_transmission_texture(),
    )
    .with_render_phase_type(material_render_phase_type(material))
    .with_material_layout(
      Some(
        bind_group.layout_descriptor(
          "mgstudio_pbr::Material<\{M::material_debug_name()}>",
        ),
      ),
    )
    .with_material_key(
      @material.ErasedMaterialKey::new(
        material_hash_bind_group_data(key.bind_group_data()),
        "MaterialKey<\{M::material_debug_name()}>",
      ),
    )
    .with_user_specialize(
      Some(fn(_label, descriptor, layout, erased_key) {
        let typed_key = MaterialPipelineKey::new(
          erased_key.mesh_key(),
          key.bind_group_layout_key(),
          key.bind_group_data(),
        )
        M::specialize(descriptor, layout, typed_key)
      }),
    )
    .with_shadows_enabled(M::enable_shadows())
    .with_prepass_enabled(M::enable_prepass())
  properties = material_properties_add_shader(
    properties,
    @material.MATERIAL_VERTEX_SHADER_LABEL,
    pipeline.vertex_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.MATERIAL_FRAGMENT_SHADER_LABEL,
    pipeline.fragment_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.PREPASS_VERTEX_SHADER_LABEL,
    pipeline.prepass_vertex_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.PREPASS_FRAGMENT_SHADER_LABEL,
    pipeline.prepass_fragment_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.DEFERRED_VERTEX_SHADER_LABEL,
    pipeline.deferred_vertex_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.DEFERRED_FRAGMENT_SHADER_LABEL,
    pipeline.deferred_fragment_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.MESHLET_FRAGMENT_SHADER_LABEL,
    pipeline.meshlet_fragment_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.MESHLET_PREPASS_FRAGMENT_SHADER_LABEL,
    pipeline.meshlet_prepass_fragment_shader,
  )
  properties = material_properties_add_shader(
    properties,
    @material.MESHLET_DEFERRED_FRAGMENT_SHADER_LABEL,
    pipeline.meshlet_deferred_fragment_shader,
  )
  PreparedMaterial::{
    source,
    bind_group,
    bind_group_data: bind_group.resolved_data(),
    key,
    properties,
  }
}

///|
pub fn[M] PreparedMaterial::prepared_handle(
  source : @asset.Handle[M],
) -> @asset.Handle[PreparedMaterial[M]] {
  @asset.Handle::new(source.id())
}

///|
pub fn[M] PreparedMaterial::bind_group_data(
  self : PreparedMaterial[M],
) -> @render_resource.MaterialBindGroupResolvedData {
  self.bind_group_data
}

///|
pub fn[M] PreparedMaterial::properties(
  self : PreparedMaterial[M],
) -> @material.MaterialProperties {
  self.properties
}

///|
pub fn[M] PreparedMaterial::resolved_material(
  self : PreparedMaterial[M],
) -> Render3dResolvedMaterial {
  Render3dResolvedMaterial::new(
    StandardMaterial::StandardMaterial(),
    self.properties,
    self.bind_group_data,
  )
}

///|
fn material_hash_bind_group_data(data : String) -> UInt64 {
  let mut hash = 1469598103934665603UL
  for byte in @utf8.encode(data[:]) {
    hash = hash ^ byte.to_uint().to_uint64()
    hash = hash * 1099511628211UL
  }
  hash
}

///|
pub struct MaterialPlugin[M] {
  debug_flags : @render.RenderDebugFlags
  asset_init : (() -> M)?
}

///|
pub fn[M] MaterialPlugin::MaterialPlugin() -> MaterialPlugin[M] {
  MaterialPlugin::{
    debug_flags: @render.RenderDebugFlags::RenderDebugFlags(),
    asset_init: None,
  }
}

///|
pub fn[M] MaterialPlugin::with_asset_init(
  self : MaterialPlugin[M],
  init : () -> M,
) -> MaterialPlugin[M] {
  MaterialPlugin::{ ..self, asset_init: Some(init) }
}

///|
pub fn[M] MaterialPlugin::with_debug_flags(
  self : MaterialPlugin[M],
  debug_flags : @render.RenderDebugFlags,
) -> MaterialPlugin[M] {
  MaterialPlugin::{ ..self, debug_flags, }
}

///|
pub fn[M] MaterialPlugin::debug_flags(
  self : MaterialPlugin[M],
) -> @render.RenderDebugFlags {
  self.debug_flags
}

///|
pub impl[M : Material + @asset.Asset] @app.Plugin for MaterialPlugin[M] with fn build(
  self,
  app,
) {
  material_plugin_build(app, self)
}

///|
pub impl[M : Material + @asset.Asset] @app.Plugin for MaterialPlugin[M] with fn name(
  _self,
) {
  "mgstudio.pbr.MaterialPlugin<\{M::asset_debug_name()}>"
}

///|
fn[M : Material] material_pipeline_from_material_hooks(
  _probe : @asset.Handle[M],
) -> MaterialPipeline[M] {
  ignore(_probe)
  MaterialPipeline::new(
    M::vertex_shader(),
    M::fragment_shader(),
    M::prepass_vertex_shader(),
    M::prepass_fragment_shader(),
    M::deferred_vertex_shader(),
    M::deferred_fragment_shader(),
    M::meshlet_fragment_shader(),
    M::meshlet_prepass_fragment_shader(),
    M::meshlet_deferred_fragment_shader(),
  )
}

///|
fn[M : Material] ensure_prepared_material_assets_resource_in_world(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[M]],
  ] = @render.RenderAssets::resource()
  if world.get_resource(prepared_assets_key) is None {
    world.insert_resource(prepared_assets_key, @render.RenderAssets::new())
  }
}

///|
fn[M : Material] ensure_material_pipeline_resource_in_world(
  world : @ecs.World,
  pipeline : MaterialPipeline[M],
) -> Unit {
  let pipeline_key : @ecs.ResourceKey[MaterialPipeline[M]] = MaterialPipeline::resource()
  if world.get_resource(pipeline_key) is None {
    world.insert_resource(pipeline_key, pipeline)
  }
}

///|
fn[M : Material] ensure_render_material_instances_resource_in_world(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  let key : @ecs.ResourceKey[RenderMaterial3dInstances[M]] = RenderMaterial3dInstances::resource()
  if world.get_resource(key) is None {
    world.insert_resource(key, RenderMaterial3dInstances::new())
  }
}

///|
pub fn[M : Material] prepared_material_assets_or_empty(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> @render.RenderAssets[PreparedMaterial[M]] {
  _probe |> ignore
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[M]],
  ] = @render.RenderAssets::resource()
  let empty_prepared_assets : @render.RenderAssets[PreparedMaterial[M]] = @render.RenderAssets::new()
  if world.get_resource(prepared_assets_key) is Some(prepared_assets) {
    prepared_assets
  } else {
    empty_prepared_assets
  }
}

///|
pub fn[M : Material] render_material3d_instances_or_empty(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> RenderMaterial3dInstances[M] {
  _probe |> ignore
  let instances_key : @ecs.ResourceKey[RenderMaterial3dInstances[M]] = RenderMaterial3dInstances::resource()
  let empty_instances = RenderMaterial3dInstances::new()
  if world.get_resource(instances_key) is Some(instances) {
    instances
  } else {
    empty_instances
  }
}

///|
pub fn[M] prepared_material_handle_for_entity(
  entity : @core.Entity,
  material_instances : RenderMaterial3dInstances[M],
) -> @asset.Handle[PreparedMaterial[M]]? {
  guard material_instances.get(entity) is Some(material_handle) else {
    return None
  }
  Some(PreparedMaterial::prepared_handle(material_handle))
}

///|
pub fn[M] prepared_material_get(
  prepared_assets : @render.RenderAssets[PreparedMaterial[M]],
  handle : @asset.Handle[PreparedMaterial[M]],
) -> PreparedMaterial[M]? {
  prepared_assets.get(handle.id())
}

///|
pub struct MaterialRuntimeEntry {
  type_name : String
  contains_source_material_fn : (@ecs.World, @core.Entity) -> Bool
  resolve_material_fn : (@ecs.World, @ecs.World, @core.Entity) -> Render3dResolvedMaterial?
}

///|
pub struct MaterialRuntimeRegistry {
  entries : Array[MaterialRuntimeEntry]
}

///|
pub fn MaterialRuntimeRegistry::new() -> MaterialRuntimeRegistry {
  MaterialRuntimeRegistry::{ entries: [] }
}

///|
let material_runtime_registry_key : @ecs.ResourceKey[MaterialRuntimeRegistry] = @ecs.register_resource(
  debug_name="mgstudio_pbr::MaterialRuntimeRegistry",
)

///|
pub impl @app.Resource for MaterialRuntimeRegistry with fn resource() {
  material_runtime_registry_key
}

///|
pub fn MaterialRuntimeRegistry::contains_type_name(
  self : MaterialRuntimeRegistry,
  type_name : String,
) -> Bool {
  self.entries.any(fn(entry) { entry.type_name == type_name })
}

///|
pub fn MaterialRuntimeRegistry::entry_count(
  self : MaterialRuntimeRegistry,
) -> Int {
  self.entries.length()
}

///|
fn MaterialRuntimeRegistry::register(
  self : MaterialRuntimeRegistry,
  entry : MaterialRuntimeEntry,
) -> Unit {
  if self.contains_type_name(entry.type_name) {
    return
  }
  self.entries.push(entry)
}

///|
fn ensure_material_runtime_registry_resource_in_world(
  world : @ecs.World,
) -> Unit {
  if world.get_resource(MaterialRuntimeRegistry::resource()) is None {
    world.insert_resource(
      MaterialRuntimeRegistry::resource(),
      MaterialRuntimeRegistry::new(),
    )
  }
}

///|
pub fn material_runtime_registry_or_empty(
  world : @ecs.World,
) -> MaterialRuntimeRegistry {
  if world.get_resource(MaterialRuntimeRegistry::resource()) is Some(registry) {
    registry
  } else {
    MaterialRuntimeRegistry::new()
  }
}

///|
pub fn[M : Material] material_runtime_type_name(
  _probe : @asset.Handle[M],
) -> String {
  ignore(_probe)
  "Material<\{M::material_debug_name()}>"
}

///|
fn[M : Material] material_runtime_entry(
  probe : @asset.Handle[M],
) -> MaterialRuntimeEntry {
  let type_name = material_runtime_type_name(probe)
  let material_key : @ecs.ComponentKey[MeshMaterial3dTyped[M]] = MeshMaterial3dTyped::component()
  let contains_source_material = fn(
    source_world : @ecs.World,
    entity : @core.Entity,
  ) -> Bool {
    (try! source_world.get_by_key(entity, material_key)) is Some(_)
  }
  MaterialRuntimeEntry::{
    type_name,
    contains_source_material_fn: contains_source_material,
    resolve_material_fn: fn(render_world, source_world, entity) {
      guard (try! source_world.get_by_key(entity, material_key))
        is Some(mesh_material) else {
        return None
      }
      let prepared_assets = prepared_material_assets_or_empty(
        render_world, probe,
      )
      let prepared_handle = PreparedMaterial::prepared_handle(
        mesh_material.handle(),
      )
      guard prepared_material_get(prepared_assets, prepared_handle)
        is Some(prepared) else {
        return None
      }
      Some(prepared.resolved_material())
    },
  }
}

///|
fn[M : Material] register_material_runtime_world(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> Unit {
  ensure_material_runtime_registry_resource_in_world(world)
  if world.get_resource_mut(MaterialRuntimeRegistry::resource())
    is Some(registry) {
    registry.modify(fn(value) { value.register(material_runtime_entry(probe)) })
  }
}

///|
fn[M : Material] material_bind_group_allocator_label(
  _probe : @asset.Handle[M],
) -> String {
  ignore(_probe)
  M::material_debug_name()
}

///|
fn[M : Material] add_material_bind_group_allocator_system(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> Unit {
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
  let label = material_bind_group_allocator_label(probe)
  allocators.modify(fn(value) {
    value.insert(label, MaterialBindGroupAllocator::default_non_bindless())
  })
}

///|
pub fn material_runtime_registry_contains_entity(
  source_world : @ecs.World,
  registry : MaterialRuntimeRegistry,
  entity : @core.Entity,
) -> Bool {
  for entry in registry.entries {
    if (entry.contains_source_material_fn)(source_world, entity) {
      return true
    }
  }
  false
}

///|
pub fn material_runtime_registry_resolve_material(
  render_world : @ecs.World,
  source_world : @ecs.World,
  registry : MaterialRuntimeRegistry,
  entity : @core.Entity,
) -> Render3dResolvedMaterial? {
  for entry in registry.entries {
    guard (entry.contains_source_material_fn)(source_world, entity) else {
      continue
    }
    guard (entry.resolve_material_fn)(render_world, source_world, entity)
      is Some(material) else {
      return None
    }
    return Some(material)
  }
  None
}

///|
fn[M : Material] material_shader_asset_paths(
  _probe : @asset.Handle[M],
) -> Array[String] {
  ignore(_probe)
  let paths : Array[String] = []
  let hooks = [
    M::vertex_shader(),
    M::fragment_shader(),
    M::prepass_vertex_shader(),
    M::prepass_fragment_shader(),
    M::deferred_vertex_shader(),
    M::deferred_fragment_shader(),
    M::meshlet_fragment_shader(),
    M::meshlet_prepass_fragment_shader(),
    M::meshlet_deferred_fragment_shader(),
  ]
  for hook in hooks {
    if hook is Some(path) {
      if !paths.any(fn(value) { value == path }) {
        paths.push(path)
      }
    }
  }
  paths
}

///|
fn render3d_register_shader_source_asset(
  world : @ecs.World,
  path : String,
) -> Unit {
  if @shader.shader_path_is_wesl(path) {
    @shader_runtime_render.shader_register_wesl_runtime_source(world, path, []) catch {
      err =>
        abort(
          "failed to compile render3d wesl shader asset: \{path}: \{err.message()}",
        )
    }
    return
  }
  @shader_runtime_render.shader_register_wgsl_runtime_source(world, path)
}

///|
fn register_material_shader_sources(
  world : @ecs.World,
  shader_paths : Array[String],
) -> Unit {
  for path in shader_paths {
    render3d_register_shader_source_asset(world, path)
  }
}

///|
fn[M : Material + @asset.Asset] material_plugin_build(
  app : @app.App[@ecs.World],
  plugin : MaterialPlugin[M],
) -> @app.App[@ecs.World] {
  let probe : @asset.Handle[M] = @asset.Handle::new(0)
  let shader_paths = material_shader_asset_paths(probe)
  let pipeline = material_pipeline_from_material_hooks(probe)
  let configured = match plugin.asset_init {
    Some(init) => @asset.init_asset(app, init)
    None =>
      abort(
        "MaterialPlugin requires with_asset_init(fn() { ... }) because MoonBit cannot call init_asset with explicit generic parameters",
      )
  }
  let configured = @render.with_render_app(configured, fn(render_app) {
    let render_world = render_app.world()
    ensure_prepared_material_assets_resource_in_world(render_world, probe)
    ensure_material_pipeline_resource_in_world(render_world, pipeline)
    ensure_render_material_instances_resource_in_world(render_world, probe)
    ensure_material_runtime_registry_resource_in_world(render_world)
    register_material_runtime_world(render_world, probe)
    @render.configure_base_render_sets(render_app)
    .add_systems(
      @render.render_startup_schedule_stage(),
      @app.system(fn(world : @ecs.World) {
        add_material_bind_group_allocator_system(world, probe)
      }).named(
        "mgstudio_pbr::add_material_bind_group_allocator<\{M::material_debug_name()}>",
      ),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(fn(world : @ecs.World) {
        extract_mesh_materials_system(world, probe)
      }).in_set(@render.render_system_set_extract_commands),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(fn(world : @ecs.World) {
        prepare_material_assets_system(world, probe)
      }).in_set(@render.render_system_set_prepare_assets),
    )
  })
  if shader_paths.length() == 0 {
    configured
  } else {
    configured.add_startup_system(fn(world : @ecs.World) {
      register_material_shader_sources(world, shader_paths)
    })
  }
}

///|
pub fn[M] material_plugin(plugin : MaterialPlugin[M]) -> MaterialPlugin[M] {
  plugin
}

///|
fn[M : Material] extract_mesh_materials_system(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  _probe |> ignore
  let source_world = @render.render_source_world(world)
  let material_key : @ecs.ComponentKey[MeshMaterial3dTyped[M]] = MeshMaterial3dTyped::component()
  let key : @ecs.ResourceKey[RenderMaterial3dInstances[M]] = RenderMaterial3dInstances::resource()
  guard world.get_resource_mut(key) is Some(instances) else { return }
  instances.modify(fn(value) {
    value.clear()
    source_world.for_each_component(material_key, fn(entity, material) {
      value.set(entity, material.handle())
    })
  })
}

///|
fn[M : Material + @asset.Asset] prepare_material_assets_system(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  _probe |> ignore
  let source_world = @render.render_source_world(world)
  let instances_key : @ecs.ResourceKey[RenderMaterial3dInstances[M]] = RenderMaterial3dInstances::resource()
  let source_assets_key : @ecs.ResourceKey[@asset.Assets[M]] = @asset.assets_resource_key()
  let pipeline_key : @ecs.ResourceKey[MaterialPipeline[M]] = MaterialPipeline::resource()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial[M]],
  ] = @render.RenderAssets::resource()
  guard world.get_resource(instances_key) is Some(instances) else { return }
  guard source_world.get_resource(source_assets_key) is Some(source_assets) else {
    return
  }
  guard world.get_resource(pipeline_key) is Some(pipeline) else { return }
  guard world.get_resource_mut(prepared_assets_key) is Some(prepared_assets) else {
    return
  }
  let prepared_ids : @hashset.HashSet[Int] = @hashset.HashSet([])
  for _, material_handle in instances.instances {
    let material_id = material_handle.id()
    if prepared_ids.contains(material_id) {
      continue
    }
    prepared_ids.add(material_id)
    guard source_assets.get(material_handle) is Some(material) else { continue }
    prepared_assets.modify(fn(value) {
      value.insert(
        material_id,
        PreparedMaterial::from_material(material_handle, material, pipeline),
      )
    })
  }
}
