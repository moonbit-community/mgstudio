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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(
    @app.FixedUpdate,
    @app.system(physics2d_showcase_player_controls_fixed),
  )
  .add_systems(@app.Startup, @app.system(physics2d_showcase_setup))
  .add_systems(@app.Update, @app.system(physics2d_showcase_spawn_ball_on_click))
  .add_systems(@app.Update, @app.system(physics2d_showcase_print_events))
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
let showcase_entities : Ref[ShowcaseEntities] = Ref(ShowcaseEntities::{
  player: None,
  sensor_zone: None,
  ghost_a: None,
  ghost_b: None,
})

///|
let showcase_ghost_nocollide_enabled : Ref[Bool] = Ref(true)

///|
fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn physics2d_showcase_spawn_controls_overlay() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let content = "Physics2D Showcase Controls\nW/A/S/D or Arrow Keys: Move player\nLeft Click: Spawn ball at cursor\nG: Toggle debug render\nH: Toggle ghost pair no-collision"
  let font_style = @text.TextFont::default()
    .with_font(font)
    .with_font_size(20.0F)
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    font_style,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-390.0F, 300.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@sprite.Anchor::top_left())
  .with_bounds(@text.TextBounds::new_horizontal(780.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .with_color(
    @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore
}

///|
fn physics2d_showcase_setup(world : @ecs.World) -> Unit {

  // Make gravity visible in "pixel-ish" space.
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current_cfg) => {
      let cfg = Ref(current_cfg)
      cfg.val = @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -800.0F))
      cfg_res.insert(cfg.val)
    }
    None => ()
  }

  // Enable debug gizmos by default.
  @physics2d.physics2d_debug_render_set_enabled(true)
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  // Camera.
  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @transform.Transform::identity()).spawn(
    world,
  )
  |> ignore
  physics2d_showcase_spawn_controls_overlay()

  // Static world bounds.
  let floor = world.spawn_empty()
  try! world.set_by_key(
    floor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -260.0F),
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
    .with_custom_size(Some(@math.Vec2::new(800.0F, 40.0F))),
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
      @physics2d.ColliderShape2d::cuboid(400.0F, 20.0F),
    ),
  )
  try! world.set_by_key(
    floor,
    @physics2d.ecs_key_friction2d,
    @physics2d.Friction2d::new(1.0F),
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

  // A sensor zone: only the player triggers it (via hooks intersection filtering).
  let sensor_zone = world.spawn_empty()
  try! world.set_by_key(
    sensor_zone,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -140.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    sensor_zone,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.0F, 0.8F, 0.9F, 0.35F))
    .with_custom_size(Some(@math.Vec2::new(260.0F, 120.0F))),
  )
  try! world.set_by_key(
    sensor_zone,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(130.0F, 60.0F),
    ).sensor(true),
  )
  try! world.set_by_key(
    sensor_zone,
    @physics2d.ecs_key_active_hooks2d,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_intersection_pair(),
    ),
  )

  // Player character controller (no rigid body, collider moved via KCC each fixed step).
  let player = world.spawn_empty()
  try! world.set_by_key(
    player,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -40.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=2.0F,
    ),
  )
  try! world.set_by_key(
    player,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(1.0F, 1.0F, 1.0F, 0.9F))
    .with_custom_size(Some(@math.Vec2::new(28.0F, 56.0F))),
  )
  try! world.set_by_key(
    player,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::capsule_y(14.0F, 14.0F),
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
  try! world.set_by_key(
    player,
    @physics2d.ecs_key_active_hooks2d,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_intersection_pair(),
    ),
  )

  // A stack of boxes with different restitution.
  for i in 0..<6 {
    let i_f = Float::from_int(i)
    let x = -220.0F + i_f * 90.0F
    let y = -180.0F + i_f * 45.0F
    let box = world.spawn_empty()
    try! world.set_by_key(
      box,
      @transform.ecs_key_transform,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(x, y),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=1.0F,
      ),
    )
    try! world.set_by_key(
      box,
      @sprite.ecs_key_sprite,
      @sprite.Sprite::from_image(texture)
      .with_color(@sprite.Color::new(0.9F, 0.6F, 0.2F, 1.0F))
      .with_custom_size(Some(@math.Vec2::new(56.0F, 56.0F))),
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
        @physics2d.ColliderShape2d::cuboid(28.0F, 28.0F),
      ),
    )
    try! world.set_by_key(
      box,
      @physics2d.ecs_key_friction2d,
      @physics2d.Friction2d::new(0.8F),
    )
    let r = if i % 2 == 0 { 0.0F } else { 0.8F }
    try! world.set_by_key(
      box,
      @physics2d.ecs_key_restitution2d,
      @physics2d.Restitution2d::new(r),
    )
  }

  // Rope joint pendulum.
  let anchor = world.spawn_empty()
  try! world.set_by_key(
    anchor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(260.0F, 220.0F),
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
      @math.Vec2::new(260.0F, 120.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    bob,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.8F, 0.2F, 0.9F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(32.0F, 32.0F))),
  )
  try! world.set_by_key(
    bob,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    bob,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(16.0F)),
  )
  try! world.set_by_key(
    bob,
    @physics2d.ecs_key_impulse_joint2d,
    @physics2d.ImpulseJoint2d::new(
      anchor,
      @physics2d.joint2d_rope(
        120.0F,
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(0.0F, 0.0F),
      ),
    ),
  )

  // A "ghost" ball pair: hooks can disable contacts for this specific pair.
  let ghost_a = world.spawn_empty()
  try! world.set_by_key(
    ghost_a,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-260.0F, 160.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    ghost_a,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.2F, 0.9F, 0.2F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F))),
  )
  try! world.set_by_key(
    ghost_a,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    ghost_a,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(14.0F)),
  )
  try! world.set_by_key(
    ghost_a,
    @physics2d.ecs_key_velocity2d,
    @physics2d.Velocity2d::new(@math.Vec2::new(280.0F, 0.0F), 0.0F),
  )
  try! world.set_by_key(
    ghost_a,
    @physics2d.ecs_key_active_hooks2d,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_contact_pairs(),
    ),
  )
  let ghost_b = world.spawn_empty()
  try! world.set_by_key(
    ghost_b,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(260.0F, 160.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    ghost_b,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.2F, 0.3F, 1.0F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F))),
  )
  try! world.set_by_key(
    ghost_b,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    ghost_b,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(14.0F)),
  )
  try! world.set_by_key(
    ghost_b,
    @physics2d.ecs_key_velocity2d,
    @physics2d.Velocity2d::new(@math.Vec2::new(-280.0F, 0.0F), 0.0F),
  )
  try! world.set_by_key(
    ghost_b,
    @physics2d.ecs_key_active_hooks2d,
    @physics2d.ActiveHooks2d::new(
      @collision.ActiveHooks::filter_contact_pairs(),
    ),
  )
  @physics2d.physics2d_set_filter_contact_pair(world, fn(_, _, h1, h2) {
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
  @physics2d.physics2d_set_filter_intersection_pair(world, fn(_, _, h1, h2) {
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
fn physics2d_showcase_player_controls_fixed(world : @ecs.World) -> Unit {
  let dt = @time.time_fixed_timestep_seconds()
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
  let speed = 320.0F
  let delta = @math.Vec2::new(axis.x * speed * dt, axis.y * speed * dt)
  let next = kcc.reset_translation().add_translation(delta)
  try! (world.replace(
    player, @physics2d.ecs_key_kinematic_character_controller2d, next,
  )
  |> ignore)
}

///|
fn physics2d_showcase_spawn_ball_on_click(world : @ecs.World) -> Unit {
  if !@input.mouse_button_just_pressed(@window.MouseButton::Left) {
    return
  }
  guard @input.mouse_position() is Some(screen_pos) else { return }
  guard @sprite_render.render2d_viewport_to_world_2d(world, screen_pos)
    is Some(p) else {
    return
  }
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let ball = world.spawn_empty()
  try! world.set_by_key(
    ball,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(p.x, p.y),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=3.0F,
    ),
  )
  try! world.set_by_key(
    ball,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(1.0F, 0.2F, 0.2F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(24.0F, 24.0F))),
  )
  try! world.set_by_key(
    ball,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    ball,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(12.0F)),
  )
  try! world.set_by_key(
    ball,
    @physics2d.ecs_key_velocity2d,
    @physics2d.Velocity2d::new(@math.Vec2::new(0.0F, -80.0F), 0.0F),
  )
  println("[physics2d_showcase] spawned ball at (\{p.x}, \{p.y})")
}

///|
fn physics2d_showcase_print_events(world : @ecs.World) -> Unit {
  let ev_res = @physics2d.get_physics2d_events_resource(world)
  guard ev_res.get() is Some(events) else { return }
  for ev in events.collisions {
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
