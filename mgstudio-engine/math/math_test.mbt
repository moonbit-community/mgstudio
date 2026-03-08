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
fn approx_vec3(a : Vec3, b : Vec3) -> Bool {
  approx_eq(a.x, b.x) && approx_eq(a.y, b.y) && approx_eq(a.z, b.z)
}

///|
fn rotate_vec3(rotation : Quat, value : Vec3) -> Vec3 {
  let qv = Vec3::new(rotation.x, rotation.y, rotation.z)
  let t = qv.cross(value).mul_scalar(2.0F)
  value.add(t.mul_scalar(rotation.w)).add(qv.cross(t))
}

///|
test "math: vec3 smooth_nudge moves towards target" {
  let value = Vec3::new(0.0F, 0.0F, 0.0F)
  value.smooth_nudge(Vec3::new(10.0F, 0.0F, 0.0F), 1.0F, 1.0F)
  inspect(value.x > 6.3F && value.x < 6.4F, content="true")
  inspect(value.y == 0.0F && value.z == 0.0F, content="true")
}

///|
test "math: vec3 element helpers follow bevy-style scale helpers" {
  let value = Vec3::new(1.25F, -2.75F, 0.5F)
  inspect(value.max_element() == 1.25F, content="true")
  inspect(value.min_element() == -2.75F, content="true")
  let floored = value.floor()
  inspect(
    floored.x == 1.0F && floored.y == -3.0F && floored.z == 0.0F,
    content="true",
  )
  let ceiled = value.ceil()
  inspect(
    ceiled.x == 2.0F && ceiled.y == -2.0F && ceiled.z == 1.0F,
    content="true",
  )
  let zxy = value.zxy()
  inspect(zxy.x == 0.5F && zxy.y == 1.25F && zxy.z == -2.75F, content="true")
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
test "math: transform constructors and rotate_y preserve bevy semantics" {
  let translation = Vec3::new(1.0F, 2.0F, 3.0F)
  let from_translation = Transform::from_translation(translation)
  inspect(
    from_translation.translation.x == 1.0F &&
    from_translation.translation.y == 2.0F &&
    from_translation.translation.z == 3.0F,
    content="true",
  )
  inspect(
    from_translation.scale.x == 1.0F &&
    from_translation.scale.y == 1.0F &&
    from_translation.scale.z == 1.0F,
    content="true",
  )

  let rotation = Quat::from_rotation_y(pi_half())
  let from_rotation = Transform::from_rotation(rotation)
  inspect(quat_same_rotation(from_rotation.rotation, rotation), content="true")
  let forward = from_rotation.forward()
  inspect(approx_eq(forward.x, -1.0F), content="true")
  inspect(approx_eq(forward.y, 0.0F), content="true")
  inspect(approx_eq(forward.z, 0.0F), content="true")

  let rotated = Transform::identity()
  rotated.rotate_y(pi_half())
  inspect(quat_same_rotation(rotated.rotation, rotation), content="true")
}

///|
test "math: transform rotate_around orbits translation and rotation" {
  let transform = Transform::from_xyz(1.0F, 0.0F, 0.0F)
  transform.rotate_around(Vec3::zero(), Quat::from_rotation_y(pi_half()))
  inspect(approx_eq(transform.translation.x, 0.0F), content="true")
  inspect(approx_eq(transform.translation.y, 0.0F), content="true")
  inspect(approx_eq(transform.translation.z, -1.0F), content="true")
  inspect(
    approx_vec3(transform.forward(), Vec3::new(-1.0F, 0.0F, 0.0F)),
    content="true",
  )
}

///|
test "math: transform align matches Bevy documented example" {
  let transform = Transform::identity()
  transform.align(
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
    Vec3::new(1.0F, 1.0F, 0.0F),
    Vec3::new(0.0F, 0.0F, 1.0F),
  )
  let main_axis_image = rotate_vec3(
    transform.rotation,
    Vec3::new(1.0F, 0.0F, 0.0F),
  )
  let secondary_axis_image = rotate_vec3(
    transform.rotation,
    Vec3::new(1.0F, 1.0F, 0.0F),
  )
  inspect(
    approx_vec3(main_axis_image, Vec3::new(0.0F, 1.0F, 0.0F)),
    content="true",
  )
  inspect(
    approx_vec3(secondary_axis_image, Vec3::new(0.0F, 1.0F, 1.0F)),
    content="true",
  )
}

///|
test "math: transform align falls back to Bevy default axes" {
  let lhs = Transform::identity()
  lhs.align(
    Vec3::zero(),
    Vec3::new(0.0F, 0.0F, 1.0F),
    Vec3::zero(),
    Vec3::new(1.0F, 0.0F, 0.0F),
  )
  let rhs = Transform::identity()
  rhs.align(
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(0.0F, 0.0F, 1.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
    Vec3::new(1.0F, 0.0F, 0.0F),
  )
  inspect(quat_same_rotation(lhs.rotation, rhs.rotation), content="true")
}

///|
test "math: transform align ignores degenerate secondary pair like Bevy" {
  let transform = Transform::identity()
  transform.align(
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(0.0F, 0.0F, 1.0F),
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
  )
  inspect(
    approx_vec3(transform.right(), Vec3::new(0.0F, 0.0F, 1.0F)),
    content="true",
  )
  inspect(
    approx_vec3(transform.up(), Vec3::new(0.0F, 1.0F, 0.0F)),
    content="true",
  )
}

///|
test "math: transform aligned_by preserves translation and returns aligned copy" {
  let base = Transform::from_xyz(2.0F, 3.0F, 4.0F)
  let aligned = base.aligned_by(
    Vec3::new(0.0F, 0.0F, -1.0F),
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
  )
  inspect(quat_same_rotation(base.rotation, Quat::identity()), content="true")
  inspect(approx_vec3(aligned.translation, base.translation), content="true")
  inspect(approx_vec3(aligned.scale, base.scale), content="true")
  inspect(
    approx_vec3(aligned.forward(), Vec3::new(1.0F, 0.0F, 0.0F)),
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
test "math: quat lerp normalizes and takes the shortest path" {
  let start = Quat::identity()
  let end_90 = Quat::from_rotation_y(pi_half())
  let halfway = start.lerp(end_90, 0.5F)
  let expected_half = Quat::from_rotation_y(pi_half() / 2.0F)
  inspect(quat_same_rotation(halfway, expected_half), content="true")

  let end_180 = Quat::from_rotation_y(pi())
  let negated = Quat::{
    x: -end_180.x,
    y: -end_180.y,
    z: -end_180.z,
    w: -end_180.w,
  }
  inspect(
    quat_same_rotation(start.lerp(negated, 1.0F), end_180),
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
