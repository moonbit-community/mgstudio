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
pub(all) struct Transform {
  mut translation : @math.Vec3
  mut rotation : @math.Quat
  mut scale : @math.Vec3
}

///|
pub fn Transform::new(
  translation : @math.Vec3,
  rotation : @math.Quat,
  scale : @math.Vec3,
) -> Transform {
  Transform::{ translation, rotation, scale }
}

///|
pub impl ToJson for Transform with to_json(self) {
  (
    self.translation.x,
    self.translation.y,
    self.translation.z,
    self.rotation.x,
    self.rotation.y,
    self.rotation.z,
    self.rotation.w,
    self.scale.x,
    self.scale.y,
    self.scale.z,
  ).to_json()
}

///|
pub impl @json.FromJson for Transform with from_json(json, path) {
  let (tx, ty, tz, rx, ry, rz, rw, sx, sy, sz) : (
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
  ) = @json.from_json(json, path~)
  Transform::new(
    @math.Vec3::new(tx, ty, tz),
    @math.Quat::new(rx, ry, rz, rw),
    @math.Vec3::new(sx, sy, sz),
  )
}

///|
pub fn Transform::identity() -> Transform {
  Transform::{
    translation: @math.Vec3::zero(),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::splat(1.0F),
  }
}

///|
pub impl Default for Transform with default() {
  Transform::identity()
}

///|
pub fn Transform::from_xyz(x : Float, y : Float, z : Float) -> Transform {
  Transform::new(
    @math.Vec3::new(x, y, z),
    @math.Quat::identity(),
    @math.Vec3::splat(1.0F),
  )
}

///|
pub fn Transform::from_translation(translation : @math.Vec3) -> Transform {
  Transform::new(translation, @math.Quat::identity(), @math.Vec3::splat(1.0F))
}

///|
pub fn Transform::from_rotation(rotation : @math.Quat) -> Transform {
  Transform::new(@math.Vec3::zero(), rotation, @math.Vec3::splat(1.0F))
}

///|
pub fn Transform::from_xy(x : Float, y : Float) -> Transform {
  Transform::from_xyz(x, y, 0.0F)
}

///|
pub fn Transform::from_xy_rotation_scale(
  translation : @math.Vec2,
  rotation_z : Float,
  scale : @math.Vec2,
  z? : Float = 0.0F,
) -> Transform {
  Transform::new(
    @math.Vec3::new(translation.x, translation.y, z),
    @math.Quat::from_rotation_z(rotation_z),
    @math.Vec3::new(scale.x, scale.y, 1.0F),
  )
}

///|
pub fn Transform::rotation_z(self : Transform) -> Float {
  self.rotation.to_rotation_z_angle()
}

///|
pub fn Transform::with_translation(
  self : Transform,
  translation : @math.Vec3,
) -> Transform {
  Transform::{ translation, rotation: self.rotation, scale: self.scale }
}

///|
pub fn Transform::with_rotation(
  self : Transform,
  rotation : @math.Quat,
) -> Transform {
  Transform::{ translation: self.translation, rotation, scale: self.scale }
}

///|
pub fn Transform::with_scale(self : Transform, scale : @math.Vec3) -> Transform {
  Transform::{ translation: self.translation, rotation: self.rotation, scale }
}

///|
pub fn Transform::local_x(self : Transform) -> @math.Vec3 {
  transform_rotate_vec3(self.rotation, @math.Vec3::new(1.0F, 0.0F, 0.0F)).normalize_or_zero()
}

///|
pub fn Transform::left(self : Transform) -> @math.Vec3 {
  self.local_x().neg()
}

///|
pub fn Transform::right(self : Transform) -> @math.Vec3 {
  self.local_x()
}

///|
pub fn Transform::local_y(self : Transform) -> @math.Vec3 {
  transform_rotate_vec3(self.rotation, @math.Vec3::new(0.0F, 1.0F, 0.0F)).normalize_or_zero()
}

///|
pub fn Transform::up(self : Transform) -> @math.Vec3 {
  self.local_y()
}

///|
pub fn Transform::down(self : Transform) -> @math.Vec3 {
  self.local_y().neg()
}

///|
pub fn Transform::local_z(self : Transform) -> @math.Vec3 {
  transform_rotate_vec3(self.rotation, @math.Vec3::new(0.0F, 0.0F, 1.0F)).normalize_or_zero()
}

///|
pub fn Transform::forward(self : Transform) -> @math.Vec3 {
  self.local_z().neg()
}

///|
pub fn Transform::back(self : Transform) -> @math.Vec3 {
  self.local_z()
}

///|
pub fn Transform::looking_at(
  self : Transform,
  target : @math.Vec3,
  up : @math.Vec3,
) -> Transform {
  let forward = target.sub(self.translation).normalize_or_zero()
  if forward.length_squared() <= 1.0e-12F {
    return self
  }
  let up_hint = if up.length_squared() <= 1.0e-12F {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    up.normalize_or_zero()
  }
  let z_axis = forward.neg()
  let mut x_axis = up_hint.cross(z_axis).normalize_or_zero()
  if x_axis.length_squared() <= 1.0e-12F {
    x_axis = @math.Vec3::new(1.0F, 0.0F, 0.0F).cross(z_axis).normalize_or_zero()
    if x_axis.length_squared() <= 1.0e-12F {
      x_axis = @math.Vec3::new(0.0F, 0.0F, 1.0F)
        .cross(z_axis)
        .normalize_or_zero()
    }
  }
  let y_axis = z_axis.cross(x_axis).normalize_or_zero()
  let rotation = transform_quat_from_basis(x_axis, y_axis, z_axis)
  Transform::{ translation: self.translation, rotation, scale: self.scale }
}

///|
pub fn Transform::looking_to(
  self : Transform,
  direction : @math.Vec3,
  up : @math.Vec3,
) -> Transform {
  let forward = direction.normalize_or_zero()
  if forward.length_squared() <= 1.0e-12F {
    return self.looking_at(
      self.translation.add(@math.Vec3::new(0.0F, 0.0F, -1.0F)),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    )
  }
  let up_hint = if up.length_squared() <= 1.0e-12F {
    @math.Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    up
  }
  self.looking_at(self.translation.add(forward), up_hint)
}

///|
pub fn Transform::rotate(self : Transform, rotation : @math.Quat) -> Unit {
  self.rotation = rotation.mul(self.rotation).normalize()
}

///|
pub fn Transform::translate_around(
  self : Transform,
  point : @math.Vec3,
  rotation : @math.Quat,
) -> Unit {
  self.translation = point.add(
    transform_rotate_vec3(rotation.normalize(), self.translation.sub(point)),
  )
}

///|
pub fn Transform::rotate_around(
  self : Transform,
  point : @math.Vec3,
  rotation : @math.Quat,
) -> Unit {
  self.translate_around(point, rotation)
  self.rotate(rotation)
}

///|
pub fn Transform::aligned_by(
  self : Transform,
  main_axis : @math.Vec3,
  main_direction : @math.Vec3,
  secondary_axis : @math.Vec3,
  secondary_direction : @math.Vec3,
) -> Transform {
  let aligned = Transform::{
    translation: self.translation,
    rotation: self.rotation,
    scale: self.scale,
  }
  aligned.align(main_axis, main_direction, secondary_axis, secondary_direction)
  aligned
}

///|
pub fn Transform::align(
  self : Transform,
  main_axis : @math.Vec3,
  main_direction : @math.Vec3,
  secondary_axis : @math.Vec3,
  secondary_direction : @math.Vec3,
) -> Unit {
  let main_axis = match transform_vec3_try_normalize(main_axis) {
    Some(value) => value
    None => @math.Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let main_direction = match transform_vec3_try_normalize(main_direction) {
    Some(value) => value
    None => @math.Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let secondary_axis = match transform_vec3_try_normalize(secondary_axis) {
    Some(value) => value
    None => @math.Vec3::new(0.0F, 1.0F, 0.0F)
  }
  let secondary_direction = match
    transform_vec3_try_normalize(secondary_direction) {
    Some(value) => value
    None => @math.Vec3::new(0.0F, 1.0F, 0.0F)
  }

  let first_rotation = transform_quat_from_rotation_arc(
    main_axis, main_direction,
  )
  let secondary_image = transform_rotate_vec3(first_rotation, secondary_axis)
  let secondary_image_ortho = transform_vec3_try_normalize(
    transform_vec3_reject_from_normalized(secondary_image, main_direction),
  )
  let secondary_direction_ortho = transform_vec3_try_normalize(
    transform_vec3_reject_from_normalized(secondary_direction, main_direction),
  )

  self.rotation = match (secondary_image_ortho, secondary_direction_ortho) {
    (Some(image), Some(direction)) =>
      transform_quat_from_rotation_arc(image, direction)
      .mul(first_rotation)
      .normalize()
    _ => first_rotation
  }
}

///|
pub fn Transform::rotate_y(self : Transform, angle : Float) -> Unit {
  self.rotate(@math.Quat::from_rotation_y(angle))
}

///|
pub fn Transform::rotate_z(self : Transform, angle : Float) -> Unit {
  self.rotate(@math.Quat::from_rotation_z(angle))
}

///|
fn transform_rotate_vec3(
  rotation : @math.Quat,
  value : @math.Vec3,
) -> @math.Vec3 {
  let qv = @math.Vec3::new(rotation.x, rotation.y, rotation.z)
  let t = qv.cross(value).mul_scalar(2.0F)
  value.add(t.mul_scalar(rotation.w)).add(qv.cross(t))
}

///|
fn transform_vec3_try_normalize(value : @math.Vec3) -> @math.Vec3? {
  let len_sq = value.length_squared()
  if len_sq <= 1.0e-12F {
    None
  } else {
    Some(value.mul_scalar(1.0F / @math.sqrt(len_sq)))
  }
}

///|
fn transform_vec3_reject_from_normalized(
  value : @math.Vec3,
  normal : @math.Vec3,
) -> @math.Vec3 {
  value.sub(normal.mul_scalar(value.dot(normal)))
}

///|
fn transform_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn transform_vec3_any_orthonormal_vector(normal : @math.Vec3) -> @math.Vec3 {
  let axis = if transform_abs(normal.x) > transform_abs(normal.z) {
    @math.Vec3::new(-normal.y, normal.x, 0.0F)
  } else {
    @math.Vec3::new(0.0F, -normal.z, normal.y)
  }
  match transform_vec3_try_normalize(axis) {
    Some(value) => value
    None => @math.Vec3::new(1.0F, 0.0F, 0.0F)
  }
}

///|
fn transform_quat_from_rotation_arc(
  from : @math.Vec3,
  to : @math.Vec3,
) -> @math.Quat {
  let from = match transform_vec3_try_normalize(from) {
    Some(value) => value
    None => @math.Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let to = match transform_vec3_try_normalize(to) {
    Some(value) => value
    None => @math.Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let dot = from.dot(to)
  if dot >= 1.0F - 1.0e-6F {
    return @math.Quat::identity()
  }
  if dot <= -1.0F + 1.0e-6F {
    return @math.Quat::from_axis_angle(
      transform_vec3_any_orthonormal_vector(from),
      @math.pi(),
    )
  }
  @math.Quat::{
    x: from.y * to.z - from.z * to.y,
    y: from.z * to.x - from.x * to.z,
    z: from.x * to.y - from.y * to.x,
    w: 1.0F + dot,
  }.normalize()
}

///|
fn transform_quat_from_basis(
  x_axis : @math.Vec3,
  y_axis : @math.Vec3,
  z_axis : @math.Vec3,
) -> @math.Quat {
  let m00 = x_axis.x
  let m01 = y_axis.x
  let m02 = z_axis.x
  let m10 = x_axis.y
  let m11 = y_axis.y
  let m12 = z_axis.y
  let m20 = x_axis.z
  let m21 = y_axis.z
  let m22 = z_axis.z
  let trace = m00 + m11 + m22
  if trace > 0.0F {
    let s = @math.sqrt(trace + 1.0F) * 2.0F
    return @math.Quat::{
      x: (m21 - m12) / s,
      y: (m02 - m20) / s,
      z: (m10 - m01) / s,
      w: 0.25F * s,
    }.normalize()
  }
  if m00 > m11 && m00 > m22 {
    let s = @math.sqrt(1.0F + m00 - m11 - m22) * 2.0F
    return @math.Quat::{
      x: 0.25F * s,
      y: (m01 + m10) / s,
      z: (m02 + m20) / s,
      w: (m21 - m12) / s,
    }.normalize()
  }
  if m11 > m22 {
    let s = @math.sqrt(1.0F + m11 - m00 - m22) * 2.0F
    return @math.Quat::{
      x: (m01 + m10) / s,
      y: 0.25F * s,
      z: (m12 + m21) / s,
      w: (m02 - m20) / s,
    }.normalize()
  }
  let s = @math.sqrt(1.0F + m22 - m00 - m11) * 2.0F
  @math.Quat::{
    x: (m02 + m20) / s,
    y: (m12 + m21) / s,
    z: 0.25F * s,
    w: (m10 - m01) / s,
  }.normalize()
}
