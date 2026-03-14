// Copyright 2026 International Digital Economy Academy
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
priv struct KeyIdMappingCase {
  name : String
  key_code : @window_core.KeyCode
}

///|
fn key_id_mapping_cases() -> Array[KeyIdMappingCase] {
  [
    KeyIdMappingCase::{ name: "KeyA", key_code: KeyA },
    KeyIdMappingCase::{ name: "KeyB", key_code: KeyB },
    KeyIdMappingCase::{ name: "KeyC", key_code: KeyC },
    KeyIdMappingCase::{ name: "KeyD", key_code: KeyD },
    KeyIdMappingCase::{ name: "KeyE", key_code: KeyE },
    KeyIdMappingCase::{ name: "KeyF", key_code: KeyF },
    KeyIdMappingCase::{ name: "KeyG", key_code: KeyG },
    KeyIdMappingCase::{ name: "KeyH", key_code: KeyH },
    KeyIdMappingCase::{ name: "KeyI", key_code: KeyI },
    KeyIdMappingCase::{ name: "KeyJ", key_code: KeyJ },
    KeyIdMappingCase::{ name: "KeyK", key_code: KeyK },
    KeyIdMappingCase::{ name: "KeyL", key_code: KeyL },
    KeyIdMappingCase::{ name: "KeyM", key_code: KeyM },
    KeyIdMappingCase::{ name: "KeyN", key_code: KeyN },
    KeyIdMappingCase::{ name: "KeyO", key_code: KeyO },
    KeyIdMappingCase::{ name: "KeyP", key_code: KeyP },
    KeyIdMappingCase::{ name: "KeyQ", key_code: KeyQ },
    KeyIdMappingCase::{ name: "KeyR", key_code: KeyR },
    KeyIdMappingCase::{ name: "KeyS", key_code: KeyS },
    KeyIdMappingCase::{ name: "KeyT", key_code: KeyT },
    KeyIdMappingCase::{ name: "KeyU", key_code: KeyU },
    KeyIdMappingCase::{ name: "KeyV", key_code: KeyV },
    KeyIdMappingCase::{ name: "KeyW", key_code: KeyW },
    KeyIdMappingCase::{ name: "KeyX", key_code: KeyX },
    KeyIdMappingCase::{ name: "KeyY", key_code: KeyY },
    KeyIdMappingCase::{ name: "KeyZ", key_code: KeyZ },
    KeyIdMappingCase::{ name: "Digit1", key_code: Digit1 },
    KeyIdMappingCase::{ name: "Digit2", key_code: Digit2 },
    KeyIdMappingCase::{ name: "Digit3", key_code: Digit3 },
    KeyIdMappingCase::{ name: "Digit4", key_code: Digit4 },
    KeyIdMappingCase::{ name: "Digit5", key_code: Digit5 },
    KeyIdMappingCase::{ name: "Digit6", key_code: Digit6 },
    KeyIdMappingCase::{ name: "Digit7", key_code: Digit7 },
    KeyIdMappingCase::{ name: "Digit8", key_code: Digit8 },
    KeyIdMappingCase::{ name: "Tab", key_code: Tab },
    KeyIdMappingCase::{ name: "Enter", key_code: Enter },
    KeyIdMappingCase::{ name: "Backspace", key_code: Backspace },
    KeyIdMappingCase::{ name: "ShiftLeft", key_code: ShiftLeft },
    KeyIdMappingCase::{ name: "ShiftRight", key_code: ShiftRight },
    KeyIdMappingCase::{ name: "ControlLeft", key_code: ControlLeft },
    KeyIdMappingCase::{ name: "ControlRight", key_code: ControlRight },
    KeyIdMappingCase::{ name: "ArrowUp", key_code: ArrowUp },
    KeyIdMappingCase::{ name: "ArrowDown", key_code: ArrowDown },
    KeyIdMappingCase::{ name: "ArrowLeft", key_code: ArrowLeft },
    KeyIdMappingCase::{ name: "ArrowRight", key_code: ArrowRight },
    KeyIdMappingCase::{ name: "PageUp", key_code: PageUp },
    KeyIdMappingCase::{ name: "PageDown", key_code: PageDown },
    KeyIdMappingCase::{ name: "Space", key_code: Space },
    KeyIdMappingCase::{ name: "Escape", key_code: Escape },
    KeyIdMappingCase::{ name: "Semicolon", key_code: Semicolon },
    KeyIdMappingCase::{ name: "Comma", key_code: Comma },
    KeyIdMappingCase::{ name: "Period", key_code: Period },
    KeyIdMappingCase::{ name: "Slash", key_code: Slash },
    KeyIdMappingCase::{ name: "Minus", key_code: Minus },
    KeyIdMappingCase::{ name: "Equal", key_code: Equal },
    KeyIdMappingCase::{ name: "NumpadAdd", key_code: NumpadAdd },
    KeyIdMappingCase::{ name: "NumpadSubtract", key_code: NumpadSubtract },
    KeyIdMappingCase::{ name: "BracketLeft", key_code: BracketLeft },
    KeyIdMappingCase::{ name: "BracketRight", key_code: BracketRight },
    KeyIdMappingCase::{ name: "Quote", key_code: Quote },
  ]
}

///|
test "windowing_native: input key lookup stays aligned with keycode ids" {
  for case_ in key_id_mapping_cases() {
    assert_eq(
      input_key_id(case_.name),
      input_key_id_from_key_code(case_.key_code),
    )
  }
}

///|
test "windowing_native: unsupported key names stay unmapped" {
  assert_eq(input_key_id("Digit9"), -1)
  assert_eq(input_key_id("Digit0"), -1)
  assert_eq(input_key_id("Backquote"), -1)
  assert_eq(input_key_id("Backslash"), -1)
  assert_eq(input_key_id("Unknown"), -1)
}
