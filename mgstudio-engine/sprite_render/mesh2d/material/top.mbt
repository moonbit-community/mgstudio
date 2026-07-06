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
// Bevy source: `bevy/crates/bevy_sprite_render/src/mesh2d/material.rs`.
pub(all) enum AlphaMode2d {
  Opaque
  Mask(Float)
  Blend
} derive(ToJson, FromJson)

///|
pub struct RenderMaterial2dInstances[M] {
  instances : @hashmap.HashMap[(Int, Int), @asset.Handle[M]]
}

///|
pub fn[M] RenderMaterial2dInstances::new() -> RenderMaterial2dInstances[M] {
  RenderMaterial2dInstances::{ instances: @hashmap.HashMap([]) }
}

///|
pub fn[M] RenderMaterial2dInstances::contains(
  self : RenderMaterial2dInstances[M],
  entity : @core.Entity,
) -> Bool {
  self.instances.contains(@render_material.render_material_entity_key(entity))
}

///|
pub fn[M] RenderMaterial2dInstances::get(
  self : RenderMaterial2dInstances[M],
  entity : @core.Entity,
) -> @asset.Handle[M]? {
  self.instances.get(@render_material.render_material_entity_key(entity))
}

///|
pub fn[M] RenderMaterial2dInstances::set(
  self : RenderMaterial2dInstances[M],
  entity : @core.Entity,
  material : @asset.Handle[M],
) -> Unit {
  self.instances.set(
    @render_material.render_material_entity_key(entity),
    material,
  )
}

///|
pub fn[M] RenderMaterial2dInstances::remove(
  self : RenderMaterial2dInstances[M],
  entity : @core.Entity,
) -> Unit {
  self.instances.remove(@render_material.render_material_entity_key(entity))
  |> ignore
}

///|
pub fn[M] RenderMaterial2dInstances::clear(
  self : RenderMaterial2dInstances[M],
) -> Unit {
  self.instances.clear()
}

///|
pub fn[M : Material2d] render_material2d_instances_resource_key_of(
  _probe : @asset.Handle[M],
) -> @ecs.ResourceKey[RenderMaterial2dInstances[M]] {
  ignore(_probe)
  M::material2d_keys().render_material2d_instances
}

///|
pub impl[M : Material2d] @app.Resource for RenderMaterial2dInstances[M] with fn resource() {
  M::material2d_keys().render_material2d_instances
}

///|
fn material2d_mesh_pipeline_key_bits(alpha_mode : AlphaMode2d) -> Int {
  match alpha_mode {
    Opaque => 0
    Mask(_) => @sprite_render_mesh2d_runtime.MESH2D_PIPELINE_KEY_MAY_DISCARD
    Blend => @sprite_render_mesh2d_runtime.MESH2D_PIPELINE_KEY_BLEND_ALPHA
  }
}

///|
fn material2d_mesh_pipeline_key_bits_for_host_mesh(
  mesh_info : @render.HostGpuMeshInfo,
) -> Int {
  @sprite_render_mesh2d_runtime.mesh2d_pipeline_key_bits_for_primitive(
    mesh_info.primitive_topology(),
    mesh_info.index_count(),
    mesh_info.uses_u32_indices(),
  )
}

///|
pub fn material2d_u32le_pack(xs : Array[UInt]) -> Bytes {
  let len = xs.length()
  Bytes::makei(len * 4, i => {
    let word = xs[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
pub fn material2d_f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
pub fn material2d_alpha_mode_kind_bits(alpha_mode : AlphaMode2d) -> UInt {
  match alpha_mode {
    Opaque => 0U
    Mask(_) => 0x40000000U
    Blend => 0x80000000U
  }
}

///|
fn material2d_bytes_bind_group_data(bytes : Bytes) -> String {
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
pub(all) enum Material2dBindingValue {
  Uniform(Bytes)
  Texture(
    @asset.Handle[@asset.Image]?,
    Material2dTextureSampleType,
    Material2dTextureViewDimension
  )
  Sampler(@asset.Handle[@asset.Image]?)
}

///|
pub(all) enum Material2dTextureSampleType {
  Float
  UInt
} derive(Eq, Debug)

///|
pub(all) enum Material2dTextureViewDimension {
  D2
  D2Array
} derive(Eq, Debug)

///|
fn material2d_texture_sample_type_key(
  sample_type : Material2dTextureSampleType,
) -> String {
  match sample_type {
    Material2dTextureSampleType::Float => "float"
    Material2dTextureSampleType::UInt => "uint"
  }
}

///|
fn material2d_texture_view_dimension_key(
  view_dimension : Material2dTextureViewDimension,
) -> String {
  match view_dimension {
    Material2dTextureViewDimension::D2 => "2d"
    Material2dTextureViewDimension::D2Array => "2d_array"
  }
}

///|
pub struct Material2dBinding {
  binding : Int
  value : Material2dBindingValue
}

///|
pub fn Material2dBinding::uniform(
  binding : Int,
  bytes : Bytes,
) -> Material2dBinding {
  Material2dBinding::{ binding, value: Uniform(bytes) }
}

///|
pub fn Material2dBinding::texture(
  binding : Int,
  texture : @asset.Handle[@asset.Image]?,
) -> Material2dBinding {
  Material2dBinding::{
    binding,
    value: Texture(
      texture,
      Material2dTextureSampleType::Float,
      Material2dTextureViewDimension::D2,
    ),
  }
}

///|
pub fn Material2dBinding::texture_with_layout(
  binding : Int,
  texture : @asset.Handle[@asset.Image]?,
  sample_type : Material2dTextureSampleType,
  view_dimension : Material2dTextureViewDimension,
) -> Material2dBinding {
  Material2dBinding::{
    binding,
    value: Texture(texture, sample_type, view_dimension),
  }
}

///|
pub fn Material2dBinding::sampler(
  binding : Int,
  texture : @asset.Handle[@asset.Image]?,
) -> Material2dBinding {
  Material2dBinding::{ binding, value: Sampler(texture) }
}

///|
fn material2d_binding_layout_kind_key(value : Material2dBindingValue) -> String {
  match value {
    Uniform(_) => "uniform"
    Texture(_, sample_type, view_dimension) =>
      "texture(\{material2d_texture_sample_type_key(sample_type)},\{material2d_texture_view_dimension_key(view_dimension)})"
    Sampler(_) => "sampler"
  }
}

///|
fn material2d_binding_data_key(value : Material2dBindingValue) -> String {
  match value {
    Uniform(bytes) => "uniform(\{material2d_bytes_bind_group_data(bytes)})"
    Texture(texture, sample_type, view_dimension) => {
      let texture_id = match texture {
        Some(value) => value.id().to_string()
        None => "none"
      }
      "texture(\{texture_id},\{material2d_texture_sample_type_key(sample_type)},\{material2d_texture_view_dimension_key(view_dimension)})"
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
pub struct Material2dBindGroup {
  bindings : Array[Material2dBinding]
}

///|
pub fn Material2dBindGroup::new(
  bindings : Array[Material2dBinding],
) -> Material2dBindGroup {
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
        "duplicate Material2d bind-group binding \{normalized[i].binding.to_string()}",
      )
    }
  }
  Material2dBindGroup::{ bindings: normalized }
}

///|
pub fn Material2dBindGroup::Material2dBindGroup() -> Material2dBindGroup {
  Material2dBindGroup::new([])
}

///|
pub fn Material2dBindGroup::binding(
  self : Material2dBindGroup,
  binding : Int,
) -> Material2dBinding? {
  for entry in self.bindings {
    if entry.binding == binding {
      return Some(entry)
    }
  }
  None
}

///|
pub fn Material2dBindGroup::layout_key(self : Material2dBindGroup) -> String {
  let mut data = ""
  for i in 0..<self.bindings.length() {
    let binding = self.bindings[i]
    if i > 0 {
      data = "\{data};"
    }
    data = "\{data}\{binding.binding.to_string()}:\{material2d_binding_layout_kind_key(binding.value)}"
  }
  data
}

///|
pub fn Material2dBindGroup::bind_group_data(
  self : Material2dBindGroup,
) -> String {
  let mut data = ""
  for i in 0..<self.bindings.length() {
    let binding = self.bindings[i]
    if i > 0 {
      data = "\{data};"
    }
    data = "\{data}\{binding.binding.to_string()}:\{material2d_binding_data_key(binding.value)}"
  }
  data
}

///|
pub struct Material2dKey[_] {
  mesh_key : Int
  bind_group_layout_key : String
  bind_group_data : String
}

///|
pub fn[M] Material2dKey::new(
  mesh_key : Int,
  bind_group_layout_key : String,
  bind_group_data : String,
) -> Material2dKey[M] {
  Material2dKey::{ mesh_key, bind_group_layout_key, bind_group_data }
}

///|
pub fn[M] Material2dKey::mesh_key(self : Material2dKey[M]) -> Int {
  self.mesh_key
}

///|
pub fn[M] Material2dKey::with_mesh_key(
  self : Material2dKey[M],
  mesh_key : Int,
) -> Material2dKey[M] {
  Material2dKey::{ ..self, mesh_key, }
}

///|
pub struct Material2dPipeline[_] {
  vertex_shader : String?
  fragment_shader : String?
}

///|
pub struct MeshMaterial2d[M] {
  handle : @asset.Handle[M]
}

///|
pub fn[M] MeshMaterial2d::new(material : @asset.Handle[M]) -> MeshMaterial2d[M] {
  MeshMaterial2d::{ handle: material }
}

///|
pub impl[M : Material2d] @ecs.Component for MeshMaterial2d[M] with fn component() {
  M::material2d_keys().mesh_material2d_component
}

///|
fn[M] encode_mesh_material2d(material : MeshMaterial2d[M]) -> Json {
  material.handle.to_json()
}

///|
fn[M] decode_mesh_material2d(json : Json) -> MeshMaterial2d[M] {
  let handle : @asset.Handle[M] = try! @json.from_json(json)
  MeshMaterial2d::new(handle)
}

///|
pub impl[M] ToJson for MeshMaterial2d[M] with fn to_json(self) {
  encode_mesh_material2d(self)
}

///|
pub impl[M] @json.FromJson for MeshMaterial2d[M] with fn from_json(json, _path) {
  decode_mesh_material2d(json)
}

///|
pub struct Material2dKeys[M] {
  mesh_material2d_component : @ecs.ComponentKey[MeshMaterial2d[M]]
  render_material2d_instances : @ecs.ResourceKey[RenderMaterial2dInstances[M]]
  material2d_pipeline : @ecs.ResourceKey[Material2dPipeline[M]]
  prepared_render_asset : @render.RenderAssetResourceKeys[PreparedMaterial2d[M]]
}

///|
pub fn[M] register_material2d_keys(
  material_debug_name : String,
) -> Material2dKeys[M] {
  Material2dKeys::{
    mesh_material2d_component: @ecs.register_component(
      debug_name="mgstudio_sprite_render::MeshMaterial2d<\{material_debug_name}>",
    ),
    render_material2d_instances: @ecs.register_resource(
      debug_name="mgstudio_sprite_render::RenderMaterial2dInstances<\{material_debug_name}>",
    ),
    material2d_pipeline: @ecs.register_resource(
      debug_name="mgstudio_sprite_render::Material2dPipeline<\{material_debug_name}>",
    ),
    prepared_render_asset: @render.register_render_asset_resource_keys(
      "mgstudio_sprite_render::PreparedMaterial2d<\{material_debug_name}>",
    ),
  }
}

///|
pub(open) trait Material2d {
  fn material2d_debug_name() -> String
  fn material2d_keys() -> Material2dKeys[Self]
  fn alpha_mode(self : Self) -> AlphaMode2d
  fn bind_group(self : Self) -> Material2dBindGroup
  fn specialize(
    descriptor : @render.RenderPipelineDescriptor,
    layout : @mesh.MeshVertexBufferLayout,
    key : Material2dKey[Self],
  ) -> @render.RenderPipelineDescriptor
}

///|
pub fn[M] Material2dPipeline::Material2dPipeline() -> Material2dPipeline[M] {
  Material2dPipeline::{ vertex_shader: None, fragment_shader: None }
}

///|
pub fn[M] Material2dPipeline::new(
  vertex_shader : String?,
  fragment_shader : String?,
) -> Material2dPipeline[M] {
  Material2dPipeline::{ vertex_shader, fragment_shader }
}

///|
pub fn[M : Material2d] Material2dPipeline::key_for(
  _ : Material2dPipeline[M],
  material : M,
  bind_group : Material2dBindGroup,
) -> Material2dKey[M] {
  Material2dKey::new(
    material2d_mesh_pipeline_key_bits(material.alpha_mode()),
    bind_group.layout_key(),
    bind_group.bind_group_data(),
  )
}

///|
fn material2d_push_material_bind_group_def(
  shader_defs : Array[@render.ShaderDefVal],
) -> Unit {
  shader_defs.push(@render.ShaderDefVal::UInt("MATERIAL_BIND_GROUP", 2U))
}

///|
pub fn[M : Material2d] Material2dPipeline::specialize(
  self : Material2dPipeline[M],
  descriptor : @render.RenderPipelineDescriptor,
  layout : @mesh.MeshVertexBufferLayout,
  key : Material2dKey[M],
) -> @render.RenderPipelineDescriptor {
  let vertex = descriptor.vertex
  material2d_push_material_bind_group_def(vertex.shader_defs)
  let descriptor = descriptor.with_vertex(
    @render.VertexState::new(
      match self.vertex_shader {
        Some(shader) => Some(shader)
        None => vertex.shader
      },
      vertex.shader_defs,
      vertex.entry_point,
      vertex.buffers,
    ),
  )
  let descriptor = match descriptor.fragment {
    Some(fragment) => {
      material2d_push_material_bind_group_def(fragment.shader_defs)
      descriptor.with_fragment(
        Some(
          @render.FragmentState::new(
            match self.fragment_shader {
              Some(shader) => Some(shader)
              None => fragment.shader
            },
            fragment.shader_defs,
            fragment.entry_point,
            fragment.targets,
          ),
        ),
      )
    }
    None => descriptor
  }
  M::specialize(descriptor, layout, key)
}

///|
fn material2d_base_pipeline_descriptor(
  primitive_topology : UInt,
) -> @render.RenderPipelineDescriptor {
  @render.RenderPipelineDescriptor::RenderPipelineDescriptor()
  .with_vertex(@render.VertexState::VertexState())
  .with_fragment(Some(@render.FragmentState::FragmentState()))
  .with_primitive(
    @render.PrimitiveState::PrimitiveState().with_topology(primitive_topology),
  )
}

///|
pub struct Material2dProperties {
  alpha_mode : AlphaMode2d
  mesh_pipeline_key_bits : Int
}

///|
pub fn Material2dProperties::new(
  alpha_mode : AlphaMode2d,
  mesh_pipeline_key_bits : Int,
) -> Material2dProperties {
  Material2dProperties::{ alpha_mode, mesh_pipeline_key_bits }
}

///|
pub struct PreparedMaterial2d[M] {
  source : @asset.Handle[M]
  bind_group : Material2dBindGroup
  host_bind_group : @render.HostMaterial2dBindGroup
  key : Material2dKey[M]
  properties : Material2dProperties
}

///|
pub impl[M : Material2d] @render.RenderAssetResource for PreparedMaterial2d[M] with fn render_asset_resource_debug_name() {
  "mgstudio_sprite_render::PreparedMaterial2d<\{M::material2d_debug_name()}>"
}

///|
pub impl[M : Material2d] @render.RenderAssetResource for PreparedMaterial2d[M] with fn render_asset_resource_keys() {
  M::material2d_keys().prepared_render_asset
}

///|
pub fn[M : Material2d] PreparedMaterial2d::from_material(
  source : @asset.Handle[M],
  material : M,
  pipeline : Material2dPipeline[M],
) -> PreparedMaterial2d[M] {
  let bind_group = material.bind_group()
  let host_bind_group = material2d_bind_group_to_host(bind_group)
  let key = pipeline.key_for(material, bind_group)
  PreparedMaterial2d::{
    source,
    bind_group,
    host_bind_group,
    key,
    properties: Material2dProperties::new(material.alpha_mode(), key.mesh_key),
  }
}

///|
pub fn[M] PreparedMaterial2d::prepared_handle(
  source : @asset.Handle[M],
) -> @asset.Handle[PreparedMaterial2d[M]] {
  @asset.Handle::new(source.id())
}

///|
pub impl[M : Material2d] @app.Resource for Material2dPipeline[M] with fn resource() {
  M::material2d_keys().material2d_pipeline
}

///|
pub fn[M : Material2d] material2d_runtime_type_name(
  _probe : @asset.Handle[M],
) -> String {
  ignore(_probe)
  "Material2d<\{M::material2d_debug_name()}>"
}

///|
pub fn mesh_alpha_mode_kind(alpha_mode : AlphaMode2d) -> Int {
  match alpha_mode {
    Opaque => 0
    Mask(_) => 1
    Blend => 2
  }
}

///|
pub fn mesh_alpha_cutoff(alpha_mode : AlphaMode2d) -> Float {
  match alpha_mode {
    Mask(cutoff) => cutoff
    _ => 0.5F
  }
}

///|
pub fn material2d_mesh_phase_from_properties(
  properties : Material2dProperties,
) -> Int? {
  match properties.alpha_mode {
    Blend => Some(1)
    Mask(_) | Opaque => Some(0)
  }
}

///|
test "material2d alpha mode pipeline key bits match Bevy" {
  debug_inspect(material2d_mesh_pipeline_key_bits(Opaque), content="0")
  debug_inspect(material2d_mesh_pipeline_key_bits(Mask(0.5F)), content="8")
  debug_inspect(material2d_mesh_pipeline_key_bits(Blend), content="4")
}

///|
test "material2d phase selection stays separate from pipeline key bits" {
  debug_inspect(
    material2d_mesh_phase_from_properties(
      Material2dProperties::new(
        Opaque,
        material2d_mesh_pipeline_key_bits(Opaque),
      ),
    ),
    content="Some(0)",
  )
  debug_inspect(
    material2d_mesh_phase_from_properties(
      Material2dProperties::new(
        Mask(0.5F),
        material2d_mesh_pipeline_key_bits(Mask(0.5F)),
      ),
    ),
    content="Some(0)",
  )
  debug_inspect(
    material2d_mesh_phase_from_properties(
      Material2dProperties::new(Blend, material2d_mesh_pipeline_key_bits(Blend)),
    ),
    content="Some(1)",
  )
}

///|
pub fn[M] prepared_material2d_alpha_phase(
  material : PreparedMaterial2d[M],
) -> Int? {
  material2d_mesh_phase_from_properties(material.properties)
}

///|
pub(all) struct RenderMaterial2dResolvedMaterial {
  phase : Int
  draw_mesh_fn : (@sprite_render_mesh2d_runtime.ExtractedMesh2d) -> Unit
}

///|
pub fn RenderMaterial2dResolvedMaterial::phase(
  self : RenderMaterial2dResolvedMaterial,
) -> Int {
  self.phase
}

///|
pub fn RenderMaterial2dResolvedMaterial::draw_mesh(
  self : RenderMaterial2dResolvedMaterial,
  mesh : @sprite_render_mesh2d_runtime.ExtractedMesh2d,
) -> Unit {
  (self.draw_mesh_fn)(mesh)
}

///|
fn[M : Material2d] render_material2d_resolved_material(
  material : PreparedMaterial2d[M],
  pipeline : Material2dPipeline[M],
) -> RenderMaterial2dResolvedMaterial? {
  guard prepared_material2d_alpha_phase(material) is Some(phase) else {
    return None
  }
  Some(RenderMaterial2dResolvedMaterial::{
    phase,
    draw_mesh_fn: fn(mesh) {
      draw_material2d_mesh_item_with_prepared_material(mesh, material, pipeline)
    },
  })
}

///|
pub(all) enum RenderMaterial2dResolvedSlot {
  Pending
  Resolved(RenderMaterial2dResolvedMaterial)
}

///|
pub struct RenderMaterial2dResolvedSlots {
  slots : @render_material.RenderMaterialEntitySlots[
    RenderMaterial2dResolvedSlot,
  ]
}

///|
pub fn RenderMaterial2dResolvedSlots::new() -> RenderMaterial2dResolvedSlots {
  let slots : @render_material.RenderMaterialEntitySlots[
    RenderMaterial2dResolvedSlot,
  ] = @render_material.RenderMaterialEntitySlots::new()
  RenderMaterial2dResolvedSlots::{ slots, }
}

///|
pub fn RenderMaterial2dResolvedSlots::get(
  self : RenderMaterial2dResolvedSlots,
  entity : @core.Entity,
) -> RenderMaterial2dResolvedSlot? {
  self.slots.get(entity)
}

///|
pub fn RenderMaterial2dResolvedSlots::set_pending(
  self : RenderMaterial2dResolvedSlots,
  entity : @core.Entity,
) -> Unit {
  self.slots.set(entity, RenderMaterial2dResolvedSlot::Pending)
}

///|
pub fn RenderMaterial2dResolvedSlots::set_resolved(
  self : RenderMaterial2dResolvedSlots,
  entity : @core.Entity,
  material : RenderMaterial2dResolvedMaterial,
) -> Unit {
  self.slots.set(entity, RenderMaterial2dResolvedSlot::Resolved(material))
}

///|
pub fn RenderMaterial2dResolvedSlots::remove(
  self : RenderMaterial2dResolvedSlots,
  entity : @core.Entity,
) -> Unit {
  self.slots.remove(entity)
}

///|
pub fn RenderMaterial2dResolvedSlots::contains(
  self : RenderMaterial2dResolvedSlots,
  entity : @core.Entity,
) -> Bool {
  self.slots.contains(entity)
}

///|
pub fn RenderMaterial2dResolvedSlots::is_pending(
  self : RenderMaterial2dResolvedSlots,
  entity : @core.Entity,
) -> Bool {
  match self.get(entity) {
    Some(Pending) => true
    _ => false
  }
}

///|
pub fn RenderMaterial2dResolvedSlots::is_resolved(
  self : RenderMaterial2dResolvedSlots,
  entity : @core.Entity,
) -> Bool {
  match self.get(entity) {
    Some(Resolved(_)) => true
    _ => false
  }
}

///|
let render_material2d_resolved_slots_key : @ecs.ResourceKey[
  RenderMaterial2dResolvedSlots,
] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::RenderMaterial2dResolvedSlots",
)

///|
pub impl @app.Resource for RenderMaterial2dResolvedSlots with fn resource() {
  render_material2d_resolved_slots_key
}

///|
fn ensure_render_material2d_resolved_slots_resource_in_world(
  world : @ecs.World,
) -> Unit {
  if world.get_resource(RenderMaterial2dResolvedSlots::resource()) is None {
    world.insert_resource(
      RenderMaterial2dResolvedSlots::resource(),
      RenderMaterial2dResolvedSlots::new(),
    )
  }
}

///|
pub fn render_material2d_resolved_slots_or_empty(
  world : @ecs.World,
) -> RenderMaterial2dResolvedSlots {
  match world.get_resource(RenderMaterial2dResolvedSlots::resource()) {
    Some(slots) => slots
    None => RenderMaterial2dResolvedSlots::new()
  }
}

///|
pub fn[M] prepared_material2d_get(
  prepared_assets : @render.RenderAssets[PreparedMaterial2d[M]],
  handle : @asset.Handle[PreparedMaterial2d[M]],
) -> PreparedMaterial2d[M]? {
  prepared_assets.get(handle.id())
}

///|
pub fn[M] prepared_material2d_handle_for_entity(
  entity : @core.Entity,
  material_instances : RenderMaterial2dInstances[M],
) -> @asset.Handle[PreparedMaterial2d[M]]? {
  guard material_instances.get(entity) is Some(material_handle) else {
    return None
  }
  Some(PreparedMaterial2d::prepared_handle(material_handle))
}

///|
pub fn material2d_binding_to_host(
  binding : Material2dBinding,
) -> @render.HostMaterial2dBinding {
  match binding.value {
    Uniform(bytes) =>
      @render.HostMaterial2dBinding::uniform(
        binding.binding.reinterpret_as_uint(),
        bytes,
      )
    Texture(texture, sample_type, view_dimension) =>
      @render.HostMaterial2dBinding::texture(
        binding.binding.reinterpret_as_uint(),
        match texture {
          Some(value) => value.id()
          None => -1
        },
        sample_type=match sample_type {
          Material2dTextureSampleType::Float =>
            @render.HostMaterial2dTextureSampleType::Float
          Material2dTextureSampleType::UInt =>
            @render.HostMaterial2dTextureSampleType::UInt
        },
        view_dimension=match view_dimension {
          Material2dTextureViewDimension::D2 =>
            @render.HostMaterial2dTextureViewDimension::D2
          Material2dTextureViewDimension::D2Array =>
            @render.HostMaterial2dTextureViewDimension::D2Array
        },
      )
    Sampler(texture) =>
      @render.HostMaterial2dBinding::sampler(
        binding.binding.reinterpret_as_uint(),
        match texture {
          Some(value) => value.id()
          None => -1
        },
      )
  }
}

///|
pub fn material2d_bind_group_to_host(
  bind_group : Material2dBindGroup,
) -> @render.HostMaterial2dBindGroup {
  let bindings : Array[@render.HostMaterial2dBinding] = []
  for binding in bind_group.bindings {
    bindings.push(material2d_binding_to_host(binding))
  }
  @render.HostMaterial2dBindGroup::new(bindings)
}

///|
pub fn[M : Material2d] prepared_material2d_assets_or_empty(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> @render.RenderAssets[PreparedMaterial2d[M]] {
  _probe |> ignore
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial2d[M]],
  ] = @render.RenderAssets::resource()
  let empty_prepared_assets : @render.RenderAssets[PreparedMaterial2d[M]] = @render.RenderAssets::new()
  if world.get_resource(prepared_assets_key) is Some(prepared_assets) {
    prepared_assets
  } else {
    empty_prepared_assets
  }
}

///|
pub fn[M : Material2d] render_material2d_instances_or_empty(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> RenderMaterial2dInstances[M] {
  _probe |> ignore
  let instances_key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  let empty_instances = RenderMaterial2dInstances::new()
  if world.get_resource(instances_key) is Some(instances) {
    instances
  } else {
    empty_instances
  }
}

///|
pub fn[M : Material2d] material2d_pipeline_or_default(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Material2dPipeline[M] {
  _probe |> ignore
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[M]] = Material2dPipeline::resource()
  let default_pipeline = Material2dPipeline::Material2dPipeline()
  if world.get_resource(pipeline_key) is Some(pipeline) {
    pipeline
  } else {
    default_pipeline
  }
}

///|
pub fn[M] render_material2d_instances_for_tests(
  instances_info : Array[(@core.Entity, @asset.Handle[M])],
) -> RenderMaterial2dInstances[M] {
  let instances = RenderMaterial2dInstances::new()
  for info in instances_info {
    let (entity, material) = info
    instances.set(entity, material)
  }
  instances
}

///|
fn material2d_shader_asset_paths(
  vertex_shader : String?,
  fragment_shader : String?,
) -> Array[String] {
  let paths : Array[String] = []
  if vertex_shader is Some(path) {
    paths.push(path)
  }
  if fragment_shader is Some(path) {
    let exists = paths.any(fn(value) { value == path })
    if !exists {
      paths.push(path)
    }
  }
  paths
}

///|
fn render2d_register_shader_source_asset(
  world : @ecs.World,
  path : String,
) -> Unit {
  if @shader.shader_path_is_wesl(path) {
    @shader_runtime_render.shader_register_wesl_runtime_source(world, path, []) catch {
      err =>
        abort(
          "failed to compile render2d wesl shader asset: \{path}: \{err.message()}",
        )
    }
    return
  }
  @shader_runtime_render.shader_register_wgsl_runtime_source(world, path)
}

///|
fn register_material2d_shader_sources(
  world : @ecs.World,
  shader_paths : Array[String],
) -> Unit {
  for path in shader_paths {
    render2d_register_shader_source_asset(world, path)
  }
}

///|
pub struct Material2dPlugin[M] {
  vertex_shader : String?
  fragment_shader : String?
  asset_init : (() -> M)?
}

///|
pub fn[M] Material2dPlugin::Material2dPlugin() -> Material2dPlugin[M] {
  Material2dPlugin::{
    vertex_shader: None,
    fragment_shader: None,
    asset_init: None,
  }
}

///|
pub fn[M] Material2dPlugin::with_vertex_shader(
  self : Material2dPlugin[M],
  path : String,
) -> Material2dPlugin[M] {
  Material2dPlugin::{ ..self, vertex_shader: Some(path) }
}

///|
pub fn[M] Material2dPlugin::with_fragment_shader(
  self : Material2dPlugin[M],
  path : String,
) -> Material2dPlugin[M] {
  Material2dPlugin::{ ..self, fragment_shader: Some(path) }
}

///|
pub fn[M] Material2dPlugin::with_asset_init(
  self : Material2dPlugin[M],
  init : () -> M,
) -> Material2dPlugin[M] {
  Material2dPlugin::{ ..self, asset_init: Some(init) }
}

///|
pub impl[M : Material2d + @asset.Asset] @app.Plugin for Material2dPlugin[M] with fn build(
  self,
  app,
) {
  material2d_plugin_build(app, self)
}

///|
pub impl[M : Material2d + @asset.Asset] @app.Plugin for Material2dPlugin[M] with fn name(
  _self,
) {
  "mgstudio.sprite_render.Material2dPlugin<\{M::asset_debug_name()}>"
}

///|
fn[M] material2d_pipeline_resource_from_plugin(
  plugin : Material2dPlugin[M],
) -> Material2dPipeline[M] {
  Material2dPipeline::new(plugin.vertex_shader, plugin.fragment_shader)
}

///|
fn[M : Material2d] ensure_prepared_material2d_assets_resource_in_world(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial2d[M]],
  ] = @render.RenderAssets::resource()
  if world.get_resource(prepared_assets_key) is None {
    world.insert_resource(prepared_assets_key, @render.RenderAssets::new())
  }
}

///|
fn[M : Material2d] ensure_material2d_pipeline_resource_in_world(
  world : @ecs.World,
  pipeline : Material2dPipeline[M],
) -> Unit {
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[M]] = Material2dPipeline::resource()
  if world.get_resource(pipeline_key) is None {
    world.insert_resource(pipeline_key, pipeline)
  }
}

///|
fn[M : Material2d] ensure_render_material2d_instances_resource_in_world(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  let key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  if world.get_resource(key) is None {
    world.insert_resource(key, RenderMaterial2dInstances::new())
  }
}

///|
fn[M : Material2d + @asset.Asset] material2d_plugin_build(
  app : @app.App[@ecs.World],
  plugin : Material2dPlugin[M],
) -> @app.App[@ecs.World] {
  let probe : @asset.Handle[M] = @asset.Handle::new(0)
  let shader_paths = material2d_shader_asset_paths(
    plugin.vertex_shader,
    plugin.fragment_shader,
  )
  let pipeline = material2d_pipeline_resource_from_plugin(plugin)
  let configured = match plugin.asset_init {
    Some(init) => @asset.init_asset(app, init)
    None =>
      abort(
        "Material2dPlugin requires with_asset_init(fn() { ... }) because MoonBit cannot call init_asset with explicit generic parameters",
      )
  }
  let configured = @render.with_render_app(configured, fn(render_app) {
    let render_world = render_app.world()
    ensure_prepared_material2d_assets_resource_in_world(render_world, probe)
    ensure_material2d_pipeline_resource_in_world(render_world, pipeline)
    ensure_render_material2d_instances_resource_in_world(render_world, probe)
    ensure_render_material2d_resolved_slots_resource_in_world(render_world)
    let stage = @render.render_schedule_stage()
    @render.configure_base_render_sets(render_app)
    .add_systems(
      stage,
      @app.system(fn(world : @ecs.World) {
        extract_material2d_mesh_instances_system(world, probe)
      }).in_set(@sprite_render_schedule.render2d_set_extract_materials),
    )
    .add_systems(
      stage,
      @app.system(fn(world : @ecs.World) {
        prepare_material2d_assets_system(world, probe)
      }).in_set(@sprite_render_schedule.render2d_set_prepare_materials),
    )
    .configure_set(stage, @render.render_system_set_extract_commands, before=[
      @sprite_render_schedule.render2d_set_extract_materials,
    ])
    .configure_set(stage, @render.render_system_set_queue_meshes, before=[
      @sprite_render_schedule.render2d_set_prepare_materials,
    ])
  })
  if shader_paths.length() == 0 {
    configured
  } else {
    configured.add_startup_system(fn(world : @ecs.World) {
      register_material2d_shader_sources(world, shader_paths)
    })
  }
}

///|
pub fn[M] material2d_plugin(
  plugin : Material2dPlugin[M],
) -> Material2dPlugin[M] {
  plugin
}

///|
pub fn[M] prepared_material2d_handle_for_mesh(
  mesh : @sprite_render_mesh2d_runtime.ExtractedMesh2d,
  material_instances : RenderMaterial2dInstances[M],
) -> @asset.Handle[PreparedMaterial2d[M]]? {
  prepared_material2d_handle_for_entity(
    mesh.entity.main_entity,
    material_instances,
  )
}

///|
pub fn[M : Material2d] draw_material2d_mesh_item(
  mesh : @sprite_render_mesh2d_runtime.ExtractedMesh2d,
  prepared_assets : @render.RenderAssets[PreparedMaterial2d[M]],
  material_instances : RenderMaterial2dInstances[M],
  pipeline : Material2dPipeline[M],
) -> Unit {
  guard prepared_material2d_handle_for_mesh(mesh, material_instances)
    is Some(material_handle) else {
    return
  }
  guard prepared_material2d_get(prepared_assets, material_handle)
    is Some(material) else {
    return
  }
  draw_material2d_mesh_item_with_prepared_material(mesh, material, pipeline)
}

///|
pub fn[M : Material2d] draw_material2d_mesh_item_with_prepared_material(
  mesh : @sprite_render_mesh2d_runtime.ExtractedMesh2d,
  material : PreparedMaterial2d[M],
  pipeline : Material2dPipeline[M],
) -> Unit {
  let payload = mesh.payload
  guard @render.host_gpu_mesh2d_vertex_layout(mesh_id=payload.mesh_id)
    is Some(mesh_vertex_layout) else {
    return
  }
  guard @render.host_gpu_mesh_info(payload.mesh_id) is Some(mesh_info) else {
    return
  }
  let pipeline_descriptor = pipeline.specialize(
    material2d_base_pipeline_descriptor(mesh_info.primitive_topology()),
    mesh_vertex_layout,
    material.key.with_mesh_key(
      material.key.mesh_key |
      material2d_mesh_pipeline_key_bits_for_host_mesh(mesh_info),
    ),
  )
  let transform = payload.transform
  @render.host_gpu_draw_mesh_material(
    mesh_id=payload.mesh_id,
    x=transform.translation.x,
    y=transform.translation.y,
    rotation=transform.rotation_z(),
    scale_x=transform.scale.x,
    scale_y=transform.scale.y,
    alpha_mode_kind=mesh_alpha_mode_kind(material.properties.alpha_mode),
    material_bind_group=material.host_bind_group,
    vertex_shader_path=pipeline.vertex_shader,
    fragment_shader_path=pipeline.fragment_shader,
    pipeline_descriptor=Some(pipeline_descriptor),
  )
}

///|
fn[M : Material2d] extract_material2d_mesh_instances_system(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> Unit {
  probe |> ignore
  let source_world = @render.render_source_world(world)
  let material_key : @ecs.ComponentKey[MeshMaterial2d[M]] = MeshMaterial2d::component()
  let key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  let prepared_assets = prepared_material2d_assets_or_empty(world, probe)
  let pipeline = material2d_pipeline_or_default(world, probe)
  guard world.get_resource_mut(key) is Some(instances) else { return }
  instances.modify(fn(value) {
    value.clear()
    match world.get_resource_mut(RenderMaterial2dResolvedSlots::resource()) {
      Some(resolved_slots) =>
        resolved_slots.modify(fn(slots) {
          source_world.for_each_component(material_key, fn(entity, material) {
            value.set(entity, material.handle)
            let prepared_handle = PreparedMaterial2d::prepared_handle(
              material.handle,
            )
            match prepared_material2d_get(prepared_assets, prepared_handle) {
              Some(prepared) =>
                match render_material2d_resolved_material(prepared, pipeline) {
                  Some(resolved) => slots.set_resolved(entity, resolved)
                  None => slots.set_pending(entity)
                }
              None => slots.set_pending(entity)
            }
          })
        })
      None =>
        source_world.for_each_component(material_key, fn(entity, material) {
          value.set(entity, material.handle)
        })
    }
  })
}

///|
fn[M : Material2d + @asset.Asset] prepare_material2d_assets_system(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  _probe |> ignore
  let source_world = @render.render_source_world(world)
  let instances_key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  let source_assets_key : @ecs.ResourceKey[@asset.Assets[M]] = @asset.assets_resource_key()
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[M]] = Material2dPipeline::resource()
  let prepared_assets_key : @ecs.ResourceKey[
    @render.RenderAssets[PreparedMaterial2d[M]],
  ] = @render.RenderAssets::resource()
  guard world.get_resource(instances_key) is Some(instances) else { return }
  guard source_world.get_resource(source_assets_key) is Some(source_assets) else {
    return
  }
  guard world.get_resource(pipeline_key) is Some(pipeline) else { return }
  register_material2d_shader_sources(
    source_world,
    material2d_shader_asset_paths(
      pipeline.vertex_shader,
      pipeline.fragment_shader,
    ),
  )
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
    let prepared_id = material_handle.id()
    let prepared_material = PreparedMaterial2d::from_material(
      material_handle, material, pipeline,
    )
    prepared_assets.modify(fn(value) {
      value.insert(prepared_id, prepared_material)
    })
    match render_material2d_resolved_material(prepared_material, pipeline) {
      Some(resolved) =>
        match
          world.get_resource_mut(RenderMaterial2dResolvedSlots::resource()) {
          Some(resolved_slots) =>
            resolved_slots.modify(fn(slots) {
              for entity_key, instance_material_handle in instances.instances {
                if instance_material_handle.id() == material_id {
                  slots.set_resolved(
                    @core.Entity::new(entity_key.0, entity_key.1),
                    resolved,
                  )
                }
              }
            })
          None => ()
        }
      None =>
        match
          world.get_resource_mut(RenderMaterial2dResolvedSlots::resource()) {
          Some(resolved_slots) =>
            resolved_slots.modify(fn(slots) {
              for entity_key, instance_material_handle in instances.instances {
                if instance_material_handle.id() == material_id {
                  slots.set_pending(
                    @core.Entity::new(entity_key.0, entity_key.1),
                  )
                }
              }
            })
          None => ()
        }
    }
  }
}

///|
pub fn material2d_resolved_phase_for_draw(
  slots : RenderMaterial2dResolvedSlots,
  mesh : @sprite_render_mesh2d_runtime.ExtractedMesh2d,
) -> Int? {
  match slots.get(mesh.entity.main_entity) {
    Some(Resolved(material)) => Some(material.phase())
    _ => None
  }
}

///|
pub fn draw_resolved_material2d_mesh_item(
  slots : RenderMaterial2dResolvedSlots,
  mesh : @sprite_render_mesh2d_runtime.ExtractedMesh2d,
) -> Unit {
  match slots.get(mesh.entity.main_entity) {
    Some(Resolved(material)) => material.draw_mesh(mesh)
    _ => ()
  }
}
