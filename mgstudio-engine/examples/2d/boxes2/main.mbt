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
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(rapier2d_boxes2_setup))
  .run()
}

///|
fn rapier2d_boxes2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.53F, 0.71F, 0.47F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let floor = world.spawn_empty()
  try! world.set_by_key(
    floor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -250.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    floor,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.25F, 0.25F, 0.25F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(780.0F, 40.0F))),
  )
  try! world.set_by_key(
    floor,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::fixed(),
  )
  try! world.set_by_key(
    floor,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(390.0F, 20.0F),
    ),
  )
  let left_wall = world.spawn_empty()
  try! world.set_by_key(
    left_wall,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-410.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    left_wall,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::fixed(),
  )
  try! world.set_by_key(
    left_wall,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(20.0F, 400.0F),
    ),
  )
  let right_wall = world.spawn_empty()
  try! world.set_by_key(
    right_wall,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(410.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    right_wall,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::fixed(),
  )
  try! world.set_by_key(
    right_wall,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(20.0F, 400.0F),
    ),
  )
  for row in 0..<6 {
    for col in 0..<8 {
      let box = world.spawn_empty()
      try! world.set_by_key(
        box,
        @transform.ecs_key_transform,
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(
            -280.0F + Float::from_int(col) * 80.0F,
            -220.0F + Float::from_int(row) * 58.0F,
          ),
          0.0F,
          @math.Vec2::new(1.0F, 1.0F),
          z=1.0F,
        ),
      )
      try! world.set_by_key(
        box,
        @sprite.ecs_key_sprite,
        @sprite.Sprite::from_image(texture)
        .with_color(@sprite.Color::new(0.92F, 0.72F, 0.34F, 1.0F))
        .with_custom_size(Some(@math.Vec2::new(48.0F, 48.0F))),
      )
      try! world.set_by_key(
        box,
        @physics2d.ecs_key_rigid_body2d,
        @physics2d.RigidBody2d::dynamic(),
      )
      try! world.set_by_key(
        box,
        @physics2d.ecs_key_collider2d,
        @physics2d.Collider2d::new(
          @physics2d.ColliderShape2d::cuboid(24.0F, 24.0F),
        ),
      )
    }
  }
}
