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
fn behavior_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn behavior_approx_eq(a : Float, b : Float) -> Bool {
  behavior_abs_float(a - b) < 0.0001F
}

///|
fn behavior_quat_same_rotation(a : @math.Quat, b : @math.Quat) -> Bool {
  let direct = behavior_approx_eq(a.x, b.x) &&
    behavior_approx_eq(a.y, b.y) &&
    behavior_approx_eq(a.z, b.z) &&
    behavior_approx_eq(a.w, b.w)
  if direct {
    return true
  }
  behavior_approx_eq(a.x, -b.x) &&
  behavior_approx_eq(a.y, -b.y) &&
  behavior_approx_eq(a.z, -b.z) &&
  behavior_approx_eq(a.w, -b.w)
}

///|
fn behavior_approx_vec3(a : @math.Vec3, b : @math.Vec3) -> Bool {
  behavior_approx_eq(a.x, b.x) &&
  behavior_approx_eq(a.y, b.y) &&
  behavior_approx_eq(a.z, b.z)
}

///|
fn behavior_rotate_vec3(
  rotation : @math.Quat,
  value : @math.Vec3,
) -> @math.Vec3 {
  let qv = @math.Vec3::new(rotation.x, rotation.y, rotation.z)
  let t = qv.cross(value).mul_scalar(2.0F)
  value.add(t.mul_scalar(rotation.w)).add(qv.cross(t))
}

///|
test "transform behavior: looking_to aligns forward direction" {
  let transform = Transform::from_xyz(1.0F, 2.0F, 3.0F).looking_to(
    @math.Vec3::new(0.0F, 0.0F, -2.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let forward = transform.forward()
  debug_inspect(forward.x == 0.0F, content="true")
  debug_inspect(forward.y == 0.0F, content="true")
  debug_inspect(forward.z < -0.999F, content="true")
}

///|
test "transform behavior: looking_to aligns arbitrary forward and back" {
  let direction = @math.Vec3::new(0.35F, -0.2F, -0.9F).normalize_or_zero()
  let transform = Transform::from_xyz(1.0F, 2.0F, 3.0F).looking_to(
    direction,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let forward = transform.forward()
  let back = transform.back()
  debug_inspect(forward.dot(direction) > 0.999F, content="true")
  debug_inspect(back.dot(direction.neg()) > 0.999F, content="true")
}

///|
test "transform behavior: rotate_z updates z rotation" {
  let transform = Transform::identity()
  transform.rotate_z(@math.pi_half())
  debug_inspect(
    transform.rotation_z() > 1.56F && transform.rotation_z() < 1.58F,
    content="true",
  )
}

///|
test "transform behavior: constructors and rotate_y preserve semantics" {
  let translation = @math.Vec3::new(1.0F, 2.0F, 3.0F)
  let from_translation = Transform::from_translation(translation)
  debug_inspect(
    from_translation.translation.x == 1.0F &&
    from_translation.translation.y == 2.0F &&
    from_translation.translation.z == 3.0F,
    content="true",
  )
  debug_inspect(
    from_translation.scale.x == 1.0F &&
    from_translation.scale.y == 1.0F &&
    from_translation.scale.z == 1.0F,
    content="true",
  )

  let rotation = @math.Quat::from_rotation_y(@math.pi_half())
  let from_rotation = Transform::from_rotation(rotation)
  debug_inspect(
    behavior_quat_same_rotation(from_rotation.rotation, rotation),
    content="true",
  )
  let forward = from_rotation.forward()
  debug_inspect(behavior_approx_eq(forward.x, -1.0F), content="true")
  debug_inspect(behavior_approx_eq(forward.y, 0.0F), content="true")
  debug_inspect(behavior_approx_eq(forward.z, 0.0F), content="true")

  let rotated = Transform::identity()
  rotated.rotate_y(@math.pi_half())
  debug_inspect(
    behavior_quat_same_rotation(rotated.rotation, rotation),
    content="true",
  )
}

///|
test "transform behavior: global affine axes match directional helpers" {
  let transform = Transform::from_xyz(1.25F, -0.5F, 2.0F).looking_to(
    @math.Vec3::new(0.35F, 0.1F, -0.9F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  transform.scale = @math.Vec3::new(1.5F, 0.75F, 2.0F)
  let affine = GlobalTransform::from_transform(transform).affine()
  debug_inspect(
    behavior_approx_vec3(
      affine.matrix3.x_axis,
      transform.right().mul_scalar(transform.scale.x),
    ),
    content="true",
  )
  debug_inspect(
    behavior_approx_vec3(
      affine.matrix3.y_axis,
      transform.up().mul_scalar(transform.scale.y),
    ),
    content="true",
  )
  debug_inspect(
    behavior_approx_vec3(
      affine.matrix3.z_axis,
      transform.back().mul_scalar(transform.scale.z),
    ),
    content="true",
  )
  debug_inspect(
    behavior_approx_vec3(
      affine.transform_point3(@math.Vec3::new(0.0F, 0.0F, -1.0F)),
      transform.translation.add(
        transform.forward().mul_scalar(transform.scale.z),
      ),
    ),
    content="true",
  )
}

///|
test "transform behavior: rotate_around orbits translation and rotation" {
  let transform = Transform::from_xyz(1.0F, 0.0F, 0.0F)
  transform.rotate_around(
    @math.Vec3::zero(),
    @math.Quat::from_rotation_y(@math.pi_half()),
  )
  debug_inspect(
    behavior_approx_eq(transform.translation.x, 0.0F),
    content="true",
  )
  debug_inspect(
    behavior_approx_eq(transform.translation.y, 0.0F),
    content="true",
  )
  debug_inspect(
    behavior_approx_eq(transform.translation.z, -1.0F),
    content="true",
  )
  debug_inspect(
    behavior_approx_vec3(
      transform.forward(),
      @math.Vec3::new(-1.0F, 0.0F, 0.0F),
    ),
    content="true",
  )
}

///|
test "transform behavior: align matches documented example" {
  let transform = Transform::identity()
  transform.align(
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec3::new(1.0F, 1.0F, 0.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
  )
  let main_axis_image = behavior_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  )
  let secondary_axis_image = behavior_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(1.0F, 1.0F, 0.0F),
  )
  debug_inspect(
    behavior_approx_vec3(main_axis_image, @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    content="true",
  )
  debug_inspect(
    behavior_approx_vec3(
      secondary_axis_image,
      @math.Vec3::new(0.0F, 1.0F, 1.0F),
    ),
    content="true",
  )
}

///|
test "transform behavior: align falls back to default axes" {
  let lhs = Transform::identity()
  lhs.align(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::zero(),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  )
  let rhs = Transform::identity()
  rhs.align(
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  )
  debug_inspect(
    behavior_quat_same_rotation(lhs.rotation, rhs.rotation),
    content="true",
  )
}

///|
test "transform behavior: align ignores degenerate secondary pair" {
  let transform = Transform::identity()
  transform.align(
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  debug_inspect(
    behavior_approx_vec3(transform.right(), @math.Vec3::new(0.0F, 0.0F, 1.0F)),
    content="true",
  )
  debug_inspect(
    behavior_approx_vec3(transform.up(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    content="true",
  )
}

///|
test "transform behavior: aligned_by preserves translation and returns aligned copy" {
  let base = Transform::from_xyz(2.0F, 3.0F, 4.0F)
  let aligned = base.aligned_by(
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  debug_inspect(
    behavior_quat_same_rotation(base.rotation, @math.Quat::identity()),
    content="true",
  )
  debug_inspect(
    behavior_approx_vec3(aligned.translation, base.translation),
    content="true",
  )
  debug_inspect(behavior_approx_vec3(aligned.scale, base.scale), content="true")
  debug_inspect(
    behavior_approx_vec3(aligned.forward(), @math.Vec3::new(1.0F, 0.0F, 0.0F)),
    content="true",
  )
}
