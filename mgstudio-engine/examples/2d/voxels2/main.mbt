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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(rapier2d_voxels2_setup))
  .run()
}

///|
fn rapier2d_voxels2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.58F, 0.73F, 0.49F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) =>
      cfg_res.insert(current.with_gravity(@math.Vec2::new(0.0F, -750.0F)))
    None =>
      cfg_res.insert(
        @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -750.0F)),
      )
  }
  for y in 0..<8 {
    for x in 0..<16 {
      let voxel = world.spawn_empty()
      try! world.set_by_key(
        voxel,
        @transform.ecs_key_transform,
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(
            -320.0F + Float::from_int(x) * 42.0F,
            -180.0F + Float::from_int(y) * 42.0F,
          ),
          0.0F,
          @math.Vec2::new(1.0F, 1.0F),
          z=1.0F,
        ),
      )
      try! world.set_by_key(
        voxel,
        @sprite.ecs_key_sprite,
        @sprite.Sprite::from_image(texture)
        .with_color(@sprite.Color::new(0.92F, 0.74F, 0.37F, 1.0F))
        .with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F))),
      )
      try! world.set_by_key(
        voxel,
        @physics2d.ecs_key_rigid_body2d,
        @physics2d.RigidBody2d::dynamic(),
      )
      try! world.set_by_key(
        voxel,
        @physics2d.ecs_key_collider2d,
        @physics2d.Collider2d::new(
          @physics2d.ColliderShape2d::cuboid(14.0F, 14.0F),
        ),
      )
    }
  }
}
