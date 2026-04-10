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
// Bevy source: `bevy/crates/bevy_gilrs/src/rumble.rs`.

///|
pub fn to_gilrs_magnitude(ratio : Float) -> Int {
  let clamped = if ratio <= 0.0F {
    0.0F
  } else if ratio >= 1.0F {
    1.0F
  } else {
    ratio
  }
  (clamped * 65535.0F).to_int()
}

///|
pub fn play_gilrs_rumble(
  gamepad_id : Int,
  strong_motor : Float,
  weak_motor : Float,
  duration_ms : Int64,
) -> GamepadRumbleResult {
  gamepad_set_rumble(gamepad_id, strong_motor, weak_motor, duration_ms)
}
