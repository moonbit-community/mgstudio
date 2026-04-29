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
// Bevy source: `bevy/crates/bevy_picking/src/mesh_picking/mod.rs`.

///|
pub using @picking {type PickingState}

///|
pub using @picking {type HitData}

///|
pub using @picking {type PointerButton}

///|
pub using @picking {type PointerHits}

///|
pub using @picking {type PointerInput}

///|
pub using @picking {type PointerId}

///|
pub using @picking {type PointerInteraction}

///|
pub using @picking {type PointerLocation}

///|
pub using @picking {type PointerMap}

///|
pub using @picking {type PointerPress}

///|
pub let ecs_res_key_picking_state : @ecs.ResourceKey[@picking.PickingState] = @picking.ecs_res_key_picking_state

///|
pub let ecs_res_key_pointer_map : @ecs.ResourceKey[@picking.PointerMap] = @picking.ecs_res_key_pointer_map

///|
pub let ecs_key_pointer_id : @ecs.ComponentKey[@picking.PointerId] = @picking.ecs_key_pointer_id

///|
pub let ecs_key_pointer_interaction : @ecs.ComponentKey[
  @picking.PointerInteraction,
] = @picking.ecs_key_pointer_interaction

///|
pub let ecs_key_pointer_location : @ecs.ComponentKey[@picking.PointerLocation] = @picking.ecs_key_pointer_location

///|
pub let ecs_key_pointer_press : @ecs.ComponentKey[@picking.PointerPress] = @picking.ecs_key_pointer_press

///|
pub let ecs_msg_key_pointer_hits : @ecs.MessageKey[@picking.PointerHits] = @picking.ecs_msg_key_pointer_hits

///|
pub let ecs_msg_key_pointer_input : @ecs.MessageKey[@picking.PointerInput] = @picking.ecs_msg_key_pointer_input

///|
pub fn ensure_picking_state_system(world : @ecs.World) -> Unit {
  @picking.ensure_picking_state_system(world)
}

///|
pub fn get_picking_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[@picking.PickingState] {
  @picking.get_picking_state_resource(world)
}

///|
pub fn get_pointer_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[@picking.PointerMap] {
  @picking.get_pointer_map_resource(world)
}

///|
pub fn pointer_hits_message_key() -> @ecs.MessageKey[@picking.PointerHits] {
  @picking.pointer_hits_message_key()
}

///|
pub fn pointer_input_message_key() -> @ecs.MessageKey[@picking.PointerInput] {
  @picking.pointer_input_message_key()
}

///|
pub let picking_set : @app.SystemSet = @picking.picking_set

///|
pub let picking_set_events : @app.SystemSet = @picking.picking_set_events

///|
pub let picking_set_hits : @app.SystemSet = @picking.picking_set_hits

///|
pub let picking_set_input : @app.SystemSet = @picking.picking_set_input

///|
pub fn picking_apply_a11y_actions_system(world : @ecs.World) -> Unit {
  @picking.picking_apply_a11y_actions_system(world)
}

///|
pub fn picking_clear_system(world : @ecs.World) -> Unit {
  @picking.picking_clear_system(world)
}

///|
pub fn picking_collect_mouse_system(world : @ecs.World) -> Unit {
  @picking.picking_collect_mouse_system(world)
}

///|
pub fn picking_generate_events_system(world : @ecs.World) -> Unit {
  @picking.picking_generate_events_system(world)
}

///|
pub fn picking_hover_pipeline_system(world : @ecs.World) -> Unit {
  @picking.picking_hover_pipeline_system(world)
}

///|
pub fn picking_process_pointer_inputs_system(world : @ecs.World) -> Unit {
  @picking.picking_process_pointer_inputs_system(world)
}

///|
pub fn picking_update_pointer_interactions_system(world : @ecs.World) -> Unit {
  @picking.picking_update_pointer_interactions_system(world)
}

///|
pub fn picking_mesh3d_hit_test_system(world : @ecs.World) -> Unit {
  @picking.picking_mesh3d_hit_test_system(world)
}

///|
pub fn picking_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @picking.picking_plugin(app)
}

///|
pub fn picking_sprite2d_hit_test_system(world : @ecs.World) -> Unit {
  @picking.picking_sprite2d_hit_test_system(world)
}

///|
pub fn picking_ui_hit_test_system(world : @ecs.World) -> Unit {
  @picking.picking_ui_hit_test_system(world)
}
