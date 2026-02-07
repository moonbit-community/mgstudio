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
fn drain_events(world : @ecs_world.World, tick : Int) -> Array[PointerEvent] {
  let events_res = HasRes_PickingEvents::get_picking_events_resource(world)
  let events = events_res.get_ref_mut(tick).unwrap()
  PickingEvents::drain(events)
}

///|
fn set_frame(
  world : @ecs_world.World,
  tick : Int,
  inputs : PointerInputs,
  hits : PickingHits,
) -> Unit {
  HasRes_PointerInputs::get_pointer_inputs_resource(world).insert(inputs, tick)
  HasRes_PickingHits::get_picking_hits_resource(world).insert(hits, tick)
  picking_clear_system(world)
  picking_generate_events_system(world)
}

///|
test "picking: generates enter/leave and click events (single pointer)" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  HasRes_PickingState::get_picking_state_resource(world).insert(
    PickingState::default(),
    tick,
  )
  HasRes_PickingEvents::get_picking_events_resource(world).insert(
    PickingEvents::default(),
    tick,
  )
  HasRes_PointerInputs::get_pointer_inputs_resource(world).insert(
    PointerInputs::default(),
    tick,
  )
  HasRes_PickingHits::get_picking_hits_resource(world).insert(
    PickingHits::default(),
    tick,
  )
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
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  HasRes_PickingState::get_picking_state_resource(world).insert(
    PickingState::default(),
    tick,
  )
  HasRes_PickingEvents::get_picking_events_resource(world).insert(
    PickingEvents::default(),
    tick,
  )
  HasRes_PointerInputs::get_pointer_inputs_resource(world).insert(
    PointerInputs::default(),
    tick,
  )
  HasRes_PickingHits::get_picking_hits_resource(world).insert(
    PickingHits::default(),
    tick,
  )
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
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  @a11y.HasRes_A11yState::get_a11y_state_resource(world).insert(
    @a11y.A11yState::default(),
    tick,
  )
  HasRes_PickingEvents::get_picking_events_resource(world).insert(
    PickingEvents::default(),
    tick,
  )
  let entity = @core.Entity::new(7, 3)
  let packed = entity.id * 65536 + entity.generation + 1
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    @moon_accesskit.NodeId::from_u64(packed.to_uint64()),
  )
  let state = @a11y.HasRes_A11yState::get_a11y_state_resource(world).get_ref_mut(
    tick,
  )
  @a11y.A11yState::push_action(state.unwrap(), req)
  picking_apply_a11y_actions_system(world)
  let interaction = @ui.Has_Interaction::get_interaction_store(world).get(
    entity,
  )
  inspect(interaction is Some(@ui.Interaction::Hovered), content="true")
}

///|
test "picking: a11y scroll actions update ScrollPosition without click events" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  @a11y.HasRes_A11yState::get_a11y_state_resource(world).insert(
    @a11y.A11yState::default(),
    tick,
  )
  HasRes_PickingEvents::get_picking_events_resource(world).insert(
    PickingEvents::default(),
    tick,
  )
  let entity = @core.Entity::new(9, 1)
  @ui.Has_Node::get_node_store(world).insert(
    entity,
    @ui.Node::default().with_overflow(
      @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Scroll),
    ),
    tick,
  )
  @ui.Has_UiLayout::get_ui_layout_store(world).insert(
    entity,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(100.0F, 100.0F),
      ),
    ),
    tick,
  )
  @ui.Has_ScrollPosition::get_scroll_position_store(world).insert(
    entity,
    @ui.ScrollPosition::default(),
    tick,
  )
  let child = @core.Entity::new(10, 1)
  @ui.Has_UiLayout::get_ui_layout_store(world).insert(
    child,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(100.0F, 260.0F),
      ),
    ),
    tick,
  )
  @hierarchy.Has_Children::get_children_store(world).insert(
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
  let state = @a11y.HasRes_A11yState::get_a11y_state_resource(world).get_ref_mut(
    tick,
  )
  @a11y.A11yState::push_action(state.unwrap(), req_down)
  @a11y.A11yState::push_action(state.unwrap(), req_right)
  picking_apply_a11y_actions_system(world)
  let scroll = @ui.Has_ScrollPosition::get_scroll_position_store(world).get(
    entity,
  )
  inspect(
    scroll is Some(v) && v.offset_x == 0.0F && v.offset_y == 24.0F,
    content="true",
  )
  let events = drain_events(world, tick)
  inspect(events.length(), content="0")
}

///|
test "picking: a11y set-value action updates UiText content" {
  let world = @ecs_world.World::new()
  let tick = @core.ChangeTickWorld::increment_change_tick(world)
  @a11y.HasRes_A11yState::get_a11y_state_resource(world).insert(
    @a11y.A11yState::default(),
    tick,
  )
  HasRes_PickingEvents::get_picking_events_resource(world).insert(
    PickingEvents::default(),
    tick,
  )
  let text_handle = @text.text_spawn(
    @text.Text2dBundle::new(
      @text.Text2d::new("Old"),
      @text.TextFont::default(),
      @math.Transform::identity(),
    ),
  )
  let entity = @core.Entity::new(11, 2)
  @ui.Has_UiText::get_ui_text_store(world).insert(
    entity,
    @ui.UiText::new(text_handle),
    tick,
  )
  let packed = entity.id * 65536 + entity.generation + 1
  let node_id = @moon_accesskit.NodeId::from_u64(packed.to_uint64())
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::SetValue,
    @moon_accesskit.TreeId::root(),
    node_id,
  )
  req.set_data(@moon_accesskit.ActionData::Value("Updated"))
  let state = @a11y.HasRes_A11yState::get_a11y_state_resource(world).get_ref_mut(
    tick,
  )
  @a11y.A11yState::push_action(state.unwrap(), req)
  picking_apply_a11y_actions_system(world)
  inspect(
    @text.text_get_content(text_handle).unwrap() == "Updated",
    content="true",
  )
  let events = drain_events(world, tick)
  inspect(events.length(), content="0")
}
