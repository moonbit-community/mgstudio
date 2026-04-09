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
// Bevy source-shape anchor (`bevy_input/src/button_input.rs`).

///|
pub fn[T] ButtonInput::is_empty(self : ButtonInput[T]) -> Bool {
  self.pressed.length() == 0
}

///|
pub fn[T : ButtonInputButton] ButtonInput::contains(
  self : ButtonInput[T],
  button : T,
) -> Bool {
  self.pressed(button) ||
  self.just_pressed(button) ||
  self.just_released(button)
}

///|
pub fn[T] ButtonInput::pressed_count(self : ButtonInput[T]) -> Int {
  self.pressed.length()
}
