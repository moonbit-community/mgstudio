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
fn drain_events(world : @ecs.World) -> Array[@pointer_events.PointerEvent] {
  let events_res = @app.get_picking_events_resource(world)
  guard events_res.get() is Some(events_value) else { return [] }
  let events = Ref::new(events_value)
  let out = @app.PickingEvents::drain(events)
  events_res.insert(events.val)
  out
}

///|
fn set_frame(
  world : @ecs.World,
  inputs : PointerInputs,
  hits : PickingHits,
) -> Unit {
  get_pointer_inputs_resource(world).insert(inputs)
  get_picking_hits_resource(world).insert(hits)
  picking_clear_system(world)
  picking_generate_events_system(world)
}

///|
test "picking: generates enter/leave and click events (single pointer)" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_picking_hits_resource(world).insert(PickingHits::default())
  let e1 = @core.Entity::new(1, 0)
  let e2 = @core.Entity::new(2, 0)
  let pos0 = @math.Vec2::new(10.0F, 20.0F)
  let pos1 = @math.Vec2::new(11.0F, 20.0F)

  // Frame 1: hover e1.
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos0), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1)], [None]),
  )
  let ev0 = drain_events(world)
  inspect(ev0.length(), content="2")
  inspect(ev0[0].kind == @pointer_events.PointerEventKind::Move, content="true")
  inspect(
    ev0[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  inspect(ev0[1].target.unwrap().id == e1.id, content="true")

  // Frame 2: move (same hit).
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1)], [None]),
  )
  let ev1 = drain_events(world)
  inspect(ev1.length(), content="1")
  inspect(ev1[0].kind == @pointer_events.PointerEventKind::Move, content="true")

  // Frame 3: switch hover to e2.
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev2 = drain_events(world)
  inspect(ev2.length(), content="2")
  inspect(
    ev2[0].kind == @pointer_events.PointerEventKind::Leave,
    content="true",
  )
  inspect(ev2[0].target.unwrap().id == e1.id, content="true")
  inspect(
    ev2[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  inspect(ev2[1].target.unwrap().id == e2.id, content="true")

  // Frame 4: press e2.
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), true, true, false),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev3 = drain_events(world)
  inspect(ev3.length(), content="1")
  inspect(ev3[0].kind == @pointer_events.PointerEventKind::Down, content="true")
  inspect(ev3[0].target.unwrap().id == e2.id, content="true")

  // Frame 5: release on e2 (click).
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, true),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev4 = drain_events(world)
  inspect(ev4.length(), content="2")
  inspect(ev4[0].kind == @pointer_events.PointerEventKind::Up, content="true")
  inspect(
    ev4[1].kind == @pointer_events.PointerEventKind::Click,
    content="true",
  )
}

///|
test "picking: handles multiple pointers independently" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_picking_hits_resource(world).insert(PickingHits::default())
  let e1 = @core.Entity::new(1, 0)
  let e2 = @core.Entity::new(2, 0)
  let p0 = @math.Vec2::new(5.0F, 5.0F)
  let p1 = @math.Vec2::new(15.0F, 15.0F)
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(p0), false, false, false),
      PointerInput::new(1, Some(p1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1), Some(e2)], [None, None]),
  )
  let events = drain_events(world)
  inspect(events.length(), content="4")
  inspect(events[0].pointer == 0, content="true")
  inspect(events[1].pointer == 0, content="true")
  inspect(events[2].pointer == 1, content="true")
  inspect(events[3].pointer == 1, content="true")
  inspect(
    events[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  inspect(
    events[3].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
}

///|
test "picking: a11y focus action maps to hovered interaction" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
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
  state_res.insert(state.val)
  picking_apply_a11y_actions_system(world)
  let interaction = try! world.get_by_key(entity, @ui.ecs_key_interaction)
  inspect(interaction is Some(@ui.Interaction::Hovered), content="true")
}

///|
test "picking: a11y scroll actions update ScrollPosition without click events" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @ui.ecs_key_node,
    @ui.Node::default().with_overflow(
      @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Scroll),
    ),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_ui_layout,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(100.0F, 100.0F),
      ),
    ),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_scroll_position,
    @ui.ScrollPosition::default(),
  )
  let child = world.spawn_empty()
  try! world.set_by_key(
    child,
    @ui.ecs_key_ui_layout,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(100.0F, 260.0F),
      ),
    ),
  )
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([child]),
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
  state_res.insert(state.val)
  picking_apply_a11y_actions_system(world)
  let scroll = try! world.get_by_key(entity, @ui.ecs_key_scroll_position)
  inspect(
    scroll is Some(v) && v.offset_x == 0.0F && v.offset_y == 24.0F,
    content="true",
  )
  let events = drain_events(world)
  inspect(events.length(), content="0")
}

///|
test "picking: a11y set-value action updates Text content" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new("Old"))
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
  state_res.insert(state.val)
  picking_apply_a11y_actions_system(world)
  inspect(
    world.get_by_key(entity, @text.ecs_key_text).unwrap().content,
    content="Updated",
  )
  let events = drain_events(world)
  inspect(events.length(), content="0")
}

///|
test "picking: ignores a11y actions targeting non-alive entities" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  @a11y.get_a11y_state_resource(world).insert(@a11y.A11yState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
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
  state_res.insert(state.val)
  picking_apply_a11y_actions_system(world)
  let state_after = @a11y.get_a11y_state_resource(world).get().unwrap()
  inspect(
    state_after.focused_node() == @moon_accesskit.NodeId::root(),
    content="true",
  )
  inspect(
    try! (world.get_by_key(dead_entity, @ui.ecs_key_interaction) is None),
    content="true",
  )
  let events = drain_events(world)
  inspect(events.length(), content="0")
}

///|
test "picking: pointer observers dispatch generated move enter and leave events" {
  let seen : Array[String] = []
  let mut app = @app.App::new(@ecs.World::new()).add_pointer_observer(fn(
    pointer : @app.OnPointer[@app.PointerMove],
  ) {
    if pointer.target() is Some(target) {
      seen.push("move:" + target.id.to_string())
    }
  })
  app = app.add_pointer_observer(fn(
    pointer : @app.OnPointer[@app.PointerEnter],
  ) {
    if pointer.target() is Some(target) {
      seen.push("enter:" + target.id.to_string())
    }
  })
  app = app.add_pointer_observer(fn(
    pointer : @app.OnPointer[@app.PointerLeave],
  ) {
    if pointer.target() is Some(target) {
      seen.push("leave:" + target.id.to_string())
    }
  })
  let world = app.world()
  let tick = world.advance_sequence()
  ignore(tick)
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_picking_hits_resource(world).insert(PickingHits::default())

  let e1 = @core.Entity::new(1, 0)
  let e2 = @core.Entity::new(2, 0)
  let pos = @math.Vec2::new(10.0F, 20.0F)

  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1)], [None]),
  )
  @app.dispatch_pointer_observers_system(world)

  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  @app.dispatch_pointer_observers_system(world)

  inspect(seen, content="[\"move:1\", \"enter:1\", \"leave:1\", \"enter:2\"]")
}
