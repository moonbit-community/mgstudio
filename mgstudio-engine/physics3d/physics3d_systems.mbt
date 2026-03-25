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
fn make_collider_builder(
  shape : ColliderShape3d,
) -> @collision.ColliderBuilder3D {
  match shape {
    Ball(radius) => @collision.ColliderBuilder3D::ball(radius)
    Cuboid(hx, hy, hz) => @collision.ColliderBuilder3D::cuboid(hx, hy, hz)
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
}

///|
pub fn physics3d_clear_events_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ev_res = get_physics3d_events_resource(ecs_world)
  guard ev_res.get() is Some(events) else { return }
  let events_ref = Ref::new(events)
  events_ref.val.clear()
  ev_res.insert(events_ref.val)
}

///|
pub fn physics3d_cleanup_despawned_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(ctx_value) else { return }
  let ctx_ref = Ref::new(ctx_value)
  let ctx = ctx_ref.val

  // 1) Remove handles/rapier state when the authoring component is removed.
  let remove_bodies : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_body_handle3d, fn(e, _h) {
    if !(try! ecs_world.contains_by_key(e, ecs_key_rigid_body3d)) {
      remove_bodies.push(e)
    }
  })
  for e in remove_bodies {
    if (try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle3d)) is Some(h) {
      // Remove attached colliders too; we will reinsert standalone colliders later
      // if the authoring Collider3d component still exists.
      let attached = ctx.colliders.remove_attached_to(h.handle)
      for ch in attached {
        let key = ch.into_raw_parts()
        if ctx.collider_to_entity.get(key) is Some(owner) {
          try! (ecs_world.take(owner, ecs_key_rapier_collider_handle3d)
          |> ignore)
          ctx.entity_to_collider.remove(entity_key(owner))
        }
        ctx.collider_to_entity.remove(key)
        ctx.colliders.remove(ch) |> ignore
      }
      ctx.rigid_bodies.remove(h.handle) |> ignore
      try! (ecs_world.take(e, ecs_key_rapier_body_handle3d) |> ignore)
      ctx.entity_to_body.remove(entity_key(e))
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

  // 2) Remove rapier state when entities are despawned (handle components gone).
  let alive : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  ecs_world.for_each_component(ecs_key_rapier_body_handle3d, fn(e, _h) {
    alive.set(entity_key(e), true)
  })
  ecs_world.for_each_component(ecs_key_rapier_collider_handle3d, fn(e, _h) {
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
        ctx.colliders.remove(ch) |> ignore
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
  ctx_res.insert(ctx_ref.val)
}

///|
pub fn physics3d_sync_insertions_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(ctx_value) else { return }
  let ctx_ref = Ref::new(ctx_value)
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
    let builder = match rb3d.body_type {
      @dynamics.RigidBodyType::Dynamic =>
        @dynamics.RigidBodyBuilder3D::dynamic()
      @dynamics.RigidBodyType::Fixed => @dynamics.RigidBodyBuilder3D::fixed()
      @dynamics.RigidBodyType::KinematicPositionBased =>
        @dynamics.RigidBodyBuilder3D::kinematic_position_based()
      @dynamics.RigidBodyType::KinematicVelocityBased =>
        @dynamics.RigidBodyBuilder3D::kinematic_velocity_based()
    }
    let mut builder = builder
      .translation(mg_vec3_to_rapier(t))
      .rotation(mg_quat_to_rapier(r))
    if (try! ecs_world.get_by_key(entity, ecs_key_velocity3d)) is Some(v) {
      builder = builder
        .linvel(mg_vec3_to_rapier(v.linvel))
        .angvel(mg_vec3_to_rapier(v.angvel))
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
    let handle = match
      (try! ecs_world.get_by_key(entity, ecs_key_rapier_body_handle3d)) {
      Some(bodyh) => {
        let mut builder = make_collider_builder(col3d.shape).sensor(
          col3d.sensor,
        )
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
        if (try! ecs_world.get_by_key(
            entity, ecs_key_contact_force_event_threshold3d,
          ))
          is Some(threshold) {
          builder = builder.contact_force_event_threshold(threshold.threshold)
        }
        let collider = builder.build()
        ctx.colliders.insert_with_parent(
          collider,
          bodyh.handle,
          ctx.rigid_bodies,
        )
      }
      None => {
        let transform = (try! ecs_world.get_by_key(
          entity, @transform.ecs_key_transform,
        )).unwrap_or(@transform.Transform::identity())
        let mut builder = make_collider_builder(col3d.shape)
          .sensor(col3d.sensor)
          .position(mg_transform_to_iso3(transform))
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
        if (try! ecs_world.get_by_key(
            entity, ecs_key_contact_force_event_threshold3d,
          ))
          is Some(threshold) {
          builder = builder.contact_force_event_threshold(threshold.threshold)
        }
        let collider = builder.build()
        ctx.colliders.insert(collider)
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
  ctx_res.insert(ctx_ref.val)
}

///|
pub fn physics3d_sync_world_to_rapier_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(ctx_value) else { return }
  let ctx_ref = Ref::new(ctx_value)
  let ctx = ctx_ref.val
  let dt = match (try! world.get_resource(@time.fixed_time_resource_key())) {
    Some(fixed_time) => fixed_time.timestep_seconds()
    None => abort("Missing Time<Fixed> resource in physics3d systems")
  }
  ctx.integration = ctx.integration.set_dt(dt)
  ecs_world.for_each_component(ecs_key_rapier_collider_handle3d, fn(
    entity,
    ch,
  ) {
    guard ctx.colliders.get_mut(ch.handle) is Some(collider) else { return }
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
  })
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
  let ctx_ref = Ref::new(ctx_value)
  let ev_ref = Ref::new(events_value)
  let ctx = ctx_ref.val
  let events = ev_ref.val
  let gravity = mg_vec3_to_rapier(cfg.gravity)
  ctx.pipeline.step_with_events(
    gravity,
    ctx.integration,
    ctx.islands,
    ctx.broad_phase,
    ctx.narrow_phase,
    ctx.rigid_bodies,
    ctx.colliders,
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
