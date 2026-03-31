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
priv struct ContactFilterState {
  left : @core.Entity?
  right : @core.Entity?
}

///|
let contact_filter_state : Ref[ContactFilterState] = Ref::new(ContactFilterState::{
  left: None,
  right: None,
})

///|
let contact_filter_enabled : Ref[Bool] = Ref::new(true)

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(rapier2d_contact_filter2_setup))
  .add_systems(@app.Update, @app.system(rapier2d_contact_filter2_toggle))
  .run()
}

///|
fn rapier2d_contact_filter2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.90F, 0.90F, 0.95F, 1.0F)),
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
      @math.Vec2::new(0.0F, -240.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
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
      @physics2d.ColliderShape2d::cuboid(380.0F, 18.0F),
    ),
  )
  let left = world.spawn_empty()
  try! world.set_by_key(
    left,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-180.0F, -40.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    left,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.95F, 0.35F, 0.35F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(36.0F, 36.0F))),
  )
  try! world.set_by_key(
    left,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    left,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(18.0F)),
  )
  let right = world.spawn_empty()
  try! world.set_by_key(
    right,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(180.0F, -40.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    right,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.35F, 0.35F, 0.95F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(36.0F, 36.0F))),
  )
  try! world.set_by_key(
    right,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    right,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(18.0F)),
  )
  try! world.set_by_key(
    left,
    @physics2d.ecs_key_active_hooks2d,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_contact_pairs(),
    ),
  )
  try! world.set_by_key(
    right,
    @physics2d.ecs_key_active_hooks2d,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_contact_pairs(),
    ),
  )
  contact_filter_state.val = ContactFilterState::{
    left: Some(left),
    right: Some(right),
  }
  @physics2d.physics2d_set_filter_contact_pair(world, fn(_, _, h1, h2) {
    if !contact_filter_enabled.val {
      return true
    }
    match
      (
        @physics2d.physics2d_hook_entity_from_collider_handle(h1),
        @physics2d.physics2d_hook_entity_from_collider_handle(h2),
      ) {
      (Some(e1), Some(e2)) => {
        guard contact_filter_state.val.left is Some(left) else { return true }
        guard contact_filter_state.val.right is Some(right) else { return true }
        !((
          e1.id == left.id &&
          e1.generation == left.generation &&
          e2.id == right.id &&
          e2.generation == right.generation
        ) ||
        (
          e1.id == right.id &&
          e1.generation == right.generation &&
          e2.id == left.id &&
          e2.generation == left.generation
        ))
      }
      _ => true
    }
  })
  println("[contact_filter2] press Space to toggle the contact filter")
}

///|
fn rapier2d_contact_filter2_toggle(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    contact_filter_enabled.val = !contact_filter_enabled.val
    println(
      "[contact_filter2] contact filter enabled=\{contact_filter_enabled.val}",
    )
  }
}
