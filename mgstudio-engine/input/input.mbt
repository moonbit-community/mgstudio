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
}

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
}

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
  pressed_ids : Array[String]
  just_pressed_ids : Array[String]
  just_released_ids : Array[String]
  marker : T?
}

///|
pub fn[T] ButtonInput::new() -> ButtonInput[T] {
  { pressed_ids: [], just_pressed_ids: [], just_released_ids: [], marker: None }
}

///|
fn string_array_contains(xs : Array[String], value : String) -> Bool {
  for x in xs {
    if x == value {
      return true
    }
  }
  false
}

///|
fn string_array_push_unique(xs : Array[String], value : String) -> Unit {
  if !string_array_contains(xs, value) {
    xs.push(value)
  }
}

///|
fn[T : ButtonInputButton] button_input_mark_pressed(
  input : ButtonInput[T],
  button : T,
) -> Unit {
  string_array_push_unique(
    input.pressed_ids,
    ButtonInputButton::button_id(button),
  )
}

///|
fn[T : ButtonInputButton] button_input_mark_just_pressed(
  input : ButtonInput[T],
  button : T,
) -> Unit {
  string_array_push_unique(
    input.just_pressed_ids,
    ButtonInputButton::button_id(button),
  )
}

///|
fn[T : ButtonInputButton] button_input_mark_just_released(
  input : ButtonInput[T],
  button : T,
) -> Unit {
  string_array_push_unique(
    input.just_released_ids,
    ButtonInputButton::button_id(button),
  )
}

///|
pub fn[T : ButtonInputButton] ButtonInput::pressed(
  self : ButtonInput[T],
  button : T,
) -> Bool {
  string_array_contains(self.pressed_ids, ButtonInputButton::button_id(button))
}

///|
pub fn[T : ButtonInputButton] ButtonInput::just_pressed(
  self : ButtonInput[T],
  button : T,
) -> Bool {
  string_array_contains(
    self.just_pressed_ids,
    ButtonInputButton::button_id(button),
  )
}

///|
pub fn[T : ButtonInputButton] ButtonInput::just_released(
  self : ButtonInput[T],
  button : T,
) -> Bool {
  string_array_contains(
    self.just_released_ids,
    ButtonInputButton::button_id(button),
  )
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
pub struct KeyboardInput {
  key_code : @window.KeyCode
  logical_key : Key
  state : ButtonState
  repeat : Bool
}

///|
pub struct KeyboardCharacter {
  character : String
}

///|
pub struct MouseButtonInput {
  button : @window.MouseButton
  state : ButtonState
}

///|
pub struct MouseMotion {
  delta : @math.Vec2
}

///|
pub struct CursorMoved {
  position : @math.Vec2
  delta : @math.Vec2?
}

///|
pub(all) enum MouseScrollUnit {
  Line
  Pixel
}

///|
pub struct MouseWheel {
  unit : MouseScrollUnit
  x : Float
  y : Float
}

///|
pub struct PinchGesture {
  delta : Float
}

///|
pub struct RotationGesture {
  delta : Float
}

///|
pub struct DoubleTapGesture {
  position : @math.Vec2
}

///|
pub(all) enum TouchPhase {
  Started
  Moved
  Ended
  Canceled
}

///|
pub struct TouchInput {
  id : Int
  phase : TouchPhase
  position : @math.Vec2
}

///|
pub(all) enum FileDragAndDrop {
  DroppedFile(String)
  HoveredFile(String)
  HoveredFileCanceled
}

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
let keyboard_input_events_ref : Ref[@core.Messages[KeyboardInput]] = Ref::new(
  @core.Messages::new(),
)

///|
let keyboard_character_events_ref : Ref[@core.Messages[KeyboardCharacter]] = Ref::new(
  @core.Messages::new(),
)

///|
let mouse_button_input_events_ref : Ref[@core.Messages[MouseButtonInput]] = Ref::new(
  @core.Messages::new(),
)

///|
let mouse_motion_events_ref : Ref[@core.Messages[MouseMotion]] = Ref::new(
  @core.Messages::new(),
)

///|
let cursor_moved_events_ref : Ref[@core.Messages[CursorMoved]] = Ref::new(
  @core.Messages::new(),
)

///|
let mouse_wheel_events_ref : Ref[@core.Messages[MouseWheel]] = Ref::new(
  @core.Messages::new(),
)

///|
let pinch_gesture_events_ref : Ref[@core.Messages[PinchGesture]] = Ref::new(
  @core.Messages::new(),
)

///|
let rotation_gesture_events_ref : Ref[@core.Messages[RotationGesture]] = Ref::new(
  @core.Messages::new(),
)

///|
let double_tap_gesture_events_ref : Ref[@core.Messages[DoubleTapGesture]] = Ref::new(
  @core.Messages::new(),
)

///|
let touch_input_events_ref : Ref[@core.Messages[TouchInput]] = Ref::new(
  @core.Messages::new(),
)

///|
let file_drag_and_drop_events_ref : Ref[@core.Messages[FileDragAndDrop]] = Ref::new(
  @core.Messages::new(),
)

///|
let accumulated_mouse_motion_resource_ref : Ref[
  @core.Resource[AccumulatedMouseMotion],
] = Ref::new(@core.Resource::new())

///|
let accumulated_mouse_scroll_resource_ref : Ref[
  @core.Resource[AccumulatedMouseScroll],
] = Ref::new(@core.Resource::new())

///|
let touches_resource_ref : Ref[@core.Resource[Touches]] = Ref::new(
  @core.Resource::new(),
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
fn host_input_is_key_down_id(code_id : Int) -> Bool = "mgstudio_host" "input_is_key_down"

///|
fn host_input_is_key_just_pressed_id(code_id : Int) -> Bool = "mgstudio_host" "input_is_key_just_pressed"

///|
fn host_input_is_key_just_released_id(code_id : Int) -> Bool = "mgstudio_host" "input_is_key_just_released"

///|
fn host_input_is_key_repeated_id(code_id : Int) -> Bool = "mgstudio_host" "input_is_key_repeated"

///|
pub fn host_input_finish_frame() -> Unit = "mgstudio_host" "input_finish_frame"

///|
fn host_input_is_mouse_button_down_id(button_id : Int) -> Bool = "mgstudio_host" "input_is_mouse_button_down"

///|
fn host_input_is_mouse_button_just_pressed_id(button_id : Int) -> Bool = "mgstudio_host" "input_is_mouse_button_just_pressed"

///|
fn host_input_is_mouse_button_just_released_id(button_id : Int) -> Bool = "mgstudio_host" "input_is_mouse_button_just_released"

///|
pub fn host_input_mouse_x() -> Float = "mgstudio_host" "input_mouse_x"

///|
pub fn host_input_mouse_y() -> Float = "mgstudio_host" "input_mouse_y"

///|
pub fn host_input_has_cursor() -> Bool = "mgstudio_host" "input_has_cursor"

///|
pub fn host_input_wheel_x() -> Float = "mgstudio_host" "input_wheel_x"

///|
pub fn host_input_wheel_y() -> Float = "mgstudio_host" "input_wheel_y"

///|
fn host_input_text_event_count() -> Int = "mgstudio_host" "input_text_event_count"

///|
fn host_input_text_event_len(index~ : Int) -> Int = "mgstudio_host" "input_text_event_len"

///|
fn host_input_text_event_code_unit(index~ : Int, offset~ : Int) -> Int = "mgstudio_host" "input_text_event_code_unit"

///|
fn host_input_touch_event_count() -> Int = "mgstudio_host" "input_touch_event_count"

///|
fn host_input_touch_event_id(index~ : Int) -> Int = "mgstudio_host" "input_touch_event_id"

///|
fn host_input_touch_event_phase(index~ : Int) -> Int = "mgstudio_host" "input_touch_event_phase"

///|
fn host_input_touch_event_x(index~ : Int) -> Float = "mgstudio_host" "input_touch_event_x"

///|
fn host_input_touch_event_y(index~ : Int) -> Float = "mgstudio_host" "input_touch_event_y"

///|
fn host_input_drag_and_drop_event_count() -> Int = "mgstudio_host" "input_drag_and_drop_event_count"

///|
fn host_input_drag_and_drop_event_kind(index~ : Int) -> Int = "mgstudio_host" "input_drag_and_drop_event_kind"

///|
fn host_input_drag_and_drop_event_len(index~ : Int) -> Int = "mgstudio_host" "input_drag_and_drop_event_len"

///|
fn host_input_drag_and_drop_event_code_unit(index~ : Int, offset~ : Int) -> Int = "mgstudio_host" "input_drag_and_drop_event_code_unit"

///|
pub fn key_pressed(code : @window.KeyCode) -> Bool {
  @core.with_host_string_id(keycode_to_string(code), fn(code_id) {
    host_input_is_key_down_id(code_id)
  })
}

///|
pub fn key_just_pressed(code : @window.KeyCode) -> Bool {
  @core.with_host_string_id(keycode_to_string(code), fn(code_id) {
    host_input_is_key_just_pressed_id(code_id)
  })
}

///|
pub fn key_just_released(code : @window.KeyCode) -> Bool {
  @core.with_host_string_id(keycode_to_string(code), fn(code_id) {
    host_input_is_key_just_released_id(code_id)
  })
}

///|
pub fn key_repeated(code : @window.KeyCode) -> Bool {
  @core.with_host_string_id(keycode_to_string(code), fn(code_id) {
    host_input_is_key_repeated_id(code_id)
  })
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
fn key_to_string(key : Key) -> String {
  match key {
    Character(text) => "Character:" + text
    Enter => "Enter"
    Backspace => "Backspace"
    Tab => "Tab"
    Shift => "Shift"
    Control => "Control"
    ArrowUp => "ArrowUp"
    ArrowDown => "ArrowDown"
    ArrowLeft => "ArrowLeft"
    ArrowRight => "ArrowRight"
    PageUp => "PageUp"
    PageDown => "PageDown"
    Space => "Space"
    Escape => "Escape"
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
  @core.with_host_string_id(mouse_button_to_string(button), fn(button_id) {
    host_input_is_mouse_button_down_id(button_id)
  })
}

///|
pub fn mouse_button_just_pressed(button : @window.MouseButton) -> Bool {
  @core.with_host_string_id(mouse_button_to_string(button), fn(button_id) {
    host_input_is_mouse_button_just_pressed_id(button_id)
  })
}

///|
pub fn mouse_button_just_released(button : @window.MouseButton) -> Bool {
  @core.with_host_string_id(mouse_button_to_string(button), fn(button_id) {
    host_input_is_mouse_button_just_released_id(button_id)
  })
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
  if accumulated_mouse_motion_resource_ref.val.get_ref() is Some(motion_ref) {
    motion_ref.val.delta
  } else {
    @math.Vec2::new(0.0F, 0.0F)
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
      if touches_resource_ref.val.get_ref() is Some(touches_ref) {
        if input_primary_pointer_from_touches(touches_ref.val)
          is Some(touch_position) {
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
  if touches_resource_ref.val.get_ref() is Some(touches_ref) {
    return touches_ref.val.active.length() > 0
  }
  false
}

///|
pub fn primary_pointer_just_pressed() -> Bool {
  if mouse_button_just_pressed(@window.MouseButton::Left) {
    return true
  }
  if touches_resource_ref.val.get_ref() is Some(touches_ref) {
    return touches_ref.val.just_pressed.length() > 0
  }
  false
}

///|
pub fn primary_pointer_just_released() -> Bool {
  if mouse_button_just_released(@window.MouseButton::Left) {
    return true
  }
  if touches_resource_ref.val.get_ref() is Some(touches_ref) {
    return touches_ref.val.just_released.length() > 0 ||
      touches_ref.val.just_canceled.length() > 0
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
pub fn[W : @core.ChangeTickWorld] input_poll_keyboard_system(world : W) -> Unit {
  let tick = world.read_change_tick()
  for code in keyboard_event_keycodes {
    if key_repeated(code) {
      keyboard_input_events_ref.val.send(tick, KeyboardInput::{
        key_code: code,
        logical_key: logical_key_from_keycode(code),
        state: ButtonState::Pressed,
        repeat: true,
      })
    }
    if key_just_pressed(code) {
      keyboard_input_events_ref.val.send(tick, KeyboardInput::{
        key_code: code,
        logical_key: logical_key_from_keycode(code),
        state: ButtonState::Pressed,
        repeat: false,
      })
    }
    if key_just_released(code) {
      keyboard_input_events_ref.val.send(tick, KeyboardInput::{
        key_code: code,
        logical_key: logical_key_from_keycode(code),
        state: ButtonState::Released,
        repeat: false,
      })
    }
  }
  let text_event_count = host_input_text_event_count()
  for i in 0..<text_event_count {
    if input_text_event_at(i) is Some(text) {
      keyboard_character_events_ref.val.send(tick, KeyboardCharacter::{
        character: text,
      })
    }
  }
}

///|
pub fn[W : @core.ChangeTickWorld] input_poll_drag_and_drop_system(
  world : W,
) -> Unit {
  let tick = world.read_change_tick()
  let event_count = host_input_drag_and_drop_event_count()
  for i in 0..<event_count {
    if input_drag_and_drop_event_at(i) is Some(event) {
      file_drag_and_drop_events_ref.val.send(tick, event)
    }
  }
}

///|
fn vec2_is_zero(value : @math.Vec2) -> Bool {
  value.x == 0.0F && value.y == 0.0F
}

///|
fn ensure_input_resources(tick : @core.Tick) -> Unit {
  let motion_resource = accumulated_mouse_motion_resource_ref.val
  if !motion_resource.is_present() {
    motion_resource.insert(AccumulatedMouseMotion::new(), tick)
  }
  let scroll_resource = accumulated_mouse_scroll_resource_ref.val
  if !scroll_resource.is_present() {
    scroll_resource.insert(AccumulatedMouseScroll::new(), tick)
  }
  let touches_resource = touches_resource_ref.val
  if !touches_resource.is_present() {
    touches_resource.insert(Touches::new(), tick)
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
pub fn[W : @core.ChangeTickWorld] input_poll_mouse_system(world : W) -> Unit {
  let tick = world.read_change_tick()
  ensure_input_resources(tick)

  for button in mouse_event_buttons {
    if mouse_button_just_pressed(button) {
      mouse_button_input_events_ref.val.send(tick, MouseButtonInput::{
        button,
        state: Pressed,
      })
    }
    if mouse_button_just_released(button) {
      mouse_button_input_events_ref.val.send(tick, MouseButtonInput::{
        button,
        state: Released,
      })
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
    cursor_moved_events_ref.val.send(tick, CursorMoved::{
      position: current_position,
      delta: delta_opt,
    })
    if delta_opt is Some(delta) {
      mouse_delta = delta
      mouse_motion_events_ref.val.send(tick, MouseMotion::{ delta, })
    }
  }
  input_last_mouse_position_ref.val = current_position_opt

  let wheel_delta = mouse_wheel_delta()
  if !vec2_is_zero(wheel_delta) {
    mouse_wheel_events_ref.val.send(tick, MouseWheel::{
      unit: MouseScrollUnit::Line,
      x: wheel_delta.x,
      y: wheel_delta.y,
    })
  }
  // Gesture event shapes are kept for Bevy API surface parity.
  // Runtime backends do not provide gesture sources yet, so emission stays dormant.
  let pinch_delta = wheel_delta.x
  if pinch_delta > 1_000_000.0F || pinch_delta < -1_000_000.0F {
    pinch_gesture_events_ref.val.send(tick, PinchGesture::{ delta: pinch_delta })
  }
  let rotation_delta = wheel_delta.y
  if rotation_delta > 1_000_000.0F || rotation_delta < -1_000_000.0F {
    rotation_gesture_events_ref.val.send(tick, RotationGesture::{
      delta: rotation_delta,
    })
  }

  if accumulated_mouse_motion_resource_ref.val.get_ref_mut(tick)
    is Some(motion_ref) {
    motion_ref.val = AccumulatedMouseMotion::{ delta: mouse_delta }
  }
  if accumulated_mouse_scroll_resource_ref.val.get_ref_mut(tick)
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
    touch_input_events_ref.val.send(tick, TouchInput::{
      id: touch_id,
      phase: touch_phase,
      position,
    })
  }
  for touch in active_touches {
    touches.active.push(touch)
  }
  input_active_touches_ref.val = active_touches

  if touches_resource_ref.val.get_ref_mut(tick) is Some(touches_ref) {
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
fn[W : @core.SystemContextWorld] input_world_system_ticks(
  world : W,
) -> @core.SystemTicks {
  world.get_system_context().ticks()
}

///|
fn keyboard_input_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[KeyboardInput] {
  keyboard_input_events_ref.val.reader(ticks)
}

///|
fn keyboard_character_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[KeyboardCharacter] {
  keyboard_character_events_ref.val.reader(ticks)
}

///|
fn keyboard_input_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[KeyboardInput] {
  keyboard_input_events_ref.val.writer(tick)
}

///|
fn keyboard_character_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[KeyboardCharacter] {
  keyboard_character_events_ref.val.writer(tick)
}

///|
fn mouse_button_input_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[MouseButtonInput] {
  mouse_button_input_events_ref.val.reader(ticks)
}

///|
fn mouse_motion_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[MouseMotion] {
  mouse_motion_events_ref.val.reader(ticks)
}

///|
fn cursor_moved_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[CursorMoved] {
  cursor_moved_events_ref.val.reader(ticks)
}

///|
fn mouse_wheel_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[MouseWheel] {
  mouse_wheel_events_ref.val.reader(ticks)
}

///|
fn pinch_gesture_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[PinchGesture] {
  pinch_gesture_events_ref.val.reader(ticks)
}

///|
fn rotation_gesture_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[RotationGesture] {
  rotation_gesture_events_ref.val.reader(ticks)
}

///|
fn double_tap_gesture_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[DoubleTapGesture] {
  double_tap_gesture_events_ref.val.reader(ticks)
}

///|
fn touch_input_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[TouchInput] {
  touch_input_events_ref.val.reader(ticks)
}

///|
fn file_drag_and_drop_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[FileDragAndDrop] {
  file_drag_and_drop_events_ref.val.reader(ticks)
}

///|
fn mouse_button_input_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[MouseButtonInput] {
  mouse_button_input_events_ref.val.writer(tick)
}

///|
fn mouse_motion_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[MouseMotion] {
  mouse_motion_events_ref.val.writer(tick)
}

///|
fn cursor_moved_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[CursorMoved] {
  cursor_moved_events_ref.val.writer(tick)
}

///|
fn mouse_wheel_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[MouseWheel] {
  mouse_wheel_events_ref.val.writer(tick)
}

///|
fn pinch_gesture_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[PinchGesture] {
  pinch_gesture_events_ref.val.writer(tick)
}

///|
fn rotation_gesture_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[RotationGesture] {
  rotation_gesture_events_ref.val.writer(tick)
}

///|
fn double_tap_gesture_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[DoubleTapGesture] {
  double_tap_gesture_events_ref.val.writer(tick)
}

///|
fn touch_input_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[TouchInput] {
  touch_input_events_ref.val.writer(tick)
}

///|
fn file_drag_and_drop_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[FileDragAndDrop] {
  file_drag_and_drop_events_ref.val.writer(tick)
}

///|
pub fn[W : @core.SystemContextWorld] keyboard_input_events(
  world : W,
) -> @core.MessageReader[KeyboardInput] {
  keyboard_input_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] keyboard_character_events(
  world : W,
) -> @core.MessageReader[KeyboardCharacter] {
  keyboard_character_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] mouse_button_input_events(
  world : W,
) -> @core.MessageReader[MouseButtonInput] {
  mouse_button_input_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] mouse_motion_events(
  world : W,
) -> @core.MessageReader[MouseMotion] {
  mouse_motion_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] cursor_moved_events(
  world : W,
) -> @core.MessageReader[CursorMoved] {
  cursor_moved_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] mouse_wheel_events(
  world : W,
) -> @core.MessageReader[MouseWheel] {
  mouse_wheel_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] pinch_gesture_events(
  world : W,
) -> @core.MessageReader[PinchGesture] {
  pinch_gesture_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] rotation_gesture_events(
  world : W,
) -> @core.MessageReader[RotationGesture] {
  rotation_gesture_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] double_tap_gesture_events(
  world : W,
) -> @core.MessageReader[DoubleTapGesture] {
  double_tap_gesture_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] touch_input_events(
  world : W,
) -> @core.MessageReader[TouchInput] {
  touch_input_events_reader(input_world_system_ticks(world))
}

///|
pub fn[W : @core.SystemContextWorld] file_drag_and_drop_events(
  world : W,
) -> @core.MessageReader[FileDragAndDrop] {
  file_drag_and_drop_events_reader(input_world_system_ticks(world))
}

///|
pub impl @core.Message for KeyboardInput with reader(ticks) {
  keyboard_input_events_reader(ticks)
}

///|
pub impl @core.Message for KeyboardInput with writer(tick) {
  keyboard_input_events_writer(tick)
}

///|
pub impl @core.Message for KeyboardCharacter with reader(ticks) {
  keyboard_character_events_reader(ticks)
}

///|
pub impl @core.Message for KeyboardCharacter with writer(tick) {
  keyboard_character_events_writer(tick)
}

///|
pub impl @core.Message for MouseButtonInput with reader(ticks) {
  mouse_button_input_events_reader(ticks)
}

///|
pub impl @core.Message for MouseButtonInput with writer(tick) {
  mouse_button_input_events_writer(tick)
}

///|
pub impl @core.Message for MouseMotion with reader(ticks) {
  mouse_motion_events_reader(ticks)
}

///|
pub impl @core.Message for MouseMotion with writer(tick) {
  mouse_motion_events_writer(tick)
}

///|
pub impl @core.Message for CursorMoved with reader(ticks) {
  cursor_moved_events_reader(ticks)
}

///|
pub impl @core.Message for CursorMoved with writer(tick) {
  cursor_moved_events_writer(tick)
}

///|
pub impl @core.Message for MouseWheel with reader(ticks) {
  mouse_wheel_events_reader(ticks)
}

///|
pub impl @core.Message for MouseWheel with writer(tick) {
  mouse_wheel_events_writer(tick)
}

///|
pub impl @core.Message for PinchGesture with reader(ticks) {
  pinch_gesture_events_reader(ticks)
}

///|
pub impl @core.Message for PinchGesture with writer(tick) {
  pinch_gesture_events_writer(tick)
}

///|
pub impl @core.Message for RotationGesture with reader(ticks) {
  rotation_gesture_events_reader(ticks)
}

///|
pub impl @core.Message for RotationGesture with writer(tick) {
  rotation_gesture_events_writer(tick)
}

///|
pub impl @core.Message for DoubleTapGesture with reader(ticks) {
  double_tap_gesture_events_reader(ticks)
}

///|
pub impl @core.Message for DoubleTapGesture with writer(tick) {
  double_tap_gesture_events_writer(tick)
}

///|
pub impl @core.Message for TouchInput with reader(ticks) {
  touch_input_events_reader(ticks)
}

///|
pub impl @core.Message for TouchInput with writer(tick) {
  touch_input_events_writer(tick)
}

///|
pub impl @core.Message for FileDragAndDrop with reader(ticks) {
  file_drag_and_drop_events_reader(ticks)
}

///|
pub impl @core.Message for FileDragAndDrop with writer(tick) {
  file_drag_and_drop_events_writer(tick)
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
  key_to_string(self)
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
pub impl[T : ButtonInputSnapshotProvider] @app.SystemParam for ButtonInput[T] with get() {
  ButtonInputSnapshotProvider::read_button_input()
}

///|
pub impl @app.Resource for AccumulatedMouseMotion with resource() {
  accumulated_mouse_motion_resource_ref.val
}

///|
pub impl @app.Resource for AccumulatedMouseScroll with resource() {
  accumulated_mouse_scroll_resource_ref.val
}

///|
pub impl @app.Resource for Touches with resource() {
  touches_resource_ref.val
}

///|
pub fn[W : @core.ChangeTickWorld] input_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_pre_update_system(input_poll_keyboard_system)
  .add_pre_update_system(input_poll_drag_and_drop_system)
  .add_pre_update_system(input_poll_mouse_system)
  .add_pre_update_system(input_poll_gamepad_system)
  .add_post_update_system(input_finish_system)
}
