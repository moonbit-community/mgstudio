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
fn enqueue_a11y_action(
  world : @ecs.World,
  request : @moon_accesskit.ActionRequest,
) -> Unit {
  if !world.contains_message(@a11y.ecs_msg_key_action_request) {
    world.init_message(@a11y.ecs_msg_key_action_request)
  }
  ignore(
    world.send_message(
      @a11y.ecs_msg_key_action_request,
      @a11y.ActionRequest::new(request),
    ),
  )
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
  debug_inspect(ev0.length(), content="2")
  debug_inspect(
    ev0[0].kind == @pointer_events.PointerEventKind::Move,
    content="true",
  )
  debug_inspect(
    ev0[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  debug_inspect(ev0[1].target.unwrap().id == e1.id, content="true")

  // Frame 2: move (same hit).
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e1)], [None]),
  )
  let ev1 = drain_events(world)
  debug_inspect(ev1.length(), content="1")
  debug_inspect(
    ev1[0].kind == @pointer_events.PointerEventKind::Move,
    content="true",
  )

  // Frame 3: switch hover to e2.
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, false),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev2 = drain_events(world)
  debug_inspect(ev2.length(), content="2")
  debug_inspect(
    ev2[0].kind == @pointer_events.PointerEventKind::Leave,
    content="true",
  )
  debug_inspect(ev2[0].target.unwrap().id == e1.id, content="true")
  debug_inspect(
    ev2[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  debug_inspect(ev2[1].target.unwrap().id == e2.id, content="true")

  // Frame 4: press e2.
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), true, true, false),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev3 = drain_events(world)
  debug_inspect(ev3.length(), content="1")
  debug_inspect(
    ev3[0].kind == @pointer_events.PointerEventKind::Down,
    content="true",
  )
  debug_inspect(ev3[0].target.unwrap().id == e2.id, content="true")

  // Frame 5: release on e2 (click).
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos1), false, false, true),
    ]),
    PickingHits::from_arrays([Some(e2)], [None]),
  )
  let ev4 = drain_events(world)
  debug_inspect(ev4.length(), content="2")
  debug_inspect(
    ev4[0].kind == @pointer_events.PointerEventKind::Up,
    content="true",
  )
  debug_inspect(
    ev4[1].kind == @pointer_events.PointerEventKind::Click,
    content="true",
  )
}

///|
test "picking: primary target priority is ui > sprite2d > mesh3d > window" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_picking_hits_resource(world).insert(PickingHits::default())
  let ui_entity = @core.Entity::new(11, 0)
  let sprite_entity = @core.Entity::new(12, 0)
  let mesh_entity = @core.Entity::new(13, 0)
  let window_entity = @core.Entity::new(14, 0)
  let pos = @math.Vec2::new(10.0F, 10.0F)

  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays(
      [Some(ui_entity)],
      [Some(sprite_entity)],
      mesh3d=[Some(mesh_entity)],
      window=[Some(window_entity)],
    ),
  )
  let ui_events = drain_events(world)
  debug_inspect(ui_events.length(), content="2")
  debug_inspect(ui_events[1].target.unwrap().id == ui_entity.id, content="true")

  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays(
      [None],
      [Some(sprite_entity)],
      mesh3d=[Some(mesh_entity)],
      window=[Some(window_entity)],
    ),
  )
  let sprite_events = drain_events(world)
  debug_inspect(sprite_events.length(), content="2")
  debug_inspect(
    sprite_events[0].kind == @pointer_events.PointerEventKind::Leave,
    content="true",
  )
  debug_inspect(
    sprite_events[0].target.unwrap().id == ui_entity.id,
    content="true",
  )
  debug_inspect(
    sprite_events[1].target.unwrap().id == sprite_entity.id,
    content="true",
  )

  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays([None], [None], mesh3d=[Some(mesh_entity)], window=[
      Some(window_entity),
    ]),
  )
  let mesh_events = drain_events(world)
  debug_inspect(mesh_events.length(), content="2")
  debug_inspect(
    mesh_events[0].kind == @pointer_events.PointerEventKind::Leave,
    content="true",
  )
  debug_inspect(
    mesh_events[0].target.unwrap().id == sprite_entity.id,
    content="true",
  )
  debug_inspect(
    mesh_events[1].target.unwrap().id == mesh_entity.id,
    content="true",
  )

  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays([None], [None], mesh3d=[None], window=[
      Some(window_entity),
    ]),
  )
  let window_events = drain_events(world)
  debug_inspect(window_events.length(), content="2")
  debug_inspect(
    window_events[0].kind == @pointer_events.PointerEventKind::Leave,
    content="true",
  )
  debug_inspect(
    window_events[0].target.unwrap().id == mesh_entity.id,
    content="true",
  )
  debug_inspect(
    window_events[1].target.unwrap().id == window_entity.id,
    content="true",
  )
}

///|
test "picking: non-hoverable non-blocking Pickable allows lower hit" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_picking_hits_resource(world).insert(PickingHits::default())
  let top = world.spawn_empty()
  try! world.set_by_key(top, ecs_key_pickable, pickable_ignore)
  let lower = world.spawn_empty()
  let pos = @math.Vec2::new(20.0F, 20.0F)
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays([Some(top)], [Some(lower)]),
  )
  let events = drain_events(world)
  debug_inspect(events.length(), content="2")
  debug_inspect(
    events[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  debug_inspect(events[1].target.unwrap().id == lower.id, content="true")
}

///|
test "picking: non-hoverable blocking Pickable suppresses lower hits" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  get_picking_state_resource(world).insert(PickingState::default())
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_picking_hits_resource(world).insert(PickingHits::default())
  let top = world.spawn_empty()
  try! world.set_by_key(top, ecs_key_pickable, Pickable::new(true, false))
  let lower = world.spawn_empty()
  let pos = @math.Vec2::new(20.0F, 20.0F)
  set_frame(
    world,
    PointerInputs::from_array([
      PointerInput::new(0, Some(pos), false, false, false),
    ]),
    PickingHits::from_arrays([Some(top)], [Some(lower)]),
  )
  let events = drain_events(world)
  debug_inspect(events.length(), content="1")
  debug_inspect(
    events[0].kind == @pointer_events.PointerEventKind::Move,
    content="true",
  )
  debug_inspect(events[0].target is None, content="true")
}

///|
test "picking: window backend populates fallback hit for active pointers" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  get_pointer_inputs_resource(world).insert(
    PointerInputs::from_array([
      PointerInput::new(
        0,
        Some(@math.Vec2::new(1.0F, 2.0F)),
        false,
        false,
        false,
      ),
      PointerInput::new(1, None, false, false, false),
    ]),
  )
  get_picking_hits_resource(world).insert(PickingHits::default())
  let window_entity = world.spawn_empty()
  try! world.set_by_key(
    window_entity,
    @window.ecs_key_window,
    @window.Window::default(),
  )
  try! world.set_by_key(window_entity, @window.ecs_key_primary_window, @window.PrimaryWindow::{

  })
  picking_window_hit_test_system(world)
  let hits = get_picking_hits_resource(world)
    .get()
    .unwrap_or(PickingHits::default())
  debug_inspect(
    hits.window(0) is Some(hit) && hit.id == window_entity.id,
    content="true",
  )
  debug_inspect(hits.window(1) is None, content="true")
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
  debug_inspect(events.length(), content="4")
  debug_inspect(events[0].pointer == 0, content="true")
  debug_inspect(events[1].pointer == 0, content="true")
  debug_inspect(events[2].pointer == 1, content="true")
  debug_inspect(events[3].pointer == 1, content="true")
  debug_inspect(
    events[1].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
  debug_inspect(
    events[3].kind == @pointer_events.PointerEventKind::Enter,
    content="true",
  )
}

///|
test "picking: ui hit test respects transformed ui node" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  get_pointer_inputs_resource(world).insert(
    PointerInputs::from_array([
      PointerInput::new(
        0,
        Some(@math.Vec2::new(140.0F, 170.0F)),
        false,
        false,
        false,
      ),
    ]),
  )
  get_picking_hits_resource(world).insert(PickingHits::default())
  @ui.get_ui_context_resource(world).insert(
    @ui.UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(800.0F, 600.0F),
      Some(@core.Entity::new(0, 0)),
      @transform.Transform::identity(),
      1.0F,
      Some(@math.Vec2::new(140.0F, 170.0F)),
      false,
    ),
  )
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    entity,
    @ui.ecs_key_ui_layout,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(40.0F, 50.0F),
        @math.Vec2::new(240.0F, 110.0F),
      ),
    ),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-260.0F, 220.0F),
      1.5707964F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  @ui.get_ui_stack_resource(world).insert(@ui.UiStack::default())
  @ui.ui_stack_system(world)
  picking_ui_hit_test_system(world)
  let hits = get_picking_hits_resource(world)
    .get()
    .unwrap_or(PickingHits::default())
  debug_inspect(
    hits.ui(0) is Some(hit) &&
    hit.id == entity.id &&
    hit.generation == entity.generation,
    content="true",
  )
}

///|
test "picking: ui hit test keeps top and bottom rows distinct" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  get_pointer_inputs_resource(world).insert(PointerInputs::default())
  get_picking_hits_resource(world).insert(PickingHits::default())
  @ui.get_ui_context_resource(world).insert(
    @ui.UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(800.0F, 600.0F),
      Some(@core.Entity::new(0, 0)),
      @transform.Transform::identity(),
      1.0F,
      None,
      false,
    ),
  )
  let top = world.spawn_empty()
  try! world.set_by_key(top, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    top,
    @ui.ecs_key_ui_layout,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(120.0F, 80.0F),
        @math.Vec2::new(320.0F, 180.0F),
      ),
    ),
  )
  let bottom = world.spawn_empty()
  try! world.set_by_key(bottom, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    bottom,
    @ui.ecs_key_ui_layout,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(120.0F, 260.0F),
        @math.Vec2::new(320.0F, 360.0F),
      ),
    ),
  )
  @ui.get_ui_stack_resource(world).insert(@ui.UiStack::default())
  @ui.ui_stack_system(world)
  let top_center = @math.Vec2::new(220.0F, 130.0F)
  let bottom_center = @math.Vec2::new(220.0F, 310.0F)

  get_pointer_inputs_resource(world).insert(
    PointerInputs::from_array([
      PointerInput::new(0, Some(top_center), false, false, false),
    ]),
  )
  picking_ui_hit_test_system(world)
  let hits_top = get_picking_hits_resource(world)
    .get()
    .unwrap_or(PickingHits::default())
  debug_inspect(hits_top.ui(0) is Some(hit) && hit.id == top.id, content="true")

  get_pointer_inputs_resource(world).insert(
    PointerInputs::from_array([
      PointerInput::new(0, Some(bottom_center), false, false, false),
    ]),
  )
  picking_ui_hit_test_system(world)
  let hits_bottom = get_picking_hits_resource(world)
    .get()
    .unwrap_or(PickingHits::default())
  debug_inspect(
    hits_bottom.ui(0) is Some(hit) && hit.id == bottom.id,
    content="true",
  )
}

///|
test "picking: ui hit test still matches button with Interaction component" {
  let world = @ecs.World::new()
  ignore(world.advance_sequence())
  get_pointer_inputs_resource(world).insert(
    PointerInputs::from_array([
      PointerInput::new(
        0,
        Some(@math.Vec2::new(120.0F, 80.0F)),
        false,
        false,
        false,
      ),
    ]),
  )
  get_picking_hits_resource(world).insert(PickingHits::default())
  @ui.get_ui_context_resource(world).insert(
    @ui.UiContext::new(
      @asset.Handle::new(1),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(800.0F, 600.0F),
      Some(@core.Entity::new(0, 0)),
      @transform.Transform::identity(),
      1.0F,
      Some(@math.Vec2::new(120.0F, 80.0F)),
      false,
    ),
  )
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    entity,
    @ui.ecs_key_interaction,
    @ui.Interaction::Hovered,
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_ui_layout,
    @ui.UiLayout::new(
      @math.Rect::new(
        @math.Vec2::new(40.0F, 50.0F),
        @math.Vec2::new(240.0F, 110.0F),
      ),
    ),
  )
  @ui.get_ui_stack_resource(world).insert(@ui.UiStack::default())
  @ui.ui_stack_system(world)
  picking_ui_hit_test_system(world)
  let hits = get_picking_hits_resource(world)
    .get()
    .unwrap_or(PickingHits::default())
  debug_inspect(
    hits.ui(0) is Some(hit) &&
    hit.id == entity.id &&
    hit.generation == entity.generation,
    content="true",
  )
}

///|
test "picking: a11y focus action maps to hovered interaction" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  world.insert_resource(
    @input_focus.InputFocus::resource(),
    @input_focus.InputFocus::default(),
  )
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  let entity = world.spawn_empty()
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    @a11y.node_id_for_entity(entity),
  )
  enqueue_a11y_action(world, req)
  picking_apply_a11y_actions_system(world)
  let interaction = try! world.get_by_key(entity, @ui.ecs_key_interaction)
  debug_inspect(interaction is Some(@ui.Interaction::Hovered), content="true")
  let focus = try! world.get_resource(@input_focus.InputFocus::resource())
  debug_inspect(focus.unwrap().get() == Some(entity), content="true")
}

///|
test "picking: a11y scroll actions update ScrollPosition without click events" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
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
  let node_id = @a11y.node_id_for_entity(entity)
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
  enqueue_a11y_action(world, req_down)
  enqueue_a11y_action(world, req_right)
  picking_apply_a11y_actions_system(world)
  let scroll = try! world.get_by_key(entity, @ui.ecs_key_scroll_position)
  debug_inspect(
    scroll is Some(v) && v.offset_x == 0.0F && v.offset_y == 24.0F,
    content="true",
  )
  let events = drain_events(world)
  debug_inspect(events.length(), content="0")
}

///|
test "picking: a11y set-value action updates Text content" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new("Old"))
  let node_id = @a11y.node_id_for_entity(entity)
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::SetValue,
    @moon_accesskit.TreeId::root(),
    node_id,
  )
  req.set_data(@moon_accesskit.ActionData::Value("Updated"))
  enqueue_a11y_action(world, req)
  picking_apply_a11y_actions_system(world)
  debug_inspect(
    world.get_by_key(entity, @text.ecs_key_text).unwrap().content,
    content="\"Updated\"",
  )
  let events = drain_events(world)
  debug_inspect(events.length(), content="0")
}

///|
test "picking: ignores a11y actions targeting non-alive entities" {
  let world = @ecs.World::new()
  let tick = world.advance_sequence()
  ignore(tick)
  world.insert_resource(
    @input_focus.InputFocus::resource(),
    @input_focus.InputFocus::default(),
  )
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
  let dead_entity = @core.Entity::new(999, 1)
  let req = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    @a11y.node_id_for_entity(dead_entity),
  )
  enqueue_a11y_action(world, req)
  picking_apply_a11y_actions_system(world)
  let focus = try! world.get_resource(@input_focus.InputFocus::resource())
  debug_inspect(focus.unwrap().get() is None, content="true")
  debug_inspect(world.is_alive(dead_entity), content="false")
  let events = drain_events(world)
  debug_inspect(events.length(), content="0")
}

///|
test "picking: pointer observers dispatch generated move enter and leave events" {
  let seen : Array[String] = []
  let mut app = @app.App::new(@ecs.World::new()).add_pointer_observer(fn(
    pointer : @app.OnPointer[@app.PointerMove],
  ) {
    if pointer.target() is Some(target) {
      seen.push("move:\{target.id.to_string()}")
    }
  })
  app = app.add_pointer_observer(fn(
    pointer : @app.OnPointer[@app.PointerEnter],
  ) {
    if pointer.target() is Some(target) {
      seen.push("enter:\{target.id.to_string()}")
    }
  })
  app = app.add_pointer_observer(fn(
    pointer : @app.OnPointer[@app.PointerLeave],
  ) {
    if pointer.target() is Some(target) {
      seen.push("leave:\{target.id.to_string()}")
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

  debug_inspect(
    seen,
    content="[\"move:1\", \"enter:1\", \"leave:1\", \"enter:2\"]",
  )
}
