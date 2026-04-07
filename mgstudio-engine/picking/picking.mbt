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
/// Picking framework (UI + 2D sprite + 3D mesh).

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
/// Per-frame pointer inputs captured from the runtime/input layer.
pub struct PointerInputs {
  mut pointers : Array[PointerInput]
} derive(ToJson, FromJson)

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
pub struct PickingHits {
  ui : Array[@core.Entity?]
  sprite2d : Array[@core.Entity?]
  mesh3d : Array[@core.Entity?]
} derive(ToJson, FromJson)

///|
pub fn PickingHits::default() -> PickingHits {
  PickingHits::{ ui: [], sprite2d: [], mesh3d: [] }
}

///|
pub fn PickingHits::from_arrays(
  ui : Array[@core.Entity?],
  sprite2d : Array[@core.Entity?],
  mesh3d? : Array[@core.Entity?] = [],
) -> PickingHits {
  PickingHits::{ ui, sprite2d, mesh3d }
}

///|
fn PickingHits::ensure_capacity(
  self : Ref[PickingHits],
  pointer : @pointer_events.PointerId,
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
  while self.val.mesh3d.length() < need {
    self.val.mesh3d.push(None)
  }
}

///|
pub fn PickingHits::set_ui(
  self : Ref[PickingHits],
  pointer : @pointer_events.PointerId,
  entity : @core.Entity?,
) -> Unit {
  PickingHits::ensure_capacity(self, pointer)
  self.val.ui[pointer] = entity
}

///|
pub fn PickingHits::ui(
  self : PickingHits,
  pointer : @pointer_events.PointerId,
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
  pointer : @pointer_events.PointerId,
  entity : @core.Entity?,
) -> Unit {
  PickingHits::ensure_capacity(self, pointer)
  self.val.sprite2d[pointer] = entity
}

///|
pub fn PickingHits::sprite2d(
  self : PickingHits,
  pointer : @pointer_events.PointerId,
) -> @core.Entity? {
  if pointer < 0 || pointer >= self.sprite2d.length() {
    None
  } else {
    self.sprite2d[pointer]
  }
}

///|
pub fn PickingHits::set_mesh3d(
  self : Ref[PickingHits],
  pointer : @pointer_events.PointerId,
  entity : @core.Entity?,
) -> Unit {
  PickingHits::ensure_capacity(self, pointer)
  self.val.mesh3d[pointer] = entity
}

///|
pub fn PickingHits::mesh3d(
  self : PickingHits,
  pointer : @pointer_events.PointerId,
) -> @core.Entity? {
  if pointer < 0 || pointer >= self.mesh3d.length() {
    None
  } else {
    self.mesh3d[pointer]
  }
}

///|
pub(all) enum PointerButton {
  Primary
  Secondary
  Middle
} derive(Eq, Show)

///|
pub impl @app.Resource for PointerInputs with resource() {
  ecs_res_key_pointer_inputs
}

///|
pub impl @app.Resource for PickingHits with resource() {
  ecs_res_key_picking_hits
}

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
pub fn picking_clear_system(world : @ecs.World) -> Unit {
  @app.get_picking_events_resource(world).insert(@app.PickingEvents::default())
}

///|
pub fn ensure_picking_state_system(world : @ecs.World) -> Unit {
  let res = get_picking_state_resource(world)
  if res.get() is None {
    res.insert(PickingState::default())
  }
}

///|
pub fn ensure_picking_hits_system(world : @ecs.World) -> Unit {
  let res = get_picking_hits_resource(world)
  if res.get() is None {
    res.insert(PickingHits::default())
  }
}

///|
pub fn ensure_pointer_inputs_system(world : @ecs.World) -> Unit {
  let res = get_pointer_inputs_resource(world)
  if res.get() is None {
    res.insert(PointerInputs::default())
  }
}

///|
pub fn picking_collect_mouse_system(world : @ecs.World) -> Unit {
  let res = get_pointer_inputs_resource(world)
  guard res.get() is Some(inputs_value) else { return }
  let inputs = Ref::new(inputs_value)
  PointerInputs::clear(inputs)
  let pointer : @pointer_events.PointerId = 0
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
  res.insert(inputs.val)
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
fn picking_rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
fn sprite_region_size(sprite : @sprite.Sprite) -> @math.Vec2 {
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
fn picking_camera_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(gt) => gt.to_transform_approx()
    None =>
      match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
        Some(value) => value
        None => @transform.Transform::identity()
      }
  }
}

///|
fn picking_camera_target_size(
  camera : @sprite.Camera,
  window_width : Int,
  window_height : Int,
) -> @math.IVec2 {
  match camera.physical_target_size() {
    Some(size) =>
      if size.x > 0 && size.y > 0 {
        size
      } else {
        @math.IVec2::new(window_width, window_height)
      }
    None => @math.IVec2::new(window_width, window_height)
  }
}

///|
fn picking_insert_camera_sorted(
  cameras : Ref[Array[(@core.Entity, @sprite.Camera, @pbr.Projection)]],
  camera : (@core.Entity, @sprite.Camera, @pbr.Projection),
) -> Unit {
  let mut insert_at = cameras.val.length()
  for i in 0..<cameras.val.length() {
    if camera.1.order > cameras.val[i].1.order {
      insert_at = i
      break
    }
  }
  cameras.val.insert(insert_at, camera)
}

///|
/// 3D mesh hit testing backend (ray cast against `Mesh3d`).
pub fn picking_mesh3d_hit_test_system(world : @ecs.World) -> Unit {
  let inputs_res = get_pointer_inputs_resource(world)
  let hits_res = get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get() is Some(hits_value) else { return }
  let hits = Ref::new(hits_value)
  let scale_factor = @window.window_scale_factor()
  let window_width = @window.window_width()
  let window_height = @window.window_height()
  let cameras : Ref[Array[(@core.Entity, @sprite.Camera, @pbr.Projection)]] = Ref::new([],
  )
  world.for_each_component(@pbr.ecs_key_camera3d, fn(entity, _camera3d) {
    guard (try! world.get_by_key(entity, @sprite.ecs_key_camera))
      is Some(camera) else {
      return
    }
    if !camera.is_active {
      return
    }
    let projection = match
      (try! world.get_by_key(entity, @pbr.ecs_key_projection)) {
      Some(value) => value
      None => @pbr.Projection::default()
    }
    picking_insert_camera_sorted(cameras, (entity, camera, projection))
  })
  for input in inputs0.pointers {
    let pointer_id = input.pointer
    let mut hit_top : @core.Entity? = None
    if input.window_position is Some(cursor) {
      for entry in cameras.val {
        if hit_top is Some(_) {
          break
        }
        let camera_entity = entry.0
        let camera = entry.1
        let projection = entry.2
        let camera_transform = picking_camera_transform(world, camera_entity)
        let target_size = picking_camera_target_size(
          camera, window_width, window_height,
        )
        if @pbr.mesh_ray_cast_from_camera_first(
            world,
            cursor,
            camera,
            projection,
            camera_transform,
            target_size,
            scale_factor,
            @pbr.MeshRayCastSettings::default().with_include_invisible(false),
          )
          is Some((entity, _hit)) {
          hit_top = Some(entity)
        }
      }
    }
    PickingHits::set_mesh3d(hits, pointer_id, hit_top)
  }
  hits_res.insert(hits.val)
}

///|

///|
/// 2D sprite hit testing backend (orthographic camera, clip-agnostic).
pub fn picking_sprite2d_hit_test_system(world : @ecs.World) -> Unit {
  let inputs_res = get_pointer_inputs_resource(world)
  let hits_res = get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get() is Some(hits_value) else { return }
  let hits = Ref::new(hits_value)
  let ctx_res = @ui.get_ui_context_resource(world)
  guard ctx_res.get() is Some(ctx0) else { return }
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
      world.for_each_component(@sprite.ecs_key_sprite, fn(entity, sprite) {
        if (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility))
          is Some(vv) &&
          !vv.is_visible() {
          return
        }
        let transform = match
          (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
          Some(gt) => gt.to_transform_approx()
          None =>
            match
              (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
              Some(t) => t
              None => @transform.Transform::identity()
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
        let anchor = match
          (try! world.get_by_key(entity, @sprite.ecs_key_anchor)) {
          Some(a) => a
          None => @sprite.Anchor::default()
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
  hits_res.insert(hits.val)
}

///|
/// UI hit testing backend (front-to-back, clip aware).
pub fn picking_ui_hit_test_system(world : @ecs.World) -> Unit {
  let inputs_res = get_pointer_inputs_resource(world)
  let hits_res = get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get() is Some(hits_value) else { return }
  let hits = Ref::new(hits_value)
  let stack_res = @ui.get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  for input in inputs0.pointers {
    let pointer_id = input.pointer
    let mut hit_top : @core.Entity? = None
    let mut captured = false
    if input.window_position is Some(pointer_window_pos) {
      for i in 0..<stack0.uinodes.length() {
        if captured {
          break
        }
        let idx = stack0.uinodes.length() - 1 - i
        let entity = stack0.uinodes[idx]
        if !(try! world.contains_by_key(entity, @ui.ecs_key_button)) {
          continue
        }
        if (try! world.get_by_key(entity, @visibility.ecs_key_view_visibility))
          is Some(vv) &&
          !vv.is_visible() {
          continue
        }
        if !@ui.ui_entity_contains_pointer(world, entity, pointer_window_pos) {
          continue
        }
        if hit_top is None {
          hit_top = Some(entity)
        }
        let focus = match
          (try! world.get_by_key(entity, @ui.ecs_key_focus_policy)) {
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
  hits_res.insert(hits.val)
}

///|
fn picking_primary_hit(
  hits : PickingHits,
  pointer : @pointer_events.PointerId,
) -> @core.Entity? {
  match PickingHits::ui(hits, pointer) {
    Some(e) => Some(e)
    None =>
      match PickingHits::sprite2d(hits, pointer) {
        Some(e) => Some(e)
        None => PickingHits::mesh3d(hits, pointer)
      }
  }
}

///|
fn entity_from_node_id(node_id : @moon_accesskit.NodeId) -> @core.Entity {
  let raw = node_id.to_u64()
  if raw == 0UL {
    return @core.Entity::new(0, 0)
  }
  let packed = raw.to_int() - 1
  let id = packed / 65536
  let gen = packed - id * 65536
  @core.Entity::new(id, gen)
}

///|
/// Apply host-driven accessibility actions to UI state and picking events.
pub fn picking_apply_a11y_actions_system(world : @ecs.World) -> Unit {
  let state_res = @a11y.get_a11y_state_resource(world)
  guard state_res.get() is Some(state_value) else { return }
  let state = Ref::new(state_value)
  let actions = @a11y.A11yState::drain_actions(state)
  if actions.length() == 0 {
    state_res.insert(state.val)
    return
  }
  let events_res = @app.get_picking_events_resource(world)
  guard events_res.get() is Some(events_value) else {
    state_res.insert(state.val)
    return
  }
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

  for req in actions {
    let entity = entity_from_node_id(req.target_node())
    if !world.is_alive(entity) {
      continue
    }
    match req.action() {
      @moon_accesskit.Action::Focus => {
        @a11y.A11yState::set_focused_node(state, req.target_node())
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
        @a11y.A11yState::set_focused_node(state, req.target_node())
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
          @a11y.A11yState::set_focused_node(state, req.target_node())
          text_node.content = value
          ignore(try! world.replace(entity, @text.ecs_key_text, text_node))
        }
      _ => ()
    }
  }
  state_res.insert(state.val)
  events_res.insert(events.val)
}

///|
/// Generate pointer enter/leave/down/up/click events from hit-test results.
pub fn picking_generate_events_system(world : @ecs.World) -> Unit {
  let inputs_res = get_pointer_inputs_resource(world)
  let hits_res = get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get() is Some(hits0) else { return }
  let events_res = @app.get_picking_events_resource(world)
  guard events_res.get() is Some(events_value) else { return }
  let events = Ref::new(events_value)
  let state_res = get_picking_state_resource(world)
  guard state_res.get() is Some(state_value) else { return }
  let picking_state = Ref::new(state_value)
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
      let pos = match pos_opt {
        Some(v) => v
        None => @math.Vec2::new(0.0F, 0.0F)
      }
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
      let pos = match pos_opt {
        Some(v) => v
        None => @math.Vec2::new(0.0F, 0.0F)
      }
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

///|
pub fn picking_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
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
    @app.system(picking_mesh3d_hit_test_system).in_set(picking_set_hits),
  )
  .add_pre_update_system_config(
    @app.system(picking_apply_a11y_actions_system).in_set(picking_set_events),
  )
  .add_pre_update_system_config(
    @app.system(picking_generate_events_system).in_set(picking_set_events),
  )
  .add_pre_update_system_config(
    @app.system(@app.dispatch_pointer_observers_system).after(
      picking_set_events,
    ),
  )
  .configure_set(@app.PreUpdate, picking_set_input, before=[picking_set_hits])
  .configure_set(
    @app.PreUpdate,
    picking_set_hits,
    after=[picking_set_input, @transform.transform_set_propagate],
    before=[picking_set_events],
  )
  .configure_set(@app.PreUpdate, picking_set_events, after=[
    picking_set_hits, @a11y.a11y_set, @ui.ui_set_focus,
  ])
}
