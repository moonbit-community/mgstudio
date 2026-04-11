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
// Bevy source: `bevy/crates/bevy_animation/src/animatable.rs`.
// Animatable interpolation/blend helpers used by clip sampling + glTF keyframe evaluation.

///|
pub struct BlendInput[T] {
  weight : Float
  value : T
  additive : Bool
}

///|
pub fn[T] BlendInput::new(
  weight : Float,
  value : T,
  additive? : Bool = false,
) -> BlendInput[T] {
  BlendInput::{ weight, value, additive }
}

///|
pub fn animation_interpolate_float_unclamped(
  a : Float,
  b : Float,
  t : Float,
) -> Float {
  a + (b - a) * t
}

///|
pub fn animation_step_bool_unclamped(a : Bool, b : Bool, t : Float) -> Bool {
  if t >= 1.0F {
    b
  } else {
    a
  }
}

///|
pub fn animation_interpolate_vec3_unclamped(
  a : @math.Vec3,
  b : @math.Vec3,
  t : Float,
) -> @math.Vec3 {
  @math.Vec3::interpolate(a, b, t)
}

///|
pub fn animation_interpolate_quat_unclamped(
  a : @math.Quat,
  b : @math.Quat,
  t : Float,
) -> @math.Quat {
  @math.Quat::interpolate(a, b, t)
}

///|
pub fn animation_interpolate_weights_unclamped(
  a : Array[Float],
  b : Array[Float],
  t : Float,
) -> Array[Float] {
  let len = if a.length() > b.length() { a.length() } else { b.length() }
  let out : Array[Float] = []
  for i in 0..<len {
    let av = match a.get(i) {
      Some(value) => value
      None => 0.0F
    }
    let bv = match b.get(i) {
      Some(value) => value
      None => 0.0F
    }
    out.push(animation_interpolate_float_unclamped(av, bv, t))
  }
  out
}

///|
pub fn animation_interpolate_color_unclamped(
  a : @sprite.Color,
  b : @sprite.Color,
  t : Float,
) -> @sprite.Color {
  @sprite.Color::new(
    animation_interpolate_float_unclamped(a.r, b.r, t),
    animation_interpolate_float_unclamped(a.g, b.g, t),
    animation_interpolate_float_unclamped(a.b, b.b, t),
    animation_interpolate_float_unclamped(a.a, b.a, t),
  )
}

///|
fn animation_cubic_blend_coefficients(
  t : Float,
) -> (Float, Float, Float, Float) {
  let t2 = t * t
  let t3 = t2 * t
  (
    2.0F * t3 - 3.0F * t2 + 1.0F,
    t3 - 2.0F * t2 + t,
    -2.0F * t3 + 3.0F * t2,
    t3 - t2,
  )
}

///|
pub fn animation_interpolate_with_cubic_bezier_vec3(
  value_start : @math.Vec3,
  tangent_out_start : @math.Vec3,
  tangent_in_end : @math.Vec3,
  value_end : @math.Vec3,
  t : Float,
  step_duration : Float,
) -> @math.Vec3 {
  let (coeff_start, coeff_tangent_out, coeff_end, coeff_tangent_in) = animation_cubic_blend_coefficients(
    t,
  )
  value_start
  .mul_scalar(coeff_start)
  .add(tangent_out_start.mul_scalar(step_duration * coeff_tangent_out))
  .add(value_end.mul_scalar(coeff_end))
  .add(tangent_in_end.mul_scalar(step_duration * coeff_tangent_in))
}

///|
fn animation_quat_normalized(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> @math.Quat {
  let len_sq = x * x + y * y + z * z + w * w
  if len_sq <= 1.0e-12F {
    return @math.Quat::identity()
  }
  @math.Quat::new(x, y, z, w).normalize()
}

///|
pub fn animation_interpolate_with_cubic_bezier_quat(
  value_start : @math.Quat,
  tangent_out_start : @math.Vec4,
  tangent_in_end : @math.Vec4,
  value_end : @math.Quat,
  t : Float,
  step_duration : Float,
) -> @math.Quat {
  let (coeff_start, coeff_tangent_out, coeff_end, coeff_tangent_in) = animation_cubic_blend_coefficients(
    t,
  )
  animation_quat_normalized(
    value_start.x * coeff_start +
    tangent_out_start.x * step_duration * coeff_tangent_out +
    value_end.x * coeff_end +
    tangent_in_end.x * step_duration * coeff_tangent_in,
    value_start.y * coeff_start +
    tangent_out_start.y * step_duration * coeff_tangent_out +
    value_end.y * coeff_end +
    tangent_in_end.y * step_duration * coeff_tangent_in,
    value_start.z * coeff_start +
    tangent_out_start.z * step_duration * coeff_tangent_out +
    value_end.z * coeff_end +
    tangent_in_end.z * step_duration * coeff_tangent_in,
    value_start.w * coeff_start +
    tangent_out_start.w * step_duration * coeff_tangent_out +
    value_end.w * coeff_end +
    tangent_in_end.w * step_duration * coeff_tangent_in,
  )
}

///|
fn animation_array_or_zero(values : Array[Float], index : Int) -> Float {
  match values.get(index) {
    Some(value) => value
    None => 0.0F
  }
}

///|
pub fn animation_interpolate_with_cubic_bezier_weights(
  value_start : Array[Float],
  tangent_out_start : Array[Float],
  tangent_in_end : Array[Float],
  value_end : Array[Float],
  t : Float,
  step_duration : Float,
) -> Array[Float] {
  let (coeff_start, coeff_tangent_out, coeff_end, coeff_tangent_in) = animation_cubic_blend_coefficients(
    t,
  )
  let len = {
    let mut max_len = value_start.length()
    if tangent_out_start.length() > max_len {
      max_len = tangent_out_start.length()
    }
    if tangent_in_end.length() > max_len {
      max_len = tangent_in_end.length()
    }
    if value_end.length() > max_len {
      max_len = value_end.length()
    }
    max_len
  }
  let out : Array[Float] = []
  for i in 0..<len {
    let sample = animation_array_or_zero(value_start, i) * coeff_start +
      animation_array_or_zero(tangent_out_start, i) *
      step_duration *
      coeff_tangent_out +
      animation_array_or_zero(value_end, i) * coeff_end +
      animation_array_or_zero(tangent_in_end, i) *
      step_duration *
      coeff_tangent_in
    out.push(sample)
  }
  out
}

///|
pub fn animation_translation_keyframe(
  time : Float,
  value : @math.Vec3,
) -> KeyframeVec3 {
  KeyframeVec3::new(time, value)
}

///|
pub fn animation_rotation_keyframe(
  time : Float,
  value : @math.Quat,
) -> KeyframeQuat {
  KeyframeQuat::new(time, value)
}

///|
pub fn animation_scale_keyframe(
  time : Float,
  value : @math.Vec3,
) -> KeyframeVec3 {
  KeyframeVec3::new(time, value)
}
