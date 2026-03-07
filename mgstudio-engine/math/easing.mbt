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
/// Bevy-aligned easing functions over the unit interval.

///|
const EASING_LOG2_1023 : Float = 9.998590429745329F

///|
const EASING_FRAC_1_1023 : Float = 0.0009775171065493646F

///|
const EASING_BACK_CONSTANT : Float = 1.70158F

///|
pub(all) enum JumpAt {
  Start
  End
  None
  Both
} derive(Eq, Show, ToJson, FromJson)

///|
pub impl Default for JumpAt with default() {
  JumpAt::End
}

///|
pub(all) enum EaseFunction {
  Linear
  QuadraticIn
  QuadraticOut
  QuadraticInOut
  CubicIn
  CubicOut
  CubicInOut
  QuarticIn
  QuarticOut
  QuarticInOut
  QuinticIn
  QuinticOut
  QuinticInOut
  SmoothStepIn
  SmoothStepOut
  SmoothStep
  SmootherStepIn
  SmootherStepOut
  SmootherStep
  SineIn
  SineOut
  SineInOut
  CircularIn
  CircularOut
  CircularInOut
  ExponentialIn
  ExponentialOut
  ExponentialInOut
  ElasticIn
  ElasticOut
  ElasticInOut
  BackIn
  BackOut
  BackInOut
  BounceIn
  BounceOut
  BounceInOut
  Steps(Int, JumpAt)
  Elastic(Float)
} derive(Show, ToJson, FromJson)

///|
pub impl Default for EaseFunction with default() {
  EaseFunction::Linear
}

///|
pub(open) trait Ease {
  interpolate(self : Self, end : Self, t : Float) -> Self
}

///|
pub impl Ease for Float with interpolate(self, end, t) {
  self + (end - self) * t
}

///|
pub impl Ease for Vec2 with interpolate(self, end, t) {
  Vec2::new(self.x + (end.x - self.x) * t, self.y + (end.y - self.y) * t)
}

///|
pub impl Ease for Vec3 with interpolate(self, end, t) {
  Vec3::new(
    self.x + (end.x - self.x) * t,
    self.y + (end.y - self.y) * t,
    self.z + (end.z - self.z) * t,
  )
}

///|
pub impl Ease for Vec4 with interpolate(self, end, t) {
  Vec4::new(
    self.x + (end.x - self.x) * t,
    self.y + (end.y - self.y) * t,
    self.z + (end.z - self.z) * t,
    self.w + (end.w - self.w) * t,
  )
}

///|
pub impl Ease for Quat with interpolate(self, end, t) {
  self.lerp(end, t)
}

///|
pub impl Ease for Transform with interpolate(self, end, t) {
  Transform::{
    translation: self.translation.interpolate(end.translation, t),
    rotation: self.rotation.interpolate(end.rotation, t),
    scale: self.scale.interpolate(end.scale, t),
  }
}

///|
pub struct EasingCurve[T] {
  start : T
  end : T
  ease_fn : EaseFunction
}

///|
pub fn[T] EasingCurve::new(
  start : T,
  end : T,
  ease_fn : EaseFunction,
) -> EasingCurve[T] {
  EasingCurve::{ start, end, ease_fn }
}

///|
pub fn EaseFunction::sample(self : EaseFunction, t : Float) -> Float? {
  if t < 0.0F || t > 1.0F {
    None
  } else {
    Some(self.sample_clamped(t))
  }
}

///|
pub fn EaseFunction::sample_clamped(self : EaseFunction, t : Float) -> Float {
  easing_eval(self, easing_clamp01(t))
}

///|
pub fn[T : Ease] EasingCurve::sample(self : EasingCurve[T], t : Float) -> T? {
  match self.ease_fn.sample(t) {
    Some(value) => Some(self.start.interpolate(self.end, value))
    None => None
  }
}

///|
pub fn[T : Ease] EasingCurve::sample_clamped(
  self : EasingCurve[T],
  t : Float,
) -> T {
  self.start.interpolate(self.end, self.ease_fn.sample_clamped(t))
}

///|
fn easing_eval(function : EaseFunction, t : Float) -> Float {
  match function {
    Linear => t
    QuadraticIn => t * t
    QuadraticOut => 1.0F - (1.0F - t) * (1.0F - t)
    QuadraticInOut =>
      if t < 0.5F {
        2.0F * t * t
      } else {
        1.0F - (-2.0F * t + 2.0F) * (-2.0F * t + 2.0F) / 2.0F
      }
    CubicIn => t * t * t
    CubicOut => 1.0F - (1.0F - t) * (1.0F - t) * (1.0F - t)
    CubicInOut =>
      if t < 0.5F {
        4.0F * t * t * t
      } else {
        1.0F -
        (-2.0F * t + 2.0F) * (-2.0F * t + 2.0F) * (-2.0F * t + 2.0F) / 2.0F
      }
    QuarticIn => t * t * t * t
    QuarticOut => {
      let one_minus = 1.0F - t
      1.0F - one_minus * one_minus * one_minus * one_minus
    }
    QuarticInOut =>
      if t < 0.5F {
        8.0F * t * t * t * t
      } else {
        let value = -2.0F * t + 2.0F
        1.0F - value * value * value * value / 2.0F
      }
    QuinticIn => t * t * t * t * t
    QuinticOut => {
      let one_minus = 1.0F - t
      1.0F - one_minus * one_minus * one_minus * one_minus * one_minus
    }
    QuinticInOut =>
      if t < 0.5F {
        16.0F * t * t * t * t * t
      } else {
        let value = -2.0F * t + 2.0F
        1.0F - value * value * value * value * value / 2.0F
      }
    SmoothStepIn => (1.5F - 0.5F * t) * t * t
    SmoothStepOut => (1.5F + -0.5F * t * t) * t
    SmoothStep => (3.0F - 2.0F * t) * t * t
    SmootherStepIn => (2.5F + (-1.875F + 0.375F * t) * t) * t * t * t
    SmootherStepOut => (1.875F + (-1.25F + 0.375F * t * t) * t * t) * t
    SmootherStep => (10.0F + (-15.0F + 6.0F * t) * t) * t * t * t
    SineIn => 1.0F - cos(t * pi() / 2.0F)
    SineOut => sin(t * pi() / 2.0F)
    SineInOut => -(cos(pi() * t) - 1.0F) / 2.0F
    CircularIn => 1.0F - sqrt(1.0F - t * t)
    CircularOut => sqrt(1.0F - (t - 1.0F) * (t - 1.0F))
    CircularInOut =>
      if t < 0.5F {
        (1.0F - sqrt(1.0F - 2.0F * t * (2.0F * t))) / 2.0F
      } else {
        (sqrt(1.0F - (-2.0F * t + 2.0F) * (-2.0F * t + 2.0F)) + 1.0F) / 2.0F
      }
    ExponentialIn =>
      pow(2.0F, 10.0F * t - EASING_LOG2_1023) - EASING_FRAC_1_1023
    ExponentialOut =>
      EASING_FRAC_1_1023 +
      1.0F -
      pow(2.0F, -10.0F * t - (EASING_LOG2_1023 - 10.0F))
    ExponentialInOut =>
      if t < 0.5F {
        pow(2.0F, 20.0F * t - (EASING_LOG2_1023 + 1.0F)) -
        EASING_FRAC_1_1023 / 2.0F
      } else {
        EASING_FRAC_1_1023 / 2.0F +
        1.0F -
        pow(2.0F, -20.0F * t - (EASING_LOG2_1023 - 19.0F))
      }
    ElasticIn =>
      -pow(2.0F, 10.0F * t - 10.0F) *
      sin((t * 10.0F - 10.75F) * 2.0F * pi() / 3.0F)
    ElasticOut =>
      pow(2.0F, -10.0F * t) * sin((t * 10.0F - 0.75F) * 2.0F * pi() / 3.0F) +
      1.0F
    ElasticInOut => {
      let c = 2.0F * pi() / 4.5F
      if t < 0.5F {
        -pow(2.0F, 20.0F * t - 10.0F) * sin((t * 20.0F - 11.125F) * c) / 2.0F
      } else {
        pow(2.0F, -20.0F * t + 10.0F) * sin((t * 20.0F - 11.125F) * c) / 2.0F +
        1.0F
      }
    }
    BackIn =>
      (EASING_BACK_CONSTANT + 1.0F) * t * t * t - EASING_BACK_CONSTANT * t * t
    BackOut => {
      let delta = t - 1.0F
      1.0F +
      (EASING_BACK_CONSTANT + 1.0F) * delta * delta * delta +
      EASING_BACK_CONSTANT * delta * delta
    }
    BackInOut => {
      let c2 = EASING_BACK_CONSTANT + 1.525F
      if t < 0.5F {
        2.0F * t * (2.0F * t) * ((c2 + 1.0F) * 2.0F * t - c2) / 2.0F
      } else {
        (
          (2.0F * t - 2.0F) *
          (2.0F * t - 2.0F) *
          ((c2 + 1.0F) * (2.0F * t - 2.0F) + c2) +
          2.0F
        ) /
        2.0F
      }
    }
    BounceIn => 1.0F - easing_bounce_out(1.0F - t)
    BounceOut => easing_bounce_out(t)
    BounceInOut =>
      if t < 0.5F {
        (1.0F - easing_bounce_out(1.0F - 2.0F * t)) / 2.0F
      } else {
        (1.0F + easing_bounce_out(2.0F * t - 1.0F)) / 2.0F
      }
    Steps(num_steps, jump_at) => easing_steps(num_steps, jump_at, t)
    Elastic(omega) =>
      1.0F -
      (1.0F - t) * (1.0F - t) * (2.0F * sin(omega * t) / omega + cos(omega * t))
  }
}

///|
fn easing_steps(num_steps : Int, jump_at : JumpAt, t : Float) -> Float {
  let (a, b) = match jump_at {
    Start => (1.0F, 0)
    End => (0.0F, 0)
    None => (0.0F, -1)
    Both => (1.0F, 1)
  }
  let current_step = (t * easing_int_to_float(num_steps)).floor().to_int()
  let step_size = easing_max_int(num_steps + b, 1)
  easing_clamp01(
    (easing_int_to_float(current_step) + a) / easing_int_to_float(step_size),
  )
}

///|
fn easing_bounce_out(t : Float) -> Float {
  if t < 4.0F / 11.0F {
    121.0F * t * t / 16.0F
  } else if t < 8.0F / 11.0F {
    363.0F / 40.0F * t * t - 99.0F / 10.0F * t + 17.0F / 5.0F
  } else if t < 9.0F / 10.0F {
    4356.0F / 361.0F * t * t - 35442.0F / 1805.0F * t + 16061.0F / 1805.0F
  } else {
    54.0F / 5.0F * t * t - 513.0F / 25.0F * t + 268.0F / 25.0F
  }
}

///|
fn easing_clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn easing_max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn easing_int_to_float(value : Int) -> Float {
  Float::from_double(value.to_double())
}
