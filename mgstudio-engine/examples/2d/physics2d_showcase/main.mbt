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
/// Physics2D showcase:
/// - Dynamic bodies (stacking, friction/restitution).
/// - Joints (rope pendulum).
/// - Sensors + intersection events.
/// - Bevy-style hooks via global physics hooks (contact + intersection filtering).
/// - Kinematic character controller (WASD movement).
///
/// Controls:
/// - WASD: move the character controller.
/// - Left click: spawn a ball at cursor.
/// - G: toggle physics debug rendering.
/// - H: toggle the "no-collision" hook for a specific ball pair.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_fixed_update_system(physics2d_showcase_player_controls_fixed)
  .add_plugins(plugins)
  .add_startup_system(physics2d_showcase_setup)
  .add_system(physics2d_showcase_spawn_ball_on_click)
  .add_system(physics2d_showcase_print_events)
  .run()
}

///|
priv struct ShowcaseEntities {
  player : @core.Entity?
  sensor_zone : @core.Entity?
  ghost_a : @core.Entity?
  ghost_b : @core.Entity?
}

///|
let showcase_entities : Ref[ShowcaseEntities] = Ref::new(ShowcaseEntities::{
  player: None,
  sensor_zone: None,
  ghost_a: None,
  ghost_b: None,
})

///|
let showcase_ghost_nocollide_enabled : Ref[Bool] = Ref::new(true)

///|
fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn physics2d_showcase_setup(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)

  // Make gravity visible in "pixel-ish" space.
  let cfg_res = @physics2d.HasRes_Physics2dConfig::get_physics2d_config_resource(
    world,
  )
  match cfg_res.get_ref_mut(tick) {
    Some(r) =>
      r.val = @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -800.0F))
    None => ()
  }

  // Enable debug gizmos by default.
  @physics2d.physics2d_debug_render_set_enabled(true)
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  // Camera.
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let rb_store = @physics2d.Has_RigidBody2d::get_rigid_body2d_store(world)
  let col_store = @physics2d.Has_Collider2d::get_collider2d_store(world)
  let vel_store = @physics2d.Has_Velocity2d::get_velocity2d_store(world)
  let friction_store = @physics2d.Has_Friction2d::get_friction2d_store(world)
  let restitution_store = @physics2d.Has_Restitution2d::get_restitution2d_store(
    world,
  )
  let active_hooks_store = @physics2d.Has_ActiveHooks2d::get_active_hooks2d_store(
    world,
  )
  let kcc_store = @physics2d.Has_KinematicCharacterController2d::get_kinematic_character_controller2d_store(
    world,
  )
  let kcc_out_store = @physics2d.Has_KinematicCharacterControllerOutput2d::get_kinematic_character_controller_output2d_store(
    world,
  )
  let impulse_joint_store = @physics2d.Has_ImpulseJoint2d::get_impulse_joint2d_store(
    world,
  )

  // Static world bounds.
  let floor = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    floor,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -260.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  sprite_store.insert(
    floor,
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(0.25F, 0.25F, 0.25F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(800.0F, 40.0F))),
    tick,
  )
  rb_store.insert(floor, @physics2d.RigidBody2d::fixed(), tick)
  col_store.insert(
    floor,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(400.0F, 20.0F),
    ),
    tick,
  )
  friction_store.insert(floor, @physics2d.Friction2d::new(1.0F), tick)
  let left_wall = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    left_wall,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-410.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  rb_store.insert(left_wall, @physics2d.RigidBody2d::fixed(), tick)
  col_store.insert(
    left_wall,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(20.0F, 400.0F),
    ),
    tick,
  )
  let right_wall = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    right_wall,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(410.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  rb_store.insert(right_wall, @physics2d.RigidBody2d::fixed(), tick)
  col_store.insert(
    right_wall,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(20.0F, 400.0F),
    ),
    tick,
  )

  // A sensor zone: only the player triggers it (via hooks intersection filtering).
  let sensor_zone = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    sensor_zone,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -140.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  sprite_store.insert(
    sensor_zone,
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(0.0F, 0.8F, 0.9F, 0.35F))
    .with_custom_size(Some(@math.Vec2::new(260.0F, 120.0F))),
    tick,
  )
  col_store.insert(
    sensor_zone,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(130.0F, 60.0F),
    ).sensor(true),
    tick,
  )
  active_hooks_store.insert(
    sensor_zone,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_intersection_pair(),
    ),
    tick,
  )

  // Player character controller (no rigid body, collider moved via KCC each fixed step).
  let player = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    player,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -40.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=2.0F,
    ),
    tick,
  )
  sprite_store.insert(
    player,
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(1.0F, 1.0F, 1.0F, 0.9F))
    .with_custom_size(Some(@math.Vec2::new(28.0F, 56.0F))),
    tick,
  )
  col_store.insert(
    player,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::capsule_y(14.0F, 14.0F),
    ),
    tick,
  )
  kcc_store.insert(
    player,
    @physics2d.KinematicCharacterController2d::default(),
    tick,
  )
  kcc_out_store.insert(
    player,
    @physics2d.KinematicCharacterControllerOutput2d::new(),
    tick,
  )
  active_hooks_store.insert(
    player,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_intersection_pair(),
    ),
    tick,
  )

  // A stack of boxes with different restitution.
  for i in 0..<6 {
    let i_f = Float::from_int(i)
    let x = -220.0F + i_f * 90.0F
    let y = -180.0F + i_f * 45.0F
    let box = @core.SpawnWorld::spawn_empty(world)
    transform_store.insert(
      box,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(x, y),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=1.0F,
      ),
      tick,
    )
    sprite_store.insert(
      box,
      @render2d.Sprite::from_image(texture)
      .with_color(@render2d.Color::new(0.9F, 0.6F, 0.2F, 1.0F))
      .with_custom_size(Some(@math.Vec2::new(56.0F, 56.0F))),
      tick,
    )
    rb_store.insert(box, @physics2d.RigidBody2d::dynamic(), tick)
    col_store.insert(
      box,
      @physics2d.Collider2d::new(
        @physics2d.ColliderShape2d::cuboid(28.0F, 28.0F),
      ),
      tick,
    )
    friction_store.insert(box, @physics2d.Friction2d::new(0.8F), tick)
    let r = if i % 2 == 0 { 0.0F } else { 0.8F }
    restitution_store.insert(box, @physics2d.Restitution2d::new(r), tick)
  }

  // Rope joint pendulum.
  let anchor = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    anchor,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(260.0F, 220.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  rb_store.insert(anchor, @physics2d.RigidBody2d::fixed(), tick)
  col_store.insert(
    anchor,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(6.0F)),
    tick,
  )
  let bob = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    bob,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(260.0F, 120.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
    tick,
  )
  sprite_store.insert(
    bob,
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(0.8F, 0.2F, 0.9F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(32.0F, 32.0F))),
    tick,
  )
  rb_store.insert(bob, @physics2d.RigidBody2d::dynamic(), tick)
  col_store.insert(
    bob,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(16.0F)),
    tick,
  )
  impulse_joint_store.insert(
    bob,
    @physics2d.ImpulseJoint2d::new(
      anchor,
      @physics2d.joint2d_rope(
        120.0F,
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(0.0F, 0.0F),
      ),
    ),
    tick,
  )

  // A "ghost" ball pair: hooks can disable contacts for this specific pair.
  let ghost_a = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    ghost_a,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-260.0F, 160.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
    tick,
  )
  sprite_store.insert(
    ghost_a,
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(0.2F, 0.9F, 0.2F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F))),
    tick,
  )
  rb_store.insert(ghost_a, @physics2d.RigidBody2d::dynamic(), tick)
  col_store.insert(
    ghost_a,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(14.0F)),
    tick,
  )
  vel_store.insert(
    ghost_a,
    @physics2d.Velocity2d::new(@math.Vec2::new(280.0F, 0.0F), 0.0F),
    tick,
  )
  active_hooks_store.insert(
    ghost_a,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_contact_pairs(),
    ),
    tick,
  )
  let ghost_b = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    ghost_b,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(260.0F, 160.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
    tick,
  )
  sprite_store.insert(
    ghost_b,
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(0.2F, 0.3F, 1.0F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F))),
    tick,
  )
  rb_store.insert(ghost_b, @physics2d.RigidBody2d::dynamic(), tick)
  col_store.insert(
    ghost_b,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(14.0F)),
    tick,
  )
  vel_store.insert(
    ghost_b,
    @physics2d.Velocity2d::new(@math.Vec2::new(-280.0F, 0.0F), 0.0F),
    tick,
  )
  active_hooks_store.insert(
    ghost_b,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_contact_pairs(),
    ),
    tick,
  )
  @physics2d.physics2d_set_filter_contact_pair(fn(_, _, h1, h2) {
    if !showcase_ghost_nocollide_enabled.val {
      return true
    }
    match
      (
        @physics2d.physics2d_hook_entity_from_collider_handle(h1),
        @physics2d.physics2d_hook_entity_from_collider_handle(h2),
      ) {
      (Some(e1), Some(e2)) =>
        match (showcase_entities.val.ghost_a, showcase_entities.val.ghost_b) {
          (Some(a), Some(b)) =>
            !((entity_eq(e1, a) && entity_eq(e2, b)) ||
            (entity_eq(e1, b) && entity_eq(e2, a)))
          _ => true
        }
      _ => true
    }
  })
  @physics2d.physics2d_set_filter_intersection_pair(fn(_, _, h1, h2) {
    match
      (
        @physics2d.physics2d_hook_entity_from_collider_handle(h1),
        @physics2d.physics2d_hook_entity_from_collider_handle(h2),
      ) {
      (Some(e1), Some(e2)) =>
        match
          (showcase_entities.val.player, showcase_entities.val.sensor_zone) {
          (Some(player), Some(sensor)) =>
            if entity_eq(e1, sensor) {
              entity_eq(e2, player)
            } else if entity_eq(e2, sensor) {
              entity_eq(e1, player)
            } else {
              true
            }
          _ => true
        }
      _ => true
    }
  })
  showcase_entities.val = ShowcaseEntities::{
    player: Some(player),
    sensor_zone: Some(sensor_zone),
    ghost_a: Some(ghost_a),
    ghost_b: Some(ghost_b),
  }
  println(
    "[physics2d_showcase] WASD move, click spawn ball, G debug, H toggle ghost pair no-collision",
  )
}

///|
fn physics2d_showcase_player_controls_fixed(world : @ecs_world.World) -> Unit {
  let dt = @app.fixed_time_timestep_seconds()
  if @input.key_just_pressed(@window.KeyCode::KeyG) {
    let enabled = @physics2d.physics2d_debug_render_config().enabled
    @physics2d.physics2d_debug_render_set_enabled(!enabled)
    println("[physics2d_showcase] debug_render enabled=\{!enabled}")
  }
  if @input.key_just_pressed(@window.KeyCode::KeyH) {
    showcase_ghost_nocollide_enabled.val = !showcase_ghost_nocollide_enabled.val
    println(
      "[physics2d_showcase] ghost_pair no-collision enabled=\{showcase_ghost_nocollide_enabled.val}",
    )
  }
  guard showcase_entities.val.player is Some(player) else { return }
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let kcc_store = @physics2d.Has_KinematicCharacterController2d::get_kinematic_character_controller2d_store(
    world,
  )
  guard kcc_store.get(player) is Some(kcc) else { return }
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
  let speed = 320.0F
  let delta = @math.Vec2::new(axis.x * speed * dt, axis.y * speed * dt)
  let next = kcc.reset_translation().add_translation(delta)
  kcc_store.set(player, next, tick) |> ignore
}

///|
fn physics2d_showcase_spawn_ball_on_click(world : @ecs_world.World) -> Unit {
  if !@input.mouse_button_just_pressed(@window.MouseButton::Left) {
    return
  }
  guard @input.mouse_position() is Some(screen_pos) else { return }
  guard @render2d.render2d_viewport_to_world_2d(world, screen_pos) is Some(p) else {
    return
  }
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let sprite_store = @render2d.Has_Sprite::get_sprite_store(world)
  let rb_store = @physics2d.Has_RigidBody2d::get_rigid_body2d_store(world)
  let col_store = @physics2d.Has_Collider2d::get_collider2d_store(world)
  let vel_store = @physics2d.Has_Velocity2d::get_velocity2d_store(world)
  let ball = @core.SpawnWorld::spawn_empty(world)
  transform_store.insert(
    ball,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(p.x, p.y),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=3.0F,
    ),
    tick,
  )
  sprite_store.insert(
    ball,
    @render2d.Sprite::from_image(texture)
    .with_color(@render2d.Color::new(1.0F, 0.2F, 0.2F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(24.0F, 24.0F))),
    tick,
  )
  rb_store.insert(ball, @physics2d.RigidBody2d::dynamic(), tick)
  col_store.insert(
    ball,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(12.0F)),
    tick,
  )
  vel_store.insert(
    ball,
    @physics2d.Velocity2d::new(@math.Vec2::new(0.0F, -80.0F), 0.0F),
    tick,
  )
  println("[physics2d_showcase] spawned ball at (\{p.x}, \{p.y})")
}

///|
fn physics2d_showcase_print_events(world : @ecs_world.World) -> Unit {
  let ev_res = @physics2d.HasRes_Physics2dEvents::get_physics2d_events_resource(
    world,
  )
  guard ev_res.get_ref() is Some(r) else { return }
  for ev in r.val.collisions {
    match ev {
      @physics2d.CollisionEvent2d::Started(a, b, sensor) =>
        if sensor {
          println("[physics2d_showcase] sensor started: \{a.id} <-> \{b.id}")
        }
      @physics2d.CollisionEvent2d::Stopped(a, b, sensor) =>
        if sensor {
          println("[physics2d_showcase] sensor stopped: \{a.id} <-> \{b.id}")
        }
    }
  }
}
