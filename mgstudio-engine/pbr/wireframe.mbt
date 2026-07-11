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
priv struct WireframeMaterialAssetEventCursor {
  mut cursor : @ecs.MessageCursor[@asset.AssetEvent[WireframeMaterial]]
}

///|
priv struct WireframeMeshAssetEventCursor {
  mut cursor : @ecs.MessageCursor[@asset.AssetEvent[@mesh.Mesh]]
}

///|
fn WireframeMaterialAssetEventCursor::WireframeMaterialAssetEventCursor() -> WireframeMaterialAssetEventCursor {
  WireframeMaterialAssetEventCursor::{
    cursor: @ecs.MessageCursor::MessageCursor(),
  }
}

///|
fn WireframeMeshAssetEventCursor::WireframeMeshAssetEventCursor() -> WireframeMeshAssetEventCursor {
  WireframeMeshAssetEventCursor::{ cursor: @ecs.MessageCursor::MessageCursor() }
}

///|
let wireframe_material_asset_event_cursor_key : @ecs.ResourceKey[
  WireframeMaterialAssetEventCursor,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::WireframeMaterialAssetEventCursor",
)

///|
let wireframe_mesh_asset_event_cursor_key : @ecs.ResourceKey[
  WireframeMeshAssetEventCursor,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::WireframeMeshAssetEventCursor",
)

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
pub fn WireframeEntitiesNeedingSpecialization::changed_len(
  self : WireframeEntitiesNeedingSpecialization,
) -> Int {
  self.changed.length()
}

///|
pub fn WireframeEntitiesNeedingSpecialization::removed_len(
  self : WireframeEntitiesNeedingSpecialization,
) -> Int {
  self.removed.length()
}

///|
pub fn WireframeEntitiesNeedingSpecialization::changed_contains(
  self : WireframeEntitiesNeedingSpecialization,
  entity : @core.Entity,
) -> Bool {
  self.changed.contains(entity)
}

///|
pub fn WireframeEntitiesNeedingSpecialization::removed_contains(
  self : WireframeEntitiesNeedingSpecialization,
  entity : @core.Entity,
) -> Bool {
  self.removed.contains(entity)
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
let wireframe_dirty_specialization_set_clear : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.dirty_specialization.clear",
)

///|
let wireframe_dirty_specialization_set_check_for_changes : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.dirty_specialization.check_for_changes",
)

///|
let wireframe_dirty_specialization_set_check_for_removals : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.dirty_specialization.check_for_removals",
)

///|
let wireframe_render_set_specialize : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.specialize",
)

///|
let wireframe_render_set_prepare_bind_groups : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.prepare_bind_groups",
)

///|
let wireframe_render_set_prepare_view_keys : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.prepare_view_keys",
)

///|
let wireframe_render_set_queue : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.queue",
)

///|
let wireframe_render_set_node : @app.SystemSet = @app.system_set(
  "mgstudio.pbr.wireframe.node",
)

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
  if world.get_resource(wireframe_material_asset_event_cursor_key) is None {
    world.insert_resource(
      wireframe_material_asset_event_cursor_key,
      WireframeMaterialAssetEventCursor::WireframeMaterialAssetEventCursor(),
    )
  }
  if world.get_resource(wireframe_mesh_asset_event_cursor_key) is None {
    world.insert_resource(
      wireframe_mesh_asset_event_cursor_key,
      WireframeMeshAssetEventCursor::WireframeMeshAssetEventCursor(),
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
fn wireframe_entities_needing_specialization_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[WireframeEntitiesNeedingSpecialization] {
  if world.get_resource(WireframeEntitiesNeedingSpecialization::resource())
    is None {
    world.insert_resource(
      WireframeEntitiesNeedingSpecialization::resource(),
      WireframeEntitiesNeedingSpecialization::WireframeEntitiesNeedingSpecialization(),
    )
  }
  match
    world.get_resource_mut(WireframeEntitiesNeedingSpecialization::resource()) {
    Some(value) => value
    None => abort("Missing WireframeEntitiesNeedingSpecialization resource")
  }
}

///|
fn wireframe_collect_unique_entity(
  entities : Array[@core.Entity],
  seen : Map[UInt64, Bool],
  entity : @core.Entity,
) -> Unit {
  let key = entity.to_bits()
  if !seen.contains(key) {
    seen.set(key, true)
    entities.push(entity)
  }
}

///|
fn wireframe_material_asset_changed_ids_since_last_check(
  world : @ecs.World,
) -> @hashset.HashSet[Int] {
  let changed_ids : @hashset.HashSet[Int] = @hashset.HashSet([])
  let event_key : @ecs.MessageKey[@asset.AssetEvent[WireframeMaterial]] = @ecs.Message::message()
  if !world.contains_message(event_key) {
    return changed_ids
  }
  if world.get_resource(wireframe_material_asset_event_cursor_key) is None {
    world.insert_resource(
      wireframe_material_asset_event_cursor_key,
      WireframeMaterialAssetEventCursor::WireframeMaterialAssetEventCursor(),
    )
  }
  guard world.get_resource_mut(wireframe_material_asset_event_cursor_key)
    is Some(cursor_resource) else {
    return changed_ids
  }
  cursor_resource.modify(fn(cursor_state) {
    let reader = world.message_reader(event_key, cursor=cursor_state.cursor)
    for event in reader.read() {
      match event {
        Added(handle) | Modified(handle) | Removed(handle) =>
          changed_ids.add(handle.id())
        Unused(_) | LoadedWithDependencies(_) => ()
      }
    }
    cursor_state.cursor = reader.cursor()
  })
  changed_ids
}

///|
fn wireframe_mesh_asset_changed_ids_since_last_check(
  world : @ecs.World,
) -> @hashset.HashSet[Int] {
  let changed_ids : @hashset.HashSet[Int] = @hashset.HashSet([])
  let event_key : @ecs.MessageKey[@asset.AssetEvent[@mesh.Mesh]] = @ecs.Message::message()
  if !world.contains_message(event_key) {
    return changed_ids
  }
  if world.get_resource(wireframe_mesh_asset_event_cursor_key) is None {
    world.insert_resource(
      wireframe_mesh_asset_event_cursor_key,
      WireframeMeshAssetEventCursor::WireframeMeshAssetEventCursor(),
    )
  }
  guard world.get_resource_mut(wireframe_mesh_asset_event_cursor_key)
    is Some(cursor_resource) else {
    return changed_ids
  }
  cursor_resource.modify(fn(cursor_state) {
    let reader = world.message_reader(event_key, cursor=cursor_state.cursor)
    for event in reader.read() {
      match event {
        Added(handle) | Modified(handle) | Removed(handle) =>
          changed_ids.add(handle.id())
        Unused(_) | LoadedWithDependencies(_) => ()
      }
    }
    cursor_state.cursor = reader.cursor()
  })
  changed_ids
}

///|
fn wireframe_collect_material_asset_changed_entities(
  world : @ecs.World,
  changed_material_ids : @hashset.HashSet[Int],
  entities_needing_specialization : WireframeEntitiesNeedingSpecialization,
  changed_seen : Map[UInt64, Bool],
) -> Unit {
  world.for_each_component(ecs_key_mesh3d_wireframe, fn(entity, wireframe) {
    if changed_material_ids.contains(wireframe.material().id()) {
      wireframe_collect_unique_entity(
        entities_needing_specialization.changed,
        changed_seen,
        entity,
      )
    }
  })
}

///|
fn wireframe_collect_mesh_asset_changed_entities(
  world : @ecs.World,
  changed_mesh_ids : @hashset.HashSet[Int],
  entities_needing_specialization : WireframeEntitiesNeedingSpecialization,
  changed_seen : Map[UInt64, Bool],
) -> Unit {
  world.for_each_component(ecs_key_mesh3d, fn(entity, mesh3d) {
    if changed_mesh_ids.contains(mesh3d.mesh().id()) {
      wireframe_collect_unique_entity(
        entities_needing_specialization.changed,
        changed_seen,
        entity,
      )
    }
  })
}

///|
fn check_wireframe_entities_needing_specialization_from_world(
  world : @ecs.World,
  entities_needing_specialization : WireframeEntitiesNeedingSpecialization,
  system_ticks : @core.SystemTicks,
) -> Unit {
  entities_needing_specialization.changed.clear()
  entities_needing_specialization.removed.clear()

  let changed_seen : Map[UInt64, Bool] = {}
  for entity in world.changed_components(ecs_key_mesh3d, system_ticks).read() {
    wireframe_collect_unique_entity(
      entities_needing_specialization.changed,
      changed_seen,
      entity,
    )
  }
  for
    entity in world
    .changed_components(ecs_key_mesh3d_wireframe, system_ticks)
    .read() {
    wireframe_collect_unique_entity(
      entities_needing_specialization.changed,
      changed_seen,
      entity,
    )
  }
  for
    entity in world
    .changed_components(ecs_key_wireframe_line_width, system_ticks)
    .read() {
    wireframe_collect_unique_entity(
      entities_needing_specialization.changed,
      changed_seen,
      entity,
    )
  }
  for
    entity in world
    .changed_components(ecs_key_wireframe_topology, system_ticks)
    .read() {
    wireframe_collect_unique_entity(
      entities_needing_specialization.changed,
      changed_seen,
      entity,
    )
  }
  wireframe_collect_mesh_asset_changed_entities(
    world,
    wireframe_mesh_asset_changed_ids_since_last_check(world),
    entities_needing_specialization,
    changed_seen,
  )
  wireframe_collect_material_asset_changed_entities(
    world,
    wireframe_material_asset_changed_ids_since_last_check(world),
    entities_needing_specialization,
    changed_seen,
  )

  let removed_seen : Map[UInt64, Bool] = {}
  for entity in world.removed_components(ecs_key_mesh3d, system_ticks).read() {
    wireframe_collect_unique_entity(
      entities_needing_specialization.removed,
      removed_seen,
      entity,
    )
  }
  for
    entity in world
    .removed_components(ecs_key_mesh3d_wireframe, system_ticks)
    .read() {
    wireframe_collect_unique_entity(
      entities_needing_specialization.removed,
      removed_seen,
      entity,
    )
  }
}

///|
fn check_wireframe_entities_needing_specialization_system(
  world : @ecs.World,
) -> Unit {
  let system_ticks = @app.current_system_ticks()
  wireframe_entities_needing_specialization_mut_or_init(world).modify(fn(
    value,
  ) {
    check_wireframe_entities_needing_specialization_from_world(
      world, value, system_ticks,
    )
  })
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
          material_instances.insert(
            @render.MainEntity::new(entity),
            material.material().id(),
          )
        } else {
          ignore(material_instances.remove(@render.MainEntity::new(entity)))
        }
      _ => ()
    }
  }

  for
    entity in source_world
    .removed_components(@visibility.ecs_key_view_visibility, system_ticks)
    .read() {
    if !changed_entities.contains(entity.to_bits()) {
      ignore(material_instances.remove(@render.MainEntity::new(entity)))
    }
  }
  for
    entity in source_world
    .removed_components(ecs_key_mesh3d_wireframe, system_ticks)
    .read() {
    if !changed_entities.contains(entity.to_bits()) {
      ignore(material_instances.remove(@render.MainEntity::new(entity)))
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
fn render_wireframe_assets_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[RenderWireframeAssets] {
  if world.get_resource(RenderWireframeAssets::resource()) is None {
    world.insert_resource(
      RenderWireframeAssets::resource(),
      RenderWireframeAssets::RenderWireframeAssets(),
    )
  }
  match world.get_resource_mut(RenderWireframeAssets::resource()) {
    Some(assets) => assets
    None => abort("Missing RenderWireframeAssets resource")
  }
}

///|
fn extract_wireframe_material_assets_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let key : @ecs.ResourceKey[@asset.Assets[WireframeMaterial]] = @asset.assets_resource_key()
  guard source_world.get_resource(key) is Some(source_assets) else { return }
  render_wireframe_assets_mut_or_init(world).modify(fn(render_assets) {
    render_assets.clear()
    for item in source_assets.iter() {
      let (handle, material) = item
      render_assets.insert(
        handle.id(),
        RenderWireframeMaterial::from_material(material),
      )
    }
  })
}

///|
fn dirty_wireframe_specializations_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[DirtyWireframeSpecializations] {
  if world.get_resource(DirtyWireframeSpecializations::resource()) is None {
    world.insert_resource(
      DirtyWireframeSpecializations::resource(),
      DirtyWireframeSpecializations::DirtyWireframeSpecializations(),
    )
  }
  match world.get_resource_mut(DirtyWireframeSpecializations::resource()) {
    Some(value) => value
    None => abort("Missing DirtyWireframeSpecializations resource")
  }
}

///|
fn wireframe_mesh_visibility_class() -> String {
  ecs_key_mesh3d.id().to_string()
}

///|
fn wireframe_entity_bits(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn wireframe_main_entity_compare(
  left : @render.MainEntity,
  right : @render.MainEntity,
) -> Int {
  let left_bits = wireframe_entity_bits(left.id())
  let right_bits = wireframe_entity_bits(right.id())
  if left_bits < right_bits {
    -1
  } else if left_bits > right_bits {
    1
  } else {
    0
  }
}

///|
fn wireframe_visible_pair_compare(
  left : (@core.Entity, @render.MainEntity),
  right : (@core.Entity, @render.MainEntity),
) -> Int {
  wireframe_main_entity_compare(left.1, right.1)
}

///|
fn wireframe_render_entity_for_main(
  source_world : @ecs.World,
  main_entity : @core.Entity,
) -> @core.Entity {
  match
    (try! source_world.get_by_key(main_entity, @render.ecs_key_render_entity)) {
    Some(render_entity) => render_entity.id()
    None => main_entity
  }
}

///|
fn wireframe_retained_view_entity(
  render_entity : @core.Entity,
  main_entity : @render.MainEntity?,
) -> @core.Entity {
  match main_entity {
    Some(value) => value.id()
    None => render_entity
  }
}

///|
fn extract_wireframe_visible_mesh_pairs(
  source_world : @ecs.World,
  visible_entities : @camera_camera.VisibleEntities,
) -> Array[(@core.Entity, @render.MainEntity)] {
  let pairs : Array[(@core.Entity, @render.MainEntity)] = []
  for main_entity in visible_entities.get(@mesh.ecs_key_mesh3d.id()) {
    pairs.push(
      (
        wireframe_render_entity_for_main(source_world, main_entity),
        @render.MainEntity::new(main_entity),
      ),
    )
  }
  pairs.sort_by(wireframe_visible_pair_compare)
  pairs
}

///|
fn extract_wireframe_render_visible_entities_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let live_render_views : Map[UInt64, Bool] = {}
  let mesh_visibility_class = wireframe_mesh_visibility_class()
  let extracted_views : Array[
    (@core.Entity, @camera_camera.Camera, @camera_camera.VisibleEntities),
  ] = []
  let camera_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[Camera3d],
        @ecs.Optional[@camera_camera.Camera],
        @ecs.Read[@camera_camera.VisibleEntities],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! camera_query.view(fn(_query_entity, data) {
    let (main_view_entity, (_camera3d, camera_opt, visible_entities)) = data
    let camera = match camera_opt.value() {
      Some(value) => value
      None => @camera_camera.Camera::Camera()
    }
    extracted_views.push((main_view_entity, camera, visible_entities.value()))
  })
  for extracted_view in extracted_views {
    let (main_view_entity, camera, visible_entities) = extracted_view
    let render_view_entity = wireframe_render_entity_for_main(
      source_world, main_view_entity,
    )
    if !camera.is_active {
      if world.is_alive(render_view_entity) {
        ignore(
          world.remove_by_key(
            render_view_entity, @render_visibility.ecs_key_render_visible_entities,
          ) catch {
            _ => false
          },
        )
      }
      return
    }
    guard world.is_alive(render_view_entity) else { return }
    live_render_views.set(wireframe_entity_bits(render_view_entity), true)
    let render_visible_entities = match
      (try! world.get_by_key(
        render_view_entity, @render_visibility.ecs_key_render_visible_entities,
      )) {
      Some(value) => value
      None => @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
    }
    let render_visible_mesh_entities = render_visible_entities.class_or_insert(
      mesh_visibility_class,
    )
    render_visible_mesh_entities.prepare_for_new_frame()
    render_visible_mesh_entities.update_cpu_culled_entities(
      extract_wireframe_visible_mesh_pairs(source_world, visible_entities),
    )
    render_visible_mesh_entities.sort_added_entities()
    try! world.set_by_key(
      render_view_entity, @render_visibility.ecs_key_render_visible_entities, render_visible_entities,
    )
  }
  let stale_query : @ecs.Query[
    (@core.Entity, @ecs.Read[@render_visibility.RenderVisibleEntities]),
    @ecs.All,
  ] = @ecs.query(world)
  let stale_entities : Array[@core.Entity] = []
  try! stale_query.view(fn(_query_entity, data) {
    let (render_view_entity, _visible_entities) = data
    if !live_render_views
      .get(wireframe_entity_bits(render_view_entity))
      .unwrap_or(false) {
      stale_entities.push(render_view_entity)
    }
  })
  for entity in stale_entities {
    ignore(
      world.remove_by_key(
        entity, @render_visibility.ecs_key_render_visible_entities,
      ) catch {
        _ => false
      },
    )
  }
}

///|
fn wireframe_view_key_cache_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[WireframeViewKeyCache] {
  if world.get_resource(WireframeViewKeyCache::resource()) is None {
    world.insert_resource(
      WireframeViewKeyCache::resource(),
      WireframeViewKeyCache::WireframeViewKeyCache(),
    )
  }
  match world.get_resource_mut(WireframeViewKeyCache::resource()) {
    Some(value) => value
    None => abort("Missing WireframeViewKeyCache resource")
  }
}

///|
fn prepare_wireframe_view_key_cache_system(world : @ecs.World) -> Unit {
  let live_views : Map[UInt64, Bool] = {}
  wireframe_view_key_cache_mut_or_init(world).modify(fn(cache) {
    match render3d_pending_frame_snapshot(world) {
      Some(frame) =>
        for camera in frame.cameras {
          let retained_view_entity = camera.entity.main_entity
          cache.insert(
            retained_view_entity,
            render3d_camera_mesh_pipeline_view_key_bits(camera.payload),
          )
          live_views.set(retained_view_entity.to_bits(), true)
        }
      None => ()
    }
    cache.retain_live_views(live_views)
  })
}

///|
fn specialize_wireframes_system(world : @ecs.World) -> Unit {
  let phases = match world.get_resource(Wireframe3dPhases::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing Wireframe3dPhases resource during pbr wireframe specialization",
      )
  }
  let view_key_cache = match
    world.get_resource(WireframeViewKeyCache::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing WireframeViewKeyCache resource during pbr wireframe specialization",
      )
  }
  let pending_wireframe_queues = match
    world.get_resource(PendingWireframeQueues::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing PendingWireframeQueues resource during pbr wireframe specialization",
      )
  }
  let specialized_wireframe_pipeline_cache = match
    world.get_resource(SpecializedWireframePipelineCache::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing SpecializedWireframePipelineCache resource during pbr wireframe specialization",
      )
  }
  let specialized_wireframe_mesh_pipelines = match
    world.get_resource(SpecializedWireframeMeshPipelines::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing SpecializedWireframeMeshPipelines resource during pbr wireframe specialization",
      )
  }
  let render_wireframe_instances = match
    world.get_resource(RenderWireframeInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderWireframeInstances resource during pbr wireframe specialization",
      )
  }
  let dirty_wireframe_specializations = match
    world.get_resource(DirtyWireframeSpecializations::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing DirtyWireframeSpecializations resource during pbr wireframe specialization",
      )
  }
  let render_wireframe_assets = match
    world.get_resource(RenderWireframeAssets::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderWireframeAssets resource during pbr wireframe specialization",
      )
  }
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshInstances resource during pbr wireframe specialization",
      )
  }
  let render_meshes = match
    world.get_resource(@render_mesh.RenderMeshAssets::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshAssets resource during pbr wireframe specialization",
      )
  }
  let render_visibility_ranges = match
    world.get_resource(@render_visibility.RenderVisibilityRanges::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderVisibilityRanges resource during pbr wireframe specialization",
      )
  }
  let render_lightmaps = match
    world.get_resource(@lightmap.RenderLightmaps::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderLightmaps resource during pbr wireframe specialization",
      )
  }
  let pipeline = match world.get_resource(Wireframe3dPipeline::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing Wireframe3dPipeline resource during pbr wireframe specialization",
      )
  }
  let mesh_pipeline = match world.get_resource(MeshPipeline::resource()) {
    Some(value) => value
    None =>
      abort("missing MeshPipeline resource during pbr wireframe specialization")
  }
  let pipeline_cache = match
    world.get_resource(@render.pipeline_cache_resource_key) {
    Some(value) => value
    None =>
      abort(
        "missing PipelineCache resource during pbr wireframe specialization",
      )
  }
  let live_views : Map[UInt64, Bool] = {}
  let mesh_visibility_class = wireframe_mesh_visibility_class()
  let view_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[@render_visibility.RenderVisibleEntities],
        @ecs.Optional[@render.MainEntity],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! view_query.view(fn(_query_entity, data) {
    let (render_view_entity, (visible_entities, main_entity)) = data
    let retained_view_entity = wireframe_retained_view_entity(
      render_view_entity,
      main_entity.value(),
    )
    live_views.set(retained_view_entity.to_bits(), true)
    guard phases.contains(retained_view_entity) else { return }
    guard view_key_cache.get(retained_view_entity) is Some(view_key_bits) else {
      return
    }
    guard visible_entities.value().get(mesh_visibility_class)
      is Some(render_visible_mesh_entities) else {
      return
    }
    let view_pending_wireframe_queues = pending_wireframe_queues.prepare_for_new_frame(
      retained_view_entity,
    )
    specialize_wireframe_phase_items(
      retained_view_entity,
      render_visible_mesh_entities,
      view_pending_wireframe_queues,
      specialized_wireframe_pipeline_cache,
      specialized_wireframe_mesh_pipelines,
      render_wireframe_instances,
      dirty_wireframe_specializations,
      render_wireframe_assets.as_map(),
      render_mesh_instances,
      render_meshes,
      view_key_bits,
      render_visibility_ranges,
      render_lightmaps,
      pipeline,
      mesh_pipeline,
      pipeline_cache,
    )
  })
  pending_wireframe_queues.expire_stale_views(live_views)
  specialized_wireframe_pipeline_cache.expire_stale_views(live_views)
  view_key_cache.retain_live_views(live_views)
}

///|
fn queue_wireframes_system(world : @ecs.World) -> Unit {
  let phases = match world.get_resource(Wireframe3dPhases::resource()) {
    Some(value) => value
    None =>
      abort("missing Wireframe3dPhases resource during pbr wireframe queueing")
  }
  let pending_wireframe_queues = match
    world.get_resource(PendingWireframeQueues::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing PendingWireframeQueues resource during pbr wireframe queueing",
      )
  }
  let specialized_wireframe_pipeline_cache = match
    world.get_resource(SpecializedWireframePipelineCache::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing SpecializedWireframePipelineCache resource during pbr wireframe queueing",
      )
  }
  let render_wireframe_instances = match
    world.get_resource(RenderWireframeInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderWireframeInstances resource during pbr wireframe queueing",
      )
  }
  let dirty_wireframe_specializations = match
    world.get_resource(DirtyWireframeSpecializations::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing DirtyWireframeSpecializations resource during pbr wireframe queueing",
      )
  }
  let render_wireframe_assets = match
    world.get_resource(RenderWireframeAssets::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderWireframeAssets resource during pbr wireframe queueing",
      )
  }
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshInstances resource during pbr wireframe queueing",
      )
  }
  let mesh_allocator = match
    world.get_resource(@render_mesh.MeshAllocator::resource()) {
    Some(value) => value
    None =>
      abort("missing MeshAllocator resource during pbr wireframe queueing")
  }
  let draw_functions = match
    world.get_resource(Wireframe3dDrawFunctions::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing Wireframe3dDrawFunctions resource during pbr wireframe queueing",
      )
  }
  let gpu_preprocessing_support = wireframe_3d_gpu_preprocessing_support(world)
  let mesh_visibility_class = wireframe_mesh_visibility_class()
  let view_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[@render_visibility.RenderVisibleEntities],
        @ecs.Optional[@render.MainEntity],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! view_query.view(fn(_query_entity, data) {
    let (render_view_entity, (visible_entities, main_entity)) = data
    let retained_view_entity = wireframe_retained_view_entity(
      render_view_entity,
      main_entity.value(),
    )
    guard phases.phase(retained_view_entity) is Some(wireframe_phase) else {
      return
    }
    guard visible_entities.value().get(mesh_visibility_class)
      is Some(render_mesh_visible_entities) else {
      return
    }
    let view_pending_wireframe_queues = match
      pending_wireframe_queues.view(retained_view_entity) {
      Some(value) => value
      None =>
        abort(
          "missing view PendingWireframeQueues during pbr wireframe queueing",
        )
    }
    queue_wireframe_phase_items(
      wireframe_phase,
      retained_view_entity,
      render_mesh_visible_entities,
      view_pending_wireframe_queues,
      specialized_wireframe_pipeline_cache,
      render_wireframe_instances,
      dirty_wireframe_specializations,
      render_wireframe_assets.as_map(),
      render_mesh_instances,
      mesh_allocator,
      draw_functions,
      gpu_preprocessing_support,
    )
  })
}

///|
fn prepare_wireframe_wide_bind_groups_system(world : @ecs.World) -> Unit {
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshInstances resource during pbr wireframe wide bind group preparation",
      )
  }
  let render_meshes = match
    world.get_resource(@render_mesh.RenderMeshAssets::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderMeshAssets resource during pbr wireframe wide bind group preparation",
      )
  }
  let render_wireframe_instances = match
    world.get_resource(RenderWireframeInstances::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderWireframeInstances resource during pbr wireframe wide bind group preparation",
      )
  }
  let render_wireframe_assets = match
    world.get_resource(RenderWireframeAssets::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing RenderWireframeAssets resource during pbr wireframe wide bind group preparation",
      )
  }
  let mesh_allocator = match
    world.get_resource(@render_mesh.MeshAllocator::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing MeshAllocator resource during pbr wireframe wide bind group preparation",
      )
  }
  let wide_bind_groups = match
    world.get_resource(WireframeWideBindGroups::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing WireframeWideBindGroups resource during pbr wireframe wide bind group preparation",
      )
  }
  prepare_wireframe_wide_bind_groups(
    render_mesh_instances, render_meshes, render_wireframe_instances, render_wireframe_assets,
    mesh_allocator, wide_bind_groups,
  )
}

///|
fn wireframe_3d_render_node_system(world : @ecs.World) -> Unit {
  guard world.get_resource(Wireframe3dPhases::resource()) is Some(phases) else {
    return
  }
  for retained_view_entity in phases.retained_view_entities() {
    let preflight_plan : Wireframe3dRenderNodePlan? = Some(
      wireframe_3d_render_node_plan(phases, retained_view_entity, false),
    ) catch {
      _ => None
    }
    guard preflight_plan is Some(_) else { continue }
    let draw_functions = match
      world.get_resource(Wireframe3dDrawFunctions::resource()) {
      Some(value) => value
      None =>
        abort(
          "missing Wireframe3dDrawFunctions resource during pbr wireframe node",
        )
    }
    let render_wireframe_instances = match
      world.get_resource(RenderWireframeInstances::resource()) {
      Some(value) => value
      None =>
        abort(
          "missing RenderWireframeInstances resource during pbr wireframe node",
        )
    }
    let render_wireframe_assets = match
      world.get_resource(RenderWireframeAssets::resource()) {
      Some(value) => value
      None =>
        abort(
          "missing RenderWireframeAssets resource during pbr wireframe node",
        )
    }
    let render_mesh_instances = match
      world.get_resource(RenderMeshInstances::resource()) {
      Some(value) => value
      None =>
        abort("missing RenderMeshInstances resource during pbr wireframe node")
    }
    let render_meshes = match
      world.get_resource(@render_mesh.RenderMeshAssets::resource()) {
      Some(value) => value
      None =>
        abort("missing RenderMeshAssets resource during pbr wireframe node")
    }
    let mesh_allocator = match
      world.get_resource(@render_mesh.MeshAllocator::resource()) {
      Some(value) => value
      None => abort("missing MeshAllocator resource during pbr wireframe node")
    }
    let wide_bind_groups = match
      world.get_resource(WireframeWideBindGroups::resource()) {
      Some(value) => value
      None =>
        abort(
          "missing WireframeWideBindGroups resource during pbr wireframe node",
        )
    }
    let plan = Some(
      wireframe_3d_render_node_command_plan(
        phases, retained_view_entity, false, draw_functions, render_wireframe_instances,
        render_wireframe_assets, render_mesh_instances, render_meshes, mesh_allocator,
        wide_bind_groups,
      ),
    ) catch {
      _ => None
    }
    guard plan is Some(plan) else { continue }
    @app.timeline_trace_emit_counter_int(
      "wireframe_3d_render_node_command_plans",
      plan.command_plan_count(),
    )
    @app.timeline_trace_emit_counter_int(
      "wireframe_3d_render_node_command_skips",
      plan.command_skip_count(),
    )
    @app.timeline_trace_emit_counter_int(
      "wireframe_3d_render_node_command_failures",
      plan.command_failure_count(),
    )
  }
}

///|
fn wireframe_3d_phases_mut_or_init(
  world : @ecs.World,
) -> @ecs.ResourceMut[Wireframe3dPhases] {
  if world.get_resource(Wireframe3dPhases::resource()) is None {
    world.insert_resource(
      Wireframe3dPhases::resource(),
      Wireframe3dPhases::Wireframe3dPhases(),
    )
  }
  match world.get_resource_mut(Wireframe3dPhases::resource()) {
    Some(value) => value
    None => abort("Missing Wireframe3dPhases resource")
  }
}

///|
fn wireframe_3d_gpu_preprocessing_support(
  world : @ecs.World,
) -> @render_batching.GpuPreprocessingSupport {
  match
    world.get_resource(@render_batching.GpuPreprocessingSupport::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing GpuPreprocessingSupport resource during pbr wireframe queueing",
      )
  }
}

///|
fn extract_wireframe_3d_camera_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let gpu_preprocessing_support = wireframe_3d_gpu_preprocessing_support(world)
  let live_views : Map[UInt64, Bool] = {}
  wireframe_3d_phases_mut_or_init(world).modify(fn(phases) {
    let query : @ecs.Query[
      (
        @core.Entity,
        @ecs.Read[Camera3d],
        @ecs.Optional[@camera_camera.Camera],
        @ecs.Has[NoIndirectDrawing],
      ),
      @ecs.All,
    ] = @ecs.query(source_world)
    try! query.view(fn(_query_entity, data) {
      let (main_entity, _camera3d, camera_opt, no_indirect_drawing) = data
      let camera = match camera_opt.value() {
        Some(value) => value
        None => @camera_camera.Camera::Camera()
      }
      if !camera.is_active {
        return
      }
      let requested_mode = if no_indirect_drawing.present() {
        @render_batching.GpuPreprocessingMode::PreprocessingOnly
      } else {
        @render_batching.GpuPreprocessingMode::Culling
      }
      let gpu_preprocessing_mode = gpu_preprocessing_support.min(requested_mode)
      phases.prepare_for_new_frame(main_entity, gpu_preprocessing_mode)
      live_views.set(main_entity.to_bits(), true)
    })
    phases.retain_live_views(live_views)
  })
}

///|
fn clear_dirty_wireframe_specializations_system(world : @ecs.World) -> Unit {
  dirty_wireframe_specializations_mut_or_init(world).modify(fn(value) {
    value.clear()
  })
}

///|
fn extract_wireframe_entities_needing_specialization_system(
  world : @ecs.World,
) -> Unit {
  let source_world = @render.render_source_world(world)
  guard source_world.get_resource(
      WireframeEntitiesNeedingSpecialization::resource(),
    )
    is Some(entities_needing_specialization) else {
    return
  }
  dirty_wireframe_specializations_mut_or_init(world).modify(fn(dirty) {
    for entity in entities_needing_specialization.changed {
      dirty.insert_changed(@render.MainEntity::new(entity))
    }
  })
}

///|
fn extract_wireframe_entities_that_need_specializations_removed_system(
  world : @ecs.World,
) -> Unit {
  let source_world = @render.render_source_world(world)
  guard source_world.get_resource(
      WireframeEntitiesNeedingSpecialization::resource(),
    )
    is Some(entities_needing_specialization) else {
    return
  }
  dirty_wireframe_specializations_mut_or_init(world).modify(fn(dirty) {
    for entity in entities_needing_specialization.removed {
      dirty.insert_removed(@render.MainEntity::new(entity))
    }
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
    SpecializedWireframeMeshPipelines::resource(),
    fn() {
      SpecializedWireframeMeshPipelines::SpecializedWireframeMeshPipelines()
    },
  )
  wireframe_init_render_resource_if_missing(
    world,
    RenderWireframeInstances::resource(),
    fn() { RenderWireframeInstances::RenderWireframeInstances() },
  )
  wireframe_init_render_resource_if_missing(
    world,
    RenderWireframeAssets::resource(),
    fn() { RenderWireframeAssets::RenderWireframeAssets() },
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
  wireframe_init_render_resource_if_missing(
    world,
    DirtyWireframeSpecializations::resource(),
    fn() { DirtyWireframeSpecializations::DirtyWireframeSpecializations() },
  )
  wireframe_init_render_resource_if_missing(
    world,
    Wireframe3dPhases::resource(),
    fn() { Wireframe3dPhases::Wireframe3dPhases() },
  )
  wireframe_init_render_resource_if_missing(
    world,
    WireframeViewKeyCache::resource(),
    fn() { WireframeViewKeyCache::WireframeViewKeyCache() },
  )
  let stage = @render.render_schedule_stage()
  let extract_stage = @render.render_extract_schedule_stage()
  let graph_stage = @render.RenderGraph::schedule()
  sub_app
  .configure_sets(
    graph_stage,
    wireframe_render_set_node,
    after=[@core_pipeline.core3d_system_set_main_pass()],
    before=[@core_pipeline.core3d_system_set_early_post_process()],
  )
  .configure_sets(stage, wireframe_render_set_prepare_view_keys, in_sets=[
    render3d_set_queue,
  ])
  .configure_sets(
    stage,
    wireframe_render_set_specialize,
    before=[wireframe_render_set_prepare_bind_groups],
    in_sets=[render3d_set_queue_meshes],
  )
  .configure_sets(
    stage,
    wireframe_render_set_prepare_bind_groups,
    before=[wireframe_render_set_queue],
    in_sets=[render3d_set_queue_meshes],
  )
  .configure_sets(stage, wireframe_render_set_queue, in_sets=[
    render3d_set_queue_meshes,
  ])
  .configure_sets(
    extract_stage,
    wireframe_dirty_specialization_set_clear,
    before=[wireframe_dirty_specialization_set_check_for_changes],
    in_sets=[render3d_set_extract],
  )
  .configure_sets(
    extract_stage,
    wireframe_dirty_specialization_set_check_for_changes,
    before=[wireframe_dirty_specialization_set_check_for_removals],
    in_sets=[render3d_set_extract],
  )
  .configure_sets(
    extract_stage,
    wireframe_dirty_specialization_set_check_for_removals,
    in_sets=[render3d_set_extract],
  )
  .add_systems(
    extract_stage,
    @app.system(extract_wireframe_3d_camera_system).in_set(render3d_set_extract),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_wireframe_render_visible_entities_system).in_set(
      render3d_set_extract,
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(clear_dirty_wireframe_specializations_system).in_set(
      wireframe_dirty_specialization_set_clear,
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_wireframe_entities_needing_specialization_system).in_set(
      wireframe_dirty_specialization_set_check_for_changes,
    ),
  )
  .add_systems(
    extract_stage,
    @app.system(
      extract_wireframe_entities_that_need_specializations_removed_system,
    ).in_set(wireframe_dirty_specialization_set_check_for_removals),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_wireframe_materials_system).in_set(render3d_set_extract),
  )
  .add_systems(
    extract_stage,
    @app.system(extract_wireframe_material_assets_system).in_set(
      render3d_set_extract,
    ),
  )
  .add_systems(
    stage,
    @app.system(prepare_wireframe_view_key_cache_system).in_set(
      wireframe_render_set_prepare_view_keys,
    ),
  )
  .add_systems(
    stage,
    @app.system(specialize_wireframes_system).in_set(
      wireframe_render_set_specialize,
    ),
  )
  .add_systems(
    stage,
    @app.system(prepare_wireframe_wide_bind_groups_system).in_set(
      wireframe_render_set_prepare_bind_groups,
    ),
  )
  .add_systems(
    stage,
    @app.system(queue_wireframes_system).in_set(wireframe_render_set_queue),
  )
  .add_systems(
    graph_stage,
    @app.system(wireframe_3d_render_node_system).in_set(
      wireframe_render_set_node,
    ),
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
  .add_systems_world(
    @app.PostUpdate,
    check_wireframe_entities_needing_specialization_system,
  )
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
