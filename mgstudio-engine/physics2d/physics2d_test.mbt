// Copyright 2026 International Digital Economy Academy
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
fn approx_eq_f32(a : Float, b : Float) -> Bool {
  let diff = if a >= b { a - b } else { b - a }
  diff < 0.0001F
}

///|
fn configure_fixed_time(world : @ecs.World, timestep_seconds : Float) -> Unit {
  world.insert_resource(
    @time.fixed_time_resource_key(),
    @time.Time::from_seconds(timestep_seconds),
  )
}

///|
let ecs_key_transform : @ecs.ComponentKey[@transform.Transform] = @transform.ecs_key_transform

///|
test "physics2d: falling body collides and writes back transform" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  // Make the test converge quickly.
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, -200.0F))
  cfg_res.insert(cfg.val)
  let floor = world.spawn()
  let ball = world.spawn()

  // Floor at y = -1 with half-height 0.5 => top at y = -0.5.
  try! world.set_by_key(
    floor,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(floor, ecs_key_rigid_body2d, RigidBody2d::fixed())
  try! world.set_by_key(
    floor,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
  )
  try! world.set_by_key(
    floor,
    ecs_key_contact_force_event_threshold2d,
    ContactForceEventThreshold2d::new(0.0F),
  )
  try! world.set_by_key(
    ball,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 5.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(ball, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    ball,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    ball,
    ecs_key_contact_force_event_threshold2d,
    ContactForceEventThreshold2d::new(0.0F),
  )
  try! world.set_by_key(ball, ecs_key_velocity2d, Velocity2d::zero())
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  let initial_y = try! world.get_by_key(ball, ecs_key_transform).unwrap().translation.y

  // Step for ~2 seconds.
  let mut i = 0
  while i < 120 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.advance_sequence() |> ignore
    i = i + 1
  }
  let final_y = try! world.get_by_key(ball, ecs_key_transform).unwrap().translation.y
  debug_inspect(final_y < initial_y, content="true")
  let events = get_physics2d_events_resource(world).get().unwrap()
  debug_inspect(events.collisions.length() > 0, content="true")
  debug_inspect(events.contact_forces.length() > 0, content="true")
}

///|
test "physics2d: gravity scale 0 disables gravity" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, -100.0F))
  cfg_res.insert(cfg.val)
  let no_grav = world.spawn()
  let grav = world.spawn()
  try! world.set_by_key(
    no_grav,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    grav,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(no_grav, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(grav, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    no_grav,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(
    grav,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(
    no_grav,
    ecs_key_gravity_scale2d,
    GravityScale2d::new(0.0F),
  )
  try! world.set_by_key(no_grav, ecs_key_velocity2d, Velocity2d::zero())
  try! world.set_by_key(grav, ecs_key_velocity2d, Velocity2d::zero())
  physics2d_sync_insertions_system(world)
  let y0 = try! world.get_by_key(no_grav, ecs_key_transform).unwrap().translation.y
  let y1 = try! world.get_by_key(grav, ecs_key_transform).unwrap().translation.y
  let mut i = 0
  while i < 60 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.advance_sequence() |> ignore
    i = i + 1
  }
  // Debug (kept): this test asserts semantics via positions; keep the following
  // assertions focused and avoid relying on exact floating-point equality.
  let y0_final = try! world.get_by_key(no_grav, ecs_key_transform).unwrap().translation.y
  let y1_final = try! world.get_by_key(grav, ecs_key_transform).unwrap().translation.y
  debug_inspect(y0_final > y0 - 0.01F, content="true")
  debug_inspect(y1_final < y1, content="true")
}

///|
test "physics2d: damping reduces velocity" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let no_damp = world.spawn()
  let damp = world.spawn()
  for e in [no_damp, damp] {
    try! world.set_by_key(
      e,
      ecs_key_transform,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
    )
    try! world.set_by_key(e, ecs_key_rigid_body2d, RigidBody2d::dynamic())
    try! world.set_by_key(
      e,
      ecs_key_collider2d,
      Collider2d::new(ColliderShape2d::ball(0.2F)),
    )
    try! world.set_by_key(
      e,
      ecs_key_velocity2d,
      Velocity2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
    )
  }
  try! world.set_by_key(damp, ecs_key_damping2d, Damping2d::new(10.0F, 0.0F))
  physics2d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.advance_sequence() |> ignore
    i = i + 1
  }
  let v_no = try! world.get_by_key(no_damp, ecs_key_velocity2d).unwrap().linvel.x
  let v_damp = try! world.get_by_key(damp, ecs_key_velocity2d).unwrap().linvel.x
  debug_inspect(v_damp < v_no, content="true")
}

///|
test "physics2d: external impulse applies once and clears" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let e = world.spawn()
  try! world.set_by_key(
    e,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(e, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    e,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(e, ecs_key_velocity2d, Velocity2d::zero())
  try! world.set_by_key(
    e,
    ecs_key_external_impulse2d,
    ExternalImpulse2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let v = try! world.get_by_key(e, ecs_key_velocity2d).unwrap()
  debug_inspect(v.linvel.x > 0.0F, content="true")
  let imp = try! world.get_by_key(e, ecs_key_external_impulse2d).unwrap()
  debug_inspect(imp.impulse.x == 0.0F, content="true")
}

///|
test "physics2d: default collider density yields non-zero mass" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let e = world.spawn()
  try! world.set_by_key(
    e,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(e, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  // No `ColliderDensity2d` here: this test asserts moon_rapier's default density
  // behaves like upstream Rapier (non-zero mass).
  try! world.set_by_key(
    e,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(e, ecs_key_velocity2d, Velocity2d::zero())
  try! world.set_by_key(
    e,
    ecs_key_external_impulse2d,
    ExternalImpulse2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let bh = try! world.get_by_key(e, ecs_key_rapier_body_handle2d).unwrap().handle
  debug_inspect(
    ctx.rigid_bodies.get(bh).unwrap().inv_mass() > 0.0F,
    content="true",
  )
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let v = try! world.get_by_key(e, ecs_key_velocity2d).unwrap()
  debug_inspect(v.linvel.x > 0.0F, content="true")
}

///|
test "physics2d: external force persists" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let e = world.spawn()
  try! world.set_by_key(
    e,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(e, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    e,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(e, ecs_key_velocity2d, Velocity2d::zero())
  try! world.set_by_key(
    e,
    ecs_key_external_force2d,
    ExternalForce2d::new(@math.Vec2::new(50.0F, 0.0F), 0.0F),
  )
  physics2d_sync_insertions_system(world)
  let x0 = try! world.get_by_key(e, ecs_key_transform).unwrap().translation.x
  let mut i = 0
  while i < 30 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.advance_sequence() |> ignore
    i = i + 1
  }
  let x1 = try! world.get_by_key(e, ecs_key_transform).unwrap().translation.x
  debug_inspect(x1 > x0, content="true")
}

///|
test "physics2d: CCD prevents tunneling through thin floor" {
  fn run(ccd_enabled : Bool) -> Float {
    let world = @ecs.World::new()
    configure_fixed_time(world, 1.0F / 10.0F)
    physics2d_init_resources_system(world)
    let cfg_res = get_physics2d_config_resource(world)
    let cfg = Ref(cfg_res.get().unwrap())
    cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
    cfg_res.insert(cfg.val)
    let floor = world.spawn()
    let ball = world.spawn()
    try! world.set_by_key(
      floor,
      ecs_key_transform,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
    )
    try! world.set_by_key(floor, ecs_key_rigid_body2d, RigidBody2d::fixed())
    try! world.set_by_key(
      floor,
      ecs_key_collider2d,
      Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.01F)),
    )
    try! world.set_by_key(
      ball,
      ecs_key_transform,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 1.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
    )
    try! world.set_by_key(ball, ecs_key_rigid_body2d, RigidBody2d::dynamic())
    try! world.set_by_key(
      ball,
      ecs_key_collider2d,
      Collider2d::new(ColliderShape2d::ball(0.01F)),
    )
    try! world.set_by_key(
      ball,
      ecs_key_velocity2d,
      Velocity2d::new(@math.Vec2::new(0.0F, -200.0F), 0.0F),
    )
    if ccd_enabled {
      try! world.set_by_key(ball, ecs_key_ccd2d, Ccd2d::enabled())
    }
    physics2d_sync_insertions_system(world)
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    try! world.get_by_key(ball, ecs_key_transform).unwrap().translation.y
  }

  let y_no_ccd = run(false)
  let y_ccd = run(true)
  debug_inspect(y_no_ccd < -0.5F, content="true")
  debug_inspect(y_ccd > -0.5F, content="true")
}

///|
test "physics2d: collision groups filter collision events" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let a = world.spawn()
  let b = world.spawn()
  for e in [a, b] {
    try! world.set_by_key(
      e,
      ecs_key_transform,
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
    )
    try! world.set_by_key(e, ecs_key_rigid_body2d, RigidBody2d::dynamic())
    try! world.set_by_key(
      e,
      ecs_key_collider2d,
      Collider2d::new(ColliderShape2d::ball(0.5F)),
    )
    try! world.set_by_key(e, ecs_key_velocity2d, Velocity2d::zero())
  }
  // Put them in disjoint groups so they never collide.
  try! world.set_by_key(
    a,
    ecs_key_collision_groups2d,
    CollisionGroups2d::new(1, 1, @dynamics.InteractionTestMode::And),
  )
  try! world.set_by_key(
    b,
    ecs_key_collision_groups2d,
    CollisionGroups2d::new(2, 2, @dynamics.InteractionTestMode::And),
  )
  try! world.set_by_key(
    a,
    ecs_key_solver_groups2d,
    SolverGroups2d::new(1, 1, @dynamics.InteractionTestMode::And),
  )
  try! world.set_by_key(
    b,
    ecs_key_solver_groups2d,
    SolverGroups2d::new(2, 2, @dynamics.InteractionTestMode::And),
  )
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let events = get_physics2d_events_resource(world).get().unwrap()
  debug_inspect(events.collisions.length() == 0, content="true")
}

///|
test "physics2d: collider material and active event properties sync to rapier" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let e_default = world.spawn()
  try! world.set_by_key(
    e_default,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(e_default, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    e_default,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    e_default,
    ecs_key_collider_density2d,
    ColliderDensity2d::new(2.5F),
  )
  try! world.set_by_key(e_default, ecs_key_friction2d, Friction2d::new(0.25F))
  try! world.set_by_key(
    e_default,
    ecs_key_restitution2d,
    Restitution2d::new(0.75F),
  )
  try! world.set_by_key(
    e_default,
    ecs_key_contact_force_event_threshold2d,
    ContactForceEventThreshold2d::new(0.125F),
  )

  let e_override = world.spawn()
  try! world.set_by_key(
    e_override,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    e_override,
    ecs_key_rigid_body2d,
    RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    e_override,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    e_override,
    ecs_key_active_events2d,
    ActiveEvents2d::new(@collision.ActiveEvents::collision_events()),
  )
  try! world.set_by_key(
    e_override,
    ecs_key_contact_force_event_threshold2d,
    ContactForceEventThreshold2d::new(0.125F),
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()

  let ch0 = try! world
    .get_by_key(e_default, ecs_key_rapier_collider_handle2d)
    .unwrap().handle
  let collider0 = ctx.colliders.get(ch0).unwrap()
  debug_inspect(approx_eq_f32(collider0.density(), 2.5F), content="true")
  debug_inspect(approx_eq_f32(collider0.friction(), 0.25F), content="true")
  debug_inspect(approx_eq_f32(collider0.restitution(), 0.75F), content="true")
  debug_inspect(
    collider0
    .active_events()
    .contains(@collision.ActiveEvents::collision_events()),
    content="true",
  )
  debug_inspect(
    collider0
    .active_events()
    .contains(@collision.ActiveEvents::contact_force_events()),
    content="true",
  )
  debug_inspect(
    approx_eq_f32(collider0.contact_force_event_threshold(), 0.125F),
    content="true",
  )

  let ch1 = try! world
    .get_by_key(e_override, ecs_key_rapier_collider_handle2d)
    .unwrap().handle
  let collider1 = ctx.colliders.get(ch1).unwrap()
  debug_inspect(
    collider1
    .active_events()
    .contains(@collision.ActiveEvents::collision_events()),
    content="true",
  )
  debug_inspect(
    !collider1
    .active_events()
    .contains(@collision.ActiveEvents::contact_force_events()),
    content="true",
  )
}

///|
test "physics2d: query pipeline sees inserted colliders" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let floor = world.spawn()
  try! world.set_by_key(
    floor,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(floor, ecs_key_rigid_body2d, RigidBody2d::fixed())
  try! world.set_by_key(
    floor,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let hit = ctx.cast_ray_entity(
    @math.Vec2::new(0.0F, 10.0F),
    @math.Vec2::new(0.0F, -1.0F),
    100.0F,
    true,
  )
  debug_inspect(hit is Some(_), content="true")
  match hit {
    Some(h) => debug_inspect(h.entity.id == floor.id, content="true")
    None => debug_inspect(false, content="false")
  }
  let at_origin = ctx.intersect_point_entities(@math.Vec2::new(0.0F, 0.0F))
  debug_inspect(at_origin.length() > 0, content="true")
  debug_inspect(at_origin[0].id == floor.id, content="true")
  let excluded = ctx.query_filter_exclude_entity(
    @collision.QueryFilter::new(),
    floor,
  )
  let miss = ctx.cast_ray_entity_with_filter(
    @math.Vec2::new(0.0F, 10.0F),
    @math.Vec2::new(0.0F, -1.0F),
    100.0F,
    true,
    excluded,
  )
  debug_inspect(miss is None, content="true")
  let proj = ctx.project_point_entity(@math.Vec2::new(0.0F, 3.0F), 10.0F, true)
  debug_inspect(proj is Some(_), content="true")
  match proj {
    Some(p) => debug_inspect(p.entity.id == floor.id, content="true")
    None => debug_inspect(false, content="false")
  }
  let proj2 = ctx.project_point_entity_with_filter(
    @math.Vec2::new(0.0F, 3.0F),
    10.0F,
    true,
    excluded,
  )
  debug_inspect(proj2 is None, content="true")
  let feat = ctx.project_point_and_get_feature_entity(
    @math.Vec2::new(0.0F, 3.0F),
    10.0F,
    true,
  )
  debug_inspect(feat is Some(_), content="true")
  match feat {
    Some(p) => debug_inspect(p.entity.id == floor.id, content="true")
    None => debug_inspect(false, content="false")
  }
  let shape_hits = ctx.intersect_shape_entities(
    ColliderShape2d::ball(0.5F),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  debug_inspect(shape_hits.length() > 0, content="true")
  debug_inspect(shape_hits[0].id == floor.id, content="true")
  let aabb_hits = ctx.intersect_aabb_entities_conservative(
    @math.Rect::new(@math.Vec2::new(-1.0F, -1.0F), @math.Vec2::new(1.0F, 1.0F)),
  )
  debug_inspect(aabb_hits.length() > 0, content="true")
  debug_inspect(aabb_hits[0].id == floor.id, content="true")
  let sweep = ctx.cast_shape_entity(
    ColliderShape2d::ball(0.5F),
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 3.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    @math.Vec2::new(0.0F, -1.0F),
    @collision.ShapeCastOptions::new(10.0F, false),
  )
  debug_inspect(sweep is Some(_), content="true")
  match sweep {
    Some(s) => debug_inspect(s.entity.id == floor.id, content="true")
    None => debug_inspect(false, content="false")
  }
}

///|
test "physics2d: convex polygon and compound colliders can be inserted" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let convex = world.spawn()
  try! world.set_by_key(
    convex,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(5.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(convex, ecs_key_rigid_body2d, RigidBody2d::fixed())
  try! world.set_by_key(
    convex,
    ecs_key_collider2d,
    Collider2d::new(
      ColliderShape2d::convex_polygon([
        @math.Vec2::new(-1.0F, -1.0F),
        @math.Vec2::new(1.0F, -1.0F),
        @math.Vec2::new(1.0F, 1.0F),
        @math.Vec2::new(-1.0F, 1.0F),
      ]),
    ),
  )
  let compound = world.spawn()
  try! world.set_by_key(
    compound,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-5.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(compound, ecs_key_rigid_body2d, RigidBody2d::fixed())
  try! world.set_by_key(
    compound,
    ecs_key_collider2d,
    Collider2d::new(
      ColliderShape2d::compound([
        (
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(-1.0F, 0.0F),
            0.0F,
            @math.Vec2::new(1.0F, 1.0F),
            z=0.0F,
          ),
          ColliderShape2d::ball(0.5F),
        ),
        (
          @transform.Transform::from_xy_rotation_scale(
            @math.Vec2::new(1.0F, 0.0F),
            0.0F,
            @math.Vec2::new(1.0F, 1.0F),
            z=0.0F,
          ),
          ColliderShape2d::ball(0.5F),
        ),
      ]),
    ),
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let hits1 = ctx.intersect_aabb_entities_conservative(
    @math.Rect::new(@math.Vec2::new(4.0F, -2.0F), @math.Vec2::new(6.0F, 2.0F)),
  )
  let mut has_convex = false
  for e in hits1 {
    if e.id == convex.id {
      has_convex = true
    }
  }
  debug_inspect(has_convex, content="true")
  let hits2 = ctx.intersect_aabb_entities_conservative(
    @math.Rect::new(@math.Vec2::new(-6.0F, -2.0F), @math.Vec2::new(-4.0F, 2.0F)),
  )
  let mut has_compound = false
  for e in hits2 {
    if e.id == compound.id {
      has_compound = true
    }
  }
  debug_inspect(has_compound, content="true")
}

///|
test "physics2d: hooks filter_contact_pair can disable contacts" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let old_hooks = physics2d_hooks_config(world)
  let called = Ref(false)
  let mapped = Ref(false)
  physics2d_set_filter_contact_pair(world, fn(_bodies, _colliders, h1, _h2) {
    called.val = true
    mapped.val = physics2d_hook_entity_from_collider_handle(h1) is Some(_)
    false
  })
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let a = world.spawn()
  let b = world.spawn()
  try! world.set_by_key(
    a,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-0.49F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    b,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.49F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(a, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(b, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    a,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    b,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    a,
    ecs_key_velocity2d,
    Velocity2d::new(@math.Vec2::new(1.0F, 0.0F), 0.0F),
  )
  try! world.set_by_key(
    b,
    ecs_key_velocity2d,
    Velocity2d::new(@math.Vec2::new(-1.0F, 0.0F), 0.0F),
  )
  try! world.set_by_key(
    a,
    ecs_key_active_hooks2d,
    ActiveHooks2d::new(@collision.ActiveHooks::filter_contact_pairs()),
  )
  try! world.set_by_key(
    b,
    ecs_key_active_hooks2d,
    ActiveHooks2d::new(@collision.ActiveHooks::filter_contact_pairs()),
  )
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  debug_inspect(called.val, content="true")
  debug_inspect(mapped.val, content="true")
  let events = get_physics2d_events_resource(world).get().unwrap()
  debug_inspect(events.collisions.length() == 0, content="true")
  physics2d_hooks_set_config(world, old_hooks)
}

///|
test "physics2d: impulse joint is inserted and cleaned up" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let a = world.spawn()
  let b = world.spawn()
  try! world.set_by_key(
    a,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(a, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    a,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(a, ecs_key_velocity2d, Velocity2d::zero())
  try! world.set_by_key(
    b,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(b, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  try! world.set_by_key(
    b,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(b, ecs_key_velocity2d, Velocity2d::zero())
  let fixed = @dynamics.FixedJointBuilder::new().build()
  let data = @dynamics.GenericJoint::from_fixed(fixed)
  try! world.set_by_key(
    a,
    ecs_key_impulse_joint2d,
    ImpulseJoint2d::new(b, data),
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_joints_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  debug_inspect(ctx.impulse_joints.len() == 1, content="true")
  debug_inspect(
    try! world.contains_by_key(a, ecs_key_rapier_impulse_joint_handle2d),
    content="true",
  )

  // Remove authoring component and verify cleanup removes the Rapier joint.
  try! (world.take(a, ecs_key_impulse_joint2d) |> ignore)
  physics2d_cleanup_despawned_system(world)
  debug_inspect(ctx.impulse_joints.len() == 0, content="true")
  debug_inspect(
    !(try! world.contains_by_key(a, ecs_key_rapier_impulse_joint_handle2d)),
    content="true",
  )
}

///|
test "physics2d: child collider attaches to parent body" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let body = world.spawn()
  try! world.set_by_key(
    body,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(body, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  let child = world.spawn()
  try! world.set_by_key(
    child,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
  )
  try! world.set_by_key(
    child,
    ecs_key_collider_parent2d,
    ColliderParent2d::new(body),
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let bh = try! world.get_by_key(body, ecs_key_rapier_body_handle2d).unwrap().handle
  let ch = try! world
    .get_by_key(child, ecs_key_rapier_collider_handle2d)
    .unwrap().handle
  let collider = ctx.colliders.get(ch).unwrap()
  debug_inspect(
    collider.parent().unwrap().into_raw_parts() == bh.into_raw_parts(),
    content="true",
  )
  let rel = collider.position_wrt_parent().unwrap()
  debug_inspect(rel.translation.x == 1.0F, content="true")
}

///|
test "physics2d: multiple child colliders aggregate parent mass" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)

  let body_single = world.spawn()
  try! world.set_by_key(
    body_single,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-3.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    body_single,
    ecs_key_rigid_body2d,
    RigidBody2d::dynamic(),
  )
  let child_single = world.spawn()
  try! world.set_by_key(
    child_single,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    child_single,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    child_single,
    ecs_key_collider_parent2d,
    ColliderParent2d::new(body_single),
  )

  let body_double = world.spawn()
  try! world.set_by_key(
    body_double,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    body_double,
    ecs_key_rigid_body2d,
    RigidBody2d::dynamic(),
  )
  let child_double_a = world.spawn()
  try! world.set_by_key(
    child_double_a,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-0.75F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    child_double_a,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    child_double_a,
    ecs_key_collider_parent2d,
    ColliderParent2d::new(body_double),
  )
  let child_double_b = world.spawn()
  try! world.set_by_key(
    child_double_b,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.75F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    child_double_b,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    child_double_b,
    ecs_key_collider_parent2d,
    ColliderParent2d::new(body_double),
  )

  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let bh_single = (try! world.get_by_key(
      body_single, ecs_key_rapier_body_handle2d,
    )).unwrap().handle
  let bh_double = (try! world.get_by_key(
      body_double, ecs_key_rapier_body_handle2d,
    )).unwrap().handle
  let inv_single = ctx.rigid_bodies.get(bh_single).unwrap().inv_mass()
  let inv_double = ctx.rigid_bodies.get(bh_double).unwrap().inv_mass()
  debug_inspect(inv_single > 0.0F, content="true")
  debug_inspect(inv_double > 0.0F, content="true")
  debug_inspect(inv_double < inv_single, content="true")
}

///|
test "physics2d: collision events use child collider entity mapping" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, -500.0F))
  cfg_res.insert(cfg.val)

  let floor = world.spawn()
  try! world.set_by_key(
    floor,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(floor, ecs_key_rigid_body2d, RigidBody2d::fixed())
  try! world.set_by_key(
    floor,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::cuboid(5.0F, 0.5F)),
  )

  let body = world.spawn()
  try! world.set_by_key(
    body,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(body, ecs_key_rigid_body2d, RigidBody2d::dynamic())
  let child = world.spawn()
  try! world.set_by_key(
    child,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.6F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    child,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    child,
    ecs_key_collider_parent2d,
    ColliderParent2d::new(body),
  )

  physics2d_sync_insertions_system(world)
  let mut seen_child = false
  let mut seen_parent = false
  for _ in 0..<120 {
    physics2d_clear_events_system(world)
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    let events = get_physics2d_events_resource(world).get().unwrap()
    for ev in events.collisions {
      match ev {
        CollisionEvent2d::Started(a, b, _) => {
          if a.id == child.id || b.id == child.id {
            seen_child = true
          }
          if a.id == body.id || b.id == body.id {
            seen_parent = true
          }
        }
        CollisionEvent2d::Stopped(_, _, _) => ()
      }
    }
  }
  debug_inspect(seen_child, content="true")
  debug_inspect(!seen_parent, content="true")
}

///|
test "physics2d: kinematic character controller moves and outputs" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val)
  let floor = world.spawn()
  try! world.set_by_key(
    floor,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(floor, ecs_key_rigid_body2d, RigidBody2d::fixed())
  try! world.set_by_key(
    floor,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
  )
  let character = world.spawn()
  try! world.set_by_key(
    character,
    ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    character,
    ecs_key_collider2d,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
  )
  try! world.set_by_key(
    character,
    ecs_key_kinematic_character_controller2d,
    KinematicCharacterController2d::default().with_translation(
      @math.Vec2::new(0.0F, -2.0F),
    ),
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_character_controller_system(world)
  let y = try! world.get_by_key(character, ecs_key_transform).unwrap().translation.y
  debug_inspect(y > 0.9F, content="true")
  let kcc_after = (try! world.get_by_key(
    character, ecs_key_kinematic_character_controller2d,
  )).unwrap()
  debug_inspect(kcc_after.translation.y == 0.0F, content="true")
  let out = (try! world.get_by_key(
    character, ecs_key_kinematic_character_controller_output2d,
  )).unwrap()
  debug_inspect(out.effective_translation.y <= 0.0F, content="true")
  debug_inspect(out.collisions.length() > 0, content="true")
}
