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
fn keycode_to_string(code : @window.KeyCode) -> String {
  match code {
    KeyA => "KeyA"
    KeyB => "KeyB"
    KeyC => "KeyC"
    KeyD => "KeyD"
    KeyE => "KeyE"
    KeyF => "KeyF"
    KeyG => "KeyG"
    KeyH => "KeyH"
    KeyI => "KeyI"
    KeyJ => "KeyJ"
    KeyK => "KeyK"
    KeyL => "KeyL"
    KeyM => "KeyM"
    KeyN => "KeyN"
    KeyO => "KeyO"
    KeyP => "KeyP"
    KeyQ => "KeyQ"
    KeyR => "KeyR"
    KeyS => "KeyS"
    KeyT => "KeyT"
    KeyU => "KeyU"
    KeyV => "KeyV"
    KeyW => "KeyW"
    KeyX => "KeyX"
    KeyY => "KeyY"
    KeyZ => "KeyZ"
    Digit1 => "Digit1"
    Digit2 => "Digit2"
    Digit3 => "Digit3"
    Digit4 => "Digit4"
    Digit5 => "Digit5"
    Digit6 => "Digit6"
    Digit7 => "Digit7"
    Digit8 => "Digit8"
    F1 => "F1"
    F2 => "F2"
    F3 => "F3"
    F4 => "F4"
    F5 => "F5"
    F6 => "F6"
    F7 => "F7"
    F8 => "F8"
    F9 => "F9"
    F10 => "F10"
    F11 => "F11"
    F12 => "F12"
    Tab => "Tab"
    Enter => "Enter"
    Backspace => "Backspace"
    ShiftLeft => "ShiftLeft"
    ShiftRight => "ShiftRight"
    ControlLeft => "ControlLeft"
    ControlRight => "ControlRight"
    ArrowUp => "ArrowUp"
    ArrowDown => "ArrowDown"
    ArrowLeft => "ArrowLeft"
    ArrowRight => "ArrowRight"
    PageUp => "PageUp"
    PageDown => "PageDown"
    Space => "Space"
    Escape => "Escape"
    Semicolon => "Semicolon"
    Comma => "Comma"
    Period => "Period"
    Slash => "Slash"
    Minus => "Minus"
    Equal => "Equal"
    NumpadAdd => "NumpadAdd"
    NumpadSubtract => "NumpadSubtract"
    BracketLeft => "BracketLeft"
    BracketRight => "BracketRight"
    Quote => "Quote"
  }
}

///|
let keyboard_event_keycodes : Array[@window.KeyCode] = [
  KeyA,
  KeyB,
  KeyC,
  KeyD,
  KeyE,
  KeyF,
  KeyG,
  KeyH,
  KeyI,
  KeyJ,
  KeyK,
  KeyL,
  KeyM,
  KeyN,
  KeyO,
  KeyP,
  KeyQ,
  KeyR,
  KeyS,
  KeyT,
  KeyU,
  KeyV,
  KeyW,
  KeyX,
  KeyY,
  KeyZ,
  Digit1,
  Digit2,
  Digit3,
  Digit4,
  Digit5,
  Digit6,
  Digit7,
  Digit8,
  F1,
  F2,
  F3,
  F4,
  F5,
  F6,
  F7,
  F8,
  F9,
  F10,
  F11,
  F12,
  Tab,
  Enter,
  Backspace,
  ShiftLeft,
  ShiftRight,
  ControlLeft,
  ControlRight,
  ArrowUp,
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  PageUp,
  PageDown,
  Space,
  Escape,
  Semicolon,
  Comma,
  Period,
  Slash,
  Minus,
  Equal,
  NumpadAdd,
  NumpadSubtract,
  BracketLeft,
  BracketRight,
  Quote,
]

///|
pub type ButtonState = @input_events.ButtonState

///|
pub type Key = @input_events.Key

///|
pub(open) trait ButtonInputButton {
  button_id(self : Self) -> String
}

///|
pub(open) trait ButtonInputSnapshotProvider {
  read_button_input() -> ButtonInput[Self]
}

///|
pub struct ButtonInput[T] {
  pressed : Array[(String, T)]
  just_pressed : Array[(String, T)]
  just_released : Array[(String, T)]
}

///|
pub fn[T] ButtonInput::new() -> ButtonInput[T] {
  { pressed: [], just_pressed: [], just_released: [] }
}

///|
pub impl[T] Default for ButtonInput[T] with default() {
  ButtonInput::new()
}

///|
pub impl[T : ToJson] ToJson for ButtonInput[T] with to_json(self) {
  (self.pressed, self.just_pressed, self.just_released).to_json()
}

///|
pub impl[T : @json.FromJson] @json.FromJson for ButtonInput[T] with from_json(
  json,
  path,
) {
  let (pressed, just_pressed, just_released) : (
    Array[(String, T)],
    Array[(String, T)],
    Array[(String, T)],
  ) = @json.from_json(json, path~)
  ButtonInput::{ pressed, just_pressed, just_released }
}

///|
pub struct Axis[T] {
  axis_data : Array[(T, Float)]
}

///|
pub const AXIS_MIN : Float = -1.0F

///|
pub const AXIS_MAX : Float = 1.0F

///|
pub fn[T] Axis::new() -> Axis[T] {
  { axis_data: [] }
}

///|
pub impl[T] Default for Axis[T] with default() {
  Axis::new()
}

///|
pub impl[T : ToJson] ToJson for Axis[T] with to_json(self) {
  self.axis_data.to_json()
}

///|
pub impl[T : @json.FromJson] @json.FromJson for Axis[T] with from_json(
  json,
  path,
) {
  let axis_data : Array[(T, Float)] = @json.from_json(json, path~)
  Axis::{ axis_data, }
}

///|
fn clamp_axis_value(value : Float) -> Float {
  if value < AXIS_MIN {
    AXIS_MIN
  } else if value > AXIS_MAX {
    AXIS_MAX
  } else {
    value
  }
}

///|
fn[T : Eq] axis_index_of(
  axis_data : Array[(T, Float)],
  input_device : T,
) -> Int? {
  for i in 0..<axis_data.length() {
    if axis_data[i].0 == input_device {
      return Some(i)
    }
  }
  None
}

///|
fn[T] entry_contains(xs : Array[(String, T)], button_id : String) -> Bool {
  for entry in xs {
    if entry.0 == button_id {
      return true
    }
  }
  false
}

///|
fn[T : ButtonInputButton] entry_push_unique(
  xs : Array[(String, T)],
  button : T,
) -> Unit {
  let id = ButtonInputButton::button_id(button)
  if !entry_contains(xs, id) {
    xs.push((id, button))
  }
}

///|
fn[T] entry_remove(xs : Array[(String, T)], button_id : String) -> Bool {
  for i in 0..<xs.length() {
    if xs[i].0 == button_id {
      xs.remove(i) |> ignore
      return true
    }
  }
  false
}

///|
fn[T : ButtonInputButton] button_input_mark_pressed(
  input : ButtonInput[T],
  button : T,
) -> Unit {
  entry_push_unique(input.pressed, button)
}

///|
fn[T : ButtonInputButton] button_input_mark_just_pressed(
  input : ButtonInput[T],
  button : T,
) -> Unit {
  entry_push_unique(input.just_pressed, button)
}

///|
fn[T : ButtonInputButton] button_input_mark_just_released(
  input : ButtonInput[T],
  button : T,
) -> Unit {
  entry_push_unique(input.just_released, button)
}

///|
pub fn[T : ButtonInputButton] ButtonInput::press(
  self : ButtonInput[T],
  input : T,
) -> Unit {
  if !entry_contains(self.pressed, ButtonInputButton::button_id(input)) {
    self.pressed.push((ButtonInputButton::button_id(input), input))
    entry_push_unique(self.just_pressed, input)
  }
}

///|
pub fn[T : ButtonInputButton] ButtonInput::pressed(
  self : ButtonInput[T],
  button : T,
) -> Bool {
  entry_contains(self.pressed, ButtonInputButton::button_id(button))
}

///|
pub fn[T : ButtonInputButton] ButtonInput::any_pressed(
  self : ButtonInput[T],
  buttons : Array[T],
) -> Bool {
  for button in buttons {
    if self.pressed(button) {
      return true
    }
  }
  false
}

///|
pub fn[T : ButtonInputButton] ButtonInput::all_pressed(
  self : ButtonInput[T],
  buttons : Array[T],
) -> Bool {
  for button in buttons {
    if !self.pressed(button) {
      return false
    }
  }
  true
}

///|
pub fn[T : ButtonInputButton] ButtonInput::release(
  self : ButtonInput[T],
  input : T,
) -> Unit {
  if entry_remove(self.pressed, ButtonInputButton::button_id(input)) {
    entry_push_unique(self.just_released, input)
  }
}

///|
pub fn[T : ButtonInputButton] ButtonInput::release_all(
  self : ButtonInput[T],
) -> Unit {
  for input in self.get_pressed() {
    entry_push_unique(self.just_released, input)
  }
  self.pressed.clear()
}

///|
pub fn[T : ButtonInputButton] ButtonInput::just_pressed(
  self : ButtonInput[T],
  button : T,
) -> Bool {
  entry_contains(self.just_pressed, ButtonInputButton::button_id(button))
}

///|
pub fn[T : ButtonInputButton] ButtonInput::any_just_pressed(
  self : ButtonInput[T],
  buttons : Array[T],
) -> Bool {
  for button in buttons {
    if self.just_pressed(button) {
      return true
    }
  }
  false
}

///|
pub fn[T : ButtonInputButton] ButtonInput::all_just_pressed(
  self : ButtonInput[T],
  buttons : Array[T],
) -> Bool {
  for button in buttons {
    if !self.just_pressed(button) {
      return false
    }
  }
  true
}

///|
pub fn[T : ButtonInputButton] ButtonInput::clear_just_pressed(
  self : ButtonInput[T],
  input : T,
) -> Bool {
  entry_remove(self.just_pressed, ButtonInputButton::button_id(input))
}

///|
pub fn[T : ButtonInputButton] ButtonInput::just_released(
  self : ButtonInput[T],
  button : T,
) -> Bool {
  entry_contains(self.just_released, ButtonInputButton::button_id(button))
}

///|
pub fn[T : ButtonInputButton] ButtonInput::any_just_released(
  self : ButtonInput[T],
  buttons : Array[T],
) -> Bool {
  for button in buttons {
    if self.just_released(button) {
      return true
    }
  }
  false
}

///|
pub fn[T : ButtonInputButton] ButtonInput::all_just_released(
  self : ButtonInput[T],
  buttons : Array[T],
) -> Bool {
  for button in buttons {
    if !self.just_released(button) {
      return false
    }
  }
  true
}

///|
pub fn[T : ButtonInputButton] ButtonInput::clear_just_released(
  self : ButtonInput[T],
  input : T,
) -> Bool {
  entry_remove(self.just_released, ButtonInputButton::button_id(input))
}

///|
pub fn[T : ButtonInputButton] ButtonInput::reset(
  self : ButtonInput[T],
  input : T,
) -> Unit {
  let id = ButtonInputButton::button_id(input)
  entry_remove(self.pressed, id) |> ignore
  entry_remove(self.just_pressed, id) |> ignore
  entry_remove(self.just_released, id) |> ignore
}

///|
pub fn[T] ButtonInput::reset_all(self : ButtonInput[T]) -> Unit {
  self.pressed.clear()
  self.just_pressed.clear()
  self.just_released.clear()
}

///|
pub fn[T] ButtonInput::clear(self : ButtonInput[T]) -> Unit {
  self.just_pressed.clear()
  self.just_released.clear()
}

///|
pub fn[T] ButtonInput::get_pressed(self : ButtonInput[T]) -> Array[T] {
  let out : Array[T] = []
  for entry in self.pressed {
    out.push(entry.1)
  }
  out
}

///|
pub fn[T] ButtonInput::get_just_pressed(self : ButtonInput[T]) -> Array[T] {
  let out : Array[T] = []
  for entry in self.just_pressed {
    out.push(entry.1)
  }
  out
}

///|
pub fn[T] ButtonInput::get_just_released(self : ButtonInput[T]) -> Array[T] {
  let out : Array[T] = []
  for entry in self.just_released {
    out.push(entry.1)
  }
  out
}

///|
pub fn[T : Eq] Axis::set(
  self : Axis[T],
  input_device : T,
  position_data : Float,
) -> Float? {
  if axis_index_of(self.axis_data, input_device) is Some(index) {
    let previous = self.axis_data[index].1
    self.axis_data[index] = (input_device, position_data)
    Some(previous)
  } else {
    self.axis_data.push((input_device, position_data))
    None
  }
}

///|
pub fn[T : Eq] Axis::get(self : Axis[T], input_device : T) -> Float? {
  if axis_index_of(self.axis_data, input_device) is Some(index) {
    Some(clamp_axis_value(self.axis_data[index].1))
  } else {
    None
  }
}

///|
pub fn[T : Eq] Axis::get_unclamped(self : Axis[T], input_device : T) -> Float? {
  if axis_index_of(self.axis_data, input_device) is Some(index) {
    Some(self.axis_data[index].1)
  } else {
    None
  }
}

///|
pub fn[T : Eq] Axis::remove(self : Axis[T], input_device : T) -> Float? {
  if axis_index_of(self.axis_data, input_device) is Some(index) {
    let value = self.axis_data[index].1
    self.axis_data.remove(index) |> ignore
    Some(value)
  } else {
    None
  }
}

///|
pub fn[T] Axis::all_axes(self : Axis[T]) -> Array[T] {
  let out : Array[T] = []
  for entry in self.axis_data {
    out.push(entry.0)
  }
  out
}

///|
pub fn[T] Axis::all_axes_and_values(self : Axis[T]) -> Array[(T, Float)] {
  self.axis_data
}

///|
pub type KeyboardInput = @input_events.KeyboardInput

///|
pub type KeyboardCharacter = @input_events.KeyboardCharacter

///|
pub type KeyboardFocusLost = @input_events.KeyboardFocusLost

///|
pub type MouseButtonInput = @input_events.MouseButtonInput

///|
pub type MouseMotion = @input_events.MouseMotion

///|
pub type MouseScrollUnit = @input_events.MouseScrollUnit

///|
pub type MouseWheel = @input_events.MouseWheel

///|
pub type PinchGesture = @input_events.PinchGesture

///|
pub type RotationGesture = @input_events.RotationGesture

///|
pub type DoubleTapGesture = @input_events.DoubleTapGesture

///|
pub type PanGesture = @input_events.PanGesture

///|
pub type TouchPhase = @input_events.TouchPhase

///|
pub type TouchInput = @input_events.TouchInput

///|
pub struct Touch {
  id : Int
  position : @math.Vec2
}

///|
pub fn Touch::id(self : Touch) -> Int {
  self.id
}

///|
pub fn Touch::position(self : Touch) -> @math.Vec2 {
  self.position
}

///|
pub struct Touches {
  active : Array[Touch]
  just_pressed : Array[Touch]
  just_released : Array[Touch]
  just_canceled : Array[Touch]
}

///|
pub fn Touches::new() -> Touches {
  { active: [], just_pressed: [], just_released: [], just_canceled: [] }
}

///|
pub fn Touches::iter(self : Touches) -> Array[Touch] {
  self.active
}

///|
pub fn Touches::iter_just_pressed(self : Touches) -> Array[Touch] {
  self.just_pressed
}

///|
pub fn Touches::iter_just_released(self : Touches) -> Array[Touch] {
  self.just_released
}

///|
pub fn Touches::iter_just_canceled(self : Touches) -> Array[Touch] {
  self.just_canceled
}

///|
pub fn Touches::just_pressed(self : Touches, id : Int) -> Bool {
  for touch in self.just_pressed {
    if touch.id == id {
      return true
    }
  }
  false
}

///|
pub fn Touches::any_just_pressed(self : Touches) -> Bool {
  self.just_pressed.length() > 0
}

///|
pub struct AccumulatedMouseMotion {
  delta : @math.Vec2
}

///|
pub fn AccumulatedMouseMotion::new() -> AccumulatedMouseMotion {
  { delta: @math.Vec2::new(0.0F, 0.0F) }
}

///|
pub struct AccumulatedMouseScroll {
  unit : MouseScrollUnit
  delta : @math.Vec2
}

///|
pub fn AccumulatedMouseScroll::new() -> AccumulatedMouseScroll {
  { unit: MouseScrollUnit::Line, delta: @math.Vec2::new(0.0F, 0.0F) }
}

///|
pub fn AccumulatedMouseScroll::new_with_unit(
  unit : MouseScrollUnit,
  delta : @math.Vec2,
) -> AccumulatedMouseScroll {
  { unit, delta }
}

///|
pub let input_systems_set : @app.SystemSet = @app.system_set(
  "bevy_input::InputSystems",
)

///|
fn[T] input_resource_get(key : @ecs.ResourceKey[T]) -> T? {
  match @app.current_world() {
    Some(world) =>
      try world.get_resource(key) catch {
        _ => None
      } noraise {
        value => value
      }
    None => None
  }
}

///|
let accumulated_mouse_motion_resource_key : @ecs.ResourceKey[
  AccumulatedMouseMotion,
] = @ecs.register_resource(debug_name="bevy_input::AccumulatedMouseMotion")

///|
let accumulated_mouse_scroll_resource_key : @ecs.ResourceKey[
  AccumulatedMouseScroll,
] = @ecs.register_resource(debug_name="bevy_input::AccumulatedMouseScroll")

///|
let touches_resource_key : @ecs.ResourceKey[Touches] = @ecs.register_resource(
  debug_name="bevy_input::Touches",
)

///|
let input_last_mouse_position_ref : Ref[@math.Vec2?] = Ref::new(None)

///|
let input_active_touches_ref : Ref[Array[Touch]] = Ref::new([])

///|
let input_primary_pointer_position_ref : Ref[@math.Vec2?] = Ref::new(None)

///|
let input_primary_pointer_delta_ref : Ref[@math.Vec2] = Ref::new(
  @math.Vec2::new(0.0F, 0.0F),
)

///|
let input_window_focused_event_cursor_ref : Ref[Int] = Ref::new(0)

///|
fn host_input_is_key_down(code : String) -> Bool {
  @windowing.input_is_key_down(code)
}

///|
fn host_input_is_key_just_pressed(code : String) -> Bool {
  @windowing.input_is_key_just_pressed(code)
}

///|
fn host_input_is_key_just_released(code : String) -> Bool {
  @windowing.input_is_key_just_released(code)
}

///|
fn host_input_is_key_repeated(code : String) -> Bool {
  @windowing.input_is_key_repeated(code)
}

///|
fn host_input_clear_all_keys() -> Unit {
  @windowing.input_clear_all_keys()
}

///|
pub fn host_input_finish_frame() -> Unit {
  @windowing.input_finish_frame()
}

///|
fn host_input_is_mouse_button_down(button : String) -> Bool {
  @windowing.input_is_mouse_button_down(button)
}

///|
fn host_input_is_mouse_button_just_pressed(button : String) -> Bool {
  @windowing.input_is_mouse_button_just_pressed(button)
}

///|
fn host_input_is_mouse_button_just_released(button : String) -> Bool {
  @windowing.input_is_mouse_button_just_released(button)
}

///|
pub fn host_input_mouse_x() -> Float {
  @windowing.input_mouse_x()
}

///|
pub fn host_input_mouse_y() -> Float {
  @windowing.input_mouse_y()
}

///|
pub fn host_input_has_cursor() -> Bool {
  @windowing.input_has_cursor()
}

///|
pub fn host_input_cursor_window() -> Int {
  @windowing.input_cursor_window()
}

///|
pub fn host_input_cursor_entered_window() -> Int {
  @windowing.input_cursor_entered_window()
}

///|
pub fn host_input_cursor_left_window() -> Int {
  @windowing.input_cursor_left_window()
}

///|
pub fn host_input_wheel_x() -> Float {
  @windowing.input_wheel_x()
}

///|
pub fn host_input_wheel_y() -> Float {
  @windowing.input_wheel_y()
}

///|
fn host_input_text_event_count() -> Int {
  @windowing.input_text_event_count()
}

///|
fn host_input_text_event_len(index~ : Int) -> Int {
  @windowing.input_text_event_len(index~)
}

///|
fn host_input_text_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  @windowing.input_text_event_code_unit(index~, offset~)
}

///|
fn host_input_keyboard_event_count() -> Int {
  @windowing.input_keyboard_event_count()
}

///|
fn host_input_keyboard_event_key_id(index~ : Int) -> Int {
  @windowing.input_keyboard_event_key_id(index~)
}

///|
fn host_input_keyboard_event_state(index~ : Int) -> Int {
  @windowing.input_keyboard_event_state(index~)
}

///|
fn host_input_keyboard_event_repeat(index~ : Int) -> Bool {
  @windowing.input_keyboard_event_repeat(index~)
}

///|
fn host_input_keyboard_event_text_len(index~ : Int) -> Int {
  @windowing.input_keyboard_event_text_len(index~)
}

///|
fn host_input_keyboard_event_text_code_unit(index~ : Int, offset~ : Int) -> Int {
  @windowing.input_keyboard_event_text_code_unit(index~, offset~)
}

///|
fn host_input_ime_event_count() -> Int {
  @windowing.input_ime_event_count()
}

///|
fn host_input_ime_event_kind(index~ : Int) -> Int {
  @windowing.input_ime_event_kind(index~)
}

///|
fn host_input_ime_event_window(index~ : Int) -> Int {
  @windowing.input_ime_event_window(index~)
}

///|
fn host_input_ime_event_len(index~ : Int) -> Int {
  @windowing.input_ime_event_len(index~)
}

///|
fn host_input_ime_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  @windowing.input_ime_event_code_unit(index~, offset~)
}

///|
fn host_input_ime_event_cursor_start(index~ : Int) -> Int {
  @windowing.input_ime_event_cursor_start(index~)
}

///|
fn host_input_ime_event_cursor_end(index~ : Int) -> Int {
  @windowing.input_ime_event_cursor_end(index~)
}

///|
fn host_input_pinch_gesture_event_count() -> Int {
  @windowing.input_pinch_gesture_event_count()
}

///|
fn host_input_pinch_gesture_event_delta(index~ : Int) -> Float {
  @windowing.input_pinch_gesture_event_delta(index~)
}

///|
fn host_input_rotation_gesture_event_count() -> Int {
  @windowing.input_rotation_gesture_event_count()
}

///|
fn host_input_rotation_gesture_event_delta(index~ : Int) -> Float {
  @windowing.input_rotation_gesture_event_delta(index~)
}

///|
fn host_input_pan_gesture_event_count() -> Int {
  @windowing.input_pan_gesture_event_count()
}

///|
fn host_input_pan_gesture_event_x(index~ : Int) -> Float {
  @windowing.input_pan_gesture_event_x(index~)
}

///|
fn host_input_pan_gesture_event_y(index~ : Int) -> Float {
  @windowing.input_pan_gesture_event_y(index~)
}

///|
fn host_input_double_tap_gesture_event_count() -> Int {
  @windowing.input_double_tap_gesture_event_count()
}

///|
fn host_input_touch_event_count() -> Int {
  @windowing.input_touch_event_count()
}

///|
fn host_input_touch_event_id(index~ : Int) -> Int {
  @windowing.input_touch_event_id(index~)
}

///|
fn host_input_touch_event_phase(index~ : Int) -> Int {
  @windowing.input_touch_event_phase(index~)
}

///|
fn host_input_touch_event_x(index~ : Int) -> Float {
  @windowing.input_touch_event_x(index~)
}

///|
fn host_input_touch_event_y(index~ : Int) -> Float {
  @windowing.input_touch_event_y(index~)
}

///|
fn host_input_drag_and_drop_event_count() -> Int {
  @windowing.input_drag_and_drop_event_count()
}

///|
fn host_input_drag_and_drop_event_kind(index~ : Int) -> Int {
  @windowing.input_drag_and_drop_event_kind(index~)
}

///|
fn host_input_drag_and_drop_event_window(index~ : Int) -> Int {
  @windowing.input_drag_and_drop_event_window(index~)
}

///|
fn host_input_drag_and_drop_event_len(index~ : Int) -> Int {
  @windowing.input_drag_and_drop_event_len(index~)
}

///|
fn host_input_drag_and_drop_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  @windowing.input_drag_and_drop_event_code_unit(index~, offset~)
}

///|
pub fn key_pressed(code : @window.KeyCode) -> Bool {
  host_input_is_key_down(keycode_to_string(code))
}

///|
pub fn key_just_pressed(code : @window.KeyCode) -> Bool {
  host_input_is_key_just_pressed(keycode_to_string(code))
}

///|
pub fn key_just_released(code : @window.KeyCode) -> Bool {
  host_input_is_key_just_released(keycode_to_string(code))
}

///|
pub fn key_repeated(code : @window.KeyCode) -> Bool {
  host_input_is_key_repeated(keycode_to_string(code))
}

///|
fn mouse_button_to_string(button : @window.MouseButton) -> String {
  match button {
    Left => "Left"
    Right => "Right"
    Middle => "Middle"
  }
}

///|
fn logical_key_from_keycode(code : @window.KeyCode) -> Key {
  let shifted = key_pressed(ShiftLeft) || key_pressed(ShiftRight)
  match code {
    KeyA => Character("a")
    KeyB => Character("b")
    KeyC => Character("c")
    KeyD => Character("d")
    KeyE => Character("e")
    KeyF => Character("f")
    KeyG => Character("g")
    KeyH => Character("h")
    KeyI => Character("i")
    KeyJ => Character("j")
    KeyK => Character("k")
    KeyL => Character("l")
    KeyM => Character("m")
    KeyN => Character("n")
    KeyO => Character("o")
    KeyP => Character("p")
    KeyQ => Character("q")
    KeyR => Character("r")
    KeyS => Character("s")
    KeyT => Character("t")
    KeyU => Character("u")
    KeyV => Character("v")
    KeyW => Character("w")
    KeyX => Character("x")
    KeyY => Character("y")
    KeyZ => Character("z")
    Digit1 => Character("1")
    Digit2 => Character("2")
    Digit3 => Character("3")
    Digit4 => Character("4")
    Digit5 => Character("5")
    Digit6 => Character("6")
    Digit7 => Character("7")
    Digit8 => Character("8")
    F1 => Key::Function(1)
    F2 => Key::Function(2)
    F3 => Key::Function(3)
    F4 => Key::Function(4)
    F5 => Key::Function(5)
    F6 => Key::Function(6)
    F7 => Key::Function(7)
    F8 => Key::Function(8)
    F9 => Key::Function(9)
    F10 => Key::Function(10)
    F11 => Key::Function(11)
    F12 => Key::Function(12)
    Tab => Key::Tab
    Enter => Key::Enter
    Backspace => Key::Backspace
    ShiftLeft => Key::Shift
    ShiftRight => Key::Shift
    ControlLeft => Key::Control
    ControlRight => Key::Control
    ArrowUp => Key::ArrowUp
    ArrowDown => Key::ArrowDown
    ArrowLeft => Key::ArrowLeft
    ArrowRight => Key::ArrowRight
    PageUp => Key::PageUp
    PageDown => Key::PageDown
    Space => Character(" ")
    Escape => Key::Escape
    Semicolon => Character(";")
    Comma => Character(",")
    Period => Character(".")
    Slash => if shifted { Character("?") } else { Character("/") }
    Minus => if shifted { Character("_") } else { Character("-") }
    Equal => if shifted { Character("+") } else { Character("=") }
    NumpadAdd => Character("+")
    NumpadSubtract => Character("-")
    BracketLeft => if shifted { Character("{") } else { Character("[") }
    BracketRight => if shifted { Character("}") } else { Character("]") }
    Quote => if shifted { Character("\"") } else { Character("'") }
  }
}

///|
fn keycode_from_key_id(key_id : Int) -> @window.KeyCode? {
  match key_id {
    0 => Some(KeyA)
    1 => Some(KeyB)
    2 => Some(KeyC)
    3 => Some(KeyD)
    4 => Some(KeyE)
    5 => Some(KeyF)
    6 => Some(KeyG)
    7 => Some(KeyH)
    8 => Some(KeyI)
    9 => Some(KeyJ)
    10 => Some(KeyK)
    11 => Some(KeyL)
    12 => Some(KeyM)
    13 => Some(KeyN)
    14 => Some(KeyO)
    15 => Some(KeyP)
    16 => Some(KeyQ)
    17 => Some(KeyR)
    18 => Some(KeyS)
    19 => Some(KeyT)
    20 => Some(KeyU)
    21 => Some(KeyV)
    22 => Some(KeyW)
    23 => Some(KeyX)
    24 => Some(KeyY)
    25 => Some(KeyZ)
    26 => Some(Digit1)
    27 => Some(Digit2)
    28 => Some(Digit3)
    29 => Some(Digit4)
    30 => Some(Digit5)
    31 => Some(Digit6)
    32 => Some(Digit7)
    33 => Some(Digit8)
    34 => Some(F1)
    35 => Some(F2)
    36 => Some(F3)
    37 => Some(F4)
    38 => Some(F5)
    39 => Some(F6)
    40 => Some(F7)
    41 => Some(F8)
    42 => Some(F9)
    43 => Some(F10)
    44 => Some(F11)
    45 => Some(F12)
    46 => Some(Tab)
    47 => Some(Enter)
    48 => Some(Backspace)
    49 => Some(ShiftLeft)
    50 => Some(ShiftRight)
    51 => Some(ControlLeft)
    52 => Some(ControlRight)
    53 => Some(ArrowUp)
    54 => Some(ArrowDown)
    55 => Some(ArrowLeft)
    56 => Some(ArrowRight)
    57 => Some(PageUp)
    58 => Some(PageDown)
    59 => Some(Space)
    60 => Some(Escape)
    61 => Some(Semicolon)
    62 => Some(Comma)
    63 => Some(Period)
    64 => Some(Slash)
    65 => Some(Minus)
    66 => Some(Equal)
    67 => Some(BracketLeft)
    68 => Some(BracketRight)
    69 => Some(Quote)
    70 => Some(NumpadAdd)
    71 => Some(NumpadSubtract)
    _ => None
  }
}

///|
let mouse_event_buttons : Array[@window.MouseButton] = [Left, Right, Middle]

///|
pub fn mouse_button_pressed(button : @window.MouseButton) -> Bool {
  host_input_is_mouse_button_down(mouse_button_to_string(button))
}

///|
pub fn mouse_button_just_pressed(button : @window.MouseButton) -> Bool {
  host_input_is_mouse_button_just_pressed(mouse_button_to_string(button))
}

///|
pub fn mouse_button_just_released(button : @window.MouseButton) -> Bool {
  host_input_is_mouse_button_just_released(mouse_button_to_string(button))
}

///|
pub fn mouse_position() -> @math.Vec2? {
  if host_input_has_cursor() {
    let raw_x = host_input_mouse_x()
    let raw_y = host_input_mouse_y()
    let cursor_window = host_input_cursor_window()
    if cursor_window < 0 {
      Some(@math.Vec2::new(raw_x, raw_y))
    } else {
      let sf0 = @windowing.scale_factor(cursor_window)
      let sf = if sf0 <= 0.0F { 1.0F } else { sf0 }
      let logical_x = raw_x / sf
      let logical_y = raw_y / sf
      Some(@math.Vec2::new(logical_x, logical_y))
    }
  } else {
    None
  }
}

///|
fn input_primary_pointer_from_touches(touches : Touches) -> @math.Vec2? {
  if touches.active.length() > 0 {
    Some(touches.active[0].position)
  } else if touches.just_pressed.length() > 0 {
    Some(touches.just_pressed[0].position)
  } else {
    None
  }
}

///|
pub fn mouse_motion_delta() -> @math.Vec2 {
  match input_resource_get(AccumulatedMouseMotion::resource()) {
    Some(motion) => motion.delta
    None => @math.Vec2::new(0.0F, 0.0F)
  }
}

///|
pub fn mouse_motion_delta_opt() -> @math.Vec2? {
  let delta = mouse_motion_delta()
  if delta.x == 0.0F && delta.y == 0.0F {
    None
  } else {
    Some(delta)
  }
}

///|
pub fn primary_pointer_position() -> @math.Vec2? {
  match input_primary_pointer_position_ref.val {
    Some(position) => Some(position)
    None =>
      if input_resource_get(Touches::resource()) is Some(touches) {
        if input_primary_pointer_from_touches(touches) is Some(touch_position) {
          Some(touch_position)
        } else {
          mouse_position()
        }
      } else {
        mouse_position()
      }
  }
}

///|
pub fn primary_pointer_pressed() -> Bool {
  if mouse_button_pressed(@window.MouseButton::Left) {
    return true
  }
  if input_resource_get(Touches::resource()) is Some(touches) {
    return touches.active.length() > 0
  }
  false
}

///|
pub fn primary_pointer_just_pressed() -> Bool {
  if mouse_button_just_pressed(@window.MouseButton::Left) {
    return true
  }
  if input_resource_get(Touches::resource()) is Some(touches) {
    return touches.just_pressed.length() > 0
  }
  false
}

///|
pub fn primary_pointer_just_released() -> Bool {
  if mouse_button_just_released(@window.MouseButton::Left) {
    return true
  }
  if input_resource_get(Touches::resource()) is Some(touches) {
    return touches.just_released.length() > 0 ||
      touches.just_canceled.length() > 0
  }
  false
}

///|
pub fn primary_pointer_delta() -> @math.Vec2 {
  input_primary_pointer_delta_ref.val
}

///|
pub fn primary_pointer_delta_opt() -> @math.Vec2? {
  let delta = primary_pointer_delta()
  if delta.x == 0.0F && delta.y == 0.0F {
    None
  } else {
    Some(delta)
  }
}

///|
/// Mouse wheel delta since last `host_input_finish_frame()`.
pub fn mouse_wheel_delta() -> @math.Vec2 {
  @math.Vec2::new(host_input_wheel_x(), host_input_wheel_y())
}

///|
/// Mouse wheel delta, or `None` if both components are zero.
pub fn mouse_wheel_delta_opt() -> @math.Vec2? {
  let v = mouse_wheel_delta()
  if v.x == 0.0F && v.y == 0.0F {
    None
  } else {
    Some(v)
  }
}

///|
fn input_text_event_at(index : Int) -> String? {
  let len = host_input_text_event_len(index~)
  if len <= 0 {
    return None
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let code_unit = host_input_text_event_code_unit(index~, offset=i)
    if code_unit.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
fn input_keyboard_event_text(index : Int) -> String? {
  let len = host_input_keyboard_event_text_len(index~)
  if len <= 0 {
    return None
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let code_unit = host_input_keyboard_event_text_code_unit(index~, offset=i)
    if code_unit.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
fn input_ime_event_text(index : Int) -> String? {
  let len = host_input_ime_event_len(index~)
  if len <= 0 {
    return None
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let code_unit = host_input_ime_event_code_unit(index~, offset=i)
    if code_unit.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
fn input_ime_event_at(world : @ecs.World, index : Int) -> @window.Ime? {
  let host_window = host_input_ime_event_window(index~)
  let window_entity = if @window.window_entity_for_host(world, host_window)
    is Some(entity) {
    Some(entity)
  } else {
    @window.window_entity_for_ref(world, @window.WindowRef::Primary)
  }
  guard window_entity is Some(window_entity0) else { return None }
  let kind = host_input_ime_event_kind(index~)
  let text = input_ime_event_text(index).unwrap_or("")
  let cursor_start = host_input_ime_event_cursor_start(index~)
  let cursor_end = host_input_ime_event_cursor_end(index~)
  match kind {
    1 => Some(@window.Ime::Enabled(window_entity0))
    2 => {
      let cursor = if cursor_start >= 0 && cursor_end >= cursor_start {
        Some(@window.ImeCursorRange::new(cursor_start, cursor_end))
      } else {
        None
      }
      Some(@window.Ime::Preedit(window_entity0, text, cursor))
    }
    3 => Some(@window.Ime::Commit(window_entity0, text))
    4 => Some(@window.Ime::Disabled(window_entity0))
    5 =>
      Some(
        @window.Ime::DeleteSurrounding(window_entity0, cursor_start, cursor_end),
      )
    _ => None
  }
}

///|
fn input_drag_and_drop_event_text(index : Int) -> String? {
  let len = host_input_drag_and_drop_event_len(index~)
  if len <= 0 {
    return None
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let code_unit = host_input_drag_and_drop_event_code_unit(index~, offset=i)
    if code_unit.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
fn input_drag_and_drop_event_at(
  world : @ecs.World,
  index : Int,
) -> @window.FileDragAndDrop? {
  let host_window = host_input_drag_and_drop_event_window(index~)
  if host_window < 0 {
    return None
  }
  guard @window.window_entity_for_host(world, host_window)
    is Some(window_entity) else {
    return None
  }
  let kind = host_input_drag_and_drop_event_kind(index~)
  match kind {
    0 =>
      if input_drag_and_drop_event_text(index) is Some(path) {
        Some(@window.FileDragAndDrop::DroppedFile(window_entity, path))
      } else {
        None
      }
    1 =>
      if input_drag_and_drop_event_text(index) is Some(path) {
        Some(@window.FileDragAndDrop::HoveredFile(window_entity, path))
      } else {
        None
      }
    2 => Some(@window.FileDragAndDrop::HoveredFileCanceled(window_entity))
    _ => None
  }
}

///|
fn input_has_focused_window(world : @ecs.World) -> Bool {
  let entities : Array[@core.Entity] = []
  try! world
  .query_entities_filtered(@ecs.With::new(@window.ecs_key_window))
  .view(fn(_query_entity, entity) { entities.push(entity) })
  for entity in entities {
    if (world.entity(entity).get() catch { _ => None } : @window.Window?)
      is Some(window) {
      if window.focused {
        return true
      }
    }
  }
  false
}

///|
pub fn input_check_keyboard_focus_lost_system(world : @ecs.World) -> Unit {
  if !world.contains_message(@window.WindowFocused::message()) {
    return
  }
  let focused_reader = world.message_reader(
    @window.WindowFocused::message(),
    input_window_focused_event_cursor_ref,
  )
  let focused_events = try focused_reader.read() catch {
    _ => []
  } noraise {
    value => value
  }
  let mut saw_focus_loss = false
  for event in focused_events {
    if !event.focused {
      saw_focus_loss = true
    }
  }
  if saw_focus_loss && !input_has_focused_window(world) {
    @window.window_emit_keyboard_focus_lost(world, @window.KeyboardFocusLost::{

    })
    for code in keyboard_event_keycodes {
      if key_pressed(code) {
        @window.window_emit_keyboard_input(world, @window.KeyboardInput::{
          key_code: code,
          logical_key: logical_key_from_keycode(code),
          state: Released,
          repeat: false,
          text: None,
        })
      }
    }
    host_input_clear_all_keys()
  }
}

///|
pub fn input_poll_keyboard_system(world : @ecs.World) -> Unit {
  let character_writer = world.message_writer(keyboard_character_message_key())
  let keyboard_event_count = host_input_keyboard_event_count()
  for i in 0..<keyboard_event_count {
    let key_id = host_input_keyboard_event_key_id(index=i)
    guard keycode_from_key_id(key_id) is Some(code) else { continue }
    let state = if host_input_keyboard_event_state(index=i) == 1 {
      ButtonState::Pressed
    } else {
      ButtonState::Released
    }
    let logical_key = logical_key_from_keycode(code)
    let text = if state.is_pressed() {
      input_keyboard_event_text(i)
    } else {
      None
    }
    @window.window_emit_keyboard_input(world, @window.KeyboardInput::{
      key_code: code,
      logical_key,
      state,
      repeat: host_input_keyboard_event_repeat(index=i),
      text,
    })
  }
  let text_event_count = host_input_text_event_count()
  for i in 0..<text_event_count {
    if input_text_event_at(i) is Some(text) {
      ignore(character_writer.write(KeyboardCharacter::{ character: text }))
    }
  }
  let ime_event_count = host_input_ime_event_count()
  for i in 0..<ime_event_count {
    if input_ime_event_at(world, i) is Some(ime) {
      @window.window_emit_ime(world, ime)
    }
  }
}

///|
pub fn input_poll_drag_and_drop_system(world : @ecs.World) -> Unit {
  let event_count = host_input_drag_and_drop_event_count()
  for i in 0..<event_count {
    if input_drag_and_drop_event_at(world, i) is Some(event) {
      @window.window_emit_file_drag_and_drop(world, event)
    }
  }
}

///|
fn vec2_is_zero(value : @math.Vec2) -> Bool {
  value.x == 0.0F && value.y == 0.0F
}

///|
fn ensure_input_resources(world : @ecs.World) -> Unit {
  if (try world.get_resource(AccumulatedMouseMotion::resource()) catch {
      _ => None
    } noraise {
      value => value
    })
    is None {
    world.insert_resource(
      AccumulatedMouseMotion::resource(),
      AccumulatedMouseMotion::new(),
    )
  }
  if (try world.get_resource(AccumulatedMouseScroll::resource()) catch {
      _ => None
    } noraise {
      value => value
    })
    is None {
    world.insert_resource(
      AccumulatedMouseScroll::resource(),
      AccumulatedMouseScroll::new(),
    )
  }
  if (try world.get_resource(Touches::resource()) catch {
      _ => None
    } noraise {
      value => value
    })
    is None {
    world.insert_resource(Touches::resource(), Touches::new())
  }
}

///|
fn touch_phase_from_host(value : Int) -> TouchPhase {
  match value {
    0 => TouchPhase::Started
    1 => TouchPhase::Moved
    2 => TouchPhase::Ended
    _ => TouchPhase::Canceled
  }
}

///|
fn active_touches_upsert(active : Array[Touch], touch : Touch) -> Unit {
  let n = active.length()
  for i in 0..<n {
    if active[i].id == touch.id {
      active[i] = touch
      return
    }
  }
  active.push(touch)
}

///|
fn active_touches_remove(active : Array[Touch], id : Int) -> Unit {
  let n = active.length()
  for i in 0..<n {
    if active[i].id == id {
      let last = n - 1
      if i != last {
        active[i] = active[last]
      }
      active.pop() |> ignore
      return
    }
  }
}

///|
pub fn input_poll_mouse_system(world : @ecs.World) -> Unit {
  ensure_input_resources(world)

  for button in mouse_event_buttons {
    if mouse_button_just_pressed(button) {
      @window.window_emit_mouse_button_input(world, @window.MouseButtonInput::{
        button,
        state: Pressed,
      })
    }
    if mouse_button_just_released(button) {
      @window.window_emit_mouse_button_input(world, @window.MouseButtonInput::{
        button,
        state: Released,
      })
    }
  }

  let mut mouse_delta = @math.Vec2::new(0.0F, 0.0F)
  let entered_host_window = host_input_cursor_entered_window()
  if entered_host_window >= 0 {
    if @window.window_entity_for_host(world, entered_host_window)
      is Some(window_entity) {
      @window.window_emit_cursor_entered(world, @window.CursorEntered::{
        window: window_entity,
      })
    }
  }
  let left_host_window = host_input_cursor_left_window()
  if left_host_window >= 0 {
    if @window.window_entity_for_host(world, left_host_window)
      is Some(window_entity) {
      @window.window_emit_cursor_left(world, @window.CursorLeft::{
        window: window_entity,
      })
    }
  }
  let current_position_opt = mouse_position()
  let cursor_host_window = host_input_cursor_window()
  if current_position_opt is Some(current_position) && cursor_host_window >= 0 {
    let delta_opt = match input_last_mouse_position_ref.val {
      Some(last_position) => {
        let delta = @math.Vec2::sub(current_position, last_position)
        if vec2_is_zero(delta) {
          None
        } else {
          Some(delta)
        }
      }
      None => None
    }
    if @window.window_entity_for_host(world, cursor_host_window)
      is Some(window_entity) {
      @window.window_emit_cursor_moved(world, @window.CursorMoved::{
        window: window_entity,
        position: current_position,
        delta: delta_opt,
      })
    }
    if delta_opt is Some(delta) {
      mouse_delta = delta
      @window.window_emit_mouse_motion(world, @window.MouseMotion::{ delta, })
    }
  }
  input_last_mouse_position_ref.val = current_position_opt

  let wheel_delta = mouse_wheel_delta()
  if !vec2_is_zero(wheel_delta) {
    @window.window_emit_mouse_wheel(world, @window.MouseWheel::{
      unit: MouseScrollUnit::Line,
      x: wheel_delta.x,
      y: wheel_delta.y,
    })
  }
  let pinch_gesture_event_count = host_input_pinch_gesture_event_count()
  for i in 0..<pinch_gesture_event_count {
    @window.window_emit_pinch_gesture(world, @window.PinchGesture::{
      delta: host_input_pinch_gesture_event_delta(index=i),
    })
  }
  let rotation_gesture_event_count = host_input_rotation_gesture_event_count()
  for i in 0..<rotation_gesture_event_count {
    @window.window_emit_rotation_gesture(world, @window.RotationGesture::{
      delta: host_input_rotation_gesture_event_delta(index=i),
    })
  }
  let pan_gesture_event_count = host_input_pan_gesture_event_count()
  for i in 0..<pan_gesture_event_count {
    @window.window_emit_pan_gesture(world, @window.PanGesture::{
      delta: @math.Vec2::new(
        host_input_pan_gesture_event_x(index=i),
        host_input_pan_gesture_event_y(index=i),
      ),
    })
  }
  let double_tap_gesture_event_count = host_input_double_tap_gesture_event_count()
  for _ in 0..<double_tap_gesture_event_count {
    @window.window_emit_double_tap_gesture(world, @window.DoubleTapGesture::{  })
  }

  if (try! world.get_resource_ref_mut(AccumulatedMouseMotion::resource()))
    is Some(motion_ref) {
    motion_ref.val = AccumulatedMouseMotion::{ delta: mouse_delta }
  }
  if (try! world.get_resource_ref_mut(AccumulatedMouseScroll::resource()))
    is Some(scroll_ref) {
    scroll_ref.val = AccumulatedMouseScroll::{
      unit: MouseScrollUnit::Line,
      delta: wheel_delta,
    }
  }

  let touches = Touches::new()
  let active_touches : Array[Touch] = []
  for touch in input_active_touches_ref.val {
    active_touches.push(touch)
  }
  let touch_event_count = host_input_touch_event_count()
  for i in 0..<touch_event_count {
    let touch_id = host_input_touch_event_id(index=i)
    if touch_id < 0 {
      continue
    }
    let touch_phase = touch_phase_from_host(
      host_input_touch_event_phase(index=i),
    )
    let position = @math.Vec2::new(
      host_input_touch_event_x(index=i),
      host_input_touch_event_y(index=i),
    )
    let touch = Touch::{ id: touch_id, position }
    match touch_phase {
      TouchPhase::Started => {
        active_touches_upsert(active_touches, touch)
        touches.just_pressed.push(touch)
      }
      TouchPhase::Moved => active_touches_upsert(active_touches, touch)
      TouchPhase::Ended => {
        active_touches_remove(active_touches, touch_id)
        touches.just_released.push(touch)
      }
      TouchPhase::Canceled => {
        active_touches_remove(active_touches, touch_id)
        touches.just_canceled.push(touch)
      }
    }
    @window.window_emit_touch_input(world, @window.TouchInput::{
      id: touch_id,
      phase: touch_phase,
      position,
    })
  }
  for touch in active_touches {
    touches.active.push(touch)
  }
  input_active_touches_ref.val = active_touches

  if (try! world.get_resource_ref_mut(Touches::resource())) is Some(touches_ref) {
    touches_ref.val = touches
  }

  let primary_pointer_position = if current_position_opt is Some(mouse_pos) {
    Some(mouse_pos)
  } else {
    input_primary_pointer_from_touches(touches)
  }
  let primary_pointer_delta = match primary_pointer_position {
    Some(current_position) =>
      if input_primary_pointer_position_ref.val is Some(last_position) {
        @math.Vec2::sub(current_position, last_position)
      } else {
        @math.Vec2::new(0.0F, 0.0F)
      }
    None => @math.Vec2::new(0.0F, 0.0F)
  }
  input_primary_pointer_position_ref.val = primary_pointer_position
  input_primary_pointer_delta_ref.val = primary_pointer_delta
}

///|
pub fn[W] input_finish_system(_world : W) -> Unit {
  input_gamepad_finish_frame()
  host_input_finish_frame()
}

///|
pub impl ButtonInputButton for @window.KeyCode with button_id(self) {
  keycode_to_string(self)
}

///|
pub impl ButtonInputButton for @window.MouseButton with button_id(self) {
  mouse_button_to_string(self)
}

///|
pub impl ButtonInputButton for Key with button_id(self) {
  self.to_json().stringify()
}

///|
fn read_keycode_button_input() -> ButtonInput[@window.KeyCode] {
  let input : ButtonInput[@window.KeyCode] = ButtonInput::new()
  for code in keyboard_event_keycodes {
    if key_pressed(code) {
      button_input_mark_pressed(input, code)
    }
    if key_just_pressed(code) {
      button_input_mark_just_pressed(input, code)
    }
    if key_just_released(code) {
      button_input_mark_just_released(input, code)
    }
  }
  input
}

///|
fn read_mouse_button_input() -> ButtonInput[@window.MouseButton] {
  let input : ButtonInput[@window.MouseButton] = ButtonInput::new()
  for button in mouse_event_buttons {
    if mouse_button_pressed(button) {
      button_input_mark_pressed(input, button)
    }
    if mouse_button_just_pressed(button) {
      button_input_mark_just_pressed(input, button)
    }
    if mouse_button_just_released(button) {
      button_input_mark_just_released(input, button)
    }
  }
  input
}

///|
fn read_logical_key_button_input() -> ButtonInput[Key] {
  let input : ButtonInput[Key] = ButtonInput::new()
  for code in keyboard_event_keycodes {
    let key = logical_key_from_keycode(code)
    if key_pressed(code) {
      button_input_mark_pressed(input, key)
    }
    if key_just_pressed(code) {
      button_input_mark_just_pressed(input, key)
    }
    if key_just_released(code) {
      button_input_mark_just_released(input, key)
    }
  }
  input
}

///|
pub impl ButtonInputSnapshotProvider for @window.KeyCode with read_button_input() {
  read_keycode_button_input()
}

///|
pub impl ButtonInputSnapshotProvider for @window.MouseButton with read_button_input() {
  read_mouse_button_input()
}

///|
pub impl ButtonInputSnapshotProvider for Key with read_button_input() {
  read_logical_key_button_input()
}

///|
pub impl[T : ButtonInputSnapshotProvider] @app.SystemParam for ButtonInput[T] with init_state(
  world,
) {
  @app.system_param_empty_state(world)
}

///|
pub impl[T : ButtonInputSnapshotProvider] @app.SystemParam for ButtonInput[T] with get(
  _state,
) {
  ButtonInputSnapshotProvider::read_button_input()
}

///|
pub impl[T : ButtonInputSnapshotProvider] @app.SystemParam for ButtonInput[T] with store(
  self,
  state,
) {
  @app.system_param_store_no_state(self, state)
}

///|
pub impl @app.Resource for AccumulatedMouseMotion with resource() {
  accumulated_mouse_motion_resource_key
}

///|
pub impl @app.Resource for AccumulatedMouseScroll with resource() {
  accumulated_mouse_scroll_resource_key
}

///|
pub impl @app.Resource for Touches with resource() {
  touches_resource_key
}

///|
pub fn input_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  input_plugin_with(app, InputPlugin::default())
}

///|
pub(all) struct InputPlugin {}

///|
pub const INPUT_PLUGIN_ID : String = "bevy_input::InputPlugin"

///|
pub fn InputPlugin::default() -> InputPlugin {
  InputPlugin::{  }
}

///|
pub impl @app.PluginReplacement for InputPlugin with replacement_id(_self) {
  INPUT_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for InputPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    input_plugin_with(app, self)
  }
}

///|
pub fn input_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : InputPlugin,
) -> @app.App[@ecs.World] {
  input_gamepad_plugin(app)
  .init_resource(AccumulatedMouseMotion::new)
  .init_resource(AccumulatedMouseScroll::new)
  .init_resource(Touches::new)
  .add_message(keyboard_input_message_key())
  .add_message(keyboard_character_message_key())
  .add_message(keyboard_focus_lost_message_key())
  .add_message(mouse_button_message_key())
  .add_message(mouse_motion_message_key())
  .add_message(mouse_wheel_message_key())
  .add_message(pinch_gesture_message_key())
  .add_message(rotation_gesture_message_key())
  .add_message(double_tap_gesture_message_key())
  .add_message(pan_gesture_message_key())
  .add_message(touch_input_message_key())
  .add_pre_update_system_config(
    @app.system(input_poll_keyboard_system).in_set(input_systems_set),
  )
  .add_pre_update_system_config(
    @app.system(input_poll_drag_and_drop_system).in_set(input_systems_set),
  )
  .add_pre_update_system_config(
    @app.system(input_poll_mouse_system).in_set(input_systems_set),
  )
  .add_post_update_system(input_finish_system)
}
