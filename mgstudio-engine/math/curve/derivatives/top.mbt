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
// Bevy source: `bevy/crates/bevy_math/src/curve/derivatives/mod.rs`.
// Runtime-bearing exports live in `adaptor_impls.mbt`.

///|
pub fn[T] with_derivative_value(entry : WithDerivative[T]) -> T {
  entry.value
}

///|
pub fn[T] with_derivative_derivative(entry : WithDerivative[T]) -> T {
  entry.derivative
}

///|
pub fn[T] with_two_derivatives_value(entry : WithTwoDerivatives[T]) -> T {
  entry.value
}

///|
pub fn[T] with_two_derivatives_first(entry : WithTwoDerivatives[T]) -> T {
  entry.derivative
}

///|
pub fn[T] with_two_derivatives_second(entry : WithTwoDerivatives[T]) -> T {
  entry.second_derivative
}

///|
pub fn[T, S] with_derivative_map(
  entry : WithDerivative[T],
  f : (T) -> S,
) -> WithDerivative[S] {
  with_derivative(f(entry.value), f(entry.derivative))
}

///|
pub fn[T, S] with_two_derivatives_map(
  entry : WithTwoDerivatives[T],
  f : (T) -> S,
) -> WithTwoDerivatives[S] {
  with_two_derivatives(
    f(entry.value),
    f(entry.derivative),
    f(entry.second_derivative),
  )
}
