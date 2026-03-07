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
test "physics2d: falling body collides and writes back transform" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  // Make the test converge quickly.
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, -200.0F))
  cfg_res.insert(cfg.val, tick)
  let floor = world.spawn()
  let ball = world.spawn()

  // Floor at y = -1 with half-height 0.5 => top at y = -0.5.
  @math.get_transform_store(world).insert(
    floor,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(floor, RigidBody2d::fixed(), tick)
  get_collider2d_store(world).insert(
    floor,
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
    tick,
  )
  get_contact_force_event_threshold2d_store(world).insert(
    floor,
    ContactForceEventThreshold2d::new(0.0F),
    tick,
  )
  @math.get_transform_store(world).insert(
    ball,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 5.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(ball, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    ball,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_contact_force_event_threshold2d_store(world).insert(
    ball,
    ContactForceEventThreshold2d::new(0.0F),
    tick,
  )
  get_velocity2d_store(world).insert(ball, Velocity2d::zero(), tick)
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  let initial_y = @math.get_transform_store(world).get(ball).unwrap().translation.y

  // Step for ~2 seconds.
  let mut i = 0
  while i < 120 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  let final_y = @math.get_transform_store(world).get(ball).unwrap().translation.y
  inspect(final_y < initial_y, content="true")
  let events = get_physics2d_events_resource(world).get().unwrap()
  inspect(events.collisions.length() > 0, content="true")
  inspect(events.contact_forces.length() > 0, content="true")
}

///|
test "physics2d: gravity scale 0 disables gravity" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, -100.0F))
  cfg_res.insert(cfg.val, tick)
  let no_grav = world.spawn()
  let grav = world.spawn()
  @math.get_transform_store(world).insert(
    no_grav,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  @math.get_transform_store(world).insert(
    grav,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(no_grav, RigidBody2d::dynamic(), tick)
  get_rigid_body2d_store(world).insert(grav, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    no_grav,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_collider2d_store(world).insert(
    grav,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_gravity_scale2d_store(world).insert(
    no_grav,
    GravityScale2d::new(0.0F),
    tick,
  )
  get_velocity2d_store(world).insert(no_grav, Velocity2d::zero(), tick)
  get_velocity2d_store(world).insert(grav, Velocity2d::zero(), tick)
  physics2d_sync_insertions_system(world)
  let y0 = @math.get_transform_store(world).get(no_grav).unwrap().translation.y
  let y1 = @math.get_transform_store(world).get(grav).unwrap().translation.y
  let mut i = 0
  while i < 60 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  // Debug (kept): this test asserts semantics via positions; keep the following
  // assertions focused and avoid relying on exact floating-point equality.
  let y0_final = @math.get_transform_store(world).get(no_grav).unwrap().translation.y
  let y1_final = @math.get_transform_store(world).get(grav).unwrap().translation.y
  inspect(y0_final > y0 - 0.01F, content="true")
  inspect(y1_final < y1, content="true")
}

///|
test "physics2d: damping reduces velocity" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let no_damp = world.spawn()
  let damp = world.spawn()
  for e in [no_damp, damp] {
    @math.get_transform_store(world).insert(
      e,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    get_rigid_body2d_store(world).insert(e, RigidBody2d::dynamic(), tick)
    get_collider2d_store(world).insert(
      e,
      Collider2d::new(ColliderShape2d::ball(0.2F)),
      tick,
    )
    get_velocity2d_store(world).insert(
      e,
      Velocity2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
      tick,
    )
  }
  get_damping2d_store(world).insert(damp, Damping2d::new(10.0F, 0.0F), tick)
  physics2d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  let v_no = get_velocity2d_store(world).get(no_damp).unwrap().linvel.x
  let v_damp = get_velocity2d_store(world).get(damp).unwrap().linvel.x
  inspect(v_damp < v_no, content="true")
}

///|
test "physics2d: external impulse applies once and clears" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let e = world.spawn()
  @math.get_transform_store(world).insert(
    e,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(e, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    e,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_velocity2d_store(world).insert(e, Velocity2d::zero(), tick)
  get_external_impulse2d_store(world).insert(
    e,
    ExternalImpulse2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let v = get_velocity2d_store(world).get(e).unwrap()
  inspect(v.linvel.x > 0.0F, content="true")
  let imp = get_external_impulse2d_store(world).get(e).unwrap()
  inspect(imp.impulse.x == 0.0F, content="true")
}

///|
test "physics2d: default collider density yields non-zero mass" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let e = world.spawn()
  @math.get_transform_store(world).insert(
    e,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(e, RigidBody2d::dynamic(), tick)
  // No `ColliderDensity2d` here: this test asserts moon_rapier's default density
  // behaves like upstream Rapier (non-zero mass).
  get_collider2d_store(world).insert(
    e,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_velocity2d_store(world).insert(e, Velocity2d::zero(), tick)
  get_external_impulse2d_store(world).insert(
    e,
    ExternalImpulse2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let bh = get_rapier_body_handle2d_store(world).get(e).unwrap().handle
  inspect(ctx.rigid_bodies.get(bh).unwrap().inv_mass() > 0.0F, content="true")
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let v = get_velocity2d_store(world).get(e).unwrap()
  inspect(v.linvel.x > 0.0F, content="true")
}

///|
test "physics2d: external force persists" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let e = world.spawn()
  @math.get_transform_store(world).insert(
    e,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(e, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    e,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_velocity2d_store(world).insert(e, Velocity2d::zero(), tick)
  get_external_force2d_store(world).insert(
    e,
    ExternalForce2d::new(@math.Vec2::new(50.0F, 0.0F), 0.0F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let x0 = @math.get_transform_store(world).get(e).unwrap().translation.x
  let mut i = 0
  while i < 30 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  let x1 = @math.get_transform_store(world).get(e).unwrap().translation.x
  inspect(x1 > x0, content="true")
}

///|
test "physics2d: CCD prevents tunneling through thin floor" {
  fn run(ccd_enabled : Bool) -> Float {
    let world = @ecs.World::new()
    configure_fixed_time(world, 1.0F / 10.0F)
    physics2d_init_resources_system(world)
    let tick = world.read_change_tick()
    let cfg_res = get_physics2d_config_resource(world)
    let cfg = Ref::new(cfg_res.get().unwrap())
    cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
    cfg_res.insert(cfg.val, tick)
    let floor = world.spawn()
    let ball = world.spawn()
    @math.get_transform_store(world).insert(
      floor,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    get_rigid_body2d_store(world).insert(floor, RigidBody2d::fixed(), tick)
    get_collider2d_store(world).insert(
      floor,
      Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.01F)),
      tick,
    )
    @math.get_transform_store(world).insert(
      ball,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 1.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    get_rigid_body2d_store(world).insert(ball, RigidBody2d::dynamic(), tick)
    get_collider2d_store(world).insert(
      ball,
      Collider2d::new(ColliderShape2d::ball(0.01F)),
      tick,
    )
    get_velocity2d_store(world).insert(
      ball,
      Velocity2d::new(@math.Vec2::new(0.0F, -200.0F), 0.0F),
      tick,
    )
    if ccd_enabled {
      get_ccd2d_store(world).insert(ball, Ccd2d::enabled(), tick)
    }
    physics2d_sync_insertions_system(world)
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    @math.get_transform_store(world).get(ball).unwrap().translation.y
  }

  let y_no_ccd = run(false)
  let y_ccd = run(true)
  inspect(y_no_ccd < -0.5F, content="true")
  inspect(y_ccd > -0.5F, content="true")
}

///|
test "physics2d: collision groups filter collision events" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let a = world.spawn()
  let b = world.spawn()
  for e in [a, b] {
    @math.get_transform_store(world).insert(
      e,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    get_rigid_body2d_store(world).insert(e, RigidBody2d::dynamic(), tick)
    get_collider2d_store(world).insert(
      e,
      Collider2d::new(ColliderShape2d::ball(0.5F)),
      tick,
    )
    get_velocity2d_store(world).insert(e, Velocity2d::zero(), tick)
  }
  // Put them in disjoint groups so they never collide.
  get_collision_groups2d_store(world).insert(
    a,
    CollisionGroups2d::new(1, 1, @dynamics.InteractionTestMode::And),
    tick,
  )
  get_collision_groups2d_store(world).insert(
    b,
    CollisionGroups2d::new(2, 2, @dynamics.InteractionTestMode::And),
    tick,
  )
  get_solver_groups2d_store(world).insert(
    a,
    SolverGroups2d::new(1, 1, @dynamics.InteractionTestMode::And),
    tick,
  )
  get_solver_groups2d_store(world).insert(
    b,
    SolverGroups2d::new(2, 2, @dynamics.InteractionTestMode::And),
    tick,
  )
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let events = get_physics2d_events_resource(world).get().unwrap()
  inspect(events.collisions.length() == 0, content="true")
}

///|
test "physics2d: collider material and active event properties sync to rapier" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let e_default = world.spawn()
  @math.get_transform_store(world).insert(
    e_default,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(e_default, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    e_default,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_collider_density2d_store(world).insert(
    e_default,
    ColliderDensity2d::new(2.5F),
    tick,
  )
  get_friction2d_store(world).insert(e_default, Friction2d::new(0.25F), tick)
  get_restitution2d_store(world).insert(
    e_default,
    Restitution2d::new(0.75F),
    tick,
  )
  get_contact_force_event_threshold2d_store(world).insert(
    e_default,
    ContactForceEventThreshold2d::new(0.125F),
    tick,
  )

  let e_override = world.spawn()
  @math.get_transform_store(world).insert(
    e_override,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(e_override, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    e_override,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_active_events2d_store(world).insert(
    e_override,
    ActiveEvents2d::new(@collision.ActiveEvents::collision_events()),
    tick,
  )
  get_contact_force_event_threshold2d_store(world).insert(
    e_override,
    ContactForceEventThreshold2d::new(0.125F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let store = get_rapier_collider_handle2d_store(world)

  let ch0 = store.get(e_default).unwrap().handle
  let collider0 = ctx.colliders.get(ch0).unwrap()
  inspect(approx_eq_f32(collider0.density(), 2.5F), content="true")
  inspect(approx_eq_f32(collider0.friction(), 0.25F), content="true")
  inspect(approx_eq_f32(collider0.restitution(), 0.75F), content="true")
  inspect(
    collider0
    .active_events()
    .contains(@collision.ActiveEvents::collision_events()),
    content="true",
  )
  inspect(
    collider0
    .active_events()
    .contains(@collision.ActiveEvents::contact_force_events()),
    content="true",
  )
  inspect(
    approx_eq_f32(collider0.contact_force_event_threshold(), 0.125F),
    content="true",
  )

  let ch1 = store.get(e_override).unwrap().handle
  let collider1 = ctx.colliders.get(ch1).unwrap()
  inspect(
    collider1
    .active_events()
    .contains(@collision.ActiveEvents::collision_events()),
    content="true",
  )
  inspect(
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
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let floor = world.spawn()
  @math.get_transform_store(world).insert(
    floor,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(floor, RigidBody2d::fixed(), tick)
  get_collider2d_store(world).insert(
    floor,
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let hit = ctx.cast_ray_entity(
    @math.Vec2::new(0.0F, 10.0F),
    @math.Vec2::new(0.0F, -1.0F),
    100.0F,
    true,
  )
  inspect(hit is Some(_), content="true")
  match hit {
    Some(h) => inspect(h.entity.id == floor.id, content="true")
    None => inspect(false, content="false")
  }
  let at_origin = ctx.intersect_point_entities(@math.Vec2::new(0.0F, 0.0F))
  inspect(at_origin.length() > 0, content="true")
  inspect(at_origin[0].id == floor.id, content="true")
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
  inspect(miss is None, content="true")
  let proj = ctx.project_point_entity(@math.Vec2::new(0.0F, 3.0F), 10.0F, true)
  inspect(proj is Some(_), content="true")
  match proj {
    Some(p) => inspect(p.entity.id == floor.id, content="true")
    None => inspect(false, content="false")
  }
  let proj2 = ctx.project_point_entity_with_filter(
    @math.Vec2::new(0.0F, 3.0F),
    10.0F,
    true,
    excluded,
  )
  inspect(proj2 is None, content="true")
  let feat = ctx.project_point_and_get_feature_entity(
    @math.Vec2::new(0.0F, 3.0F),
    10.0F,
    true,
  )
  inspect(feat is Some(_), content="true")
  match feat {
    Some(p) => inspect(p.entity.id == floor.id, content="true")
    None => inspect(false, content="false")
  }
  let shape_hits = ctx.intersect_shape_entities(
    ColliderShape2d::ball(0.5F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  inspect(shape_hits.length() > 0, content="true")
  inspect(shape_hits[0].id == floor.id, content="true")
  let aabb_hits = ctx.intersect_aabb_entities_conservative(
    @math.Rect::new(@math.Vec2::new(-1.0F, -1.0F), @math.Vec2::new(1.0F, 1.0F)),
  )
  inspect(aabb_hits.length() > 0, content="true")
  inspect(aabb_hits[0].id == floor.id, content="true")
  let sweep = ctx.cast_shape_entity(
    ColliderShape2d::ball(0.5F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 3.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    @math.Vec2::new(0.0F, -1.0F),
    @collision.ShapeCastOptions::new(10.0F, false),
  )
  inspect(sweep is Some(_), content="true")
  match sweep {
    Some(s) => inspect(s.entity.id == floor.id, content="true")
    None => inspect(false, content="false")
  }
}

///|
test "physics2d: convex polygon and compound colliders can be inserted" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let convex = world.spawn()
  @math.get_transform_store(world).insert(
    convex,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(5.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(convex, RigidBody2d::fixed(), tick)
  get_collider2d_store(world).insert(
    convex,
    Collider2d::new(
      ColliderShape2d::convex_polygon([
        @math.Vec2::new(-1.0F, -1.0F),
        @math.Vec2::new(1.0F, -1.0F),
        @math.Vec2::new(1.0F, 1.0F),
        @math.Vec2::new(-1.0F, 1.0F),
      ]),
    ),
    tick,
  )
  let compound = world.spawn()
  @math.get_transform_store(world).insert(
    compound,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-5.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(compound, RigidBody2d::fixed(), tick)
  get_collider2d_store(world).insert(
    compound,
    Collider2d::new(
      ColliderShape2d::compound([
        (
          @math.Transform::from_xy_rotation_scale(
            @math.Vec2::new(-1.0F, 0.0F),
            0.0F,
            @math.Vec2::new(1.0F, 1.0F),
            z=0.0F,
          ),
          ColliderShape2d::ball(0.5F),
        ),
        (
          @math.Transform::from_xy_rotation_scale(
            @math.Vec2::new(1.0F, 0.0F),
            0.0F,
            @math.Vec2::new(1.0F, 1.0F),
            z=0.0F,
          ),
          ColliderShape2d::ball(0.5F),
        ),
      ]),
    ),
    tick,
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
  inspect(has_convex, content="true")
  let hits2 = ctx.intersect_aabb_entities_conservative(
    @math.Rect::new(@math.Vec2::new(-6.0F, -2.0F), @math.Vec2::new(-4.0F, 2.0F)),
  )
  let mut has_compound = false
  for e in hits2 {
    if e.id == compound.id {
      has_compound = true
    }
  }
  inspect(has_compound, content="true")
}

///|
test "physics2d: hooks filter_contact_pair can disable contacts" {
  let old_hooks = physics2d_hooks_config()
  let called = Ref::new(false)
  let mapped = Ref::new(false)
  physics2d_set_filter_contact_pair(fn(_bodies, _colliders, h1, _h2) {
    called.val = true
    mapped.val = physics2d_hook_entity_from_collider_handle(h1) is Some(_)
    false
  })
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let a = world.spawn()
  let b = world.spawn()
  @math.get_transform_store(world).insert(
    a,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-0.49F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  @math.get_transform_store(world).insert(
    b,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.49F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(a, RigidBody2d::dynamic(), tick)
  get_rigid_body2d_store(world).insert(b, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    a,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_collider2d_store(world).insert(
    b,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_velocity2d_store(world).insert(
    a,
    Velocity2d::new(@math.Vec2::new(1.0F, 0.0F), 0.0F),
    tick,
  )
  get_velocity2d_store(world).insert(
    b,
    Velocity2d::new(@math.Vec2::new(-1.0F, 0.0F), 0.0F),
    tick,
  )
  get_active_hooks2d_store(world).insert(
    a,
    ActiveHooks2d::new(@collision.ActiveHooks::filter_contact_pairs()),
    tick,
  )
  get_active_hooks2d_store(world).insert(
    b,
    ActiveHooks2d::new(@collision.ActiveHooks::filter_contact_pairs()),
    tick,
  )
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  inspect(called.val, content="true")
  inspect(mapped.val, content="true")
  let events = get_physics2d_events_resource(world).get().unwrap()
  inspect(events.collisions.length() == 0, content="true")
  physics2d_hooks_set_config(old_hooks)
}

///|
test "physics2d: impulse joint is inserted and cleaned up" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let a = world.spawn()
  let b = world.spawn()
  @math.get_transform_store(world).insert(
    a,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(a, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    a,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_velocity2d_store(world).insert(a, Velocity2d::zero(), tick)
  @math.get_transform_store(world).insert(
    b,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(b, RigidBody2d::dynamic(), tick)
  get_collider2d_store(world).insert(
    b,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_velocity2d_store(world).insert(b, Velocity2d::zero(), tick)
  let fixed = @dynamics.FixedJointBuilder::new().build()
  let data = @dynamics.GenericJoint::from_fixed(fixed)
  get_impulse_joint2d_store(world).insert(a, ImpulseJoint2d::new(b, data), tick)
  physics2d_sync_insertions_system(world)
  physics2d_sync_joints_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  inspect(ctx.impulse_joints.len() == 1, content="true")
  inspect(
    get_rapier_impulse_joint_handle2d_store(world).contains(a),
    content="true",
  )

  // Remove authoring component and verify cleanup removes the Rapier joint.
  get_impulse_joint2d_store(world).remove(a) |> ignore
  physics2d_cleanup_despawned_system(world)
  inspect(ctx.impulse_joints.len() == 0, content="true")
  inspect(
    !get_rapier_impulse_joint_handle2d_store(world).contains(a),
    content="true",
  )
}

///|
test "physics2d: child collider attaches to parent body" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let body = world.spawn()
  @math.get_transform_store(world).insert(
    body,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(body, RigidBody2d::dynamic(), tick)
  let child = world.spawn()
  @math.get_transform_store(world).insert(
    child,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_collider2d_store(world).insert(
    child,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  get_collider_parent2d_store(world).insert(
    child,
    ColliderParent2d::new(body),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let bh = get_rapier_body_handle2d_store(world).get(body).unwrap().handle
  let ch = get_rapier_collider_handle2d_store(world).get(child).unwrap().handle
  let collider = ctx.colliders.get(ch).unwrap()
  inspect(
    collider.parent().unwrap().into_raw_parts() == bh.into_raw_parts(),
    content="true",
  )
  let rel = collider.position_wrt_parent().unwrap()
  inspect(rel.translation.x == 1.0F, content="true")
}

///|
test "physics2d: multiple child colliders aggregate parent mass" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)

  let body_single = world.spawn()
  @math.get_transform_store(world).insert(
    body_single,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-3.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(
    body_single,
    RigidBody2d::dynamic(),
    tick,
  )
  let child_single = world.spawn()
  @math.get_transform_store(world).insert(
    child_single,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_collider2d_store(world).insert(
    child_single,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_collider_parent2d_store(world).insert(
    child_single,
    ColliderParent2d::new(body_single),
    tick,
  )

  let body_double = world.spawn()
  @math.get_transform_store(world).insert(
    body_double,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(3.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(
    body_double,
    RigidBody2d::dynamic(),
    tick,
  )
  let child_double_a = world.spawn()
  @math.get_transform_store(world).insert(
    child_double_a,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-0.75F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_collider2d_store(world).insert(
    child_double_a,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_collider_parent2d_store(world).insert(
    child_double_a,
    ColliderParent2d::new(body_double),
    tick,
  )
  let child_double_b = world.spawn()
  @math.get_transform_store(world).insert(
    child_double_b,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.75F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_collider2d_store(world).insert(
    child_double_b,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_collider_parent2d_store(world).insert(
    child_double_b,
    ColliderParent2d::new(body_double),
    tick,
  )

  physics2d_sync_insertions_system(world)
  let ctx = get_physics2d_context_resource(world).get().unwrap()
  let bh_single = get_rapier_body_handle2d_store(world)
    .get(body_single)
    .unwrap().handle
  let bh_double = get_rapier_body_handle2d_store(world)
    .get(body_double)
    .unwrap().handle
  let inv_single = ctx.rigid_bodies.get(bh_single).unwrap().inv_mass()
  let inv_double = ctx.rigid_bodies.get(bh_double).unwrap().inv_mass()
  inspect(inv_single > 0.0F, content="true")
  inspect(inv_double > 0.0F, content="true")
  inspect(inv_double < inv_single, content="true")
}

///|
test "physics2d: collision events use child collider entity mapping" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, -500.0F))
  cfg_res.insert(cfg.val, tick)

  let floor = world.spawn()
  @math.get_transform_store(world).insert(
    floor,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(floor, RigidBody2d::fixed(), tick)
  get_collider2d_store(world).insert(
    floor,
    Collider2d::new(ColliderShape2d::cuboid(5.0F, 0.5F)),
    tick,
  )

  let body = world.spawn()
  @math.get_transform_store(world).insert(
    body,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(body, RigidBody2d::dynamic(), tick)
  let child = world.spawn()
  @math.get_transform_store(world).insert(
    child,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.6F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_collider2d_store(world).insert(
    child,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_collider_parent2d_store(world).insert(
    child,
    ColliderParent2d::new(body),
    tick,
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
  inspect(seen_child, content="true")
  inspect(!seen_parent, content="true")
}

///|
test "physics2d: kinematic character controller moves and outputs" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics2d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics2d_config_resource(world)
  let cfg = Ref::new(cfg_res.get().unwrap())
  cfg.val = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  cfg_res.insert(cfg.val, tick)
  let floor = world.spawn()
  @math.get_transform_store(world).insert(
    floor,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_rigid_body2d_store(world).insert(floor, RigidBody2d::fixed(), tick)
  get_collider2d_store(world).insert(
    floor,
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
    tick,
  )
  let character = world.spawn()
  @math.get_transform_store(world).insert(
    character,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  get_collider2d_store(world).insert(
    character,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  get_kinematic_character_controller2d_store(world).insert(
    character,
    KinematicCharacterController2d::default().with_translation(
      @math.Vec2::new(0.0F, -2.0F),
    ),
    tick,
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_character_controller_system(world)
  let y = @math.get_transform_store(world).get(character).unwrap().translation.y
  inspect(y > 0.9F, content="true")
  let kcc_after = get_kinematic_character_controller2d_store(world)
    .get(character)
    .unwrap()
  inspect(kcc_after.translation.y == 0.0F, content="true")
  let out = get_kinematic_character_controller_output2d_store(world)
    .get(character)
    .unwrap()
  inspect(out.effective_translation.y <= 0.0F, content="true")
  inspect(out.collisions.length() > 0, content="true")
}
