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
//
// Adapted from Bevy's `bevy_time` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub struct Fixed {
  delta_seconds : Float
  elapsed_seconds : Float
  timestep_seconds : Float
  overstep_seconds : Float
}

///|
pub fn Fixed::delta_seconds(self : Fixed) -> Float {
  self.delta_seconds
}

///|
pub fn Fixed::elapsed_seconds(self : Fixed) -> Float {
  self.elapsed_seconds
}

///|
pub fn Fixed::timestep_seconds(self : Fixed) -> Float {
  self.timestep_seconds
}

///|
pub fn Fixed::overstep_seconds(self : Fixed) -> Float {
  self.overstep_seconds
}

///|
pub fn Fixed::overstep_fraction(self : Fixed) -> Float {
  if self.timestep_seconds <= 0.0F {
    0.0F
  } else {
    self.overstep_seconds / self.timestep_seconds
  }
}

///|
pub fn time_fixed_delta_seconds() -> Float {
  @app.fixed_time_timestep_seconds()
}

///|
pub fn time_fixed_elapsed_seconds() -> Float {
  @app.fixed_time_elapsed_seconds()
}

///|
pub fn time_fixed_timestep_seconds() -> Float {
  @app.fixed_time_timestep_seconds()
}

///|
pub fn time_fixed_overstep_seconds() -> Float {
  @app.fixed_time_overstep_seconds()
}

///|
pub fn time_fixed_overstep_fraction() -> Float {
  @app.fixed_time_overstep_fraction()
}
