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
test "sprite bounds: new Sprite with Mesh2d still receives the sprite Aabb" {
  let world = @ecs.World::new()
  defer world.close()
  let mut app = @app.App::new(world).add_plugins(SpritePlugin::SpritePlugin())
  let atlases : @asset.Assets[@asset.TextureAtlasLayout] = @asset.Assets::new()
  world.insert_resource(@asset.assets_resource_key(), atlases)
  let meshes : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
  world.insert_resource(@asset.assets_resource_key(), meshes)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_sprite,
    Sprite::sized(@math.Vec2::new(10.0F, 6.0F)),
  )
  try! world.set_by_key(entity, ecs_key_anchor, Anchor::center())
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_mesh2d,
    @mesh.Mesh2d::new(@asset.Handle::new(999)),
  )

  app = app.update()

  guard (try! world.get_by_key(entity, @camera_primitives.ecs_key_aabb))
    is Some(aabb) else {
    debug_inspect(false, content="true")
    return
  }
  let center = aabb.center()
  let half_size = aabb.half_size()
  debug_inspect(
    center.x == 0.0F &&
    center.y == 0.0F &&
    center.z == 0.0F &&
    half_size.x == 5.0F &&
    half_size.y == 3.0F &&
    half_size.z == 0.0F,
    content="true",
  )
}

///|
test "sprite bounds: equal Aabb replacement preserves change ticks" {
  let world = @ecs.World::new()
  defer world.close()
  let mut app = @app.App::new(world).add_plugins(SpritePlugin::SpritePlugin())
  let atlases : @asset.Assets[@asset.TextureAtlasLayout] = @asset.Assets::new()
  world.insert_resource(@asset.assets_resource_key(), atlases)
  let meshes : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
  world.insert_resource(@asset.assets_resource_key(), meshes)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    ecs_key_sprite,
    Sprite::sized(@math.Vec2::new(4.0F, 6.0F)),
  )
  try! world.set_by_key(entity, ecs_key_anchor, Anchor::center())
  let replace_with_equal_sprite = Ref(false)
  app = app.add_systems(
    @app.Update,
    @app.system(fn(world : @ecs.World) {
      if replace_with_equal_sprite.val {
        try! (world.replace(
          entity,
          ecs_key_sprite,
          Sprite::sized(@math.Vec2::new(4.0F, 6.0F)),
        )
        |> ignore)
        replace_with_equal_sprite.val = false
      }
    }),
  )

  app = app.update()
  let before = world.read_change_tick()
  replace_with_equal_sprite.val = true
  app = app.update()
  let after = world.read_change_tick()
  let changed = world
    .changed_components(
      @camera_primitives.ecs_key_aabb,
      @core.SystemTicks::new(before, after),
    )
    .read()
  debug_inspect(changed.contains(entity), content="false")
}
