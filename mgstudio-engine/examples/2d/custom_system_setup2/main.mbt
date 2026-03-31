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
  let plugins = @mgstudio.DefaultPlugins::build()
    .disable("mgstudio::Physics2dPlugin")
    .build()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(@physics2d.physics2d_init_resources_system)
  .add_pre_update_system(@physics2d.physics2d_clear_events_system)
  .add_pre_update_system(@physics2d.physics2d_cleanup_despawned_system)
  .add_fixed_update_system(@physics2d.physics2d_sync_insertions_system)
  .add_fixed_update_system(@physics2d.physics2d_sync_joints_system)
  .add_fixed_update_system(@physics2d.physics2d_sync_world_to_rapier_system)
  .add_fixed_update_system(@physics2d.physics2d_character_controller_system)
  .add_fixed_update_system(@physics2d.physics2d_step_system)
  .add_fixed_update_system(@physics2d.physics2d_writeback_system)
  .add_post_update_system_param(@physics2d.physics2d_debug_render_system)
  .add_systems(@app.Startup, @app.system(rapier2d_custom_system_setup2_setup))
  .run()
}

///|
fn rapier2d_custom_system_setup2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.92F, 0.94F, 0.98F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) =>
      cfg_res.insert(current.with_gravity(@math.Vec2::new(0.0F, -500.0F)))
    None =>
      cfg_res.insert(
        @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -500.0F)),
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
      @physics2d.ColliderShape2d::cuboid(380.0F, 18.0F),
    ),
  )
  for i in 0..<6 {
    let box = world.spawn_empty()
    try! world.set_by_key(
      box,
      @transform.ecs_key_transform,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-220.0F + Float::from_int(i) * 88.0F, 100.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=1.0F,
      ),
    )
    try! world.set_by_key(
      box,
      @sprite.ecs_key_sprite,
      @sprite.Sprite::from_image(texture)
      .with_color(@sprite.Color::new(0.85F, 0.55F, 0.20F, 1.0F))
      .with_custom_size(Some(@math.Vec2::new(44.0F, 44.0F))),
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
        @physics2d.ColliderShape2d::cuboid(22.0F, 22.0F),
      ),
    )
  }
}
