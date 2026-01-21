// Copyright 2025 International Digital Economy Academy
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
/// Ported from rapier/src/dynamics/joint/multibody_joint/multibody_ik.rs (one_link_fwd_kinematics).
test "one link fwd kinematics" {
  let bodies = RigidBodySet::new()
  let multibodies = MultibodyJointSet::new()
  let num_segments = 10
  let body = RigidBodyBuilder::fixed().build()
  let mut last_body = bodies.insert(body)
  let mut last_link = MultibodyJointHandle::invalid()
  for _ in 0..<num_segments {
    let body_dyn = RigidBodyBuilder::dynamic().can_sleep(false).build()
    let new_body = bodies.insert(body_dyn)
    let builder = RevoluteJointBuilder::new()
      .local_anchor1(@core.Vec2::new(0.0F, 0.05F))
      .local_anchor2(@core.Vec2::new(0.0F, -0.05F))
    let link = multibodies.insert(last_body, new_body, builder.build(), true)
    if link is Some(handle) {
      last_link = handle
    }
    last_body = new_body
  }
  if multibodies.get_mut(last_link) is Some(result) {
    let (multibody, last_id) = result
    multibody.forward_kinematics(bodies, true)
    inspect(multibody.ndofs() == num_segments, content="true")
    let jacobian2 = Jacobian::zeros(0)
    let link_pose2 = multibody.forward_kinematics_single_link(
      bodies,
      last_id,
      None,
      Some(jacobian2),
    )
    let link = multibody.link(last_id)
    if link is Some(link_value) {
      let link_pose1 = link_value.local_to_world()
      let jacobian1 = multibody.body_jacobian(last_id)
      inspect(jacobian1.equals(jacobian2), content="true")
      inspect(
        link_pose1.translation.x == link_pose2.translation.x,
        content="true",
      )
      inspect(
        link_pose1.translation.y == link_pose2.translation.y,
        content="true",
      )
    }
    let niter = 100
    let niter_real = Float::from_double(niter.to_double())
    let displacement_part : Array[@core.Real] = []
    for i in 0..<multibody.ndofs() {
      let value = Float::from_double(i.to_double()) * -0.1F / niter_real
      displacement_part.push(value)
    }
    let displacement_total : Array[@core.Real] = []
    for value in displacement_part {
      displacement_total.push(value * niter_real)
    }
    multibody.forward_kinematics_single_link(
      bodies,
      last_id,
      Some(displacement_total),
      Some(jacobian2),
    )
    |> ignore
    for _ in 0..<niter {
      multibody.apply_displacements(displacement_part)
      multibody.forward_kinematics(bodies, false)
    }
  }
}
