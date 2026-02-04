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
/// Joint systems for Physics2D integration.

///|
fn entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
pub fn[
  W : @core.ChangeTickWorld + Has_ImpulseJoint2d + Has_MultibodyJoint2d + Has_RapierBodyHandle2d + Has_RapierImpulseJointHandle2d + Has_RapierMultibodyJointHandle2d + HasRes_Physics2dContext,
] physics2d_sync_joints_system(
  world : W,
) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let ctx_res = HasRes_Physics2dContext::get_physics2d_context_resource(world)
  guard ctx_res.get_ref_mut(tick) is Some(ctx_ref) else { return }
  let ctx = ctx_ref.val
  let body_handle_store = Has_RapierBodyHandle2d::get_rapier_body_handle2d_store(
    world,
  )
  let impulse_joint_store = Has_ImpulseJoint2d::get_impulse_joint2d_store(world)
  let multibody_joint_store = Has_MultibodyJoint2d::get_multibody_joint2d_store(
    world,
  )
  let impulse_handle_store = Has_RapierImpulseJointHandle2d::get_rapier_impulse_joint_handle2d_store(
    world,
  )
  let multibody_handle_store = Has_RapierMultibodyJointHandle2d::get_rapier_multibody_joint_handle2d_store(
    world,
  )

  // Drop stale handles (e.g. when Rapier removed the joint because a body was removed).
  let drop_impulse : Array[@core.Entity] = []
  impulse_handle_store.for_each(fn(e, h) {
    if !ctx.impulse_joints.contains(h.handle) {
      drop_impulse.push(e)
    }
  })
  for e in drop_impulse {
    impulse_handle_store.remove(e) |> ignore
    ctx.entity_to_impulse_joint.remove(entity_key(e))
  }
  let drop_multibody : Array[@core.Entity] = []
  multibody_handle_store.for_each(fn(e, h) {
    // moon_rapier doesn't expose `contains` for multibody joints, so use `get`.
    if ctx.multibody_joints.get(h.handle) is None {
      drop_multibody.push(e)
    }
  })
  for e in drop_multibody {
    multibody_handle_store.remove(e) |> ignore
    ctx.entity_to_multibody_joint.remove(entity_key(e))
  }

  // If the authoring "other" entity changes or bodies are missing, reset and reinsert later.
  let reset_impulse : Array[@core.Entity] = []
  impulse_handle_store.for_each(fn(e, h) {
    let bh1 = body_handle_store.get(e)
    let author = impulse_joint_store.get(e)
    if bh1 is None || author is None {
      reset_impulse.push(e)
      return
    }
    let j = author.unwrap()
    if !entity_eq(h.other, j.other) {
      reset_impulse.push(e)
      return
    }
    if body_handle_store.get(j.other) is None {
      reset_impulse.push(e)
      return
    }
  })
  for e in reset_impulse {
    if impulse_handle_store.get(e) is Some(h) {
      ctx.impulse_joints.remove(h.handle, true) |> ignore
    }
    impulse_handle_store.remove(e) |> ignore
    ctx.entity_to_impulse_joint.remove(entity_key(e))
  }
  let reset_multibody : Array[@core.Entity] = []
  multibody_handle_store.for_each(fn(e, h) {
    let bh1 = body_handle_store.get(e)
    let author = multibody_joint_store.get(e)
    if bh1 is None || author is None {
      reset_multibody.push(e)
      return
    }
    let j = author.unwrap()
    if !entity_eq(h.other, j.other) {
      reset_multibody.push(e)
      return
    }
    if body_handle_store.get(j.other) is None {
      reset_multibody.push(e)
      return
    }
  })
  for e in reset_multibody {
    if multibody_handle_store.get(e) is Some(h) {
      ctx.multibody_joints.remove(h.handle, true)
    }
    multibody_handle_store.remove(e) |> ignore
    ctx.entity_to_multibody_joint.remove(entity_key(e))
  }

  // Insert missing impulse joints.
  impulse_joint_store.for_each(fn(e, j) {
    if impulse_handle_store.contains(e) {
      return
    }
    guard body_handle_store.get(e) is Some(bh1) else { return }
    guard body_handle_store.get(j.other) is Some(bh2) else { return }
    let handle = ctx.impulse_joints.insert(
      bh1.handle,
      bh2.handle,
      j.data,
      j.wake_up,
    )
    impulse_handle_store.insert(
      e,
      RapierImpulseJointHandle2d::new(handle, j.other),
      tick,
    )
    ctx.entity_to_impulse_joint.set(entity_key(e), handle)
  })

  // Insert missing multibody joints.
  multibody_joint_store.for_each(fn(e, j) {
    if multibody_handle_store.contains(e) {
      return
    }
    guard body_handle_store.get(e) is Some(bh1) else { return }
    guard body_handle_store.get(j.other) is Some(bh2) else { return }
    let handle = if j.kinematic {
      ctx.multibody_joints.insert_kinematic(
        bh1.handle,
        bh2.handle,
        j.data,
        j.wake_up,
      )
    } else {
      ctx.multibody_joints.insert(bh1.handle, bh2.handle, j.data, j.wake_up)
    }
    match handle {
      Some(h) => {
        multibody_handle_store.insert(
          e,
          RapierMultibodyJointHandle2d::new(h, j.other),
          tick,
        )
        ctx.entity_to_multibody_joint.set(entity_key(e), h)
      }
      None => ()
    }
  })
}
