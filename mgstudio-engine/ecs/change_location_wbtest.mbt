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
enum ChangeLocationMarker {
  Marker
}

///|
let change_location_marker_key : ComponentKey[ChangeLocationMarker] = register_component(
  debug_name="change_location_marker",
)

///|
pub impl Component for ChangeLocationMarker with fn component() {
  change_location_marker_key
}

///|
fn change_location_marker_column(
  world : World,
  entity : @core.Entity,
) -> RawTableColumn {
  let local_component_id = world
    .local_component_id(change_location_marker_key.id())
    .unwrap()
  let (table_id, _row_index) = world.entity_table_location(entity).unwrap()
  world.table_storage(table_id).unwrap().column(local_component_id).unwrap()
}

///|
test "ecs change locations: default omits storage and opt-in records caller" {
  let default_world = World::new()
  defer default_world.close()
  let default_entity = default_world.spawn()
  try! default_world.set_by_key(
    default_entity,
    change_location_marker_key,
    Marker,
  )
  debug_inspect(
    change_location_marker_column(default_world, default_entity).storage.changed_caller_ids
    is None,
    content="true",
  )
  debug_inspect(
    try! (default_world
    .get_mut(default_entity, key=change_location_marker_key)
    .unwrap()
    .changed_by()
    is None),
    content="true",
  )

  let tracked_world = World::new(track_change_locations=true)
  defer tracked_world.close()
  let tracked_entity = tracked_world.spawn()
  try! tracked_world.set_by_key(
    tracked_entity,
    change_location_marker_key,
    Marker,
  )
  debug_inspect(
    change_location_marker_column(tracked_world, tracked_entity).storage.changed_caller_ids
    .unwrap()
    .length(),
    content="1",
  )
  debug_inspect(
    try! tracked_world
    .get_mut(tracked_entity, key=change_location_marker_key)
    .unwrap()
    .changed_by()
    .unwrap()
    .contains("change_location_wbtest.mbt"),
    content="true",
  )
}
