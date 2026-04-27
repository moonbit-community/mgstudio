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
// Bevy source: `bevy/crates/bevy_sprite/src/lib.rs`.
// Package-level plugin boundary aligned with Bevy crate responsibilities.
const SPRITE_PLUGIN_NAME : String = "mgstudio.sprite.SpritePlugin"

///|
const CAMERA_VISIBILITY_RANGE_SET_CHECK : String = "mgstudio.camera.visibility.range.check"

///|
priv struct SpritePluginMarker {}

///|
let ecs_res_key_sprite_plugin_marker : @ecs.ResourceKey[SpritePluginMarker] = @ecs.register_resource(
  debug_name="mgstudio.sprite.SpritePluginMarker",
)

///|
let sprite_bounds_initialized_worlds_ref : Ref[
  @hashset.HashSet[Int]
] = Ref::new(@hashset.HashSet::new())

///|
fn sprite_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn sprite_insert_entity_key(
  set : @hashset.HashSet[UInt64],
  entity : @core.Entity,
) -> Unit {
  set.add(sprite_entity_key(entity))
}

///|
fn sprite_mesh2d_geometry_aabb(
  geometry : @mesh.Mesh2dGeometry,
) -> @camera_primitives.Aabb? {
  guard geometry.flatten_positions_xy() is Some(positions_xy) else {
    return None
  }
  if positions_xy.length() < 2 {
    return None
  }
  let mut min_x = Float::from_double(positions_xy[0])
  let mut min_y = Float::from_double(positions_xy[1])
  let mut max_x = min_x
  let mut max_y = min_y
  let mut index = 2
  while index + 1 < positions_xy.length() {
    let x = Float::from_double(positions_xy[index])
    let y = Float::from_double(positions_xy[index + 1])
    if x < min_x {
      min_x = x
    }
    if y < min_y {
      min_y = y
    }
    if x > max_x {
      max_x = x
    }
    if y > max_y {
      max_y = y
    }
    index = index + 2
  }
  Some(
    @camera_primitives.Aabb::from_min_max(
      @math.Vec3::new(min_x, min_y, 0.0F),
      @math.Vec3::new(max_x, max_y, 0.0F),
    ),
  )
}

///|
fn sprite_mesh2d_aabb(mesh2d : Mesh2d) -> @camera_primitives.Aabb? {
  guard render_mesh_asset_get(mesh2d.mesh()) is Some(mesh_asset) else {
    return None
  }
  guard mesh_asset.geometry is @mesh.MeshGeometry::Geometry2d(geometry2d) else {
    return None
  }
  sprite_mesh2d_geometry_aabb(geometry2d)
}

///|
fn sprite_size_from_image_handle(
  image : @asset.Handle[@asset.Image],
) -> @math.Vec2? {
  let width = @asset.asset_texture_width(image)
  let height = @asset.asset_texture_height(image)
  if width <= 0 || height <= 0 {
    None
  } else {
    Some(@math.Vec2::new(Float::from_int(width), Float::from_int(height)))
  }
}

///|
fn sprite_size_from_sprite(
  sprite : Sprite,
  atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout],
) -> @math.Vec2? {
  if sprite.custom_size is Some(size) {
    return Some(size)
  }
  if sprite.rect is Some(rect) {
    return Some(rect.size())
  }
  match sprite.texture_atlas {
    None => sprite_size_from_image_handle(sprite.image)
    Some(texture_atlas) =>
      texture_atlas
      .texture_rect(atlas_layout_assets)
      .map(fn(texture_rect) { texture_rect.size().to_vec2() })
  }
}

///|
fn sprite_sprite_aabb(
  sprite : Sprite,
  anchor : Anchor,
  atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout],
) -> @camera_primitives.Aabb? {
  guard sprite_size_from_sprite(sprite, atlas_layout_assets) is Some(size) else {
    return None
  }
  let anchor_vec = anchor.as_vec()
  let center_x = -anchor_vec.x * size.x
  let center_y = -anchor_vec.y * size.y
  let half_x = size.x * 0.5F
  let half_y = size.y * 0.5F
  Some(
    @camera_primitives.Aabb::from_min_max(
      @math.Vec3::new(center_x - half_x, center_y - half_y, 0.0F),
      @math.Vec3::new(center_x + half_x, center_y + half_y, 0.0F),
    ),
  )
}

///|
fn sprite_set_or_replace_aabb(
  world : @ecs.World,
  entity : @core.Entity,
  aabb : @camera_primitives.Aabb,
) -> Unit {
  if (try! world.contains_by_key(entity, @camera_primitives.ecs_key_aabb)) {
    try! (world.replace(entity, @camera_primitives.ecs_key_aabb, aabb) |> ignore)
  } else {
    try! world.set_by_key(entity, @camera_primitives.ecs_key_aabb, aabb)
  }
}

///|
fn sprite_calculate_bounds_2d(world : @ecs.World) -> Unit {
  let has_mesh2d = world.component_count(@mesh.ecs_key_mesh2d) > 0
  let has_sprite = world.component_count(ecs_key_sprite) > 0
  if !has_mesh2d && !has_sprite {
    return
  }
  let world_id = world.world_id()
  let first_run = !sprite_bounds_initialized_worlds_ref.val.contains(world_id)
  if first_run {
    sprite_bounds_initialized_worlds_ref.val.add(world_id)
  }
  let pending_aabbs : Array[(@core.Entity, @camera_primitives.Aabb)] = []
  let changed_mesh2d_entities : @hashset.HashSet[UInt64] = @hashset.HashSet::new()
  let changed_sprite_or_anchor_entities : @hashset.HashSet[UInt64] = @hashset.HashSet::new()
  if !first_run {
    let sequence = world.get_sequence_context().sequence()
    for entity in world.added_components(@mesh.ecs_key_mesh2d, sequence).read() {
      sprite_insert_entity_key(changed_mesh2d_entities, entity)
    }
    for
      entity in world.changed_components(@mesh.ecs_key_mesh2d, sequence).read() {
      sprite_insert_entity_key(changed_mesh2d_entities, entity)
    }
    for entity in world.added_components(ecs_key_sprite, sequence).read() {
      sprite_insert_entity_key(changed_sprite_or_anchor_entities, entity)
    }
    for entity in world.changed_components(ecs_key_sprite, sequence).read() {
      sprite_insert_entity_key(changed_sprite_or_anchor_entities, entity)
    }
    for entity in world.added_components(ecs_key_anchor, sequence).read() {
      sprite_insert_entity_key(changed_sprite_or_anchor_entities, entity)
    }
    for entity in world.changed_components(ecs_key_anchor, sequence).read() {
      sprite_insert_entity_key(changed_sprite_or_anchor_entities, entity)
    }
  }

  if has_mesh2d {
    let mesh2d_query : @ecs.Query[@ecs.Comp[Mesh2d], @ecs.All] = @ecs.query(
      world,
    )
    try! mesh2d_query.view(fn(entity, mesh2d_comp) {
      if (try! world.contains_by_key(
          entity, @visibility.ecs_key_no_frustum_culling,
        )) {
        return
      }
      if (try! world.contains_by_key(entity, @visibility.ecs_key_no_auto_aabb)) {
        return
      }
      let has_aabb = try! world.contains_by_key(
        entity, @camera_primitives.ecs_key_aabb,
      )
      if !first_run &&
        has_aabb &&
        !changed_mesh2d_entities.contains(sprite_entity_key(entity)) {
        return
      }
      if sprite_mesh2d_aabb(mesh2d_comp.value()) is Some(aabb) {
        pending_aabbs.push((entity, aabb))
      }
    })
  }

  if has_sprite {
    let atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout] = @asset.asset_assets_or_abort()
    let sprite_query : @ecs.Query[
      (@ecs.Comp[Sprite], @ecs.Comp[Anchor]),
      @ecs.All,
    ] = @ecs.query(world)
    try! sprite_query.view(fn(entity, data) {
      if (try! world.contains_by_key(entity, @mesh.ecs_key_mesh2d)) {
        return
      }
      if (try! world.contains_by_key(
          entity, @visibility.ecs_key_no_frustum_culling,
        )) {
        return
      }
      if (try! world.contains_by_key(entity, @visibility.ecs_key_no_auto_aabb)) {
        return
      }
      let has_aabb = try! world.contains_by_key(
        entity, @camera_primitives.ecs_key_aabb,
      )
      if !first_run &&
        has_aabb &&
        !changed_sprite_or_anchor_entities.contains(sprite_entity_key(entity)) {
        return
      }
      let (sprite_comp, anchor_comp) = data
      if sprite_sprite_aabb(
          sprite_comp.value(),
          anchor_comp.value(),
          atlas_layout_assets,
        )
        is Some(aabb) {
        pending_aabbs.push((entity, aabb))
      }
    })
  }
  for entry in pending_aabbs {
    sprite_set_or_replace_aabb(world, entry.0, entry.1)
  }
}

///|
pub fn sprite_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_res_key_sprite_plugin_marker) {
    return app
  }
  ensure_render2d_required_components(app.world())
  app
  .insert_world_resource(ecs_res_key_sprite_plugin_marker, SpritePluginMarker::{

  })
  .add_post_update_system_config(
    @app.system(sprite_calculate_bounds_2d)
    .after(@transform.transform_set_propagate)
    .before(CAMERA_VISIBILITY_RANGE_SET_CHECK),
  )
}
