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
// Bridge surface to the root `picking` package implementation.
pub using @picking {type PickingHits}

///|
pub using @picking {type PickingState}

///|
pub using @picking {type PointerButton}

///|
pub using @picking {type PointerInput}

///|
pub using @picking {type PointerInputs}

///|
pub let ecs_res_key_picking_hits : @ecs.ResourceKey[@picking.PickingHits] = @picking.ecs_res_key_picking_hits

///|
pub let ecs_res_key_picking_state : @ecs.ResourceKey[@picking.PickingState] = @picking.ecs_res_key_picking_state

///|
pub let ecs_res_key_pointer_inputs : @ecs.ResourceKey[@picking.PointerInputs] = @picking.ecs_res_key_pointer_inputs

///|
pub fn ensure_picking_hits_system(world : @ecs.World) -> Unit {
  @picking.ensure_picking_hits_system(world)
}

///|
pub fn ensure_picking_state_system(world : @ecs.World) -> Unit {
  @picking.ensure_picking_state_system(world)
}

///|
pub fn ensure_pointer_inputs_system(world : @ecs.World) -> Unit {
  @picking.ensure_pointer_inputs_system(world)
}

///|
pub fn get_picking_hits_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[@picking.PickingHits] {
  @picking.get_picking_hits_resource(world)
}

///|
pub fn get_picking_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[@picking.PickingState] {
  @picking.get_picking_state_resource(world)
}

///|
pub fn get_pointer_inputs_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[@picking.PointerInputs] {
  @picking.get_pointer_inputs_resource(world)
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
