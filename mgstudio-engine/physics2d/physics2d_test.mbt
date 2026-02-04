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
  collider_parent : @core.ComponentStore[ColliderParent2d]
  velocity : @core.ComponentStore[Velocity2d]
  damping : @core.ComponentStore[Damping2d]
  gravity_scale : @core.ComponentStore[GravityScale2d]
  locked_axes : @core.ComponentStore[LockedAxes2d]
  ccd : @core.ComponentStore[Ccd2d]
  dominance : @core.ComponentStore[Dominance2d]
  sleeping : @core.ComponentStore[Sleeping2d]
  external_force : @core.ComponentStore[ExternalForce2d]
  external_impulse : @core.ComponentStore[ExternalImpulse2d]
  rigid_body_enabled : @core.ComponentStore[RigidBodyEnabled2d]
  additional_mass_properties : @core.ComponentStore[AdditionalMassProperties2d]
  additional_solver_iterations : @core.ComponentStore[AdditionalSolverIterations2d]
  contact_force_threshold : @core.ComponentStore[ContactForceEventThreshold2d]
  collider_density : @core.ComponentStore[ColliderDensity2d]
  friction : @core.ComponentStore[Friction2d]
  friction_rule : @core.ComponentStore[FrictionCombineRule2d]
  restitution : @core.ComponentStore[Restitution2d]
  restitution_rule : @core.ComponentStore[RestitutionCombineRule2d]
  collision_groups : @core.ComponentStore[CollisionGroups2d]
  solver_groups : @core.ComponentStore[SolverGroups2d]
  collider_enabled : @core.ComponentStore[ColliderEnabled2d]
  active_collision_types : @core.ComponentStore[ActiveCollisionTypes2d]
  active_events : @core.ComponentStore[ActiveEvents2d]
  active_hooks : @core.ComponentStore[ActiveHooks2d]
  contact_skin : @core.ComponentStore[ContactSkin2d]
  collider_mass_properties : @core.ComponentStore[ColliderMassProperties2d]
  kcc : @core.ComponentStore[KinematicCharacterController2d]
  kcc_output : @core.ComponentStore[KinematicCharacterControllerOutput2d]
  impulse_joint : @core.ComponentStore[ImpulseJoint2d]
  multibody_joint : @core.ComponentStore[MultibodyJoint2d]
  body_handle : @core.ComponentStore[RapierBodyHandle2d]
  collider_handle : @core.ComponentStore[RapierColliderHandle2d]
  impulse_joint_handle : @core.ComponentStore[RapierImpulseJointHandle2d]
  multibody_joint_handle : @core.ComponentStore[RapierMultibodyJointHandle2d]
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
    collider_parent: @core.ComponentStore::new(),
    velocity: @core.ComponentStore::new(),
    damping: @core.ComponentStore::new(),
    gravity_scale: @core.ComponentStore::new(),
    locked_axes: @core.ComponentStore::new(),
    ccd: @core.ComponentStore::new(),
    dominance: @core.ComponentStore::new(),
    sleeping: @core.ComponentStore::new(),
    external_force: @core.ComponentStore::new(),
    external_impulse: @core.ComponentStore::new(),
    rigid_body_enabled: @core.ComponentStore::new(),
    additional_mass_properties: @core.ComponentStore::new(),
    additional_solver_iterations: @core.ComponentStore::new(),
    contact_force_threshold: @core.ComponentStore::new(),
    collider_density: @core.ComponentStore::new(),
    friction: @core.ComponentStore::new(),
    friction_rule: @core.ComponentStore::new(),
    restitution: @core.ComponentStore::new(),
    restitution_rule: @core.ComponentStore::new(),
    collision_groups: @core.ComponentStore::new(),
    solver_groups: @core.ComponentStore::new(),
    collider_enabled: @core.ComponentStore::new(),
    active_collision_types: @core.ComponentStore::new(),
    active_events: @core.ComponentStore::new(),
    active_hooks: @core.ComponentStore::new(),
    contact_skin: @core.ComponentStore::new(),
    collider_mass_properties: @core.ComponentStore::new(),
    kcc: @core.ComponentStore::new(),
    kcc_output: @core.ComponentStore::new(),
    impulse_joint: @core.ComponentStore::new(),
    multibody_joint: @core.ComponentStore::new(),
    body_handle: @core.ComponentStore::new(),
    collider_handle: @core.ComponentStore::new(),
    impulse_joint_handle: @core.ComponentStore::new(),
    multibody_joint_handle: @core.ComponentStore::new(),
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
impl Has_ColliderParent2d for Physics2dTestWorld with get_collider_parent2d_store(
  self,
) {
  self.collider_parent
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
impl Has_RigidBodyEnabled2d for Physics2dTestWorld with get_rigid_body_enabled2d_store(
  self,
) {
  self.rigid_body_enabled
}

///|
impl Has_AdditionalMassProperties2d for Physics2dTestWorld with get_additional_mass_properties2d_store(
  self,
) {
  self.additional_mass_properties
}

///|
impl Has_AdditionalSolverIterations2d for Physics2dTestWorld with get_additional_solver_iterations2d_store(
  self,
) {
  self.additional_solver_iterations
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
impl Has_ColliderEnabled2d for Physics2dTestWorld with get_collider_enabled2d_store(
  self,
) {
  self.collider_enabled
}

///|
impl Has_ActiveCollisionTypes2d for Physics2dTestWorld with get_active_collision_types2d_store(
  self,
) {
  self.active_collision_types
}

///|
impl Has_ActiveEvents2d for Physics2dTestWorld with get_active_events2d_store(
  self,
) {
  self.active_events
}

///|
impl Has_ActiveHooks2d for Physics2dTestWorld with get_active_hooks2d_store(self) {
  self.active_hooks
}

///|
impl Has_ContactSkin2d for Physics2dTestWorld with get_contact_skin2d_store(self) {
  self.contact_skin
}

///|
impl Has_ColliderMassProperties2d for Physics2dTestWorld with get_collider_mass_properties2d_store(
  self,
) {
  self.collider_mass_properties
}

///|
impl Has_KinematicCharacterController2d for Physics2dTestWorld with get_kinematic_character_controller2d_store(
  self,
) {
  self.kcc
}

///|
impl Has_KinematicCharacterControllerOutput2d for Physics2dTestWorld with get_kinematic_character_controller_output2d_store(
  self,
) {
  self.kcc_output
}

///|
impl Has_ImpulseJoint2d for Physics2dTestWorld with get_impulse_joint2d_store(
  self,
) {
  self.impulse_joint
}

///|
impl Has_MultibodyJoint2d for Physics2dTestWorld with get_multibody_joint2d_store(
  self,
) {
  self.multibody_joint
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
impl Has_RapierImpulseJointHandle2d for Physics2dTestWorld with get_rapier_impulse_joint_handle2d_store(
  self,
) {
  self.impulse_joint_handle
}

///|
impl Has_RapierMultibodyJointHandle2d for Physics2dTestWorld with get_rapier_multibody_joint_handle2d_store(
  self,
) {
  self.multibody_joint_handle
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

///|
test "physics2d: query pipeline sees inserted colliders" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let floor = @core.Entity::new(0, 1)
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
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let ctx = HasRes_Physics2dContext::get_physics2d_context_resource(world)
    .get_ref()
    .unwrap().val
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
    @math.Rect::new(
      @math.Vec2::new(-1.0F, -1.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ),
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
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))

  let convex = @core.Entity::new(10, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    convex,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(5.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    convex,
    RigidBody2d::fixed(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
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

  let compound = @core.Entity::new(11, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    compound,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-5.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    compound,
    RigidBody2d::fixed(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
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
  let ctx = HasRes_Physics2dContext::get_physics2d_context_resource(world)
    .get_ref()
    .unwrap().val

  let hits1 = ctx.intersect_aabb_entities_conservative(
    @math.Rect::new(
      @math.Vec2::new(4.0F, -2.0F),
      @math.Vec2::new(6.0F, 2.0F),
    ),
  )
  let mut has_convex = false
  for e in hits1 {
    if e.id == convex.id { has_convex = true }
  }
  inspect(has_convex, content="true")

  let hits2 = ctx.intersect_aabb_entities_conservative(
    @math.Rect::new(
      @math.Vec2::new(-6.0F, -2.0F),
      @math.Vec2::new(-4.0F, 2.0F),
    ),
  )
  let mut has_compound = false
  for e in hits2 {
    if e.id == compound.id { has_compound = true }
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

  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))

  let a = @core.Entity::new(20, 1)
  let b = @core.Entity::new(21, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    a,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-0.49F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  @math.Has_Transform::get_transform_store(world).insert(
    b,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.49F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(a, RigidBody2d::dynamic(), tick)
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(b, RigidBody2d::dynamic(), tick)
  Has_Collider2d::get_collider2d_store(world).insert(
    a,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    b,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    a,
    Velocity2d::new(@math.Vec2::new(1.0F, 0.0F), 0.0F),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    b,
    Velocity2d::new(@math.Vec2::new(-1.0F, 0.0F), 0.0F),
    tick,
  )
  Has_ActiveHooks2d::get_active_hooks2d_store(world).insert(
    a,
    ActiveHooks2d::new(@collision.ActiveHooks::filter_contact_pairs()),
    tick,
  )
  Has_ActiveHooks2d::get_active_hooks2d_store(world).insert(
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
  let events = HasRes_Physics2dEvents::get_physics2d_events_resource(world)
    .get_ref()
    .unwrap().val
  inspect(events.collisions.length() == 0, content="true")

  physics2d_hooks_set_config(old_hooks)
}

///|
test "physics2d: impulse joint is inserted and cleaned up" {
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
  @math.Has_Transform::get_transform_store(world).insert(
    a,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    a,
    RigidBody2d::dynamic(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    a,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    a,
    Velocity2d::zero(),
    tick,
  )
  @math.Has_Transform::get_transform_store(world).insert(
    b,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    b,
    RigidBody2d::dynamic(),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    b,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_Velocity2d::get_velocity2d_store(world).insert(
    b,
    Velocity2d::zero(),
    tick,
  )
  let fixed = @dynamics.FixedJointBuilder::new().build()
  let data = @dynamics.GenericJoint::from_fixed(fixed)
  Has_ImpulseJoint2d::get_impulse_joint2d_store(world).insert(
    a,
    ImpulseJoint2d::new(b, data),
    tick,
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_joints_system(world)
  let ctx = HasRes_Physics2dContext::get_physics2d_context_resource(world)
    .get_ref()
    .unwrap().val
  inspect(ctx.impulse_joints.len() == 1, content="true")
  inspect(
    Has_RapierImpulseJointHandle2d::get_rapier_impulse_joint_handle2d_store(
      world,
    ).contains(a),
    content="true",
  )

  // Remove authoring component and verify cleanup removes the Rapier joint.
  Has_ImpulseJoint2d::get_impulse_joint2d_store(world).remove(a) |> ignore
  physics2d_cleanup_despawned_system(world)
  inspect(ctx.impulse_joints.len() == 0, content="true")
  inspect(
    !Has_RapierImpulseJointHandle2d::get_rapier_impulse_joint_handle2d_store(
      world,
    ).contains(a),
    content="true",
  )
}

///|
test "physics2d: child collider attaches to parent body" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let body = @core.Entity::new(0, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    body,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_RigidBody2d::get_rigid_body2d_store(world).insert(
    body,
    RigidBody2d::dynamic(),
    tick,
  )
  let child = @core.Entity::new(1, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    child,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(1.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    child,
    Collider2d::new(ColliderShape2d::ball(0.2F)),
    tick,
  )
  Has_ColliderParent2d::get_collider_parent2d_store(world).insert(
    child,
    ColliderParent2d::new(body),
    tick,
  )
  physics2d_sync_insertions_system(world)
  let ctx = HasRes_Physics2dContext::get_physics2d_context_resource(world)
    .get_ref()
    .unwrap().val
  let bh = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(world)
    .get(body)
    .unwrap().handle
  let ch = Has_RapierColliderHandle2d::get_rapier_collider_handle2d_store(world)
    .get(child)
    .unwrap().handle
  let collider = ctx.colliders.get(ch).unwrap()
  inspect(
    collider.parent().unwrap().into_raw_parts() == bh.into_raw_parts(),
    content="true",
  )
  let rel = collider.position_wrt_parent().unwrap()
  inspect(rel.translation.x == 1.0F, content="true")
}

///|
test "physics2d: kinematic character controller moves and outputs" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics2dTestWorld::new()
  physics2d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  .get_ref_mut(tick)
  .unwrap().val
  = Physics2dConfig::new(@math.Vec2::new(0.0F, 0.0F))
  let floor = @core.Entity::new(0, 1)
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
    Collider2d::new(ColliderShape2d::cuboid(10.0F, 0.5F)),
    tick,
  )
  let character = @core.Entity::new(1, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    character,
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, 2.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
    tick,
  )
  Has_Collider2d::get_collider2d_store(world).insert(
    character,
    Collider2d::new(ColliderShape2d::ball(0.5F)),
    tick,
  )
  Has_KinematicCharacterController2d::get_kinematic_character_controller2d_store(
    world,
  ).insert(
    character,
    KinematicCharacterController2d::default().with_translation(
      @math.Vec2::new(0.0F, -2.0F),
    ),
    tick,
  )
  physics2d_sync_insertions_system(world)
  physics2d_sync_world_to_rapier_system(world)
  physics2d_character_controller_system(world)
  let y = @math.Has_Transform::get_transform_store(world)
    .get(character)
    .unwrap().translation.y
  inspect(y > 0.9F, content="true")
  let kcc_after = Has_KinematicCharacterController2d::get_kinematic_character_controller2d_store(
      world,
    )
    .get(character)
    .unwrap()
  inspect(kcc_after.translation.y == 0.0F, content="true")
  let out = Has_KinematicCharacterControllerOutput2d::get_kinematic_character_controller_output2d_store(
      world,
    )
    .get(character)
    .unwrap()
  inspect(out.effective_translation.y <= 0.0F, content="true")
  inspect(out.collisions.length() > 0, content="true")
}
