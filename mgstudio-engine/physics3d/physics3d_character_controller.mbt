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
/// Kinematic character controller integration (3D).

///|
pub struct CharacterCollision3d {
  /// The entity that owns the hit collider (if known).
  other : @core.Entity?
  toi : Float
  point : @math.Vec3
  normal : @math.Vec3
  translation_applied : @math.Vec3
  translation_remaining : @math.Vec3
}

///|
pub fn CharacterCollision3d::from_rapier(
  ctx : Physics3dContext,
  c : @control.CharacterCollision3DReal,
) -> CharacterCollision3d {
  let h = c.handle()
  let other = ctx.collider_to_entity.get(h.into_raw_parts())
  let hit = c.hit()
  {
    other,
    toi: hit.toi(),
    point: rapier_vec3_to_mg(hit.point()),
    normal: rapier_vec3_to_mg(hit.normal()),
    translation_applied: rapier_vec3_to_mg(c.translation_applied()),
    translation_remaining: rapier_vec3_to_mg(c.translation_remaining()),
  }
}

///|
pub struct KinematicCharacterController3d {
  /// Desired movement (one-shot). The system resets this to zero each fixed step.
  translation : @math.Vec3
  controller : @control.KinematicCharacterController3DReal
}

///|
pub fn KinematicCharacterController3d::default() -> KinematicCharacterController3d {
  {
    translation: @math.Vec3::zero(),
    controller: @control.KinematicCharacterController3DReal::default(),
  }
}

///|
pub fn KinematicCharacterController3d::with_translation(
  self : KinematicCharacterController3d,
  translation : @math.Vec3,
) -> KinematicCharacterController3d {
  KinematicCharacterController3d::{ ..self, translation, }
}

///|
pub fn KinematicCharacterController3d::add_translation(
  self : KinematicCharacterController3d,
  delta : @math.Vec3,
) -> KinematicCharacterController3d {
  KinematicCharacterController3d::{
    ..self,
    translation: @math.Vec3::new(
      self.translation.x + delta.x,
      self.translation.y + delta.y,
      self.translation.z + delta.z,
    ),
  }
}

///|
pub fn KinematicCharacterController3d::reset_translation(
  self : KinematicCharacterController3d,
) -> KinematicCharacterController3d {
  KinematicCharacterController3d::{ ..self, translation: @math.Vec3::zero() }
}

///|
pub fn KinematicCharacterController3d::with_up(
  self : KinematicCharacterController3d,
  up : @math.Vec3,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_up(mg_vec3_to_rapier(up))
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub fn KinematicCharacterController3d::with_slide(
  self : KinematicCharacterController3d,
  slide : Bool,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_slide(slide)
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub fn KinematicCharacterController3d::with_offset(
  self : KinematicCharacterController3d,
  offset : @control.CharacterLength,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_offset(offset)
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub fn KinematicCharacterController3d::with_snap_to_ground(
  self : KinematicCharacterController3d,
  snap : @control.CharacterLength?,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_snap_to_ground(snap)
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub fn KinematicCharacterController3d::with_autostep(
  self : KinematicCharacterController3d,
  autostep : @control.CharacterAutostep?,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_autostep(autostep)
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub fn KinematicCharacterController3d::with_max_slope_climb_angle(
  self : KinematicCharacterController3d,
  angle : Float,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_max_slope_climb_angle(angle)
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub fn KinematicCharacterController3d::with_min_slope_slide_angle(
  self : KinematicCharacterController3d,
  angle : Float,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_min_slope_slide_angle(angle)
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub fn KinematicCharacterController3d::with_normal_nudge_factor(
  self : KinematicCharacterController3d,
  factor : Float,
) -> KinematicCharacterController3d {
  let controller = self.controller.with_normal_nudge_factor(factor)
  KinematicCharacterController3d::{ ..self, controller, }
}

///|
pub struct KinematicCharacterControllerOutput3d {
  effective_translation : @math.Vec3
  grounded : Bool
  sliding_down_slope : Bool
  collisions : Array[CharacterCollision3d]
}

///|
pub fn KinematicCharacterControllerOutput3d::new() -> KinematicCharacterControllerOutput3d {
  {
    effective_translation: @math.Vec3::zero(),
    grounded: false,
    sliding_down_slope: false,
    collisions: [],
  }
}

///|
pub fn KinematicCharacterControllerOutput3d::without_collisions(
  self : KinematicCharacterControllerOutput3d,
) -> KinematicCharacterControllerOutput3d {
  KinematicCharacterControllerOutput3d::{ ..self, collisions: [] }
}

///|
pub fn physics3d_character_controller_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(current_ctx) else { return }
  let ctx_ref = Ref::new(current_ctx)
  let ctx = ctx_ref.val

  ctx.query_pipeline.update(ctx.rigid_bodies, ctx.colliders)
  let dt = match (try! world.get_resource(@time.fixed_time_resource_key())) {
    Some(fixed_time) => fixed_time.timestep_seconds()
    None =>
      abort("Missing Time<Fixed> resource in physics3d character controller")
  }
  ecs_world.for_each_component(ecs_key_kinematic_character_controller3d, fn(
    entity,
    kcc,
  ) {
    if (try! ecs_world.contains_by_key(entity, ecs_key_rapier_body_handle3d)) {
      return
    }
    if kcc.translation.x == 0.0F &&
      kcc.translation.y == 0.0F &&
      kcc.translation.z == 0.0F {
      return
    }
    guard (try! ecs_world.get_by_key(entity, ecs_key_rapier_collider_handle3d))
      is Some(ch) else {
      return
    }
    guard ctx.colliders.get(ch.handle) is Some(col) else { return }
    if col.parent() is Some(_) {
      return
    }
    let shape = col.shape()
    let character_pos = col.position()
    let collisions : Array[CharacterCollision3d] = []
    let query = ctx
      .query()
      .with_filter(
        @collision.QueryFilter3DReal::new().exclude_collider(ch.handle),
      )
    let movement = kcc.controller.move_shape(
      dt,
      query,
      ctx.rigid_bodies,
      ctx.colliders,
      shape,
      character_pos,
      mg_vec3_to_rapier(kcc.translation),
      fn(c) { collisions.push(CharacterCollision3d::from_rapier(ctx, c)) },
    )
    let eff = rapier_vec3_to_mg(movement.translation())

    let mut t = (try! ecs_world.get_by_key(entity, @transform.ecs_key_transform)).unwrap_or(
      @transform.Transform::identity(),
    )
    t = @transform.Transform::new(
      @math.Vec3::new(
        t.translation.x + eff.x,
        t.translation.y + eff.y,
        t.translation.z + eff.z,
      ),
      t.rotation,
      t.scale,
    )
    if (try! ecs_world.contains_by_key(entity, @transform.ecs_key_transform)) {
      try! (ecs_world.replace(entity, @transform.ecs_key_transform, t) |> ignore)
    } else {
      try! ecs_world.set_by_key(entity, @transform.ecs_key_transform, t)
    }

    if ctx.colliders.get_mut(ch.handle) is Some(col_mut) {
      col_mut.set_position(mg_transform_to_iso3(t))
    }

    let out = KinematicCharacterControllerOutput3d::{
      effective_translation: eff,
      grounded: movement.is_grounded(),
      sliding_down_slope: movement.is_sliding_down_slope(),
      collisions,
    }
    if (try! ecs_world.contains_by_key(
        entity, ecs_key_kinematic_character_controller_output3d,
      )) {
      try! (ecs_world.replace(
        entity, ecs_key_kinematic_character_controller_output3d, out,
      )
      |> ignore)
    } else {
      try! ecs_world.set_by_key(
        entity, ecs_key_kinematic_character_controller_output3d, out,
      )
    }
    try! (ecs_world.replace(
      entity,
      ecs_key_kinematic_character_controller3d,
      KinematicCharacterController3d::{ ..kcc }.reset_translation(),
    )
    |> ignore)
  })

  ctx.query_pipeline.update(ctx.rigid_bodies, ctx.colliders)
  ctx_res.insert(ctx_ref.val)
}
