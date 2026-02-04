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
  current : @math.Transform,
  iso : @rapier_core.Isometry3,
) -> @math.Transform {
  @math.Transform::new(
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
pub fn[
  W : @core.ChangeTickWorld + HasRes_Physics3dConfig + HasRes_Physics3dContext + HasRes_Physics3dEvents,
] physics3d_init_resources_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = HasRes_Physics3dConfig::get_physics3d_config_resource(world)
  if !cfg_res.is_present() {
    cfg_res.insert(Physics3dConfig::default(), tick)
  }
  let ctx_res = HasRes_Physics3dContext::get_physics3d_context_resource(world)
  if !ctx_res.is_present() {
    ctx_res.insert(Physics3dContext::new(), tick)
  }
  let ev_res = HasRes_Physics3dEvents::get_physics3d_events_resource(world)
  if !ev_res.is_present() {
    ev_res.insert(Physics3dEvents::new(), tick)
  }
}

///|
pub fn[W : @core.ChangeTickWorld + HasRes_Physics3dEvents] physics3d_clear_events_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ev_res = HasRes_Physics3dEvents::get_physics3d_events_resource(world)
  match ev_res.get_ref_mut(tick) {
    Some(r) => r.val.clear()
    None => ()
  }
}

///|
pub fn[
  W : @core.ChangeTickWorld + Has_RigidBody3d + Has_Collider3d + Has_RapierBodyHandle3d + Has_RapierColliderHandle3d + HasRes_Physics3dContext,
] physics3d_cleanup_despawned_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics3dContext::get_physics3d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let rb_store = Has_RigidBody3d::get_rigid_body3d_store(world)
  let col_store = Has_Collider3d::get_collider3d_store(world)
  let body_handle_store = Has_RapierBodyHandle3d::get_rapier_body_handle3d_store(
    world,
  )
  let collider_handle_store = Has_RapierColliderHandle3d::get_rapier_collider_handle3d_store(
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
      // Remove attached colliders too; we will reinsert standalone colliders later
      // if the authoring Collider3d component still exists.
      let attached = ctx.colliders.remove_attached_to(h.handle)
      for ch in attached {
        let key = ch.into_raw_parts()
        if ctx.collider_to_entity.get(key) is Some(owner) {
          collider_handle_store.remove(owner) |> ignore
          ctx.entity_to_collider.remove(entity_key(owner))
        }
        ctx.collider_to_entity.remove(key)
        ctx.colliders.remove(ch) |> ignore
      }
      ctx.rigid_bodies.remove(h.handle) |> ignore
      body_handle_store.remove(e) |> ignore
      ctx.entity_to_body.remove(entity_key(e))
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
      ctx.colliders.remove(h.handle) |> ignore
      collider_handle_store.remove(e) |> ignore
      ctx.entity_to_collider.remove(entity_key(e))
      ctx.collider_to_entity.remove(h.handle.into_raw_parts())
    }
  }

  // 2) Remove rapier state when entities are despawned (handle components gone).
  let alive : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  body_handle_store.for_each(fn(e, _h) { alive.set(entity_key(e), true) })
  collider_handle_store.for_each(fn(e, _h) { alive.set(entity_key(e), true) })
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
}

///|
pub fn[
  W : @core.ChangeTickWorld + @math.Has_Transform + Has_RigidBody3d + Has_Collider3d + Has_Velocity3d + Has_RapierBodyHandle3d + Has_RapierColliderHandle3d + HasRes_Physics3dContext,
] physics3d_sync_insertions_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics3dContext::get_physics3d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let vel_store = Has_Velocity3d::get_velocity3d_store(world)
  let rb_store = Has_RigidBody3d::get_rigid_body3d_store(world)
  let col_store = Has_Collider3d::get_collider3d_store(world)
  let body_handle_store = Has_RapierBodyHandle3d::get_rapier_body_handle3d_store(
    world,
  )
  let collider_handle_store = Has_RapierColliderHandle3d::get_rapier_collider_handle3d_store(
    world,
  )

  // Insert rigid bodies.
  rb_store.for_each(fn(entity, rb3d) {
    if body_handle_store.contains(entity) {
      return
    }
    let transform = transform_store
      .get(entity)
      .unwrap_or(@math.Transform::identity())
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
    if vel_store.get(entity) is Some(v) {
      builder = builder
        .linvel(mg_vec3_to_rapier(v.linvel))
        .angvel(mg_vec3_to_rapier(v.angvel))
    }
    let rb = builder.build()
    let handle = ctx.rigid_bodies.insert(rb)
    body_handle_store.insert(entity, RapierBodyHandle3d::new(handle), tick)
    ctx.entity_to_body.set(entity_key(entity), handle)
  })

  // Insert colliders.
  col_store.for_each(fn(entity, col3d) {
    if collider_handle_store.contains(entity) {
      return
    }
    let handle = match body_handle_store.get(entity) {
      Some(bodyh) => {
        let collider = make_collider_builder(col3d.shape)
          .sensor(col3d.sensor)
          .active_events(@collision.ActiveEvents::collision_events())
          .build()
        ctx.colliders.insert_with_parent(
          collider,
          bodyh.handle,
          ctx.rigid_bodies,
        )
      }
      None => {
        let transform = transform_store
          .get(entity)
          .unwrap_or(@math.Transform::identity())
        let collider = make_collider_builder(col3d.shape)
          .sensor(col3d.sensor)
          .active_events(@collision.ActiveEvents::collision_events())
          .position(mg_transform_to_iso3(transform))
          .build()
        ctx.colliders.insert(collider)
      }
    }
    collider_handle_store.insert(
      entity,
      RapierColliderHandle3d::new(handle),
      tick,
    )
    ctx.entity_to_collider.set(entity_key(entity), handle)
    ctx.collider_to_entity.set(handle.into_raw_parts(), entity)
  })
}

///|
pub fn[
  W : @core.ChangeTickWorld + @math.Has_Transform + Has_RigidBody3d + Has_Velocity3d + Has_RapierBodyHandle3d + HasRes_Physics3dContext,
] physics3d_sync_world_to_rapier_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics3dContext::get_physics3d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let dt = @app.fixed_time_timestep_seconds()
  ctx.integration = ctx.integration.set_dt(dt)
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let rb3d_store = Has_RigidBody3d::get_rigid_body3d_store(world)
  let vel_store = Has_Velocity3d::get_velocity3d_store(world)
  let body_handle_store = Has_RapierBodyHandle3d::get_rapier_body_handle3d_store(
    world,
  )
  body_handle_store.for_each(fn(entity, bh) {
    guard rb3d_store.get(entity) is Some(rb3d) else { return }
    guard ctx.rigid_bodies.get_mut(bh.handle) is Some(body) else { return }

    // Kinematic position-based bodies follow the ECS transform.
    if rb3d.body_type is @dynamics.RigidBodyType::KinematicPositionBased {
      let transform = transform_store
        .get(entity)
        .unwrap_or(@math.Transform::identity())
      body.set_next_kinematic_translation(
        mg_vec3_to_rapier(transform.translation),
      )
      body.set_next_kinematic_rotation(mg_quat_to_rapier(transform.rotation))
    }

    // Apply user-driven velocity updates.
    if vel_store.get(entity) is Some(v) {
      body.set_linvel(mg_vec3_to_rapier(v.linvel))
      body.set_angvel(mg_vec3_to_rapier(v.angvel))
    }
  })
}

///|
pub fn[
  W : @core.ChangeTickWorld + HasRes_Physics3dConfig + HasRes_Physics3dContext + HasRes_Physics3dEvents,
] physics3d_step_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = HasRes_Physics3dConfig::get_physics3d_config_resource(world)
  let ctx_res = HasRes_Physics3dContext::get_physics3d_context_resource(world)
  let ev_res = HasRes_Physics3dEvents::get_physics3d_events_resource(world)
  guard cfg_res.get_ref() is Some(cfg_ref) else { return }
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  guard ev_res.get_ref_mut(tick) is Some(ev_ref) else { return }
  let cfg = cfg_ref.val
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
}

///|
pub fn[
  W : @core.ChangeTickWorld + @math.Has_Transform + Has_Velocity3d + Has_RapierBodyHandle3d + HasRes_Physics3dContext,
] physics3d_writeback_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics3dContext::get_physics3d_context_resource(world)
  guard ctx_res.get_ref() is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let vel_store = Has_Velocity3d::get_velocity3d_store(world)
  let body_handle_store = Has_RapierBodyHandle3d::get_rapier_body_handle3d_store(
    world,
  )
  body_handle_store.for_each(fn(entity, bh) {
    guard ctx.rigid_bodies.get(bh.handle) is Some(body) else { return }
    let pos = body.position()
    let current = transform_store
      .get(entity)
      .unwrap_or(@math.Transform::identity())
    let next = update_transform_from_iso3(current, pos)
    if transform_store.contains(entity) {
      transform_store.set(entity, next, tick) |> ignore
    } else {
      transform_store.insert(entity, next, tick)
    }
    let linvel = rapier_vec3_to_mg(body.linvel())
    let angvel = rapier_vec3_to_mg(body.angvel())
    let next_vel = Velocity3d::{ linvel, angvel }
    if vel_store.contains(entity) {
      vel_store.set(entity, next_vel, tick) |> ignore
    } else {
      vel_store.insert(entity, next_vel, tick)
    }
  })
}
