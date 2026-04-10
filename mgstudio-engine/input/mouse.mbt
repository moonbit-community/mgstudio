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
// Bevy source: `bevy/crates/bevy_input/src/mouse.rs`.

///|
pub fn mouse_button_message_key() -> @ecs.MessageKey[MouseButtonInput] {
  @input_events.ecs_key_mouse_button_input
}

///|
pub fn mouse_motion_message_key() -> @ecs.MessageKey[MouseMotion] {
  @input_events.ecs_key_mouse_motion
}

///|
pub fn mouse_wheel_message_key() -> @ecs.MessageKey[MouseWheel] {
  @input_events.ecs_key_mouse_wheel
}

///|
pub fn pinch_gesture_message_key() -> @ecs.MessageKey[PinchGesture] {
  @input_events.ecs_key_pinch_gesture
}

///|
pub fn mouse_button_snapshot() -> ButtonInput[@window.MouseButton] {
  read_mouse_button_input()
}

///|
pub fn mouse_position_snapshot() -> @math.Vec2? {
  mouse_position()
}

///|
pub fn mouse_button_pressed_snapshot(button : @window.MouseButton) -> Bool {
  read_mouse_button_input().pressed(button)
}
