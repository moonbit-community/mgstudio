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
// Bevy source: `bevy/crates/bevy_picking/src/hover.rs`.
/// Picking state and hover mutation helpers.

///|
pub struct HoverMap {
  inner : @hashmap.HashMap[
    @pointer_events.PointerId,
    Array[(@core.Entity, HitData)],
  ]
}

///|
pub fn HoverMap::default() -> HoverMap {
  HoverMap::{ inner: @hashmap.HashMap::new() }
}

///|
pub fn HoverMap::from_array(
  entries : Array[(@pointer_events.PointerId, Array[(@core.Entity, HitData)])],
) -> HoverMap {
  HoverMap::{ inner: @hashmap.HashMap::from_array(entries) }
}

///|
pub fn HoverMap::get(
  self : HoverMap,
  pointer : @pointer_events.PointerId,
) -> Array[(@core.Entity, HitData)] {
  match self.inner.get(pointer) {
    Some(value) => value
    None => []
  }
}

///|
pub fn HoverMap::is_hovering(
  self : HoverMap,
  pointer : @pointer_events.PointerId,
  entity : @core.Entity,
) -> Bool {
  for entry in HoverMap::get(self, pointer) {
    if picking_entity_eq(entry.0, entity) {
      return true
    }
  }
  false
}

///|
fn HoverMap::nearest_entity(
  self : HoverMap,
  pointer : @pointer_events.PointerId,
) -> @core.Entity? {
  let entries = HoverMap::get(self, pointer)
  if entries.length() == 0 {
    None
  } else {
    Some(entries[0].0)
  }
}

///|
pub struct PreviousHoverMap {
  inner : @hashmap.HashMap[
    @pointer_events.PointerId,
    Array[(@core.Entity, HitData)],
  ]
}

///|
pub fn PreviousHoverMap::default() -> PreviousHoverMap {
  PreviousHoverMap::{ inner: @hashmap.HashMap::new() }
}

///|
pub impl @app.Resource for HoverMap with resource() {
  ecs_res_key_hover_map
}

///|
pub impl @app.Resource for PreviousHoverMap with resource() {
  ecs_res_key_previous_hover_map
}

///|
pub fn ensure_hover_maps_system(world : @ecs.World) -> Unit {
  let hover_res = get_hover_map_resource(world)
  if hover_res.get() is None {
    hover_res.insert(HoverMap::default())
  }
  let previous_res = get_previous_hover_map_resource(world)
  if previous_res.get() is None {
    previous_res.insert(PreviousHoverMap::default())
  }
}

///|
priv struct PickingPointerHitsReaderState {
  mut cursor : Int
}

///|
fn PickingPointerHitsReaderState::default() -> PickingPointerHitsReaderState {
  { cursor: 0 }
}

///|
let picking_pointer_hits_reader_state_resource_key : @ecs.ResourceKey[
  PickingPointerHitsReaderState,
] = @ecs.register_resource(
  debug_name="mgstudio_picking::PickingPointerHitsReaderState",
)

///|
fn ensure_picking_pointer_hits_reader_state(world : @ecs.World) -> Unit {
  let res = world.resource(picking_pointer_hits_reader_state_resource_key)
  if !res.is_present() {
    res.insert(PickingPointerHitsReaderState::default())
  }
}

///|
fn read_pending_pointer_hits(world : @ecs.World) -> Array[PointerHits] {
  if !world.contains_message(pointer_hits_message_key()) {
    return []
  }
  ensure_picking_pointer_hits_reader_state(world)
  let state_res = world.resource(picking_pointer_hits_reader_state_resource_key)
  guard state_res.get() is Some(state_value) else { return [] }
  let state_ref = Ref::new(state_value)
  let cursor = Ref::new(state_ref.val.cursor)
  let reader = world.message_reader(pointer_hits_message_key(), cursor)
  let messages = try! reader.read()
  state_ref.val.cursor = cursor.val
  state_res.insert(state_ref.val)
  messages
}

///|
fn picking_float_cmp_asc(a : Float, b : Float) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn picking_pointer_hit_cmp(
  a : (@pointer_events.PointerId, Float, @core.Entity, HitData),
  b : (@pointer_events.PointerId, Float, @core.Entity, HitData),
) -> Int {
  let pointer_cmp = a.0 - b.0
  if pointer_cmp != 0 {
    return pointer_cmp
  }
  let order_cmp = picking_float_cmp_asc(b.1, a.1)
  if order_cmp != 0 {
    return order_cmp
  }
  picking_float_cmp_asc(a.3.depth, b.3.depth)
}

///|
fn picking_hover_map_insert(
  map : @hashmap.HashMap[
    @pointer_events.PointerId,
    Array[(@core.Entity, HitData)],
  ],
  pointer : @pointer_events.PointerId,
  entity : @core.Entity,
  hit : HitData,
) -> Unit {
  let entries = match map.get(pointer) {
    Some(value) => value
    None => []
  }
  for entry in entries {
    if picking_entity_eq(entry.0, entity) {
      map.set(pointer, entries)
      return
    }
  }
  entries.push((entity, hit))
  map.set(pointer, entries)
}

///|
pub fn picking_generate_hovermap_system(world : @ecs.World) -> Unit {
  ensure_hover_maps_system(world)
  let previous_res = get_previous_hover_map_resource(world)
  let hover_res = get_hover_map_resource(world)
  let previous = match hover_res.get() {
    Some(current) => PreviousHoverMap::{ inner: current.inner.copy() }
    None => PreviousHoverMap::default()
  }
  let flat_hits : Array[
    (@pointer_events.PointerId, Float, @core.Entity, HitData),
  ] = []
  for message in read_pending_pointer_hits(world) {
    for pick in message.picks {
      flat_hits.push((message.pointer, message.order, pick.0, pick.1))
    }
  }
  flat_hits.sort_by(picking_pointer_hit_cmp)
  let next = @hashmap.HashMap::new()
  let blocked_pointers : @hashset.HashSet[@pointer_events.PointerId] = @hashset.HashSet::new()
  for entry in flat_hits {
    let pointer = entry.0
    if blocked_pointers.contains(pointer) {
      continue
    }
    let entity = entry.2
    let hit = entry.3
    let pickable_opt = try world.get_by_key(entity, ecs_key_pickable) catch {
      _ => None
    } noraise {
      value => value
    }
    match pickable_opt {
      Some(pickable) => {
        if pickable.is_hoverable {
          picking_hover_map_insert(next, pointer, entity, hit)
        }
        if pickable.should_block_lower {
          blocked_pointers.add(pointer)
        }
      }
      None => {
        picking_hover_map_insert(next, pointer, entity, hit)
        blocked_pointers.add(pointer)
      }
    }
  }
  previous_res.insert(previous)
  hover_res.insert(HoverMap::{ inner: next })
}

///|
fn picking_hit_depth_cmp(
  a : (@core.Entity, HitData),
  b : (@core.Entity, HitData),
) -> Int {
  picking_float_cmp_asc(a.1.depth, b.1.depth)
}

///|
pub fn picking_update_pointer_interactions_system(world : @ecs.World) -> Unit {
  let hover_map = match get_hover_map_resource(world).get() {
    Some(map) => map
    None => return
  }
  let pointers : Array[(@core.Entity, PointerId)] = []
  world.for_each_component(ecs_key_pointer_id, fn(entity, pointer_id) {
    pointers.push((entity, pointer_id))
  })
  for pointer in pointers {
    let entries = hover_map.get(pointer.1.value())
    entries.sort_by(picking_hit_depth_cmp)
    let interaction = PointerInteraction::{ sorted_entities: entries }
    if (try! world.contains_by_key(pointer.0, ecs_key_pointer_interaction)) {
      try! (world.replace(pointer.0, ecs_key_pointer_interaction, interaction)
      |> ignore)
    } else {
      try! world.set_by_key(pointer.0, ecs_key_pointer_interaction, interaction)
    }
  }
}

///|
pub fn picking_hover_pipeline_system(world : @ecs.World) -> Unit {
  picking_generate_hovermap_system(world)
  picking_update_pointer_interactions_system(world)
}

///|
/// Per-pointer picking state persisted across frames.
pub struct PickingState {
  hovered : Array[@core.Entity?]
  pressed : Array[@core.Entity?]
  last_position : Array[@math.Vec2?]
} derive(ToJson, FromJson)

///|
pub fn PickingState::default() -> PickingState {
  PickingState::{ hovered: [], pressed: [], last_position: [] }
}

///|
pub fn PickingState::hovered(
  self : PickingState,
  pointer : @pointer_events.PointerId,
) -> @core.Entity? {
  if pointer < 0 || pointer >= self.hovered.length() {
    None
  } else {
    self.hovered[pointer]
  }
}

///|
pub fn PickingState::pressed(
  self : PickingState,
  pointer : @pointer_events.PointerId,
) -> @core.Entity? {
  if pointer < 0 || pointer >= self.pressed.length() {
    None
  } else {
    self.pressed[pointer]
  }
}

///|
pub fn PickingState::last_position(
  self : PickingState,
  pointer : @pointer_events.PointerId,
) -> @math.Vec2? {
  if pointer < 0 || pointer >= self.last_position.length() {
    None
  } else {
    self.last_position[pointer]
  }
}

///|
fn PickingState::ensure_capacity(
  self : Ref[PickingState],
  pointer : @pointer_events.PointerId,
) -> Unit {
  if pointer < 0 {
    return
  }
  let need = pointer + 1
  while self.val.hovered.length() < need {
    self.val.hovered.push(None)
  }
  while self.val.pressed.length() < need {
    self.val.pressed.push(None)
  }
  while self.val.last_position.length() < need {
    self.val.last_position.push(None)
  }
}

///|
pub fn PickingState::set_pressed(
  self : Ref[PickingState],
  pointer : @pointer_events.PointerId,
  pressed : @core.Entity?,
) -> Unit {
  PickingState::ensure_capacity(self, pointer)
  self.val.pressed[pointer] = pressed
}

///|
pub fn PickingState::set_last_position(
  self : Ref[PickingState],
  pointer : @pointer_events.PointerId,
  pos : @math.Vec2?,
) -> Unit {
  PickingState::ensure_capacity(self, pointer)
  self.val.last_position[pointer] = pos
}

///|
pub fn PickingState::set_hovered(
  self : Ref[PickingState],
  pointer : @pointer_events.PointerId,
  hovered : @core.Entity?,
) -> Unit {
  PickingState::ensure_capacity(self, pointer)
  self.val.hovered[pointer] = hovered
}

///|
pub impl @app.Resource for PickingState with resource() {
  ecs_res_key_picking_state
}

///|
pub fn ensure_picking_state_system(world : @ecs.World) -> Unit {
  let res = get_picking_state_resource(world)
  if res.get() is None {
    res.insert(PickingState::default())
  }
}

///|
fn picking_entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn picking_option_entity_eq(a : @core.Entity?, b : @core.Entity?) -> Bool {
  match (a, b) {
    (None, None) => true
    (Some(x), Some(y)) => picking_entity_eq(x, y)
    _ => false
  }
}
