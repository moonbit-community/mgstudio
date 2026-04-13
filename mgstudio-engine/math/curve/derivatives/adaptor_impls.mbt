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
// Bevy source: `bevy/crates/bevy_math/src/curve/derivatives/adaptor_impls.rs`.

///|
pub struct WithDerivative[T] {
  value : T
  derivative : T
}

///|
pub fn[T] with_derivative(value : T, derivative : T) -> WithDerivative[T] {
  WithDerivative::{ value, derivative }
}

///|
pub struct WithTwoDerivatives[T] {
  value : T
  derivative : T
  second_derivative : T
}

///|
pub fn[T] with_two_derivatives(
  value : T,
  derivative : T,
  second_derivative : T,
) -> WithTwoDerivatives[T] {
  WithTwoDerivatives::{ value, derivative, second_derivative }
}
