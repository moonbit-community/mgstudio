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
test "picking: hover map coalesces PointerHits by order and Pickable blocking" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  world.init_message(pointer_hits_message_key())
  let lower = world.spawn_empty()
  let top = world.spawn_empty()
  try! world.set_by_key(top, ecs_key_pickable, Pickable::new(false, true))
  let hit_lower = HitData::new(lower, 0.0F, None, None)
  let hit_top = HitData::new(top, 0.0F, None, None)
  world.send_message(
    pointer_hits_message_key(),
    PointerHits::new(0, [(lower, hit_lower)], 0.0F),
  )
  |> ignore
  world.send_message(
    pointer_hits_message_key(),
    PointerHits::new(0, [(top, hit_top)], 1.0F),
  )
  |> ignore
  picking_generate_hovermap_system(world)
  let hover = get_hover_map_resource(world).get().unwrap_or(HoverMap::default())
  let entries = hover.get(0)
  debug_inspect(entries.length(), content="2")
  debug_inspect(hover.is_hovering(0, top), content="true")
  debug_inspect(hover.is_hovering(0, lower), content="true")
}

///|
test "picking: hover map stops at default blocking entity" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  world.init_message(pointer_hits_message_key())
  let lower = world.spawn_empty()
  let top = world.spawn_empty()
  let hit_lower = HitData::new(lower, 0.0F, None, None)
  let hit_top = HitData::new(top, 0.0F, None, None)
  world.send_message(
    pointer_hits_message_key(),
    PointerHits::new(0, [(lower, hit_lower)], 0.0F),
  )
  |> ignore
  world.send_message(
    pointer_hits_message_key(),
    PointerHits::new(0, [(top, hit_top)], 1.0F),
  )
  |> ignore
  picking_generate_hovermap_system(world)
  let hover = get_hover_map_resource(world).get().unwrap_or(HoverMap::default())
  let entries = hover.get(0)
  debug_inspect(entries.length(), content="1")
  debug_inspect(hover.is_hovering(0, top), content="true")
  debug_inspect(hover.is_hovering(0, lower), content="false")
}

///|
test "picking: pointer events use HoverMap as hit source" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  world.init_message(pointer_input_message_key())
  world.send_message(
    pointer_input_message_key(),
    PointerInput::new(0, Some(@math.Vec2::new(5.0F, 6.0F)), false, false, false),
  )
  |> ignore
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  let target = world.spawn_empty()
  get_hover_map_resource(world).insert(
    HoverMap::from_array([
      (0, [(target, HitData::new(target, 0.0F, None, None))]),
    ]),
  )
  picking_generate_events_system(world)
  let events_res = @app.get_picking_events_resource(world)
  let events = events_res.get().unwrap_or(@app.PickingEvents::default())
  let out = @app.PickingEvents::drain_all(events)
  debug_inspect(out.length(), content="2")
  debug_inspect(out[1].target.unwrap().id == target.id, content="true")
}

///|
test "picking: pointer events can be generated from PointerInput messages" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  world.init_message(pointer_input_message_key())
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  let target = world.spawn_empty()
  get_hover_map_resource(world).insert(
    HoverMap::from_array([
      (0, [(target, HitData::new(target, 0.0F, None, None))]),
    ]),
  )
  world.send_message(
    pointer_input_message_key(),
    PointerInput::new(0, Some(@math.Vec2::new(7.0F, 8.0F)), false, false, false),
  )
  |> ignore
  picking_generate_events_system(world)
  let events_res = @app.get_picking_events_resource(world)
  let events = events_res.get().unwrap_or(@app.PickingEvents::default())
  let out = @app.PickingEvents::drain_all(events)
  debug_inspect(out.length(), content="2")
  debug_inspect(
    out[0].kind == @pointer_events.PointerEventKind::Move,
    content="true",
  )
  debug_inspect(
    out[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  debug_inspect(out[1].target.unwrap().id == target.id, content="true")
}

///|
test "picking: hover pipeline updates PointerInteraction on pointer entity" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  world.init_message(pointer_hits_message_key())
  let pointer_entity = world.spawn_empty()
  try! world.set_by_key(pointer_entity, ecs_key_pointer_id, PointerId::mouse())
  try! world.set_by_key(
    pointer_entity,
    ecs_key_pointer_interaction,
    PointerInteraction::default(),
  )
  let target = world.spawn_empty()
  world.send_message(
    pointer_hits_message_key(),
    PointerHits::new(
      0,
      [(target, HitData::new(target, 3.0F, None, None))],
      1.0F,
    ),
  )
  |> ignore
  picking_hover_pipeline_system(world)
  let interaction = (try! world.get_by_key(
    pointer_entity, ecs_key_pointer_interaction,
  )).unwrap()
  let nearest = interaction.get_nearest_hit().unwrap()
  debug_inspect(nearest.0.id == target.id, content="true")
  debug_inspect(nearest.1.depth.to_double(), content="3")
}
