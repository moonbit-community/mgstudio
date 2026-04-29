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
pub let ecs_components : Array[String] = [
  "Pickable", "PointerId", "PointerInteraction", "PointerLocation", "PointerPress",
  "SpritePickingCamera",
]

///|
pub let ecs_resources : Array[String] = [
  "HoverMap", "PickingSettings", "PickingState", "PointerInputSettings", "PointerMap",
  "PreviousHoverMap", "SpritePickingSettings",
]

///|
pub let ecs_msg_key_pointer_input : @ecs.MessageKey[PointerInput] = @ecs.register_message(
  debug_name="mgstudio_picking::PointerInput",
)

///|
pub let ecs_msg_key_pointer_hits : @ecs.MessageKey[PointerHits] = @ecs.register_message(
  debug_name="mgstudio_picking::PointerHits",
)

///|
pub let ecs_key_pickable : @ecs.ComponentKey[Pickable] = @ecs.register_component(
  debug_name="picking.pickable",
)

///|
pub let ecs_key_pointer_id : @ecs.ComponentKey[PointerId] = @ecs.register_component(
  debug_name="mgstudio_picking::PointerId",
)

///|
pub let ecs_key_pointer_location : @ecs.ComponentKey[PointerLocation] = @ecs.register_component(
  debug_name="mgstudio_picking::PointerLocation",
)

///|
pub let ecs_key_pointer_press : @ecs.ComponentKey[PointerPress] = @ecs.register_component(
  debug_name="mgstudio_picking::PointerPress",
)

///|
pub let ecs_key_pointer_interaction : @ecs.ComponentKey[PointerInteraction] = @ecs.register_component(
  debug_name="mgstudio_picking::PointerInteraction",
)

///|
pub let ecs_key_sprite_picking_camera : @ecs.ComponentKey[SpritePickingCamera] = @ecs.register_component(
  debug_name="mgstudio_picking::SpritePickingCamera",
)

///|
pub let ecs_res_key_hover_map : @ecs.ResourceKey[HoverMap] = @ecs.register_resource(
  debug_name="picking.hover_map",
)

///|
pub let ecs_res_key_previous_hover_map : @ecs.ResourceKey[PreviousHoverMap] = @ecs.register_resource(
  debug_name="picking.previous_hover_map",
)

///|
pub let ecs_res_key_pointer_map : @ecs.ResourceKey[PointerMap] = @ecs.register_resource(
  debug_name="mgstudio_picking::PointerMap",
)

///|
pub let ecs_res_key_picking_settings : @ecs.ResourceKey[PickingSettings] = @ecs.register_resource(
  debug_name="picking.picking_settings",
)

///|
pub let ecs_res_key_picking_state : @ecs.ResourceKey[PickingState] = @ecs.register_resource(
  debug_name="picking.picking_state",
)

///|
pub let ecs_res_key_pointer_input_settings : @ecs.ResourceKey[
  PointerInputSettings,
] = @ecs.register_resource(debug_name="picking.pointer_input_settings")

///|
pub let ecs_res_key_sprite_picking_settings : @ecs.ResourceKey[
  SpritePickingSettings,
] = @ecs.register_resource(debug_name="mgstudio_picking::SpritePickingSettings")

///|
pub fn get_hover_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[HoverMap] {
  world.resource(ecs_res_key_hover_map)
}

///|
pub fn get_previous_hover_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PreviousHoverMap] {
  world.resource(ecs_res_key_previous_hover_map)
}

///|
pub fn get_picking_settings_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PickingSettings] {
  world.resource(ecs_res_key_picking_settings)
}

///|
pub fn get_pointer_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointerMap] {
  world.resource(ecs_res_key_pointer_map)
}

///|
pub fn get_picking_state_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PickingState] {
  world.resource(ecs_res_key_picking_state)
}

///|
pub fn get_pointer_input_settings_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointerInputSettings] {
  world.resource(ecs_res_key_pointer_input_settings)
}

///|
pub fn get_sprite_picking_settings_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[SpritePickingSettings] {
  world.resource(ecs_res_key_sprite_picking_settings)
}
