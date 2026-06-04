///|
type AlphaMode2d = @sprite_render_mesh2d_material.AlphaMode2d

///|
type RenderMaterial2dInstances[M] = @sprite_render_mesh2d_material.RenderMaterial2dInstances[
  M,
]

///|
type Material2dTextureSampleType = @sprite_render_mesh2d_material.Material2dTextureSampleType

///|
type Material2dTextureViewDimension = @sprite_render_mesh2d_material.Material2dTextureViewDimension

///|
type Material2dBinding = @sprite_render_mesh2d_material.Material2dBinding

///|
type Material2dBindGroup = @sprite_render_mesh2d_material.Material2dBindGroup

///|
type Material2dPipeline[M] = @sprite_render_mesh2d_material.Material2dPipeline[
  M,
]

///|
type Material2dKeys[M] = @sprite_render_mesh2d_material.Material2dKeys[M]

///|
type PreparedMaterial2d[M] = @sprite_render_mesh2d_material.PreparedMaterial2d[
  M,
]

///|
type MeshMaterial2d[M] = @sprite_render_mesh2d_material.MeshMaterial2d[M]

///|
fn[M] register_material2d_keys(
  material_debug_name : String,
) -> Material2dKeys[M] {
  @sprite_render_mesh2d_material.register_material2d_keys(material_debug_name)
}

///|
fn material2d_u32le_pack(xs : Array[UInt]) -> Bytes {
  @sprite_render_mesh2d_material.material2d_u32le_pack(xs)
}

///|
fn material2d_f32_bits(x : Float) -> UInt {
  @sprite_render_mesh2d_material.material2d_f32_bits(x)
}

///|
fn material2d_alpha_mode_kind_bits(alpha_mode : AlphaMode2d) -> UInt {
  @sprite_render_mesh2d_material.material2d_alpha_mode_kind_bits(alpha_mode)
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] material2d_runtime_type_name(
  probe : @asset.Handle[M],
) -> String {
  @sprite_render_mesh2d_material.material2d_runtime_type_name(probe)
}

///|
fn mesh_alpha_mode_kind(alpha_mode : AlphaMode2d) -> Int {
  @sprite_render_mesh2d_material.mesh_alpha_mode_kind(alpha_mode)
}

///|
fn mesh_alpha_cutoff(alpha_mode : AlphaMode2d) -> Float {
  @sprite_render_mesh2d_material.mesh_alpha_cutoff(alpha_mode)
}

///|
fn[M] prepared_material2d_alpha_phase(material : PreparedMaterial2d[M]) -> Int? {
  @sprite_render_mesh2d_material.prepared_material2d_alpha_phase(material)
}

///|
fn[M] prepared_material2d_get(
  prepared_assets : @render.RenderAssets[PreparedMaterial2d[M]],
  handle : @asset.Handle[PreparedMaterial2d[M]],
) -> PreparedMaterial2d[M]? {
  @sprite_render_mesh2d_material.prepared_material2d_get(
    prepared_assets, handle,
  )
}

///|
fn[M] prepared_material2d_handle_for_entity(
  entity : @core.Entity,
  material_instances : RenderMaterial2dInstances[M],
) -> @asset.Handle[PreparedMaterial2d[M]]? {
  @sprite_render_mesh2d_material.prepared_material2d_handle_for_entity(
    entity, material_instances,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] prepared_material2d_assets_or_empty(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> @render.RenderAssets[PreparedMaterial2d[M]] {
  @sprite_render_mesh2d_material.prepared_material2d_assets_or_empty(
    world, probe,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] render_material2d_instances_or_empty(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> RenderMaterial2dInstances[M] {
  @sprite_render_mesh2d_material.render_material2d_instances_or_empty(
    world, probe,
  )
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] material2d_pipeline_or_default(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> Material2dPipeline[M] {
  @sprite_render_mesh2d_material.material2d_pipeline_or_default(world, probe)
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
pub impl[M : @sprite_render_mesh2d_material.Material2d + @asset.Asset] @app.Plugin for Material2dPlugin[
  M,
] with fn build(self, app) {
  material2d_plugin_build(app, self)
}

///|
pub impl[M : @sprite_render_mesh2d_material.Material2d + @asset.Asset] @app.Plugin for Material2dPlugin[
  M,
] with fn name(_self) {
  "mgstudio.sprite.Material2dPlugin<\{M::asset_debug_name()}>"
}

///|
fn[M] material2d_pipeline_resource_from_plugin(
  plugin : Material2dPlugin[M],
) -> Material2dPipeline[M] {
  Material2dPipeline::new(plugin.vertex_shader, plugin.fragment_shader)
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] ensure_prepared_material2d_assets_resource_in_world(
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
fn[M : @sprite_render_mesh2d_material.Material2d] ensure_material2d_pipeline_resource_in_world(
  world : @ecs.World,
  pipeline : Material2dPipeline[M],
) -> Unit {
  let pipeline_key : @ecs.ResourceKey[Material2dPipeline[M]] = Material2dPipeline::resource()
  if world.get_resource(pipeline_key) is None {
    world.insert_resource(pipeline_key, pipeline)
  }
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] ensure_render_material2d_instances_resource_in_world(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  let key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  if world.get_resource(key) is None {
    world.insert_resource(key, RenderMaterial2dInstances::new())
  }
}

///|
fn ensure_material2d_runtime_registry_resource_in_world(
  world : @ecs.World,
) -> Unit {
  if world.get_resource(Material2dRuntimeRegistry::resource()) is None {
    world.insert_resource(
      Material2dRuntimeRegistry::resource(),
      Material2dRuntimeRegistry::new(),
    )
  }
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d + @asset.Asset] material2d_plugin_build(
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
    ensure_material2d_runtime_registry_resource_in_world(render_world)
    register_material2d_runtime_world(render_world, probe)
    let stage = @render.render_schedule_stage()
    @render.configure_base_render_sets(render_app)
    .add_systems(
      stage,
      @app.system(fn(world : @ecs.World) {
        extract_material2d_mesh_instances_system(world, probe)
      }).in_set(render2d_set_extract_materials),
    )
    .add_systems(
      stage,
      @app.system(fn(world : @ecs.World) {
        prepare_material2d_assets_system(world, probe)
      }).in_set(render2d_set_prepare_materials),
    )
    .configure_set(stage, @render.render_system_set_extract_commands, before=[
      render2d_set_extract_materials,
    ])
    .configure_set(stage, @render.render_system_set_queue_meshes, before=[
      render2d_set_prepare_materials,
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
fn[M] draw_material2d_mesh_item(
  mesh : ExtractedMesh2d,
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
pub impl @app.Resource for Material2dRuntimeRegistry with fn resource() {
  material2d_runtime_registry_key
}

///|
let material2d_runtime_registry_key : @ecs.ResourceKey[
  Material2dRuntimeRegistry,
] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::Material2dRuntimeRegistry",
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
  if world.get_resource(Material2dRuntimeRegistry::resource()) is Some(registry) {
    registry
  } else {
    Material2dRuntimeRegistry::new()
  }
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d] material2d_runtime_entry(
  probe : @asset.Handle[M],
) -> Material2dRuntimeEntry {
  let type_name = material2d_runtime_type_name(probe)
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
fn[M : @sprite_render_mesh2d_material.Material2d] register_material2d_runtime_world(
  world : @ecs.World,
  probe : @asset.Handle[M],
) -> Unit {
  ensure_material2d_runtime_registry_resource_in_world(world)
  if world.get_resource_mut(Material2dRuntimeRegistry::resource())
    is Some(registry) {
    registry.modify(fn(value) {
      value.register(material2d_runtime_entry(probe))
    })
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
fn[M : @sprite_render_mesh2d_material.Material2d] extract_material2d_mesh_instances_system(
  world : @ecs.World,
  _probe : @asset.Handle[M],
) -> Unit {
  _probe |> ignore
  let source_world = @render.render_source_world(world)
  let material_key : @ecs.ComponentKey[MeshMaterial2d[M]] = MeshMaterial2d::component()
  let key : @ecs.ResourceKey[RenderMaterial2dInstances[M]] = RenderMaterial2dInstances::resource()
  guard world.get_resource_mut(key) is Some(instances) else { return }
  instances.modify(fn(value) {
    value.clear()
    source_world.for_each_component(material_key, fn(entity, material) {
      value.set(entity, material.handle)
    })
  })
}

///|
fn[M : @sprite_render_mesh2d_material.Material2d + @asset.Asset] prepare_material2d_assets_system(
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
    prepared_assets.modify(fn(value) {
      value.insert(
        prepared_id,
        PreparedMaterial2d::from_material(material_handle, material, pipeline),
      )
    })
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
