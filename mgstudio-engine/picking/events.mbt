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
// Bevy source: `bevy/crates/bevy_picking/src/events.rs`.
/// Picking event emission logic.

///|
fn entity_from_node_id(node_id : @moon_accesskit.NodeId) -> @core.Entity {
  @core.Entity::from_bits(node_id.to_u64())
}

///|
priv struct PickingA11yActionReaderState {
  mut cursor : Int
}

///|
fn PickingA11yActionReaderState::default() -> PickingA11yActionReaderState {
  { cursor: 0 }
}

///|
let picking_a11y_action_reader_state_resource_key : @ecs.ResourceKey[
  PickingA11yActionReaderState,
] = @ecs.register_resource(
  debug_name="mgstudio_picking::PickingA11yActionReaderState",
)

///|
fn ensure_picking_a11y_action_reader_state(world : @ecs.World) -> Unit {
  let res = world.resource(picking_a11y_action_reader_state_resource_key)
  if !res.is_present() {
    res.insert(PickingA11yActionReaderState::default())
  }
}

///|
fn read_pending_a11y_actions(world : @ecs.World) -> Array[@a11y.ActionRequest] {
  ensure_picking_a11y_action_reader_state(world)
  let state_res = world.resource(picking_a11y_action_reader_state_resource_key)
  guard state_res.get() is Some(state_value) else { return [] }
  let state_ref = Ref::new(state_value)
  let cursor = Ref::new(state_ref.val.cursor)
  let reader = world.message_reader(@a11y.ecs_msg_key_action_request, cursor)
  let actions = try! reader.read()
  state_ref.val.cursor = cursor.val
  state_res.insert(state_ref.val)
  actions
}

///|
priv struct PickingPointerInputEventReaderState {
  mut cursor : Int
}

///|
fn PickingPointerInputEventReaderState::default() -> PickingPointerInputEventReaderState {
  { cursor: 0 }
}

///|
let picking_pointer_input_event_reader_state_resource_key : @ecs.ResourceKey[
  PickingPointerInputEventReaderState,
] = @ecs.register_resource(
  debug_name="mgstudio_picking::PickingPointerInputEventReaderState",
)

///|
fn ensure_picking_pointer_input_event_reader_state(world : @ecs.World) -> Unit {
  let res = world.resource(
    picking_pointer_input_event_reader_state_resource_key,
  )
  if !res.is_present() {
    res.insert(PickingPointerInputEventReaderState::default())
  }
}

///|
fn read_pending_pointer_event_inputs(world : @ecs.World) -> Array[PointerInput] {
  if !world.contains_message(pointer_input_message_key()) {
    return []
  }
  ensure_picking_pointer_input_event_reader_state(world)
  let state_res = world.resource(
    picking_pointer_input_event_reader_state_resource_key,
  )
  guard state_res.get() is Some(state_value) else { return [] }
  let state_ref = Ref::new(state_value)
  let cursor = Ref::new(state_ref.val.cursor)
  let reader = world.message_reader(pointer_input_message_key(), cursor)
  let inputs = try! reader.read()
  state_ref.val.cursor = cursor.val
  state_res.insert(state_ref.val)
  inputs
}

///|
fn picking_set_input_focus(world : @ecs.World, entity : @core.Entity) -> Unit {
  let focus_ref = try
    world.get_resource_ref_mut(@input_focus.InputFocus::resource())
  catch {
    _ => None
  } noraise {
    value => value
  }
  guard focus_ref is Some(input_focus_ref) else { return }
  input_focus_ref.val.set(entity)
}

///|
/// Apply host-driven accessibility actions to UI state and picking events.
pub fn picking_apply_a11y_actions_system(world : @ecs.World) -> Unit {
  let actions = read_pending_a11y_actions(world)
  if actions.length() == 0 {
    return
  }
  let events_res = @app.get_picking_events_resource(world)
  guard events_res.get() is Some(events_value) else { return }
  let events = Ref::new(events_value)
  let scroll_step = 24.0F
  fn apply_scroll_delta(entity : @core.Entity, dx : Float, dy : Float) -> Unit {
    guard (try! world.get_by_key(entity, @ui.ecs_key_node)) is Some(target_node) else {
      return
    }
    let prev = match
      (try! world.get_by_key(entity, @ui.ecs_key_scroll_position)) {
      Some(v) => v
      None => @ui.ScrollPosition::default()
    }
    let mut max_offset_x = 0.0F
    let mut max_offset_y = 0.0F
    if (try! world.get_by_key(entity, @ui.ecs_key_ui_layout))
      is Some(target_layout) &&
      (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      let target_size = target_layout.rect.size()
      if target_size.x > 0.0F && target_size.y > 0.0F {
        let mut content_min : @math.Vec2? = None
        let mut content_max : @math.Vec2? = None
        for i in 0..<children.entities.length() {
          let child = children.entities[i]
          if (try! world.get_by_key(child, @ui.ecs_key_ui_layout))
            is Some(child_layout) {
            let unscrolled_min = @math.Vec2::new(
              child_layout.rect.min.x + prev.offset_x,
              child_layout.rect.min.y + prev.offset_y,
            )
            let unscrolled_max = @math.Vec2::new(
              child_layout.rect.max.x + prev.offset_x,
              child_layout.rect.max.y + prev.offset_y,
            )
            content_min = match content_min {
              Some(current) =>
                Some(
                  @math.Vec2::new(
                    if unscrolled_min.x < current.x {
                      unscrolled_min.x
                    } else {
                      current.x
                    },
                    if unscrolled_min.y < current.y {
                      unscrolled_min.y
                    } else {
                      current.y
                    },
                  ),
                )
              None => Some(unscrolled_min)
            }
            content_max = match content_max {
              Some(current) =>
                Some(
                  @math.Vec2::new(
                    if unscrolled_max.x > current.x {
                      unscrolled_max.x
                    } else {
                      current.x
                    },
                    if unscrolled_max.y > current.y {
                      unscrolled_max.y
                    } else {
                      current.y
                    },
                  ),
                )
              None => Some(unscrolled_max)
            }
          }
        }
        match (content_min, content_max) {
          (Some(min_v), Some(max_v)) => {
            let content_w = max_v.x - min_v.x
            let content_h = max_v.y - min_v.y
            let overflow_x = content_w - target_size.x
            let overflow_y = content_h - target_size.y
            if overflow_x > 0.0F {
              max_offset_x = overflow_x
            }
            if overflow_y > 0.0F {
              max_offset_y = overflow_y
            }
          }
          _ => ()
        }
      }
    }
    let mut next_x = if target_node.overflow.x == @ui.OverflowAxis::Scroll {
      prev.offset_x + dx
    } else {
      0.0F
    }
    let mut next_y = if target_node.overflow.y == @ui.OverflowAxis::Scroll {
      prev.offset_y + dy
    } else {
      0.0F
    }
    if next_x < 0.0F {
      next_x = 0.0F
    }
    if next_y < 0.0F {
      next_y = 0.0F
    }
    if next_x > max_offset_x {
      next_x = max_offset_x
    }
    if next_y > max_offset_y {
      next_y = max_offset_y
    }
    let next = @ui.ScrollPosition::new(next_x, next_y)
    if (try! world.contains_by_key(entity, @ui.ecs_key_scroll_position)) {
      try! (world.replace(entity, @ui.ecs_key_scroll_position, next) |> ignore)
    } else {
      try! world.set_by_key(entity, @ui.ecs_key_scroll_position, next)
    }
  }

  for action_request in actions {
    let req = action_request.accesskit_request()
    let entity = entity_from_node_id(req.target_node())
    if !world.is_alive(entity) {
      continue
    }
    match req.action() {
      @moon_accesskit.Action::Focus => {
        picking_set_input_focus(world, entity)
        // Map focus-driven navigation (tab / VO) to the hovered state so UI can
        // reflect focus without requiring pointer position.
        if (try! world.contains_by_key(entity, @ui.ecs_key_interaction)) {
          try! (world.replace(
            entity,
            @ui.ecs_key_interaction,
            @ui.Interaction::Hovered,
          )
          |> ignore)
        } else {
          try! world.set_by_key(
            entity,
            @ui.ecs_key_interaction,
            @ui.Interaction::Hovered,
          )
        }
      }
      @moon_accesskit.Action::Click => {
        picking_set_input_focus(world, entity)
        if (try! world.contains_by_key(entity, @ui.ecs_key_interaction)) {
          try! (world.replace(
            entity,
            @ui.ecs_key_interaction,
            @ui.Interaction::Pressed,
          )
          |> ignore)
        } else {
          try! world.set_by_key(
            entity,
            @ui.ecs_key_interaction,
            @ui.Interaction::Pressed,
          )
        }
        @app.PickingEvents::push(
          events,
          @pointer_events.PointerEvent::new(
            0,
            @pointer_events.PointerEventKind::Click,
            @math.Vec2::new(0.0F, 0.0F),
            target=Some(entity),
          ),
        )
      }
      @moon_accesskit.Action::ScrollUp =>
        apply_scroll_delta(entity, 0.0F, -scroll_step)
      @moon_accesskit.Action::ScrollDown =>
        apply_scroll_delta(entity, 0.0F, scroll_step)
      @moon_accesskit.Action::ScrollLeft =>
        apply_scroll_delta(entity, -scroll_step, 0.0F)
      @moon_accesskit.Action::ScrollRight =>
        apply_scroll_delta(entity, scroll_step, 0.0F)
      @moon_accesskit.Action::SetValue =>
        if req.data() is Some(@moon_accesskit.ActionData::Value(value)) {
          guard (try! world.get_by_key(entity, @text.ecs_key_text))
            is Some(text_node) else {
            continue
          }
          picking_set_input_focus(world, entity)
          text_node.content = value
          ignore(try! world.replace(entity, @text.ecs_key_text, text_node))
        }
      _ => ()
    }
  }
  events_res.insert(events.val)
}

///|
/// Generate pointer enter/leave/down/up/click events from hit-test results.
pub fn picking_generate_events_system(world : @ecs.World) -> Unit {
  let inputs = read_pending_pointer_event_inputs(world)
  if inputs.length() == 0 {
    return
  }
  let hover_map = get_hover_map_resource(world).get()
  let events_res = @app.get_picking_events_resource(world)
  guard events_res.get() is Some(events_value) else { return }
  let events = Ref::new(events_value)
  let state_res = get_picking_state_resource(world)
  guard state_res.get() is Some(state_value) else { return }
  let picking_state = Ref::new(state_value)
  for input in inputs {
    let pointer_id = input.pointer
    let pos_opt = input.window_position
    let hit_top = match hover_map {
      Some(map) => map.nearest_entity(pointer_id)
      None => None
    }

    // Move.
    match pos_opt {
      Some(pos) => {
        match PickingState::last_position(picking_state.val, pointer_id) {
          Some(prev) =>
            if prev.x != pos.x || prev.y != pos.y {
              @app.PickingEvents::push(
                events,
                @pointer_events.PointerEvent::new(
                  pointer_id,
                  @pointer_events.PointerEventKind::Move,
                  pos,
                  target=hit_top,
                ),
              )
            }
          None =>
            @app.PickingEvents::push(
              events,
              @pointer_events.PointerEvent::new(
                pointer_id,
                @pointer_events.PointerEventKind::Move,
                pos,
                target=hit_top,
              ),
            )
        }
        PickingState::set_last_position(picking_state, pointer_id, Some(pos))
      }
      None => PickingState::set_last_position(picking_state, pointer_id, None)
    }

    // Hover enter/leave.
    let prev_hovered = PickingState::hovered(picking_state.val, pointer_id)
    if !picking_option_entity_eq(prev_hovered, hit_top) {
      let pos = picking_window_position_or_origin(pos_opt)
      match prev_hovered {
        Some(prev_e) =>
          @app.PickingEvents::push(
            events,
            @pointer_events.PointerEvent::new(
              pointer_id,
              @pointer_events.PointerEventKind::Leave,
              pos,
              target=Some(prev_e),
            ),
          )
        None => ()
      }
      match hit_top {
        Some(next_e) =>
          @app.PickingEvents::push(
            events,
            @pointer_events.PointerEvent::new(
              pointer_id,
              @pointer_events.PointerEventKind::Enter,
              pos,
              target=Some(next_e),
            ),
          )
        None => ()
      }
      PickingState::set_hovered(picking_state, pointer_id, hit_top)
    }

    // Down / up / click.
    if input.just_pressed {
      if pos_opt is Some(pos) && hit_top is Some(target) {
        @app.PickingEvents::push(
          events,
          @pointer_events.PointerEvent::new(
            pointer_id,
            @pointer_events.PointerEventKind::Down,
            pos,
            target=Some(target),
          ),
        )
        PickingState::set_pressed(picking_state, pointer_id, Some(target))
      }
    }
    if input.just_released {
      let pos = picking_window_position_or_origin(pos_opt)
      match PickingState::pressed(picking_state.val, pointer_id) {
        Some(pressed_entity) => {
          @app.PickingEvents::push(
            events,
            @pointer_events.PointerEvent::new(
              pointer_id,
              @pointer_events.PointerEventKind::Up,
              pos,
              target=Some(pressed_entity),
            ),
          )
          if hit_top is Some(hit_entity) &&
            picking_entity_eq(hit_entity, pressed_entity) {
            @app.PickingEvents::push(
              events,
              @pointer_events.PointerEvent::new(
                pointer_id,
                @pointer_events.PointerEventKind::Click,
                pos,
                target=Some(pressed_entity),
              ),
            )
          }
        }
        None => ()
      }
      PickingState::set_pressed(picking_state, pointer_id, None)
    }
  }
  events_res.insert(events.val)
  state_res.insert(picking_state.val)
}
