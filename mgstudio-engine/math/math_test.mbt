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
fn vec3_within_half_size(value : Vec3, half_size : Vec3) -> Bool {
  abs_float(value.x) <= half_size.x &&
  abs_float(value.y) <= half_size.y &&
  abs_float(value.z) <= half_size.z
}

///|
test "math: cuboid constructors preserve Bevy full-size semantics" {
  let cuboid = Cuboid::new(3.0F, 7.0F, 2.0F)
  debug_inspect(
    approx_vec3(cuboid.half_size, Vec3::new(1.5F, 3.5F, 1.0F)),
    content="true",
  )
  debug_inspect(
    approx_vec3(cuboid.size(), Vec3::new(3.0F, 7.0F, 2.0F)),
    content="true",
  )
  debug_inspect(
    approx_vec3(
      Cuboid::from_size(Vec3::new(3.0F, 7.0F, 2.0F)).half_size,
      cuboid.half_size,
    ),
    content="true",
  )
  debug_inspect(
    approx_vec3(Cuboid::from_length(2.0F).half_size, Vec3::splat(1.0F)),
    content="true",
  )
  debug_inspect(
    approx_vec3(Cuboid::default().half_size, Vec3::splat(0.5F)),
    content="true",
  )
}

///|
test "math: cuboid from_corners ignores corner order like Bevy" {
  let lhs = Cuboid::from_corners(
    Vec3::new(-1.5F, -3.5F, -1.0F),
    Vec3::new(1.5F, 3.5F, 1.0F),
  )
  let rhs = Cuboid::from_corners(
    Vec3::new(1.5F, 3.5F, 1.0F),
    Vec3::new(-1.5F, -3.5F, -1.0F),
  )
  debug_inspect(
    approx_vec3(lhs.half_size, Vec3::new(1.5F, 3.5F, 1.0F)),
    content="true",
  )
  debug_inspect(approx_vec3(lhs.half_size, rhs.half_size), content="true")
}

///|
test "math: cuboid sample_interior is seeded and stays inside bounds" {
  let cuboid = Cuboid::new(3.0F, 7.0F, 2.0F)
  let rng0 = @random.Rand::chacha8(seed=b"mathcuboidsampleseed000000000001")
  let rng1 = @random.Rand::chacha8(seed=b"mathcuboidsampleseed000000000001")
  let sample0 = cuboid.sample_interior(rng0)
  let sample1 = cuboid.sample_interior(rng1)
  debug_inspect(approx_vec3(sample0, sample1), content="true")
  debug_inspect(
    vec3_within_half_size(sample0, cuboid.half_size),
    content="true",
  )

  let degenerate = Cuboid::from_size(Vec3::zero())
  let zero_sample = degenerate.sample_interior(
    @random.Rand::chacha8(seed=b"mathcuboidzeroseed00000000000001"),
  )
  debug_inspect(approx_vec3(zero_sample, Vec3::zero()), content="true")
}

///|
test "math: vec3 smooth_nudge moves towards target" {
  let value = Vec3::new(0.0F, 0.0F, 0.0F)
  value.smooth_nudge(Vec3::new(10.0F, 0.0F, 0.0F), 1.0F, 1.0F)
  debug_inspect(value.x > 6.3F && value.x < 6.4F, content="true")
  debug_inspect(value.y == 0.0F && value.z == 0.0F, content="true")
}

///|
test "math: vec3 element helpers follow bevy-style scale helpers" {
  let value = Vec3::new(1.25F, -2.75F, 0.5F)
  debug_inspect(value.max_element() == 1.25F, content="true")
  debug_inspect(value.min_element() == -2.75F, content="true")
  let floored = value.floor()
  debug_inspect(
    floored.x == 1.0F && floored.y == -3.0F && floored.z == 0.0F,
    content="true",
  )
  let ceiled = value.ceil()
  debug_inspect(
    ceiled.x == 2.0F && ceiled.y == -2.0F && ceiled.z == 1.0F,
    content="true",
  )
  let zxy = value.zxy()
  debug_inspect(
    zxy.x == 0.5F && zxy.y == 1.25F && zxy.z == -2.75F,
    content="true",
  )
}

///|
test "math: vec2 normalize_or_zero normalizes nonzero vectors" {
  let value = Vec2::new(3.0F, 4.0F).normalize_or_zero()
  debug_inspect(value.x == 0.6F, content="true")
  debug_inspect(value.y == 0.8F, content="true")
  let zero = Vec2::zero().normalize_or_zero()
  debug_inspect(zero.x == 0.0F, content="true")
  debug_inspect(zero.y == 0.0F, content="true")
}

///|
test "math: pi matches two half turns" {
  debug_inspect(pi() > 3.1415F && pi() < 3.1416F, content="true")
  debug_inspect(pi_half() * 2.0F == pi(), content="true")
}

///|
test "math: quat to_euler YXZ roundtrips orbit rotations" {
  let rotation = Quat::from_euler(EulerRot::YXZ, 0.65F, -0.31F, 0.42F)
  let (yaw, pitch, roll) = rotation.to_euler(EulerRot::YXZ)
  let rebuilt = Quat::from_euler(EulerRot::YXZ, yaw, pitch, roll)
  debug_inspect(quat_same_rotation(rotation, rebuilt), content="true")
}

///|
test "math: quat to_euler supports XYZ and ZYX orders" {
  let xyz = Quat::from_euler(EulerRot::XYZ, 0.25F, -0.5F, 0.75F)
  let xyz_angles = xyz.to_euler(EulerRot::XYZ)
  debug_inspect(
    quat_same_rotation(
      xyz,
      Quat::from_euler(EulerRot::XYZ, xyz_angles.0, xyz_angles.1, xyz_angles.2),
    ),
    content="true",
  )

  let zyx = Quat::from_euler(EulerRot::ZYX, 0.9F, -0.2F, 0.3F)
  let zyx_angles = zyx.to_euler(EulerRot::ZYX)
  debug_inspect(
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
  debug_inspect(quat_same_rotation(halfway, expected_half), content="true")

  let end_180 = Quat::from_rotation_y(pi())
  let negated = Quat::{
    x: -end_180.x,
    y: -end_180.y,
    z: -end_180.z,
    w: -end_180.w,
  }
  debug_inspect(
    quat_same_rotation(start.lerp(negated, 1.0F), end_180),
    content="true",
  )
}

///|
test "math: extrinsic EulerRot aliases reverse intrinsic order" {
  let intrinsic = Quat::from_euler(EulerRot::ZXY, 0.2F, 0.4F, -0.6F)
  let extrinsic = Quat::from_euler(EulerRot::YXZEx, -0.6F, 0.4F, 0.2F)
  debug_inspect(quat_same_rotation(intrinsic, extrinsic), content="true")

  let extrinsic_angles = extrinsic.to_euler(EulerRot::YXZEx)
  debug_inspect(
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
