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
let debug_toggle_state : Ref[Bool] = Ref(true)

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(rapier2d_debug_toggle2_setup))
  .add_systems(@app.Update, @app.system(rapier2d_debug_toggle2_update))
  .run()
}

///|
fn rapier2d_debug_toggle2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.62F, 0.76F, 0.55F, 1.0F)),
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
      @physics2d.ColliderShape2d::cuboid(390.0F, 20.0F),
    ),
  )
  for i in 0..<8 {
    for j in 0..<4 {
      let box = world.spawn_empty()
      try! world.set_by_key(
        box,
        @transform.ecs_key_transform,
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(
            -220.0F + Float::from_int(i) * 62.0F,
            -120.0F + Float::from_int(j) * 62.0F,
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
        .with_color(@sprite.Color::new(0.95F, 0.78F, 0.28F, 1.0F))
        .with_custom_size(Some(@math.Vec2::new(36.0F, 36.0F))),
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
          @physics2d.ColliderShape2d::cuboid(18.0F, 18.0F),
        ),
      )
    }
  }
  @physics2d.physics2d_debug_render_set_enabled(debug_toggle_state.val)
}

///|
fn rapier2d_debug_toggle2_update(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyV) {
    debug_toggle_state.val = !debug_toggle_state.val
    @physics2d.physics2d_debug_render_set_enabled(debug_toggle_state.val)
    println("[debug_toggle2] debug render enabled=\{debug_toggle_state.val}")
  }
}
