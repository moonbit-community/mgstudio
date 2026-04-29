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
  let anchor = @sprite.Anchor::default()
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
      @sprite.Anchor::default(),
      @math.Vec2::new(0.0F, 0.0F),
      BoundingBox,
    ),
    content="true",
  )
}

///|
test "sprite picking camera marker requirement filters cameras" {
  let world = @ecs.World::new()
  let camera_entity = world.spawn_empty()
  try! world.set_by_key(
    camera_entity,
    @sprite.ecs_key_camera2d,
    @sprite.Camera2d::default(),
  )
  try! world.set_by_key(
    camera_entity,
    @sprite.ecs_key_camera,
    @sprite.Camera::default(),
  )
  try! world.set_by_key(
    camera_entity,
    @camera.ecs_key_projection,
    @camera.Projection::default(),
  )
  try! world.set_by_key(
    camera_entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
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
