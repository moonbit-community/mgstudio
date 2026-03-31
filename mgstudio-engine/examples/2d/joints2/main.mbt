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
  .add_systems(@app.Startup, @app.system(rapier2d_joints2_setup))
  .run()
}

///|
fn rapier2d_joints2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.90F, 0.92F, 0.96F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) =>
      cfg_res.insert(current.with_gravity(@math.Vec2::new(0.0F, -700.0F)))
    None =>
      cfg_res.insert(
        @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -700.0F)),
      )
  }
  let anchor = world.spawn_empty()
  try! world.set_by_key(
    anchor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 200.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    anchor,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::fixed(),
  )
  try! world.set_by_key(
    anchor,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(6.0F)),
  )
  let mut previous = anchor
  for i in 0..<4 {
    let link = world.spawn_empty()
    try! world.set_by_key(
      link,
      @transform.ecs_key_transform,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 160.0F - Float::from_int(i) * 60.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=1.0F,
      ),
    )
    try! world.set_by_key(
      link,
      @sprite.ecs_key_sprite,
      @sprite.Sprite::from_image(texture)
      .with_color(@sprite.Color::new(0.85F, 0.55F, 0.20F, 1.0F))
      .with_custom_size(Some(@math.Vec2::new(40.0F, 18.0F))),
    )
    try! world.set_by_key(
      link,
      @physics2d.ecs_key_rigid_body2d,
      @physics2d.RigidBody2d::dynamic(),
    )
    try! world.set_by_key(
      link,
      @physics2d.ecs_key_collider2d,
      @physics2d.Collider2d::new(
        @physics2d.ColliderShape2d::cuboid(20.0F, 9.0F),
      ),
    )
    try! world.set_by_key(
      link,
      @physics2d.ecs_key_impulse_joint2d,
      @physics2d.ImpulseJoint2d::new(
        previous,
        @physics2d.joint2d_revolute(
          @math.Vec2::new(0.0F, -30.0F),
          @math.Vec2::new(0.0F, 30.0F),
        ),
      ),
    )
    previous = link
  }
}
