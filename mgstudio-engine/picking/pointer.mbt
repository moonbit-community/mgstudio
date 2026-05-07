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
// Bevy source: `bevy/crates/bevy_picking/src/pointer.rs`.
/// Pointer input/button types and pointer-focused helpers.

///|
pub struct PointerId {
  value : @pointer_events.PointerId
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn PointerId::new(value : @pointer_events.PointerId) -> PointerId {
  PointerId::{ value, }
}

///|
pub fn PointerId::mouse() -> PointerId {
  PointerId::{ value: 0 }
}

///|
pub fn PointerId::touch(touch_id : Int) -> PointerId {
  PointerId::{ value: if touch_id >= 0 { touch_id + 1 } else { 1 } }
}

///|
pub fn PointerId::value(self : PointerId) -> @pointer_events.PointerId {
  self.value
}

///|
pub fn PointerId::is_mouse(self : PointerId) -> Bool {
  self.value == 0
}

///|
pub fn PointerId::is_touch(self : PointerId) -> Bool {
  self.value > 0
}

///|
pub fn PointerId::get_touch_id(self : PointerId) -> Int? {
  if self.value > 0 {
    Some(self.value - 1)
  } else {
    None
  }
}

///|
pub impl @ecs.Component for PointerId with component() {
  ecs_key_pointer_id
}

///|
pub struct PointerLocation {
  location : @math.Vec2?
} derive(ToJson, FromJson)

///|
pub fn PointerLocation::default() -> PointerLocation {
  PointerLocation::{ location: None }
}

///|
pub fn PointerLocation::new(location : @math.Vec2) -> PointerLocation {
  PointerLocation::{ location: Some(location) }
}

///|
pub fn PointerLocation::location(self : PointerLocation) -> @math.Vec2? {
  self.location
}

///|
pub impl @ecs.Component for PointerLocation with component() {
  ecs_key_pointer_location
}

///|
pub struct PointerPress {
  primary : Bool
  secondary : Bool
  middle : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn PointerPress::default() -> PointerPress {
  PointerPress::{ primary: false, secondary: false, middle: false }
}

///|
pub fn PointerPress::is_primary_pressed(self : PointerPress) -> Bool {
  self.primary
}

///|
pub fn PointerPress::is_secondary_pressed(self : PointerPress) -> Bool {
  self.secondary
}

///|
pub fn PointerPress::is_middle_pressed(self : PointerPress) -> Bool {
  self.middle
}

///|
pub fn PointerPress::is_any_pressed(self : PointerPress) -> Bool {
  self.primary || self.secondary || self.middle
}

///|
pub impl @ecs.Component for PointerPress with component() {
  ecs_key_pointer_press
}

///|
pub struct PointerInteraction {
  sorted_entities : Array[(@core.Entity, HitData)]
} derive(ToJson, FromJson)

///|
pub fn PointerInteraction::default() -> PointerInteraction {
  PointerInteraction::{ sorted_entities: [] }
}

///|
pub fn PointerInteraction::get_nearest_hit(
  self : PointerInteraction,
) -> (@core.Entity, HitData)? {
  if self.sorted_entities.length() == 0 {
    None
  } else {
    Some(self.sorted_entities[0])
  }
}

///|
pub impl @ecs.Component for PointerInteraction with component() {
  ecs_key_pointer_interaction
}

///|
pub struct PointerMap {
  inner : @hashmap.HashMap[@pointer_events.PointerId, @core.Entity]
}

///|
pub fn PointerMap::default() -> PointerMap {
  PointerMap::{ inner: @hashmap.HashMap([]) }
}

///|
pub fn PointerMap::get_entity(
  self : PointerMap,
  pointer_id : @pointer_events.PointerId,
) -> @core.Entity? {
  self.inner.get(pointer_id)
}

///|
pub impl @app.Resource for PointerMap with resource() {
  ecs_res_key_pointer_map
}

///|
pub fn ensure_pointer_map_system(world : @ecs.World) -> Unit {
  let res = get_pointer_map_resource(world)
  if res.get() is None {
    res.insert(PointerMap::default())
  }
}

///|
pub fn update_pointer_map_system(world : @ecs.World) -> Unit {
  let map = @hashmap.HashMap([])
  world.for_each_component(ecs_key_pointer_id, fn(entity, id) {
    map.set(id.value(), entity)
  })
  get_pointer_map_resource(world).insert(PointerMap::{ inner: map })
}

///|
fn pointer_entity_for_id(
  world : @ecs.World,
  pointer_id : @pointer_events.PointerId,
) -> @core.Entity? {
  match get_pointer_map_resource(world).get() {
    Some(map) =>
      match map.get_entity(pointer_id) {
        Some(entity) => Some(entity)
        None => {
          let found : Ref[@core.Entity?] = Ref(None)
          world.for_each_component(ecs_key_pointer_id, fn(entity, id) {
            if found.val is None && id.value() == pointer_id {
              found.val = Some(entity)
            }
          })
          found.val
        }
      }
    None => {
      let found : Ref[@core.Entity?] = Ref(None)
      world.for_each_component(ecs_key_pointer_id, fn(entity, id) {
        if found.val is None && id.value() == pointer_id {
          found.val = Some(entity)
        }
      })
      found.val
    }
  }
}

///|
fn ensure_pointer_entity(
  world : @ecs.World,
  pointer_id : @pointer_events.PointerId,
  location : @math.Vec2?,
) -> @core.Entity {
  let entity = match pointer_entity_for_id(world, pointer_id) {
    Some(entity) => entity
    None => world.spawn_empty()
  }
  if !(try! world.contains_by_key(entity, ecs_key_pointer_id)) {
    try! world.set_by_key(
      entity,
      ecs_key_pointer_id,
      PointerId::new(pointer_id),
    )
  }
  if !(try! world.contains_by_key(entity, ecs_key_pointer_location)) {
    try! world.set_by_key(entity, ecs_key_pointer_location, PointerLocation::{
      location,
    })
  }
  if !(try! world.contains_by_key(entity, ecs_key_pointer_press)) {
    try! world.set_by_key(
      entity,
      ecs_key_pointer_press,
      PointerPress::default(),
    )
  }
  if !(try! world.contains_by_key(entity, ecs_key_pointer_interaction)) {
    try! world.set_by_key(
      entity,
      ecs_key_pointer_interaction,
      PointerInteraction::default(),
    )
  }
  entity
}

///|
pub fn spawn_mouse_pointer_system(world : @ecs.World) -> Unit {
  ignore(ensure_pointer_entity(world, PointerId::mouse().value(), None))
  update_pointer_map_system(world)
}

///|
priv struct PointerInputReaderState {
  mut cursor : Int
}

///|
fn PointerInputReaderState::default() -> PointerInputReaderState {
  { cursor: 0 }
}

///|
let pointer_input_reader_state_resource_key : @ecs.ResourceKey[
  PointerInputReaderState,
] = @ecs.register_resource(
  debug_name="mgstudio_picking::PointerInputReaderState",
)

///|
fn ensure_pointer_input_reader_state(world : @ecs.World) -> Unit {
  let res = world.resource(pointer_input_reader_state_resource_key)
  if !res.is_present() {
    res.insert(PointerInputReaderState::default())
  }
}

///|
fn read_pending_pointer_inputs(world : @ecs.World) -> Array[PointerInput] {
  if !world.contains_message(pointer_input_message_key()) {
    return []
  }
  ensure_pointer_input_reader_state(world)
  let state_res = world.resource(pointer_input_reader_state_resource_key)
  guard state_res.get() is Some(state_value) else { return [] }
  let state_ref = Ref(state_value)
  let cursor = Ref(state_ref.val.cursor)
  let reader = world.message_reader(pointer_input_message_key(), cursor)
  let messages = try! reader.read()
  state_ref.val.cursor = cursor.val
  state_res.insert(state_ref.val)
  messages
}

///|
pub fn pointer_input_receive_system(world : @ecs.World) -> Unit {
  let messages = read_pending_pointer_inputs(world)
  for input in messages {
    let entity = ensure_pointer_entity(
      world,
      input.pointer,
      input.window_position,
    )
    let location = PointerLocation::{ location: input.window_position }
    if (try! world.contains_by_key(entity, ecs_key_pointer_location)) {
      try! (world.replace(entity, ecs_key_pointer_location, location) |> ignore)
    } else {
      try! world.set_by_key(entity, ecs_key_pointer_location, location)
    }
    let prev_press = match
      (try! world.get_by_key(entity, ecs_key_pointer_press)) {
      Some(value) => value
      None => PointerPress::default()
    }
    let primary = if input.just_pressed {
      true
    } else if input.just_released {
      false
    } else {
      input.down
    }
    let press = PointerPress::{
      primary,
      secondary: prev_press.secondary,
      middle: prev_press.middle,
    }
    if (try! world.contains_by_key(entity, ecs_key_pointer_press)) {
      try! (world.replace(entity, ecs_key_pointer_press, press) |> ignore)
    } else {
      try! world.set_by_key(entity, ecs_key_pointer_press, press)
    }
  }
  update_pointer_map_system(world)
}

///|
pub fn picking_process_pointer_inputs_system(world : @ecs.World) -> Unit {
  ensure_pointer_map_system(world)
  update_pointer_map_system(world)
  pointer_input_receive_system(world)
}

///|
pub fn pointer_inputs_from_entities(world : @ecs.World) -> Array[PointerInput] {
  let inputs : Array[PointerInput] = []
  world.for_each_component(ecs_key_pointer_id, fn(entity, id) {
    let location = match
      (try! world.get_by_key(entity, ecs_key_pointer_location)) {
      Some(value) => value.location()
      None => None
    }
    let press = match (try! world.get_by_key(entity, ecs_key_pointer_press)) {
      Some(value) => value
      None => PointerPress::default()
    }
    inputs.push(
      PointerInput::new(
        id.value(),
        location,
        press.is_primary_pressed(),
        false,
        false,
      ),
    )
  })
  inputs
}

///|
pub fn pointer_inputs_for_backend(world : @ecs.World) -> Array[PointerInput] {
  pointer_inputs_from_entities(world)
}

///|
pub struct PointerInput {
  pointer : @pointer_events.PointerId
  window_position : @math.Vec2?
  down : Bool
  just_pressed : Bool
  just_released : Bool
} derive(ToJson, FromJson)

///|
pub fn PointerInput::new(
  pointer : @pointer_events.PointerId,
  window_position : @math.Vec2?,
  down : Bool,
  just_pressed : Bool,
  just_released : Bool,
) -> PointerInput {
  PointerInput::{ pointer, window_position, down, just_pressed, just_released }
}

///|
pub fn pointer_input_message_key() -> @ecs.MessageKey[PointerInput] {
  ecs_msg_key_pointer_input
}

///|
pub impl @ecs.Message for PointerInput with message() {
  ecs_msg_key_pointer_input
}

///|
pub(all) enum PointerButton {
  Primary
  Secondary
  Middle
} derive(Eq, Debug)
