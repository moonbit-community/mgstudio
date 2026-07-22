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
    { name: "KeyA", key_code: KeyA },
    { name: "KeyB", key_code: KeyB },
    { name: "KeyC", key_code: KeyC },
    { name: "KeyD", key_code: KeyD },
    { name: "KeyE", key_code: KeyE },
    { name: "KeyF", key_code: KeyF },
    { name: "KeyG", key_code: KeyG },
    { name: "KeyH", key_code: KeyH },
    { name: "KeyI", key_code: KeyI },
    { name: "KeyJ", key_code: KeyJ },
    { name: "KeyK", key_code: KeyK },
    { name: "KeyL", key_code: KeyL },
    { name: "KeyM", key_code: KeyM },
    { name: "KeyN", key_code: KeyN },
    { name: "KeyO", key_code: KeyO },
    { name: "KeyP", key_code: KeyP },
    { name: "KeyQ", key_code: KeyQ },
    { name: "KeyR", key_code: KeyR },
    { name: "KeyS", key_code: KeyS },
    { name: "KeyT", key_code: KeyT },
    { name: "KeyU", key_code: KeyU },
    { name: "KeyV", key_code: KeyV },
    { name: "KeyW", key_code: KeyW },
    { name: "KeyX", key_code: KeyX },
    { name: "KeyY", key_code: KeyY },
    { name: "KeyZ", key_code: KeyZ },
    { name: "Digit1", key_code: Digit1 },
    { name: "Digit2", key_code: Digit2 },
    { name: "Digit3", key_code: Digit3 },
    { name: "Digit4", key_code: Digit4 },
    { name: "Digit5", key_code: Digit5 },
    { name: "Digit6", key_code: Digit6 },
    { name: "Digit7", key_code: Digit7 },
    { name: "Digit8", key_code: Digit8 },
    { name: "Digit9", key_code: Digit9 },
    { name: "Digit0", key_code: Digit0 },
    { name: "Tab", key_code: Tab },
    { name: "Enter", key_code: Enter },
    { name: "Backspace", key_code: Backspace },
    { name: "ShiftLeft", key_code: ShiftLeft },
    { name: "ShiftRight", key_code: ShiftRight },
    { name: "ControlLeft", key_code: ControlLeft },
    { name: "ControlRight", key_code: ControlRight },
    { name: "ArrowUp", key_code: ArrowUp },
    { name: "ArrowDown", key_code: ArrowDown },
    { name: "ArrowLeft", key_code: ArrowLeft },
    { name: "ArrowRight", key_code: ArrowRight },
    { name: "PageUp", key_code: PageUp },
    { name: "PageDown", key_code: PageDown },
    { name: "Space", key_code: Space },
    { name: "Escape", key_code: Escape },
    { name: "Semicolon", key_code: Semicolon },
    { name: "Comma", key_code: Comma },
    { name: "Period", key_code: Period },
    { name: "Slash", key_code: Slash },
    { name: "Minus", key_code: Minus },
    { name: "Equal", key_code: Equal },
    { name: "NumpadAdd", key_code: NumpadAdd },
    { name: "NumpadSubtract", key_code: NumpadSubtract },
    { name: "BracketLeft", key_code: BracketLeft },
    { name: "BracketRight", key_code: BracketRight },
    { name: "Quote", key_code: Quote },
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
  assert_eq(input_key_id("Backquote"), -1)
  assert_eq(input_key_id("Backslash"), -1)
  assert_eq(input_key_id("Unknown"), -1)
}
