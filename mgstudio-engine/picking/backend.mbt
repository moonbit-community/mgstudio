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
pub struct HitData {
  camera : @core.Entity
  depth : Float
  position : @math.Vec3?
  normal : @math.Vec3?
} derive(ToJson, FromJson)

///|
pub fn HitData::new(
  camera : @core.Entity,
  depth : Float,
  position : @math.Vec3?,
  normal : @math.Vec3?,
) -> HitData {
  HitData::{ camera, depth, position, normal }
}

///|
pub struct PointerHits {
  pointer : @pointer_events.PointerId
  picks : Array[(@core.Entity, HitData)]
  order : Float
} derive(ToJson, FromJson)

///|
pub fn PointerHits::new(
  pointer : @pointer_events.PointerId,
  picks : Array[(@core.Entity, HitData)],
  order : Float,
) -> PointerHits {
  PointerHits::{ pointer, picks, order }
}

///|
pub fn pointer_hits_message_key() -> @ecs.MessageKey[PointerHits] {
  ecs_msg_key_pointer_hits
}

///|
pub impl @ecs.Message for PointerHits with message() {
  ecs_msg_key_pointer_hits
}

///|
fn picking_write_pointer_hits(
  world : @ecs.World,
  pointer : @pointer_events.PointerId,
  picks : Array[(@core.Entity, HitData)],
  order : Float,
) -> Unit {
  if world.contains_message(pointer_hits_message_key()) {
    ignore(
      world
      .message_writer(pointer_hits_message_key())
      .write(PointerHits::new(pointer, picks, order)),
    )
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
  cameras : Ref[Array[(@core.Entity, @sprite.Camera, @camera.Projection)]],
  camera : (@core.Entity, @sprite.Camera, @camera.Projection),
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
fn picking_insert_sprite_camera_sorted(
  cameras : Ref[
    Array[
      (
        @core.Entity,
        @sprite.Camera,
        @camera.Projection,
        @transform.Transform,
        Bool,
      ),
    ],
  ],
  camera : (
    @core.Entity,
    @sprite.Camera,
    @camera.Projection,
    @transform.Transform,
    Bool,
  ),
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
fn current_sprite_picking_settings(world : @ecs.World) -> SpritePickingSettings {
  match get_sprite_picking_settings_resource(world).get() {
    Some(settings) => settings
    None => SpritePickingSettings::default()
  }
}

///|
fn picking_image_assets(world : @ecs.World) -> @asset.Assets[@asset.Image] {
  let key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) => assets
    None => @asset.Assets::new()
  }
}

///|
fn picking_texture_atlas_assets(
  world : @ecs.World,
) -> @asset.Assets[@asset.TextureAtlasLayout] {
  let key : @ecs.ResourceKey[@asset.Assets[@asset.TextureAtlasLayout]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) => assets
    None => @asset.Assets::new()
  }
}

///|
fn picking_sprite_rgba8_alpha_at(
  image : @asset.Image,
  pixel : @math.Vec2,
) -> Float? {
  match image.format {
    Rgba8Unorm | Rgba8UnormSrgb => ()
    _ => return None
  }
  let x = pixel.x.to_int()
  let y = pixel.y.to_int()
  if x < 0 || y < 0 || x >= image.width || y >= image.height {
    return None
  }
  let alpha_offset = (y * image.width + x) * 4 + 3
  guard image.pixels.get(alpha_offset) is Some(alpha) else { return None }
  Some(Float::from_int(alpha.to_int()) / 255.0F)
}

///|
fn picking_sprite_pixel_is_valid(
  world : @ecs.World,
  sprite : @sprite.Sprite,
  anchor : @sprite.Anchor,
  local_pos : @math.Vec2,
  mode : SpritePickingMode,
) -> Bool {
  let images = picking_image_assets(world)
  let texture_atlases = picking_texture_atlas_assets(world)
  guard sprite.compute_pixel_space_point(
      local_pos, anchor, images, texture_atlases,
    )
    is Ok(pixel) else {
    return false
  }
  match mode {
    BoundingBox => true
    AlphaThreshold(cutoff) =>
      match images.get(sprite.image) {
        None => true
        Some(image) =>
          match picking_sprite_rgba8_alpha_at(image, pixel) {
            Some(alpha) => alpha > cutoff
            None => false
          }
      }
  }
}

///|
fn picking_sprite_cameras(
  world : @ecs.World,
  settings : SpritePickingSettings,
) -> Array[
  (@core.Entity, @sprite.Camera, @camera.Projection, @transform.Transform, Bool),
] {
  let cameras : Ref[
    Array[
      (
        @core.Entity,
        @sprite.Camera,
        @camera.Projection,
        @transform.Transform,
        Bool,
      ),
    ],
  ] = Ref([])
  world.for_each_component(@sprite.ecs_key_camera2d, fn(entity, _camera2d) {
    guard (try! world.get_by_key(entity, @sprite.ecs_key_camera))
      is Some(camera) else {
      return
    }
    if !camera.is_active {
      return
    }
    let has_marker = try! world.contains_by_key(
      entity, ecs_key_sprite_picking_camera,
    )
    if settings.require_markers && !has_marker {
      return
    }
    let projection = match
      (try! world.get_by_key(entity, @camera.ecs_key_projection)) {
      Some(value) => value
      None => @camera.Projection::default()
    }
    let transform = picking_camera_transform(world, entity)
    picking_insert_sprite_camera_sorted(
      cameras,
      (entity, camera, projection, transform, has_marker),
    )
  })
  cameras.val
}

///|
fn picking_sprite_ray_local_hit(
  origin : @math.Vec3,
  direction : @math.Vec3,
  transform : @transform.Transform,
  max_distance : Float,
) -> (@math.Vec2, Float)? {
  guard @pbr_render.render3d_inverse_transform_point(transform, origin)
    is Some(local_origin) else {
    return None
  }
  guard @pbr_render.render3d_inverse_transform_direction(transform, direction)
    is Some(local_direction) else {
    return None
  }
  if @pbr_render.absf(local_direction.z) <= 1.0e-9F {
    return None
  }
  let distance = -local_origin.z / local_direction.z
  if distance < 0.0F || distance > max_distance {
    return None
  }
  let local_hit = local_origin.add(local_direction.mul_scalar(distance))
  Some((@math.Vec2::new(local_hit.x, local_hit.y), distance))
}

///|
fn picking_sprite_collect_sorted(
  world : @ecs.World,
) -> Array[
  (@core.Entity, @sprite.Sprite, @transform.Transform, @sprite.Anchor, Pickable),
] {
  let sorted_sprites : Array[
    (
      @core.Entity,
      @sprite.Sprite,
      @transform.Transform,
      @sprite.Anchor,
      Pickable,
    ),
  ] = []
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
        match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
          Some(t) => t
          None => @transform.Transform::identity()
        }
    }
    let anchor = match (try! world.get_by_key(entity, @sprite.ecs_key_anchor)) {
      Some(a) => a
      None => @sprite.Anchor::default()
    }
    let pickable = match (try! world.get_by_key(entity, ecs_key_pickable)) {
      Some(value) => value
      None => Pickable::default()
    }
    let mut insert_at = sorted_sprites.length()
    for i in 0..<sorted_sprites.length() {
      if transform.translation.z > sorted_sprites[i].2.translation.z {
        insert_at = i
        break
      }
    }
    sorted_sprites.insert(
      insert_at,
      (entity, sprite, transform, anchor, pickable),
    )
  })
  sorted_sprites
}

///|
fn picking_sprite_hit_from_local_pos(
  world : @ecs.World,
  entry : (
    @core.Entity,
    @sprite.Sprite,
    @transform.Transform,
    @sprite.Anchor,
    Pickable,
  ),
  local_pos : @math.Vec2,
  settings : SpritePickingSettings,
  depth : Float,
) -> (@core.Entity, HitData)? {
  let entity = entry.0
  let sprite = entry.1
  let transform = entry.2
  let anchor = entry.3
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
    return None
  }
  let abs_x = if local_pos.x < 0.0F { -local_pos.x } else { local_pos.x }
  let abs_y = if local_pos.y < 0.0F { -local_pos.y } else { local_pos.y }
  if abs_x <= half.x &&
    abs_y <= half.y &&
    picking_sprite_pixel_is_valid(
      world,
      sprite,
      anchor,
      local_pos,
      settings.picking_mode,
    ) {
    let position = transform.transform_point(
      @math.Vec3::new(local_pos.x, local_pos.y, 0.0F),
    )
    Some(
      (
        entity,
        HitData::new(entity, depth, Some(position), Some(transform.back())),
      ),
    )
  } else {
    None
  }
}

///|
/// 3D mesh hit testing backend (ray cast against `Mesh3d`).
pub fn picking_mesh3d_hit_test_system(world : @ecs.World) -> Unit {
  let inputs = pointer_inputs_for_backend(world)
  let scale_factor = @window.window_scale_factor()
  let window_width = @window.window_width()
  let window_height = @window.window_height()
  let cameras : Ref[Array[(@core.Entity, @sprite.Camera, @camera.Projection)]] = Ref([],
  )
  world.for_each_component(@camera.ecs_key_camera3d, fn(entity, _camera3d) {
    guard (try! world.get_by_key(entity, @sprite.ecs_key_camera))
      is Some(camera) else {
      return
    }
    if !camera.is_active {
      return
    }
    let projection = match
      (try! world.get_by_key(entity, @camera.ecs_key_projection)) {
      Some(value) => value
      None => @camera.Projection::default()
    }
    picking_insert_camera_sorted(cameras, (entity, camera, projection))
  })
  for input in inputs {
    let pointer_id = input.pointer
    let mut hit_top : @core.Entity? = None
    let mut hit_payload : (@core.Entity, HitData)? = None
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
          is Some((entity, hit)) {
          hit_top = Some(entity)
          hit_payload = Some(
            (
              entity,
              HitData::new(
                camera_entity,
                hit.distance,
                Some(hit.point),
                Some(hit.normal),
              ),
            ),
          )
        }
      }
    }
    picking_write_pointer_hits(
      world,
      pointer_id,
      match hit_payload {
        Some(payload) => [payload]
        None => []
      },
      match hit_payload {
        Some(_) => 2.0F
        None => 2.0F
      },
    )
  }
}

///|
/// 2D sprite hit testing backend (orthographic camera, clip-agnostic).
pub fn picking_sprite2d_hit_test_system(world : @ecs.World) -> Unit {
  let inputs = pointer_inputs_for_backend(world)
  let settings = current_sprite_picking_settings(world)
  let scale_factor = @window.window_scale_factor()
  let window_width = @window.window_width()
  let window_height = @window.window_height()
  let cameras = picking_sprite_cameras(world, settings)
  let sorted_sprites = picking_sprite_collect_sorted(world)
  for input in inputs {
    let pointer_id = input.pointer
    let mut wrote_camera_hits = false
    if input.window_position is Some(pointer_window_pos) {
      for camera_entry in cameras {
        let camera = camera_entry.1
        let projection = camera_entry.2
        let camera_transform = camera_entry.3
        let target_size = picking_camera_target_size(
          camera, window_width, window_height,
        )
        guard @camera.camera_viewport_to_world_ray(
            pointer_window_pos, camera, projection, camera_transform, target_size,
            scale_factor,
          )
          is Some((origin, direction)) else {
          continue
        }
        let max_distance = projection.far().max(1.0F)
        let picks : Array[(@core.Entity, HitData)] = []
        let mut blocked = false
        for entry in sorted_sprites {
          if blocked {
            break
          }
          let transform = entry.2
          let pickable = entry.4
          guard picking_sprite_ray_local_hit(
              origin, direction, transform, max_distance,
            )
            is Some((local_pos, depth)) else {
            continue
          }
          guard picking_sprite_hit_from_local_pos(
              world, entry, local_pos, settings, depth,
            )
            is Some(payload) else {
            continue
          }
          picks.push(payload)
          if pickable.should_block_lower {
            blocked = true
          }
        }
        picking_write_pointer_hits(world, pointer_id, picks, 2.0F)
        wrote_camera_hits = true
      }
    }
    if !wrote_camera_hits {
      picking_write_pointer_hits(world, pointer_id, [], 2.0F)
    }
  }
}

///|
/// UI hit testing backend (front-to-back, clip aware).
pub fn picking_ui_hit_test_system(world : @ecs.World) -> Unit {
  let inputs = pointer_inputs_for_backend(world)
  let stack_res = @ui.get_ui_stack_resource(world)
  guard stack_res.get() is Some(stack0) else { return }
  for input in inputs {
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
    picking_write_pointer_hits(
      world,
      pointer_id,
      match hit_top {
        Some(entity) => [(entity, HitData::new(entity, 0.0F, None, None))]
        None => []
      },
      3.0F,
    )
  }
}

///|
/// Window hit backend (`bevy_picking::window::update_window_hits` shape).
pub fn picking_window_hit_test_system(world : @ecs.World) -> Unit {
  let inputs = pointer_inputs_for_backend(world)
  let primary_window_entity : Ref[@core.Entity?] = Ref(None)
  world.for_each_component(@window.ecs_key_primary_window, fn(
    entity,
    _primary,
  ) {
    if primary_window_entity.val is None {
      primary_window_entity.val = Some(entity)
    }
  })
  if primary_window_entity.val is None {
    world.for_each_component(@window.ecs_key_window, fn(entity, _window) {
      if primary_window_entity.val is None {
        primary_window_entity.val = Some(entity)
      }
    })
  }
  for input in inputs {
    let pointer_id = input.pointer
    let hit_window = match input.window_position {
      Some(_) => primary_window_entity.val
      None => None
    }
    picking_write_pointer_hits(
      world,
      pointer_id,
      match hit_window {
        Some(entity) => [(entity, HitData::new(entity, 0.0F, None, None))]
        None => []
      },
      0.0F,
    )
  }
}
