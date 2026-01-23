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
/// Ported from rapier/src/dynamics/joint/impulse_joint/impulse_joint_set.rs examples.
test "impulse joint set insert remove" {
  let bodies = RigidBodySet::new()
  let joints = ImpulseJointSet::new()
  let body1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let joint = GenericJoint::from_revolute(RevoluteJointBuilder::new().build())
  let handle = joints.insert(body1, body2, joint, true)
  inspect(joints.len() == 1, content="true")
  inspect(!joints.is_empty(), content="true")
  inspect(joints.contains(handle), content="true")
  inspect(joints.get(handle) is Some(_), content="true")
  let removed = joints.remove(handle, true)
  inspect(removed is Some(_), content="true")
  inspect(joints.len() == 0, content="true")
  inspect(joints.is_empty(), content="true")
  inspect(!joints.contains(handle), content="true")
}

///|
/// Ported from rapier/src/dynamics/joint/impulse_joint/impulse_joint_set.rs examples.
test "impulse joint set attached and between" {
  let bodies = RigidBodySet::new()
  let joints = ImpulseJointSet::new()
  let body1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body3 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let joint = GenericJoint::from_revolute(RevoluteJointBuilder::new().build())
  joints.insert(body1, body2, joint, true) |> ignore
  joints.insert(body1, body3, joint, true) |> ignore
  joints.insert(body2, body3, joint, true) |> ignore
  inspect(joints.attached_joints(body1).length() == 2, content="true")
  inspect(joints.attached_joints(body2).length() == 2, content="true")
  inspect(joints.joints_between(body1, body2).length() == 1, content="true")
  inspect(joints.joints_between(body1, body3).length() == 1, content="true")
  inspect(joints.joints_between(body2, body3).length() == 1, content="true")
}

///|
/// Ported from rapier/src/dynamics/joint/impulse_joint/impulse_joint_set.rs behavior.
test "impulse joint set enabled filtering" {
  let bodies = RigidBodySet::new()
  let joints = ImpulseJointSet::new()
  let body1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body3 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let joint = GenericJoint::from_revolute(RevoluteJointBuilder::new().build())
  let handle1 = joints.insert(body1, body2, joint, true)
  let handle2 = joints.insert(body1, body3, joint, true)
  handle1 |> ignore
  joints.set_enabled(handle2, false)
  inspect(joints.attached_enabled_joints(body1).length(), content="1")
  joints.set_enabled(handle2, true)
  inspect(joints.attached_enabled_joints(body1).length(), content="2")
}

///|
/// Ported from rapier/src/dynamics/joint/impulse_joint/impulse_joint_set.rs examples.
test "impulse joint set remove attached" {
  let bodies = RigidBodySet::new()
  let joints = ImpulseJointSet::new()
  let body1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body3 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let joint = GenericJoint::from_revolute(RevoluteJointBuilder::new().build())
  let handle1 = joints.insert(body1, body2, joint, true)
  let handle2 = joints.insert(body1, body3, joint, true)
  let handle3 = joints.insert(body2, body3, joint, true)
  let removed = joints.remove_joints_attached_to_rigid_body(body1)
  inspect(removed.length() == 2, content="true")
  inspect(!joints.contains(handle1), content="true")
  inspect(!joints.contains(handle2), content="true")
  inspect(joints.contains(handle3), content="true")
  inspect(joints.len() == 1, content="true")
}

///|
/// Ported from rapier/src/dynamics/joint/impulse_joint/impulse_joint_set.rs behavior.
test "impulse joint wake and join queues" {
  let bodies = RigidBodySet::new()
  let joints = ImpulseJointSet::new()
  let body1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let body2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let joint = GenericJoint::from_revolute(RevoluteJointBuilder::new().build())
  joints.insert(body1, body2, joint, true) |> ignore
  joints.insert(body1, body2, joint, true) |> ignore
  let join_pairs = joints.take_to_join()
  inspect(join_pairs.length() == 1, content="true")
  let wake_handles = joints.take_wake_up()
  inspect(wake_handles.length() == 2, content="true")
  inspect(joints.take_wake_up().length() == 0, content="true")
  let handle = joints.insert(body1, body2, joint, false)
  joints.take_to_join() |> ignore
  inspect(joints.take_wake_up().length() == 0, content="true")
  joints.remove(handle, true) |> ignore
  inspect(joints.take_wake_up().length() == 2, content="true")
}
