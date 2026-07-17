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
fn sprite_mesh2d_aabb(mesh2d : Mesh2d) -> @camera_primitives.Aabb? {
  guard render_mesh_asset_get(mesh2d.mesh()) is Some(mesh_asset) else {
    return None
  }
  @camera_primitives.mesh_compute_aabb(mesh_asset)
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
fn sprite_size_from_sprite_mesh(
  sprite : SpriteMesh,
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
    @camera_primitives.Aabb::from_min_max_xyz(
      center_x - half_x,
      center_y - half_y,
      0.0F,
      center_x + half_x,
      center_y + half_y,
      0.0F,
    ),
  )
}

///|
fn sprite_mesh_aabb(
  sprite : SpriteMesh,
  anchor : Anchor,
  atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout],
) -> @camera_primitives.Aabb? {
  guard sprite_size_from_sprite_mesh(sprite, atlas_layout_assets) is Some(size) else {
    return None
  }
  let anchor_vec = anchor.as_vec()
  let center_x = -anchor_vec.x * size.x
  let center_y = -anchor_vec.y * size.y
  let half_x = size.x * 0.5F
  let half_y = size.y * 0.5F
  Some(
    @camera_primitives.Aabb::from_min_max_xyz(
      center_x - half_x,
      center_y - half_y,
      0.0F,
      center_x + half_x,
      center_y + half_y,
      0.0F,
    ),
  )
}

///|
fn sprite_aabbs_equal(
  current : @camera_primitives.Aabb,
  next : @camera_primitives.Aabb,
) -> Bool {
  current.equals(next)
}

///|
fn sprite_insert_or_replace_new_aabb(
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
type SpriteNewMeshAabbQuery = @ecs.Query[
  @ecs.Read[Mesh2d],
  (
    (
      (
        @ecs.Without[@camera_primitives.Aabb],
        @ecs.Without[@visibility.NoFrustumCulling],
      ),
      @ecs.Without[@visibility.NoAutoAabb],
    ),
    @ecs.Without[SpriteMesh],
  ),
]

///|
type SpriteUpdateMeshAabbQuery = @ecs.Query[
  (@ecs.Read[Mesh2d], @ecs.Write[@camera_primitives.Aabb]),
  (
    (
      (@ecs.Changed[Mesh2d], @ecs.Without[@visibility.NoFrustumCulling]),
      @ecs.Without[@visibility.NoAutoAabb],
    ),
    (@ecs.Without[SpriteMesh], @ecs.Without[Sprite]),
  ),
]

///|
type SpriteNewAabbQuery = @ecs.Query[
  (@ecs.Read[Sprite], @ecs.Read[Anchor]),
  (
    (
      @ecs.Without[@camera_primitives.Aabb],
      @ecs.Without[@visibility.NoFrustumCulling],
    ),
    @ecs.Without[@visibility.NoAutoAabb],
  ),
]

///|
type SpriteUpdateAabbQuery = @ecs.Query[
  ((@ecs.Read[Sprite], @ecs.Write[@camera_primitives.Aabb]), @ecs.Read[Anchor]),
  (
    (
      @ecs.Or[(@ecs.Changed[Sprite], @ecs.Changed[Anchor])],
      @ecs.Without[@visibility.NoFrustumCulling],
    ),
    (@ecs.Without[@visibility.NoAutoAabb], @ecs.Without[Mesh2d]),
  ),
]

///|
type SpriteMeshNewAabbQuery = @ecs.Query[
  (@ecs.Read[SpriteMesh], @ecs.Read[Anchor]),
  (
    (
      @ecs.Without[@camera_primitives.Aabb],
      @ecs.Without[@visibility.NoFrustumCulling],
    ),
    @ecs.Without[@visibility.NoAutoAabb],
  ),
]

///|
type SpriteMeshUpdateAabbQuery = @ecs.Query[
  (
    (@ecs.Read[SpriteMesh], @ecs.Write[@camera_primitives.Aabb]),
    @ecs.Read[Anchor],
  ),
  (
    (
      @ecs.Or[(@ecs.Changed[SpriteMesh], @ecs.Changed[Anchor])],
      @ecs.Without[@visibility.NoFrustumCulling],
    ),
    @ecs.Without[@visibility.NoAutoAabb],
  ),
]

///|
fn sprite_collect_new_mesh_aabbs(
  world : @ecs.World,
  pending_aabbs : Array[(@core.Entity, @camera_primitives.Aabb)],
) -> Unit {
  let query : SpriteNewMeshAabbQuery = @ecs.query_filtered(
    world,
    (
      (
        (
          @ecs.Without::new(@camera_primitives.ecs_key_aabb),
          @ecs.Without::new(@visibility.ecs_key_no_frustum_culling),
        ),
        @ecs.Without::new(@visibility.ecs_key_no_auto_aabb),
      ),
      @ecs.Without::new(ecs_key_sprite_mesh),
    ),
  )
  try! query.for_each_table(fn(batch) {
    let mesh2d = batch.read(@mesh.ecs_key_mesh2d).unwrap()
    for row_index in 0..<batch.length() {
      if sprite_mesh2d_aabb(mesh2d.value(row_index)) is Some(aabb) {
        pending_aabbs.push((batch.entity(row_index), aabb))
      }
    }
  })
}

///|
fn sprite_update_mesh_aabbs(world : @ecs.World) -> Int {
  let query : SpriteUpdateMeshAabbQuery = @ecs.query_filtered(
    world,
    (
      (
        (
          @ecs.Changed::new(@mesh.ecs_key_mesh2d),
          @ecs.Without::new(@visibility.ecs_key_no_frustum_culling),
        ),
        @ecs.Without::new(@visibility.ecs_key_no_auto_aabb),
      ),
      (
        @ecs.Without::new(ecs_key_sprite_mesh),
        @ecs.Without::new(ecs_key_sprite),
      ),
    ),
  )
  let changed_count = Ref(0)
  let used_batch = try! query.try_for_each_filtered_table(fn(batch, rows) {
    let mesh2d = batch.read(@mesh.ecs_key_mesh2d).unwrap()
    let aabbs = batch.write(@camera_primitives.ecs_key_aabb).unwrap()
    try! rows.for_each(fn(row_index) {
      changed_count.val = changed_count.val + 1
      if sprite_mesh2d_aabb(mesh2d.value(row_index)) is Some(next) &&
        !sprite_aabbs_equal(aabbs.peek(row_index), next) {
        aabbs.set(row_index, next)
      }
    })
  })
  if !used_batch {
    try! query.for_each(fn(_entity, data) {
      changed_count.val = changed_count.val + 1
      let (mesh2d, aabb) = data
      if sprite_mesh2d_aabb(mesh2d.value()) is Some(next) &&
        !sprite_aabbs_equal(aabb.peek(), next) {
        aabb.set(next)
      }
    })
  }
  changed_count.val
}

///|
fn sprite_collect_new_sprite_aabbs(
  world : @ecs.World,
  atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout],
  pending_aabbs : Array[(@core.Entity, @camera_primitives.Aabb)],
) -> Unit {
  let query : SpriteNewAabbQuery = @ecs.query_filtered(
    world,
    (
      (
        @ecs.Without::new(@camera_primitives.ecs_key_aabb),
        @ecs.Without::new(@visibility.ecs_key_no_frustum_culling),
      ),
      @ecs.Without::new(@visibility.ecs_key_no_auto_aabb),
    ),
  )
  try! query.for_each_table(fn(batch) {
    let sprites = batch.read(ecs_key_sprite).unwrap()
    let anchors = batch.read(ecs_key_anchor).unwrap()
    for row_index in 0..<batch.length() {
      if sprite_sprite_aabb(
          sprites.value(row_index),
          anchors.value(row_index),
          atlas_layout_assets,
        )
        is Some(aabb) {
        pending_aabbs.push((batch.entity(row_index), aabb))
      }
    }
  })
}

///|
fn sprite_update_sprite_aabbs(
  world : @ecs.World,
  atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout],
) -> Int {
  let query : SpriteUpdateAabbQuery = @ecs.query_filtered(
    world,
    (
      (
        @ecs.Or::new(
          (@ecs.Changed::new(ecs_key_sprite), @ecs.Changed::new(ecs_key_anchor)),
        ),
        @ecs.Without::new(@visibility.ecs_key_no_frustum_culling),
      ),
      (
        @ecs.Without::new(@visibility.ecs_key_no_auto_aabb),
        @ecs.Without::new(@mesh.ecs_key_mesh2d),
      ),
    ),
  )
  let changed_count = Ref(0)
  let used_batch = try! query.try_for_each_filtered_table(fn(batch, rows) {
    let sprites = batch.read(ecs_key_sprite).unwrap()
    let aabbs = batch.write(@camera_primitives.ecs_key_aabb).unwrap()
    let anchors = batch.read(ecs_key_anchor).unwrap()
    try! rows.for_each(fn(row_index) {
      changed_count.val = changed_count.val + 1
      if sprite_sprite_aabb(
          sprites.value(row_index),
          anchors.value(row_index),
          atlas_layout_assets,
        )
        is Some(next) &&
        !sprite_aabbs_equal(aabbs.peek(row_index), next) {
        aabbs.set(row_index, next)
      }
    })
  })
  if !used_batch {
    try! query.for_each(fn(_entity, data) {
      changed_count.val = changed_count.val + 1
      let ((sprite, aabb), anchor) = data
      if sprite_sprite_aabb(sprite.value(), anchor.value(), atlas_layout_assets)
        is Some(next) &&
        !sprite_aabbs_equal(aabb.peek(), next) {
        aabb.set(next)
      }
    })
  }
  changed_count.val
}

///|
fn sprite_collect_new_sprite_mesh_aabbs(
  world : @ecs.World,
  atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout],
  pending_aabbs : Array[(@core.Entity, @camera_primitives.Aabb)],
) -> Unit {
  let query : SpriteMeshNewAabbQuery = @ecs.query_filtered(
    world,
    (
      (
        @ecs.Without::new(@camera_primitives.ecs_key_aabb),
        @ecs.Without::new(@visibility.ecs_key_no_frustum_culling),
      ),
      @ecs.Without::new(@visibility.ecs_key_no_auto_aabb),
    ),
  )
  try! query.for_each_table(fn(batch) {
    let sprite_meshes = batch.read(ecs_key_sprite_mesh).unwrap()
    let anchors = batch.read(ecs_key_anchor).unwrap()
    for row_index in 0..<batch.length() {
      if sprite_mesh_aabb(
          sprite_meshes.value(row_index),
          anchors.value(row_index),
          atlas_layout_assets,
        )
        is Some(aabb) {
        pending_aabbs.push((batch.entity(row_index), aabb))
      }
    }
  })
}

///|
fn sprite_update_sprite_mesh_aabbs(
  world : @ecs.World,
  atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout],
) -> Int {
  let query : SpriteMeshUpdateAabbQuery = @ecs.query_filtered(
    world,
    (
      (
        @ecs.Or::new(
          (
            @ecs.Changed::new(ecs_key_sprite_mesh),
            @ecs.Changed::new(ecs_key_anchor),
          ),
        ),
        @ecs.Without::new(@visibility.ecs_key_no_frustum_culling),
      ),
      @ecs.Without::new(@visibility.ecs_key_no_auto_aabb),
    ),
  )
  let changed_count = Ref(0)
  let used_batch = try! query.try_for_each_filtered_table(fn(batch, rows) {
    let sprite_meshes = batch.read(ecs_key_sprite_mesh).unwrap()
    let aabbs = batch.write(@camera_primitives.ecs_key_aabb).unwrap()
    let anchors = batch.read(ecs_key_anchor).unwrap()
    try! rows.for_each(fn(row_index) {
      changed_count.val = changed_count.val + 1
      if sprite_mesh_aabb(
          sprite_meshes.value(row_index),
          anchors.value(row_index),
          atlas_layout_assets,
        )
        is Some(next) &&
        !sprite_aabbs_equal(aabbs.peek(row_index), next) {
        aabbs.set(row_index, next)
      }
    })
  })
  if !used_batch {
    try! query.for_each(fn(_entity, data) {
      changed_count.val = changed_count.val + 1
      let ((sprite_mesh, aabb), anchor) = data
      if sprite_mesh_aabb(
          sprite_mesh.value(),
          anchor.value(),
          atlas_layout_assets,
        )
        is Some(next) &&
        !sprite_aabbs_equal(aabb.peek(), next) {
        aabb.set(next)
      }
    })
  }
  changed_count.val
}

///|
fn sprite_calculate_bounds_2d(world : @ecs.World) -> Unit {
  let has_mesh2d = world.component_count(@mesh.ecs_key_mesh2d) > 0
  let has_sprite = world.component_count(ecs_key_sprite) > 0
  let has_sprite_mesh = world.component_count(ecs_key_sprite_mesh) > 0
  if !has_mesh2d && !has_sprite && !has_sprite_mesh {
    return
  }
  let pending_aabbs : Array[(@core.Entity, @camera_primitives.Aabb)] = []
  let mut changed_mesh2d_count = 0
  let mut changed_sprite_count = 0
  let mut changed_sprite_mesh_count = 0

  let scan_mesh2d_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.scan_mesh2d",
  )
  if has_mesh2d {
    sprite_collect_new_mesh_aabbs(world, pending_aabbs)
    changed_mesh2d_count = sprite_update_mesh_aabbs(world)
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.scan_mesh2d",
    scan_mesh2d_trace_start_us,
  )

  let scan_sprites_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.scan_sprites",
  )
  if has_sprite {
    let atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout] = @asset.asset_assets_or_abort()
    sprite_collect_new_sprite_aabbs(world, atlas_layout_assets, pending_aabbs)
    changed_sprite_count = sprite_update_sprite_aabbs(
      world, atlas_layout_assets,
    )
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.scan_sprites",
    scan_sprites_trace_start_us,
  )

  let scan_sprite_mesh_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.scan_sprite_mesh",
  )
  if has_sprite_mesh {
    let atlas_layout_assets : @asset.Assets[@asset.TextureAtlasLayout] = @asset.asset_assets_or_abort()
    sprite_collect_new_sprite_mesh_aabbs(
      world, atlas_layout_assets, pending_aabbs,
    )
    changed_sprite_mesh_count = sprite_update_sprite_mesh_aabbs(
      world, atlas_layout_assets,
    )
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.scan_sprite_mesh",
    scan_sprite_mesh_trace_start_us,
  )

  let apply_aabbs_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.apply_aabbs",
  )
  for entry in pending_aabbs {
    sprite_insert_or_replace_new_aabb(world, entry.0, entry.1)
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "sprite_bounds.apply_aabbs",
    apply_aabbs_trace_start_us,
  )
  @app.timeline_trace_emit_counter_int(
    "sprite_bounds.changed_mesh2d_entities", changed_mesh2d_count,
  )
  @app.timeline_trace_emit_counter_int(
    "sprite_bounds.changed_sprite_or_anchor_entities", changed_sprite_count,
  )
  @app.timeline_trace_emit_counter_int(
    "sprite_bounds.changed_sprite_mesh_or_anchor_entities", changed_sprite_mesh_count,
  )
  @app.timeline_trace_emit_counter_int(
    "sprite_bounds.pending_aabbs",
    pending_aabbs.length(),
  )
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
