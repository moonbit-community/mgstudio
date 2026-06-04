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
fn material2d_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

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
  self.instances.contains(material2d_entity_key(entity))
}

///|
pub fn[M] RenderMaterial2dInstances::get(
  self : RenderMaterial2dInstances[M],
  entity : @core.Entity,
) -> @asset.Handle[M]? {
  self.instances.get(material2d_entity_key(entity))
}

///|
pub fn[M] RenderMaterial2dInstances::set(
  self : RenderMaterial2dInstances[M],
  entity : @core.Entity,
  material : @asset.Handle[M],
) -> Unit {
  self.instances.set(material2d_entity_key(entity), material)
}

///|
pub fn[M] RenderMaterial2dInstances::remove(
  self : RenderMaterial2dInstances[M],
  entity : @core.Entity,
) -> Unit {
  self.instances.remove(material2d_entity_key(entity)) |> ignore
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
const MATERIAL2D_PIPELINE_KEY_OPAQUE : Int = 1

///|
const MATERIAL2D_PIPELINE_KEY_ALPHA_MASK : Int = 2

///|
const MATERIAL2D_PIPELINE_KEY_BLEND : Int = 4

///|
fn material2d_mesh_pipeline_key_bits(alpha_mode : AlphaMode2d) -> Int {
  match alpha_mode {
    Opaque => MATERIAL2D_PIPELINE_KEY_OPAQUE
    Mask(_) => MATERIAL2D_PIPELINE_KEY_ALPHA_MASK
    Blend => MATERIAL2D_PIPELINE_KEY_BLEND
  }
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
  let key_bits = properties.mesh_pipeline_key_bits
  if (key_bits & MATERIAL2D_PIPELINE_KEY_BLEND) != 0 {
    Some(1)
  } else if (key_bits & MATERIAL2D_PIPELINE_KEY_ALPHA_MASK) != 0 {
    Some(0)
  } else {
    Some(0)
  }
}

///|
pub fn[M] prepared_material2d_alpha_phase(
  material : PreparedMaterial2d[M],
) -> Int? {
  material2d_mesh_phase_from_properties(material.properties)
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
