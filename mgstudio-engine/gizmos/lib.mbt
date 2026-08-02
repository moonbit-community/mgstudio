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
// Bevy source: `bevy/crates/bevy_gizmos/src/lib.rs`.
// Package-level plugin boundary aligned with Bevy gizmos crate.

const GIZMO_PLUGIN_NAME : String = "mgstudio.gizmos.GizmoPlugin"

///|
priv struct GizmoPluginMarker {}

///|
pub let gizmo_set_flush : @app.SystemSet = @app.system_set(
  "mgstudio.gizmos.flush",
)

///|
pub let gizmo_set_mesh : @app.SystemSet = @app.system_set(
  "mgstudio.gizmos.mesh",
)

///|
let ecs_res_key_gizmo_plugin_marker : @ecs.ResourceKey[GizmoPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_gizmos::GizmoPluginMarker",
)

///|
pub struct GizmoPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn GizmoPlugin::GizmoPlugin() -> GizmoPlugin {
  GizmoPlugin::{  }
}

// The `Isometry2d`, `GizmoLine*`, `GizmoConfig*`, `Gizmos`, `GizmoStorage` and
// builder types are now defined by their own Bevy source owners in this package
// (`gizmos.mbt`, `config.mbt`), so the previous re-export bridge to `@sprite` is
// gone. `init_gizmo_group` is owned by `config.mbt`.

///|
pub fn gizmo_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  gizmo_plugin_with(app, GizmoPlugin())
}

///|
pub impl @app.Plugin for GizmoPlugin with fn name(_self) {
  GIZMO_PLUGIN_NAME
}

///|
pub impl @app.Plugin for GizmoPlugin with fn build(self, app) {
  gizmo_plugin_with(app, self)
}

///|
#warnings("-unnecessary_annotation")
pub fn gizmo_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GizmoPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let mut next = app
  if next.contains_resource(ecs_res_key_gizmo_plugin_marker) {
    return next
  }
  install_retained_gizmo_required_components(next.world())
  next = @asset.init_asset(next, fn() { GizmoAsset::GizmoAsset() })
  next = next.init_resource(fn() { GizmoHandles::GizmoHandles() })
  next = next.insert_world_resource(ecs_res_key_gizmo_plugin_marker, GizmoPluginMarker::{

  })
  next = global_gizmos_plugin(next)
  next = aabb_gizmo_plugin(next)
  next = frustum_gizmo_plugin(next)
  next = skinned_mesh_bounds_gizmo_plugin(next)
  next = next.add_last_system_config(
    @app.system(update_gizmo_meshes).in_set(gizmo_set_mesh),
  )
  next = next.configure_set(Last, gizmo_set_flush, before=[gizmo_set_mesh])
  next
}

///|
// Bevy source: `bevy/crates/bevy_gizmos/src/lib.rs` (`GizmoAsset` and the
// retained gizmo mesh-update runtime).

///|
pub struct GizmoAsset {
  buffer : GizmoBuffer
  config_type_name : String
}

///|
pub impl @asset.Asset for GizmoAsset with fn asset_debug_name() {
  "mgstudio_gizmos::GizmoAsset"
}

///|
pub impl @asset.Asset for GizmoAsset with fn asset_as_image(_self) {
  None
}

///|
let gizmo_asset_resource_keys : @asset.AssetResourceKeys[GizmoAsset] = @asset.register_asset_resource_keys(
  GizmoAsset::asset_debug_name(),
)

///|
pub impl @asset.Asset for GizmoAsset with fn asset_resource_keys() {
  gizmo_asset_resource_keys
}

///|
pub fn GizmoAsset::new() -> GizmoAsset {
  {
    buffer: GizmoBuffer(),
    config_type_name: DefaultGizmoConfigGroup::gizmo_config_group_debug_name(),
  }
}

///|
fn vec3_from_gizmo_line_2d(point : @math.Vec2) -> @math.Vec3 {
  @math.Vec3::new(point.x, point.y, 0.0F)
}

///|
pub fn GizmoAsset::from_drained_storage(
  drained : DrainedGizmoStorage,
) -> GizmoAsset {
  let buffer = GizmoBuffer::GizmoBuffer()
  let state = drained.state()
  for line in state.lines {
    buffer.list_positions.push(vec3_from_gizmo_line_2d(line.start))
    buffer.list_positions.push(vec3_from_gizmo_line_2d(line.end))
    buffer.list_colors.push(line.start_color.as_linear_rgba())
    buffer.list_colors.push(line.end_color.as_linear_rgba())
  }
  for line in state.lines_3d {
    buffer.list_positions.push(line.start)
    buffer.list_positions.push(line.end)
    buffer.list_colors.push(line.start_color.as_linear_rgba())
    buffer.list_colors.push(line.end_color.as_linear_rgba())
  }
  { buffer, config_type_name: drained.group_type_name() }
}

///|
pub fn GizmoAsset::is_empty(self : GizmoAsset) -> Bool {
  self.buffer.list_positions().length() == 0 &&
  self.buffer.strip_positions().length() == 0
}

///|
pub fn GizmoAsset::config_type_name(self : GizmoAsset) -> String {
  self.config_type_name
}

///|
pub fn GizmoAsset::GizmoAsset() -> GizmoAsset {
  GizmoAsset::new()
}

///|
pub impl Default for GizmoAsset with fn default() {
  GizmoAsset()
}

///|
pub struct GizmoHandleEntry {
  handle : @asset.Handle[GizmoAsset]
  config : GizmoConfig
}

///|
pub fn GizmoHandleEntry::handle(
  self : GizmoHandleEntry,
) -> @asset.Handle[GizmoAsset] {
  self.handle
}

///|
pub fn GizmoHandleEntry::config(self : GizmoHandleEntry) -> GizmoConfig {
  self.config
}

///|
pub struct GizmoHandles {
  handles : @hashmap.HashMap[String, GizmoHandleEntry]
}

///|
pub fn GizmoHandles::GizmoHandles() -> GizmoHandles {
  { handles: HashMap([]) }
}

///|
pub impl Default for GizmoHandles with fn default() {
  GizmoHandles()
}

///|
let ecs_res_key_gizmo_handles : @ecs.ResourceKey[GizmoHandles] = @ecs.register_resource(
  debug_name="mgstudio_gizmos::GizmoHandles",
)

///|
pub impl @app.Resource for GizmoHandles with fn resource() {
  ecs_res_key_gizmo_handles
}

///|
pub fn GizmoHandles::get(
  self : GizmoHandles,
  group_type_name : String,
) -> GizmoHandleEntry? {
  self.handles.get(group_type_name)
}

///|
pub fn GizmoHandles::entries(
  self : GizmoHandles,
) -> Array[(String, GizmoHandleEntry)] {
  let entries : Array[(String, GizmoHandleEntry)] = []
  for entry in self.handles.iter() {
    entries.push(entry)
  }
  entries
}

///|
fn gizmo_assets_resource_or_insert(
  world : @ecs.World,
) -> @asset.Assets[GizmoAsset] {
  let key : @ecs.ResourceKey[@asset.Assets[GizmoAsset]] = @asset.assets_resource_key()
  match world.get_resource(key) {
    Some(assets) => assets
    None => {
      let assets = @asset.Assets::new()
      world.insert_resource(key, assets)
      assets
    }
  }
}

///|
fn gizmo_handles_resource_or_insert(world : @ecs.World) -> GizmoHandles {
  match world.get_resource(ecs_res_key_gizmo_handles) {
    Some(handles) => handles
    None => {
      let handles = GizmoHandles::GizmoHandles()
      world.insert_resource(ecs_res_key_gizmo_handles, handles)
      handles
    }
  }
}

///|
pub fn update_gizmo_meshes(world : @ecs.World) -> Unit {
  let drained_storages = drain_registered_gizmo_storages(world)
  if drained_storages.length() == 0 {
    return
  }
  let assets = gizmo_assets_resource_or_insert(world)
  let handles = gizmo_handles_resource_or_insert(world)
  for drained in drained_storages {
    let group_type_name = drained.group_type_name()
    let asset = GizmoAsset::from_drained_storage(drained)
    if asset.is_empty() {
      handles.handles.remove(group_type_name) |> ignore
      continue
    }
    match handles.handles.get(group_type_name) {
      Some(entry) => {
        ignore(assets.set(entry.handle(), asset))
        handles.handles.set(group_type_name, {
          handle: entry.handle(),
          config: drained.config(),
        })
      }
      None => {
        let handle = assets.add(asset)
        handles.handles.set(group_type_name, {
          handle,
          config: drained.config(),
        })
      }
    }
  }
}
