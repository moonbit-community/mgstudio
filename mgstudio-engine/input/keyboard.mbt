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
// Bevy source-shape anchor (`bevy_input/src/keyboard.rs`).

///|
pub fn keyboard_input_message_key() -> @ecs.MessageKey[KeyboardInput] {
  @input_events.ecs_key_keyboard_input
}

///|
pub fn keyboard_character_message_key() -> @ecs.MessageKey[KeyboardCharacter] {
  @input_events.ecs_key_keyboard_character
}

///|
pub fn keyboard_focus_lost_message_key() -> @ecs.MessageKey[KeyboardFocusLost] {
  @input_events.ecs_key_keyboard_focus_lost
}

///|
pub fn keyboard_input_snapshot() -> ButtonInput[@window.KeyCode] {
  read_keycode_button_input()
}

///|
pub fn logical_key_snapshot() -> ButtonInput[Key] {
  read_logical_key_button_input()
}
