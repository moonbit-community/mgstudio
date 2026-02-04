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
/// Picking framework (UI + 2D + 3D). Initial implementation focuses on UI.
///
/// TODO: Implement hit-testing and event generation.

///|
pub type PointerId = Int

///|
pub(all) enum PointerButton {
  Primary
  Secondary
  Middle
} derive(Eq, Show)

///|
pub(all) enum PointerEventKind {
  Move
  Enter
  Leave
  Down
  Up
  Click
} derive(Eq, Show)

///|
pub struct PointerEvent {
  pointer : PointerId
  kind : PointerEventKind
  position : @math.Vec2
  target : @core.Entity?
}

///|
pub fn PointerEvent::new(
  pointer : PointerId,
  kind : PointerEventKind,
  position : @math.Vec2,
  target? : @core.Entity? = None,
) -> PointerEvent {
  PointerEvent::{ pointer, kind, position, target }
}

///|
/// Per-frame picking events produced by picking systems and consumed by UI.
#ecs.resource
pub struct PickingEvents {
  mut events : Array[PointerEvent]
}

///|
pub fn PickingEvents::default() -> PickingEvents {
  PickingEvents::{ events: [] }
}

///|
pub fn PickingEvents::push(self : Ref[PickingEvents], event : PointerEvent) -> Unit {
  self.val.events = self.val.events + [event]
}

///|
pub fn PickingEvents::drain(self : Ref[PickingEvents]) -> Array[PointerEvent] {
  let out = self.val.events
  self.val.events = []
  out
}

///|
/// Per-pointer picking state persisted across frames.
#ecs.resource
pub struct PickingState {
  mut hovered : @core.Entity?
  mut pressed : @core.Entity?
  mut last_position : @math.Vec2?
}

///|
pub fn PickingState::default() -> PickingState {
  PickingState::{ hovered: None, pressed: None, last_position: None }
}

///|
pub fn PickingState::set_hovered(
  self : Ref[PickingState],
  hovered : @core.Entity?,
) -> Unit {
  self.val.hovered = hovered
}

///|
pub fn PickingState::set_pressed(
  self : Ref[PickingState],
  pressed : @core.Entity?,
) -> Unit {
  self.val.pressed = pressed
}

///|
pub fn PickingState::set_last_position(
  self : Ref[PickingState],
  pos : @math.Vec2?,
) -> Unit {
  self.val.last_position = pos
}

///|
pub let picking_set : @app.SystemSet = @app.system_set("mgstudio.picking")

///|
pub fn[W : HasRes_PickingEvents + @core.ChangeTickWorld] picking_clear_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_PickingEvents::get_picking_events_resource(world).insert(
    PickingEvents::default(),
    tick,
  )
}

///|
pub fn[W : HasRes_PickingState + @core.ChangeTickWorld] ensure_picking_state_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_PickingState::get_picking_state_resource(world)
  if res.get() is None {
    res.insert(PickingState::default(), tick)
  }
}

///|
pub fn[W : HasRes_PickingEvents + HasRes_PickingState + @core.ChangeTickWorld] picking_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app.add_pre_update_system_config(
    @app.system(picking_clear_system).in_set(picking_set),
  )
  .add_pre_update_system_config(
    @app.system(ensure_picking_state_system).in_set(picking_set),
  )
}
