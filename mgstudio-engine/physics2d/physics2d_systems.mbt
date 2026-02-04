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
/// Systems for Physics2D integration.

///|
fn entity_key(e : @core.Entity) -> (Int, Int) {
  (e.id, e.generation)
}

///|
fn update_transform_from_iso2(
  current : @math.Transform,
  iso : @rapier_core.Isometry2,
) -> @math.Transform {
  let angle = iso.rotation.angle()
  @math.Transform::new(
    @math.Vec3::new(iso.translation.x, iso.translation.y, current.translation.z),
    @math.Quat::from_rotation_z(angle),
    current.scale,
  )
}

///|
fn make_collider_builder(shape : ColliderShape2d) -> @collision.ColliderBuilder {
  match shape {
    Ball(radius) => @collision.ColliderBuilder::ball(radius)
    Cuboid(hx, hy) => @collision.ColliderBuilder::cuboid(hx, hy)
    CapsuleX(half_height, radius) =>
      @collision.ColliderBuilder::capsule_x(half_height, radius)
    CapsuleY(half_height, radius) =>
      @collision.ColliderBuilder::capsule_y(half_height, radius)
    Segment(a, b) =>
      @collision.ColliderBuilder::segment(
        mg_vec2_to_rapier(a),
        mg_vec2_to_rapier(b),
      )
  }
}

///|
fn rigid_body_type_eq(
  a : @dynamics.RigidBodyType,
  b : @dynamics.RigidBodyType,
) -> Bool {
  match (a, b) {
    (@dynamics.RigidBodyType::Dynamic, @dynamics.RigidBodyType::Dynamic) => true
    (@dynamics.RigidBodyType::Fixed, @dynamics.RigidBodyType::Fixed) => true
    (
      @dynamics.RigidBodyType::KinematicPositionBased,
      @dynamics.RigidBodyType::KinematicPositionBased,
    ) => true
    (
      @dynamics.RigidBodyType::KinematicVelocityBased,
      @dynamics.RigidBodyType::KinematicVelocityBased,
    ) => true
    _ => false
  }
}

///|
fn collision_groups_to_rapier(
  groups : CollisionGroups2d,
) -> @dynamics.InteractionGroups {
  @dynamics.InteractionGroups::new(
    @dynamics.Group::new(groups.memberships),
    @dynamics.Group::new(groups.filter),
    groups.test_mode,
  )
}

///|
fn solver_groups_to_rapier(
  groups : SolverGroups2d,
) -> @dynamics.InteractionGroups {
  @dynamics.InteractionGroups::new(
    @dynamics.Group::new(groups.memberships),
    @dynamics.Group::new(groups.filter),
    groups.test_mode,
  )
}

///|
pub fn[
  W : @core.ChangeTickWorld + HasRes_Physics2dConfig + HasRes_Physics2dContext + HasRes_Physics2dEvents,
] physics2d_init_resources_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  if !cfg_res.is_present() {
    cfg_res.insert(Physics2dConfig::default(), tick)
  }
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  if !ctx_res.is_present() {
    ctx_res.insert(Physics2dContext::new(), tick)
  }
  let ev_res = HasRes_Physics2dEvents::get_physics2d_events_resource(world)
  if !ev_res.is_present() {
    ev_res.insert(Physics2dEvents::new(), tick)
  }
}

///|
pub fn[W : @core.ChangeTickWorld + HasRes_Physics2dEvents] physics2d_clear_events_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ev_res = HasRes_Physics2dEvents::get_physics2d_events_resource(world)
  match ev_res.get_ref_mut(tick) {
    Some(r) => r.val.clear()
    None => ()
  }
}

///|
pub fn[
  W : @core.ChangeTickWorld + Has_RigidBody2d + Has_Collider2d + Has_ImpulseJoint2d + Has_MultibodyJoint2d + Has_RapierBodyHandle2d + Has_RapierColliderHandle2d + Has_RapierImpulseJointHandle2d + Has_RapierMultibodyJointHandle2d + HasRes_Physics2dContext,
] physics2d_cleanup_despawned_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let rb_store = Has_RigidBody2d::get_rigid_body2d_store(world)
  let col_store = Has_Collider2d::get_collider2d_store(world)
  let impulse_joint_store = Has_ImpulseJoint2d::get_impulse_joint2d_store(world)
  let multibody_joint_store = Has_MultibodyJoint2d::get_multibody_joint2d_store(
    world,
  )
  let body_handle_store = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(
    world,
  )
  let collider_handle_store = Has_RapierColliderHandle2d::get_rapier_collider_handle2d_store(
    world,
  )
  let impulse_joint_handle_store = Has_RapierImpulseJointHandle2d::get_rapier_impulse_joint_handle2d_store(
    world,
  )
  let multibody_joint_handle_store = Has_RapierMultibodyJointHandle2d::get_rapier_multibody_joint_handle2d_store(
    world,
  )

  // 1) Remove handles/rapier state when the authoring component is removed.
  let remove_bodies : Array[@core.Entity] = []
  body_handle_store.for_each(fn(e, _h) {
    if !rb_store.contains(e) {
      remove_bodies.push(e)
    }
  })
  for e in remove_bodies {
    if body_handle_store.get(e) is Some(h) {
      // Remove and detach all colliders attached to this body (including
      // colliders authored by other entities).
      let attached = ctx.colliders.colliders_with_parent(h.handle)
      for ch in attached {
        let raw = ch.into_raw_parts()
        if ctx.collider_to_entity.get(raw) is Some(owner) {
          collider_handle_store.remove(owner) |> ignore
          ctx.entity_to_collider.remove(entity_key(owner))
          ctx.collider_to_entity.remove(raw)
        }
      }

      @pipeline.remove_rigid_body(
        ctx.rigid_bodies,
        h.handle,
        ctx.islands,
        ctx.colliders,
        ctx.impulse_joints,
        ctx.multibody_joints,
        true,
        true,
      )
      |> ignore
      body_handle_store.remove(e) |> ignore
      ctx.entity_to_body.remove(entity_key(e))

      // If this entity also authored a collider, the collider was removed by
      // `remove_rigid_body`. Drop the handle so it can be reinserted as a
      // standalone collider (if Collider2d still exists).
      if collider_handle_store.get(e) is Some(ch) {
        collider_handle_store.remove(e) |> ignore
        ctx.entity_to_collider.remove(entity_key(e))
        ctx.collider_to_entity.remove(ch.handle.into_raw_parts())
      }

      // Drop joint handles authored by this entity; `remove_rigid_body` removes
      // all attached joints in Rapier.
      if impulse_joint_handle_store.get(e) is Some(jh) {
        impulse_joint_handle_store.remove(e) |> ignore
        ctx.entity_to_impulse_joint.remove(entity_key(e))
        // Best-effort remove: the joint may already be gone.
        ctx.impulse_joints.remove(jh.handle, true) |> ignore
      }
      if multibody_joint_handle_store.get(e) is Some(jh) {
        multibody_joint_handle_store.remove(e) |> ignore
        ctx.entity_to_multibody_joint.remove(entity_key(e))
        ctx.multibody_joints.remove(jh.handle, true)
      }
    }
  }
  let remove_colliders : Array[@core.Entity] = []
  collider_handle_store.for_each(fn(e, _h) {
    if !col_store.contains(e) {
      remove_colliders.push(e)
    }
  })
  for e in remove_colliders {
    if collider_handle_store.get(e) is Some(h) {
      ctx.colliders.remove(h.handle, ctx.islands, ctx.rigid_bodies, true)
      |> ignore
      collider_handle_store.remove(e) |> ignore
      ctx.entity_to_collider.remove(entity_key(e))
      ctx.collider_to_entity.remove(h.handle.into_raw_parts())
    }
  }

  // Remove joints when the authoring component is removed or bodies are missing.
  let remove_impulse_joints : Array[@core.Entity] = []
  impulse_joint_handle_store.for_each(fn(e, _h) {
    if !impulse_joint_store.contains(e) || !body_handle_store.contains(e) {
      remove_impulse_joints.push(e)
    }
  })
  for e in remove_impulse_joints {
    if impulse_joint_handle_store.get(e) is Some(h) {
      ctx.impulse_joints.remove(h.handle, true) |> ignore
      impulse_joint_handle_store.remove(e) |> ignore
      ctx.entity_to_impulse_joint.remove(entity_key(e))
    }
  }
  let remove_multibody_joints : Array[@core.Entity] = []
  multibody_joint_handle_store.for_each(fn(e, _h) {
    if !multibody_joint_store.contains(e) || !body_handle_store.contains(e) {
      remove_multibody_joints.push(e)
    }
  })
  for e in remove_multibody_joints {
    if multibody_joint_handle_store.get(e) is Some(h) {
      ctx.multibody_joints.remove(h.handle, true)
      multibody_joint_handle_store.remove(e) |> ignore
      ctx.entity_to_multibody_joint.remove(entity_key(e))
    }
  }

  // 2) Remove rapier state when entities are despawned (handle components gone).
  let alive : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  body_handle_store.for_each(fn(e, _h) { alive.set(entity_key(e), true) })
  collider_handle_store.for_each(fn(e, _h) { alive.set(entity_key(e), true) })
  impulse_joint_handle_store.for_each(fn(e, _h) {
    alive.set(entity_key(e), true)
  })
  multibody_joint_handle_store.for_each(fn(e, _h) {
    alive.set(entity_key(e), true)
  })
  let dead_body_keys : Array[(Int, Int)] = []
  for entry in ctx.entity_to_body.iter() {
    let (k, _h) = entry
    if !alive.contains(k) {
      dead_body_keys.push(k)
    }
  }
  for k in dead_body_keys {
    if ctx.entity_to_body.get(k) is Some(handle) {
      // Remove and detach all colliders attached to this body (including
      // colliders authored by other entities).
      let attached = ctx.colliders.colliders_with_parent(handle)
      for ch in attached {
        let raw = ch.into_raw_parts()
        if ctx.collider_to_entity.get(raw) is Some(owner) {
          collider_handle_store.remove(owner) |> ignore
          ctx.entity_to_collider.remove(entity_key(owner))
          ctx.collider_to_entity.remove(raw)
        }
      }

      @pipeline.remove_rigid_body(
        ctx.rigid_bodies,
        handle,
        ctx.islands,
        ctx.colliders,
        ctx.impulse_joints,
        ctx.multibody_joints,
        true,
        true,
      )
      |> ignore
      ctx.entity_to_body.remove(k)
    }
  }
  let dead_collider_keys : Array[(Int, Int)] = []
  for entry in ctx.entity_to_collider.iter() {
    let (k, _h) = entry
    if !alive.contains(k) {
      dead_collider_keys.push(k)
    }
  }
  for k in dead_collider_keys {
    if ctx.entity_to_collider.get(k) is Some(handle) {
      ctx.colliders.remove(handle, ctx.islands, ctx.rigid_bodies, true)
      |> ignore
      ctx.entity_to_collider.remove(k)
      ctx.collider_to_entity.remove(handle.into_raw_parts())
    }
  }
  let dead_impulse_joint_keys : Array[(Int, Int)] = []
  for entry in ctx.entity_to_impulse_joint.iter() {
    let (k, _h) = entry
    if !alive.contains(k) {
      dead_impulse_joint_keys.push(k)
    }
  }
  for k in dead_impulse_joint_keys {
    if ctx.entity_to_impulse_joint.get(k) is Some(handle) {
      ctx.impulse_joints.remove(handle, true) |> ignore
      ctx.entity_to_impulse_joint.remove(k)
    }
  }
  let dead_multibody_joint_keys : Array[(Int, Int)] = []
  for entry in ctx.entity_to_multibody_joint.iter() {
    let (k, _h) = entry
    if !alive.contains(k) {
      dead_multibody_joint_keys.push(k)
    }
  }
  for k in dead_multibody_joint_keys {
    if ctx.entity_to_multibody_joint.get(k) is Some(handle) {
      ctx.multibody_joints.remove(handle, true)
      ctx.entity_to_multibody_joint.remove(k)
    }
  }

  // Keep query pipeline in sync with removals.
  ctx.query_pipeline.update()
}

///|
pub fn[
  W : @core.ChangeTickWorld + @math.Has_Transform + Has_RigidBody2d + Has_Collider2d + Has_ColliderParent2d + Has_Velocity2d + Has_Damping2d + Has_GravityScale2d + Has_LockedAxes2d + Has_Ccd2d + Has_Dominance2d + Has_Sleeping2d + Has_ExternalForce2d + Has_ExternalImpulse2d + Has_ContactForceEventThreshold2d + Has_ColliderDensity2d + Has_Friction2d + Has_FrictionCombineRule2d + Has_Restitution2d + Has_RestitutionCombineRule2d + Has_CollisionGroups2d + Has_SolverGroups2d + Has_RapierBodyHandle2d + Has_RapierColliderHandle2d + HasRes_Physics2dContext,
] physics2d_sync_insertions_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let vel_store = Has_Velocity2d::get_velocity2d_store(world)
  let damping_store = Has_Damping2d::get_damping2d_store(world)
  let gravity_scale_store = Has_GravityScale2d::get_gravity_scale2d_store(world)
  let locked_axes_store = Has_LockedAxes2d::get_locked_axes2d_store(world)
  let ccd_store = Has_Ccd2d::get_ccd2d_store(world)
  let dominance_store = Has_Dominance2d::get_dominance2d_store(world)
  let sleeping_store = Has_Sleeping2d::get_sleeping2d_store(world)
  let contact_force_threshold_store = Has_ContactForceEventThreshold2d::get_contact_force_event_threshold2d_store(
    world,
  )
  let density_store = Has_ColliderDensity2d::get_collider_density2d_store(world)
  let friction_store = Has_Friction2d::get_friction2d_store(world)
  let friction_rule_store = Has_FrictionCombineRule2d::get_friction_combine_rule2d_store(
    world,
  )
  let restitution_store = Has_Restitution2d::get_restitution2d_store(world)
  let restitution_rule_store = Has_RestitutionCombineRule2d::get_restitution_combine_rule2d_store(
    world,
  )
  let collision_groups_store = Has_CollisionGroups2d::get_collision_groups2d_store(
    world,
  )
  let solver_groups_store = Has_SolverGroups2d::get_solver_groups2d_store(world)
  let rb_store = Has_RigidBody2d::get_rigid_body2d_store(world)
  let col_store = Has_Collider2d::get_collider2d_store(world)
  let col_parent_store = Has_ColliderParent2d::get_collider_parent2d_store(world)
  let body_handle_store = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(
    world,
  )
  let collider_handle_store = Has_RapierColliderHandle2d::get_rapier_collider_handle2d_store(
    world,
  )

  // Insert rigid bodies.
  rb_store.for_each(fn(entity, rb2d) {
    if body_handle_store.contains(entity) {
      return
    }
    let transform = transform_store
      .get(entity)
      .unwrap_or(@math.Transform::identity())
    let iso = mg_transform_to_iso2(transform)
    let builder = match rb2d.body_type {
      @dynamics.RigidBodyType::Dynamic => @dynamics.RigidBodyBuilder::dynamic()
      @dynamics.RigidBodyType::Fixed => @dynamics.RigidBodyBuilder::fixed()
      @dynamics.RigidBodyType::KinematicPositionBased =>
        @dynamics.RigidBodyBuilder::kinematic_position_based()
      @dynamics.RigidBodyType::KinematicVelocityBased =>
        @dynamics.RigidBodyBuilder::kinematic_velocity_based()
    }
    let mut builder = builder.position(iso)
    if vel_store.get(entity) is Some(v) {
      builder = builder.linvel(mg_vec2_to_rapier(v.linvel)).angvel(v.angvel)
    }
    if damping_store.get(entity) is Some(d) {
      builder = builder.linear_damping(d.linear).angular_damping(d.angular)
    }
    if gravity_scale_store.get(entity) is Some(gs) {
      builder = builder.gravity_scale(gs.scale)
    }
    if locked_axes_store.get(entity) is Some(la) {
      if la.lock_translations {
        builder = builder.lock_translations()
      }
      if la.lock_rotations {
        builder = builder.lock_rotations()
      }
    }
    if ccd_store.get(entity) is Some(ccd) {
      builder = builder
        .ccd_enabled(ccd.enabled)
        .soft_ccd_prediction(ccd.soft_prediction)
    }
    if dominance_store.get(entity) is Some(dom) {
      builder = builder.dominance_group(dom.group)
    }
    if sleeping_store.get(entity) is Some(s) {
      builder = builder.sleeping(s.sleeping)
    }
    let rb = builder.build()
    let handle = ctx.rigid_bodies.insert(rb)
    body_handle_store.insert(entity, RapierBodyHandle2d::new(handle), tick)
    ctx.entity_to_body.set(entity_key(entity), handle)
  })

  // Insert colliders.
  col_store.for_each(fn(entity, col2d) {
    if collider_handle_store.contains(entity) {
      return
    }
    let mut active_events = @collision.ActiveEvents::collision_events()
    let mut builder = make_collider_builder(col2d.shape).sensor(col2d.sensor)
    // No workaround policy: do NOT set a default density here.
    // If moon_rapier defaults are incorrect, users must opt-in via
    // `ColliderDensity2d` until upstream fixes the default behavior.
    if density_store.get(entity) is Some(d) {
      builder = builder.density(d.density)
    }
    if friction_store.get(entity) is Some(f) {
      builder = builder.friction(f.coefficient)
    }
    if friction_rule_store.get(entity) is Some(r) {
      builder = builder.friction_combine_rule(r.rule)
    }
    if restitution_store.get(entity) is Some(r) {
      builder = builder.restitution(r.coefficient)
    }
    if restitution_rule_store.get(entity) is Some(r) {
      builder = builder.restitution_combine_rule(r.rule)
    }
    if collision_groups_store.get(entity) is Some(g) {
      builder = builder.collision_groups(collision_groups_to_rapier(g))
    }
    if solver_groups_store.get(entity) is Some(g) {
      builder = builder.solver_groups(solver_groups_to_rapier(g))
    }
    if contact_force_threshold_store.get(entity) is Some(th) {
      active_events = active_events.insert(
        @collision.ActiveEvents::contact_force_events(),
      )
      builder = builder.contact_force_event_threshold(th.threshold)
    }
    builder = builder.active_events(active_events).user_data(entity.id)
    let handle = match body_handle_store.get(entity) {
      Some(bodyh) => {
        let collider = builder.build()
        // moon_rapier currently doesn't recompute body mass properties when
        // attaching colliders. For now (v1 assumes one collider per entity),
        // set the body's local mass properties from the attached collider so
        // impulses/forces work immediately.
        let mprops = collider.mass_properties()
        let handle = ctx.colliders.insert_with_parent(
          collider,
          bodyh.handle,
          ctx.rigid_bodies,
        )
        if ctx.rigid_bodies.get_mut_internal_with_modification_tracking(
            bodyh.handle,
          )
          is Some(body) {
          body.set_local_mass_properties(mprops) |> ignore
        }
        handle
      }
      None => {
        match col_parent_store.get(entity) {
          Some(p) =>
            match body_handle_store.get(p.parent) {
              Some(parent_bh) => {
                let transform = transform_store
                  .get(entity)
                  .unwrap_or(@math.Transform::identity())
                let iso = mg_transform_to_iso2(transform)
                let collider = builder
                  .translation(iso.translation)
                  .rotation(iso.rotation.angle())
                  .build()
                ctx.colliders.insert_with_parent(
                  collider,
                  parent_bh.handle,
                  ctx.rigid_bodies,
                )
              }
              None => {
                let transform = transform_store
                  .get(entity)
                  .unwrap_or(@math.Transform::identity())
                let iso = mg_transform_to_iso2(transform)
                let collider = builder
                  .translation(iso.translation)
                  .rotation(iso.rotation.angle())
                  .build()
                ctx.colliders.insert(collider)
              }
            }
          None => {
            let transform = transform_store
              .get(entity)
              .unwrap_or(@math.Transform::identity())
            let iso = mg_transform_to_iso2(transform)
            let collider = builder
              .translation(iso.translation)
              .rotation(iso.rotation.angle())
              .build()
            ctx.colliders.insert(collider)
          }
        }
      }
    }
    collider_handle_store.insert(
      entity,
      RapierColliderHandle2d::new(handle),
      tick,
    )
    ctx.entity_to_collider.set(entity_key(entity), handle)
    ctx.collider_to_entity.set(handle.into_raw_parts(), entity)
  })

  // Keep query pipeline in sync with insertions.
  ctx.query_pipeline.update()
}

///|
pub fn[
  W : @core.ChangeTickWorld + @math.Has_Transform + Has_RigidBody2d + Has_Collider2d + Has_ColliderParent2d + Has_Velocity2d + Has_Damping2d + Has_GravityScale2d + Has_LockedAxes2d + Has_Ccd2d + Has_Dominance2d + Has_Sleeping2d + Has_ExternalForce2d + Has_ExternalImpulse2d + Has_ContactForceEventThreshold2d + Has_ColliderDensity2d + Has_Friction2d + Has_FrictionCombineRule2d + Has_Restitution2d + Has_RestitutionCombineRule2d + Has_CollisionGroups2d + Has_SolverGroups2d + Has_RapierBodyHandle2d + Has_RapierColliderHandle2d + HasRes_Physics2dContext,
] physics2d_sync_world_to_rapier_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let dt = @app.fixed_time_timestep_seconds()
  ctx.integration = ctx.integration.set_dt(dt)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let rb2d_store = Has_RigidBody2d::get_rigid_body2d_store(world)
  let col2d_store = Has_Collider2d::get_collider2d_store(world)
  let col_parent_store = Has_ColliderParent2d::get_collider_parent2d_store(world)
  let vel_store = Has_Velocity2d::get_velocity2d_store(world)
  let damping_store = Has_Damping2d::get_damping2d_store(world)
  let gravity_scale_store = Has_GravityScale2d::get_gravity_scale2d_store(world)
  let locked_axes_store = Has_LockedAxes2d::get_locked_axes2d_store(world)
  let ccd_store = Has_Ccd2d::get_ccd2d_store(world)
  let dominance_store = Has_Dominance2d::get_dominance2d_store(world)
  let sleeping_store = Has_Sleeping2d::get_sleeping2d_store(world)
  let external_force_store = Has_ExternalForce2d::get_external_force2d_store(
    world,
  )
  let external_impulse_store = Has_ExternalImpulse2d::get_external_impulse2d_store(
    world,
  )
  let contact_force_threshold_store = Has_ContactForceEventThreshold2d::get_contact_force_event_threshold2d_store(
    world,
  )
  let density_store = Has_ColliderDensity2d::get_collider_density2d_store(world)
  let friction_store = Has_Friction2d::get_friction2d_store(world)
  let friction_rule_store = Has_FrictionCombineRule2d::get_friction_combine_rule2d_store(
    world,
  )
  let restitution_store = Has_Restitution2d::get_restitution2d_store(world)
  let restitution_rule_store = Has_RestitutionCombineRule2d::get_restitution_combine_rule2d_store(
    world,
  )
  let collision_groups_store = Has_CollisionGroups2d::get_collision_groups2d_store(
    world,
  )
  let solver_groups_store = Has_SolverGroups2d::get_solver_groups2d_store(world)
  let body_handle_store = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(
    world,
  )
  let collider_handle_store = Has_RapierColliderHandle2d::get_rapier_collider_handle2d_store(
    world,
  )

  // Colliders: update authoring properties and keep standalone colliders
  // (no parent rigid body) following Transform.
  collider_handle_store.for_each(fn(entity, ch) {
    guard ctx.colliders.get_mut_internal_with_modification_tracking(ch.handle)
      is Some(collider) else {
      return
    }
    if col2d_store.get(entity) is Some(col2d) {
      collider.set_sensor(col2d.sensor) |> ignore
    }
    if density_store.get(entity) is Some(d) {
      collider.set_density(d.density) |> ignore
    }
    if friction_store.get(entity) is Some(f) {
      collider.set_friction(f.coefficient) |> ignore
    }
    if friction_rule_store.get(entity) is Some(r) {
      collider.set_friction_combine_rule(r.rule) |> ignore
    }
    if restitution_store.get(entity) is Some(r) {
      collider.set_restitution(r.coefficient) |> ignore
    }
    if restitution_rule_store.get(entity) is Some(r) {
      collider.set_restitution_combine_rule(r.rule) |> ignore
    }
    if collision_groups_store.get(entity) is Some(g) {
      collider.set_collision_groups(collision_groups_to_rapier(g)) |> ignore
    }
    if solver_groups_store.get(entity) is Some(g) {
      collider.set_solver_groups(solver_groups_to_rapier(g)) |> ignore
    }
    if contact_force_threshold_store.get(entity) is Some(th) {
      collider.set_active_events(
        @collision.ActiveEvents::collision_events().insert(
          @collision.ActiveEvents::contact_force_events(),
        ),
      )
      |> ignore
      collider.set_contact_force_event_threshold(th.threshold) |> ignore
    } else {
      collider.set_active_events(@collision.ActiveEvents::collision_events())
      |> ignore
    }
    if body_handle_store.contains(entity) {
      return
    }
    if col_parent_store.get(entity) is Some(p) {
      if body_handle_store.get(p.parent) is Some(_parent_bh) {
        let transform = transform_store
          .get(entity)
          .unwrap_or(@math.Transform::identity())
        collider.set_position_wrt_parent(mg_transform_to_iso2(transform)) |> ignore
        return
      }
    }
    let transform = transform_store
      .get(entity)
      .unwrap_or(@math.Transform::identity())
    collider.set_position(mg_transform_to_iso2(transform)) |> ignore
  })
  body_handle_store.for_each(fn(entity, bh) {
    guard rb2d_store.get(entity) is Some(rb2d) else { return }
    guard ctx.rigid_bodies.get_mut_internal_with_modification_tracking(
        bh.handle,
      )
      is Some(body) else {
      return
    }
    if !rigid_body_type_eq(body.body_type(), rb2d.body_type) {
      body.set_body_type(rb2d.body_type, true) |> ignore
    }

    // Kinematic position-based bodies follow the ECS transform.
    if rb2d.body_type is @dynamics.RigidBodyType::KinematicPositionBased {
      let transform = transform_store
        .get(entity)
        .unwrap_or(@math.Transform::identity())
      let iso = mg_transform_to_iso2(transform)
      body.set_next_kinematic_translation(iso.translation) |> ignore
      body.set_next_kinematic_rotation(iso.rotation) |> ignore
    }

    // Apply user-driven velocity updates.
    if vel_store.get(entity) is Some(v) {
      body.set_linvel(mg_vec2_to_rapier(v.linvel), true) |> ignore
      body.set_angvel(v.angvel, true) |> ignore
    }

    // Bevy-like authoring components.
    let damping = damping_store.get(entity)
    body.set_linear_damping(damping.map(fn(d) { d.linear }).unwrap_or(0.0F))
    |> ignore
    body.set_angular_damping(damping.map(fn(d) { d.angular }).unwrap_or(0.0F))
    |> ignore
    body.set_gravity_scale(
      gravity_scale_store.get(entity).map(fn(g) { g.scale }).unwrap_or(1.0F),
      true,
    )
    |> ignore
    let la = locked_axes_store.get(entity)
    body.set_locked_translations(
      la.map(fn(x) { x.lock_translations }).unwrap_or(false),
      true,
    )
    |> ignore
    body.set_locked_rotations(
      la.map(fn(x) { x.lock_rotations }).unwrap_or(false),
      true,
    )
    |> ignore
    let ccd = ccd_store.get(entity)
    body.enable_ccd(ccd.map(fn(c) { c.enabled }).unwrap_or(false)) |> ignore
    body.set_soft_ccd_prediction(
      ccd.map(fn(c) { c.soft_prediction }).unwrap_or(0.0F),
    )
    |> ignore
    body.set_dominance_group(
      dominance_store.get(entity).map(fn(d) { d.group }).unwrap_or(0),
    )
    |> ignore
    match sleeping_store.get(entity) {
      Some(s) =>
        if s.sleeping {
          body.sleep() |> ignore
        } else {
          body.wake_up(true) |> ignore
        }
      None => ()
    }

    // External forces (persistent, applied each fixed step).
    if external_force_store.get(entity) is Some(f) {
      body.add_force(mg_vec2_to_rapier(f.force), true) |> ignore
      body.add_torque(f.torque, true) |> ignore
    }

    // External impulses (one-shot, cleared after application).
    if external_impulse_store.get(entity) is Some(imp) {
      if imp.impulse.x != 0.0F || imp.impulse.y != 0.0F {
        body.apply_impulse(mg_vec2_to_rapier(imp.impulse), true) |> ignore
      }
      if imp.torque_impulse != 0.0F {
        body.apply_torque_impulse(imp.torque_impulse, true) |> ignore
      }
      external_impulse_store.set(entity, ExternalImpulse2d::zero(), tick)
      |> ignore
    }
  })

  // Keep query pipeline in sync with any transform/authoring changes.
  ctx.query_pipeline.update()
}

///|
pub fn[
  W : @core.ChangeTickWorld + HasRes_Physics2dConfig + HasRes_Physics2dContext + HasRes_Physics2dEvents,
] physics2d_step_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = HasRes_Physics2dConfig::get_physics2d_config_resource(world)
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  let ev_res = HasRes_Physics2dEvents::get_physics2d_events_resource(world)
  guard cfg_res.get_ref() is Some(cfg_ref) else { return }
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  guard ev_res.get_ref_mut(tick) is Some(ev_ref) else { return }
  let cfg = cfg_ref.val
  let ctx = ctx_ref.val
  let events = ev_ref.val
  let gravity = mg_vec2_to_rapier(cfg.gravity)
  ctx.pipeline.step(
    gravity,
    ctx.integration,
    ctx.islands,
    ctx.broad_phase,
    ctx.narrow_phase,
    ctx.rigid_bodies,
    ctx.colliders,
    ctx.impulse_joints,
    ctx.multibody_joints,
    ctx.ccd,
    ctx.hooks,
    ctx.event_handler,
  )
  let rapier_events = ctx.event_handler.take_collision_events()
  for ev in rapier_events {
    if ev.removed() {
      continue
    }
    let h1 = ev.collider1()
    let h2 = ev.collider2()
    let e1 = ctx.collider_to_entity.get(h1.into_raw_parts())
    let e2 = ctx.collider_to_entity.get(h2.into_raw_parts())
    match (e1, e2) {
      (Some(a), Some(b)) => {
        let sensor = ev.sensor()
        if ev.started() {
          events.collisions.push(CollisionEvent2d::Started(a, b, sensor))
        } else if ev.stopped() {
          events.collisions.push(CollisionEvent2d::Stopped(a, b, sensor))
        }
      }
      _ => ()
    }
  }
  let rapier_contact_force_events = ctx.event_handler.take_contact_force_events()
  for ev in rapier_contact_force_events {
    let h1 = ev.collider1()
    let h2 = ev.collider2()
    let e1 = ctx.collider_to_entity.get(h1.into_raw_parts())
    let e2 = ctx.collider_to_entity.get(h2.into_raw_parts())
    match (e1, e2) {
      (Some(a), Some(b)) =>
        events.contact_forces.push(ContactForceEvent2d::{
          entity1: a,
          entity2: b,
          total_force: rapier_vec2_to_mg(ev.total_force()),
          total_force_magnitude: ev.total_force_magnitude(),
          max_force_direction: rapier_vec2_to_mg(ev.max_force_direction()),
          max_force_magnitude: ev.max_force_magnitude(),
        })
      _ => ()
    }
  }

  // Update query pipeline after stepping so queries see current positions.
  ctx.query_pipeline.update()
}

///|
pub fn[
  W : @core.ChangeTickWorld + @math.Has_Transform + Has_Velocity2d + Has_RapierBodyHandle2d + HasRes_Physics2dContext,
] physics2d_writeback_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  guard ctx_res.get_ref() is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let vel_store = Has_Velocity2d::get_velocity2d_store(world)
  let body_handle_store = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(
    world,
  )
  body_handle_store.for_each(fn(entity, bh) {
    guard ctx.rigid_bodies.get(bh.handle) is Some(body) else { return }
    let pos = body.position()
    let current = transform_store
      .get(entity)
      .unwrap_or(@math.Transform::identity())
    let next = update_transform_from_iso2(current, pos)
    if transform_store.contains(entity) {
      transform_store.set(entity, next, tick) |> ignore
    } else {
      transform_store.insert(entity, next, tick)
    }
    let linvel = rapier_vec2_to_mg(body.linvel())
    let angvel = body.angvel()
    let next_vel = Velocity2d::{ linvel, angvel }
    if vel_store.contains(entity) {
      vel_store.set(entity, next_vel, tick) |> ignore
    } else {
      vel_store.insert(entity, next_vel, tick)
    }
  })
}
