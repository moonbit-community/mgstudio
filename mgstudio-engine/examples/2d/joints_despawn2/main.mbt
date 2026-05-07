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
let joints_despawn2_state : Ref[(Int, @core.Entity?)] = Ref((0, None))

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(rapier2d_joints_despawn2_setup))
  .add_systems(@app.Update, @app.system(rapier2d_joints_despawn2_tick))
  .run()
}

///|
fn rapier2d_joints_despawn2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.88F, 0.91F, 0.96F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) =>
      cfg_res.insert(current.with_gravity(@math.Vec2::new(0.0F, -650.0F)))
    None =>
      cfg_res.insert(
        @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -650.0F)),
      )
  }
  let anchor = world.spawn_empty()
  try! world.set_by_key(
    anchor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-60.0F, 180.0F),
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
  let bob = world.spawn_empty()
  try! world.set_by_key(
    bob,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(120.0F, 40.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    bob,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.95F, 0.60F, 0.25F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(34.0F, 34.0F))),
  )
  try! world.set_by_key(
    bob,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    bob,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(17.0F)),
  )
  try! world.set_by_key(
    bob,
    @physics2d.ecs_key_impulse_joint2d,
    @physics2d.ImpulseJoint2d::new(
      anchor,
      @physics2d.joint2d_rope(
        220.0F,
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(0.0F, 0.0F),
      ),
    ),
  )
  joints_despawn2_state.val = (0, Some(bob))
}

///|
fn rapier2d_joints_despawn2_tick(world : @ecs.World) -> Unit {
  let (ticks, entity) = joints_despawn2_state.val
  let next_ticks = ticks + 1
  joints_despawn2_state.val = (next_ticks, entity)
  if next_ticks == 240 {
    guard entity is Some(e) else { return }
    try! world.despawn(e)
    joints_despawn2_state.val = (next_ticks, None)
    println("[joints_despawn2] despawned the jointed body")
  }
}
