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
/// Legacy ECS component types.
pub let ecs_components : Array[String] = []

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = [
  "PickingHits", "PickingState", "PickingEvents", "PointerInputs",
]

///|
pub(open) trait HasRes_PickingHits {
  get_picking_hits_resource(self : Self) -> @core.Resource[PickingHits]
}

///|
pub(open) trait HasRes_PickingState {
  get_picking_state_resource(self : Self) -> @core.Resource[PickingState]
}

///|
pub(open) trait HasRes_PickingEvents {
  get_picking_events_resource(self : Self) -> @core.Resource[PickingEvents]
}

///|
pub(open) trait HasRes_PointerInputs {
  get_pointer_inputs_resource(self : Self) -> @core.Resource[PointerInputs]
}

///|
pub fn[W : HasRes_PickingHits] query_get_picking_hits_resource(
  world : W,
) -> @core.Resource[PickingHits] {
  world.get_picking_hits_resource()
}

///|
pub fn[W : HasRes_PickingState] query_get_picking_state_resource(
  world : W,
) -> @core.Resource[PickingState] {
  world.get_picking_state_resource()
}

///|
pub fn[W : HasRes_PickingEvents] query_get_picking_events_resource(
  world : W,
) -> @core.Resource[PickingEvents] {
  world.get_picking_events_resource()
}

///|
pub fn[W : HasRes_PointerInputs] query_get_pointer_inputs_resource(
  world : W,
) -> @core.Resource[PointerInputs] {
  world.get_pointer_inputs_resource()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_picking_hits_resource_by_world : Map[
  Int,
  @core.Resource[PickingHits],
] = {}

///|
pub impl HasRes_PickingHits for @ecs.World with get_picking_hits_resource(self) {
  bridge_get_picking_hits_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_picking_state_resource_by_world : Map[
  Int,
  @core.Resource[PickingState],
] = {}

///|
pub impl HasRes_PickingState for @ecs.World with get_picking_state_resource(
  self,
) {
  bridge_get_picking_state_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_picking_events_resource_by_world : Map[
  Int,
  @core.Resource[PickingEvents],
] = {}

///|
pub impl HasRes_PickingEvents for @ecs.World with get_picking_events_resource(
  self,
) {
  bridge_get_picking_events_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_pointer_inputs_resource_by_world : Map[
  Int,
  @core.Resource[PointerInputs],
] = {}

///|
pub impl HasRes_PointerInputs for @ecs.World with get_pointer_inputs_resource(
  self,
) {
  bridge_get_pointer_inputs_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
/// End ECS bridge impls.
