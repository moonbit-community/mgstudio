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
let render_material2d_instances_resource_registry : Ref[
  @hashmap.HashMap[String, @any.Any],
] = Ref::new(@hashmap.HashMap::new())

///|
pub fn[M] RenderMaterial2dInstances::new() -> RenderMaterial2dInstances[M] {
  RenderMaterial2dInstances::{ instances: @hashmap.HashMap::new() }
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
fn[M] registered_render_material2d_instances_resource_key() -> @ecs.ResourceKey[
  RenderMaterial2dInstances[M],
] {
  let probe : RenderMaterial2dInstances[M] = RenderMaterial2dInstances::new()
  let type_name = @any.of(probe).type_name()
  match render_material2d_instances_resource_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "render material2d instances resource registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = @ecs.register_resource(
        debug_name="bevy_sprite_render::\{type_name}",
      )
      render_material2d_instances_resource_registry.val.set(
        type_name,
        @any.of(key),
      )
      key
    }
  }
}

///|
pub fn[M] render_material2d_instances_resource_key_of(
  _probe : @asset.Handle[M],
) -> @ecs.ResourceKey[RenderMaterial2dInstances[M]] {
  registered_render_material2d_instances_resource_key()
}

///|
pub impl[M] @app.Resource for RenderMaterial2dInstances[M] with resource() {
  registered_render_material2d_instances_resource_key()
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
fn material2d_u32le_pack(xs : Array[UInt]) -> Bytes {
  let len = xs.length()
  Bytes::makei(len * 4, i => {
    let word = xs[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn material2d_f32_bits(x : Float) -> UInt {
  x.reinterpret_as_uint()
}

///|
fn material2d_alpha_mode_kind_bits(alpha_mode : AlphaMode2d) -> UInt {
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
  Texture(@asset.Handle[@asset.Image]?)
  Sampler(@asset.Handle[@asset.Image]?)
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
  Material2dBinding::{ binding, value: Texture(texture) }
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
    Texture(_) => "texture"
    Sampler(_) => "sampler"
  }
}

///|
fn material2d_binding_data_key(value : Material2dBindingValue) -> String {
  match value {
    Uniform(bytes) => "uniform(\{material2d_bytes_bind_group_data(bytes)})"
    Texture(texture) => {
      let texture_id = match texture {
        Some(value) => value.id().to_string()
        None => "none"
      }
      "texture(\{texture_id})"
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
pub fn Material2dBindGroup::default() -> Material2dBindGroup {
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
pub(open) trait Material2d {
  alpha_mode(self : Self) -> AlphaMode2d
  bind_group(self : Self) -> Material2dBindGroup
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
pub fn[M] Material2dPipeline::default() -> Material2dPipeline[M] {
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
fn[M] init_material2d_assets_resource(
  app : @app.App[@ecs.World],
  _probe : @asset.Handle[M],
) -> @app.App[@ecs.World] {
  app.init_resource(fn() {
    let assets : @asset.Assets[M] = @asset.Assets::new()
    assets
  })
}

///|
let material2d_pipeline_resource_registry : Ref[
  @hashmap.HashMap[String, @any.Any],
] = Ref::new(@hashmap.HashMap::new())

///|
fn[M] registered_material2d_pipeline_resource_key() -> @ecs.ResourceKey[
  Material2dPipeline[M],
] {
  let probe : Material2dPipeline[M] = Material2dPipeline::default()
  let type_name = @any.of(probe).type_name()
  match material2d_pipeline_resource_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "material2d pipeline resource registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[Material2dPipeline[M]] = @ecs.register_resource(
        debug_name="bevy_sprite_render::\{type_name}",
      )
      material2d_pipeline_resource_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub impl[M] @app.Resource for Material2dPipeline[M] with resource() {
  registered_material2d_pipeline_resource_key()
}

///|
fn[M] material2d_type_name(_probe : @asset.Handle[M]) -> String {
  @any.of(_probe).type_name()
}

///|
pub fn[M] material2d_runtime_type_name(_probe : @asset.Handle[M]) -> String {
  material2d_type_name(_probe)
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
  let asset_server = render2d_asset_server_or_abort(world)
  let blob = asset_server.load_bytes(path)
  guard @asset.asset_blob_read_text(blob) is Some(source) else {
    abort("failed to load render2d shader asset text: \{path}")
  }
  @render.register_wgsl_source(path, source)
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
pub struct Material2dPlugin[_] {
  vertex_shader : String?
  fragment_shader : String?
}

///|
pub fn[M] Material2dPlugin::default() -> Material2dPlugin[M] {
  Material2dPlugin::{ vertex_shader: None, fragment_shader: None }
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
fn[M] material2d_pipeline_resource_from_plugin(
  plugin : Material2dPlugin[M],
) -> Material2dPipeline[M] {
  Material2dPipeline::new(plugin.vertex_shader, plugin.fragment_shader)
}

///|
fn[M] ensure_prepared_material2d_assets_resource_in_world(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  let prepared_assets_key : @ecs.ResourceKey[
    @asset.Assets[PreparedMaterial2d[M]],
  ] = @asset.assets_resource_key()
  if (try! world.get_resource(prepared_assets_key)) is None {
    world.insert_resource(prepared_assets_key, @asset.Assets::new())
  }
}

///|
fn[M] ensure_material2d_pipeline_resource_in_world(
  world : @ecs.World,
  pipeline : Material2dPipeline[M],
) -> Unit {
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[M]] = Material2dPipeline::resource()
  if (try! world.get_resource(pipeline_key)) is None {
    world.insert_resource(pipeline_key, pipeline)
  }
}

///|
fn[M] ensure_render_material2d_instances_resource_in_world(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  let key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  if (try! world.get_resource(key)) is None {
    world.insert_resource(key, RenderMaterial2dInstances::new())
  }
}

///|
fn ensure_material2d_runtime_registry_resource_in_world(
  world : @ecs.World,
) -> Unit {
  if (try! world.get_resource(Material2dRuntimeRegistry::resource())) is None {
    world.insert_resource(
      Material2dRuntimeRegistry::resource(),
      Material2dRuntimeRegistry::new(),
    )
  }
}

///|
pub fn[M : Material2d] material2d_plugin(
  plugin : Material2dPlugin[M],
) -> @app.Plugin[@ecs.World] {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    let probe : @asset.Handle[M] = @asset.Handle::new(0)
    let shader_paths = material2d_shader_asset_paths(
      plugin.vertex_shader,
      plugin.fragment_shader,
    )
    let pipeline = material2d_pipeline_resource_from_plugin(plugin)
    let configured = init_material2d_assets_resource(app, probe)
    let configured = @render.with_render_app(configured, fn(render_app) {
      let render_world = render_app.world()
      ensure_prepared_material2d_assets_resource_in_world(render_world, probe)
      ensure_material2d_pipeline_resource_in_world(render_world, pipeline)
      ensure_render_material2d_instances_resource_in_world(render_world, probe)
      ensure_material2d_runtime_registry_resource_in_world(render_world)
      register_material2d_runtime_world(render_world, probe)
      render_app
      .add_systems(
        @app.PostUpdate,
        @app.system(fn(world : @ecs.World) {
          extract_material2d_mesh_instances_system(world, probe)
        }).in_set(render2d_set_extract_materials),
      )
      .add_systems(
        @app.PostUpdate,
        @app.system(fn(world : @ecs.World) {
          prepare_material2d_assets_system(world, probe)
        }).in_set(render2d_set_prepare_materials),
      )
    })
    if shader_paths.length() == 0 {
      configured
    } else {
      configured.add_startup_system(fn(world : @ecs.World) {
        register_material2d_shader_sources(world, shader_paths)
      })
    }
  }
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
fn mesh_alpha_mode_kind(alpha_mode : AlphaMode2d) -> Int {
  match alpha_mode {
    Opaque => 0
    Mask(_) => 1
    Blend => 2
  }
}

///|
fn mesh_alpha_cutoff(alpha_mode : AlphaMode2d) -> Float {
  match alpha_mode {
    Mask(cutoff) => cutoff
    _ => 0.5F
  }
}

///|
fn material2d_mesh_phase_from_properties(
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
fn[M] prepared_material2d_alpha_phase(material : PreparedMaterial2d[M]) -> Int? {
  material2d_mesh_phase_from_properties(material.properties)
}

///|
fn[M] prepared_material2d_get(
  prepared_assets : @asset.Assets[PreparedMaterial2d[M]],
  handle : @asset.Handle[PreparedMaterial2d[M]],
) -> PreparedMaterial2d[M]? {
  prepared_assets.get(handle)
}

///|
fn[M] prepared_material2d_handle_for_entity(
  entity : @core.Entity,
  material_instances : RenderMaterial2dInstances[M],
) -> @asset.Handle[PreparedMaterial2d[M]]? {
  guard material_instances.get(entity) is Some(material_handle) else {
    return None
  }
  Some(PreparedMaterial2d::prepared_handle(material_handle))
}

///|
fn[M] prepared_material2d_handle_for_mesh(
  mesh : ExtractedMesh2d,
  material_instances : RenderMaterial2dInstances[M],
) -> @asset.Handle[PreparedMaterial2d[M]]? {
  prepared_material2d_handle_for_entity(
    mesh.entity.main_entity,
    material_instances,
  )
}

///|
fn material2d_binding_to_host(
  binding : Material2dBinding,
) -> @render.HostMaterial2dBinding {
  match binding.value {
    Uniform(bytes) =>
      @render.HostMaterial2dBinding::uniform(
        binding.binding.reinterpret_as_uint(),
        bytes,
      )
    Texture(texture) =>
      @render.HostMaterial2dBinding::texture(
        binding.binding.reinterpret_as_uint(),
        match texture {
          Some(value) => value.id()
          None => -1
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
fn material2d_bind_group_to_host(
  bind_group : Material2dBindGroup,
) -> @render.HostMaterial2dBindGroup {
  let bindings : Array[@render.HostMaterial2dBinding] = []
  for binding in bind_group.bindings {
    bindings.push(material2d_binding_to_host(binding))
  }
  @render.HostMaterial2dBindGroup::new(bindings)
}

///|
fn[M] prepared_material2d_assets_or_empty(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> @asset.Assets[PreparedMaterial2d[M]] {
  _probe |> ignore
  let prepared_assets_key : @ecs.ResourceKey[
    @asset.Assets[PreparedMaterial2d[M]],
  ] = @asset.assets_resource_key()
  let empty_prepared_assets : @asset.Assets[PreparedMaterial2d[M]] = @asset.Assets::new()
  if (try! world.get_resource_ref(prepared_assets_key))
    is Some(prepared_assets_ref) {
    prepared_assets_ref.val
  } else {
    empty_prepared_assets
  }
}

///|
fn[M] render_material2d_instances_or_empty(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> RenderMaterial2dInstances[M] {
  _probe |> ignore
  let instances_key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  let empty_instances = RenderMaterial2dInstances::new()
  if (try! world.get_resource_ref(instances_key)) is Some(instances_ref) {
    instances_ref.val
  } else {
    empty_instances
  }
}

///|
fn[M] material2d_pipeline_or_default(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Material2dPipeline[M] {
  _probe |> ignore
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[M]] = Material2dPipeline::resource()
  let default_pipeline = Material2dPipeline::default()
  if (try! world.get_resource(pipeline_key)) is Some(pipeline) {
    pipeline
  } else {
    default_pipeline
  }
}

///|
fn[M] draw_material2d_mesh_item(
  mesh : ExtractedMesh2d,
  prepared_assets : @asset.Assets[PreparedMaterial2d[M]],
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
fn[M] draw_material2d_mesh_item_with_prepared_material(
  mesh : ExtractedMesh2d,
  material : PreparedMaterial2d[M],
  pipeline : Material2dPipeline[M],
) -> Unit {
  let payload = mesh.payload
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
  )
}

///|
priv struct Material2dRuntimeEntry {
  type_name : String
  contains_source_material_fn : (@ecs.World, @core.Entity) -> Bool
  mesh_phase_for_draw_fn : (@ecs.World, ExtractedMesh2d) -> Int?
  draw_mesh_fn : (@ecs.World, ExtractedMesh2d) -> Unit
}

///|
struct Material2dRuntimeRegistry {
  entries : Array[Material2dRuntimeEntry]
}

///|
pub fn Material2dRuntimeRegistry::new() -> Material2dRuntimeRegistry {
  Material2dRuntimeRegistry::{ entries: [] }
}

///|
pub impl @app.Resource for Material2dRuntimeRegistry with resource() {
  material2d_runtime_registry_key
}

///|
let material2d_runtime_registry_key : @ecs.ResourceKey[
  Material2dRuntimeRegistry,
] = @ecs.register_resource(
  debug_name="bevy_sprite_render::Material2dRuntimeRegistry",
)

///|
pub fn Material2dRuntimeRegistry::contains_type_name(
  self : Material2dRuntimeRegistry,
  type_name : String,
) -> Bool {
  self.entries.any(fn(entry) { entry.type_name == type_name })
}

///|
pub fn Material2dRuntimeRegistry::entry_count(
  self : Material2dRuntimeRegistry,
) -> Int {
  self.entries.length()
}

///|
fn Material2dRuntimeRegistry::register(
  self : Material2dRuntimeRegistry,
  entry : Material2dRuntimeEntry,
) -> Unit {
  if self.contains_type_name(entry.type_name) {
    return
  }
  self.entries.push(entry)
}

///|
fn material2d_runtime_registry_or_empty(
  world : @ecs.World,
) -> Material2dRuntimeRegistry {
  if (try! world.get_resource(Material2dRuntimeRegistry::resource()))
    is Some(registry) {
    registry
  } else {
    Material2dRuntimeRegistry::new()
  }
}

///|
fn[M] material2d_runtime_entry(
  probe : @asset.Handle[M],
) -> Material2dRuntimeEntry {
  let type_name = material2d_type_name(probe)
  let material_key : @ecs.ComponentKey[MeshMaterial2d[M]] = MeshMaterial2d::component()
  let contains_source_material = fn(
    source_world : @ecs.World,
    entity : @core.Entity,
  ) -> Bool {
    (try! source_world.get_by_key(entity, material_key)) is Some(_)
  }
  Material2dRuntimeEntry::{
    type_name,
    contains_source_material_fn: contains_source_material,
    mesh_phase_for_draw_fn: fn(world, mesh) {
      let prepared_assets = prepared_material2d_assets_or_empty(world, probe)
      let material_instances = render_material2d_instances_or_empty(
        world, probe,
      )
      guard prepared_material2d_handle_for_mesh(mesh, material_instances)
        is Some(material_handle) else {
        return None
      }
      guard prepared_material2d_get(prepared_assets, material_handle)
        is Some(material) else {
        return None
      }
      prepared_material2d_alpha_phase(material)
    },
    draw_mesh_fn: fn(world, mesh) {
      let prepared_assets = prepared_material2d_assets_or_empty(world, probe)
      let material_instances = render_material2d_instances_or_empty(
        world, probe,
      )
      let pipeline = material2d_pipeline_or_default(world, probe)
      draw_material2d_mesh_item(
        mesh, prepared_assets, material_instances, pipeline,
      )
    },
  }
}

///|
fn[M] register_material2d_runtime_world(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> Unit {
  ensure_material2d_runtime_registry_resource_in_world(world)
  if (try! world.get_resource_ref_mut(Material2dRuntimeRegistry::resource()))
    is Some(registry_ref) {
    registry_ref.val.register(material2d_runtime_entry(probe))
  }
}

///|
fn material2d_runtime_registry_contains_entity(
  source_world : @ecs.World,
  registry : Material2dRuntimeRegistry,
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
fn draw_registered_material2d_mesh_item(
  world : @ecs.World,
  registry : Material2dRuntimeRegistry,
  runtime_index : Int,
  mesh : ExtractedMesh2d,
) -> Unit {
  guard runtime_index >= 0 && runtime_index < registry.entries.length() else {
    return
  }
  let entry = registry.entries[runtime_index]
  (entry.draw_mesh_fn)(world, mesh)
}

///|
fn[M] extract_material2d_mesh_instances_system(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  _probe |> ignore
  let source_world = @render.render_source_world(world)
  let material_key : @ecs.ComponentKey[MeshMaterial2d[M]] = MeshMaterial2d::component()
  let key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  guard (try! world.get_resource_ref_mut(key)) is Some(instances_ref) else {
    return
  }
  instances_ref.val.clear()
  source_world.for_each_component(material_key, fn(entity, material) {
    instances_ref.val.set(entity, material.handle)
  })
}

///|
fn[M : Material2d] prepare_material2d_assets_system(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  _probe |> ignore
  let source_world = @render.render_source_world(world)
  let instances_key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  let source_assets_key : @ecs.ResourceKey[@asset.Assets[M]] = @asset.assets_resource_key()
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[M]] = Material2dPipeline::resource()
  let prepared_assets_key : @ecs.ResourceKey[
    @asset.Assets[PreparedMaterial2d[M]],
  ] = @asset.assets_resource_key()
  guard (try! world.get_resource_ref(instances_key)) is Some(instances_ref) else {
    return
  }
  guard (try! source_world.get_resource_ref(source_assets_key))
    is Some(source_assets_ref) else {
    return
  }
  guard (try! world.get_resource(pipeline_key)) is Some(pipeline) else {
    return
  }
  guard (try! world.get_resource_ref_mut(prepared_assets_key))
    is Some(prepared_assets_ref) else {
    return
  }
  let prepared_ids : @hashmap.HashMap[Int, Bool] = @hashmap.HashMap::new()
  for _, material_handle in instances_ref.val.instances {
    let material_id = material_handle.id()
    if prepared_ids.contains(material_id) {
      continue
    }
    prepared_ids.set(material_id, true)
    guard source_assets_ref.val.get(material_handle) is Some(material) else {
      continue
    }
    let prepared_handle = PreparedMaterial2d::prepared_handle(material_handle)
    prepared_assets_ref.val.insert(
      prepared_handle,
      PreparedMaterial2d::from_material(material_handle, material, pipeline),
    )
    |> ignore
  }
}

///|
fn[M] render_material2d_instances_for_tests(
  instances_info : Array[(@core.Entity, @asset.Handle[M])],
) -> RenderMaterial2dInstances[M] {
  let instances = RenderMaterial2dInstances::new()
  for info in instances_info {
    let (entity, material) = info
    instances.set(entity, material)
  }
  instances
}
