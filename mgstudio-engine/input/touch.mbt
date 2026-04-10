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
// Bevy source: `bevy/crates/bevy_input/src/touch.rs`.

///|
pub fn touch_input_message_key() -> @ecs.MessageKey[TouchInput] {
  @input_events.ecs_key_touch_input
}

///|
pub fn touches_new() -> Touches {
  Touches::new()
}

///|
pub fn touches_any_just_pressed(touches : Touches) -> Bool {
  touches.any_just_pressed()
}

///|
pub fn touches_iter_active(touches : Touches) -> Array[Touch] {
  touches.iter()
}

///|
pub fn touches_iter_just_pressed(touches : Touches) -> Array[Touch] {
  touches.iter_just_pressed()
}

///|
pub fn touches_iter_just_released(touches : Touches) -> Array[Touch] {
  touches.iter_just_released()
}
