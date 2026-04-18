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
pub fn touches_any_just_released(touches : Touches) -> Bool {
  touches.any_just_released()
}

///|
pub fn touches_any_just_canceled(touches : Touches) -> Bool {
  touches.any_just_canceled()
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

///|
pub fn touches_iter_just_canceled(touches : Touches) -> Array[Touch] {
  touches.iter_just_canceled()
}

///|
pub fn touches_get_pressed(touches : Touches, id : Int) -> Touch? {
  touches.get_pressed(id)
}

///|
pub fn touches_get_released(touches : Touches, id : Int) -> Touch? {
  touches.get_released(id)
}

///|
pub fn touches_just_pressed(touches : Touches, id : Int) -> Bool {
  touches.just_pressed(id)
}

///|
pub fn touches_just_released(touches : Touches, id : Int) -> Bool {
  touches.just_released(id)
}

///|
pub fn touches_just_canceled(touches : Touches, id : Int) -> Bool {
  touches.just_canceled(id)
}

///|
pub fn touches_clear_just_pressed(touches : Touches, id : Int) -> Bool {
  touches.clear_just_pressed(id)
}

///|
pub fn touches_clear_just_released(touches : Touches, id : Int) -> Bool {
  touches.clear_just_released(id)
}

///|
pub fn touches_clear_just_canceled(touches : Touches, id : Int) -> Bool {
  touches.clear_just_canceled(id)
}

///|
pub fn touches_release(touches : Touches, id : Int) -> Unit {
  touches.release(id)
}

///|
pub fn touches_release_all(touches : Touches) -> Unit {
  touches.release_all()
}

///|
pub fn touches_clear(touches : Touches) -> Unit {
  touches.clear()
}

///|
pub fn touches_reset_all(touches : Touches) -> Unit {
  touches.reset_all()
}

///|
pub fn touches_first_pressed_position(touches : Touches) -> @math.Vec2? {
  touches.first_pressed_position()
}
