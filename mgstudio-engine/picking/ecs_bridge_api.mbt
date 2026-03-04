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
/// ECS component bridge types.
pub let ecs_components : Array[String] = []

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = [
  "PickingHits", "PickingState", "PickingEvents", "PointerInputs",
]

///|
pub let ecs_res_key_picking_hits : @ecs.ResourceKey[PickingHits] = @ecs.register_resource(
  debug_name="picking.picking_hits",
)

///|
pub let ecs_res_key_picking_state : @ecs.ResourceKey[PickingState] = @ecs.register_resource(
  debug_name="picking.picking_state",
)

///|
pub let ecs_res_key_picking_events : @ecs.ResourceKey[PickingEvents] = @ecs.register_resource(
  debug_name="picking.picking_events",
)

///|
pub let ecs_res_key_pointer_inputs : @ecs.ResourceKey[PointerInputs] = @ecs.register_resource(
  debug_name="picking.pointer_inputs",
)

///|
pub fn get_picking_hits_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PickingHits] {
  world.resource(ecs_res_key_picking_hits)
}

///|
pub fn get_picking_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PickingState] {
  world.resource(ecs_res_key_picking_state)
}

///|
pub fn get_picking_events_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PickingEvents] {
  world.resource(ecs_res_key_picking_events)
}

///|
pub fn get_pointer_inputs_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointerInputs] {
  world.resource(ecs_res_key_pointer_inputs)
}
