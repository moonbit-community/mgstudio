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
// Bevy source: `bevy/crates/bevy_picking/src/backend.rs`.
/// Backend-facing hit-test types and systems.

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
pub impl @app.Resource for PickingHits with resource() {
  ecs_res_key_picking_hits
}

///|
pub fn ensure_picking_hits_system(world : @ecs.World) -> Unit {
  let res = get_picking_hits_resource(world)
  if res.get() is None {
    res.insert(PickingHits::default())
  }
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
        if @picking_mesh_ray_cast.mesh_ray_cast_from_camera_first(
            world,
            cursor,
            camera,
            projection,
            camera_transform,
            target_size,
            scale_factor,
            @picking_mesh_ray_cast.MeshRayCastSettings::default().with_include_invisible(
              false,
            ),
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
/// 2D sprite hit testing backend (orthographic camera, clip-agnostic).
pub fn picking_sprite2d_hit_test_system(world : @ecs.World) -> Unit {
  let inputs_res = get_pointer_inputs_resource(world)
  let hits_res = get_picking_hits_resource(world)
  guard inputs_res.get() is Some(inputs0) else { return }
  guard hits_res.get() is Some(hits_value) else { return }
  let hits = Ref::new(hits_value)
  let ctx_res = @ui.get_ui_context_resource(world)
  guard ctx_res.get() is Some(ctx0) else { return }
  for input in inputs0.pointers {
    let pointer_id = input.pointer
    let mut hit_top : @core.Entity? = None
    let mut hit_z = -1.0e30F
    if input.window_position is Some(pointer_window_pos) {
      if picking_window_to_sprite_world(pointer_window_pos, ctx0)
        is Some(pointer_world) {
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
          let abs_x = if local_pos.x < 0.0F {
            -local_pos.x
          } else {
            local_pos.x
          }
          let abs_y = if local_pos.y < 0.0F {
            -local_pos.y
          } else {
            local_pos.y
          }
          if abs_x <= half.x && abs_y <= half.y {
            let z = transform.translation.z
            if z > hit_z {
              hit_z = z
              hit_top = Some(entity)
            }
          }
        })
      }
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
