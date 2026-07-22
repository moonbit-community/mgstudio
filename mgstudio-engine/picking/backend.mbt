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
  { camera, depth, position, normal }
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
  { pointer, picks, order }
}

///|
pub fn pointer_hits_message_key() -> @ecs.MessageKey[PointerHits] {
  ecs_msg_key_pointer_hits
}

///|
pub impl @ecs.Message for PointerHits with fn message() {
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
fn picking_mesh_camera_transform(
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
fn picking_camera_affine(
  world : @ecs.World,
  entity : @core.Entity,
) -> @math.Affine3 {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global_transform) => global_transform.affine()
    None =>
      match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
        Some(transform) =>
          @transform.GlobalTransform::from_transform(transform).affine()
        None => @math.Affine3::identity()
      }
  }
}

///|
fn picking_affine_inverse(affine : @math.Affine3) -> @math.Affine3? {
  let cofactor_x = affine.matrix3.y_axis.cross(affine.matrix3.z_axis)
  let cofactor_y = affine.matrix3.z_axis.cross(affine.matrix3.x_axis)
  let cofactor_z = affine.matrix3.x_axis.cross(affine.matrix3.y_axis)
  let determinant = affine.matrix3.z_axis.dot(cofactor_z)
  if determinant == 0.0F {
    return None
  }
  let inverse_matrix3 = @math.Mat3::from_cols(
      cofactor_x, cofactor_y, cofactor_z,
    )
    .transpose()
    .mul_scalar(1.0F / determinant)
  Some(
    @math.Affine3::from_mat3_translation(
      inverse_matrix3,
      inverse_matrix3.mul_vec3(affine.translation).neg(),
    ),
  )
}

///|
fn picking_insert_camera_sorted(
  cameras : Array[(@core.Entity, @camera_camera.Camera, @camera.Projection)],
  camera : (@core.Entity, @camera_camera.Camera, @camera.Projection),
) -> Unit {
  let mut insert_at = cameras.length()
  for i in 0..<cameras.length() {
    if camera.1.order > cameras[i].1.order {
      insert_at = i
      break
    }
  }
  cameras.insert(insert_at, camera)
}

///|
fn picking_insert_sprite_camera_sorted(
  cameras : Array[
    (
      @core.Entity,
      @camera_camera.Camera,
      @camera.Projection,
      @math.Affine3,
      Bool,
      @camera_render_layers.RenderLayers,
    ),
  ],
  camera : (
    @core.Entity,
    @camera_camera.Camera,
    @camera.Projection,
    @math.Affine3,
    Bool,
    @camera_render_layers.RenderLayers,
  ),
) -> Unit {
  let mut insert_at = cameras.length()
  for i in 0..<cameras.length() {
    if camera.1.order > cameras[i].1.order {
      insert_at = i
      break
    }
  }
  cameras.insert(insert_at, camera)
}

///|
fn current_sprite_picking_settings(world : @ecs.World) -> SpritePickingSettings {
  match get_sprite_picking_settings_resource(world).get() {
    Some(settings) => settings
    None => SpritePickingSettings()
  }
}

///|
fn picking_image_assets(world : @ecs.World) -> @asset.Assets[@asset.Image] {
  let key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  match world.get_resource(key) {
    Some(assets) => assets
    None => @asset.Assets::new()
  }
}

///|
fn picking_texture_atlas_assets(
  world : @ecs.World,
) -> @asset.Assets[@asset.TextureAtlasLayout] {
  let key : @ecs.ResourceKey[@asset.Assets[@asset.TextureAtlasLayout]] = @asset.assets_resource_key()
  match world.get_resource(key) {
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
    is Inside(pixel) else {
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
  (
    @core.Entity,
    @camera_camera.Camera,
    @camera.Projection,
    @math.Affine3,
    Bool,
    @camera_render_layers.RenderLayers,
  ),
] {
  let cameras : Array[
    (
      @core.Entity,
      @camera_camera.Camera,
      @camera.Projection,
      @math.Affine3,
      Bool,
      @camera_render_layers.RenderLayers,
    ),
  ] = []
  world.for_each_component(@camera_components2d.ecs_key_camera2d, fn(
    entity,
    _camera2d,
  ) {
    guard (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
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
    guard (try! world.get_by_key(
        entity, @camera_projection2d.ecs_key_projection,
      ))
      is Some(Orthographic(projection_2d)) else {
      return
    }
    // Mgstudio stores the implemented 2D authoring subset separately from the
    // full runtime projection. Reconstruct Bevy's Camera2d-required
    // `OrthographicProjection::default_2d()` before the viewport update below.
    let projection = @camera.Projection::Orthographic(
      @camera.OrthographicProjection3d::default_2d().with_scale(
        projection_2d.scale,
      ),
    )
    let affine = picking_camera_affine(world, entity)
    let render_layers = (try! world.get_by_key(
      entity, @camera_render_layers.ecs_key_render_layers,
    )).unwrap_or(RenderLayers())
    picking_insert_sprite_camera_sorted(
      cameras,
      (entity, camera, projection, affine, has_marker, render_layers),
    )
  })
  cameras
}

///|
fn picking_sprite_ray_local_hit(
  origin : @math.Vec3,
  direction : @math.Vec3,
  affine : @math.Affine3,
  max_distance : Float,
) -> (@math.Vec2, Float)? {
  guard picking_affine_inverse(affine) is Some(world_to_sprite) else {
    return None
  }
  let cursor_start_sprite = world_to_sprite.transform_point3(origin)
  let cursor_end_sprite = world_to_sprite.transform_point3(
    origin.add(direction.mul_scalar(max_distance)),
  )
  if cursor_start_sprite.z == cursor_end_sprite.z {
    return None
  }
  let lerp_factor = -cursor_start_sprite.z /
    (cursor_end_sprite.z - cursor_start_sprite.z)
  if !(lerp_factor >= 0.0F && lerp_factor <= 1.0F) {
    return None
  }
  let local_hit = cursor_start_sprite.add(
    cursor_end_sprite.sub(cursor_start_sprite).mul_scalar(lerp_factor),
  )
  Some((@math.Vec2::new(local_hit.x, local_hit.y), lerp_factor * max_distance))
}

///|
fn picking_sprite_camera_viewport_to_world_ray(
  screen : @math.Vec2,
  camera : @camera_camera.Camera,
  projection : @camera.Projection,
  camera_affine : @math.Affine3,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (@math.Vec3, @math.Vec3)? {
  guard @pbr_render.render3d_camera_viewport_rect_logical(
      camera, target_size, scale_factor,
    )
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  if screen.x < viewport_x ||
    screen.y < viewport_y ||
    screen.x > viewport_x + viewport_width ||
    screen.y > viewport_y + viewport_height {
    return None
  }
  let ndc_x = (screen.x - viewport_x) / viewport_width * 2.0F - 1.0F
  let ndc_y = 1.0F - (screen.y - viewport_y) / viewport_height * 2.0F
  let clip_from_view = projection
    .update(viewport_width, viewport_height)
    .get_clip_from_view()
  guard @pbr_render.render3d_projection_matrix_inverse(clip_from_view)
    is Some(view_from_clip) else {
    return None
  }
  let near_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 1.0F, 1.0F),
  )
  let far_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 1.1920929e-7F, 1.0F),
  )
  if near_view_h.w == 0.0F || far_view_h.w == 0.0F {
    return None
  }
  let near_view = @math.Vec3::new(
    near_view_h.x / near_view_h.w,
    near_view_h.y / near_view_h.w,
    near_view_h.z / near_view_h.w,
  )
  let far_view = @math.Vec3::new(
    far_view_h.x / far_view_h.w,
    far_view_h.y / far_view_h.w,
    far_view_h.z / far_view_h.w,
  )
  let direction = camera_affine.matrix3
    .mul_vec3(far_view.sub(near_view))
    .normalize_or_zero()
  if direction.length_squared() <= 1.0e-12F ||
    direction.x.is_nan() ||
    direction.y.is_nan() ||
    direction.z.is_nan() {
    return None
  }
  Some((camera_affine.transform_point3(near_view), direction))
}

///|
type SpritePickingEntry = (
  @core.Entity,
  @sprite.Sprite,
  @math.Affine3,
  @sprite.Anchor,
  Pickable,
  @camera_render_layers.RenderLayers,
)

///|
fn picking_sprite_depth_radix_key(entry : SpritePickingEntry) -> UInt {
  let bits = (-entry.2.translation.z).reinterpret_as_uint()
  let flip_negative_mask = if (bits & 0x8000_0000U) != 0U {
    0xffff_ffffU
  } else {
    0U
  }
  bits ^ (flip_negative_mask | 0x8000_0000U)
}

///|
// Bevy source: `radsort::sort_by_key(..., |(_, _, transform, ..)|
// -transform.translation().z)` in `bevy_sprite::picking_backend::sprite_picking`.
fn picking_sprite_stable_radix_sort(
  entries : Array[SpritePickingEntry],
) -> Array[SpritePickingEntry] {
  if entries.length() < 2 {
    return entries
  }
  let mut current = entries
  for digit in 0..<4 {
    let offsets = FixedArray::make(256, 0)
    let shift = digit * 8
    for entry in current {
      let bucket = ((picking_sprite_depth_radix_key(entry) >> shift) & 0xffU).reinterpret_as_int()
      offsets[bucket] = offsets[bucket] + 1
    }
    let mut non_empty_buckets = 0
    for bucket in 0..<256 {
      if offsets[bucket] != 0 {
        non_empty_buckets = non_empty_buckets + 1
      }
    }
    if non_empty_buckets <= 1 {
      continue
    }
    let mut offset = 0
    for bucket in 0..<256 {
      let count = offsets[bucket]
      offsets[bucket] = offset
      offset = offset + count
    }
    let next = Array::make(current.length(), current[0])
    for entry in current {
      let bucket = ((picking_sprite_depth_radix_key(entry) >> shift) & 0xffU).reinterpret_as_int()
      let index = offsets[bucket]
      next[index] = entry
      offsets[bucket] = index + 1
    }
    current = next
  }
  current
}

///|
fn picking_sprite_collect_sorted(
  world : @ecs.World,
) -> Array[SpritePickingEntry] {
  let sprites : Array[SpritePickingEntry] = []
  let query : @ecs.Query[
    (
      (
        @ecs.Read[@sprite.Sprite],
        @ecs.Read[@transform.GlobalTransform],
        @ecs.Read[@sprite.Anchor],
        @ecs.Read[Pickable],
      ),
      (
        @ecs.Read[@visibility.ViewVisibility],
        @ecs.Optional[@camera_render_layers.RenderLayers],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.for_each_table(fn(batch) {
    let sprite = batch.read(@sprite.ecs_key_sprite).unwrap()
    let global_transform = batch
      .read(@transform.ecs_key_global_transform)
      .unwrap()
    let anchor = batch.read(@sprite.ecs_key_anchor).unwrap()
    let pickable = batch.read(ecs_key_pickable).unwrap()
    let visibility = batch.read(@visibility.ecs_key_view_visibility).unwrap()
    let layers = batch.read(@camera_render_layers.ecs_key_render_layers)
    for row_index in 0..<batch.length() {
      if global_transform.value(row_index).affine().is_nan() ||
        !visibility.value(row_index).is_visible() {
        continue
      }
      sprites.push(
        (
          batch.entity(row_index),
          sprite.value(row_index),
          global_transform.value(row_index).affine(),
          anchor.value(row_index),
          pickable.value(row_index),
          match layers {
            Some(column) => column.value(row_index)
            None => RenderLayers()
          },
        ),
      )
    }
  })
  picking_sprite_stable_radix_sort(sprites)
}

///|
fn picking_sprite_hit_from_local_pos(
  world : @ecs.World,
  entry : (
    @core.Entity,
    @sprite.Sprite,
    @math.Affine3,
    @sprite.Anchor,
    Pickable,
    @camera_render_layers.RenderLayers,
  ),
  local_pos : @math.Vec2,
  settings : SpritePickingSettings,
  camera_entity : @core.Entity,
  camera_affine : @math.Affine3,
  camera_near : Float,
) -> (@core.Entity, HitData)? {
  let entity = entry.0
  let sprite = entry.1
  let affine = entry.2
  let anchor = entry.3
  if picking_sprite_pixel_is_valid(
      world,
      sprite,
      anchor,
      local_pos,
      settings.picking_mode,
    ) {
    let position = affine.transform_point3(
      @math.Vec3::new(local_pos.x, local_pos.y, 0.0F),
    )
    guard picking_affine_inverse(camera_affine) is Some(world_to_camera) else {
      return None
    }
    let camera_position = world_to_camera.transform_point3(position)
    let depth = -camera_near - camera_position.z
    Some(
      (
        entity,
        HitData::new(
          camera_entity,
          depth,
          Some(position),
          Some(affine.matrix3.z_axis.normalize()),
        ),
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
  let cameras : Array[(@core.Entity, @camera_camera.Camera, @camera.Projection)] = []
  world.for_each_component(@camera.ecs_key_camera3d, fn(entity, _camera3d) {
    guard (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
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
      for entry in cameras {
        if hit_top is Some(_) {
          break
        }
        let camera_entity = entry.0
        let camera = entry.1
        let projection = entry.2
        let camera_transform = picking_mesh_camera_transform(
          world, camera_entity,
        )
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
            @picking_mesh_ray_cast.MeshRayCastIntersectionSettings::MeshRayCastIntersectionSettings().with_include_invisible(
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
        let camera_affine = camera_entry.3
        let camera_layers = camera_entry.5
        guard projection is Orthographic(orthographic) else { continue }
        let target_size = picking_camera_target_size(
          camera, window_width, window_height,
        )
        guard picking_sprite_camera_viewport_to_world_ray(
            pointer_window_pos, camera, projection, camera_affine, target_size, scale_factor,
          )
          is Some((origin, direction)) else {
          continue
        }
        let max_distance = orthographic.far() - orthographic.near()
        let picks : Array[(@core.Entity, HitData)] = []
        let mut blocked = false
        for entry in sorted_sprites {
          if blocked {
            break
          }
          let affine = entry.2
          let pickable = entry.4
          if !camera_layers.intersects(entry.5) {
            continue
          }
          guard picking_sprite_ray_local_hit(
              origin, direction, affine, max_distance,
            )
            is Some((local_pos, _depth)) else {
            continue
          }
          guard picking_sprite_hit_from_local_pos(
              world,
              entry,
              local_pos,
              settings,
              camera_entry.0,
              camera_affine,
              orthographic.near(),
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
          None => Block
        }
        if focus == Block {
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
priv struct PickingEntitySearchState {
  mut entity : @core.Entity?
}

///|
/// Window hit backend (`bevy_picking::window::update_window_hits` shape).
pub fn picking_window_hit_test_system(world : @ecs.World) -> Unit {
  let inputs = pointer_inputs_for_backend(world)
  let primary_window = PickingEntitySearchState::{ entity: None }
  world.for_each_component(@window.ecs_key_primary_window, fn(
    entity,
    _primary,
  ) {
    if primary_window.entity is None {
      primary_window.entity = Some(entity)
    }
  })
  if primary_window.entity is None {
    world.for_each_component(@window.ecs_key_window, fn(entity, _window) {
      if primary_window.entity is None {
        primary_window.entity = Some(entity)
      }
    })
  }
  for input in inputs {
    let pointer_id = input.pointer
    let hit_window = match input.window_position {
      Some(_) => primary_window.entity
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
