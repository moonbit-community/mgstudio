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
priv struct PlayerMovementState {
  player : @core.Entity?
}

///|
let player_movement_state : Ref[PlayerMovementState] = Ref::new(PlayerMovementState::{
  player: None,
})

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(rapier2d_player_movement2_setup))
  .add_systems(@app.FixedUpdate, @app.system(rapier2d_player_movement2_fixed))
  .run()
}

///|
fn rapier2d_player_movement2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.75F, 0.82F, 0.65F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) =>
      cfg_res.insert(current.with_gravity(@math.Vec2::new(0.0F, 0.0F)))
    None =>
      cfg_res.insert(
        @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F)),
      )
  }
  let floor = world.spawn_empty()
  try! world.set_by_key(
    floor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -180.0F),
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
      @physics2d.ColliderShape2d::cuboid(390.0F, 18.0F),
    ),
  )
  let player = world.spawn_empty()
  try! world.set_by_key(
    player,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -120.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    player,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(30.0F, 60.0F))),
  )
  try! world.set_by_key(
    player,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::capsule_y(15.0F, 15.0F),
    ),
  )
  try! world.set_by_key(
    player,
    @physics2d.ecs_key_kinematic_character_controller2d,
    @physics2d.KinematicCharacterController2d::default(),
  )
  try! world.set_by_key(
    player,
    @physics2d.ecs_key_kinematic_character_controller_output2d,
    @physics2d.KinematicCharacterControllerOutput2d::new(),
  )
  player_movement_state.val = PlayerMovementState::{ player: Some(player) }
}

///|
fn rapier2d_player_movement2_fixed(world : @ecs.World) -> Unit {
  guard player_movement_state.val.player is Some(player) else { return }
  guard (try! world.get_by_key(
      player, @physics2d.ecs_key_kinematic_character_controller2d,
    ))
    is Some(kcc) else {
    return
  }
  let mut axis = @math.Vec2::new(0.0F, 0.0F)
  if @input.key_pressed(@window.KeyCode::KeyA) ||
    @input.key_pressed(@window.KeyCode::ArrowLeft) {
    axis = @math.Vec2::new(axis.x - 1.0F, axis.y)
  }
  if @input.key_pressed(@window.KeyCode::KeyD) ||
    @input.key_pressed(@window.KeyCode::ArrowRight) {
    axis = @math.Vec2::new(axis.x + 1.0F, axis.y)
  }
  if @input.key_pressed(@window.KeyCode::KeyW) ||
    @input.key_pressed(@window.KeyCode::ArrowUp) {
    axis = @math.Vec2::new(axis.x, axis.y + 1.0F)
  }
  if @input.key_pressed(@window.KeyCode::KeyS) ||
    @input.key_pressed(@window.KeyCode::ArrowDown) {
    axis = @math.Vec2::new(axis.x, axis.y - 1.0F)
  }
  let dt = @time.time_fixed_timestep_seconds()
  let delta = @math.Vec2::new(axis.x * 240.0F * dt, axis.y * 240.0F * dt)
  let next = kcc.reset_translation().add_translation(delta)
  try! (world.replace(
    player, @physics2d.ecs_key_kinematic_character_controller2d, next,
  )
  |> ignore)
}
