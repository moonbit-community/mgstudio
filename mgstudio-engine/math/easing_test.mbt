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
fn easing_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn easing_approx_eq(a : Float, b : Float) -> Bool {
  easing_abs(a - b) < 0.0001F
}

///|
fn easing_quat_same_rotation(a : Quat, b : Quat) -> Bool {
  let direct = easing_approx_eq(a.x, b.x) &&
    easing_approx_eq(a.y, b.y) &&
    easing_approx_eq(a.z, b.z) &&
    easing_approx_eq(a.w, b.w)
  if direct {
    true
  } else {
    easing_approx_eq(a.x, -b.x) &&
    easing_approx_eq(a.y, -b.y) &&
    easing_approx_eq(a.z, -b.z) &&
    easing_approx_eq(a.w, -b.w)
  }
}

///|
test "math: ease function sample matches unit interval semantics" {
  inspect(EaseFunction::SmoothStep.sample(-0.1F) is None, content="true")
  inspect(EaseFunction::SmoothStep.sample(1.1F) is None, content="true")
  inspect(EaseFunction::SmoothStep.sample(0.0F) == Some(0.0F), content="true")
  inspect(EaseFunction::SmoothStep.sample(0.5F) == Some(0.5F), content="true")
  inspect(EaseFunction::SmoothStep.sample(1.0F) == Some(1.0F), content="true")
}

///|
test "math: steps easing follows Bevy jump semantics" {
  inspect(
    EaseFunction::Steps(4, JumpAt::Start).sample_clamped(0.1F) == 0.25F,
    content="true",
  )
  inspect(
    EaseFunction::Steps(4, JumpAt::End).sample_clamped(0.1F) == 0.0F,
    content="true",
  )
  inspect(
    EaseFunction::Steps(4, JumpAt::Both).sample_clamped(0.1F) == 0.2F,
    content="true",
  )
  inspect(
    EaseFunction::Steps(4, JumpAt::None).sample_clamped(0.6F) == 2.0F / 3.0F,
    content="true",
  )
}

///|
test "math: easing curve interpolates floats and vec2 values" {
  let scalar = EasingCurve::new(2.0F, 4.0F, EaseFunction::Linear)
  inspect(scalar.sample_clamped(0.5F) == 3.0F, content="true")
  inspect(scalar.sample(-1.0F) is None, content="true")

  let vector = EasingCurve::new(
    Vec2::new(0.0F, 4.0F),
    Vec2::new(2.0F, 8.0F),
    EaseFunction::Linear,
  )
  let vector_sample = vector.sample_clamped(0.5F)
  inspect(
    easing_approx_eq(vector_sample.x, 1.0F) &&
    easing_approx_eq(vector_sample.y, 6.0F),
    content="true",
  )
}

///|
test "math: easing curve interpolates quaternions on the shortest path" {
  let curve = EasingCurve::new(
    Quat::identity(),
    Quat::from_rotation_y(pi_half()),
    EaseFunction::Linear,
  )
  let halfway = curve.sample_clamped(0.5F)
  inspect(
    easing_quat_same_rotation(halfway, Quat::from_rotation_y(pi_half() / 2.0F)),
    content="true",
  )
}
