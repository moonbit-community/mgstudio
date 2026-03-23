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
pub(all) enum KeyCode {
  KeyA
  KeyB
  KeyC
  KeyD
  KeyE
  KeyF
  KeyG
  KeyH
  KeyI
  KeyJ
  KeyK
  KeyL
  KeyM
  KeyN
  KeyO
  KeyP
  KeyQ
  KeyR
  KeyS
  KeyT
  KeyU
  KeyV
  KeyW
  KeyX
  KeyY
  KeyZ
  Digit1
  Digit2
  Digit3
  Digit4
  Digit5
  Digit6
  Digit7
  Digit8
  F1
  F2
  F3
  F4
  F5
  F6
  F7
  F8
  F9
  F10
  F11
  F12
  Tab
  Enter
  Backspace
  ShiftLeft
  ShiftRight
  ControlLeft
  ControlRight
  ArrowUp
  ArrowDown
  ArrowLeft
  ArrowRight
  PageUp
  PageDown
  Space
  Escape
  Semicolon
  Comma
  Period
  Slash
  Minus
  Equal
  NumpadAdd
  NumpadSubtract
  BracketLeft
  BracketRight
  Quote
} derive(Eq, Hash, Show, ToJson, FromJson)

///|
pub(all) enum MouseButton {
  Left
  Right
  Middle
} derive(Eq, Hash, Show, ToJson, FromJson)

///|
pub(all) enum ButtonState {
  Pressed
  Released
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn ButtonState::is_pressed(self : ButtonState) -> Bool {
  match self {
    Pressed => true
    Released => false
  }
}

///|
pub(all) enum Key {
  Character(String)
  Enter
  Backspace
  Tab
  Shift
  Control
  ArrowUp
  ArrowDown
  ArrowLeft
  ArrowRight
  PageUp
  PageDown
  Space
  Escape
  Function(Int)
} derive(Eq, ToJson, FromJson)

///|
pub(all) struct KeyboardInput {
  key_code : KeyCode
  logical_key : Key
  state : ButtonState
  repeat : Bool
  text : String?
} derive(ToJson, FromJson)

///|
pub(all) struct KeyboardCharacter {
  character : String
} derive(ToJson, FromJson)

///|
pub(all) struct KeyboardFocusLost {} derive(Eq, ToJson, FromJson)

///|
pub(all) struct MouseButtonInput {
  button : MouseButton
  state : ButtonState
} derive(ToJson, FromJson)

///|
pub(all) struct MouseMotion {
  delta : @math.Vec2
} derive(ToJson, FromJson)

///|
pub(all) enum MouseScrollUnit {
  Line
  Pixel
} derive(ToJson, FromJson)

///|
pub(all) struct MouseWheel {
  unit : MouseScrollUnit
  x : Float
  y : Float
} derive(ToJson, FromJson)

///|
pub(all) struct PinchGesture {
  delta : Float
} derive(ToJson, FromJson)

///|
pub(all) struct RotationGesture {
  delta : Float
} derive(ToJson, FromJson)

///|
pub(all) struct DoubleTapGesture {} derive(ToJson, FromJson)

///|
pub(all) struct PanGesture {
  delta : @math.Vec2
} derive(ToJson, FromJson)

///|
pub(all) enum TouchPhase {
  Started
  Moved
  Ended
  Canceled
} derive(ToJson, FromJson)

///|
pub(all) struct TouchInput {
  id : Int
  phase : TouchPhase
  position : @math.Vec2
} derive(ToJson, FromJson)

///|
pub let ecs_key_keyboard_input : @ecs.MessageKey[KeyboardInput] = @ecs.register_message(
  debug_name="bevy_input::keyboard::KeyboardInput",
)

///|
pub let ecs_key_keyboard_character : @ecs.MessageKey[KeyboardCharacter] = @ecs.register_message(
  debug_name="bevy_input::keyboard::KeyboardCharacter",
)

///|
pub let ecs_key_keyboard_focus_lost : @ecs.MessageKey[KeyboardFocusLost] = @ecs.register_message(
  debug_name="bevy_input::keyboard::KeyboardFocusLost",
)

///|
pub let ecs_key_mouse_button_input : @ecs.MessageKey[MouseButtonInput] = @ecs.register_message(
  debug_name="bevy_input::mouse::MouseButtonInput",
)

///|
pub let ecs_key_mouse_motion : @ecs.MessageKey[MouseMotion] = @ecs.register_message(
  debug_name="bevy_input::mouse::MouseMotion",
)

///|
pub let ecs_key_mouse_wheel : @ecs.MessageKey[MouseWheel] = @ecs.register_message(
  debug_name="bevy_input::mouse::MouseWheel",
)

///|
pub let ecs_key_pinch_gesture : @ecs.MessageKey[PinchGesture] = @ecs.register_message(
  debug_name="bevy_input::gestures::PinchGesture",
)

///|
pub let ecs_key_rotation_gesture : @ecs.MessageKey[RotationGesture] = @ecs.register_message(
  debug_name="bevy_input::gestures::RotationGesture",
)

///|
pub let ecs_key_double_tap_gesture : @ecs.MessageKey[DoubleTapGesture] = @ecs.register_message(
  debug_name="bevy_input::gestures::DoubleTapGesture",
)

///|
pub let ecs_key_pan_gesture : @ecs.MessageKey[PanGesture] = @ecs.register_message(
  debug_name="bevy_input::gestures::PanGesture",
)

///|
pub let ecs_key_touch_input : @ecs.MessageKey[TouchInput] = @ecs.register_message(
  debug_name="bevy_input::touch::TouchInput",
)

///|
pub impl @ecs.Message for KeyboardInput with message() {
  ecs_key_keyboard_input
}

///|
pub impl @ecs.Message for KeyboardCharacter with message() {
  ecs_key_keyboard_character
}

///|
pub impl @ecs.Message for KeyboardFocusLost with message() {
  ecs_key_keyboard_focus_lost
}

///|
pub impl @ecs.Message for MouseButtonInput with message() {
  ecs_key_mouse_button_input
}

///|
pub impl @ecs.Message for MouseMotion with message() {
  ecs_key_mouse_motion
}

///|
pub impl @ecs.Message for MouseWheel with message() {
  ecs_key_mouse_wheel
}

///|
pub impl @ecs.Message for PinchGesture with message() {
  ecs_key_pinch_gesture
}

///|
pub impl @ecs.Message for RotationGesture with message() {
  ecs_key_rotation_gesture
}

///|
pub impl @ecs.Message for DoubleTapGesture with message() {
  ecs_key_double_tap_gesture
}

///|
pub impl @ecs.Message for PanGesture with message() {
  ecs_key_pan_gesture
}

///|
pub impl @ecs.Message for TouchInput with message() {
  ecs_key_touch_input
}
