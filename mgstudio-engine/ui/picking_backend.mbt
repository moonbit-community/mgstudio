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
// Bevy source: `bevy/crates/bevy_ui/src/picking_backend.rs`.
pub fn ui_pointer_pos_in_viewport(
  mouse_pos : @math.Vec2,
  viewport_origin : @math.Vec2,
  viewport_size : @math.Vec2,
) -> @math.Vec2? {
  let pos_in_view = @math.Vec2::new(
    mouse_pos.x - viewport_origin.x,
    mouse_pos.y - viewport_origin.y,
  )
  if pos_in_view.x >= 0.0F &&
    pos_in_view.y >= 0.0F &&
    pos_in_view.x <= viewport_size.x &&
    pos_in_view.y <= viewport_size.y {
    Some(pos_in_view)
  } else {
    None
  }
}

///|
pub fn ui_pointer_pos_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
  pointer_window_pos : @math.Vec2,
) -> @math.Vec2? {
  let legacy_ctx = get_ui_context_resource(world).get()
  let entity_ctx = ui_entity_resolved_camera_state(world, entity, legacy_ctx)
  ui_pointer_pos_in_viewport(
    pointer_window_pos,
    entity_ctx.viewport_origin,
    entity_ctx.viewport_size,
  )
}

///|
pub fn ui_entity_contains_pointer(
  world : @ecs.World,
  entity : @core.Entity,
  pointer_window_pos : @math.Vec2,
) -> Bool {
  guard ui_pointer_pos_for_entity(world, entity, pointer_window_pos)
    is Some(pointer) else {
    return false
  }
  let legacy_ctx = get_ui_context_resource(world).get()
  let entity_ctx = ui_entity_resolved_camera_state(world, entity, legacy_ctx)
  guard (try! world.get_by_key(entity, ecs_key_ui_layout)) is Some(layout) else {
    return false
  }
  let node_rect = layout.rect
  if !ui_pointer_hit_for_entity_transform(
      world, entity, node_rect, pointer, entity_ctx,
    ) {
    return false
  }
  let (clip_rect, has_clip) = match
    (try! world.get_by_key(entity, ecs_key_calculated_clip)) {
    Some(v) => (v.clip, true)
    None => (node_rect, false)
  }
  let visible_rect = ui_rect_intersect(node_rect, clip_rect)
  if has_clip && !visible_rect.contains(pointer) {
    return false
  }
  true
}
