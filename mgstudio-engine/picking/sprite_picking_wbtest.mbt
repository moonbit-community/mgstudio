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
test "sprite picking alpha threshold samples rgba8 pixels" {
  let world = @ecs.World::new()
  defer world.close()
  let images : @asset.Assets[@asset.Image] = @asset.Assets::new()
  let image_handle : @asset.Handle[@asset.Image] = @asset.Handle::new(0)
  ignore(
    images.insert(
      image_handle,
      @asset.Image::new(2, 1, Bytes::from_array([0, 0, 0, 0, 0, 0, 0, 255])),
    ),
  )
  world.insert_resource(@asset.assets_resource_key(), images)
  let atlases : @asset.Assets[@asset.TextureAtlasLayout] = @asset.Assets::new()
  world.insert_resource(@asset.assets_resource_key(), atlases)
  let sprite = @sprite.Sprite::from_image(image_handle)
    .with_rect(
      Some(
        @math.Rect::new(
          @math.Vec2::new(0.0F, 0.0F),
          @math.Vec2::new(2.0F, 1.0F),
        ),
      ),
    )
    .with_custom_size(Some(@math.Vec2::new(2.0F, 1.0F)))
  let anchor = @sprite.Anchor::Anchor()
  debug_inspect(
    picking_sprite_pixel_is_valid(
      world,
      sprite,
      anchor,
      @math.Vec2::new(-0.5F, 0.0F),
      AlphaThreshold(0.1F),
    ),
    content="false",
  )
  debug_inspect(
    picking_sprite_pixel_is_valid(
      world,
      sprite,
      anchor,
      @math.Vec2::new(0.5F, 0.0F),
      AlphaThreshold(0.1F),
    ),
    content="true",
  )
}

///|
test "sprite picking bounding box ignores transparent pixels" {
  let world = @ecs.World::new()
  defer world.close()
  let images : @asset.Assets[@asset.Image] = @asset.Assets::new()
  let image_handle : @asset.Handle[@asset.Image] = @asset.Handle::new(0)
  ignore(
    images.insert(
      image_handle,
      @asset.Image::new(1, 1, Bytes::from_array([0, 0, 0, 0])),
    ),
  )
  world.insert_resource(@asset.assets_resource_key(), images)
  let atlases : @asset.Assets[@asset.TextureAtlasLayout] = @asset.Assets::new()
  world.insert_resource(@asset.assets_resource_key(), atlases)
  let sprite = @sprite.Sprite::from_image(image_handle)
    .with_rect(
      Some(
        @math.Rect::new(
          @math.Vec2::new(0.0F, 0.0F),
          @math.Vec2::new(1.0F, 1.0F),
        ),
      ),
    )
    .with_custom_size(Some(@math.Vec2::new(1.0F, 1.0F)))
  debug_inspect(
    picking_sprite_pixel_is_valid(
      world,
      sprite,
      @sprite.Anchor::Anchor(),
      @math.Vec2::new(0.0F, 0.0F),
      BoundingBox,
    ),
    content="true",
  )
}

///|
test "sprite picking collection matches bevy required query and stable depth sort" {
  let world = @ecs.World::new()
  defer world.close()
  let entities : Array[@core.Entity] = []
  let nan = 0.0F / 0.0F
  for
    candidate in [
      (1.0F, true, true, None),
      (1.0F, true, true, Some(3)),
      (3.0F, true, true, None),
      (4.0F, false, true, None),
      (5.0F, true, false, None),
      (nan, true, true, None),
    ] {
    let entity = world.spawn_empty()
    entities.push(entity)
    try! world.set_by_key(
      entity,
      @sprite.ecs_key_sprite,
      @sprite.Sprite::sized(@math.Vec2::new(8.0F, 8.0F)),
    )
    try! world.set_by_key(
      entity,
      @transform.ecs_key_global_transform,
      @transform.GlobalTransform::from_transform(
        @transform.Transform::from_xyz(0.0F, 0.0F, candidate.0),
      ),
    )
    try! world.set_by_key(
      entity,
      @sprite.ecs_key_anchor,
      @sprite.Anchor::center(),
    )
    try! world.set_by_key(
      entity,
      @visibility.ecs_key_view_visibility,
      @visibility.ViewVisibility::new(candidate.1),
    )
    if candidate.2 {
      try! world.set_by_key(entity, ecs_key_pickable, Pickable::Pickable())
    }
    match candidate.3 {
      Some(layer) =>
        try! world.set_by_key(
          entity,
          @camera_render_layers.ecs_key_render_layers,
          @camera_render_layers.RenderLayers::layer(layer),
        )
      None => ()
    }
  }

  let sorted = picking_sprite_collect_sorted(world)
  let ok = sorted.length() == 3 &&
    sorted[0].0 == entities[2] &&
    sorted[1].0 == entities[0] &&
    sorted[2].0 == entities[1] &&
    sorted[0].5.mask() == 1 &&
    sorted[1].5.mask() == 1 &&
    sorted[2].5.mask() == 8
  debug_inspect(ok, content="true")
}

///|
test "sprite picking hit data uses camera entity and camera-space depth" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = @core.Entity::new(7, 0)
  let camera_entity = @core.Entity::new(11, 0)
  let sprite_transform = @transform.GlobalTransform::from_transform(
    @transform.Transform::from_xyz(0.0F, 0.0F, 2.0F),
  ).affine()
  let camera_transform = @transform.GlobalTransform::from_transform(
    @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F),
  ).affine()
  let entry : SpritePickingEntry = (
    entity,
    @sprite.Sprite::sized(@math.Vec2::new(2.0F, 2.0F)),
    sprite_transform,
    @sprite.Anchor::center(),
    Pickable::Pickable(),
    @camera_render_layers.RenderLayers::RenderLayers(),
  )
  let hit = picking_sprite_hit_from_local_pos(
    world,
    entry,
    @math.Vec2::zero(),
    SpritePickingSettings::new(false, BoundingBox),
    camera_entity,
    camera_transform,
    -1.0F,
  )
  guard hit is Some((hit_entity, hit_data)) else {
    debug_inspect(false, content="true")
    return
  }
  let position_ok = match hit_data.position {
    Some(position) =>
      position.x == 0.0F && position.y == 0.0F && position.z == 2.0F
    None => false
  }
  let ok = hit_entity == entity &&
    hit_data.camera == camera_entity &&
    hit_data.depth == 9.0F &&
    position_ok
  debug_inspect(ok, content="true")
}

///|
test "sprite picking preserves sheared global transform affine semantics" {
  let world = @ecs.World::new()
  defer world.close()
  @camera_components2d.ensure_camera2d_required_components(world)
  let parent = @transform.GlobalTransform::from_transform(
    @transform.Transform::identity()
    .with_translation(@math.Vec3::new(3.0F, -2.0F, 5.0F))
    .with_scale(@math.Vec3::new(0.5F, 1.0F, 0.25F)),
  )
  let child = @transform.GlobalTransform::from_transform(
    @transform.Transform::identity().with_rotation(
      @math.Quat::from_rotation_y(0.6F),
    ),
  )
  let global_transform = parent.mul(child)
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::sized(@math.Vec2::new(2.0F, 2.0F)),
  )
  try! world.set_by_key(
    entity, @transform.ecs_key_global_transform, global_transform,
  )
  try! world.set_by_key(
    entity,
    @sprite.ecs_key_anchor,
    @sprite.Anchor::center(),
  )
  try! world.set_by_key(entity, ecs_key_pickable, Pickable::Pickable())
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(true),
  )
  let camera_entity = world.spawn_empty()
  try! world.set_by_key(
    camera_entity,
    @camera_components2d.ecs_key_camera2d,
    @camera_components2d.Camera2d::Camera2d(),
  )
  try! world.set_by_key(
    camera_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  let entries = picking_sprite_collect_sorted(world)
  let cameras = picking_sprite_cameras(
    world,
    SpritePickingSettings::new(false, BoundingBox),
  )
  assert_eq(entries.length(), 1)
  assert_eq(cameras.length(), 1)
  let affine = global_transform.affine()
  let local_start = @math.Vec3::new(0.75F, 0.0F, 1.0F)
  let local_end = @math.Vec3::new(0.75F, 0.0F, -1.0F)
  let ray_origin = affine.transform_point3(local_start)
  let ray_end = affine.transform_point3(local_end)
  let ray_delta = ray_end.sub(ray_origin)
  guard picking_sprite_ray_local_hit(
      ray_origin,
      ray_delta.normalize(),
      entries[0].2,
      ray_delta.length(),
    )
    is Some((local_hit, _)) else {
    fail("expected sheared sprite ray hit")
  }
  guard picking_sprite_hit_from_local_pos(
      world,
      entries[0],
      local_hit,
      SpritePickingSettings::new(false, BoundingBox),
      camera_entity,
      cameras[0].3,
      -1.0F,
    )
    is Some((_, hit_data)) else {
    fail("expected sheared sprite hit data")
  }
  let expected_position = affine.transform_point3(
    @math.Vec3::new(0.75F, 0.0F, 0.0F),
  )
  let expected_normal = affine.matrix3.z_axis.normalize()
  guard hit_data.position is Some(position) else {
    fail("expected world hit position")
  }
  guard hit_data.normal is Some(normal) else {
    fail("expected world hit normal")
  }
  assert_eq(@pbr_render.absf(local_hit.x - 0.75F) <= 1.0e-5F, true)
  assert_eq(@pbr_render.absf(local_hit.y) <= 1.0e-5F, true)
  assert_eq(position.distance(expected_position) <= 1.0e-5F, true)
  assert_eq(normal.distance(expected_normal) <= 1.0e-5F, true)
}

///|
test "sprite picking camera marker requirement filters cameras" {
  let world = @ecs.World::new()
  defer world.close()
  @camera_components2d.ensure_camera2d_required_components(world)
  let camera_entity = world.spawn_empty()
  try! world.set_by_key(
    camera_entity,
    @camera_components2d.ecs_key_camera2d,
    @camera_components2d.Camera2d::Camera2d(),
  )
  debug_inspect(
    picking_sprite_cameras(world, SpritePickingSettings::new(true, BoundingBox)).length(),
    content="0",
  )
  try! world.set_by_key(camera_entity, ecs_key_sprite_picking_camera, SpritePickingCamera::{

  })
  debug_inspect(
    picking_sprite_cameras(world, SpritePickingSettings::new(true, BoundingBox)).length(),
    content="1",
  )
}

///|
test "sprite picking collects standard Camera2d orthographic projection" {
  let world = @ecs.World::new()
  defer world.close()
  @camera_components2d.ensure_camera2d_required_components(world)
  let camera_entity = world.spawn_empty()
  try! world.set_by_key(
    camera_entity,
    @camera_components2d.ecs_key_camera2d,
    @camera_components2d.Camera2d::Camera2d(),
  )
  ignore(
    try! world.replace(
      camera_entity,
      @camera_projection2d.ecs_key_projection,
      @camera_projection2d.Projection::Orthographic(
        @camera_projection2d.OrthographicProjection::new(2.0F),
      ),
    ),
  )
  let cameras = picking_sprite_cameras(
    world,
    SpritePickingSettings::new(false, BoundingBox),
  )
  assert_eq(cameras.length(), 1)
  let projection_matches_camera2d = match cameras[0].2 {
    @camera.Projection::Orthographic(orthographic) =>
      orthographic.scale() == 2.0F &&
      orthographic.near() == -1000.0F &&
      orthographic.far() == 1000.0F
    _ => false
  }
  assert_eq(projection_matches_camera2d, true)
  guard picking_sprite_camera_viewport_to_world_ray(
      @math.Vec2::new(50.0F, 50.0F),
      cameras[0].1,
      cameras[0].2,
      cameras[0].3,
      @math.IVec2::new(100, 100),
      1.0F,
    )
    is Some((origin, direction)) else {
    fail("expected standard Camera2d viewport ray")
  }
  guard picking_sprite_ray_local_hit(
      origin,
      direction,
      @math.Affine3::identity(),
      2000.0F,
    )
    is Some((local_hit, _)) else {
    fail("expected standard Camera2d ray to intersect the sprite plane")
  }
  assert_eq(@pbr_render.absf(local_hit.x) <= 1.0e-5F, true)
  assert_eq(@pbr_render.absf(local_hit.y) <= 1.0e-5F, true)
}
