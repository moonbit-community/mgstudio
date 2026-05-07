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
/// Joint systems for Physics3D integration.

///|
pub fn physics3d_sync_joints_system(world : @ecs.World) -> Unit {
  let ecs_world = world
  let ctx_res = get_physics3d_context_resource(ecs_world)
  guard ctx_res.get() is Some(current_ctx) else { return }
  let ctx_ref = Ref(current_ctx)
  let ctx = ctx_ref.val

  // Rebuild joint sets every fixed step from authoring components.
  let drop_impulse : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_impulse_joint_handle3d, fn(
    e,
    _h,
  ) {
    drop_impulse.push(e)
  })
  for e in drop_impulse {
    try! (ecs_world.take(e, ecs_key_rapier_impulse_joint_handle3d) |> ignore)
  }
  let drop_multibody : Array[@core.Entity] = []
  ecs_world.for_each_component(ecs_key_rapier_multibody_joint_handle3d, fn(
    e,
    _h,
  ) {
    drop_multibody.push(e)
  })
  for e in drop_multibody {
    try! (ecs_world.take(e, ecs_key_rapier_multibody_joint_handle3d) |> ignore)
  }
  ctx.entity_to_impulse_joint.clear()
  ctx.entity_to_multibody_joint.clear()
  ctx.impulse_joints = @dynamics.JointSet3DReal::new()
  ctx.multibody_joints = @dynamics.MultibodyJointSet3DReal::new()
  ctx.rope_joints = @dynamics.RopeJointSet3DReal::new()

  ecs_world.for_each_component(ecs_key_impulse_joint3d, fn(e, j) {
    guard (try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle3d))
      is Some(bh1) else {
      return
    }
    guard (try! ecs_world.get_by_key(j.other, ecs_key_rapier_body_handle3d))
      is Some(bh2) else {
      return
    }
    let handle = ctx.impulse_joints.insert_generic(
      bh1.handle,
      bh2.handle,
      j.data.to_3d_real(),
      j.wake_up,
    )
    try! ecs_world.set_by_key(
      e,
      ecs_key_rapier_impulse_joint_handle3d,
      RapierImpulseJointHandle3d::new(handle, j.other),
    )
    ctx.entity_to_impulse_joint.set(entity_key(e), handle)
  })

  ecs_world.for_each_component(ecs_key_multibody_joint3d, fn(e, j) {
    guard (try! ecs_world.get_by_key(e, ecs_key_rapier_body_handle3d))
      is Some(bh1) else {
      return
    }
    guard (try! ecs_world.get_by_key(j.other, ecs_key_rapier_body_handle3d))
      is Some(bh2) else {
      return
    }
    let handle = if j.kinematic {
      ctx.multibody_joints.insert_kinematic(
        bh1.handle,
        bh2.handle,
        j.data.to_3d_real(),
        j.wake_up,
      )
    } else {
      ctx.multibody_joints.insert(
        bh1.handle,
        bh2.handle,
        j.data.to_3d_real(),
        j.wake_up,
      )
    }
    match handle {
      Some(h) => {
        try! ecs_world.set_by_key(
          e,
          ecs_key_rapier_multibody_joint_handle3d,
          RapierMultibodyJointHandle3d::new(h, j.other),
        )
        ctx.entity_to_multibody_joint.set(entity_key(e), h)
      }
      None => ()
    }
  })
  ctx_res.insert(ctx_ref.val)
}
