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
/// Marker component aligned with Bevy's `Wireframe`.
///
/// Meshes with this marker render in wireframe regardless of
/// `WireframeConfig::global`.
pub struct Wireframe {} derive(ToJson, FromJson)

///|
pub fn Wireframe::Wireframe() -> Wireframe {
  Wireframe::{  }
}

///|
/// Marker component aligned with Bevy's `NoWireframe`.
///
/// Meshes with this marker never render in wireframe regardless of
/// `WireframeConfig::global`.
pub struct NoWireframe {} derive(ToJson, FromJson)

///|
pub fn NoWireframe::NoWireframe() -> NoWireframe {
  NoWireframe::{  }
}

///|
/// Per-mesh wireframe color aligned with Bevy's `WireframeColor`.
pub struct WireframeColor {
  color : @color.Color
} derive(ToJson, FromJson)

///|
pub fn WireframeColor::WireframeColor() -> WireframeColor {
  WireframeColor::{ color: @color.Color::white() }
}

///|
pub fn WireframeColor::new(color : @color.Color) -> WireframeColor {
  WireframeColor::{ color, }
}

///|
pub fn WireframeColor::with_color(
  self : WireframeColor,
  color : @color.Color,
) -> WireframeColor {
  self |> ignore
  WireframeColor::{ color, }
}

///|
/// Sets the line width of the wireframe in screen-space pixels.
pub struct WireframeLineWidth {
  width : Float
} derive(ToJson, FromJson)

///|
pub fn WireframeLineWidth::WireframeLineWidth() -> WireframeLineWidth {
  WireframeLineWidth::{ width: 1.0F }
}

///|
pub fn WireframeLineWidth::new(width : Float) -> WireframeLineWidth {
  WireframeLineWidth::{ width, }
}

///|
pub fn WireframeLineWidth::with_width(
  self : WireframeLineWidth,
  width : Float,
) -> WireframeLineWidth {
  self |> ignore
  WireframeLineWidth::{ width, }
}

///|
/// Controls whether wireframe edges follow triangle or quad topology.
pub(all) enum WireframeTopology {
  Triangles
  Quads
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn WireframeTopology::default() -> WireframeTopology {
  Triangles
}

///|
pub struct WireframeMaterial {
  color : @color.Color
  line_width : Float
  topology : WireframeTopology
} derive(ToJson, FromJson)

///|
pub fn WireframeMaterial::WireframeMaterial() -> WireframeMaterial {
  WireframeMaterial::{
    color: @color.Color::white(),
    line_width: 1.0F,
    topology: WireframeTopology::default(),
  }
}

///|
pub fn WireframeMaterial::new(
  color : @color.Color,
  line_width : Float,
  topology : WireframeTopology,
) -> WireframeMaterial {
  WireframeMaterial::{ color, line_width, topology }
}

///|
pub impl @asset.Asset for WireframeMaterial with fn asset_debug_name() {
  "mgstudio_pbr::WireframeMaterial"
}

///|
pub impl @asset.Asset for WireframeMaterial with fn asset_as_image(_self) {
  None
}

///|
let wireframe_material_asset_resource_keys : @asset.AssetResourceKeys[
  WireframeMaterial,
] = @asset.register_asset_resource_keys(WireframeMaterial::asset_debug_name())

///|
pub impl @asset.Asset for WireframeMaterial with fn asset_resource_keys() {
  wireframe_material_asset_resource_keys
}

///|
pub struct Mesh3dWireframe {
  material : @asset.Handle[WireframeMaterial]
} derive(ToJson, FromJson)

///|
pub fn Mesh3dWireframe::new(
  material : @asset.Handle[WireframeMaterial],
) -> Mesh3dWireframe {
  Mesh3dWireframe::{ material, }
}

///|
pub fn Mesh3dWireframe::material(
  self : Mesh3dWireframe,
) -> @asset.Handle[WireframeMaterial] {
  self.material
}

///|
pub struct RenderWireframeMaterial {
  color : @color.Color
  line_width : Float
  topology : WireframeTopology
} derive(ToJson, FromJson)

///|
pub fn RenderWireframeMaterial::from_material(
  material : WireframeMaterial,
) -> RenderWireframeMaterial {
  RenderWireframeMaterial::{
    color: material.color,
    line_width: material.line_width,
    topology: material.topology,
  }
}

///|
priv struct GlobalWireframeMaterial {
  handle : @asset.Handle[WireframeMaterial]
}

///|
let global_wireframe_material_key : @ecs.ResourceKey[GlobalWireframeMaterial] = @ecs.register_resource(
  debug_name="mgstudio.render3d.global_wireframe_material",
)

///|
impl @app.Resource for GlobalWireframeMaterial with fn resource() {
  global_wireframe_material_key
}

///|
pub struct WireframeEntitiesNeedingSpecialization {
  changed : Array[@core.Entity]
  removed : Array[@core.Entity]
}

///|
pub fn WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization() -> WireframeEntitiesNeedingSpecialization {
  WireframeEntitiesNeedingSpecialization::{ changed: [], removed: [] }
}

///|
pub impl @app.Resource for WireframeEntitiesNeedingSpecialization with fn resource() {
  ecs_key_wireframe_entities_needing_specialization
}

///|
pub struct WireframeConfig {
  global : Bool
  default_color : @color.Color
  default_line_width : Float
  default_topology : WireframeTopology
} derive(ToJson, FromJson)

///|
pub fn WireframeConfig::WireframeConfig() -> WireframeConfig {
  WireframeConfig::{
    global: false,
    default_color: @color.Color::white(),
    default_line_width: 1.0F,
    default_topology: WireframeTopology::default(),
  }
}

///|
pub fn WireframeConfig::new(
  global : Bool,
  default_color : @color.Color,
  default_line_width? : Float = 1.0F,
  default_topology? : WireframeTopology = WireframeTopology::default(),
) -> WireframeConfig {
  WireframeConfig::{
    global,
    default_color,
    default_line_width,
    default_topology,
  }
}

///|
pub fn WireframeConfig::with_global(
  self : WireframeConfig,
  global : Bool,
) -> WireframeConfig {
  WireframeConfig::{ ..self, global, }
}

///|
pub fn WireframeConfig::with_default_color(
  self : WireframeConfig,
  default_color : @color.Color,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_color, }
}

///|
pub fn WireframeConfig::with_default_line_width(
  self : WireframeConfig,
  default_line_width : Float,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_line_width, }
}

///|
pub fn WireframeConfig::with_default_topology(
  self : WireframeConfig,
  default_topology : WireframeTopology,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_topology, }
}

///|
pub impl @app.Resource for WireframeConfig with fn resource() {
  ecs_key_wireframe_config
}

///|
const WIREFRAME_PLUGIN_NAME : String = "mgstudio.pbr.WireframePlugin"

///|
pub struct WireframePlugin {}

///|
pub fn WireframePlugin::WireframePlugin() -> WireframePlugin {
  WireframePlugin::{  }
}

///|
pub impl @app.Plugin for WireframePlugin with fn name(_self) {
  WIREFRAME_PLUGIN_NAME
}

///|
pub impl @app.Plugin for WireframePlugin with fn build(_self, app) {
  wireframe_plugin(app)
}

///|
fn init_wireframe_resources(world : @ecs.World) -> Unit {
  let wireframe_config = get_wireframe_config_resource(world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(WireframeConfig::WireframeConfig())
  }
  if world.get_resource(WireframeEntitiesNeedingSpecialization::resource())
    is None {
    world.insert_resource(
      WireframeEntitiesNeedingSpecialization::resource(),
      WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization(),
    )
  }
}

///|
fn wireframe_material_assets_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[@asset.Assets[WireframeMaterial]] {
  let key : @ecs.ResourceKey[@asset.Assets[WireframeMaterial]] = @asset.assets_resource_key()
  match world.get_resource_mut(key) {
    Some(assets) => assets
    None =>
      abort(
        "Assets<WireframeMaterial> is missing; WireframePlugin must initialize the asset store before wireframe systems run",
      )
  }
}

///|
fn global_wireframe_material_or_abort(
  world : @ecs.World,
) -> GlobalWireframeMaterial {
  match world.get_resource(GlobalWireframeMaterial::resource()) {
    Some(material) => material
    None =>
      abort(
        "GlobalWireframeMaterial is missing; WireframePlugin startup must run before wireframe material systems",
      )
  }
}

///|
fn setup_global_wireframe_material(world : @ecs.World) -> Unit {
  let config = match world.get_resource(WireframeConfig::resource()) {
    Some(config) => config
    None => abort("WireframeConfig is missing during global wireframe setup")
  }
  let handle = wireframe_material_assets_mut_or_abort(world).modify(fn(assets) {
    assets.add(
      WireframeMaterial::new(
        config.default_color,
        config.default_line_width,
        config.default_topology,
      ),
    )
  })
  world.insert_resource(GlobalWireframeMaterial::resource(), GlobalWireframeMaterial::{
    handle,
  })
}

///|
fn wireframe_startup_system(world : @ecs.World) -> Unit {
  init_wireframe_resources(world)
  setup_global_wireframe_material(world)
}

///|
fn get_wireframe_material(
  maybe_color : WireframeColor?,
  maybe_width : WireframeLineWidth?,
  maybe_topology : WireframeTopology?,
  materials : @asset.Assets[WireframeMaterial],
  global_material : GlobalWireframeMaterial,
  config : WireframeConfig,
) -> @asset.Handle[WireframeMaterial] {
  if maybe_color is Some(_) ||
    maybe_width is Some(_) ||
    maybe_topology is Some(_) {
    let color = match maybe_color {
      Some(value) => value.color
      None => config.default_color
    }
    let line_width = match maybe_width {
      Some(value) => value.width
      None => config.default_line_width
    }
    let topology = match maybe_topology {
      Some(value) => value
      None => config.default_topology
    }
    materials.add(WireframeMaterial::new(color, line_width, topology))
  } else {
    global_material.handle
  }
}

///|
fn[T] wireframe_has_component(
  world : @ecs.World,
  entity : @core.Entity,
  key : @ecs.ComponentKey[T],
) -> Bool {
  if !world.is_alive(entity) {
    false
  } else {
    (try! world.get_by_key(entity, key)) is Some(_)
  }
}

///|
fn mark_wireframe_specialization_changed(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  if world.get_resource_mut(WireframeEntitiesNeedingSpecialization::resource())
    is Some(needs) {
    needs.modify(fn(value) { value.changed.push(entity) })
  }
}

///|
fn mark_wireframe_specialization_removed(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  if world.get_resource_mut(WireframeEntitiesNeedingSpecialization::resource())
    is Some(needs) {
    needs.modify(fn(value) { value.removed.push(entity) })
  }
}

///|
fn set_mesh3d_wireframe_component(
  world : @ecs.World,
  entity : @core.Entity,
  handle : @asset.Handle[WireframeMaterial],
) -> Unit {
  guard world.is_alive(entity) else { return }
  let current = try! world.get_by_key(entity, ecs_key_mesh3d_wireframe)
  let changed = match current {
    Some(value) => value.material().id() != handle.id()
    None => true
  }
  try! world.set_by_key(
    entity,
    ecs_key_mesh3d_wireframe,
    Mesh3dWireframe::new(handle),
  )
  if changed {
    mark_wireframe_specialization_changed(world, entity)
  }
}

///|
fn remove_mesh3d_wireframe_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Unit {
  guard wireframe_has_component(world, entity, ecs_key_mesh3d_wireframe) else {
    return
  }
  try! (world.remove_by_key(entity, ecs_key_mesh3d_wireframe) |> ignore)
  mark_wireframe_specialization_removed(world, entity)
}

///|
fn wireframe_material_handle_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
  config : WireframeConfig,
  global_material : GlobalWireframeMaterial,
) -> @asset.Handle[WireframeMaterial] {
  let maybe_color = try! world.get_by_key(entity, ecs_key_wireframe_color)
  let maybe_width = try! world.get_by_key(entity, ecs_key_wireframe_line_width)
  let maybe_topology = try! world.get_by_key(entity, ecs_key_wireframe_topology)
  wireframe_material_assets_mut_or_abort(world).modify(fn(materials) {
    get_wireframe_material(
      maybe_color, maybe_width, maybe_topology, materials, global_material, config,
    )
  })
}

///|
fn refresh_explicit_wireframe_material(
  world : @ecs.World,
  entity : @core.Entity,
  config : WireframeConfig,
  global_material : GlobalWireframeMaterial,
) -> Unit {
  guard wireframe_has_component(world, entity, ecs_key_wireframe) else {
    return
  }
  guard wireframe_has_component(world, entity, ecs_key_mesh3d_wireframe) else {
    return
  }
  let handle = wireframe_material_handle_for_entity(
    world, entity, config, global_material,
  )
  set_mesh3d_wireframe_component(world, entity, handle)
}

///|
fn wireframe_config_changed(world : @ecs.World) -> Unit {
  let ticks = world.get_tick_context().ticks()
  guard world.is_resource_changed(WireframeConfig::resource(), ticks) else {
    return
  }
  guard world.get_resource(WireframeConfig::resource()) is Some(config) else {
    return
  }
  let global_material = global_wireframe_material_or_abort(world)
  let global_updated = wireframe_material_assets_mut_or_abort(world).modify(fn(
    materials,
  ) {
    materials.set(
      global_material.handle,
      WireframeMaterial::new(
        config.default_color,
        config.default_line_width,
        config.default_topology,
      ),
    )
  })
  if !global_updated {
    abort(
      "Global WireframeMaterial handle is missing from Assets<WireframeMaterial>",
    )
  }
  world.for_each_component(ecs_key_wireframe, fn(entity, _marker) {
    refresh_explicit_wireframe_material(world, entity, config, global_material)
  })
}

///|
fn wireframe_color_changed(world : @ecs.World) -> Unit {
  guard world.get_resource(WireframeConfig::resource()) is Some(config) else {
    return
  }
  let global_material = global_wireframe_material_or_abort(world)
  let ticks = world.get_tick_context().ticks()
  for entity in world.changed_components(ecs_key_wireframe_color, ticks).read() {
    refresh_explicit_wireframe_material(world, entity, config, global_material)
  }
}

///|
fn wireframe_line_width_changed(world : @ecs.World) -> Unit {
  guard world.get_resource(WireframeConfig::resource()) is Some(config) else {
    return
  }
  let global_material = global_wireframe_material_or_abort(world)
  let ticks = world.get_tick_context().ticks()
  for
    entity in world
    .changed_components(ecs_key_wireframe_line_width, ticks)
    .read() {
    refresh_explicit_wireframe_material(world, entity, config, global_material)
  }
}

///|
fn wireframe_topology_changed(world : @ecs.World) -> Unit {
  guard world.get_resource(WireframeConfig::resource()) is Some(config) else {
    return
  }
  let global_material = global_wireframe_material_or_abort(world)
  let ticks = world.get_tick_context().ticks()
  for
    entity in world.changed_components(ecs_key_wireframe_topology, ticks).read() {
    refresh_explicit_wireframe_material(world, entity, config, global_material)
  }
}

///|
fn apply_wireframe_material(world : @ecs.World) -> Unit {
  let config = match world.get_resource(WireframeConfig::resource()) {
    Some(config) => config
    None => return
  }
  let global_material = global_wireframe_material_or_abort(world)

  for
    entity in world
    .removed_components(ecs_key_wireframe, world.get_tick_context().ticks())
    .read() {
    remove_mesh3d_wireframe_component(world, entity)
  }

  world.for_each_component(ecs_key_no_wireframe, fn(entity, _marker) {
    remove_mesh3d_wireframe_component(world, entity)
  })

  world.for_each_component(ecs_key_wireframe, fn(entity, _marker) {
    guard !wireframe_has_component(world, entity, ecs_key_mesh3d_wireframe) else {
      return
    }
    let handle = wireframe_material_handle_for_entity(
      world, entity, config, global_material,
    )
    set_mesh3d_wireframe_component(world, entity, handle)
  })
}

///|
fn apply_global_wireframe_material(world : @ecs.World) -> Unit {
  let config = match world.get_resource(WireframeConfig::resource()) {
    Some(config) => config
    None => return
  }
  let global_material = global_wireframe_material_or_abort(world)

  world.for_each_component(ecs_key_mesh3d, fn(entity, _mesh3d) {
    guard !wireframe_has_component(world, entity, ecs_key_wireframe) else {
      return
    }
    guard !wireframe_has_component(world, entity, ecs_key_no_wireframe) else {
      remove_mesh3d_wireframe_component(world, entity)
      return
    }

    if config.global {
      guard !wireframe_has_component(world, entity, ecs_key_mesh3d_wireframe) else {
        return
      }
      let handle = wireframe_material_handle_for_entity(
        world, entity, config, global_material,
      )
      set_mesh3d_wireframe_component(world, entity, handle)
    } else {
      remove_mesh3d_wireframe_component(world, entity)
    }
  })
}

///|
fn wireframe_material_application_system(world : @ecs.World) -> Unit {
  wireframe_config_changed(world)
  wireframe_color_changed(world)
  wireframe_line_width_changed(world)
  wireframe_topology_changed(world)
  apply_wireframe_material(world)
  apply_global_wireframe_material(world)
}

///|
fn render_wireframe_instances_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[RenderWireframeInstances] {
  if world.get_resource(RenderWireframeInstances::resource()) is None {
    world.insert_resource(
      RenderWireframeInstances::resource(),
      RenderWireframeInstances::RenderWireframeInstances(),
    )
  }
  match world.get_resource_mut(RenderWireframeInstances::resource()) {
    Some(instances) => instances
    None => abort("Missing RenderWireframeInstances resource")
  }
}

///|
fn wireframe_collect_changed_mesh_entities(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Map[UInt64, @core.Entity] {
  let changed : Map[UInt64, @core.Entity] = {}
  for
    entity in source_world
    .changed_components(@visibility.ecs_key_view_visibility, system_ticks)
    .read() {
    changed.set(entity.to_bits(), entity)
  }
  for
    entity in source_world
    .changed_components(ecs_key_mesh3d_wireframe, system_ticks)
    .read() {
    changed.set(entity.to_bits(), entity)
  }
  changed
}

///|
fn extract_wireframe_materials_from_world(
  source_world : @ecs.World,
  material_instances : RenderWireframeInstances,
  system_ticks : @core.SystemTicks,
) -> Unit {
  let changed_entities = wireframe_collect_changed_mesh_entities(
    source_world, system_ticks,
  )
  for _, entity in changed_entities {
    match
      (
        try! source_world.get_by_key(
          entity, @visibility.ecs_key_view_visibility,
        ),
        try! source_world.get_by_key(entity, ecs_key_mesh3d_wireframe),
      ) {
      (Some(view_visibility), Some(material)) =>
        if view_visibility.get() {
          material_instances.insert(entity, material.material().id())
        } else {
          ignore(material_instances.remove(entity))
        }
      _ => ()
    }
  }

  for
    entity in source_world
    .removed_components(@visibility.ecs_key_view_visibility, system_ticks)
    .read() {
    if !changed_entities.contains(entity.to_bits()) {
      ignore(material_instances.remove(entity))
    }
  }
  for
    entity in source_world
    .removed_components(ecs_key_mesh3d_wireframe, system_ticks)
    .read() {
    if !changed_entities.contains(entity.to_bits()) {
      ignore(material_instances.remove(entity))
    }
  }
}

///|
fn extract_wireframe_materials_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let system_ticks = @app.current_system_ticks()
  render_wireframe_instances_mut_or_init(world).modify(fn(material_instances) {
    extract_wireframe_materials_from_world(
      source_world, material_instances, system_ticks,
    )
  })
}

///|
fn[T] wireframe_init_render_resource_if_missing(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
  init : () -> T,
) -> Unit {
  if world.get_resource(key) is None {
    world.insert_resource(key, init())
  }
}

///|
fn configure_wireframe_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  wireframe_init_render_resource_if_missing(
    world,
    Wireframe3dPipeline::resource(),
    fn() { Wireframe3dPipeline::new() },
  )
  wireframe_init_render_resource_if_missing(
    world,
    SpecializedWireframePipelineCache::resource(),
    fn() {
      SpecializedWireframePipelineCache::SpecializedWireframePipelineCache()
    },
  )
  wireframe_init_render_resource_if_missing(
    world,
    RenderWireframeInstances::resource(),
    fn() { RenderWireframeInstances::RenderWireframeInstances() },
  )
  wireframe_init_render_resource_if_missing(
    world,
    WireframeWideBindGroups::resource(),
    fn() { WireframeWideBindGroups::WireframeWideBindGroups() },
  )
  wireframe_init_render_resource_if_missing(
    world,
    PendingWireframeQueues::resource(),
    fn() { PendingWireframeQueues::PendingWireframeQueues() },
  )
  wireframe_init_render_resource_if_missing(
    world,
    Wireframe3dDrawFunctions::resource(),
    fn() { Wireframe3dDrawFunctions::Wireframe3dDrawFunctions() },
  )
  sub_app.add_systems(
    @render.render_schedule_stage(),
    @app.system(extract_wireframe_materials_system).in_set(render3d_set_extract),
  )
}

///|
pub fn wireframe_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  wireframe_plugin_with(app, WireframePlugin::WireframePlugin())
}

///|
pub fn wireframe_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : WireframePlugin,
) -> @app.App[@ecs.World] {
  @asset.init_asset(app, fn() { WireframeMaterial::WireframeMaterial() })
  .add_startup_system(wireframe_startup_system)
  .add_systems_world(@app.PostUpdate, wireframe_material_application_system)
  |> fn(next) {
    @render.try_with_render_app(next, configure_wireframe_render_sub_app)
  }
}

///|
priv struct WireframeMeshCacheEntry {
  source_mesh_handle_id : Int
  wireframe_mesh_id : Int
}

///|
priv struct Render3dWireframeMeshCache {
  mut entries : Array[WireframeMeshCacheEntry]
}

///|
let render3d_wireframe_mesh_cache_key : @ecs.ResourceKey[
  Render3dWireframeMeshCache,
] = @ecs.register_resource(debug_name="mgstudio.render3d.wireframe_mesh_cache")

///|
impl @app.Resource for Render3dWireframeMeshCache with fn resource() {
  render3d_wireframe_mesh_cache_key
}

///|
fn render3d_wireframe_mesh_cache_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[Render3dWireframeMeshCache] {
  if world.get_resource(Render3dWireframeMeshCache::resource()) is None {
    world.insert_resource(Render3dWireframeMeshCache::resource(), {
      entries: [],
    })
  }
  match world.get_resource_mut(Render3dWireframeMeshCache::resource()) {
    Some(cache) => cache
    None => abort("Missing Render3dWireframeMeshCache resource")
  }
}

///|
fn render3d_wireframe_mesh_cache_get(
  world : @ecs.World,
  source_mesh_handle_id : Int,
) -> Int? {
  let cache = render3d_wireframe_mesh_cache_mut_or_init(world)
  for item in cache.peek().entries {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      return Some(item.wireframe_mesh_id)
    }
  }
  None
}

///|
fn render3d_wireframe_mesh_cache_set(
  world : @ecs.World,
  source_mesh_handle_id : Int,
  wireframe_mesh_id : Int,
) -> Unit {
  let cache = render3d_wireframe_mesh_cache_mut_or_init(world)
  let next : Array[WireframeMeshCacheEntry] = []
  let mut replaced = false
  for item in cache.peek().entries {
    if item.source_mesh_handle_id == source_mesh_handle_id {
      if !replaced {
        next.push({ source_mesh_handle_id, wireframe_mesh_id })
        replaced = true
      }
    } else {
      next.push(item)
    }
  }
  if !replaced {
    next.push({ source_mesh_handle_id, wireframe_mesh_id })
  }
  cache.modify(fn(value) { value.entries = next })
}

///|
fn render3d_upload_wireframe_geometry(geometry : @mesh.Mesh3dGeometry) -> Int? {
  guard geometry.flatten_interleaved_xyz_normal_uv_rgba_joints_weights_vertices()
    is Some(vertices_double) else {
    return None
  }
  let vertices = vertices_double.map(fn(value) { Float::from_double(value) })
  let mesh_id = @render.host_gpu_create_mesh3d_xyznuvrgba(
    vertices_xyznuvrgba=vertices,
    primitive_topology=geometry.primitive_topology().to_int(),
  )
  if mesh_id <= 0 {
    None
  } else {
    Some(mesh_id)
  }
}

///|
fn render3d_wireframe_mesh_id(
  world : @ecs.World,
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Int? {
  let source_mesh_handle_id = mesh_handle.id()
  if render3d_wireframe_mesh_cache_get(world, source_mesh_handle_id)
    is Some(mesh_id) {
    return Some(mesh_id)
  }
  let source_mesh = match @sprite.render_mesh_asset_get(mesh_handle) {
    Some(mesh_asset) => mesh_asset
    None => return None
  }
  match source_mesh.geometry {
    @mesh.MeshGeometry::Geometry3d(geometry3d) =>
      match geometry3d.primitive_topology() {
        @mesh.Mesh3dPrimitiveTopology::TriangleList =>
          match geometry3d.to_wireframe_line_list() {
            Some(wireframe_geometry) => {
              guard render3d_upload_wireframe_geometry(wireframe_geometry)
                is Some(wireframe_mesh_id) else {
                return None
              }
              render3d_wireframe_mesh_cache_set(
                world, source_mesh_handle_id, wireframe_mesh_id,
              )
              Some(wireframe_mesh_id)
            }
            None => None
          }
        @mesh.Mesh3dPrimitiveTopology::LineList => {
          guard render3d_upload_wireframe_geometry(geometry3d) is Some(mesh_id) else {
            return None
          }
          render3d_wireframe_mesh_cache_set(
            world, source_mesh_handle_id, mesh_id,
          )
          Some(mesh_id)
        }
        @mesh.Mesh3dPrimitiveTopology::LineStrip => {
          guard render3d_upload_wireframe_geometry(geometry3d) is Some(mesh_id) else {
            return None
          }
          render3d_wireframe_mesh_cache_set(
            world, source_mesh_handle_id, mesh_id,
          )
          Some(mesh_id)
        }
      }
    _ => None
  }
}

///|
fn render3d_mesh_should_draw_wireframe(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> Bool {
  ignore(wireframe_config)
  !mesh.payload.has_no_wireframe &&
  mesh.payload.wireframe_asset_id is Some(_) &&
  mesh.payload.wireframe_material is Some(_)
}

///|
fn render3d_mesh_wireframe_color(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> @color.Color {
  if mesh.payload.wireframe_color is Some(color_component) {
    color_component.color
  } else if mesh.payload.wireframe_material is Some(material) {
    material.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    @color.Color::white()
  }
}

///|
fn render3d_mesh_wireframe_line_width(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> Float {
  if mesh.payload.wireframe_line_width is Some(width_component) {
    width_component.width
  } else if mesh.payload.wireframe_material is Some(material) {
    material.line_width
  } else if wireframe_config is Some(config) {
    config.default_line_width
  } else {
    1.0F
  }
}

///|
fn render3d_mesh_wireframe_topology(
  mesh : ExtractedMesh3d,
  wireframe_config : WireframeConfig?,
) -> WireframeTopology {
  if mesh.payload.wireframe_topology is Some(topology) {
    topology
  } else if mesh.payload.wireframe_material is Some(material) {
    material.topology
  } else if wireframe_config is Some(config) {
    config.default_topology
  } else {
    WireframeTopology::default()
  }
}
