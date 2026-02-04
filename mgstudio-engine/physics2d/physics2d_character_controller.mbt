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
/// Kinematic character controller integration (2D).

///|
pub struct CharacterCollision2d {
  /// The entity that owns the hit collider (if known).
  other : @core.Entity?
  toi : Float
  point : @math.Vec2
  normal : @math.Vec2
  translation_applied : @math.Vec2
  translation_remaining : @math.Vec2
}

///|
pub fn CharacterCollision2d::from_rapier(
  ctx : Physics2dContext,
  c : @control.CharacterCollision,
) -> CharacterCollision2d {
  let h = c.handle()
  let other = ctx.collider_to_entity.get(h.into_raw_parts())
  let hit = c.hit()
  {
    other,
    toi: hit.toi(),
    point: rapier_vec2_to_mg(hit.point()),
    normal: rapier_vec2_to_mg(hit.normal()),
    translation_applied: rapier_vec2_to_mg(c.translation_applied()),
    translation_remaining: rapier_vec2_to_mg(c.translation_remaining()),
  }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct KinematicCharacterController2d {
  /// Desired movement (one-shot). The system resets this to zero each fixed step.
  translation : @math.Vec2
  controller : @control.KinematicCharacterController
}

///|
pub fn KinematicCharacterController2d::default() -> KinematicCharacterController2d {
  {
    translation: @math.Vec2::new(0.0F, 0.0F),
    controller: @control.KinematicCharacterController::default(),
  }
}

///|
pub fn KinematicCharacterController2d::with_translation(
  self : KinematicCharacterController2d,
  translation : @math.Vec2,
) -> KinematicCharacterController2d {
  KinematicCharacterController2d::{ ..self, translation, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct KinematicCharacterControllerOutput2d {
  effective_translation : @math.Vec2
  grounded : Bool
  sliding_down_slope : Bool
  mut collisions : Array[CharacterCollision2d]
}

///|
pub fn KinematicCharacterControllerOutput2d::new() -> KinematicCharacterControllerOutput2d {
  {
    effective_translation: @math.Vec2::new(0.0F, 0.0F),
    grounded: false,
    sliding_down_slope: false,
    collisions: [],
  }
}

///|
pub fn[
  W : @core.ChangeTickWorld + @math.Has_Transform + Has_KinematicCharacterController2d + Has_KinematicCharacterControllerOutput2d + Has_RapierBodyHandle2d + Has_RapierColliderHandle2d + HasRes_Physics2dContext,
] physics2d_character_controller_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val

  // Ensure queries see the latest collider positions (e.g. standalone colliders synced from Transform).
  ctx.query_pipeline.update()
  let dt = @app.fixed_time_timestep_seconds()
  let transform_store = @math.Has_Transform::get_transform_store(world)
  let body_handle_store = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(
    world,
  )
  let collider_handle_store = Has_RapierColliderHandle2d::get_rapier_collider_handle2d_store(
    world,
  )
  let controller_store = Has_KinematicCharacterController2d::get_kinematic_character_controller2d_store(
    world,
  )
  let output_store = Has_KinematicCharacterControllerOutput2d::get_kinematic_character_controller_output2d_store(
    world,
  )
  controller_store.for_each(fn(entity, kcc) {
    // Avoid conflicting with rigid-body driven motion for now.
    if body_handle_store.contains(entity) {
      return
    }
    if kcc.translation.x == 0.0F && kcc.translation.y == 0.0F {
      return
    }
    guard collider_handle_store.get(entity) is Some(ch) else { return }
    guard ctx.colliders.get(ch.handle) is Some(col) else { return }
    let shape = col.shape()
    let character_pos = col.position()
    let collisions : Array[CharacterCollision2d] = []
    let query = ctx
      .query()
      .with_filter(@collision.QueryFilter::new().exclude_collider(ch.handle))
    let movement = kcc.controller.move_shape(
      dt,
      query,
      shape,
      character_pos,
      mg_vec2_to_rapier(kcc.translation),
      fn(c) { collisions.push(CharacterCollision2d::from_rapier(ctx, c)) },
    )
    let eff = rapier_vec2_to_mg(movement.translation())

    // Apply to ECS transform.
    let mut t = transform_store
      .get(entity)
      .unwrap_or(@math.Transform::identity())
    t = @math.Transform::new(
      @math.Vec3::new(
        t.translation.x + eff.x,
        t.translation.y + eff.y,
        t.translation.z,
      ),
      t.rotation,
      t.scale,
    )
    if transform_store.contains(entity) {
      transform_store.set(entity, t, tick) |> ignore
    } else {
      transform_store.insert(entity, t, tick)
    }

    // Apply to Rapier collider immediately so the next physics step sees it.
    if ctx.colliders.get_mut_internal_with_modification_tracking(ch.handle)
      is Some(col_mut) {
      let next_pos = mg_transform_to_iso2(t)
      col_mut.set_position(next_pos) |> ignore
    }

    // Write output and reset one-shot input.
    let out = KinematicCharacterControllerOutput2d::{
      effective_translation: eff,
      grounded: movement.is_grounded(),
      sliding_down_slope: movement.is_sliding_down_slope(),
      collisions,
    }
    if output_store.contains(entity) {
      output_store.set(entity, out, tick) |> ignore
    } else {
      output_store.insert(entity, out, tick)
    }
    controller_store.set(
      entity,
      KinematicCharacterController2d::{
        ..kcc,
        translation: @math.Vec2::new(0.0F, 0.0F),
      },
      tick,
    )
    |> ignore
  })

  // Colliders moved; keep query pipeline consistent.
  ctx.query_pipeline.update()
}
