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
fn drain_events(world : @ecs.World, tick : Int) -> Array[PointerEvent] {
  let events_res = get_picking_events_resource(world)
  guard events_res.get() is Some(events_value) else { return [] }
  let events = Ref::new(events_value)
  let out = PickingEvents::drain(events)
  events_res.insert(events.val, tick)
  out
}

///|
fn set_frame(
  world : @ecs.World,
  tick : Int,
  inputs : PointerInputs,
  hits : PickingHits,
) -> Unit {
  get_pointer_inputs_resource(world).insert(inputs, tick)
  get_picking_hits_resource(world).insert(hits, tick)
  picking_clear_system(world)
  picking_generate_events_system(world)
}

///|
test "picking: generates enter/leave and click events (single pointer)" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  get_picking_state_resource(world).insert(PickingState::default(), tick)
  get_picking_events_resource(world).insert(PickingEvents::default(), tick)
  get_pointer_inputs_resource(world).insert(PointerInputs::default(), tick)
  get_picking_hits_resource(world).insert(PickingHits::default(), tick)
  let e1 = @core.Entity::new(1, 0)
  let e2 = @core.Entity::new(2, 0)
  let pos0 = @math.Vec2::new(10.0F, 20.0F)
  let pos1 = @math.Vec2::new(11.0F, 20.0F)

  // Frame 1: hover e1.
  set_frame(
    world,
    tick,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos0), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1)], [None]),
  )
  let ev0 = drain_events(world, tick)
  inspect(ev0.length(), content="2")
  inspect(ev0[0].kind == PointerEventKind::Move, content="true")
  inspect(ev0[1].kind == PointerEventKind::Enter, content="true")
  inspect(ev0[1].target.unwrap().id == e1.id, content="true")

  // Frame 2: move (same hit).
  set_frame(
    world,
    tick,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1)], [None]),
  )
  let ev1 = drain_events(world, tick)
  inspect(ev1.length(), content="1")
  inspect(ev1[0].kind == PointerEventKind::Move, content="true")

  // Frame 3: switch hover to e2.
  set_frame(
    world,
    tick,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev2 = drain_events(world, tick)
  inspect(ev2.length(), content="2")
  inspect(ev2[0].kind == PointerEventKind::Leave, content="true")
  inspect(ev2[0].target.unwrap().id == e1.id, content="true")
  inspect(ev2[1].kind == PointerEventKind::Enter, content="true")
  inspect(ev2[1].target.unwrap().id == e2.id, content="true")

  // Frame 4: press e2.
  set_frame(
    world,
    tick,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), true, true, false),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev3 = drain_events(world, tick)
  inspect(ev3.length(), content="1")
  inspect(ev3[0].kind == PointerEventKind::Down, content="true")
  inspect(ev3[0].target.unwrap().id == e2.id, content="true")

  // Frame 5: release on e2 (click).
  set_frame(
    world,
    tick,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, true),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev4 = drain_events(world, tick)
  inspect(ev4.length(), content="2")
  inspect(ev4[0].kind == PointerEventKind::Up, content="true")
  inspect(ev4[1].kind == PointerEventKind::Click, content="true")
}

///|
test "picking: handles multiple pointers independently" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  get_picking_state_resource(world).insert(PickingState::default(), tick)
  get_picking_events_resource(world).insert(PickingEvents::default(), tick)
  get_pointer_inputs_resource(world).insert(PointerInputs::default(), tick)
  get_picking_hits_resource(world).insert(PickingHits::default(), tick)
  let e1 = @core.Entity::new(1, 0)
  let e2 = @core.Entity::new(2, 0)
  let p0 = @math.Vec2::new(5.0F, 5.0F)
  let p1 = @math.Vec2::new(15.0F, 15.0F)
  set_frame(
    world,
    tick,
    PointerInputs::from_array([
      PointerInput::new(0, Some(p0), false, false, false),
      PointerInput::new(1, Some(p1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1), Some(e2)], [None, None]),
  )
  let events = drain_events(world, tick)
  inspect(events.length(), content="4")
  inspect(events[0].pointer == 0, content="true")
  inspect(events[1].pointer == 0, content="true")
  inspect(events[2].pointer == 1, content="true")
  inspect(events[3].pointer == 1, content="true")
  inspect(events[1].kind == PointerEventKind::Enter, content="true")
  inspect(events[3].kind == PointerEventKind::Enter, content="true")
}

///|
test "picking: a11y focus action maps to hovered interaction" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default(), tick)
  get_picking_events_resource(world).insert(PickingEvents::default(), tick)
  let entity = world.spawn_empty()
  let packed = entity.id * 65536 + entity.generation + 1
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    @moon_accesskit.NodeId::from_u64(packed.to_uint64()),
  )
  let state_res = @a11y.get_a11y_state_resource(world)
  let state = Ref::new(state_res.get().unwrap())
  @a11y.A11yState::push_action(state, req)
  state_res.insert(state.val, tick)
  picking_apply_a11y_actions_system(world)
  let interaction = @ui.get_interaction_store(world).get(entity)
  inspect(interaction is Some(@ui.Interaction::Hovered), content="true")
}

///|
test "picking: a11y scroll actions update ScrollPosition without click events" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default(), tick)
  get_picking_events_resource(world).insert(PickingEvents::default(), tick)
  let entity = world.spawn_empty()
  @ui.get_node_store(world).insert(
    entity,
    @ui.Node::default().with_overflow(
      @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Scroll),
    ),
    tick,
  )
  @ui.get_ui_layout_store(world).insert(
    entity,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(100.0F, 100.0F),
      ),
    ),
    tick,
  )
  @ui.get_scroll_position_store(world).insert(
    entity,
    @ui.ScrollPosition::default(),
    tick,
  )
  let child = world.spawn_empty()
  @ui.get_ui_layout_store(world).insert(
    child,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(100.0F, 260.0F),
      ),
    ),
    tick,
  )
  @hierarchy.get_children_store(world).insert(
    entity,
    @hierarchy.Children::new([child]),
    tick,
  )
  let packed = entity.id * 65536 + entity.generation + 1
  let node_id = @moon_accesskit.NodeId::from_u64(packed.to_uint64())
  let req_down = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::ScrollDown,
    @moon_accesskit.TreeId::root(),
    node_id,
  )
  let req_right = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::ScrollRight,
    @moon_accesskit.TreeId::root(),
    node_id,
  )
  let state_res = @a11y.get_a11y_state_resource(world)
  let state = Ref::new(state_res.get().unwrap())
  @a11y.A11yState::push_action(state, req_down)
  @a11y.A11yState::push_action(state, req_right)
  state_res.insert(state.val, tick)
  picking_apply_a11y_actions_system(world)
  let scroll = @ui.get_scroll_position_store(world).get(entity)
  inspect(
    scroll is Some(v) && v.offset_x == 0.0F && v.offset_y == 24.0F,
    content="true",
  )
  let events = drain_events(world, tick)
  inspect(events.length(), content="0")
}

///|
test "picking: a11y set-value action updates Text content" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default(), tick)
  get_picking_events_resource(world).insert(PickingEvents::default(), tick)
  let entity = world.spawn_empty()
  world
  .component(@text.ecs_key_text)
  .insert(entity, @text.Text::new("Old"), tick)
  let packed = entity.id * 65536 + entity.generation + 1
  let node_id = @moon_accesskit.NodeId::from_u64(packed.to_uint64())
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::SetValue,
    @moon_accesskit.TreeId::root(),
    node_id,
  )
  req.set_data(@moon_accesskit.ActionData::Value("Updated"))
  let state_res = @a11y.get_a11y_state_resource(world)
  let state = Ref::new(state_res.get().unwrap())
  @a11y.A11yState::push_action(state, req)
  state_res.insert(state.val, tick)
  picking_apply_a11y_actions_system(world)
  inspect(
    world.get(entity, @text.ecs_key_text).unwrap().content,
    content="Updated",
  )
  let events = drain_events(world, tick)
  inspect(events.length(), content="0")
}

///|
test "picking: ignores a11y actions targeting non-alive entities" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default(), tick)
  get_picking_events_resource(world).insert(PickingEvents::default(), tick)
  let dead_entity = @core.Entity::new(999, 1)
  let packed = dead_entity.id * 65536 + dead_entity.generation + 1
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    @moon_accesskit.NodeId::from_u64(packed.to_uint64()),
  )
  let state_res = @a11y.get_a11y_state_resource(world)
  let state = Ref::new(state_res.get().unwrap())
  @a11y.A11yState::push_action(state, req)
  state_res.insert(state.val, tick)
  picking_apply_a11y_actions_system(world)
  let state_after = @a11y.get_a11y_state_resource(world).get().unwrap()
  inspect(
    state_after.focused_node() == @moon_accesskit.NodeId::root(),
    content="true",
  )
  inspect(
    @ui.get_interaction_store(world).get(dead_entity) is None,
    content="true",
  )
  let events = drain_events(world, tick)
  inspect(events.length(), content="0")
}
