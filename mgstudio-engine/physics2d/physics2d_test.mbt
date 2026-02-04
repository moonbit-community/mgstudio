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
struct Physics2dTestWorld {
  mut tick : @core.Tick
  transform : @core.ComponentStore[@math.Transform]
  rigid_body : @core.ComponentStore[RigidBody2d]
  collider : @core.ComponentStore[Collider2d]
  velocity : @core.ComponentStore[Velocity2d]
  damping : @core.ComponentStore[Damping2d]
  gravity_scale : @core.ComponentStore[GravityScale2d]
  locked_axes : @core.ComponentStore[LockedAxes2d]
  ccd : @core.ComponentStore[Ccd2d]
  dominance : @core.ComponentStore[Dominance2d]
  sleeping : @core.ComponentStore[Sleeping2d]
  external_force : @core.ComponentStore[ExternalForce2d]
  external_impulse : @core.ComponentStore[ExternalImpulse2d]
  contact_force_threshold : @core.ComponentStore[ContactForceEventThreshold2d]
  collider_density : @core.ComponentStore[ColliderDensity2d]
  friction : @core.ComponentStore[Friction2d]
  friction_rule : @core.ComponentStore[FrictionCombineRule2d]
  restitution : @core.ComponentStore[Restitution2d]
  restitution_rule : @core.ComponentStore[RestitutionCombineRule2d]
  collision_groups : @core.ComponentStore[CollisionGroups2d]
  solver_groups : @core.ComponentStore[SolverGroups2d]
  body_handle : @core.ComponentStore[RapierBodyHandle2d]
  collider_handle : @core.ComponentStore[RapierColliderHandle2d]
  config : @core.Resource[Physics2dConfig]
  context : @core.Resource[Physics2dContext]
  events : @core.Resource[Physics2dEvents]
}

///|
fn Physics2dTestWorld::new() -> Physics2dTestWorld {
  {
    tick: 0,
    transform: @core.ComponentStore::new(),
    rigid_body: @core.ComponentStore::new(),
    collider: @core.ComponentStore::new(),
    velocity: @core.ComponentStore::new(),
    damping: @core.ComponentStore::new(),
    gravity_scale: @core.ComponentStore::new(),
    locked_axes: @core.ComponentStore::new(),
    ccd: @core.ComponentStore::new(),
    dominance: @core.ComponentStore::new(),
    sleeping: @core.ComponentStore::new(),
    external_force: @core.ComponentStore::new(),
    external_impulse: @core.ComponentStore::new(),
    contact_force_threshold: @core.ComponentStore::new(),
    collider_density: @core.ComponentStore::new(),
    friction: @core.ComponentStore::new(),
    friction_rule: @core.ComponentStore::new(),
    restitution: @core.ComponentStore::new(),
    restitution_rule: @core.ComponentStore::new(),
    collision_groups: @core.ComponentStore::new(),
    solver_groups: @core.ComponentStore::new(),
    body_handle: @core.ComponentStore::new(),
    collider_handle: @core.ComponentStore::new(),
    config: @core.Resource::new(),
    context: @core.Resource::new(),
    events: @core.Resource::new(),
  }
}

///|
impl @core.ChangeTickWorld for Physics2dTestWorld with read_change_tick(self) {
  self.tick
}

///|
impl @core.ChangeTickWorld for Physics2dTestWorld with increment_change_tick(
  self,
) {
  self.tick = self.tick + 1
  self.tick
}

///|
impl @math.Has_Transform for Physics2dTestWorld with get_transform_store(self) {
  self.transform
}

///|
impl Has_RigidBody2d for Physics2dTestWorld with get_rigid_body2d_store(self) {
  self.rigid_body
}

///|
impl Has_Collider2d for Physics2dTestWorld with get_collider2d_store(self) {
  self.collider
}

///|
impl Has_Velocity2d for Physics2dTestWorld with get_velocity2d_store(self) {
  self.velocity
}

///|
impl Has_Damping2d for Physics2dTestWorld with get_damping2d_store(self) {
  self.damping
}

///|
impl Has_GravityScale2d for Physics2dTestWorld with get_gravity_scale2d_store(
  self,
) {
  self.gravity_scale
}

///|
impl Has_LockedAxes2d for Physics2dTestWorld with get_locked_axes2d_store(self) {
  self.locked_axes
}

///|
impl Has_Ccd2d for Physics2dTestWorld with get_ccd2d_store(self) {
  self.ccd
}

///|
impl Has_Dominance2d for Physics2dTestWorld with get_dominance2d_store(self) {
  self.dominance
}

///|
impl Has_Sleeping2d for Physics2dTestWorld with get_sleeping2d_store(self) {
  self.sleeping
}

///|
impl Has_ExternalForce2d for Physics2dTestWorld with get_external_force2d_store(
  self,
) {
  self.external_force
}

///|
impl Has_ExternalImpulse2d for Physics2dTestWorld with get_external_impulse2d_store(
  self,
) {
  self.external_impulse
}

///|
impl Has_ContactForceEventThreshold2d for Physics2dTestWorld with get_contact_force_event_threshold2d_store(
  self,
) {
  self.contact_force_threshold
}

///|
impl Has_ColliderDensity2d for Physics2dTestWorld with get_collider_density2d_store(
  self,
) {
  self.collider_density
}

///|
impl Has_Friction2d for Physics2dTestWorld with get_friction2d_store(self) {
  self.friction
}

///|
impl Has_FrictionCombineRule2d for Physics2dTestWorld with get_friction_combine_rule2d_store(
  self,
) {
  self.friction_rule
}

///|
impl Has_Restitution2d for Physics2dTestWorld with get_restitution2d_store(self) {
  self.restitution
}

///|
impl Has_RestitutionCombineRule2d for Physics2dTestWorld with get_restitution_combine_rule2d_store(
  self,
) {
  self.restitution_rule
}

///|
impl Has_CollisionGroups2d for Physics2dTestWorld with get_collision_groups2d_store(
  self,
) {
  self.collision_groups
}

///|
impl Has_SolverGroups2d for Physics2dTestWorld with get_solver_groups2d_store(
  self,
) {
  self.solver_groups
}

///|
impl Has_RapierBodyHandle2d for Physics2dTestWorld with get_rapier_body_handle2d_store(
  self,
) {
  self.body_handle
}

///|
impl Has_RapierColliderHandle2d for Physics2dTestWorld with get_rapier_collider_handle2d_store(
  self,
) {
  self.collider_handle
}

///|
impl HasRes_Physics2dConfig for Physics2dTestWorld with get_physics2d_config_resource(
  self,
) {
  self.config
}

///|
impl HasRes_Physics2dContext for Physics2dTestWorld with get_physics2d_context_resource(
  self,
) {
  self.context
}

///|
impl HasRes_Physics2dEvents for Physics2dTestWorld with get_physics2d_events_resource(
  self,
) {
  self.events
}

///|
test "physics2d: falling body collides and writes back transform" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  // Make the test converge quickly.
  let cfg_res = HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  cfg_res.get_ref_mut(tick).unwrap().val = Physics2dConfig::new(
    @math.Vec2::new(0.0F, -200.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)

  // Floor at y = -1 with half-height 0.5 => top at y = -0.5.
  @math.Has_Transform::get_transform_store(world).insert(
    floor,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -1.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    floor,
    RigidBody2d::fixed(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    floor,
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
    tick,
  )
  Has_ContactForceEventThreshold2d::get_contact_force_event_threshold2d_store(
    world,
  ).insert(floor, ContactForceEventThreshold2d::new(0.0F), tick)
  @math.Has_Transform::get_transform_store(world).insert(
    ball,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 5.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    ball,
    RigidBody2d::dynamic(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    ball,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  Has_ContactForceEventThreshold2d::get_contact_force_event_threshold2d_store(
    world,
  ).insert(ball, ContactForceEventThreshold2d::new(0.0F), tick)
  Has_Velocity2d::get_velocity2d_store(world).insert(
    ball,
    Velocity2d::zero(),
    tick,
  )
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  let initial_y = @math.Has_Transform::get_transform_store(world)
    .get(ball)
    .unwrap().translation.y

  // Step for ~2 seconds.
  let mut i = 0
  while i < 120 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    @core.ChangeTickWorld::increment_change_tick(world) |> ignore
    i = i + 1
  }
  let final_y = @math.Has_Transform::get_transform_store(world)
    .get(ball)
    .unwrap().translation.y
  inspect(final_y < initial_y, content="true")
  let events = HasRes_Physics2dEvents::get_physics2d_events_resource(world)
    .get_ref()
    .unwrap().val
  inspect(events.collisions.length() > 0, content="true")
  inspect(events.contact_forces.length() > 0, content="true")
}

///|
test "physics2d: gravity scale 0 disables gravity" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, -100.0F))
  let no_grav = @core.Entity::new(0, 1)
  let grav = @core.Entity::new(1, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    no_grav,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  @math.Has_Transform::get_transform_store(world).insert(
    grav,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    no_grav,
    RigidBody2d::dynamic(),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    grav,
    RigidBody2d::dynamic(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    no_grav,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    grav,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_GravityScale2d::get_gravity_scale2d_store(world).insert(
    no_grav,
    GravityScale2d::new(0.0F),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    no_grav,
    Velocity2d::zero(),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    grav,
    Velocity2d::zero(),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let y0 = @math.Has_Transform::get_transform_store(world).get(no_grav).unwrap().translation.y
  let y1 = @math.Has_Transform::get_transform_store(world).get(grav).unwrap().translation.y
  let mut i = 0
  while i < 60 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    @core.ChangeTickWorld::increment_change_tick(world) |> ignore
    i = i + 1
  }
  // Debug (kept): this test asserts semantics via positions; keep the following
  // assertions focused and avoid relying on exact floating-point equality.
  let y0_final = @math.Has_Transform::get_transform_store(world)
    .get(no_grav)
    .unwrap().translation.y
  let y1_final = @math.Has_Transform::get_transform_store(world)
    .get(grav)
    .unwrap().translation.y
  inspect(y0_final > y0 - 0.01F, content="true")
  inspect(y1_final < y1, content="true")
}

///|
test "physics2d: damping reduces velocity" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let no_damp = @core.Entity::new(0, 1)
  let damp = @core.Entity::new(1, 1)
  for e in [no_damp, damp] {
    @math.Has_Transform::get_transform_store(world).insert(
      e,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    Has_RigidBody2d::get_rigid_body2d_store(world).insert(
      e,
      RigidBody2d::dynamic(),
      tick,
    )
    Has_Collider2d::get_collider2d_store(world).insert(
      e,
      Collider2d::new(ColliderShape2d::ball(0.2F)),
      tick,
    )
    Has_Velocity2d::get_velocity2d_store(world).insert(
      e,
      Velocity2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
      tick,
    )
  }
  Has_Damping2d::get_damping2d_store(world).insert(
    damp,
    Damping2d::new(10.0F, 0.0F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    @core.ChangeTickWorld::increment_change_tick(world) |> ignore
    i = i + 1
  }
  let v_no = Has_Velocity2d::get_velocity2d_store(world).get(no_damp).unwrap().linvel.x
  let v_damp = Has_Velocity2d::get_velocity2d_store(world).get(damp).unwrap().linvel.x
  inspect(v_damp < v_no, content="true")
}

///|
test "physics2d: external impulse applies once and clears" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let e = @core.Entity::new(0, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    e,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    e,
    RigidBody2d::dynamic(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    e,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    e,
    Velocity2d::zero(),
    tick,
  )
  Has_ExternalImpulse2d::get_external_impulse2d_store(world).insert(
    e,
    ExternalImpulse2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let v = Has_Velocity2d::get_velocity2d_store(world).get(e).unwrap()
  inspect(v.linvel.x > 0.0F, content="true")
  let imp = Has_ExternalImpulse2d::get_external_impulse2d_store(world)
    .get(e)
    .unwrap()
  inspect(imp.impulse.x == 0.0F, content="true")
}

///|
test "physics2d: default collider density yields non-zero mass" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let e = @core.Entity::new(0, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    e,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    e,
    RigidBody2d::dynamic(),
    tick,
  )
  // No `ColliderDensity2d` here: this test asserts moon_rapier's default density
  // behaves like upstream Rapier (non-zero mass).
  Has_Collider2d::get_collider2d_store(world).insert(
    e,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    e,
    Velocity2d::zero(),
    tick,
  )
  Has_ExternalImpulse2d::get_external_impulse2d_store(world).insert(
    e,
    ExternalImpulse2d::new(@math.Vec2::new(10.0F, 0.0F), 0.0F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let ctx = HasRes_Physics2dContext::get_physics2d_context_resource(world)
    .get_ref()
    .unwrap().val
  let bh = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(world)
    .get(e)
    .unwrap().handle
  inspect(ctx.rigid_bodies.get(bh).unwrap().inv_mass() > 0.0F, content="true")
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let v = Has_Velocity2d::get_velocity2d_store(world).get(e).unwrap()
  inspect(v.linvel.x > 0.0F, content="true")
}

///|
test "physics2d: external force persists" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let e = @core.Entity::new(0, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    e,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    e,
    RigidBody2d::dynamic(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    e,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    e,
    Velocity2d::zero(),
    tick,
  )
  Has_ExternalForce2d::get_external_force2d_store(world).insert(
    e,
    ExternalForce2d::new(@math.Vec2::new(50.0F, 0.0F), 0.0F),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let x0 = @math.Has_Transform::get_transform_store(world).get(e).unwrap().translation.x
  let mut i = 0
  while i < 30 {
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    @core.ChangeTickWorld::increment_change_tick(world) |> ignore
    i = i + 1
  }
  let x1 = @math.Has_Transform::get_transform_store(world).get(e).unwrap().translation.x
  inspect(x1 > x0, content="true")
}

///|
test "physics2d: CCD prevents tunneling through thin floor" {
  fn run(ccd_enabled : Bool) -> Float {
    @app.fixed_time_reset()
    @app.fixed_time_set_timestep_seconds(1.0F / 10.0F)
    let world = Physics2dTestWorld::new()
    physics2d_init_resources_system(world)
    let tick = @core.ChangeTickWorld::read_change_tick(world)
    HasRes_Physics2dConfig::get_physics2d_config_resource(world)
    .get_ref_mut(tick)
    .unwrap().val
    = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
    let floor = @core.Entity::new(0, 1)
    let ball = @core.Entity::new(1, 1)
    @math.Has_Transform::get_transform_store(world).insert(
      floor,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    Has_RigidBody2d::get_rigid_body2d_store(world).insert(
      floor,
      RigidBody2d::fixed(),
      tick,
    )
    Has_Collider2d::get_collider2d_store(world).insert(
      floor,
      Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.01F)),
      tick,
    )
    @math.Has_Transform::get_transform_store(world).insert(
      ball,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 1.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    Has_RigidBody2d::get_rigid_body2d_store(world).insert(
      ball,
      RigidBody2d::dynamic(),
      tick,
    )
    Has_Collider2d::get_collider2d_store(world).insert(
      ball,
      Collider2d::new(ColliderShape2d::ball(0.01F)),
      tick,
    )
    Has_Velocity2d::get_velocity2d_store(world).insert(
      ball,
      Velocity2d::new(@math.Vec2::new(0.0F, -200.0F), 0.0F),
      tick,
    )
    if ccd_enabled {
      Has_Ccd2d::get_ccd2d_store(world).insert(ball, Ccd2d::enabled(), tick)
    }
    physics2d_sync_insertions_system(world)
    physics2d_sync_world_to_rapier_system(world)
    physics2d_step_system(world)
    physics2d_writeback_system(world)
    @math.Has_Transform::get_transform_store(world).get(ball).unwrap().translation.y
  }

  let y_no_ccd = run(false)
  let y_ccd = run(true)
  inspect(y_no_ccd < -0.5F, content="true")
  inspect(y_ccd > -0.5F, content="true")
}

///|
test "physics2d: collision groups filter collision events" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let a = @core.Entity::new(0, 1)
  let b = @core.Entity::new(1, 1)
  for e in [a, b] {
    @math.Has_Transform::get_transform_store(world).insert(
      e,
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(0.0F, 0.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=0.0F,
      ),
      tick,
    )
    Has_RigidBody2d::get_rigid_body2d_store(world).insert(
      e,
      RigidBody2d::dynamic(),
      tick,
    )
    Has_Collider2d::get_collider2d_store(world).insert(
      e,
      Collider2d::new(ColliderShape2d::ball(0.5F)),
      tick,
    )
    Has_Velocity2d::get_velocity2d_store(world).insert(
      e,
      Velocity2d::zero(),
      tick,
    )
  }
  // Put them in disjoint groups so they never collide.
  Has_CollisionGroups2d::get_collision_groups2d_store(world).insert(
    a,
    CollisionGroups2d::new(1, 1, @dynamics.InteractionTestMode::And),
    tick,
  )
  Has_CollisionGroups2d::get_collision_groups2d_store(world).insert(
    b,
    CollisionGroups2d::new(2, 2, @dynamics.InteractionTestMode::And),
    tick,
  )
  Has_SolverGroups2d::get_solver_groups2d_store(world).insert(
    a,
    SolverGroups2d::new(1, 1, @dynamics.InteractionTestMode::And),
    tick,
  )
  Has_SolverGroups2d::get_solver_groups2d_store(world).insert(
    b,
    SolverGroups2d::new(2, 2, @dynamics.InteractionTestMode::And),
    tick,
  )
  physics2d_clear_events_system(world)
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_step_system(world)
  physics2d_writeback_system(world)
  let events = HasRes_Physics2dEvents::get_physics2d_events_resource(world)
    .get_ref()
    .unwrap().val
  inspect(events.collisions.length() == 0, content="true")
}
