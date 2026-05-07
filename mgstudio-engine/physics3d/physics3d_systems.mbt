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
/// Systems for Physics3D integration.

///|
fn entity_key(e : @core.Entity) -> (Int, Int) {
  (e.id, e.generation)
}

///|
fn update_transform_from_iso3(
  current : @transform.Transform,
  iso : @rapier_core.Isometry3,
) -> @transform.Transform {
  @transform.Transform::new(
    @math.Vec3::new(iso.translation.x, iso.translation.y, iso.translation.z),
    rapier_quat_to_mg(iso.rotation),
    current.scale,
  )
}

///|
fn collision_groups_to_rapier(
  groups : CollisionGroups3d,
) -> @dynamics.InteractionGroups {
  @dynamics.InteractionGroups::new(
    @dynamics.Group::new(groups.memberships),
    @dynamics.Group::new(groups.filter),
    groups.test_mode,
  )
}

///|
fn solver_groups_to_rapier(
  groups : SolverGroups3d,
) -> @dynamics.InteractionGroups {
  @dynamics.InteractionGroups::new(
    @dynamics.Group::new(groups.memberships),
    @dynamics.Group::new(groups.filter),
    groups.test_mode,
  )
}

///|
fn vec3_array_to_rapier(
  vertices : Array[@math.Vec3],
) -> Array[@rapier_core.Vec3] {
  let out : Array[@rapier_core.Vec3] = []
  for v in vertices {
    out.push(mg_vec3_to_rapier(v))
  }
  out
}

///|
fn collider_shape3d_to_rapier(shape : ColliderShape3d) -> @collision.Shape3D {
  match shape {
    Ball(radius) => @collision.Shape3D::ball(radius)
    Cuboid(hx, hy, hz) => @collision.Shape3D::cuboid(hx, hy, hz)
    CapsuleX(half_height, radius) => {
      let c = @collision.Shape3D::capsule_y(radius, half_height)
      @collision.Shape3D::Compound([
        (
          @rapier_core.Isometry3::new(
            @rapier_core.Vec3::zero(),
            @rapier_core.rotation_from_scaled_axis(
              @rapier_core.Vec3::new(0.0F, 0.0F, -1.5707964F),
            ),
          ),
          c,
        ),
      ])
    }
    CapsuleY(half_height, radius) =>
      @collision.Shape3D::capsule_y(radius, half_height)
    CapsuleZ(half_height, radius) => {
      let c = @collision.Shape3D::capsule_y(radius, half_height)
      @collision.Shape3D::Compound([
        (
          @rapier_core.Isometry3::new(
            @rapier_core.Vec3::zero(),
            @rapier_core.rotation_from_scaled_axis(
              @rapier_core.Vec3::new(1.5707964F, 0.0F, 0.0F),
            ),
          ),
          c,
        ),
      ])
    }
    Cylinder(half_height, radius) =>
      @collision.Shape3D::cylinder(radius, half_height)
    Cone(half_height, radius) => @collision.Shape3D::cone(radius, half_height)
    HalfSpace(normal) =>
      @collision.Shape3D::halfspace(mg_vec3_to_rapier(normal))
    Triangle(a, b, c) =>
      @collision.Shape3D::triangle(
        mg_vec3_to_rapier(a),
        mg_vec3_to_rapier(b),
        mg_vec3_to_rapier(c),
      )
    TriMesh(vertices, indices) =>
      @collision.Shape3D::TriMesh(vec3_array_to_rapier(vertices), indices)
    ConvexHull(vertices) =>
      @collision.Shape3D::ConvexHull(vec3_array_to_rapier(vertices), 0.0F)
    Compound(parts) => {
      let rs : Array[(@rapier_core.Isometry3, @collision.Shape3D)] = []
      for part in parts {
        let (t, s) = part
        rs.push((mg_transform_to_iso3(t), collider_shape3d_to_rapier(s)))
      }
      @collision.Shape3D::Compound(rs)
    }
    Heightfield(heights, nrows, ncols, scale) =>
      if @collision.ColliderBuilder3D::heightfield(
          heights,
          nrows,
          ncols,
          mg_vec3_to_rapier(scale),
        )
        is Some(builder) {
        builder.shape
      } else {
        abort("Invalid ColliderShape3d::Heightfield inputs")
      }
    Raw(shape3d) => shape3d
  }
}

///|
fn make_collider_builder(
  shape : ColliderShape3d,
) -> @collision.ColliderBuilder3D {
  match shape {
    Ball(radius) => @collision.ColliderBuilder3D::ball(radius)
    Cuboid(hx, hy, hz) => @collision.ColliderBuilder3D::cuboid(hx, hy, hz)
    CapsuleX(half_height, radius) =>
      @collision.ColliderBuilder3D::capsule_x(radius, half_height)
    CapsuleY(half_height, radius) =>
      @collision.ColliderBuilder3D::capsule_y(radius, half_height)
    CapsuleZ(half_height, radius) =>
      @collision.ColliderBuilder3D::capsule_z(radius, half_height)
    Cylinder(half_height, radius) =>
      @collision.ColliderBuilder3D::cylinder(radius, half_height)
    Cone(half_height, radius) =>
      @collision.ColliderBuilder3D::cone(radius, half_height)
    HalfSpace(normal) =>
      @collision.ColliderBuilder3D::halfspace(mg_vec3_to_rapier(normal))
    Triangle(a, b, c) =>
      @collision.ColliderBuilder3D::triangle(
        mg_vec3_to_rapier(a),
        mg_vec3_to_rapier(b),
        mg_vec3_to_rapier(c),
      )
    TriMesh(vertices, indices) =>
      match
        @collision.ColliderBuilder3D::trimesh(
          vec3_array_to_rapier(vertices),
          indices,
        ) {
        Some(builder) => builder
        None => abort("Invalid ColliderShape3d::TriMesh")
      }
    ConvexHull(vertices) =>
      match
        @collision.ColliderBuilder3D::convex_hull(
          vec3_array_to_rapier(vertices),
        ) {
        Some(builder) => builder
        None => abort("Invalid ColliderShape3d::ConvexHull")
      }
    Compound(parts) => {
      let rs : Array[(@rapier_core.Isometry3, @collision.ColliderBuilder3D)] = []
      for part in parts {
        let (t, s) = part
        rs.push((mg_transform_to_iso3(t), make_collider_builder(s)))
      }
      match @collision.ColliderBuilder3D::compound(rs) {
        Some(builder) => builder
        None => abort("Invalid ColliderShape3d::Compound")
      }
    }
    Heightfield(heights, nrows, ncols, scale) =>
      match
        @collision.ColliderBuilder3D::heightfield(
          heights,
          nrows,
          ncols,
          mg_vec3_to_rapier(scale),
        ) {
        Some(builder) => builder
        None => abort("Invalid ColliderShape3d::Heightfield")
      }
    Raw(_shape3d) => abort("ColliderShape3d::Raw is not supported in builder")
  }
}

///|
pub fn physics3d_init_resources_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let cfg_res = get_physics3d_config_resource(ecs_world)
  if !cfg_res.is_present() {
    cfg_res.insert(Physics3dConfig::default())
  }
  let ctx_res = get_physics3d_context_resource(ecs_world)
  if !ctx_res.is_present() {
    ctx_res.insert(Physics3dContext::new())
  }
  let ev_res = get_physics3d_events_resource(ecs_world)
  if !ev_res.is_present() {
    ev_res.insert(Physics3dEvents::new())
  }
  let hooks_res = get_physics3d_hooks_config_resource(ecs_world)
  if !hooks_res.is_present() {
    hooks_res.insert(Physics3dHooksConfig::default())
  }
}

///|
pub fn physics3d_clear_events_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ev_res = get_physics3d_events_resource(ecs_world)
  guard ev_res.get() is Some(events) else { return }
  let events_ref = Ref(events)
  events_ref.val.clear()
  ev_res.insert(events_ref.val)
}

///|
pub fn physics3d_cleanup_despawned_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(ctx_value) else { return }
  let ctx_ref = Ref(ctx_value)
  let ctx = ctx_ref.val

  // 1) Remove handles/rapier state when authoring components are removed.
  let remove_bodies : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_body_handle3d, fn(e, _h) {
    if !(try! ecs_world.contains_by_key(e, ecs_key_rigid_body3d)) {
      remove_bodies.push(e)
    }
  })
  for e in remove_bodies {
    if (try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle3d)) is Some(h) {
      let attached = ctx.colliders.remove_attached_to(h.handle)
      for ch in attached {
        let key = ch.into_raw_parts()
        if ctx.collider_to_entity.get(key) is Some(owner) {
          try! (ecs_world.take(owner, ecs_key_rapier_collider_handle3d)
          |> ignore)
          ctx.entity_to_collider.remove(entity_key(owner))
        }
        ctx.collider_to_entity.remove(key)
      }
      ctx.rigid_bodies.remove(h.handle) |> ignore
      try! (ecs_world.take(e, ecs_key_rapier_body_handle3d) |> ignore)
      ctx.entity_to_body.remove(entity_key(e))
      if (try! ecs_world.get_by_key(e, ecs_key_rapier_impulse_joint_handle3d))
        is Some(_) {
        try! (ecs_world.take(e, ecs_key_rapier_impulse_joint_handle3d) |> ignore)
        ctx.entity_to_impulse_joint.remove(entity_key(e))
      }
      if (try! ecs_world.get_by_key(e, ecs_key_rapier_multibody_joint_handle3d))
        is Some(_) {
        try! (ecs_world.take(e, ecs_key_rapier_multibody_joint_handle3d)
        |> ignore)
        ctx.entity_to_multibody_joint.remove(entity_key(e))
      }
    }
  }
  let remove_colliders : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_collider_handle3d, fn(e, _h) {
    if !(try! ecs_world.contains_by_key(e, ecs_key_collider3d)) {
      remove_colliders.push(e)
    }
  })
  for e in remove_colliders {
    if (try! ecs_world.get_by_key(e, ecs_key_rapier_collider_handle3d))
      is Some(h) {
      ctx.colliders.remove(h.handle) |> ignore
      try! (ecs_world.take(e, ecs_key_rapier_collider_handle3d) |> ignore)
      ctx.entity_to_collider.remove(entity_key(e))
      ctx.collider_to_entity.remove(h.handle.into_raw_parts())
    }
  }

  let remove_impulse_joints : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_impulse_joint_handle3d, fn(
    e,
    _h,
  ) {
    if !((try! ecs_world.contains_by_key(e, ecs_key_impulse_joint3d)) &&
      (try! ecs_world.contains_by_key(e, ecs_key_rapier_body_handle3d))) {
      remove_impulse_joints.push(e)
    }
  })
  for e in remove_impulse_joints {
    try! (ecs_world.take(e, ecs_key_rapier_impulse_joint_handle3d) |> ignore)
    ctx.entity_to_impulse_joint.remove(entity_key(e))
  }
  let remove_multibody_joints : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_multibody_joint_handle3d, fn(
    e,
    h,
  ) {
    if !((try! ecs_world.contains_by_key(e, ecs_key_multibody_joint3d)) &&
      (try! ecs_world.contains_by_key(e, ecs_key_rapier_body_handle3d))) {
      remove_multibody_joints.push(e)
      return
    }
    if ctx.multibody_joints.get(h.handle) is None {
      remove_multibody_joints.push(e)
    }
  })
  for e in remove_multibody_joints {
    if (try! ecs_world.get_by_key(e, ecs_key_rapier_multibody_joint_handle3d))
      is Some(h) {
      ctx.multibody_joints.remove(h.handle, true)
    }
    try! (ecs_world.take(e, ecs_key_rapier_multibody_joint_handle3d) |> ignore)
    ctx.entity_to_multibody_joint.remove(entity_key(e))
  }

  // 2) Remove rapier state when entities are despawned (handle components gone).
  let alive : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap([])
  ecs_world.for_each_component(ecs_key_rapier_body_handle3d, fn(e, _h) {
    alive.set(entity_key(e), true)
  })
  ecs_world.for_each_component(ecs_key_rapier_collider_handle3d, fn(e, _h) {
    alive.set(entity_key(e), true)
  })
  ecs_world.for_each_component(ecs_key_rapier_impulse_joint_handle3d, fn(
    e,
    _h,
  ) {
    alive.set(entity_key(e), true)
  })
  ecs_world.for_each_component(ecs_key_rapier_multibody_joint_handle3d, fn(
    e,
    _h,
  ) {
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
      let attached = ctx.colliders.remove_attached_to(handle)
      for ch in attached {
        ctx.collider_to_entity.remove(ch.into_raw_parts())
      }
      ctx.rigid_bodies.remove(handle) |> ignore
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
      ctx.colliders.remove(handle) |> ignore
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
    ctx.entity_to_impulse_joint.remove(k)
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
  ctx.query_pipeline.update(ctx.rigid_bodies, ctx.colliders)
  ctx_res.insert(ctx_ref.val)
}

///|
pub fn physics3d_sync_insertions_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(ctx_value) else { return }
  let ctx_ref = Ref(ctx_value)
  let ctx = ctx_ref.val

  // Insert rigid bodies.
  ecs_world.for_each_component(ecs_key_rigid_body3d, fn(entity, rb3d) {
    if (try! ecs_world.contains_by_key(entity, ecs_key_rapier_body_handle3d)) {
      return
    }
    let transform = (try! ecs_world.get_by_key(
      entity, @transform.ecs_key_transform,
    )).unwrap_or(@transform.Transform::identity())
    let t = transform.translation
    let r = transform.rotation
    let mut builder = match rb3d.body_type {
      @dynamics.RigidBodyType::Dynamic =>
        @dynamics.RigidBodyBuilder3D::dynamic()
      @dynamics.RigidBodyType::Fixed => @dynamics.RigidBodyBuilder3D::fixed()
      @dynamics.RigidBodyType::KinematicPositionBased =>
        @dynamics.RigidBodyBuilder3D::kinematic_position_based()
      @dynamics.RigidBodyType::KinematicVelocityBased =>
        @dynamics.RigidBodyBuilder3D::kinematic_velocity_based()
    }
    builder = builder
      .translation(mg_vec3_to_rapier(t))
      .rotation(mg_quat_to_rapier(r))
    if (try! ecs_world.get_by_key(entity, ecs_key_velocity3d)) is Some(v) {
      builder = builder
        .linvel(mg_vec3_to_rapier(v.linvel))
        .angvel(mg_vec3_to_rapier(v.angvel))
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_damping3d)) is Some(d) {
      builder = builder.linear_damping(d.linear).angular_damping(d.angular)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_gravity_scale3d)) is Some(g) {
      builder = builder.gravity_scale(g.scale)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_ccd3d)) is Some(c) {
      builder = builder
        .ccd_enabled(c.enabled)
        .soft_ccd_prediction(c.soft_prediction)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_dominance3d)) is Some(d) {
      builder = builder.dominance_group(d.group)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_locked_axes3d)) is Some(l) {
      builder = builder
        .enabled_translations(
          !l.lock_translation_x,
          !l.lock_translation_y,
          !l.lock_translation_z,
        )
        .enabled_rotations(
          !l.lock_rotation_x,
          !l.lock_rotation_y,
          !l.lock_rotation_z,
        )
    }
    if (try! ecs_world.get_by_key(
        entity, ecs_key_additional_solver_iterations3d,
      ))
      is Some(it) {
      builder = builder.additional_solver_iterations(it.iterations)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_additional_mass_properties3d))
      is Some(m) {
      builder = match m {
        Mass(mass) => builder.additional_mass(mass)
        MassProperties(props) => builder.additional_mass_properties(props)
      }
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_sleeping3d)) is Some(s) {
      builder = builder.sleeping(s.sleeping)
    }
    let rb = builder.build()
    let handle = ctx.rigid_bodies.insert(rb)
    try! ecs_world.set_by_key(
      entity,
      ecs_key_rapier_body_handle3d,
      RapierBodyHandle3d::new(handle),
    )
    ctx.entity_to_body.set(entity_key(entity), handle)
  })

  // Insert colliders.
  ecs_world.for_each_component(ecs_key_collider3d, fn(entity, col3d) {
    if (try! ecs_world.contains_by_key(entity, ecs_key_rapier_collider_handle3d)) {
      return
    }
    let mut builder = make_collider_builder(col3d.shape).sensor(col3d.sensor)
    if (try! ecs_world.get_by_key(entity, ecs_key_collider_enabled3d))
      is Some(enabled) {
      builder = builder.enabled(enabled.enabled)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_collider_density3d))
      is Some(density) {
      builder = builder.density(density.density)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_friction3d)) is Some(f) {
      builder = builder.friction(f.coefficient)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_friction_combine_rule3d))
      is Some(r) {
      builder = builder.friction_combine_rule(r.rule)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_restitution3d)) is Some(r) {
      builder = builder.restitution(r.coefficient)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_restitution_combine_rule3d))
      is Some(r) {
      builder = builder.restitution_combine_rule(r.rule)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_collision_groups3d))
      is Some(g) {
      builder = builder.collision_groups(collision_groups_to_rapier(g))
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_solver_groups3d)) is Some(g) {
      builder = builder.solver_groups(solver_groups_to_rapier(g))
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_active_collision_types3d))
      is Some(active_types) {
      builder = builder.active_collision_types(active_types.types)
    }
    let active_events = match
      (try! ecs_world.get_by_key(entity, ecs_key_active_events3d)) {
      Some(active_events) => active_events.events
      None =>
        if (try! ecs_world.get_by_key(
            entity, ecs_key_contact_force_event_threshold3d,
          ))
          is Some(_) {
          @collision.ActiveEvents::collision_events().insert(
            @collision.ActiveEvents::contact_force_events(),
          )
        } else {
          @collision.ActiveEvents::collision_events()
        }
    }
    builder = builder.active_events(active_events)
    if (try! ecs_world.get_by_key(entity, ecs_key_active_hooks3d))
      is Some(active_hooks) {
      builder = builder.active_hooks(active_hooks.hooks)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_contact_skin3d)) is Some(skin) {
      builder = builder.contact_skin(skin.skin)
    }
    if (try! ecs_world.get_by_key(
        entity, ecs_key_contact_force_event_threshold3d,
      ))
      is Some(threshold) {
      builder = builder.contact_force_event_threshold(threshold.threshold)
    }
    let handle = match
      (try! ecs_world.get_by_key(entity, ecs_key_rapier_body_handle3d)) {
      Some(bodyh) => {
        let collider = builder.build()
        ctx.colliders.insert_with_parent(
          collider,
          bodyh.handle,
          ctx.rigid_bodies,
        )
      }
      None =>
        match (try! ecs_world.get_by_key(entity, ecs_key_collider_parent3d)) {
          Some(parent) =>
            match
              (try! ecs_world.get_by_key(
                parent.parent,
                ecs_key_rapier_body_handle3d,
              )) {
              Some(parent_bh) => {
                let transform = (try! ecs_world.get_by_key(
                  entity, @transform.ecs_key_transform,
                )).unwrap_or(@transform.Transform::identity())
                let collider = builder
                  .position(mg_transform_to_iso3(transform))
                  .build()
                ctx.colliders.insert_with_parent(
                  collider,
                  parent_bh.handle,
                  ctx.rigid_bodies,
                )
              }
              None => {
                let transform = (try! ecs_world.get_by_key(
                  entity, @transform.ecs_key_transform,
                )).unwrap_or(@transform.Transform::identity())
                let collider = builder
                  .position(mg_transform_to_iso3(transform))
                  .build()
                ctx.colliders.insert(collider)
              }
            }
          None => {
            let transform = (try! ecs_world.get_by_key(
              entity, @transform.ecs_key_transform,
            )).unwrap_or(@transform.Transform::identity())
            let collider = builder
              .position(mg_transform_to_iso3(transform))
              .build()
            ctx.colliders.insert(collider)
          }
        }
    }
    try! ecs_world.set_by_key(
      entity,
      ecs_key_rapier_collider_handle3d,
      RapierColliderHandle3d::new(handle),
    )
    ctx.entity_to_collider.set(entity_key(entity), handle)
    ctx.collider_to_entity.set(handle.into_raw_parts(), entity)
  })
  ctx.query_pipeline.update(ctx.rigid_bodies, ctx.colliders)
  ctx_res.insert(ctx_ref.val)
}

///|
pub fn physics3d_sync_world_to_rapier_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let cfg_res = get_physics3d_config_resource(ecs_world)
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard cfg_res.get() is Some(cfg) else { return }
  guard ctx_res.get() is Some(ctx_value) else { return }
  let ctx_ref = Ref(ctx_value)
  let ctx = ctx_ref.val
  let dt = match (try! world.get_resource(@time.fixed_time_resource_key())) {
    Some(fixed_time) => fixed_time.timestep_seconds()
    None => abort("Missing Time<Fixed> resource in physics3d systems")
  }
  ctx.integration = cfg.integration.set_dt(dt)
  physics3d_apply_hooks(world, ctx)
  ecs_world.for_each_component(ecs_key_rapier_collider_handle3d, fn(
    entity,
    ch,
  ) {
    guard ctx.colliders.get_mut(ch.handle) is Some(collider) else { return }
    if (try! ecs_world.get_by_key(entity, ecs_key_collider3d)) is Some(col3d) {
      collider.set_shape(collider_shape3d_to_rapier(col3d.shape)) |> ignore
    }
    collider.set_enabled(
      (try! ecs_world.get_by_key(entity, ecs_key_collider_enabled3d))
      .map(fn(e) { e.enabled })
      .unwrap_or(true),
    )
    |> ignore
    if (try! ecs_world.get_by_key(entity, ecs_key_friction3d)) is Some(f) {
      collider.set_friction(f.coefficient) |> ignore
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_friction_combine_rule3d))
      is Some(r) {
      collider.set_friction_combine_rule(r.rule) |> ignore
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_restitution3d)) is Some(r) {
      collider.set_restitution(r.coefficient) |> ignore
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_restitution_combine_rule3d))
      is Some(r) {
      collider.set_restitution_combine_rule(r.rule) |> ignore
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_collision_groups3d))
      is Some(g) {
      collider.set_collision_groups(collision_groups_to_rapier(g)) |> ignore
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_solver_groups3d)) is Some(g) {
      collider.set_solver_groups(solver_groups_to_rapier(g)) |> ignore
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_active_collision_types3d))
      is Some(active_types) {
      collider.set_active_collision_types(active_types.types) |> ignore
    }
    let active_events = match
      (try! ecs_world.get_by_key(entity, ecs_key_active_events3d)) {
      Some(active_events) => active_events.events
      None =>
        if (try! ecs_world.get_by_key(
            entity, ecs_key_contact_force_event_threshold3d,
          ))
          is Some(_) {
          @collision.ActiveEvents::collision_events().insert(
            @collision.ActiveEvents::contact_force_events(),
          )
        } else {
          @collision.ActiveEvents::collision_events()
        }
    }
    collider.set_active_events(active_events) |> ignore
    if (try! ecs_world.get_by_key(entity, ecs_key_active_hooks3d))
      is Some(active_hooks) {
      collider.set_active_hooks(active_hooks.hooks) |> ignore
    }
    if (try! ecs_world.get_by_key(
        entity, ecs_key_contact_force_event_threshold3d,
      ))
      is Some(threshold) {
      collider.set_contact_force_event_threshold(threshold.threshold) |> ignore
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_contact_skin3d)) is Some(s) {
      collider.set_contact_skin(s.skin) |> ignore
    }
    if (try! ecs_world.contains_by_key(entity, ecs_key_rapier_body_handle3d)) {
      return
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_collider_parent3d)) is Some(p) {
      if (try! ecs_world.get_by_key(p.parent, ecs_key_rapier_body_handle3d))
        is Some(_parent_bh) {
        let transform = (try! ecs_world.get_by_key(
          entity, @transform.ecs_key_transform,
        )).unwrap_or(@transform.Transform::identity())
        collider.set_local_position(mg_transform_to_iso3(transform)) |> ignore
        return
      }
    }
    let transform = (try! ecs_world.get_by_key(
      entity, @transform.ecs_key_transform,
    )).unwrap_or(@transform.Transform::identity())
    collider.set_position(mg_transform_to_iso3(transform)) |> ignore
  })
  ecs_world.for_each_component(ecs_key_rapier_body_handle3d, fn(entity, bh) {
    guard (try! ecs_world.get_by_key(entity, ecs_key_rigid_body3d))
      is Some(rb3d) else {
      return
    }
    guard ctx.rigid_bodies.get_mut(bh.handle) is Some(body) else { return }

    // Kinematic position-based bodies follow the ECS transform.
    if rb3d.body_type is @dynamics.RigidBodyType::KinematicPositionBased {
      let transform = (try! ecs_world.get_by_key(
        entity, @transform.ecs_key_transform,
      )).unwrap_or(@transform.Transform::identity())
      body.set_next_kinematic_translation(
        mg_vec3_to_rapier(transform.translation),
      )
      body.set_next_kinematic_rotation(mg_quat_to_rapier(transform.rotation))
    }

    // Apply user-driven velocity updates.
    if (try! ecs_world.get_by_key(entity, ecs_key_velocity3d)) is Some(v) {
      body.set_linvel(mg_vec3_to_rapier(v.linvel))
      body.set_angvel(mg_vec3_to_rapier(v.angvel))
    }
    body.set_gravity_scale(
      try! ecs_world
      .get_by_key(entity, ecs_key_gravity_scale3d)
      .map(fn(g) { g.scale })
      .unwrap_or(1.0F),
      true,
    )
    if (try! ecs_world.get_by_key(entity, ecs_key_locked_axes3d)) is Some(l) {
      body.set_enabled_translations(
        !l.lock_translation_x,
        !l.lock_translation_y,
        !l.lock_translation_z,
        true,
      )
      body.set_enabled_rotations(
        !l.lock_rotation_x,
        !l.lock_rotation_y,
        !l.lock_rotation_z,
        true,
      )
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_ccd3d)) is Some(c) {
      body.set_ccd_active(c.enabled)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_dominance3d)) is Some(d) {
      body.set_dominance_group(d.group)
    }
    if (try! ecs_world.get_by_key(
        entity, ecs_key_additional_solver_iterations3d,
      ))
      is Some(it) {
      body.set_additional_solver_iterations(it.iterations)
    }
    match (try! ecs_world.get_by_key(entity, ecs_key_sleeping3d)) {
      Some(s) => if !s.sleeping { body.wake_up() }
      None => ()
    }
    // External forces and impulses are applied as one-step impulses.
    let frame_impulse = (try! ecs_world.get_by_key(
        entity, ecs_key_external_force3d,
      ))
      .map(fn(f) { mg_vec3_to_rapier(f.force).scale(dt) })
      .unwrap_or(@rapier_core.Vec3::zero())
    if frame_impulse.length_squared() > 0.0F {
      body.apply_impulse_at_point(frame_impulse, body.world_com(), true)
    }
    if (try! ecs_world.get_by_key(entity, ecs_key_external_impulse3d))
      is Some(imp) {
      if imp.impulse.x != 0.0F || imp.impulse.y != 0.0F || imp.impulse.z != 0.0F {
        body.apply_impulse_at_point(
          mg_vec3_to_rapier(imp.impulse),
          body.world_com(),
          true,
        )
      }
      try! (ecs_world.replace(
        entity,
        ecs_key_external_impulse3d,
        ExternalImpulse3d::zero(),
      )
      |> ignore)
    }
  })
  ctx.query_pipeline.update(ctx.rigid_bodies, ctx.colliders)
  ctx_res.insert(ctx_ref.val)
}

///|
pub fn physics3d_step_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let cfg_res = get_physics3d_config_resource(ecs_world)
  let ctx_res = get_physics3d_context_resource(ecs_world)
  let ev_res = get_physics3d_events_resource(ecs_world)
  guard cfg_res.get() is Some(cfg) else { return }
  guard ctx_res.get() is Some(ctx_value) else { return }
  guard ev_res.get() is Some(events_value) else { return }
  let ctx_ref = Ref(ctx_value)
  let ev_ref = Ref(events_value)
  let ctx = ctx_ref.val
  let events = ev_ref.val
  let gravity = mg_vec3_to_rapier(cfg.gravity)
  if !cfg.physics_pipeline_active {
    ctx.query_pipeline.update(ctx.rigid_bodies, ctx.colliders)
    ctx_res.insert(ctx_ref.val)
    ev_res.insert(ev_ref.val)
    return
  }
  physics3d_hooks_set_current_collider_map(ctx.collider_to_entity)
  ctx.pipeline.step_with_events_joint_sets_and_hooks(
    gravity,
    ctx.integration,
    ctx.islands,
    ctx.broad_phase,
    ctx.narrow_phase,
    ctx.rigid_bodies,
    ctx.colliders,
    ctx.event_handler,
    ctx.rope_joints,
    ctx.impulse_joints,
    ctx.multibody_joints,
    ctx.hooks,
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
          events.collisions.push(CollisionEvent3d::Started(a, b, sensor))
        } else if ev.stopped() {
          events.collisions.push(CollisionEvent3d::Stopped(a, b, sensor))
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
        events.contact_forces.push(ContactForceEvent3d::{
          entity1: a,
          entity2: b,
          total_force: rapier_vec3_to_mg(ev.total_force()),
          total_force_magnitude: ev.total_force_magnitude(),
          max_force_direction: rapier_vec3_to_mg(ev.max_force_direction()),
          max_force_magnitude: ev.max_force_magnitude(),
        })
      _ => ()
    }
  }
  ctx.query_pipeline.update(ctx.rigid_bodies, ctx.colliders)
  physics3d_hooks_clear_current_collider_map()
  ctx_res.insert(ctx_ref.val)
  ev_res.insert(ev_ref.val)
}

///|
pub fn physics3d_writeback_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(ctx) else { return }
  ecs_world.for_each_component(ecs_key_rapier_body_handle3d, fn(entity, bh) {
    guard ctx.rigid_bodies.get(bh.handle) is Some(body) else { return }
    let pos = body.position()
    let current = (try! ecs_world.get_by_key(
      entity, @transform.ecs_key_transform,
    )).unwrap_or(@transform.Transform::identity())
    let next = update_transform_from_iso3(current, pos)
    if (try! ecs_world.contains_by_key(entity, @transform.ecs_key_transform)) {
      try! (ecs_world.replace(entity, @transform.ecs_key_transform, next)
      |> ignore)
    } else {
      try! ecs_world.set_by_key(entity, @transform.ecs_key_transform, next)
    }
    let linvel = rapier_vec3_to_mg(body.linvel())
    let angvel = rapier_vec3_to_mg(body.angvel())
    let next_vel = Velocity3d::{ linvel, angvel }
    if (try! ecs_world.contains_by_key(entity, ecs_key_velocity3d)) {
      try! (ecs_world.replace(entity, ecs_key_velocity3d, next_vel) |> ignore)
    } else {
      try! ecs_world.set_by_key(entity, ecs_key_velocity3d, next_vel)
    }
  })
}
