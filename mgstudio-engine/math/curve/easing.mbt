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
// Bevy source: `bevy/crates/bevy_math/src/curve/easing.rs`.

///|
pub(all) enum JumpAt {
  Start
  End
  None
  Both
} derive(Eq, Debug, ToJson, FromJson)

///|
pub impl Default for JumpAt with fn default() {
  End
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
} derive(Debug, ToJson, FromJson)

///|
pub impl Default for EaseFunction with fn default() {
  Linear
}

///|
pub(open) trait Ease {
  fn interpolate(self : Self, end : Self, t : Float) -> Self
}

///|
pub impl Ease for Float with fn interpolate(self, end, t) {
  self + (end - self) * t
}

///|
pub impl Ease for @math.Vec2 with fn interpolate(self, end, t) {
  @math.Vec2::new(self.x + (end.x - self.x) * t, self.y + (end.y - self.y) * t)
}

///|
pub impl Ease for @math.Vec3 with fn interpolate(self, end, t) {
  @math.Vec3::new(
    self.x + (end.x - self.x) * t,
    self.y + (end.y - self.y) * t,
    self.z + (end.z - self.z) * t,
  )
}

///|
pub impl Ease for @math.Vec4 with fn interpolate(self, end, t) {
  @math.Vec4::new(
    self.x + (end.x - self.x) * t,
    self.y + (end.y - self.y) * t,
    self.z + (end.z - self.z) * t,
    self.w + (end.w - self.w) * t,
  )
}

///|
pub impl Ease for @math.Quat with fn interpolate(self, end, t) {
  self.lerp(end, t)
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
  { start, end, ease_fn }
}

///|
pub fn EaseFunction::sample(self : EaseFunction, t : Float) -> Float? {
  self.to_math().sample(t)
}

///|
pub fn EaseFunction::sample_clamped(self : EaseFunction, t : Float) -> Float {
  self.to_math().sample_clamped(t)
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
fn JumpAt::to_math(self : JumpAt) -> @math.JumpAt {
  match self {
    Start => Start
    End => End
    None => None
    Both => Both
  }
}

///|
fn EaseFunction::to_math(self : EaseFunction) -> @math.EaseFunction {
  match self {
    Linear => Linear
    QuadraticIn => QuadraticIn
    QuadraticOut => QuadraticOut
    QuadraticInOut => QuadraticInOut
    CubicIn => CubicIn
    CubicOut => CubicOut
    CubicInOut => CubicInOut
    QuarticIn => QuarticIn
    QuarticOut => QuarticOut
    QuarticInOut => QuarticInOut
    QuinticIn => QuinticIn
    QuinticOut => QuinticOut
    QuinticInOut => QuinticInOut
    SmoothStepIn => SmoothStepIn
    SmoothStepOut => SmoothStepOut
    SmoothStep => SmoothStep
    SmootherStepIn => SmootherStepIn
    SmootherStepOut => SmootherStepOut
    SmootherStep => SmootherStep
    SineIn => SineIn
    SineOut => SineOut
    SineInOut => SineInOut
    CircularIn => CircularIn
    CircularOut => CircularOut
    CircularInOut => CircularInOut
    ExponentialIn => ExponentialIn
    ExponentialOut => ExponentialOut
    ExponentialInOut => ExponentialInOut
    ElasticIn => ElasticIn
    ElasticOut => ElasticOut
    ElasticInOut => ElasticInOut
    BackIn => BackIn
    BackOut => BackOut
    BackInOut => BackInOut
    BounceIn => BounceIn
    BounceOut => BounceOut
    BounceInOut => BounceInOut
    Steps(count, jump_at) => Steps(count, jump_at.to_math())
    Elastic(period) => Elastic(period)
  }
}
