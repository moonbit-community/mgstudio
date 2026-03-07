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
  BracketLeft,
  BracketRight,
  Quote,
]

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
} derive(Eq, ToJson, FromJson)

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
  marker : T?
}

///|
pub fn[T] ButtonInput::new() -> ButtonInput[T] {
  { pressed: [], just_pressed: [], just_released: [], marker: None }
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
  ButtonInput::{ pressed, just_pressed, just_released, marker: None }
}

///|
pub struct Axis[T] {
  axis_data : Array[(T, Float)]
  marker : T?
}

///|
pub const AXIS_MIN : Float = -1.0F

///|
pub const AXIS_MAX : Float = 1.0F

///|
pub fn[T] Axis::new() -> Axis[T] {
  { axis_data: [], marker: None }
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
  Axis::{ axis_data, marker: None }
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
pub struct KeyboardInput {
  key_code : @window.KeyCode
  logical_key : Key
  state : ButtonState
  repeat : Bool
} derive(ToJson, FromJson)

///|
pub struct KeyboardCharacter {
  character : String
} derive(ToJson, FromJson)

///|
pub struct MouseButtonInput {
  button : @window.MouseButton
  state : ButtonState
} derive(ToJson, FromJson)

///|
pub struct MouseMotion {
  delta : @math.Vec2
} derive(ToJson, FromJson)

///|
pub struct CursorMoved {
  position : @math.Vec2
  delta : @math.Vec2?
} derive(ToJson, FromJson)

///|
pub(all) enum MouseScrollUnit {
  Line
  Pixel
} derive(ToJson, FromJson)

///|
pub struct MouseWheel {
  unit : MouseScrollUnit
  x : Float
  y : Float
} derive(ToJson, FromJson)

///|
pub struct PinchGesture {
  delta : Float
} derive(ToJson, FromJson)

///|
pub struct RotationGesture {
  delta : Float
} derive(ToJson, FromJson)

///|
pub struct DoubleTapGesture {
  position : @math.Vec2
} derive(ToJson, FromJson)

///|
pub(all) enum TouchPhase {
  Started
  Moved
  Ended
  Canceled
} derive(ToJson, FromJson)

///|
pub struct TouchInput {
  id : Int
  phase : TouchPhase
  position : @math.Vec2
} derive(ToJson, FromJson)

///|
pub(all) enum FileDragAndDrop {
  DroppedFile(String)
  HoveredFile(String)
  HoveredFileCanceled
} derive(ToJson, FromJson)

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
pub struct AccumulatedMouseMotion {
  delta : @math.Vec2
}

///|
pub fn AccumulatedMouseMotion::new() -> AccumulatedMouseMotion {
  { delta: @math.Vec2::new(0.0F, 0.0F) }
}

///|
pub struct AccumulatedMouseScroll {
  delta : @math.Vec2
}

///|
pub fn AccumulatedMouseScroll::new() -> AccumulatedMouseScroll {
  { delta: @math.Vec2::new(0.0F, 0.0F) }
}

///|
let keyboard_input_message_key : @ecs.MessageKey[KeyboardInput] = @ecs.register_message(
  debug_name="bevy_input::keyboard::KeyboardInput",
)

///|
let keyboard_character_message_key : @ecs.MessageKey[KeyboardCharacter] = @ecs.register_message(
  debug_name="bevy_input::keyboard::KeyboardCharacter",
)

///|
let mouse_button_input_message_key : @ecs.MessageKey[MouseButtonInput] = @ecs.register_message(
  debug_name="bevy_input::mouse::MouseButtonInput",
)

///|
let mouse_motion_message_key : @ecs.MessageKey[MouseMotion] = @ecs.register_message(
  debug_name="bevy_input::mouse::MouseMotion",
)

///|
let cursor_moved_message_key : @ecs.MessageKey[CursorMoved] = @ecs.register_message(
  debug_name="bevy_input::mouse::CursorMoved",
)

///|
let mouse_wheel_message_key : @ecs.MessageKey[MouseWheel] = @ecs.register_message(
  debug_name="bevy_input::mouse::MouseWheel",
)

///|
let pinch_gesture_message_key : @ecs.MessageKey[PinchGesture] = @ecs.register_message(
  debug_name="bevy_input::gestures::PinchGesture",
)

///|
let rotation_gesture_message_key : @ecs.MessageKey[RotationGesture] = @ecs.register_message(
  debug_name="bevy_input::gestures::RotationGesture",
)

///|
let double_tap_gesture_message_key : @ecs.MessageKey[DoubleTapGesture] = @ecs.register_message(
  debug_name="bevy_input::gestures::DoubleTapGesture",
)

///|
let touch_input_message_key : @ecs.MessageKey[TouchInput] = @ecs.register_message(
  debug_name="bevy_input::touch::TouchInput",
)

///|
let file_drag_and_drop_message_key : @ecs.MessageKey[FileDragAndDrop] = @ecs.register_message(
  debug_name="bevy_input::drag_and_drop::FileDragAndDrop",
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
fn host_input_is_key_down(code : String) -> Bool {
  @native_input.is_key_down(code)
}

///|
fn host_input_is_key_just_pressed(code : String) -> Bool {
  @native_input.is_key_just_pressed(code)
}

///|
fn host_input_is_key_just_released(code : String) -> Bool {
  @native_input.is_key_just_released(code)
}

///|
fn host_input_is_key_repeated(code : String) -> Bool {
  @native_input.is_key_repeated(code)
}

///|
pub fn host_input_finish_frame() -> Unit {
  @native_input.finish_frame()
}

///|
fn host_input_is_mouse_button_down(button : String) -> Bool {
  @native_input.is_mouse_button_down(button)
}

///|
fn host_input_is_mouse_button_just_pressed(button : String) -> Bool {
  @native_input.is_mouse_button_just_pressed(button)
}

///|
fn host_input_is_mouse_button_just_released(button : String) -> Bool {
  @native_input.is_mouse_button_just_released(button)
}

///|
pub fn host_input_mouse_x() -> Float {
  @native_input.mouse_x()
}

///|
pub fn host_input_mouse_y() -> Float {
  @native_input.mouse_y()
}

///|
pub fn host_input_has_cursor() -> Bool {
  @native_input.has_cursor()
}

///|
pub fn host_input_wheel_x() -> Float {
  @native_input.wheel_x()
}

///|
pub fn host_input_wheel_y() -> Float {
  @native_input.wheel_y()
}

///|
fn host_input_text_event_count() -> Int {
  @native_input.text_event_count()
}

///|
fn host_input_text_event_len(index~ : Int) -> Int {
  @native_input.text_event_len(index~)
}

///|
fn host_input_text_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  @native_input.text_event_code_unit(index~, offset~)
}

///|
fn host_input_touch_event_count() -> Int {
  @native_input.touch_event_count()
}

///|
fn host_input_touch_event_id(index~ : Int) -> Int {
  @native_input.touch_event_id(index~)
}

///|
fn host_input_touch_event_phase(index~ : Int) -> Int {
  @native_input.touch_event_phase(index~)
}

///|
fn host_input_touch_event_x(index~ : Int) -> Float {
  @native_input.touch_event_x(index~)
}

///|
fn host_input_touch_event_y(index~ : Int) -> Float {
  @native_input.touch_event_y(index~)
}

///|
fn host_input_drag_and_drop_event_count() -> Int {
  @native_input.drag_and_drop_event_count()
}

///|
fn host_input_drag_and_drop_event_kind(index~ : Int) -> Int {
  @native_input.drag_and_drop_event_kind(index~)
}

///|
fn host_input_drag_and_drop_event_len(index~ : Int) -> Int {
  @native_input.drag_and_drop_event_len(index~)
}

///|
fn host_input_drag_and_drop_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  @native_input.drag_and_drop_event_code_unit(index~, offset~)
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
    BracketLeft => if shifted { Character("{") } else { Character("[") }
    BracketRight => if shifted { Character("}") } else { Character("]") }
    Quote => if shifted { Character("\"") } else { Character("'") }
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
    Some(@math.Vec2::new(host_input_mouse_x(), host_input_mouse_y()))
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
fn input_drag_and_drop_event_at(index : Int) -> FileDragAndDrop? {
  let kind = host_input_drag_and_drop_event_kind(index~)
  match kind {
    0 =>
      if input_drag_and_drop_event_text(index) is Some(path) {
        Some(FileDragAndDrop::DroppedFile(path))
      } else {
        None
      }
    1 =>
      if input_drag_and_drop_event_text(index) is Some(path) {
        Some(FileDragAndDrop::HoveredFile(path))
      } else {
        None
      }
    2 => Some(FileDragAndDrop::HoveredFileCanceled)
    _ => None
  }
}

///|
pub fn input_poll_keyboard_system(world : @ecs.World) -> Unit {
  let keyboard_writer = world.message_writer(keyboard_input_message_key)
  let character_writer = world.message_writer(keyboard_character_message_key)
  for code in keyboard_event_keycodes {
    if key_repeated(code) {
      ignore(
        keyboard_writer.write(KeyboardInput::{
          key_code: code,
          logical_key: logical_key_from_keycode(code),
          state: ButtonState::Pressed,
          repeat: true,
        }),
      )
    }
    if key_just_pressed(code) {
      ignore(
        keyboard_writer.write(KeyboardInput::{
          key_code: code,
          logical_key: logical_key_from_keycode(code),
          state: ButtonState::Pressed,
          repeat: false,
        }),
      )
    }
    if key_just_released(code) {
      ignore(
        keyboard_writer.write(KeyboardInput::{
          key_code: code,
          logical_key: logical_key_from_keycode(code),
          state: ButtonState::Released,
          repeat: false,
        }),
      )
    }
  }
  let text_event_count = host_input_text_event_count()
  for i in 0..<text_event_count {
    if input_text_event_at(i) is Some(text) {
      ignore(character_writer.write(KeyboardCharacter::{ character: text }))
    }
  }
}

///|
pub fn input_poll_drag_and_drop_system(world : @ecs.World) -> Unit {
  let writer = world.message_writer(file_drag_and_drop_message_key)
  let event_count = host_input_drag_and_drop_event_count()
  for i in 0..<event_count {
    if input_drag_and_drop_event_at(i) is Some(event) {
      ignore(writer.write(event))
    }
  }
}

///|
fn vec2_is_zero(value : @math.Vec2) -> Bool {
  value.x == 0.0F && value.y == 0.0F
}

///|
fn ensure_input_resources(world : @ecs.World, tick : @core.Tick) -> Unit {
  if (try world.get_resource(AccumulatedMouseMotion::resource()) catch {
      _ => None
    } noraise {
      value => value
    })
    is None {
    world.insert_resource_with_change_tick(
      AccumulatedMouseMotion::resource(),
      AccumulatedMouseMotion::new(),
      tick,
    )
  }
  if (try world.get_resource(AccumulatedMouseScroll::resource()) catch {
      _ => None
    } noraise {
      value => value
    })
    is None {
    world.insert_resource_with_change_tick(
      AccumulatedMouseScroll::resource(),
      AccumulatedMouseScroll::new(),
      tick,
    )
  }
  if (try world.get_resource(Touches::resource()) catch {
      _ => None
    } noraise {
      value => value
    })
    is None {
    world.insert_resource_with_change_tick(
      Touches::resource(),
      Touches::new(),
      tick,
    )
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
  let tick = world.read_change_tick()
  ensure_input_resources(world, tick)
  let mouse_button_writer = world.message_writer(mouse_button_input_message_key)
  let mouse_motion_writer = world.message_writer(mouse_motion_message_key)
  let cursor_moved_writer = world.message_writer(cursor_moved_message_key)
  let mouse_wheel_writer = world.message_writer(mouse_wheel_message_key)
  let pinch_gesture_writer = world.message_writer(pinch_gesture_message_key)
  let rotation_gesture_writer = world.message_writer(
    rotation_gesture_message_key,
  )
  let touch_input_writer = world.message_writer(touch_input_message_key)

  for button in mouse_event_buttons {
    if mouse_button_just_pressed(button) {
      ignore(
        mouse_button_writer.write(MouseButtonInput::{ button, state: Pressed }),
      )
    }
    if mouse_button_just_released(button) {
      ignore(
        mouse_button_writer.write(MouseButtonInput::{ button, state: Released }),
      )
    }
  }

  let mut mouse_delta = @math.Vec2::new(0.0F, 0.0F)
  let current_position_opt = mouse_position()
  if current_position_opt is Some(current_position) {
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
    ignore(
      cursor_moved_writer.write(CursorMoved::{
        position: current_position,
        delta: delta_opt,
      }),
    )
    if delta_opt is Some(delta) {
      mouse_delta = delta
      ignore(mouse_motion_writer.write(MouseMotion::{ delta, }))
    }
  }
  input_last_mouse_position_ref.val = current_position_opt

  let wheel_delta = mouse_wheel_delta()
  if !vec2_is_zero(wheel_delta) {
    ignore(
      mouse_wheel_writer.write(MouseWheel::{
        unit: MouseScrollUnit::Line,
        x: wheel_delta.x,
        y: wheel_delta.y,
      }),
    )
  }
  // Gesture event shapes are kept for Bevy API surface parity.
  // Runtime backends do not provide gesture sources yet, so emission stays dormant.
  let pinch_delta = wheel_delta.x
  if pinch_delta > 1_000_000.0F || pinch_delta < -1_000_000.0F {
    ignore(pinch_gesture_writer.write(PinchGesture::{ delta: pinch_delta }))
  }
  let rotation_delta = wheel_delta.y
  if rotation_delta > 1_000_000.0F || rotation_delta < -1_000_000.0F {
    ignore(
      rotation_gesture_writer.write(RotationGesture::{ delta: rotation_delta }),
    )
  }

  if (try! world.get_resource_ref_mut(AccumulatedMouseMotion::resource(), tick))
    is Some(motion_ref) {
    motion_ref.val = AccumulatedMouseMotion::{ delta: mouse_delta }
  }
  if (try! world.get_resource_ref_mut(AccumulatedMouseScroll::resource(), tick))
    is Some(scroll_ref) {
    scroll_ref.val = AccumulatedMouseScroll::{ delta: wheel_delta }
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
        // Keep `DoubleTapGesture` constructed for API surface parity while
        // dedicated host-side gesture events are not wired yet.
        let probe = DoubleTapGesture::{ position, }
        probe |> ignore
      }
      TouchPhase::Canceled => {
        active_touches_remove(active_touches, touch_id)
        touches.just_canceled.push(touch)
      }
    }
    ignore(
      touch_input_writer.write(TouchInput::{
        id: touch_id,
        phase: touch_phase,
        position,
      }),
    )
  }
  for touch in active_touches {
    touches.active.push(touch)
  }
  input_active_touches_ref.val = active_touches

  if (try! world.get_resource_ref_mut(Touches::resource(), tick))
    is Some(touches_ref) {
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
pub impl @ecs.Message for KeyboardInput with message() {
  keyboard_input_message_key
}

///|
pub impl @ecs.Message for KeyboardCharacter with message() {
  keyboard_character_message_key
}

///|
pub impl @ecs.Message for MouseButtonInput with message() {
  mouse_button_input_message_key
}

///|
pub impl @ecs.Message for MouseMotion with message() {
  mouse_motion_message_key
}

///|
pub impl @ecs.Message for CursorMoved with message() {
  cursor_moved_message_key
}

///|
pub impl @ecs.Message for MouseWheel with message() {
  mouse_wheel_message_key
}

///|
pub impl @ecs.Message for PinchGesture with message() {
  pinch_gesture_message_key
}

///|
pub impl @ecs.Message for RotationGesture with message() {
  rotation_gesture_message_key
}

///|
pub impl @ecs.Message for DoubleTapGesture with message() {
  double_tap_gesture_message_key
}

///|
pub impl @ecs.Message for TouchInput with message() {
  touch_input_message_key
}

///|
pub impl @ecs.Message for FileDragAndDrop with message() {
  file_drag_and_drop_message_key
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
  input_gamepad_plugin(app)
  .add_message(keyboard_input_message_key)
  .add_message(keyboard_character_message_key)
  .add_message(mouse_button_input_message_key)
  .add_message(mouse_motion_message_key)
  .add_message(cursor_moved_message_key)
  .add_message(mouse_wheel_message_key)
  .add_message(pinch_gesture_message_key)
  .add_message(rotation_gesture_message_key)
  .add_message(double_tap_gesture_message_key)
  .add_message(touch_input_message_key)
  .add_message(file_drag_and_drop_message_key)
  .add_pre_update_system(input_poll_keyboard_system)
  .add_pre_update_system(input_poll_drag_and_drop_system)
  .add_pre_update_system(input_poll_mouse_system)
  .add_post_update_system(input_finish_system)
}
