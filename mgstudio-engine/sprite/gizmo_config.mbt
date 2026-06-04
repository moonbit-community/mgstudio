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
pub(open) trait GizmoConfigGroup {
  fn gizmo_config_group_debug_name() -> String
  fn gizmo_storage_resource_key() -> @ecs.ResourceKey[GizmoStorage[Self]]
  fn new_gizmo_config_group_cell() -> GizmoConfigGroupCell
  fn gizmo_config_group_cell_ref(GizmoConfigGroupCell) -> Ref[Self]?
  fn gizmo_config_group_marker(self : Self) -> Unit
}

///|
pub extenum GizmoConfigGroupCell {}

///|
pub struct DefaultGizmoConfigGroup {}

///|
pub fn DefaultGizmoConfigGroup::DefaultGizmoConfigGroup() -> DefaultGizmoConfigGroup {
  DefaultGizmoConfigGroup::{  }
}

///|
pub impl Default for DefaultGizmoConfigGroup with fn default() {
  DefaultGizmoConfigGroup::DefaultGizmoConfigGroup()
}

///|
pub impl GizmoConfigGroup for DefaultGizmoConfigGroup with fn gizmo_config_group_marker(
  _self,
) {

}

///|
pub impl GizmoConfigGroup for DefaultGizmoConfigGroup with fn gizmo_config_group_debug_name() {
  "mgstudio_gizmos::DefaultGizmoConfigGroup"
}

///|
let default_gizmo_storage_resource_key : @ecs.ResourceKey[
  GizmoStorage[DefaultGizmoConfigGroup],
] = @ecs.register_resource(
  debug_name="mgstudio_gizmos::GizmoStorage<mgstudio_gizmos::DefaultGizmoConfigGroup>",
)

///|
pub impl GizmoConfigGroup for DefaultGizmoConfigGroup with fn gizmo_storage_resource_key() {
  default_gizmo_storage_resource_key
}

///|
extenum GizmoConfigGroupCell += {
  DefaultGizmoConfigGroupCell(Ref[DefaultGizmoConfigGroup])
}

///|
pub impl GizmoConfigGroup for DefaultGizmoConfigGroup with fn new_gizmo_config_group_cell() {
  DefaultGizmoConfigGroupCell(
    Ref(DefaultGizmoConfigGroup::DefaultGizmoConfigGroup()),
  )
}

///|
pub impl GizmoConfigGroup for DefaultGizmoConfigGroup with fn gizmo_config_group_cell_ref(
  cell,
) {
  match cell {
    DefaultGizmoConfigGroupCell(value) => Some(value)
    _ => None
  }
}

///|
priv struct GizmoConfigStoreEntry {
  config : Ref[GizmoConfig]
  ext_config : GizmoConfigGroupCell
}

///|
struct GizmoConfigStore {
  entries : @hashmap.HashMap[String, GizmoConfigStoreEntry]
}

///|
fn[T : GizmoConfigGroup] gizmo_group_type_key(group : T) -> String {
  group.gizmo_config_group_marker()
  T::gizmo_config_group_debug_name()
}

///|
fn[T : GizmoConfigGroup] gizmo_group_missing_message(group : T) -> String {
  "Requested gizmo config group \{gizmo_group_type_key(group)} does not exist in `GizmoConfigStore`; call `app.init_gizmo_group(...)` first"
}

///|
fn[T : GizmoConfigGroup] gizmo_group_ref_or_abort(
  value : GizmoConfigGroupCell,
) -> Ref[T] {
  match T::gizmo_config_group_cell_ref(value) {
    Some(value_ref) => value_ref
    None => abort("gizmo config store contained a mismatched extension payload")
  }
}

///|
fn[T : GizmoConfigGroup] gizmo_config_store_entry(
  group : T,
) -> GizmoConfigStoreEntry {
  group.gizmo_config_group_marker()
  GizmoConfigStoreEntry::{
    config: Ref(GizmoConfig::GizmoConfig()),
    ext_config: T::new_gizmo_config_group_cell(),
  }
}

///|
pub fn GizmoConfigStore::GizmoConfigStore() -> GizmoConfigStore {
  let store = GizmoConfigStore::{ entries: @hashmap.HashMap([]) }
  store.register(DefaultGizmoConfigGroup::DefaultGizmoConfigGroup())
  store
}

///|
pub impl Default for GizmoConfigStore with fn default() {
  GizmoConfigStore::GizmoConfigStore()
}

///|
pub fn[T : GizmoConfigGroup] GizmoConfigStore::contains(
  self : GizmoConfigStore,
  group : T,
) -> Bool {
  self.entries.contains(gizmo_group_type_key(group))
}

///|
pub fn[T : GizmoConfigGroup] GizmoConfigStore::register(
  self : GizmoConfigStore,
  group : T,
) -> Unit {
  let key = gizmo_group_type_key(group)
  if !self.entries.contains(key) {
    self.entries.set(key, gizmo_config_store_entry(group))
  }
}

///|
pub fn[T : GizmoConfigGroup] GizmoConfigStore::get_config(
  self : GizmoConfigStore,
  group : T,
) -> (GizmoConfig, T)? {
  match self.entries.get(gizmo_group_type_key(group)) {
    Some(entry) => {
      let ext_ref : Ref[T] = gizmo_group_ref_or_abort(entry.ext_config)
      Some((entry.config.val, ext_ref.val))
    }
    None => None
  }
}

///|
pub fn[T : GizmoConfigGroup] GizmoConfigStore::config(
  self : GizmoConfigStore,
  group : T,
) -> (GizmoConfig, T) {
  match self.get_config(group) {
    Some(configs) => configs
    None => abort(gizmo_group_missing_message(group))
  }
}

///|
pub fn[T : GizmoConfigGroup] GizmoConfigStore::get_config_mut(
  self : GizmoConfigStore,
  group : T,
) -> (Ref[GizmoConfig], Ref[T])? {
  match self.entries.get(gizmo_group_type_key(group)) {
    Some(entry) =>
      Some((entry.config, gizmo_group_ref_or_abort(entry.ext_config)))
    None => None
  }
}

///|
pub fn[T : GizmoConfigGroup] GizmoConfigStore::config_mut(
  self : GizmoConfigStore,
  group : T,
) -> (Ref[GizmoConfig], Ref[T]) {
  match self.get_config_mut(group) {
    Some(configs) => configs
    None => abort(gizmo_group_missing_message(group))
  }
}

///|
let ecs_res_key_gizmo_config_store : @ecs.ResourceKey[GizmoConfigStore] = @ecs.register_resource(
  debug_name="mgstudio_gizmos::GizmoConfigStore",
)

///|
pub impl @app.Resource for GizmoConfigStore with fn resource() {
  ecs_res_key_gizmo_config_store
}

///|
pub fn[T : GizmoConfigGroup] init_gizmo_group(
  app : @app.App[@ecs.World],
  group : T,
) -> @app.App[@ecs.World] {
  let app = app
    .init_resource(fn() { GizmoConfigStore::GizmoConfigStore() })
    .init_resource(fn() {
      let storage : GizmoStorage[T] = GizmoStorage::new()
      storage
    })
  register_gizmo_storage_drain(group)
  let store : GizmoConfigStore? = app
    .world()
    .get_resource(GizmoConfigStore::resource())
  match store {
    Some(store) => store.register(group)
    None => ()
  }
  app
}
