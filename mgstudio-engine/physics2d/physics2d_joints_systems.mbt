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
pub fn physics2d_sync_joints_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics2d_context_resource(ecs_world)
  guard ctx_res.get() is Some(current_ctx) else { return }
  let ctx_ref = Ref::new(current_ctx)
  let ctx = ctx_ref.val

  // Drop stale handles (e.g. when Rapier removed the joint because a body was removed).
  let drop_impulse : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_impulse_joint_handle2d, fn(e, h) {
    if !ctx.impulse_joints.contains(h.handle) {
      drop_impulse.push(e)
    }
  })
  for e in drop_impulse {
    try! (ecs_world.take(e, ecs_key_rapier_impulse_joint_handle2d) |> ignore)
    ctx.entity_to_impulse_joint.remove(entity_key(e))
  }
  let drop_multibody : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_multibody_joint_handle2d, fn(
    e,
    h,
  ) {
    // moon_rapier doesn't expose `contains` for multibody joints, so use `get`.
    if ctx.multibody_joints.get(h.handle) is None {
      drop_multibody.push(e)
    }
  })
  for e in drop_multibody {
    try! (ecs_world.take(e, ecs_key_rapier_multibody_joint_handle2d) |> ignore)
    ctx.entity_to_multibody_joint.remove(entity_key(e))
  }

  // If the authoring "other" entity changes or bodies are missing, reset and reinsert later.
  let reset_impulse : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_impulse_joint_handle2d, fn(e, h) {
    let bh1 = try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle2d)
    let author = try! ecs_world.get_by_key(e, ecs_key_impulse_joint2d)
    if bh1 is None || author is None {
      reset_impulse.push(e)
      return
    }
    let j = author.unwrap()
    if !entity_eq(h.other, j.other) {
      reset_impulse.push(e)
      return
    }
    if (try! ecs_world.get_by_key(j.other, ecs_key_rapier_body_handle2d))
      is None {
      reset_impulse.push(e)
      return
    }
  })
  for e in reset_impulse {
    if (try! ecs_world.get_by_key(e, ecs_key_rapier_impulse_joint_handle2d))
      is Some(h) {
      ctx.impulse_joints.remove(h.handle, true) |> ignore
    }
    try! (ecs_world.take(e, ecs_key_rapier_impulse_joint_handle2d) |> ignore)
    ctx.entity_to_impulse_joint.remove(entity_key(e))
  }
  let reset_multibody : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_multibody_joint_handle2d, fn(
    e,
    h,
  ) {
    let bh1 = try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle2d)
    let author = try! ecs_world.get_by_key(e, ecs_key_multibody_joint2d)
    if bh1 is None || author is None {
      reset_multibody.push(e)
      return
    }
    let j = author.unwrap()
    if !entity_eq(h.other, j.other) {
      reset_multibody.push(e)
      return
    }
    if (try! ecs_world.get_by_key(j.other, ecs_key_rapier_body_handle2d))
      is None {
      reset_multibody.push(e)
      return
    }
  })
  for e in reset_multibody {
    if (try! ecs_world.get_by_key(e, ecs_key_rapier_multibody_joint_handle2d))
      is Some(h) {
      ctx.multibody_joints.remove(h.handle, true)
    }
    try! (ecs_world.take(e, ecs_key_rapier_multibody_joint_handle2d) |> ignore)
    ctx.entity_to_multibody_joint.remove(entity_key(e))
  }

  // Insert missing impulse joints.
  ecs_world.for_each_component(ecs_key_impulse_joint2d, fn(e, j) {
    if (try! ecs_world.contains_by_key(e, ecs_key_rapier_impulse_joint_handle2d)) {
      return
    }
    guard (try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle2d))
      is Some(bh1) else {
      return
    }
    guard (try! ecs_world.get_by_key(j.other, ecs_key_rapier_body_handle2d))
      is Some(bh2) else {
      return
    }
    let handle = ctx.impulse_joints.insert(
      bh1.handle,
      bh2.handle,
      j.data,
      j.wake_up,
    )
    try! ecs_world.set_by_key(
      e,
      ecs_key_rapier_impulse_joint_handle2d,
      RapierImpulseJointHandle2d::new(handle, j.other),
    )
    ctx.entity_to_impulse_joint.set(entity_key(e), handle)
  })

  // Insert missing multibody joints.
  ecs_world.for_each_component(ecs_key_multibody_joint2d, fn(e, j) {
    if (try! ecs_world.contains_by_key(
        e, ecs_key_rapier_multibody_joint_handle2d,
      )) {
      return
    }
    guard (try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle2d))
      is Some(bh1) else {
      return
    }
    guard (try! ecs_world.get_by_key(j.other, ecs_key_rapier_body_handle2d))
      is Some(bh2) else {
      return
    }
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
        try! ecs_world.set_by_key(
          e,
          ecs_key_rapier_multibody_joint_handle2d,
          RapierMultibodyJointHandle2d::new(h, j.other),
        )
        ctx.entity_to_multibody_joint.set(entity_key(e), h)
      }
      None => ()
    }
  })
  ctx_res.insert(ctx_ref.val)
}
