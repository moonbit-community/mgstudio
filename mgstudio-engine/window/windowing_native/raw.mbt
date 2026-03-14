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
const KEY_COUNT : Int = 64

///|
const MOUSE_BUTTON_COUNT : Int = 3

///|
const MAX_TEXT_EVENTS : Int = 256

///|
const MAX_IME_EVENTS : Int = 256

///|
const MAX_KEYBOARD_EVENTS : Int = 512

///|
const MAX_DRAG_EVENTS : Int = 64

///|
const MAX_WINDOW_THEME_EVENTS : Int = 64

///|
const MAX_WINDOW_OCCLUDED_EVENTS : Int = 64

///|
const MAX_APP_LIFECYCLE_EVENTS : Int = 16

///|
const MAX_PINCH_GESTURE_EVENTS : Int = 64

///|
const MAX_ROTATION_GESTURE_EVENTS : Int = 64

///|
const MAX_PAN_GESTURE_EVENTS : Int = 64

///|
const MAX_DOUBLE_TAP_GESTURE_EVENTS : Int = 64

///|
const MAX_RAW_WINIT_WINDOW_EVENTS : Int = 1024

///|
const ELEMENT_STATE_PRESSED : Int = 1

///|
const ELEMENT_STATE_RELEASED : Int = 2

///|
const IME_EVENT_ENABLED : Int = 1

///|
const IME_EVENT_PREEDIT : Int = 2

///|
const IME_EVENT_COMMIT : Int = 3

///|
const IME_EVENT_DISABLED : Int = 4

///|
const IME_EVENT_DELETE_SURROUNDING : Int = 5

///|
const WINDOW_THEME_LIGHT : Int = 1

///|
const WINDOW_THEME_DARK : Int = 2

///|
const APP_LIFECYCLE_IDLE : Int = 0

///|
const APP_LIFECYCLE_RUNNING : Int = 1

///|
const APP_LIFECYCLE_WILL_SUSPEND : Int = 2

///|
const APP_LIFECYCLE_SUSPENDED : Int = 3

///|
const APP_LIFECYCLE_WILL_RESUME : Int = 4

///|
const DEFAULT_FRAME_LIMIT : Int = 0

///|
pub type NativeWindowHandle = Int

///|
priv struct DragEvent {
  window : Int
  kind : Int
  text : Bytes
}

///|
priv struct KeyboardEvent {
  key_id : Int
  state : Int
  repeat : Bool
  text : Bytes
}

///|
priv struct ImeEvent {
  window : Int
  kind : Int
  text : Bytes
  cursor_start : Int
  cursor_end : Int
}

///|
priv struct WindowThemeEvent {
  window : Int
  theme : Int
}

///|
priv struct WindowOccludedEvent {
  window : Int
  occluded : Bool
}

///|
priv struct ScalarGestureEvent {
  window : Int
  delta : Float
}

///|
priv struct PanGestureEvent {
  window : Int
  x : Float
  y : Float
}

///|
priv struct DoubleTapGestureEvent {
  window : Int
}

///|
pub(all) enum RawWinitWindowEventData {
  ActivationTokenDone(
    @window_core.AsyncRequestSerial,
    @window_core.ActivationToken
  )
  CloseRequested
  CursorEntered(@window_core.DeviceId?)
  CursorLeft(@window_core.DeviceId?)
  CursorMoved(@window_core.DeviceId?, @window_dpi.PhysicalPositionF64)
  Destroyed
  DoubleTapGesture(@window_core.DeviceId?)
  DroppedFile(String)
  Focused(Bool)
  HoveredFile(String)
  HoveredFileCancelled
  Ime(@window_core.Ime)
  KeyboardInput(@window_core.DeviceId?, @window_core.KeyEvent, Bool)
  ModifiersChanged(@window_core.Modifiers)
  MouseInput(
    @window_core.DeviceId?,
    @window_core.ElementState,
    @window_core.MouseButton
  )
  MouseWheel(
    @window_core.DeviceId?,
    @window_core.MouseScrollDelta,
    @window_core.TouchPhase
  )
  Moved(@window_dpi.PhysicalPosition)
  Occluded(Bool)
  PanGesture(
    @window_core.DeviceId?,
    @window_dpi.PhysicalPositionF64,
    @window_core.TouchPhase
  )
  PinchGesture(@window_core.DeviceId?, Double, @window_core.TouchPhase)
  RedrawRequested
  Resized(@window_dpi.PhysicalSize)
  RotationGesture(@window_core.DeviceId?, Double, @window_core.TouchPhase)
  ScaleFactorChanged(Double, @window_dpi.PhysicalSize)
  ThemeChanged(@window_core.Theme)
  TouchpadPressure(@window_core.DeviceId?, Double, Int)
} derive(Eq, Show)

///|
pub(all) struct RawWinitWindowEventSnapshot {
  window_id : Int
  event : RawWinitWindowEventData
} derive(Eq, Show)

///|
fn new_bool_state(size : Int) -> Array[Bool] {
  let state = []
  for _ in 0..<size {
    state.push(false)
  }
  state
}

///|
fn parse_non_negative_int(input : String) -> Int? {
  if input.length() == 0 {
    return None
  }
  let mut value = 0
  for c in input {
    let code = c.to_int()
    if code < 48 || code > 57 {
      return None
    }
    value = value * 10 + (code - 48)
  }
  Some(value)
}

///|
fn run_loop_frame_limit() -> Int {
  if @sys.get_env_var("MGSTUDIO_WINDOW_FRAME_LIMIT") is Some(value) {
    if parse_non_negative_int(value) is Some(parsed) {
      parsed
    } else {
      DEFAULT_FRAME_LIMIT
    }
  } else {
    DEFAULT_FRAME_LIMIT
  }
}

///|
fn encode_utf8_bytes(value : String) -> Bytes {
  @utf8.encode(value[:])
}

///|
fn decode_utf8_lossy(value : Bytes) -> String {
  @utf8.decode_lossy(value[:], ignore_bom=true)
}

///|
fn bool_state_get(state : Array[Bool], index : Int) -> Bool {
  if index < 0 || index >= state.length() {
    false
  } else {
    state[index]
  }
}

///|
fn bool_state_set(state : Array[Bool], index : Int, value : Bool) -> Unit {
  if index < 0 || index >= state.length() {
    return
  }
  state[index] = value
}

///|
fn clear_bool_state(state : Array[Bool]) -> Unit {
  for i in 0..<state.length() {
    state[i] = false
  }
}

///|
fn contains_int(items : Array[Int], value : Int) -> Bool {
  for item in items {
    if item == value {
      return true
    }
  }
  false
}

///|
let open_window_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let closed_window_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
let key_down_ref : Ref[Array[Bool]] = Ref::new(new_bool_state(KEY_COUNT))

///|
let key_just_pressed_ref : Ref[Array[Bool]] = Ref::new(
  new_bool_state(KEY_COUNT),
)

///|
let key_just_released_ref : Ref[Array[Bool]] = Ref::new(
  new_bool_state(KEY_COUNT),
)

///|
let key_repeated_ref : Ref[Array[Bool]] = Ref::new(new_bool_state(KEY_COUNT))

///|
let mouse_down_ref : Ref[Array[Bool]] = Ref::new(
  new_bool_state(MOUSE_BUTTON_COUNT),
)

///|
let mouse_just_pressed_ref : Ref[Array[Bool]] = Ref::new(
  new_bool_state(MOUSE_BUTTON_COUNT),
)

///|
let mouse_just_released_ref : Ref[Array[Bool]] = Ref::new(
  new_bool_state(MOUSE_BUTTON_COUNT),
)

///|
let has_cursor_ref : Ref[Bool] = Ref::new(false)

///|
let cursor_window_ref : Ref[Int] = Ref::new(-1)

///|
let cursor_entered_window_ref : Ref[Int] = Ref::new(-1)

///|
let cursor_left_window_ref : Ref[Int] = Ref::new(-1)

///|
let mouse_x_ref : Ref[Float] = Ref::new(0.0)

///|
let mouse_y_ref : Ref[Float] = Ref::new(0.0)

///|
let wheel_x_ref : Ref[Float] = Ref::new(0.0)

///|
let wheel_y_ref : Ref[Float] = Ref::new(0.0)

///|
let text_events_ref : Ref[Array[Bytes]] = Ref::new([])

///|
let keyboard_events_ref : Ref[Array[KeyboardEvent]] = Ref::new([])

///|
let ime_events_ref : Ref[Array[ImeEvent]] = Ref::new([])

///|
let drag_events_ref : Ref[Array[DragEvent]] = Ref::new([])

///|
let drag_hovered_path_ref : Ref[Bytes?] = Ref::new(None)

///|
let drag_hovered_window_ref : Ref[Int] = Ref::new(-1)

///|
let window_theme_events_ref : Ref[Array[WindowThemeEvent]] = Ref::new([])

///|
let window_occluded_events_ref : Ref[Array[WindowOccludedEvent]] = Ref::new([])

///|
let app_lifecycle_events_ref : Ref[Array[Int]] = Ref::new([])

///|
let pinch_gesture_events_ref : Ref[Array[ScalarGestureEvent]] = Ref::new([])

///|
let rotation_gesture_events_ref : Ref[Array[ScalarGestureEvent]] = Ref::new([])

///|
let pan_gesture_events_ref : Ref[Array[PanGestureEvent]] = Ref::new([])

///|
let double_tap_gesture_events_ref : Ref[Array[DoubleTapGestureEvent]] = Ref::new([],
)

///|
let raw_winit_window_events_ref : Ref[Array[RawWinitWindowEventSnapshot]] = Ref::new([],
)

///|
let detached_accessibility_requested_ref : Ref[Bool] = Ref::new(false)

///|
let bound_accessibility_requested_ref : Ref[Ref[Bool]?] = Ref::new(None)

///|
let pending_update_payload_ref : Ref[String?] = Ref::new(None)

///|
let last_update_payload_ref : Ref[String] = Ref::new("")

///|
let pending_actions_ref : Ref[Array[@moon_accesskit.ActionRequest]] = Ref::new([])

///|
priv struct NativeWindowEntry {
  id : Int
  window_ref : Ref[@window_macos.Window]
}

///|
priv struct NativePumpHandler {}

///|
let native_event_loop_ref : Ref[@window_macos.EventLoop?] = Ref::new(None)

///|
let native_pump_handler_ref : Ref[NativePumpHandler] = Ref::new(NativePumpHandler::{

})

///|
let native_windows_ref : Ref[Array[NativeWindowEntry]] = Ref::new([])

///|
fn remove_int(items : Array[Int], value : Int) -> Unit {
  for i, item in items {
    if item == value {
      items.remove(i) |> ignore
      return
    }
  }
}

///|
fn mark_window_open(window : Int) -> Unit {
  remove_int(closed_window_ids_ref.val, window)
  if !contains_int(open_window_ids_ref.val, window) {
    open_window_ids_ref.val.push(window)
  }
}

///|
fn mark_window_closed(window : Int) -> Unit {
  if !contains_int(closed_window_ids_ref.val, window) {
    closed_window_ids_ref.val.push(window)
  }
}

///|
fn is_window_closed(window : Int) -> Bool {
  contains_int(closed_window_ids_ref.val, window)
}

///|
pub fn any_window_open() -> Bool {
  for window in open_window_ids_ref.val {
    if !is_window_closed(window) {
      return true
    }
  }
  false
}

///|
fn requested_ref() -> Ref[Bool] {
  match bound_accessibility_requested_ref.val {
    Some(requested) => requested
    None => detached_accessibility_requested_ref
  }
}

///|
pub fn bind_accessibility_requested(requested : Ref[Bool]) -> Unit {
  bound_accessibility_requested_ref.val = Some(requested)
  requested.val = detached_accessibility_requested_ref.val
}

///|
pub fn accessibility_requested() -> Bool {
  requested_ref().val
}

///|
pub fn set_accessibility_requested(requested : Bool) -> Unit {
  requested_ref().val = requested
  detached_accessibility_requested_ref.val = requested
}

///|
pub fn queue_accessibility_update(update : @moon_accesskit.TreeUpdate) -> Unit {
  queue_accessibility_update_payload(payload=update.to_json().stringify())
}

///|
pub fn queue_accessibility_update_payload(payload~ : String) -> Unit {
  pending_update_payload_ref.val = Some(payload)
}

///|
pub fn commit_pending_accessibility_update() -> Bool {
  guard accessibility_requested() else { return false }
  match pending_update_payload_ref.val {
    Some(payload) => {
      last_update_payload_ref.val = payload
      pending_update_payload_ref.val = None
      true
    }
    None => false
  }
}

///|
pub fn last_accessibility_update_payload() -> String {
  last_update_payload_ref.val
}

///|
pub fn enqueue_accessibility_action(
  action : @moon_accesskit.ActionRequest,
) -> Unit {
  pending_actions_ref.val.push(action)
  set_accessibility_requested(true)
}

///|
pub fn take_accessibility_actions() -> Array[@moon_accesskit.ActionRequest] {
  let actions = pending_actions_ref.val
  pending_actions_ref.val = []
  actions
}

///|
pub fn take_raw_winit_window_events() -> Array[RawWinitWindowEventSnapshot] {
  let events = raw_winit_window_events_ref.val
  raw_winit_window_events_ref.val = []
  events
}

///|
fn bytes_has_non_control(text : Bytes) -> Bool {
  for i in 0..<text.length() {
    if text[i].to_int() >= 32 {
      return true
    }
  }
  false
}

///|
fn push_text_event(text : Bytes) -> Unit {
  if text.length() == 0 {
    return
  }
  if !bytes_has_non_control(text) {
    return
  }
  if text_events_ref.val.length() >= MAX_TEXT_EVENTS {
    return
  }
  text_events_ref.val.push(text)
}

///|
fn push_drag_event(window : Int, kind : Int, text : Bytes) -> Unit {
  if drag_events_ref.val.length() >= MAX_DRAG_EVENTS {
    return
  }
  drag_events_ref.val.push(DragEvent::{ window, kind, text })
}

///|
fn push_window_theme_event(window : Int, theme : @window_core.Theme) -> Unit {
  if window_theme_events_ref.val.length() >= MAX_WINDOW_THEME_EVENTS {
    return
  }
  let encoded_theme = match theme {
    @window_core.Theme::Light => WINDOW_THEME_LIGHT
    @window_core.Theme::Dark => WINDOW_THEME_DARK
  }
  window_theme_events_ref.val.push(WindowThemeEvent::{
    window,
    theme: encoded_theme,
  })
}

///|
fn push_window_occluded_event(window : Int, occluded : Bool) -> Unit {
  if window_occluded_events_ref.val.length() >= MAX_WINDOW_OCCLUDED_EVENTS {
    return
  }
  window_occluded_events_ref.val.push(WindowOccludedEvent::{ window, occluded })
}

///|
fn push_app_lifecycle_event(kind : Int) -> Unit {
  if kind != APP_LIFECYCLE_IDLE &&
    kind != APP_LIFECYCLE_RUNNING &&
    kind != APP_LIFECYCLE_WILL_SUSPEND &&
    kind != APP_LIFECYCLE_SUSPENDED &&
    kind != APP_LIFECYCLE_WILL_RESUME {
    return
  }
  if app_lifecycle_events_ref.val.length() >= MAX_APP_LIFECYCLE_EVENTS {
    return
  }
  app_lifecycle_events_ref.val.push(kind)
}

///|
fn push_pinch_gesture_event(window : Int, delta : Float) -> Unit {
  if pinch_gesture_events_ref.val.length() >= MAX_PINCH_GESTURE_EVENTS {
    return
  }
  pinch_gesture_events_ref.val.push(ScalarGestureEvent::{ window, delta })
}

///|
fn push_rotation_gesture_event(window : Int, delta : Float) -> Unit {
  if rotation_gesture_events_ref.val.length() >= MAX_ROTATION_GESTURE_EVENTS {
    return
  }
  rotation_gesture_events_ref.val.push(ScalarGestureEvent::{ window, delta })
}

///|
fn push_pan_gesture_event(window : Int, x : Float, y : Float) -> Unit {
  if pan_gesture_events_ref.val.length() >= MAX_PAN_GESTURE_EVENTS {
    return
  }
  pan_gesture_events_ref.val.push(PanGestureEvent::{ window, x, y })
}

///|
fn push_double_tap_gesture_event(window : Int) -> Unit {
  if double_tap_gesture_events_ref.val.length() >= MAX_DOUBLE_TAP_GESTURE_EVENTS {
    return
  }
  double_tap_gesture_events_ref.val.push(DoubleTapGestureEvent::{ window, })
}

///|
fn raw_winit_window_event_data_from_winit_event(
  event : @window_core.WinitWindowEvent,
) -> RawWinitWindowEventData {
  match event {
    ActivationTokenDone(serial, token) => ActivationTokenDone(serial, token)
    CloseRequested => CloseRequested
    CursorEntered(device_id) => CursorEntered(device_id)
    CursorLeft(device_id) => CursorLeft(device_id)
    CursorMoved(device_id, position) => CursorMoved(device_id, position)
    Destroyed => Destroyed
    DoubleTapGesture(device_id) => DoubleTapGesture(device_id)
    DroppedFile(path) => DroppedFile(path)
    Focused(focused) => Focused(focused)
    HoveredFile(path) => HoveredFile(path)
    HoveredFileCancelled => HoveredFileCancelled
    Ime(ime_event) => Ime(ime_event)
    KeyboardInput(device_id, key_event, is_synthetic) =>
      KeyboardInput(device_id, key_event, is_synthetic)
    ModifiersChanged(modifiers) => ModifiersChanged(modifiers)
    MouseInput(device_id, state, button) => MouseInput(device_id, state, button)
    MouseWheel(device_id, delta, phase) => MouseWheel(device_id, delta, phase)
    Moved(position) => Moved(position)
    Occluded(occluded) => Occluded(occluded)
    PanGesture(device_id, delta, phase) => PanGesture(device_id, delta, phase)
    PinchGesture(device_id, delta, phase) =>
      PinchGesture(device_id, delta, phase)
    RedrawRequested => RedrawRequested
    Resized(size) => Resized(size)
    RotationGesture(device_id, delta, phase) =>
      RotationGesture(device_id, delta, phase)
    ScaleFactorChanged(scale_factor, writer) =>
      ScaleFactorChanged(scale_factor, writer.surface_size())
    ThemeChanged(theme) => ThemeChanged(theme)
    TouchpadPressure(device_id, pressure, stage) =>
      TouchpadPressure(device_id, pressure, stage)
  }
}

///|
fn push_raw_winit_window_events(
  window_id : Int,
  events : Array[@window_core.WinitWindowEvent],
) -> Unit {
  for event in events {
    if raw_winit_window_events_ref.val.length() >= MAX_RAW_WINIT_WINDOW_EVENTS {
      return
    }
    raw_winit_window_events_ref.val.push(RawWinitWindowEventSnapshot::{
      window_id,
      event: raw_winit_window_event_data_from_winit_event(event),
    })
  }
}

///|
fn push_ime_event(
  window : Int,
  kind : Int,
  text : Bytes,
  cursor_start : Int,
  cursor_end : Int,
) -> Unit {
  if kind != IME_EVENT_ENABLED &&
    kind != IME_EVENT_PREEDIT &&
    kind != IME_EVENT_COMMIT &&
    kind != IME_EVENT_DISABLED &&
    kind != IME_EVENT_DELETE_SURROUNDING {
    return
  }
  if ime_events_ref.val.length() >= MAX_IME_EVENTS {
    return
  }
  ime_events_ref.val.push(ImeEvent::{
    window,
    kind,
    text,
    cursor_start,
    cursor_end,
  })
}

///|
fn push_keyboard_event(
  key_id : Int,
  state : Int,
  repeat : Bool,
  text : Bytes,
) -> Unit {
  if state != ELEMENT_STATE_PRESSED && state != ELEMENT_STATE_RELEASED {
    return
  }
  if keyboard_events_ref.val.length() >= MAX_KEYBOARD_EVENTS {
    return
  }
  keyboard_events_ref.val.push(KeyboardEvent::{ key_id, state, repeat, text })
}

///|
fn key_id_from_key_code(key_code : @window_core.KeyCode) -> Int {
  match key_code {
    KeyA => 0
    KeyB => 1
    KeyC => 2
    KeyD => 3
    KeyE => 4
    KeyF => 5
    KeyG => 6
    KeyH => 7
    KeyI => 8
    KeyJ => 9
    KeyK => 10
    KeyL => 11
    KeyM => 12
    KeyN => 13
    KeyO => 14
    KeyP => 15
    KeyQ => 16
    KeyR => 17
    KeyS => 18
    KeyT => 19
    KeyU => 20
    KeyV => 21
    KeyW => 22
    KeyX => 23
    KeyY => 24
    KeyZ => 25
    Digit1 => 26
    Digit2 => 27
    Digit3 => 28
    Digit4 => 29
    Digit5 => 30
    Digit6 => 31
    Digit7 => 32
    Digit8 => 33
    Tab => 34
    Enter => 35
    Backspace => 36
    ShiftLeft => 37
    ShiftRight => 38
    ControlLeft => 39
    ControlRight => 40
    ArrowUp => 41
    ArrowDown => 42
    ArrowLeft => 43
    ArrowRight => 44
    PageUp => 45
    PageDown => 46
    Space => 47
    Escape => 48
    Semicolon => 49
    Comma => 50
    Period => 51
    Slash => 52
    Minus => 53
    Equal => 54
    NumpadAdd => 55
    NumpadSubtract => 56
    BracketLeft => 57
    BracketRight => 58
    Quote => 59
    _ => -1
  }
}

///|
fn key_id_from_physical_key(physical_key : @window_core.PhysicalKey) -> Int {
  match physical_key {
    Code(key_code) => key_id_from_key_code(key_code)
    Unidentified(_) => -1
  }
}

///|
fn key_code_from_name(code : String) -> @window_core.KeyCode? {
  match code {
    "KeyA" => Some(KeyA)
    "KeyB" => Some(KeyB)
    "KeyC" => Some(KeyC)
    "KeyD" => Some(KeyD)
    "KeyE" => Some(KeyE)
    "KeyF" => Some(KeyF)
    "KeyG" => Some(KeyG)
    "KeyH" => Some(KeyH)
    "KeyI" => Some(KeyI)
    "KeyJ" => Some(KeyJ)
    "KeyK" => Some(KeyK)
    "KeyL" => Some(KeyL)
    "KeyM" => Some(KeyM)
    "KeyN" => Some(KeyN)
    "KeyO" => Some(KeyO)
    "KeyP" => Some(KeyP)
    "KeyQ" => Some(KeyQ)
    "KeyR" => Some(KeyR)
    "KeyS" => Some(KeyS)
    "KeyT" => Some(KeyT)
    "KeyU" => Some(KeyU)
    "KeyV" => Some(KeyV)
    "KeyW" => Some(KeyW)
    "KeyX" => Some(KeyX)
    "KeyY" => Some(KeyY)
    "KeyZ" => Some(KeyZ)
    "Digit1" => Some(Digit1)
    "Digit2" => Some(Digit2)
    "Digit3" => Some(Digit3)
    "Digit4" => Some(Digit4)
    "Digit5" => Some(Digit5)
    "Digit6" => Some(Digit6)
    "Digit7" => Some(Digit7)
    "Digit8" => Some(Digit8)
    "Tab" => Some(Tab)
    "Enter" => Some(Enter)
    "Backspace" => Some(Backspace)
    "ShiftLeft" => Some(ShiftLeft)
    "ShiftRight" => Some(ShiftRight)
    "ControlLeft" => Some(ControlLeft)
    "ControlRight" => Some(ControlRight)
    "ArrowUp" => Some(ArrowUp)
    "ArrowDown" => Some(ArrowDown)
    "ArrowLeft" => Some(ArrowLeft)
    "ArrowRight" => Some(ArrowRight)
    "PageUp" => Some(PageUp)
    "PageDown" => Some(PageDown)
    "Space" => Some(Space)
    "Escape" => Some(Escape)
    "Semicolon" => Some(Semicolon)
    "Comma" => Some(Comma)
    "Period" => Some(Period)
    "Slash" => Some(Slash)
    "Minus" => Some(Minus)
    "Equal" => Some(Equal)
    "NumpadAdd" => Some(NumpadAdd)
    "NumpadSubtract" => Some(NumpadSubtract)
    "BracketLeft" => Some(BracketLeft)
    "BracketRight" => Some(BracketRight)
    "Quote" => Some(Quote)
    _ => None
  }
}

///|
fn mouse_button_id_from_button(button : @window_core.MouseButton) -> Int {
  match button {
    Left => 0
    Right => 1
    Middle => 2
    _ => -1
  }
}

///|
fn element_state_to_int(state : @window_core.ElementState) -> Int {
  match state {
    Pressed => ELEMENT_STATE_PRESSED
    Released => ELEMENT_STATE_RELEASED
  }
}

///|
fn ensure_native_event_loop() -> @window_macos.EventLoop {
  match native_event_loop_ref.val {
    Some(event_loop) => event_loop
    None => {
      let event_loop = @window_macos.EventLoop::new()
      event_loop.set_control_flow(@window_core.ControlFlow::Poll)
      native_event_loop_ref.val = Some(event_loop)
      event_loop
    }
  }
}

///|
fn native_window_ref(window : Int) -> Ref[@window_macos.Window]? {
  for entry in native_windows_ref.val {
    if entry.id == window {
      return Some(entry.window_ref)
    }
  }
  None
}

///|
fn native_window_remove(window : Int) -> Unit {
  for i, entry in native_windows_ref.val {
    if entry.id == window {
      native_windows_ref.val.remove(i) |> ignore
      return
    }
  }
}

///|
fn set_pointer_position(position : @window_dpi.PhysicalPositionF64) -> Unit {
  mouse_x_ref.val = Float::from_double(position.x())
  mouse_y_ref.val = Float::from_double(position.y())
}

///|
fn process_pointer_button(
  state : @window_core.ElementState,
  source : @window_core.ButtonSource,
) -> Unit {
  let button = match source.mouse_button() {
    Some(mouse_button) => mouse_button_id_from_button(mouse_button)
    None => -1
  }
  if button < 0 || button >= MOUSE_BUTTON_COUNT {
    return
  }
  let state_value = element_state_to_int(state)
  if state_value == ELEMENT_STATE_PRESSED {
    if !bool_state_get(mouse_down_ref.val, button) {
      bool_state_set(mouse_just_pressed_ref.val, button, true)
    }
    bool_state_set(mouse_down_ref.val, button, true)
  } else if state_value == ELEMENT_STATE_RELEASED {
    if bool_state_get(mouse_down_ref.val, button) {
      bool_state_set(mouse_just_released_ref.val, button, true)
    }
    bool_state_set(mouse_down_ref.val, button, false)
  }
}

///|
fn process_keyboard_input(key_event : @window_core.KeyEvent) -> Unit {
  let key_id = key_id_from_physical_key(key_event.physical_key())
  if key_id < 0 {
    return
  }
  let state = element_state_to_int(key_event.state())
  if state == ELEMENT_STATE_PRESSED {
    let repeated = key_event.repeat()
    let text = match key_event.text_with_all_modifiers() {
      Some(value) => encode_utf8_bytes(value)
      None => Bytes::from_array([])
    }
    if repeated {
      bool_state_set(key_repeated_ref.val, key_id, true)
    }
    if !bool_state_get(key_down_ref.val, key_id) {
      bool_state_set(key_just_pressed_ref.val, key_id, true)
    }
    bool_state_set(key_down_ref.val, key_id, true)
    push_text_event(text)
    push_keyboard_event(key_id, state, repeated, text)
  } else if state == ELEMENT_STATE_RELEASED {
    if bool_state_get(key_down_ref.val, key_id) {
      bool_state_set(key_just_released_ref.val, key_id, true)
    }
    bool_state_set(key_down_ref.val, key_id, false)
    push_keyboard_event(key_id, state, false, Bytes::from_array([]))
  }
}

///|
fn process_ime_event(window : Int, ime_event : @window_core.Ime) -> Unit {
  match ime_event {
    Enabled =>
      push_ime_event(window, IME_EVENT_ENABLED, Bytes::from_array([]), 0, 0)
    Preedit(text, cursor_range) => {
      let mut cursor_start = -1
      let mut cursor_end = -1
      match cursor_range {
        Some(range) => {
          cursor_start = range.start()
          cursor_end = range.end()
        }
        None => ()
      }
      push_ime_event(
        window,
        IME_EVENT_PREEDIT,
        encode_utf8_bytes(text),
        cursor_start,
        cursor_end,
      )
    }
    Commit(text) => {
      let text_bytes = encode_utf8_bytes(text)
      push_ime_event(window, IME_EVENT_COMMIT, text_bytes, 0, 0)
      push_text_event(text_bytes)
    }
    DeleteSurrounding(before_bytes, after_bytes) =>
      push_ime_event(
        window,
        IME_EVENT_DELETE_SURROUNDING,
        Bytes::from_array([]),
        before_bytes,
        after_bytes,
      )
    Disabled =>
      push_ime_event(window, IME_EVENT_DISABLED, Bytes::from_array([]), 0, 0)
  }
}

///|
fn process_drag_entered(window : Int, paths : Array[String]) -> Unit {
  drag_hovered_path_ref.val = None
  drag_hovered_window_ref.val = window
  for path in paths {
    let path_bytes = encode_utf8_bytes(path)
    if drag_hovered_path_ref.val is None {
      drag_hovered_path_ref.val = Some(path_bytes)
    }
    push_drag_event(window, 1, path_bytes)
  }
}

///|
fn process_drag_moved(window : Int) -> Unit {
  drag_hovered_window_ref.val = window
  match drag_hovered_path_ref.val {
    Some(path) => push_drag_event(window, 1, path)
    None => ()
  }
}

///|
fn process_drag_dropped(window : Int, paths : Array[String]) -> Unit {
  let hovered_window = if drag_hovered_window_ref.val >= 0 {
    drag_hovered_window_ref.val
  } else {
    window
  }
  if paths.length() > 0 {
    for path in paths {
      push_drag_event(window, 0, encode_utf8_bytes(path))
    }
  } else {
    match drag_hovered_path_ref.val {
      Some(path) => push_drag_event(hovered_window, 0, path)
      None => ()
    }
  }
  drag_hovered_path_ref.val = None
  drag_hovered_window_ref.val = -1
}

///|
fn process_drag_left(window : Int) -> Unit {
  let path = match drag_hovered_path_ref.val {
    Some(value) => value
    None => Bytes::from_array([])
  }
  let hovered_window = if drag_hovered_window_ref.val >= 0 {
    drag_hovered_window_ref.val
  } else {
    window
  }
  drag_hovered_path_ref.val = None
  drag_hovered_window_ref.val = -1
  push_drag_event(hovered_window, 2, path)
}

///|
fn process_window_event(window : Int, event : @window_core.WindowEvent) -> Unit {
  push_raw_winit_window_events(window, event.into_winit_events())
  match event {
    CloseRequested => mark_window_closed(window)
    Destroyed => mark_window_closed(window)
    PointerMoved(_, position, _is_primary, _source) => {
      has_cursor_ref.val = true
      cursor_window_ref.val = window
      set_pointer_position(position)
    }
    PointerEntered(_, position, _is_primary, _kind) => {
      has_cursor_ref.val = true
      cursor_window_ref.val = window
      cursor_entered_window_ref.val = window
      set_pointer_position(position)
    }
    PointerLeft(_, position, _is_primary, _kind) => {
      has_cursor_ref.val = false
      cursor_left_window_ref.val = window
      if cursor_window_ref.val == window {
        cursor_window_ref.val = -1
      }
      match position {
        Some(value) => set_pointer_position(value)
        None => ()
      }
    }
    PointerButton(_, state, position, _is_primary, source) => {
      has_cursor_ref.val = true
      cursor_window_ref.val = window
      set_pointer_position(position)
      process_pointer_button(state, source)
    }
    MouseWheel(_, delta, _phase) =>
      match delta {
        LineDelta(delta_x, delta_y) => {
          wheel_x_ref.val = wheel_x_ref.val + Float::from_double(delta_x)
          wheel_y_ref.val = wheel_y_ref.val + Float::from_double(delta_y)
        }
        PixelDelta(position) => {
          wheel_x_ref.val = wheel_x_ref.val + Float::from_double(position.x())
          wheel_y_ref.val = wheel_y_ref.val + Float::from_double(position.y())
        }
      }
    PinchGesture(_device_id, delta, _phase) =>
      push_pinch_gesture_event(window, Float::from_double(delta))
    RotationGesture(_device_id, delta, _phase) =>
      push_rotation_gesture_event(window, Float::from_double(delta))
    PanGesture(_device_id, delta, _phase) =>
      push_pan_gesture_event(
        window,
        Float::from_double(delta.x()),
        Float::from_double(delta.y()),
      )
    DoubleTapGesture(_device_id) => push_double_tap_gesture_event(window)
    KeyboardInput(_device_id, key_event, _is_synthetic) =>
      process_keyboard_input(key_event)
    Ime(ime_event) => process_ime_event(window, ime_event)
    DragEntered(paths, _position) => process_drag_entered(window, paths)
    DragMoved(_position) => process_drag_moved(window)
    DragDropped(paths, _position) => process_drag_dropped(window, paths)
    DragLeft(_position) => process_drag_left(window)
    ThemeChanged(theme) => push_window_theme_event(window, theme)
    Occluded(occluded) => push_window_occluded_event(window, occluded)
    _ => ()
  }
}

///|
impl @window_macos.ApplicationHandler for NativePumpHandler with window_event(
  _self,
  _event_loop,
  window_id,
  event,
) {
  process_window_event(window_id.into_raw(), event)
}

///|
impl @window_macos.ApplicationHandler for NativePumpHandler with resumed(
  _self,
  _event_loop,
) {
  push_app_lifecycle_event(APP_LIFECYCLE_WILL_RESUME)
  push_app_lifecycle_event(APP_LIFECYCLE_RUNNING)
}

///|
impl @window_macos.ApplicationHandler for NativePumpHandler with suspended(
  _self,
  _event_loop,
) {
  push_app_lifecycle_event(APP_LIFECYCLE_WILL_SUSPEND)
  push_app_lifecycle_event(APP_LIFECYCLE_SUSPENDED)
}

///|
fn pump_native_events() -> Unit {
  match native_event_loop_ref.val {
    Some(event_loop) =>
      event_loop.pump_app_events(Some(0), native_pump_handler_ref.val) |> ignore
    None => ()
  }
}

///|
pub fn create_utf8(
  logical_width : Int,
  logical_height : Int,
  physical_width : Int,
  physical_height : Int,
  use_physical_size_on_create : Bool,
  title : Bytes,
  _title_len : UInt64,
  visible : Bool,
  resizable : Bool,
  decorations : Bool,
  panel : Bool,
) -> Int {
  let event_loop = ensure_native_event_loop()
  let mut attributes = @window_core.WindowAttributes::default()
    .with_title(decode_utf8_lossy(title))
    .with_visible(visible)
    .with_active(true)
    .with_resizable(resizable)
    .with_decorations(decorations)
    .with_platform_attributes(
      @window_core.PlatformWindowAttributes::default().with_panel(panel),
    )
  if use_physical_size_on_create {
    let width = if physical_width > 0 { physical_width } else { logical_width }
    let height = if physical_height > 0 {
      physical_height
    } else {
      logical_height
    }
    attributes = attributes.with_surface_size(
      @window_dpi.PhysicalSize::new(width, height).into_size(),
    )
  } else {
    attributes = attributes.with_inner_size(
      @window_dpi.LogicalSize::new(
        logical_width.to_double(),
        logical_height.to_double(),
      ).into_size(),
    )
  }
  let native_window = event_loop.create_window(attributes)
  let window = native_window.id().into_raw()
  native_windows_ref.val.push(NativeWindowEntry::{
    id: window,
    window_ref: Ref::new(native_window),
  })
  mark_window_open(window)
  window
}

///|
pub fn create(
  logical_width~ : Int,
  logical_height~ : Int,
  physical_width~ : Int,
  physical_height~ : Int,
  use_physical_size_on_create~ : Bool,
  title~ : String,
  visible~ : Bool,
  resizable~ : Bool,
  decorations~ : Bool,
  panel~ : Bool,
) -> NativeWindowHandle {
  let title_bytes = encode_utf8_bytes(title)
  create_utf8(
    logical_width,
    logical_height,
    physical_width,
    physical_height,
    use_physical_size_on_create,
    title_bytes,
    title_bytes.length().to_uint64(),
    visible,
    resizable,
    decorations,
    panel,
  )
}

///|
pub fn poll_events(_window : Int) -> Unit {
  pump_native_events()
}

///|
pub fn width(window : Int) -> Int {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.surface_size().width()
    None => 0
  }
}

///|
pub fn height(window : Int) -> Int {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.surface_size().height()
    None => 0
  }
}

///|
pub fn scale_factor(window : Int) -> Float {
  match native_window_ref(window) {
    Some(window_ref) => Float::from_double(window_ref.val.scale_factor())
    None => 1.0
  }
}

///|
pub fn focused(window : Int) -> Bool {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.has_focus()
    None => false
  }
}

///|
pub fn should_close(window : Int) -> Bool {
  if is_window_closed(window) {
    return true
  }
  native_window_ref(window) is None &&
  contains_int(open_window_ids_ref.val, window)
}

///|
pub fn request_close(window : Int) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.drop()
    None => ()
  }
  native_window_remove(window)
  mark_window_closed(window)
}

///|
pub fn run_loop(step : FuncRef[() -> Unit]) -> Unit {
  if !any_window_open() {
    step()
    return
  }
  let frame_limit = run_loop_frame_limit()
  let mut frames = 0
  while any_window_open() {
    step()
    if frame_limit > 0 {
      frames = frames + 1
      if frames >= frame_limit {
        break
      }
    }
  }
}

///|
pub fn set_title_utf8(window : Int, title : Bytes, _title_len : UInt64) -> Unit {
  set_title(window, title=decode_utf8_lossy(title))
}

///|
pub fn set_title(window : Int, title~ : String) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_title(title)
    None => ()
  }
}

///|
pub fn set_size(window : Int, width~ : Int, height~ : Int) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) =>
      window_ref.val.request_surface_size(
        @window_dpi.PhysicalSize::new(width, height).into_size(),
      )
      |> ignore
    None => ()
  }
}

///|
pub fn set_resizable(window : Int, resizable~ : Bool) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_resizable(resizable)
    None => ()
  }
}

///|
pub fn set_visible(window : Int, visible~ : Bool) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_visible(visible)
    None => ()
  }
}

///|
pub fn set_decorations(window : Int, decorations~ : Bool) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_decorations(decorations)
    None => ()
  }
}

///|
pub fn set_transparent(window : Int, transparent~ : Bool) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_transparent(transparent)
    None => ()
  }
}

///|
pub fn set_enabled_buttons(
  window : Int,
  close~ : Bool,
  minimize~ : Bool,
  maximize~ : Bool,
) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) =>
      window_ref.val.set_enabled_buttons(
        @window_core.WindowButtons::all()
        .with_close(close)
        .with_minimize(minimize)
        .with_maximize(maximize),
      )
    None => ()
  }
}

///|
pub fn set_window_level(
  window : Int,
  level~ : @window_core.WindowLevel,
) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_window_level(level)
    None => ()
  }
}

///|
pub fn set_theme(window : Int, theme~ : @window_core.Theme?) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_theme(theme)
    None => ()
  }
}

///|
pub fn set_ime_allowed(window : Int, allowed~ : Bool) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_ime_allowed(allowed)
    None => ()
  }
}

///|
pub fn set_ime_cursor_area(
  window : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) =>
      window_ref.val.set_ime_cursor_area(
        @window_dpi.PhysicalPosition::new(x, y).into_position(),
        @window_dpi.PhysicalSize::new(width, height).into_size(),
      )
    None => ()
  }
}

///|
pub fn set_cursor_visible(window : Int, visible~ : Bool) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_cursor_visible(visible)
    None => ()
  }
}

///|
pub fn set_cursor_grab_mode(
  window : Int,
  mode~ : @window_core.CursorGrabMode,
) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_cursor_grab(mode) catch { _ => () }
    None => ()
  }
}

///|
pub fn set_cursor_icon(window : Int, icon~ : @window_core.CursorIcon) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) => window_ref.val.set_cursor_icon(icon)
    None => ()
  }
}

///|
pub fn set_mode(window : Int, mode~ : Int) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) =>
      if mode == 0 {
        window_ref.val.set_simple_fullscreen(false) |> ignore
        window_ref.val.set_fullscreen(None)
      } else if mode == 1 {
        window_ref.val.set_fullscreen(None)
        window_ref.val.set_simple_fullscreen(true) |> ignore
      } else if mode == 2 {
        window_ref.val.set_simple_fullscreen(false) |> ignore
        window_ref.val.set_fullscreen(
          Some(@window_core.Fullscreen::Borderless(None)),
        )
      }
    None => ()
  }
}

///|
pub fn set_position(window : Int, x~ : Int, y~ : Int) -> Unit {
  match native_window_ref(window) {
    Some(window_ref) =>
      window_ref.val.set_outer_position(
        @window_dpi.PhysicalPosition::new(x, y).into_position(),
      )
    None => ()
  }
}

///|
pub fn drag_window(window : Int) -> Bool {
  match native_window_ref(window) {
    Some(window_ref) =>
      try {
        window_ref.val.drag_window()
        true
      } catch {
        _ => false
      }
    None => false
  }
}

///|
pub fn drag_resize_window(
  window : Int,
  direction~ : @window_core.ResizeDirection,
) -> Bool {
  match native_window_ref(window) {
    Some(window_ref) =>
      try {
        window_ref.val.drag_resize_window(direction)
        true
      } catch {
        _ => false
      }
    None => false
  }
}

///|
pub fn position_x(window : Int) -> Int {
  match native_window_ref(window) {
    Some(window_ref) =>
      (window_ref.val.outer_position() catch {
        _ => @window_dpi.PhysicalPosition::new(0, 0)
      }).x()
    None => 0
  }
}

///|
pub fn position_y(window : Int) -> Int {
  match native_window_ref(window) {
    Some(window_ref) =>
      (window_ref.val.outer_position() catch {
        _ => @window_dpi.PhysicalPosition::new(0, 0)
      }).y()
    None => 0
  }
}

///|
pub fn attach_metal_layer(window : Int, layer : @wgpu_c.OpaquePtr) -> Unit {
  match native_window_ref(window) {
    Some(_window_ref) => host_window_attach_metal_layer(window, layer)
    None => ()
  }
}

///|
pub fn attach_surface_metal_layer(
  window : NativeWindowHandle,
  surface : @wgpu.Surface,
) -> Unit {
  attach_metal_layer(window, surface.metal_layer_handle())
}

///|
pub fn native_backend_available() -> Bool {
  @window_macos.EventLoopBuilder::new() |> ignore
  true
}

///|
pub fn input_finish_frame() -> Unit {
  clear_bool_state(key_just_pressed_ref.val)
  clear_bool_state(key_just_released_ref.val)
  clear_bool_state(key_repeated_ref.val)
  clear_bool_state(mouse_just_pressed_ref.val)
  clear_bool_state(mouse_just_released_ref.val)
  wheel_x_ref.val = 0.0
  wheel_y_ref.val = 0.0
  text_events_ref.val.clear()
  keyboard_events_ref.val.clear()
  ime_events_ref.val.clear()
  drag_events_ref.val.clear()
  window_theme_events_ref.val.clear()
  window_occluded_events_ref.val.clear()
  app_lifecycle_events_ref.val.clear()
  pinch_gesture_events_ref.val.clear()
  rotation_gesture_events_ref.val.clear()
  pan_gesture_events_ref.val.clear()
  double_tap_gesture_events_ref.val.clear()
  raw_winit_window_events_ref.val.clear()
  cursor_entered_window_ref.val = -1
  cursor_left_window_ref.val = -1
}

///|
pub fn input_has_cursor() -> Bool {
  has_cursor_ref.val
}

///|
pub fn input_cursor_window() -> Int {
  if has_cursor_ref.val {
    cursor_window_ref.val
  } else {
    -1
  }
}

///|
pub fn input_cursor_entered_window() -> Int {
  cursor_entered_window_ref.val
}

///|
pub fn input_cursor_left_window() -> Int {
  cursor_left_window_ref.val
}

///|
pub fn input_mouse_x() -> Float {
  mouse_x_ref.val
}

///|
pub fn input_mouse_y() -> Float {
  mouse_y_ref.val
}

///|
pub fn input_wheel_x() -> Float {
  wheel_x_ref.val
}

///|
pub fn input_wheel_y() -> Float {
  wheel_y_ref.val
}

///|
pub fn input_is_key_down_by_id(key_id : Int) -> Bool {
  bool_state_get(key_down_ref.val, key_id)
}

///|
pub fn input_is_key_just_pressed_by_id(key_id : Int) -> Bool {
  bool_state_get(key_just_pressed_ref.val, key_id)
}

///|
pub fn input_is_key_just_released_by_id(key_id : Int) -> Bool {
  bool_state_get(key_just_released_ref.val, key_id)
}

///|
pub fn input_is_key_repeated_by_id(key_id : Int) -> Bool {
  bool_state_get(key_repeated_ref.val, key_id)
}

///|
pub fn input_clear_all_keys() -> Unit {
  clear_bool_state(key_down_ref.val)
  clear_bool_state(key_just_pressed_ref.val)
  clear_bool_state(key_just_released_ref.val)
  clear_bool_state(key_repeated_ref.val)
}

///|
pub fn input_is_mouse_button_down_by_id(button_id : Int) -> Bool {
  bool_state_get(mouse_down_ref.val, button_id)
}

///|
pub fn input_is_mouse_button_just_pressed_by_id(button_id : Int) -> Bool {
  bool_state_get(mouse_just_pressed_ref.val, button_id)
}

///|
pub fn input_is_mouse_button_just_released_by_id(button_id : Int) -> Bool {
  bool_state_get(mouse_just_released_ref.val, button_id)
}

///|
pub fn input_key_id_from_key_code(key_code : @window_core.KeyCode) -> Int {
  key_id_from_key_code(key_code)
}

///|
pub fn input_key_id(code : String) -> Int {
  match key_code_from_name(code) {
    Some(key_code) => input_key_id_from_key_code(key_code)
    None => -1
  }
}

///|
pub fn input_mouse_button_id(button : String) -> Int {
  match button {
    "Left" => 0
    "Right" => 1
    "Middle" => 2
    _ => -1
  }
}

///|
pub fn input_is_key_down(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    input_is_key_down_by_id(id)
  }
}

///|
pub fn input_is_key_just_pressed(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    input_is_key_just_pressed_by_id(id)
  }
}

///|
pub fn input_is_key_just_released(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    input_is_key_just_released_by_id(id)
  }
}

///|
pub fn input_is_key_repeated(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    input_is_key_repeated_by_id(id)
  }
}

///|
pub fn input_is_mouse_button_down(button : String) -> Bool {
  let id = input_mouse_button_id(button)
  if id < 0 {
    false
  } else {
    input_is_mouse_button_down_by_id(id)
  }
}

///|
pub fn input_is_mouse_button_just_pressed(button : String) -> Bool {
  let id = input_mouse_button_id(button)
  if id < 0 {
    false
  } else {
    input_is_mouse_button_just_pressed_by_id(id)
  }
}

///|
pub fn input_is_mouse_button_just_released(button : String) -> Bool {
  let id = input_mouse_button_id(button)
  if id < 0 {
    false
  } else {
    input_is_mouse_button_just_released_by_id(id)
  }
}

///|
pub fn input_text_event_count() -> Int {
  text_events_ref.val.length()
}

///|
pub fn input_text_event_len(index~ : Int) -> Int {
  if index < 0 || index >= text_events_ref.val.length() {
    return 0
  }
  text_events_ref.val[index].length()
}

///|
pub fn input_text_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  if index < 0 || index >= text_events_ref.val.length() || offset < 0 {
    return 0
  }
  let text = text_events_ref.val[index]
  if offset >= text.length() {
    return 0
  }
  text[offset].to_int()
}

///|
pub fn input_keyboard_event_count() -> Int {
  keyboard_events_ref.val.length()
}

///|
pub fn input_keyboard_event_key_id(index~ : Int) -> Int {
  if index < 0 || index >= keyboard_events_ref.val.length() {
    return -1
  }
  keyboard_events_ref.val[index].key_id
}

///|
pub fn input_keyboard_event_state(index~ : Int) -> Int {
  if index < 0 || index >= keyboard_events_ref.val.length() {
    return 0
  }
  keyboard_events_ref.val[index].state
}

///|
pub fn input_keyboard_event_repeat(index~ : Int) -> Bool {
  if index < 0 || index >= keyboard_events_ref.val.length() {
    return false
  }
  keyboard_events_ref.val[index].repeat
}

///|
pub fn input_keyboard_event_text_len(index~ : Int) -> Int {
  if index < 0 || index >= keyboard_events_ref.val.length() {
    return 0
  }
  keyboard_events_ref.val[index].text.length()
}

///|
pub fn input_keyboard_event_text_code_unit(index~ : Int, offset~ : Int) -> Int {
  if index < 0 || index >= keyboard_events_ref.val.length() || offset < 0 {
    return 0
  }
  let text = keyboard_events_ref.val[index].text
  if offset >= text.length() {
    return 0
  }
  text[offset].to_int()
}

///|
pub fn input_ime_event_count() -> Int {
  ime_events_ref.val.length()
}

///|
pub fn input_ime_event_kind(index~ : Int) -> Int {
  if index < 0 || index >= ime_events_ref.val.length() {
    return 0
  }
  ime_events_ref.val[index].kind
}

///|
pub fn input_ime_event_window(index~ : Int) -> Int {
  if index < 0 || index >= ime_events_ref.val.length() {
    return 0
  }
  ime_events_ref.val[index].window
}

///|
pub fn input_ime_event_len(index~ : Int) -> Int {
  if index < 0 || index >= ime_events_ref.val.length() {
    return 0
  }
  ime_events_ref.val[index].text.length()
}

///|
pub fn input_ime_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  if index < 0 || index >= ime_events_ref.val.length() || offset < 0 {
    return 0
  }
  let text = ime_events_ref.val[index].text
  if offset >= text.length() {
    return 0
  }
  text[offset].to_int()
}

///|
pub fn input_ime_event_cursor_start(index~ : Int) -> Int {
  if index < 0 || index >= ime_events_ref.val.length() {
    return -1
  }
  ime_events_ref.val[index].cursor_start
}

///|
pub fn input_ime_event_cursor_end(index~ : Int) -> Int {
  if index < 0 || index >= ime_events_ref.val.length() {
    return -1
  }
  ime_events_ref.val[index].cursor_end
}

///|
pub fn input_pinch_gesture_event_count() -> Int {
  pinch_gesture_events_ref.val.length()
}

///|
pub fn input_pinch_gesture_event_window(index~ : Int) -> Int {
  if index < 0 || index >= pinch_gesture_events_ref.val.length() {
    return -1
  }
  pinch_gesture_events_ref.val[index].window
}

///|
pub fn input_pinch_gesture_event_delta(index~ : Int) -> Float {
  if index < 0 || index >= pinch_gesture_events_ref.val.length() {
    return 0.0
  }
  pinch_gesture_events_ref.val[index].delta
}

///|
pub fn input_rotation_gesture_event_count() -> Int {
  rotation_gesture_events_ref.val.length()
}

///|
pub fn input_rotation_gesture_event_window(index~ : Int) -> Int {
  if index < 0 || index >= rotation_gesture_events_ref.val.length() {
    return -1
  }
  rotation_gesture_events_ref.val[index].window
}

///|
pub fn input_rotation_gesture_event_delta(index~ : Int) -> Float {
  if index < 0 || index >= rotation_gesture_events_ref.val.length() {
    return 0.0
  }
  rotation_gesture_events_ref.val[index].delta
}

///|
pub fn input_pan_gesture_event_count() -> Int {
  pan_gesture_events_ref.val.length()
}

///|
pub fn input_pan_gesture_event_window(index~ : Int) -> Int {
  if index < 0 || index >= pan_gesture_events_ref.val.length() {
    return -1
  }
  pan_gesture_events_ref.val[index].window
}

///|
pub fn input_pan_gesture_event_x(index~ : Int) -> Float {
  if index < 0 || index >= pan_gesture_events_ref.val.length() {
    return 0.0
  }
  pan_gesture_events_ref.val[index].x
}

///|
pub fn input_pan_gesture_event_y(index~ : Int) -> Float {
  if index < 0 || index >= pan_gesture_events_ref.val.length() {
    return 0.0
  }
  pan_gesture_events_ref.val[index].y
}

///|
pub fn input_double_tap_gesture_event_count() -> Int {
  double_tap_gesture_events_ref.val.length()
}

///|
pub fn input_double_tap_gesture_event_window(index~ : Int) -> Int {
  if index < 0 || index >= double_tap_gesture_events_ref.val.length() {
    return -1
  }
  double_tap_gesture_events_ref.val[index].window
}

///|
pub fn input_touch_event_count() -> Int {
  0
}

///|
pub fn input_touch_event_id(index~ : Int) -> Int {
  index |> ignore
  -1
}

///|
pub fn input_touch_event_phase(index~ : Int) -> Int {
  index |> ignore
  0
}

///|
pub fn input_touch_event_x(index~ : Int) -> Float {
  index |> ignore
  0.0
}

///|
pub fn input_touch_event_y(index~ : Int) -> Float {
  index |> ignore
  0.0
}

///|
pub fn input_drag_and_drop_event_count() -> Int {
  drag_events_ref.val.length()
}

///|
pub fn input_drag_and_drop_event_kind(index~ : Int) -> Int {
  if index < 0 || index >= drag_events_ref.val.length() {
    return 0
  }
  drag_events_ref.val[index].kind
}

///|
pub fn input_drag_and_drop_event_window(index~ : Int) -> Int {
  if index < 0 || index >= drag_events_ref.val.length() {
    return -1
  }
  drag_events_ref.val[index].window
}

///|
pub fn input_drag_and_drop_event_len(index~ : Int) -> Int {
  if index < 0 || index >= drag_events_ref.val.length() {
    return 0
  }
  drag_events_ref.val[index].text.length()
}

///|
pub fn input_drag_and_drop_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  if index < 0 || index >= drag_events_ref.val.length() || offset < 0 {
    return 0
  }
  let text = drag_events_ref.val[index].text
  if offset >= text.length() {
    return 0
  }
  text[offset].to_int()
}

///|
pub fn input_window_theme_event_count() -> Int {
  window_theme_events_ref.val.length()
}

///|
pub fn input_window_theme_event_window(index~ : Int) -> Int {
  if index < 0 || index >= window_theme_events_ref.val.length() {
    return -1
  }
  window_theme_events_ref.val[index].window
}

///|
pub fn input_window_theme_event_theme(index~ : Int) -> Int {
  if index < 0 || index >= window_theme_events_ref.val.length() {
    return 0
  }
  window_theme_events_ref.val[index].theme
}

///|
pub fn input_window_occluded_event_count() -> Int {
  window_occluded_events_ref.val.length()
}

///|
pub fn input_window_occluded_event_window(index~ : Int) -> Int {
  if index < 0 || index >= window_occluded_events_ref.val.length() {
    return -1
  }
  window_occluded_events_ref.val[index].window
}

///|
pub fn input_window_occluded_event_occluded(index~ : Int) -> Bool {
  if index < 0 || index >= window_occluded_events_ref.val.length() {
    return false
  }
  window_occluded_events_ref.val[index].occluded
}

///|
pub fn input_app_lifecycle_event_count() -> Int {
  app_lifecycle_events_ref.val.length()
}

///|
pub fn input_app_lifecycle_event_kind(index~ : Int) -> Int {
  if index < 0 || index >= app_lifecycle_events_ref.val.length() {
    return APP_LIFECYCLE_IDLE
  }
  app_lifecycle_events_ref.val[index]
}

///|
extern "C" fn host_window_attach_metal_layer(
  window : Int,
  layer : @wgpu_c.OpaquePtr,
) -> Unit = "mgstudio_window_attach_metal_layer"
