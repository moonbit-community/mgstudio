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
pub struct PointerInput {
  pointer : PointerId
  window_position : @math.Vec2?
  down : Bool
  just_pressed : Bool
  just_released : Bool
}

///|
pub fn PointerInput::new(
  pointer : PointerId,
  window_position : @math.Vec2?,
  down : Bool,
  just_pressed : Bool,
  just_released : Bool,
) -> PointerInput {
  PointerInput::{ pointer, window_position, down, just_pressed, just_released }
}

///|
/// Per-frame pointer inputs captured from the runtime/input layer.
#ecs.resource
pub struct PointerInputs {
  mut pointers : Array[PointerInput]
}

///|
pub fn PointerInputs::default() -> PointerInputs {
  PointerInputs::{ pointers: [] }
}

///|
pub fn PointerInputs::from_array(
  pointers : Array[PointerInput],
) -> PointerInputs {
  PointerInputs::{ pointers, }
}

///|
pub fn PointerInputs::clear(self : Ref[PointerInputs]) -> Unit {
  self.val.pointers.clear()
}

///|
pub fn PointerInputs::push(
  self : Ref[PointerInputs],
  input : PointerInput,
) -> Unit {
  self.val.pointers = self.val.pointers + [input]
}

///|
/// Per-frame hit-test results produced by picking backends.
#ecs.resource
pub struct PickingHits {
  mut ui : Array[@core.Entity?]
  mut sprite2d : Array[@core.Entity?]
}

///|
pub fn PickingHits::default() -> PickingHits {
  PickingHits::{ ui: [], sprite2d: [] }
}

///|
pub fn PickingHits::from_arrays(
  ui : Array[@core.Entity?],
  sprite2d : Array[@core.Entity?],
) -> PickingHits {
  PickingHits::{ ui, sprite2d }
}

///|
fn PickingHits::ensure_capacity(
  self : Ref[PickingHits],
  pointer : PointerId,
) -> Unit {
  if pointer < 0 {
    return
  }
  let need = pointer + 1
  while self.val.ui.length() < need {
    self.val.ui.push(None)
  }
  while self.val.sprite2d.length() < need {
    self.val.sprite2d.push(None)
  }
}

///|
pub fn PickingHits::set_ui(
  self : Ref[PickingHits],
  pointer : PointerId,
  entity : @core.Entity?,
) -> Unit {
  PickingHits::ensure_capacity(self, pointer)
  self.val.ui[pointer] = entity
}

///|
pub fn PickingHits::ui(
  self : PickingHits,
  pointer : PointerId,
) -> @core.Entity? {
  if pointer < 0 || pointer >= self.ui.length() {
    None
  } else {
    self.ui[pointer]
  }
}

///|
pub fn PickingHits::set_sprite2d(
  self : Ref[PickingHits],
  pointer : PointerId,
  entity : @core.Entity?,
) -> Unit {
  PickingHits::ensure_capacity(self, pointer)
  self.val.sprite2d[pointer] = entity
}

///|
pub fn PickingHits::sprite2d(
  self : PickingHits,
  pointer : PointerId,
) -> @core.Entity? {
  if pointer < 0 || pointer >= self.sprite2d.length() {
    None
  } else {
    self.sprite2d[pointer]
  }
}

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
pub fn PickingEvents::push(
  self : Ref[PickingEvents],
  event : PointerEvent,
) -> Unit {
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
  mut hovered : Array[@core.Entity?]
  mut pressed : Array[@core.Entity?]
  mut last_position : Array[@math.Vec2?]
}

///|
pub fn PickingState::default() -> PickingState {
  PickingState::{ hovered: [], pressed: [], last_position: [] }
}

///|
pub fn PickingState::hovered(
  self : PickingState,
  pointer : PointerId,
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
  pointer : PointerId,
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
  pointer : PointerId,
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
  pointer : PointerId,
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
  pointer : PointerId,
  pressed : @core.Entity?,
) -> Unit {
  PickingState::ensure_capacity(self, pointer)
  self.val.pressed[pointer] = pressed
}

///|
pub fn PickingState::set_last_position(
  self : Ref[PickingState],
  pointer : PointerId,
  pos : @math.Vec2?,
) -> Unit {
  PickingState::ensure_capacity(self, pointer)
  self.val.last_position[pointer] = pos
}

///|
pub fn PickingState::set_hovered(
  self : Ref[PickingState],
  pointer : PointerId,
  hovered : @core.Entity?,
) -> Unit {
  PickingState::ensure_capacity(self, pointer)
  self.val.hovered[pointer] = hovered
}

///|
pub let picking_set : @app.SystemSet = @app.system_set("mgstudio.picking")

///|
pub let picking_set_input : @app.SystemSet = @app.system_set(
  "mgstudio.picking.input",
)

///|
pub let picking_set_hits : @app.SystemSet = @app.system_set(
  "mgstudio.picking.hits",
)

///|
pub let picking_set_events : @app.SystemSet = @app.system_set(
  "mgstudio.picking.events",
)

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
pub fn[W : HasRes_PickingHits + @core.ChangeTickWorld] ensure_picking_hits_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_PickingHits::get_picking_hits_resource(world)
  if res.get() is None {
    res.insert(PickingHits::default(), tick)
  }
}

///|
pub fn[W : HasRes_PointerInputs + @core.ChangeTickWorld] ensure_pointer_inputs_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_PointerInputs::get_pointer_inputs_resource(world)
  if res.get() is None {
    res.insert(PointerInputs::default(), tick)
  }
}

///|
pub fn[W : HasRes_PointerInputs + @core.ChangeTickWorld] picking_collect_mouse_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let res = HasRes_PointerInputs::get_pointer_inputs_resource(world)
  guard res.get_ref_mut(tick) is Some(inputs) else { return }
  PointerInputs::clear(inputs)
  let pointer : PointerId = 0
  let window_position = @input.mouse_position()
  let down = @input.mouse_button_pressed(@window.MouseButton::Left)
  let just_pressed = @input.mouse_button_just_pressed(@window.MouseButton::Left)
  let just_released = @input.mouse_button_just_released(
    @window.MouseButton::Left,
  )
  PointerInputs::push(
    inputs,
    PointerInput::new(
      pointer, window_position, down, just_pressed, just_released,
    ),
  )
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
fn picking_rect_intersect(a : @math.Rect, b : @math.Rect) -> @math.Rect {
  let min_x = if a.min.x > b.min.x { a.min.x } else { b.min.x }
  let min_y = if a.min.y > b.min.y { a.min.y } else { b.min.y }
  let max_x = if a.max.x < b.max.x { a.max.x } else { b.max.x }
  let max_y = if a.max.y < b.max.y { a.max.y } else { b.max.y }
  let min = @math.Vec2::new(min_x, min_y)
  let max = @math.Vec2::new(
    if max_x < min_x {
      min_x
    } else {
      max_x
    },
    if max_y < min_y {
      min_y
    } else {
      max_y
    },
  )
  @math.Rect::new(min, max)
}

///|
fn picking_rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
fn sprite_region_size(sprite : @render2d.Sprite) -> @math.Vec2 {
  let texture_id = sprite.image.id()
  let mut image_width = @asset.host_asset_texture_width(texture_id)
  let mut image_height = @asset.host_asset_texture_height(texture_id)
  if image_width <= 0 || image_height <= 0 {
    // Avoid division by zero for not-yet-loaded textures.
    image_width = 1
    image_height = 1
  }
  let image_rect = @math.Rect::new(
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(
      Float::from_double(image_width.to_double()),
      Float::from_double(image_height.to_double()),
    ),
  )
  let atlas_rect = match sprite.texture_atlas {
    Some(atlas) =>
      match @asset.asset_get_texture_atlas_layout(atlas.layout) {
        Some(layout_value) =>
          if atlas.index >= 0 && atlas.index < layout_value.textures.length() {
            Some(layout_value.textures[atlas.index].as_rect())
          } else {
            None
          }
        None => None
      }
    None => None
  }
  let texture_rect = match (atlas_rect, sprite.rect) {
    (None, None) => image_rect
    (None, Some(r)) => r
    (Some(ar), None) => ar
    (Some(ar), Some(r)) => {
      let min = @math.Vec2::new(r.min.x + ar.min.x, r.min.y + ar.min.y)
      let max = @math.Vec2::new(r.max.x + ar.min.x, r.max.y + ar.min.y)
      @math.Rect::new(min, max)
    }
  }
  texture_rect.size()
}

///|
/// 2D sprite hit testing backend (orthographic camera, clip-agnostic).
pub fn[
  W : HasRes_PointerInputs + HasRes_PickingHits + @ui.HasRes_UiContext + @render2d.Has_Sprite + @render2d.Has_Anchor + @math.Has_Transform + @transform.Has_GlobalTransform + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] picking_sprite2d_hit_test_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let inputs_res = HasRes_PointerInputs::get_pointer_inputs_resource(world)
  let hits_res = HasRes_PickingHits::get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get_ref_mut(tick) is Some(hits) else { return }
  let ctx_res = @ui.HasRes_UiContext::get_ui_context_resource(world)
  guard ctx_res.get() is Some(ctx0) else { return }
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let anchor_store = @render2d.Has_Anchor::get_anchor_store(world)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let global_store = @transform.Has_GlobalTransform::get_global_transform_store(
    world,
  )
  let vv_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
  let cam_translation = @math.Vec2::new(
    ctx0.camera_transform.translation.x,
    ctx0.camera_transform.translation.y,
  )
  let cam_rotation = ctx0.camera_transform.rotation_z()
  let cam_scale = if ctx0.camera_scale <= 0.0F {
    1.0F
  } else {
    ctx0.camera_scale
  }
  for input in inputs0.pointers {
    let pointer_id = input.pointer
    let pointer_pos = match input.window_position {
      Some(mouse) =>
        @ui.ui_pointer_pos_in_viewport(
          mouse,
          ctx0.viewport_origin,
          ctx0.viewport_size,
        )
      None => None
    }
    let mut hit_top : @core.Entity? = None
    let mut hit_z = -1.0e30F
    if pointer_pos is Some(p) {
      let centered = @math.Vec2::new(
        p.x - ctx0.viewport_size.x / 2.0F,
        ctx0.viewport_size.y / 2.0F - p.y,
      )
      let view_pos = @math.Vec2::new(
        centered.x * cam_scale,
        centered.y * cam_scale,
      )
      let world_offset = picking_rotate_vec2(view_pos, -cam_rotation)
      let pointer_world = @math.Vec2::new(
        cam_translation.x + world_offset.x,
        cam_translation.y + world_offset.y,
      )
      sprite_store.for_each(fn(entity, sprite) {
        if vv_store.get(entity) is Some(vv) && !vv.is_visible() {
          return
        }
        let transform = match global_store.get(entity) {
          Some(gt) => gt.to_transform_approx()
          None =>
            match transform_store.get(entity) {
              Some(t) => t
              None => @math.Transform::identity()
            }
        }
        let region = sprite_region_size(sprite)
        let denom_x = if region.x == 0.0F { 1.0F } else { region.x }
        let denom_y = if region.y == 0.0F { 1.0F } else { region.y }
        let mut scale = @math.Vec2::new(transform.scale.x, transform.scale.y)
        match sprite.custom_size {
          Some(custom) =>
            scale = @math.Vec2::new(
              scale.x * (custom.x / denom_x),
              scale.y * (custom.y / denom_y),
            )
          None => ()
        }
        let half = @math.Vec2::new(
          scale.x * region.x / 2.0F,
          scale.y * region.y / 2.0F,
        )
        if half.x <= 0.0F || half.y <= 0.0F {
          return
        }
        let anchor = match anchor_store.get(entity) {
          Some(a) => a
          None => @render2d.Anchor::default()
        }
        let a = anchor.as_vec()
        let offset_local = @math.Vec2::new(-a.x * scale.x, -a.y * scale.y)
        let offset = picking_rotate_vec2(offset_local, transform.rotation_z())
        let center = @math.Vec2::new(
          transform.translation.x + offset.x,
          transform.translation.y + offset.y,
        )
        let rel = @math.Vec2::new(
          pointer_world.x - center.x,
          pointer_world.y - center.y,
        )
        let local_pos = picking_rotate_vec2(rel, -transform.rotation_z())
        let abs_x = if local_pos.x < 0.0F { -local_pos.x } else { local_pos.x }
        let abs_y = if local_pos.y < 0.0F { -local_pos.y } else { local_pos.y }
        if abs_x <= half.x && abs_y <= half.y {
          let z = transform.translation.z
          if z > hit_z {
            hit_z = z
            hit_top = Some(entity)
          }
        }
      })
    }
    PickingHits::set_sprite2d(hits, pointer_id, hit_top)
  }
}

///|
/// UI hit testing backend (front-to-back, clip aware).
pub fn[
  W : HasRes_PointerInputs + HasRes_PickingHits + @ui.HasRes_UiContext + @ui.HasRes_UiStack + @ui.Has_UiLayout + @ui.Has_Button + @ui.Has_Interaction + @ui.Has_FocusPolicy + @ui.Has_CalculatedClip + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] picking_ui_hit_test_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let inputs_res = HasRes_PointerInputs::get_pointer_inputs_resource(world)
  let hits_res = HasRes_PickingHits::get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get_ref_mut(tick) is Some(hits) else { return }
  let ctx_res = @ui.HasRes_UiContext::get_ui_context_resource(world)
  guard ctx_res.get() is Some(ctx0) else { return }
  let stack_res = @ui.HasRes_UiStack::get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  let layout_store = @ui.Has_UiLayout::get_ui_layout_store(world)
  let button_store = @ui.Has_Button::get_button_store(world)
  let interaction_store = @ui.Has_Interaction::get_interaction_store(world)
  let focus_store = @ui.Has_FocusPolicy::get_focus_policy_store(world)
  let clip_store = @ui.Has_CalculatedClip::get_calculated_clip_store(world)
  let vv_store = @visibility.Has_ViewVisibility::get_view_visibility_store(
    world,
  )
  for input in inputs0.pointers {
    let pointer_id = input.pointer
    let pointer_pos = match input.window_position {
      Some(mouse) =>
        @ui.ui_pointer_pos_in_viewport(
          mouse,
          ctx0.viewport_origin,
          ctx0.viewport_size,
        )
      None => None
    }
    let mut hit_top : @core.Entity? = None
    let mut captured = false
    if pointer_pos is Some(p) {
      for i in 0..<stack0.uinodes.length() {
        if captured {
          break
        }
        let idx = stack0.uinodes.length() - 1 - i
        let entity = stack0.uinodes[idx]
        if !button_store.contains(entity) && !interaction_store.contains(entity) {
          continue
        }
        if vv_store.get(entity) is Some(vv) && !vv.is_visible() {
          continue
        }
        guard layout_store.get(entity) is Some(layout) else { continue }
        let node_rect = layout.rect
        if !node_rect.contains(p) {
          continue
        }
        let clip_rect = match clip_store.get(entity) {
          Some(v) => v.clip
          None => node_rect
        }
        let visible_rect = picking_rect_intersect(node_rect, clip_rect)
        if !visible_rect.contains(p) {
          continue
        }
        if hit_top is None {
          hit_top = Some(entity)
        }
        let focus = match focus_store.get(entity) {
          Some(v) => v
          None => @ui.FocusPolicy::Block
        }
        if focus == @ui.FocusPolicy::Block {
          captured = true
        }
      }
    }
    PickingHits::set_ui(hits, pointer_id, hit_top)
  }
}

///|
fn picking_primary_hit(
  hits : PickingHits,
  pointer : PointerId,
) -> @core.Entity? {
  match PickingHits::ui(hits, pointer) {
    Some(e) => Some(e)
    None => PickingHits::sprite2d(hits, pointer)
  }
}

///|
fn entity_from_node_id(node_id : @moon_accesskit.NodeId) -> @core.Entity {
  let packed = node_id.to_u64().to_int()
  let id = packed / 65536
  let gen = packed - id * 65536
  @core.Entity::new(id, gen)
}

///|
/// Apply host-driven accessibility actions to UI state and picking events.
pub fn[
  W : @a11y.HasRes_A11yState + HasRes_PickingEvents + @ui.Has_Interaction + @core.ChangeTickWorld,
] picking_apply_a11y_actions_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  guard @a11y.HasRes_A11yState::get_a11y_state_resource(world).get_ref_mut(tick)
    is Some(state) else {
    return
  }
  let actions = @a11y.A11yState::drain_actions(state)
  if actions.length() == 0 {
    return
  }
  guard HasRes_PickingEvents::get_picking_events_resource(world).get_ref_mut(
      tick,
    )
    is Some(events) else {
    return
  }
  let interaction_store = @ui.Has_Interaction::get_interaction_store(world)
  for req in actions {
    let entity = entity_from_node_id(req.target_node())
    match req.action() {
      @moon_accesskit.Action::Focus =>
        // MVP: focus is handled by the host (tab/VO). Engine-side focus routing is TODO.
        entity |> ignore
      _ => {
        if interaction_store.contains(entity) {
          interaction_store.set(entity, @ui.Interaction::Pressed, tick)
          |> ignore
        } else {
          interaction_store.insert(entity, @ui.Interaction::Pressed, tick)
        }
        PickingEvents::push(
          events,
          PointerEvent::new(
            0,
            PointerEventKind::Click,
            @math.Vec2::new(0.0F, 0.0F),
            target=Some(entity),
          ),
        )
      }
    }
  }
}

///|
/// Generate pointer enter/leave/down/up/click events from hit-test results.
pub fn[
  W : HasRes_PointerInputs + HasRes_PickingHits + HasRes_PickingEvents + HasRes_PickingState + @core.ChangeTickWorld,
] picking_generate_events_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let inputs_res = HasRes_PointerInputs::get_pointer_inputs_resource(world)
  let hits_res = HasRes_PickingHits::get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get() is Some(hits0) else { return }
  guard HasRes_PickingEvents::get_picking_events_resource(world).get_ref_mut(
      tick,
    )
    is Some(events) else {
    return
  }
  guard HasRes_PickingState::get_picking_state_resource(world).get_ref_mut(tick)
    is Some(picking_state) else {
    return
  }
  for input in inputs0.pointers {
    let pointer_id = input.pointer
    let pos_opt = input.window_position
    let hit_top = picking_primary_hit(hits0, pointer_id)

    // Move.
    match pos_opt {
      Some(pos) => {
        match PickingState::last_position(picking_state.val, pointer_id) {
          Some(prev) =>
            if prev.x != pos.x || prev.y != pos.y {
              PickingEvents::push(
                events,
                PointerEvent::new(pointer_id, PointerEventKind::Move, pos),
              )
            }
          None =>
            PickingEvents::push(
              events,
              PointerEvent::new(pointer_id, PointerEventKind::Move, pos),
            )
        }
        PickingState::set_last_position(picking_state, pointer_id, Some(pos))
      }
      None => PickingState::set_last_position(picking_state, pointer_id, None)
    }

    // Hover enter/leave.
    let prev_hovered = PickingState::hovered(picking_state.val, pointer_id)
    if !picking_option_entity_eq(prev_hovered, hit_top) {
      let pos = match pos_opt {
        Some(v) => v
        None => @math.Vec2::new(0.0F, 0.0F)
      }
      match prev_hovered {
        Some(prev_e) =>
          PickingEvents::push(
            events,
            PointerEvent::new(
              pointer_id,
              PointerEventKind::Leave,
              pos,
              target=Some(prev_e),
            ),
          )
        None => ()
      }
      match hit_top {
        Some(next_e) =>
          PickingEvents::push(
            events,
            PointerEvent::new(
              pointer_id,
              PointerEventKind::Enter,
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
        PickingEvents::push(
          events,
          PointerEvent::new(
            pointer_id,
            PointerEventKind::Down,
            pos,
            target=Some(target),
          ),
        )
        PickingState::set_pressed(picking_state, pointer_id, Some(target))
      }
    }
    if input.just_released {
      let pos = match pos_opt {
        Some(v) => v
        None => @math.Vec2::new(0.0F, 0.0F)
      }
      match PickingState::pressed(picking_state.val, pointer_id) {
        Some(pressed_entity) => {
          PickingEvents::push(
            events,
            PointerEvent::new(
              pointer_id,
              PointerEventKind::Up,
              pos,
              target=Some(pressed_entity),
            ),
          )
          if hit_top is Some(hit_entity) &&
            picking_entity_eq(hit_entity, pressed_entity) {
            PickingEvents::push(
              events,
              PointerEvent::new(
                pointer_id,
                PointerEventKind::Click,
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
}

///|
pub fn[
  W : HasRes_PickingEvents + HasRes_PickingState + HasRes_PickingHits + HasRes_PointerInputs + @a11y.HasRes_A11yState + @ui.HasRes_UiContext + @ui.HasRes_UiStack + @ui.Has_UiLayout + @ui.Has_Button + @ui.Has_Interaction + @ui.Has_FocusPolicy + @ui.Has_CalculatedClip + @render2d.Has_Sprite + @render2d.Has_Anchor + @math.Has_Transform + @transform.Has_GlobalTransform + @visibility.Has_ViewVisibility + @core.ChangeTickWorld,
] picking_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_pre_update_system_config(
    @app.system(picking_clear_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(ensure_picking_state_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(ensure_picking_hits_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(ensure_pointer_inputs_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(picking_collect_mouse_system).in_set(picking_set_input),
  )
  .add_pre_update_system_config(
    @app.system(picking_ui_hit_test_system).in_set(picking_set_hits),
  )
  .add_pre_update_system_config(
    @app.system(picking_sprite2d_hit_test_system).in_set(picking_set_hits),
  )
  .add_pre_update_system_config(
    @app.system(picking_apply_a11y_actions_system).in_set(picking_set_events),
  )
  .add_pre_update_system_config(
    @app.system(picking_generate_events_system).in_set(picking_set_events),
  )
  .configure_set(@app.PreUpdate, picking_set_input, before=[picking_set_hits])
  .configure_set(
    @app.PreUpdate,
    picking_set_hits,
    after=[
      picking_set_input, @ui.ui_set_stack, @transform.transform_set_propagate,
    ],
    before=[picking_set_events],
  )
  .configure_set(@app.PreUpdate, picking_set_events, after=[
    picking_set_hits, @a11y.a11y_set, @ui.ui_set_interaction,
  ])
}
