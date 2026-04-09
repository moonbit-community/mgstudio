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
// Bevy source: `bevy/crates/bevy_math/src/curve/mod.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub type Curve[T] = @math.Curve[T]

///|
pub type ConstantCurve[T] = @math.ConstantCurve[T]

///|
pub type FunctionCurve[T] = @math.FunctionCurve[T]

///|
pub type IterableCurve[T] = @math.IterableCurve[T]

///|
pub type SampleCurve[T] = @math.SampleCurve[T]

///|
pub type SampleAutoCurve[T] = @math.SampleAutoCurve[T]

///|
pub type UnevenSampleCurve[T] = @math.UnevenSampleCurve[T]

///|
pub type EasingCurve[T] = @math.EasingCurve[T]

///|
pub type Interval = @math.Interval

///|
pub type CurveChainError = @math.CurveChainError

///|
pub type LinearMapError = @math.LinearMapError

///|
pub type SpacedPointsError = @math.SpacedPointsError

///|
pub type InvalidIntervalError = @math.InvalidIntervalError

///|
pub type EvenCoreError = @math.EvenCoreError

///|
pub type UnevenCoreError = @math.UnevenCoreError

///|
pub type EvenCore[T] = @math.EvenCore[T]

///|
pub type UnevenCore[T] = @math.UnevenCore[T]

///|
pub fn interval(
  start : Float,
  end_ : Float,
) -> Interval raise InvalidIntervalError {
  @math.interval(start, end_)
}
