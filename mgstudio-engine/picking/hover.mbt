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

///|
fn picking_resolve_hit_candidate(
  world : @ecs.World,
  candidate : @core.Entity,
) -> (@core.Entity?, Bool) {
  let pickable_opt = try world.get_by_key(candidate, ecs_key_pickable) catch {
    _ => None
  } noraise {
    value => value
  }
  match pickable_opt {
    Some(pickable) =>
      if pickable.is_hoverable {
        (Some(candidate), true)
      } else if pickable.should_block_lower {
        (None, true)
      } else {
        (None, false)
      }
    None => (Some(candidate), true)
  }
}

///|
fn picking_primary_hit(
  world : @ecs.World,
  hits : PickingHits,
  pointer : @pointer_events.PointerId,
) -> @core.Entity? {
  let candidates : Array[@core.Entity?] = [
    PickingHits::ui(hits, pointer),
    PickingHits::sprite2d(hits, pointer),
    PickingHits::mesh3d(hits, pointer),
    PickingHits::window(hits, pointer),
  ]
  for candidate in candidates {
    match candidate {
      Some(entity) => {
        let (target, should_stop) = picking_resolve_hit_candidate(world, entity)
        if should_stop {
          return target
        }
      }
      None => ()
    }
  }
  None
}
