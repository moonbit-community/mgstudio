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
pub struct Virtual {
  delta_seconds : Float
  elapsed_seconds : Float
  relative_speed : Float
  effective_speed : Float
  max_delta_seconds : Float
  paused : Bool
  was_paused : Bool
}

///|
pub fn Virtual::delta_seconds(self : Virtual) -> Float {
  self.delta_seconds
}

///|
pub fn Virtual::elapsed_seconds(self : Virtual) -> Float {
  self.elapsed_seconds
}

///|
pub fn Virtual::relative_speed(self : Virtual) -> Float {
  self.relative_speed
}

///|
pub fn Virtual::effective_speed(self : Virtual) -> Float {
  self.effective_speed
}

///|
pub fn Virtual::max_delta_seconds(self : Virtual) -> Float {
  self.max_delta_seconds
}

///|
pub fn Virtual::is_paused(self : Virtual) -> Bool {
  self.paused
}

///|
pub fn Virtual::was_paused(self : Virtual) -> Bool {
  self.was_paused
}

///|
pub fn time_virtual_delta_seconds() -> Float {
  time_state_ref.val.virtual_delta_seconds
}

///|
pub fn time_virtual_elapsed_seconds() -> Float {
  time_state_ref.val.virtual_elapsed_seconds
}

///|
pub fn time_virtual_relative_speed() -> Float {
  time_state_ref.val.virtual_relative_speed
}

///|
pub fn time_virtual_effective_speed() -> Float {
  time_state_ref.val.virtual_effective_speed
}

///|
pub fn time_virtual_max_delta_seconds() -> Float {
  time_state_ref.val.virtual_max_delta_seconds
}

///|
pub fn time_virtual_set_relative_speed(speed : Float) -> Unit {
  time_state_ref.val.virtual_relative_speed = if speed < 0.0F {
    0.0F
  } else {
    speed
  }
}

///|
pub fn time_virtual_set_max_delta_seconds(max_delta_seconds : Float) -> Unit {
  if max_delta_seconds > 0.0F {
    time_state_ref.val.virtual_max_delta_seconds = max_delta_seconds
  }
}

///|
pub fn time_virtual_pause() -> Unit {
  time_state_ref.val.virtual_paused = true
}

///|
pub fn time_virtual_unpause() -> Unit {
  time_state_ref.val.virtual_paused = false
}

///|
pub fn time_virtual_toggle() -> Unit {
  time_state_ref.val.virtual_paused = !time_state_ref.val.virtual_paused
}

///|
pub fn time_virtual_is_paused() -> Bool {
  time_state_ref.val.virtual_paused
}
