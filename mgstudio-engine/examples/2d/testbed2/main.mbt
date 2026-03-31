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
priv struct TestbedState {
  spawned : Array[@core.Entity]
}

///|
let testbed_state : Ref[TestbedState] = Ref::new(TestbedState::{ spawned: [] })

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(rapier2d_testbed2_setup))
  .add_systems(@app.Update, @app.system(rapier2d_testbed2_update))
  .run()
}

///|
fn rapier2d_testbed2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.90F, 0.90F, 0.92F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  testbed_state.val = TestbedState::{ spawned: [] }
  rapier2d_testbed2_spawn_mode(world, texture, 0)
}

///|
fn rapier2d_testbed2_clear(world : @ecs.World) -> Unit {
  for e in testbed_state.val.spawned {
    try! world.despawn(e)
  }
  testbed_state.val.spawned.clear()
}

///|
fn rapier2d_testbed2_spawn_mode(
  world : @ecs.World,
  texture : @asset.Handle[@image.Image],
  mode : Int,
) -> Unit {
  rapier2d_testbed2_clear(world)
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) =>
      cfg_res.insert(current.with_gravity(@math.Vec2::new(0.0F, -600.0F)))
    None =>
      cfg_res.insert(
        @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -600.0F)),
      )
  }
  match mode {
    0 => {
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
          @physics2d.ColliderShape2d::cuboid(390.0F, 18.0F),
        ),
      )
      testbed_state.val.spawned.push(floor)
      for i in 0..<6 {
        let box = world.spawn_empty()
        try! world.set_by_key(
          box,
          @transform.ecs_key_transform,
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(
              -200.0F + Float::from_int(i) * 80.0F,
              -60.0F + Float::from_int(i) * 30.0F,
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
          .with_color(@sprite.Color::new(0.90F, 0.65F, 0.25F, 1.0F))
          .with_custom_size(Some(@math.Vec2::new(40.0F, 40.0F))),
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
            @physics2d.ColliderShape2d::cuboid(20.0F, 20.0F),
          ),
        )
        testbed_state.val.spawned.push(box)
      }
    }
    1 => {
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
      testbed_state.val.spawned.push(anchor)
      let bob = world.spawn_empty()
      try! world.set_by_key(
        bob,
        @transform.ecs_key_transform,
        @transform.Transform::from_xy_rotation_scale(
          @math.Vec2::new(160.0F, 40.0F),
          0.0F,
          @math.Vec2::new(1.0F, 1.0F),
          z=1.0F,
        ),
      )
      try! world.set_by_key(
        bob,
        @sprite.ecs_key_sprite,
        @sprite.Sprite::from_image(texture)
        .with_color(@sprite.Color::new(0.95F, 0.55F, 0.20F, 1.0F))
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
      testbed_state.val.spawned.push(bob)
    }
    _ => {
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
      testbed_state.val.spawned.push(player)
    }
  }
  println("[testbed2] mode=\{mode}")
}

///|
fn rapier2d_testbed2_update(world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    rapier2d_testbed2_spawn_mode(
      world,
      @asset.AssetServer::new().load("branding/icon.png"),
      0,
    )
  } else if @input.key_just_pressed(@window.KeyCode::Digit2) {
    rapier2d_testbed2_spawn_mode(
      world,
      @asset.AssetServer::new().load("branding/icon.png"),
      1,
    )
  } else if @input.key_just_pressed(@window.KeyCode::Digit3) {
    rapier2d_testbed2_spawn_mode(
      world,
      @asset.AssetServer::new().load("branding/icon.png"),
      2,
    )
  }
}
