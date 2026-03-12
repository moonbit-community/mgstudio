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
const INPUT_EVENT_POINTER_MOVED : Int = 1

///|
const INPUT_EVENT_POINTER_ENTERED : Int = 2

///|
const INPUT_EVENT_POINTER_LEFT : Int = 3

///|
const INPUT_EVENT_POINTER_BUTTON : Int = 4

///|
const INPUT_EVENT_MOUSE_WHEEL : Int = 5

///|
const INPUT_EVENT_KEYBOARD_INPUT : Int = 7

///|
const INPUT_EVENT_IME : Int = 8

///|
const INPUT_EVENT_DRAG_ENTERED : Int = 9

///|
const INPUT_EVENT_DRAG_MOVED : Int = 10

///|
const INPUT_EVENT_DRAG_DROPPED : Int = 11

///|
const INPUT_EVENT_DRAG_LEFT : Int = 12

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
const DEFAULT_FRAME_LIMIT : Int = 0

///|
pub type NativeWindowHandle = Int

///|
priv struct DragEvent {
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
fn mark_window_open(window : Int) -> Unit {
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
fn push_drag_event(kind : Int, text : Bytes) -> Unit {
  if drag_events_ref.val.length() >= MAX_DRAG_EVENTS {
    return
  }
  drag_events_ref.val.push(DragEvent::{ kind, text })
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
  ime_events_ref.val.push(ImeEvent::{ window, kind, text, cursor_start, cursor_end })
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
fn key_id_from_scancode(scancode : Int) -> Int {
  match scancode {
    0 => 0
    11 => 1
    8 => 2
    2 => 3
    14 => 4
    3 => 5
    5 => 6
    4 => 7
    34 => 8
    38 => 9
    40 => 10
    37 => 11
    46 => 12
    45 => 13
    31 => 14
    35 => 15
    12 => 16
    15 => 17
    1 => 18
    17 => 19
    32 => 20
    9 => 21
    13 => 22
    7 => 23
    16 => 24
    6 => 25
    18 => 26
    19 => 27
    20 => 28
    21 => 29
    23 => 30
    22 => 31
    26 => 32
    28 => 33
    25 => 34
    29 => 35
    48 => 36
    36 => 37
    51 => 38
    56 => 39
    60 => 40
    59 => 41
    62 => 42
    126 => 43
    125 => 44
    123 => 45
    124 => 46
    116 => 47
    121 => 48
    49 => 49
    53 => 50
    41 => 51
    43 => 52
    47 => 53
    44 => 54
    27 => 55
    24 => 56
    33 => 57
    30 => 58
    39 => 59
    50 => 60
    42 => 61
    69 => 62
    78 => 63
    _ => -1
  }
}

///|
fn process_pointer_button(window : Int) -> Unit {
  let button = host_window_input_event_button(window)
  if button < 0 || button >= MOUSE_BUTTON_COUNT {
    return
  }
  let state = host_window_input_event_state(window)
  if state == ELEMENT_STATE_PRESSED {
    if !bool_state_get(mouse_down_ref.val, button) {
      bool_state_set(mouse_just_pressed_ref.val, button, true)
    }
    bool_state_set(mouse_down_ref.val, button, true)
  } else if state == ELEMENT_STATE_RELEASED {
    if bool_state_get(mouse_down_ref.val, button) {
      bool_state_set(mouse_just_released_ref.val, button, true)
    }
    bool_state_set(mouse_down_ref.val, button, false)
  }
}

///|
fn process_keyboard_input(window : Int) -> Unit {
  let key_id = key_id_from_scancode(host_window_input_event_scancode(window))
  if key_id < 0 {
    return
  }
  let state = host_window_input_event_state(window)
  if state == ELEMENT_STATE_PRESSED {
    let repeated = host_window_input_event_repeat(window)
    let text = host_window_input_event_text_with_all_modifiers(window)
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
fn process_drag_event(window : Int, kind : Int) -> Unit {
  match kind {
    INPUT_EVENT_DRAG_ENTERED => {
      let path = host_window_input_event_path(window)
      drag_hovered_path_ref.val = Some(path)
      push_drag_event(1, path)
    }
    INPUT_EVENT_DRAG_MOVED =>
      match drag_hovered_path_ref.val {
        Some(path) => push_drag_event(1, path)
        None => {
          let path = host_window_input_event_path(window)
          if path.length() > 0 {
            drag_hovered_path_ref.val = Some(path)
            push_drag_event(1, path)
          }
        }
      }
    INPUT_EVENT_DRAG_DROPPED => {
      let path = host_window_input_event_path(window)
      drag_hovered_path_ref.val = None
      push_drag_event(0, path)
    }
    INPUT_EVENT_DRAG_LEFT => {
      drag_hovered_path_ref.val = None
      push_drag_event(2, host_window_input_event_path(window))
    }
    _ => ()
  }
}

///|
fn process_input_events(window : Int) -> Unit {
  while host_window_take_input_event(window) {
    let kind = host_window_input_event_kind(window)

    if kind == INPUT_EVENT_POINTER_MOVED ||
      kind == INPUT_EVENT_POINTER_ENTERED ||
      kind == INPUT_EVENT_POINTER_LEFT ||
      kind == INPUT_EVENT_POINTER_BUTTON {
      has_cursor_ref.val = kind != INPUT_EVENT_POINTER_LEFT
      mouse_x_ref.val = Float::from_double(host_window_input_event_x(window))
      mouse_y_ref.val = Float::from_double(host_window_input_event_y(window))
    }

    if kind == INPUT_EVENT_POINTER_BUTTON {
      process_pointer_button(window)
      continue
    }

    if kind == INPUT_EVENT_MOUSE_WHEEL {
      wheel_x_ref.val = wheel_x_ref.val +
        Float::from_double(host_window_input_event_scroll_delta_x(window))
      wheel_y_ref.val = wheel_y_ref.val +
        Float::from_double(host_window_input_event_scroll_delta_y(window))
      continue
    }

    if kind == INPUT_EVENT_KEYBOARD_INPUT {
      process_keyboard_input(window)
      continue
    }

    if kind == INPUT_EVENT_IME {
      let ime_kind = host_window_input_event_ime_kind(window)
      let ime_text = host_window_input_event_ime_text(window)
      let ime_cursor_start = host_window_input_event_ime_cursor_start(window)
      let ime_cursor_end = host_window_input_event_ime_cursor_end(window)
      push_ime_event(window, ime_kind, ime_text, ime_cursor_start, ime_cursor_end)
      if ime_kind == IME_EVENT_COMMIT {
        push_text_event(ime_text)
      }
      continue
    }

    if kind == INPUT_EVENT_DRAG_ENTERED ||
      kind == INPUT_EVENT_DRAG_MOVED ||
      kind == INPUT_EVENT_DRAG_DROPPED ||
      kind == INPUT_EVENT_DRAG_LEFT {
      process_drag_event(window, kind)
      continue
    }
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
  title_len : UInt64,
  visible : Bool,
  resizable : Bool,
  decorations : Bool,
  panel : Bool,
) -> Int {
  let width = if use_physical_size_on_create {
    if physical_width > 0 {
      physical_width
    } else {
      logical_width
    }
  } else {
    logical_width
  }
  let height = if use_physical_size_on_create {
    if physical_height > 0 {
      physical_height
    } else {
      logical_height
    }
  } else {
    logical_height
  }
  let window = host_window_create_utf8(
    width,
    height,
    visible,
    true,
    resizable,
    decorations,
    panel,
    title,
    title_len,
  )
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
pub fn poll_events(window : Int) -> Unit {
  host_window_poll(window)
  if host_window_take_close_requested(window) {
    mark_window_closed(window)
  }
  process_input_events(window)
}

///|
pub fn width(window : Int) -> Int {
  host_window_width(window)
}

///|
pub fn height(window : Int) -> Int {
  host_window_height(window)
}

///|
pub fn scale_factor(window : Int) -> Float {
  Float::from_double(host_window_scale_factor(window))
}

///|
pub fn focused(window : Int) -> Bool {
  host_window_has_focus(window)
}

///|
pub fn should_close(window : Int) -> Bool {
  if is_window_closed(window) {
    return true
  }
  if host_window_take_close_requested(window) {
    mark_window_closed(window)
    true
  } else {
    false
  }
}

///|
pub fn request_close(window : Int) -> Unit {
  host_window_close(window)
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
pub fn set_title_utf8(window : Int, title : Bytes, title_len : UInt64) -> Unit {
  host_window_set_title_utf8(window, title, title_len)
}

///|
pub fn set_title(window : Int, title~ : String) -> Unit {
  let title_bytes = encode_utf8_bytes(title)
  set_title_utf8(window, title_bytes, title_bytes.length().to_uint64())
}

///|
pub fn set_size(window : Int, width~ : Int, height~ : Int) -> Unit {
  host_window_set_surface_size(window, width, height)
}

///|
pub fn set_resizable(window : Int, resizable~ : Bool) -> Unit {
  host_window_set_resizable(window, resizable)
}

///|
pub fn set_visible(window : Int, visible~ : Bool) -> Unit {
  host_window_set_visible(window, visible)
}

///|
pub fn set_decorations(window : Int, decorations~ : Bool) -> Unit {
  host_window_set_decorations(window, decorations)
}

///|
pub fn set_transparent(window : Int, transparent~ : Bool) -> Unit {
  host_window_set_transparent(window, transparent)
}

///|
pub fn set_enabled_buttons(
  window : Int,
  close~ : Bool,
  minimize~ : Bool,
  maximize~ : Bool,
) -> Unit {
  host_window_set_enabled_buttons(window, close, minimize, maximize)
}

///|
pub fn set_window_level(window : Int, level~ : Int) -> Unit {
  host_window_set_window_level(window, level)
}

///|
pub fn set_theme(window : Int, theme~ : Int) -> Unit {
  host_window_set_theme(window, theme)
}

///|
pub fn set_ime_allowed(window : Int, allowed~ : Bool) -> Unit {
  host_window_set_ime_allowed(window, allowed)
}

///|
pub fn set_ime_cursor_area(
  window : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
) -> Unit {
  host_window_set_ime_cursor_area(window, x, y, width, height)
}

///|
pub fn set_cursor_visible(window : Int, visible~ : Bool) -> Unit {
  host_window_set_cursor_visible(window, visible)
}

///|
pub fn set_cursor_grab_mode(window : Int, mode~ : Int) -> Unit {
  host_window_set_cursor_grab(window, mode) |> ignore
}

///|
pub fn set_cursor_icon(window : Int, icon~ : Int) -> Unit {
  host_window_set_cursor(window, icon)
}

///|
pub fn set_mode(window : Int, mode~ : Int) -> Unit {
  if mode == 0 {
    host_window_set_fullscreen(window, false)
    host_window_set_simple_fullscreen(window, false) |> ignore
  } else if mode == 1 {
    host_window_set_simple_fullscreen(window, true) |> ignore
  } else if mode == 2 {
    host_window_set_fullscreen(window, true)
  }
}

///|
pub fn set_position(window : Int, x~ : Int, y~ : Int) -> Unit {
  host_window_set_position(window, x, y)
}

///|
pub fn drag_window(window : Int) -> Bool {
  host_window_drag_window(window)
}

///|
pub fn drag_resize_window(window : Int, direction~ : Int) -> Bool {
  host_window_drag_resize_window(window, direction)
}

///|
pub fn position_x(window : Int) -> Int {
  host_window_x(window)
}

///|
pub fn position_y(window : Int) -> Int {
  host_window_y(window)
}

///|
pub fn attach_metal_layer(window : Int, layer : @wgpu_c.OpaquePtr) -> Unit {
  host_window_attach_metal_layer(window, layer)
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
  @window_macos.native_backend_available()
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
}

///|
pub fn input_has_cursor() -> Bool {
  has_cursor_ref.val
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
pub fn input_key_id(code : String) -> Int {
  match code {
    "KeyA" => 0
    "KeyB" => 1
    "KeyC" => 2
    "KeyD" => 3
    "KeyE" => 4
    "KeyF" => 5
    "KeyG" => 6
    "KeyH" => 7
    "KeyI" => 8
    "KeyJ" => 9
    "KeyK" => 10
    "KeyL" => 11
    "KeyM" => 12
    "KeyN" => 13
    "KeyO" => 14
    "KeyP" => 15
    "KeyQ" => 16
    "KeyR" => 17
    "KeyS" => 18
    "KeyT" => 19
    "KeyU" => 20
    "KeyV" => 21
    "KeyW" => 22
    "KeyX" => 23
    "KeyY" => 24
    "KeyZ" => 25
    "Digit1" => 26
    "Digit2" => 27
    "Digit3" => 28
    "Digit4" => 29
    "Digit5" => 30
    "Digit6" => 31
    "Digit7" => 32
    "Digit8" => 33
    "Digit9" => 34
    "Digit0" => 35
    "Tab" => 36
    "Enter" => 37
    "Backspace" => 38
    "ShiftLeft" => 39
    "ShiftRight" => 40
    "ControlLeft" => 41
    "ControlRight" => 42
    "ArrowUp" => 43
    "ArrowDown" => 44
    "ArrowLeft" => 45
    "ArrowRight" => 46
    "PageUp" => 47
    "PageDown" => 48
    "Space" => 49
    "Escape" => 50
    "Semicolon" => 51
    "Comma" => 52
    "Period" => 53
    "Slash" => 54
    "Minus" => 55
    "Equal" => 56
    "NumpadAdd" => 62
    "NumpadSubtract" => 63
    "BracketLeft" => 57
    "BracketRight" => 58
    "Quote" => 59
    "Backquote" => 60
    "Backslash" => 61
    _ => -1
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
#borrow(title)
extern "C" fn host_window_create_utf8(
  width : Int,
  height : Int,
  visible : Bool,
  active : Bool,
  resizable : Bool,
  decorations : Bool,
  panel : Bool,
  title : Bytes,
  title_len : UInt64,
) -> Int = "mbw_window_create_utf8"

///|
extern "C" fn host_window_poll(window : Int) -> Unit = "mbw_window_poll"

///|
extern "C" fn host_window_width(window : Int) -> Int = "mbw_window_width"

///|
extern "C" fn host_window_height(window : Int) -> Int = "mbw_window_height"

///|
extern "C" fn host_window_scale_factor(window : Int) -> Double = "mbw_window_scale_factor"

///|
extern "C" fn host_window_has_focus(window : Int) -> Bool = "mbw_window_has_focus"

///|
extern "C" fn host_window_take_close_requested(window : Int) -> Bool = "mbw_window_take_close_requested"

///|
extern "C" fn host_window_close(window : Int) -> Unit = "mbw_window_close"

///|
#borrow(title)
extern "C" fn host_window_set_title_utf8(
  window : Int,
  title : Bytes,
  title_len : UInt64,
) -> Unit = "mbw_window_set_title_utf8"

///|
extern "C" fn host_window_set_surface_size(
  window : Int,
  width : Int,
  height : Int,
) -> Unit = "mbw_window_set_surface_size"

///|
extern "C" fn host_window_set_resizable(window : Int, resizable : Bool) -> Unit = "mbw_window_set_resizable"

///|
extern "C" fn host_window_set_visible(window : Int, visible : Bool) -> Unit = "mbw_window_set_visible"

///|
extern "C" fn host_window_set_decorations(
  window : Int,
  decorations : Bool,
) -> Unit = "mbw_window_set_decorations"

///|
extern "C" fn host_window_set_enabled_buttons(
  window : Int,
  close : Bool,
  minimize : Bool,
  maximize : Bool,
) -> Unit = "mbw_window_set_enabled_buttons"

///|
extern "C" fn host_window_set_transparent(
  window : Int,
  transparent : Bool,
) -> Unit = "mbw_window_set_transparent"

///|
extern "C" fn host_window_set_window_level(
  window : Int,
  level : Int,
) -> Unit = "mbw_window_set_window_level"

///|
extern "C" fn host_window_set_theme(window : Int, theme : Int) -> Unit = "mbw_window_set_theme"

///|
extern "C" fn host_window_set_ime_allowed(
  window : Int,
  allowed : Bool,
) -> Unit = "mbw_window_set_ime_allowed"

///|
extern "C" fn host_window_set_ime_cursor_area(
  window : Int,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit = "mbw_window_set_ime_cursor_area"

///|
extern "C" fn host_window_set_cursor_visible(
  window : Int,
  visible : Bool,
) -> Unit = "mbw_window_set_cursor_visible"

///|
extern "C" fn host_window_set_cursor_grab(window : Int, mode : Int) -> Bool = "mbw_window_set_cursor_grab"

///|
extern "C" fn host_window_set_cursor(window : Int, cursor : Int) -> Unit = "mbw_window_set_cursor"

///|
extern "C" fn host_window_set_fullscreen(
  window : Int,
  fullscreen : Bool,
) -> Unit = "mbw_window_set_fullscreen"

///|
extern "C" fn host_window_set_simple_fullscreen(
  window : Int,
  fullscreen : Bool,
) -> Bool = "mbw_window_set_simple_fullscreen"

///|
extern "C" fn host_window_set_position(window : Int, x : Int, y : Int) -> Unit = "mbw_window_set_position"

///|
extern "C" fn host_window_drag_window(window : Int) -> Bool = "mbw_window_drag_window"

///|
extern "C" fn host_window_drag_resize_window(
  window : Int,
  direction : Int,
) -> Bool = "mbw_window_drag_resize_window"

///|
extern "C" fn host_window_x(window : Int) -> Int = "mbw_window_x"

///|
extern "C" fn host_window_y(window : Int) -> Int = "mbw_window_y"

///|
extern "C" fn host_window_attach_metal_layer(
  window : Int,
  layer : @wgpu_c.OpaquePtr,
) -> Unit = "mgstudio_window_attach_metal_layer_from_mbw"

///|
extern "C" fn host_window_take_input_event(window : Int) -> Bool = "mbw_window_take_input_event"

///|
extern "C" fn host_window_input_event_kind(window : Int) -> Int = "mbw_window_input_event_kind"

///|
extern "C" fn host_window_input_event_x(window : Int) -> Double = "mbw_window_input_event_x"

///|
extern "C" fn host_window_input_event_y(window : Int) -> Double = "mbw_window_input_event_y"

///|
extern "C" fn host_window_input_event_state(window : Int) -> Int = "mbw_window_input_event_state"

///|
extern "C" fn host_window_input_event_button(window : Int) -> Int = "mbw_window_input_event_button"

///|
extern "C" fn host_window_input_event_scroll_delta_x(window : Int) -> Double = "mbw_window_input_event_scroll_delta_x"

///|
extern "C" fn host_window_input_event_scroll_delta_y(window : Int) -> Double = "mbw_window_input_event_scroll_delta_y"

///|
extern "C" fn host_window_input_event_scancode(window : Int) -> Int = "mbw_window_input_event_scancode"

///|
extern "C" fn host_window_input_event_repeat(window : Int) -> Bool = "mbw_window_input_event_repeat"

///|
extern "C" fn host_window_input_event_text_with_all_modifiers(
  window : Int,
) -> Bytes = "mbw_window_input_event_text_with_all_modifiers"

///|
extern "C" fn host_window_input_event_ime_kind(window : Int) -> Int = "mbw_window_input_event_ime_kind"

///|
extern "C" fn host_window_input_event_ime_text(window : Int) -> Bytes = "mbw_window_input_event_ime_text"

///|
extern "C" fn host_window_input_event_ime_cursor_start(
  window : Int,
) -> Int = "mbw_window_input_event_ime_cursor_start"

///|
extern "C" fn host_window_input_event_ime_cursor_end(window : Int) -> Int = "mbw_window_input_event_ime_cursor_end"

///|
extern "C" fn host_window_input_event_path(window : Int) -> Bytes = "mbw_window_input_event_path"
