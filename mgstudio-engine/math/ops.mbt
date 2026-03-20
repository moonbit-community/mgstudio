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
pub fn abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
pub fn atan2(y : Float, x : Float) -> Float {
  Float::from_double(@coremath.atan2(y.to_double(), x.to_double()))
}

///|
pub fn cos(value : Float) -> Float {
  Float::from_double(@coremath.cos(value.to_double()))
}

///|
pub fn sin(value : Float) -> Float {
  Float::from_double(@coremath.sin(value.to_double()))
}

///|
pub fn sqrt(value : Float) -> Float {
  @coremath.powf(value, 0.5F)
}

///|
pub fn pow(base : Float, exponent : Float) -> Float {
  Float::from_double(@coremath.pow(base.to_double(), exponent.to_double()))
}

///|
pub fn pi() -> Float {
  Float::from_double(@coremath.PI)
}

///|
pub fn pi_half() -> Float {
  Float::from_double(@coremath.PI / 2.0)
}
