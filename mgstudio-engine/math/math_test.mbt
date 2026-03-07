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
fn abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn approx_eq(a : Float, b : Float) -> Bool {
  abs_float(a - b) < 0.0001F
}

///|
fn quat_same_rotation(a : Quat, b : Quat) -> Bool {
  let direct = approx_eq(a.x, b.x) &&
    approx_eq(a.y, b.y) &&
    approx_eq(a.z, b.z) &&
    approx_eq(a.w, b.w)
  if direct {
    return true
  }
  approx_eq(a.x, -b.x) &&
  approx_eq(a.y, -b.y) &&
  approx_eq(a.z, -b.z) &&
  approx_eq(a.w, -b.w)
}

///|
test "math: vec3 smooth_nudge moves towards target" {
  let value = Vec3::new(0.0F, 0.0F, 0.0F)
  value.smooth_nudge(Vec3::new(10.0F, 0.0F, 0.0F), 1.0F, 1.0F)
  inspect(value.x > 6.3F && value.x < 6.4F, content="true")
  inspect(value.y == 0.0F && value.z == 0.0F, content="true")
}

///|
test "math: vec2 normalize_or_zero normalizes nonzero vectors" {
  let value = Vec2::new(3.0F, 4.0F).normalize_or_zero()
  inspect(value.x == 0.6F, content="true")
  inspect(value.y == 0.8F, content="true")
  let zero = Vec2::zero().normalize_or_zero()
  inspect(zero.x == 0.0F, content="true")
  inspect(zero.y == 0.0F, content="true")
}

///|
test "math: transform looking_to aligns forward direction" {
  let transform = Transform::from_xyz(1.0F, 2.0F, 3.0F).looking_to(
    Vec3::new(0.0F, 0.0F, -2.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let forward = transform.forward()
  inspect(forward.x == 0.0F, content="true")
  inspect(forward.y == 0.0F, content="true")
  inspect(forward.z < -0.999F, content="true")
}

///|
test "math: transform rotate_z updates z rotation" {
  let transform = Transform::identity()
  transform.rotate_z(pi_half())
  inspect(
    transform.rotation_z() > 1.56F && transform.rotation_z() < 1.58F,
    content="true",
  )
}

///|
test "math: pi matches two half turns" {
  inspect(pi() > 3.1415F && pi() < 3.1416F, content="true")
  inspect(pi_half() * 2.0F == pi(), content="true")
}

///|
test "math: quat to_euler YXZ roundtrips orbit rotations" {
  let rotation = Quat::from_euler(EulerRot::YXZ, 0.65F, -0.31F, 0.42F)
  let (yaw, pitch, roll) = rotation.to_euler(EulerRot::YXZ)
  let rebuilt = Quat::from_euler(EulerRot::YXZ, yaw, pitch, roll)
  inspect(quat_same_rotation(rotation, rebuilt), content="true")
}

///|
test "math: quat to_euler supports XYZ and ZYX orders" {
  let xyz = Quat::from_euler(EulerRot::XYZ, 0.25F, -0.5F, 0.75F)
  let xyz_angles = xyz.to_euler(EulerRot::XYZ)
  inspect(
    quat_same_rotation(
      xyz,
      Quat::from_euler(EulerRot::XYZ, xyz_angles.0, xyz_angles.1, xyz_angles.2),
    ),
    content="true",
  )

  let zyx = Quat::from_euler(EulerRot::ZYX, 0.9F, -0.2F, 0.3F)
  let zyx_angles = zyx.to_euler(EulerRot::ZYX)
  inspect(
    quat_same_rotation(
      zyx,
      Quat::from_euler(EulerRot::ZYX, zyx_angles.0, zyx_angles.1, zyx_angles.2),
    ),
    content="true",
  )
}

///|
test "math: extrinsic EulerRot aliases reverse intrinsic order" {
  let intrinsic = Quat::from_euler(EulerRot::ZXY, 0.2F, 0.4F, -0.6F)
  let extrinsic = Quat::from_euler(EulerRot::YXZEx, -0.6F, 0.4F, 0.2F)
  inspect(quat_same_rotation(intrinsic, extrinsic), content="true")

  let extrinsic_angles = extrinsic.to_euler(EulerRot::YXZEx)
  inspect(
    quat_same_rotation(
      extrinsic,
      Quat::from_euler(
        EulerRot::YXZEx,
        extrinsic_angles.0,
        extrinsic_angles.1,
        extrinsic_angles.2,
      ),
    ),
    content="true",
  )
}
