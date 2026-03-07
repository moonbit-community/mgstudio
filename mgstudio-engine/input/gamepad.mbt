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
const GAMEPAD_BUTTON_COUNT : Int = 20

///|
const GAMEPAD_AXIS_COUNT : Int = 9

///|
pub(all) enum GamepadButton {
  South
  East
  C
  North
  West
  Z
  LeftTrigger
  RightTrigger
  LeftTrigger2
  RightTrigger2
  Select
  Start
  Mode
  LeftThumb
  RightThumb
  DPadUp
  DPadDown
  DPadLeft
  DPadRight
  Unknown
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadButton::to_index(self : GamepadButton) -> Int {
  match self {
    South => 0
    East => 1
    C => 2
    North => 3
    West => 4
    Z => 5
    LeftTrigger => 6
    RightTrigger => 7
    LeftTrigger2 => 8
    RightTrigger2 => 9
    Select => 10
    Start => 11
    Mode => 12
    LeftThumb => 13
    RightThumb => 14
    DPadUp => 15
    DPadDown => 16
    DPadLeft => 17
    DPadRight => 18
    Unknown => 19
  }
}

///|
fn gamepad_button_from_index(index : Int) -> GamepadButton {
  match index {
    0 => GamepadButton::South
    1 => GamepadButton::East
    2 => GamepadButton::C
    3 => GamepadButton::North
    4 => GamepadButton::West
    5 => GamepadButton::Z
    6 => GamepadButton::LeftTrigger
    7 => GamepadButton::RightTrigger
    8 => GamepadButton::LeftTrigger2
    9 => GamepadButton::RightTrigger2
    10 => GamepadButton::Select
    11 => GamepadButton::Start
    12 => GamepadButton::Mode
    13 => GamepadButton::LeftThumb
    14 => GamepadButton::RightThumb
    15 => GamepadButton::DPadUp
    16 => GamepadButton::DPadDown
    17 => GamepadButton::DPadLeft
    18 => GamepadButton::DPadRight
    _ => GamepadButton::Unknown
  }
}

///|
pub(all) enum GamepadAxis {
  LeftStickX
  LeftStickY
  LeftZ
  RightStickX
  RightStickY
  RightZ
  DPadX
  DPadY
  Unknown
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadAxis::to_index(self : GamepadAxis) -> Int {
  match self {
    LeftStickX => 0
    LeftStickY => 1
    LeftZ => 2
    RightStickX => 3
    RightStickY => 4
    RightZ => 5
    DPadX => 6
    DPadY => 7
    Unknown => 8
  }
}

///|
fn gamepad_axis_from_index(index : Int) -> GamepadAxis {
  match index {
    0 => GamepadAxis::LeftStickX
    1 => GamepadAxis::LeftStickY
    2 => GamepadAxis::LeftZ
    3 => GamepadAxis::RightStickX
    4 => GamepadAxis::RightStickY
    5 => GamepadAxis::RightZ
    6 => GamepadAxis::DPadX
    7 => GamepadAxis::DPadY
    _ => GamepadAxis::Unknown
  }
}

///|
pub(all) enum GamepadInput {
  Button(GamepadButton)
  Axis(GamepadAxis)
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct Gamepad {
  id : Int
}

///|
pub struct GamepadConnectionInfo {
  name : String
  vendor_id : Int?
  product_id : Int?
} derive(Eq, Show, ToJson, FromJson)

///|
pub(all) enum GamepadConnection {
  Connected(GamepadConnectionInfo)
  Disconnected
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct GamepadConnectionEvent {
  gamepad_id : Int
  connection : GamepadConnection
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadConnectionInfo::new(
  name : String,
  vendor_id : Int?,
  product_id : Int?,
) -> GamepadConnectionInfo {
  GamepadConnectionInfo::{ name, vendor_id, product_id }
}

///|
pub fn GamepadConnectionEvent::new(
  gamepad_id : Int,
  connection : GamepadConnection,
) -> GamepadConnectionEvent {
  GamepadConnectionEvent::{ gamepad_id, connection }
}

///|
pub struct RawGamepadButtonChangedEvent {
  gamepad_id : Int
  button : GamepadButton
  value : Float
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn RawGamepadButtonChangedEvent::new(
  gamepad_id : Int,
  button : GamepadButton,
  value : Float,
) -> RawGamepadButtonChangedEvent {
  RawGamepadButtonChangedEvent::{ gamepad_id, button, value }
}

///|
pub struct RawGamepadAxisChangedEvent {
  gamepad_id : Int
  axis : GamepadAxis
  value : Float
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn RawGamepadAxisChangedEvent::new(
  gamepad_id : Int,
  axis : GamepadAxis,
  value : Float,
) -> RawGamepadAxisChangedEvent {
  RawGamepadAxisChangedEvent::{ gamepad_id, axis, value }
}

///|
pub(all) enum RawGamepadEvent {
  Connection(GamepadConnectionEvent)
  Button(RawGamepadButtonChangedEvent)
  Axis(RawGamepadAxisChangedEvent)
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct GamepadButtonChangedEvent {
  gamepad_id : Int
  button : GamepadButton
  state : ButtonState
  value : Float
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadButtonChangedEvent::new(
  gamepad_id : Int,
  button : GamepadButton,
  state : ButtonState,
  value : Float,
) -> GamepadButtonChangedEvent {
  GamepadButtonChangedEvent::{ gamepad_id, button, state, value }
}

///|
pub struct GamepadAxisChangedEvent {
  gamepad_id : Int
  axis : GamepadAxis
  value : Float
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadAxisChangedEvent::new(
  gamepad_id : Int,
  axis : GamepadAxis,
  value : Float,
) -> GamepadAxisChangedEvent {
  GamepadAxisChangedEvent::{ gamepad_id, axis, value }
}

///|
pub struct GamepadButtonStateChangedEvent {
  gamepad_id : Int
  button : GamepadButton
  state : ButtonState
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn GamepadButtonStateChangedEvent::new(
  gamepad_id : Int,
  button : GamepadButton,
  state : ButtonState,
) -> GamepadButtonStateChangedEvent {
  GamepadButtonStateChangedEvent::{ gamepad_id, button, state }
}

///|
pub(all) enum GamepadEvent {
  Connection(GamepadConnectionEvent)
  Button(GamepadButtonChangedEvent)
  Axis(GamepadAxisChangedEvent)
} derive(Eq, Show, ToJson, FromJson)

///|
priv struct GamepadSnapshot {
  id : Int
  name : String
  vendor_id : Int?
  product_id : Int?
  connected : Bool
  button_values : Array[Float]
  button_pressed : Array[Bool]
  axis_values : Array[Float]
}

///|
fn host_input_gamepad_poll() -> Unit {
  @native_input.gamepad_poll()
}

///|
fn host_input_gamepad_count() -> Int {
  @native_input.gamepad_count()
}

///|
fn host_input_gamepad_id(index : Int) -> Int {
  @native_input.gamepad_id(index)
}

///|
fn host_input_gamepad_connected(gamepad_id : Int) -> Bool {
  @native_input.gamepad_connected(gamepad_id)
}

///|
fn host_input_gamepad_name_len(gamepad_id : Int) -> Int {
  @native_input.gamepad_name_len(gamepad_id)
}

///|
fn host_input_gamepad_name_code_unit(gamepad_id~ : Int, offset~ : Int) -> Int {
  @native_input.gamepad_name_code_unit(gamepad_id~, offset~)
}

///|
fn host_input_gamepad_vendor_id(gamepad_id : Int) -> Int {
  @native_input.gamepad_vendor_id(gamepad_id)
}

///|
fn host_input_gamepad_product_id(gamepad_id : Int) -> Int {
  @native_input.gamepad_product_id(gamepad_id)
}

///|
fn host_input_gamepad_button_value(gamepad_id~ : Int, button~ : Int) -> Float {
  @native_input.gamepad_button_value(gamepad_id~, button~)
}

///|
fn host_input_gamepad_button_pressed(gamepad_id~ : Int, button~ : Int) -> Bool {
  @native_input.gamepad_button_pressed(gamepad_id~, button~)
}

///|
fn host_input_gamepad_axis_value(gamepad_id~ : Int, axis~ : Int) -> Float {
  @native_input.gamepad_axis_value(gamepad_id~, axis~)
}

///|
let current_gamepads_ref : Ref[Array[GamepadSnapshot]] = Ref::new([])

///|
let previous_gamepads_ref : Ref[Array[GamepadSnapshot]] = Ref::new([])

///|
let gamepad_event_message_key : @ecs.MessageKey[GamepadEvent] = @ecs.register_message(
  debug_name="bevy_input::gamepad::GamepadEvent",
)

///|
let raw_gamepad_event_message_key : @ecs.MessageKey[RawGamepadEvent] = @ecs.register_message(
  debug_name="bevy_input::gamepad::RawGamepadEvent",
)

///|
let gamepad_connection_event_message_key : @ecs.MessageKey[
  GamepadConnectionEvent,
] = @ecs.register_message(
  debug_name="bevy_input::gamepad::GamepadConnectionEvent",
)

///|
let raw_gamepad_axis_changed_event_message_key : @ecs.MessageKey[
  RawGamepadAxisChangedEvent,
] = @ecs.register_message(
  debug_name="bevy_input::gamepad::RawGamepadAxisChangedEvent",
)

///|
let gamepad_axis_changed_event_message_key : @ecs.MessageKey[
  GamepadAxisChangedEvent,
] = @ecs.register_message(
  debug_name="bevy_input::gamepad::GamepadAxisChangedEvent",
)

///|
let raw_gamepad_button_changed_event_message_key : @ecs.MessageKey[
  RawGamepadButtonChangedEvent,
] = @ecs.register_message(
  debug_name="bevy_input::gamepad::RawGamepadButtonChangedEvent",
)

///|
let gamepad_button_changed_event_message_key : @ecs.MessageKey[
  GamepadButtonChangedEvent,
] = @ecs.register_message(
  debug_name="bevy_input::gamepad::GamepadButtonChangedEvent",
)

///|
let gamepad_button_state_changed_event_message_key : @ecs.MessageKey[
  GamepadButtonStateChangedEvent,
] = @ecs.register_message(
  debug_name="bevy_input::gamepad::GamepadButtonStateChangedEvent",
)

///|
let input_gamepad_poll_system_set : @app.SystemSet = @app.system_set(
  "bevy_input::gamepad::poll",
)

///|
let input_gamepad_event_processing_system_set : @app.SystemSet = @app.system_set(
  "bevy_input::gamepad::event_processing",
)

///|
fn nan_f32() -> Float {
  Float::from_double(0.0 / 0.0)
}

///|
fn float_is_nan(value : Float) -> Bool {
  value != value
}

///|
fn optional_device_id(value : Int) -> Int? {
  if value < 0 {
    None
  } else {
    Some(value)
  }
}

///|
fn host_gamepad_name(gamepad_id : Int) -> String {
  let len = host_input_gamepad_name_len(gamepad_id)
  if len <= 0 {
    return ""
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let code_unit = host_input_gamepad_name_code_unit(gamepad_id~, offset=i)
    if code_unit.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  String::from_array(chars)
}

///|
fn read_gamepad_snapshot(gamepad_id : Int) -> GamepadSnapshot {
  let button_values : Array[Float] = []
  let button_pressed : Array[Bool] = []
  let axis_values : Array[Float] = []
  for i in 0..<GAMEPAD_BUTTON_COUNT {
    button_values.push(host_input_gamepad_button_value(gamepad_id~, button=i))
    button_pressed.push(
      host_input_gamepad_button_pressed(gamepad_id~, button=i),
    )
  }
  for i in 0..<GAMEPAD_AXIS_COUNT {
    axis_values.push(host_input_gamepad_axis_value(gamepad_id~, axis=i))
  }
  GamepadSnapshot::{
    id: gamepad_id,
    name: host_gamepad_name(gamepad_id),
    vendor_id: optional_device_id(host_input_gamepad_vendor_id(gamepad_id)),
    product_id: optional_device_id(host_input_gamepad_product_id(gamepad_id)),
    connected: host_input_gamepad_connected(gamepad_id),
    button_values,
    button_pressed,
    axis_values,
  }
}

///|
fn find_gamepad_snapshot(
  snapshots : Array[GamepadSnapshot],
  gamepad_id : Int,
) -> GamepadSnapshot? {
  for snapshot in snapshots {
    if snapshot.id == gamepad_id {
      return Some(snapshot)
    }
  }
  None
}

///|
fn gamepad_button_value(snapshot : GamepadSnapshot, index : Int) -> Float? {
  if index < 0 || index >= snapshot.button_values.length() {
    return None
  }
  let value = snapshot.button_values[index]
  if float_is_nan(value) {
    None
  } else {
    Some(value)
  }
}

///|
fn gamepad_axis_value(snapshot : GamepadSnapshot, index : Int) -> Float? {
  if index < 0 || index >= snapshot.axis_values.length() {
    return None
  }
  let value = snapshot.axis_values[index]
  if float_is_nan(value) {
    None
  } else {
    Some(value)
  }
}

///|
fn gamepad_button_pressed(snapshot : GamepadSnapshot?, index : Int) -> Bool {
  if snapshot is Some(state) &&
    index >= 0 &&
    index < state.button_pressed.length() {
    state.button_pressed[index]
  } else {
    false
  }
}

///|
fn button_state_from_pressed(pressed : Bool) -> ButtonState {
  if pressed {
    ButtonState::Pressed
  } else {
    ButtonState::Released
  }
}

///|
fn button_state_from_value(value : Float) -> ButtonState {
  if float_is_nan(value) || value == 0.0F {
    ButtonState::Released
  } else {
    ButtonState::Pressed
  }
}

///|
fn snapshot_button_state(
  snapshot : GamepadSnapshot?,
  index : Int,
  fallback_value : Float,
) -> ButtonState {
  if snapshot is Some(state) &&
    index >= 0 &&
    index < state.button_pressed.length() {
    button_state_from_pressed(state.button_pressed[index])
  } else {
    button_state_from_value(fallback_value)
  }
}

///|
fn should_emit_value_change(previous : Float, current : Float) -> Bool {
  if float_is_nan(current) {
    return false
  }
  if float_is_nan(previous) {
    return current != 0.0F
  }
  previous != current
}

///|
fn emit_raw_connection_event(
  world : @ecs.World,
  event : GamepadConnectionEvent,
) -> Unit {
  world.send_message(gamepad_connection_event_message_key, event) |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Connection(event),
  )
  |> ignore
}

///|
fn emit_raw_button_changed_event(
  world : @ecs.World,
  event : RawGamepadButtonChangedEvent,
) -> Unit {
  world.send_message(raw_gamepad_button_changed_event_message_key, event)
  |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Button(event),
  )
  |> ignore
}

///|
fn emit_raw_axis_changed_event(
  world : @ecs.World,
  event : RawGamepadAxisChangedEvent,
) -> Unit {
  world.send_message(raw_gamepad_axis_changed_event_message_key, event)
  |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Axis(event),
  )
  |> ignore
}

///|
fn rebuild_gamepad_events(
  previous_gamepads : Array[GamepadSnapshot],
  current_gamepads : Array[GamepadSnapshot],
  world : @ecs.World,
) -> Unit {
  for current in current_gamepads {
    if !current.connected {
      continue
    }
    if find_gamepad_snapshot(previous_gamepads, current.id) is None {
      emit_raw_connection_event(world, GamepadConnectionEvent::{
        gamepad_id: current.id,
        connection: GamepadConnection::Connected(GamepadConnectionInfo::{
          name: current.name,
          vendor_id: current.vendor_id,
          product_id: current.product_id,
        }),
      })
    }
  }

  for previous in previous_gamepads {
    if previous.connected &&
      find_gamepad_snapshot(current_gamepads, previous.id) is None {
      emit_raw_connection_event(world, GamepadConnectionEvent::{
        gamepad_id: previous.id,
        connection: GamepadConnection::Disconnected,
      })
    }
  }

  for current in current_gamepads {
    guard current.connected else { continue }
    if find_gamepad_snapshot(previous_gamepads, current.id) is Some(previous) {
      for i in 0..<GAMEPAD_BUTTON_COUNT {
        let current_value = current.button_values[i]
        let previous_value = if i < previous.button_values.length() {
          previous.button_values[i]
        } else {
          nan_f32()
        }
        if should_emit_value_change(previous_value, current_value) {
          emit_raw_button_changed_event(world, RawGamepadButtonChangedEvent::{
            gamepad_id: current.id,
            button: gamepad_button_from_index(i),
            value: current_value,
          })
        }
      }
      for i in 0..<GAMEPAD_AXIS_COUNT {
        let current_value = current.axis_values[i]
        let previous_value = if i < previous.axis_values.length() {
          previous.axis_values[i]
        } else {
          nan_f32()
        }
        if should_emit_value_change(previous_value, current_value) {
          emit_raw_axis_changed_event(world, RawGamepadAxisChangedEvent::{
            gamepad_id: current.id,
            axis: gamepad_axis_from_index(i),
            value: current_value,
          })
        }
      }
    }
  }
}

///|
priv struct GamepadProcessedEventWriters {
  gamepad_events : @ecs.MessageWriter[GamepadEvent]
  axis_events : @ecs.MessageWriter[GamepadAxisChangedEvent]
  button_events : @ecs.MessageWriter[GamepadButtonChangedEvent]
  button_state_events : @ecs.MessageWriter[GamepadButtonStateChangedEvent]
}

///|
fn current_gamepad_processing_world_abort_missing() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None => abort("Missing current world while processing gamepad events")
  }
}

///|
impl @app.SystemParam for GamepadProcessedEventWriters with init_state(world) {
  @app.system_param_empty_state(world)
}

///|
impl @app.SystemParam for GamepadProcessedEventWriters with get(_state) {
  let world = current_gamepad_processing_world_abort_missing()
  GamepadProcessedEventWriters::{
    gamepad_events: world.message_writer(gamepad_event_message_key),
    axis_events: world.message_writer(gamepad_axis_changed_event_message_key),
    button_events: world.message_writer(
      gamepad_button_changed_event_message_key,
    ),
    button_state_events: world.message_writer(
      gamepad_button_state_changed_event_message_key,
    ),
  }
}

///|
impl @app.SystemParam for GamepadProcessedEventWriters with store(self, state) {
  @app.system_param_store_no_state(self, state)
}

///|
fn process_button_event(
  raw_event : RawGamepadButtonChangedEvent,
  outputs : GamepadProcessedEventWriters,
) -> Unit {
  let index = raw_event.button.to_index()
  let current_state = snapshot_button_state(
    find_gamepad_snapshot(current_gamepads_ref.val, raw_event.gamepad_id),
    index,
    raw_event.value,
  )
  let previous_state = snapshot_button_state(
    find_gamepad_snapshot(previous_gamepads_ref.val, raw_event.gamepad_id),
    index,
    0.0F,
  )
  if previous_state != current_state {
    ignore(
      outputs.button_state_events.write(
        GamepadButtonStateChangedEvent::new(
          raw_event.gamepad_id,
          raw_event.button,
          current_state,
        ),
      ),
    )
  }
  let event = GamepadButtonChangedEvent::new(
    raw_event.gamepad_id,
    raw_event.button,
    current_state,
    raw_event.value,
  )
  ignore(outputs.button_events.write(event))
  ignore(outputs.gamepad_events.write(GamepadEvent::Button(event)))
}

///|
fn gamepad_event_processing_system(
  raw_events : @ecs.MessageReader[RawGamepadEvent],
  outputs : GamepadProcessedEventWriters,
) -> Unit {
  for raw_event in (try! raw_events.read()) {
    match raw_event {
      Connection(connection_event) =>
        ignore(
          outputs.gamepad_events.write(
            GamepadEvent::Connection(connection_event),
          ),
        )
      Axis(axis_event) => {
        let event = GamepadAxisChangedEvent::new(
          axis_event.gamepad_id,
          axis_event.axis,
          axis_event.value,
        )
        ignore(outputs.axis_events.write(event))
        ignore(outputs.gamepad_events.write(GamepadEvent::Axis(event)))
      }
      Button(button_event) => process_button_event(button_event, outputs)
    }
  }
}

///|
pub fn gamepads() -> Array[Gamepad] {
  let out : Array[Gamepad] = []
  for snapshot in current_gamepads_ref.val {
    if snapshot.connected {
      out.push(Gamepad::{ id: snapshot.id })
    }
  }
  out
}

///|
pub fn Gamepad::id(self : Gamepad) -> Int {
  self.id
}

///|
pub fn Gamepad::name(self : Gamepad) -> String {
  if find_gamepad_snapshot(current_gamepads_ref.val, self.id) is Some(snapshot) {
    snapshot.name
  } else {
    ""
  }
}

///|
pub fn Gamepad::vendor_id(self : Gamepad) -> Int? {
  if find_gamepad_snapshot(current_gamepads_ref.val, self.id) is Some(snapshot) {
    snapshot.vendor_id
  } else {
    None
  }
}

///|
pub fn Gamepad::product_id(self : Gamepad) -> Int? {
  if find_gamepad_snapshot(current_gamepads_ref.val, self.id) is Some(snapshot) {
    snapshot.product_id
  } else {
    None
  }
}

///|
pub fn Gamepad::connected(self : Gamepad) -> Bool {
  if find_gamepad_snapshot(current_gamepads_ref.val, self.id) is Some(snapshot) {
    snapshot.connected
  } else {
    false
  }
}

///|
pub fn Gamepad::get(self : Gamepad, input : GamepadInput) -> Float? {
  if find_gamepad_snapshot(current_gamepads_ref.val, self.id) is Some(snapshot) {
    match input {
      Button(button) => gamepad_button_value(snapshot, button.to_index())
      Axis(axis) => gamepad_axis_value(snapshot, axis.to_index())
    }
  } else {
    None
  }
}

///|
pub fn Gamepad::pressed(self : Gamepad, button : GamepadButton) -> Bool {
  if find_gamepad_snapshot(current_gamepads_ref.val, self.id) is Some(snapshot) {
    gamepad_button_pressed(Some(snapshot), button.to_index())
  } else {
    false
  }
}

///|
pub fn Gamepad::just_pressed(self : Gamepad, button : GamepadButton) -> Bool {
  let index = button.to_index()
  let current = find_gamepad_snapshot(current_gamepads_ref.val, self.id)
  let previous = find_gamepad_snapshot(previous_gamepads_ref.val, self.id)
  let current_pressed = gamepad_button_pressed(current, index)
  if !current_pressed {
    return false
  }
  !gamepad_button_pressed(previous, index)
}

///|
pub fn Gamepad::just_released(self : Gamepad, button : GamepadButton) -> Bool {
  let index = button.to_index()
  let current = find_gamepad_snapshot(current_gamepads_ref.val, self.id)
  let previous = find_gamepad_snapshot(previous_gamepads_ref.val, self.id)
  if gamepad_button_pressed(current, index) {
    return false
  }
  gamepad_button_pressed(previous, index)
}

///|
pub fn Gamepad::left_stick(self : Gamepad) -> @math.Vec2 {
  @math.Vec2::new(
    self.get(GamepadInput::Axis(GamepadAxis::LeftStickX)).unwrap_or(0.0F),
    self.get(GamepadInput::Axis(GamepadAxis::LeftStickY)).unwrap_or(0.0F),
  )
}

///|
pub fn Gamepad::right_stick(self : Gamepad) -> @math.Vec2 {
  @math.Vec2::new(
    self.get(GamepadInput::Axis(GamepadAxis::RightStickX)).unwrap_or(0.0F),
    self.get(GamepadInput::Axis(GamepadAxis::RightStickY)).unwrap_or(0.0F),
  )
}

///|
pub fn Gamepad::dpad(self : Gamepad) -> @math.Vec2 {
  let right = self
    .get(GamepadInput::Button(GamepadButton::DPadRight))
    .unwrap_or(0.0F)
  let left = self
    .get(GamepadInput::Button(GamepadButton::DPadLeft))
    .unwrap_or(0.0F)
  let up = self.get(GamepadInput::Button(GamepadButton::DPadUp)).unwrap_or(0.0F)
  let down = self
    .get(GamepadInput::Button(GamepadButton::DPadDown))
    .unwrap_or(0.0F)
  @math.Vec2::new(right - left, up - down)
}

///|
pub impl @ecs.Message for GamepadEvent with message() {
  gamepad_event_message_key
}

///|
pub impl @ecs.Message for GamepadConnectionEvent with message() {
  gamepad_connection_event_message_key
}

///|
pub impl @ecs.Message for RawGamepadAxisChangedEvent with message() {
  raw_gamepad_axis_changed_event_message_key
}

///|
pub impl @ecs.Message for GamepadAxisChangedEvent with message() {
  gamepad_axis_changed_event_message_key
}

///|
pub impl @ecs.Message for RawGamepadButtonChangedEvent with message() {
  raw_gamepad_button_changed_event_message_key
}

///|
pub impl @ecs.Message for GamepadButtonChangedEvent with message() {
  gamepad_button_changed_event_message_key
}

///|
pub impl @ecs.Message for GamepadButtonStateChangedEvent with message() {
  gamepad_button_state_changed_event_message_key
}

///|
pub impl @ecs.Message for RawGamepadEvent with message() {
  raw_gamepad_event_message_key
}

///|
pub fn input_gamepad_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_message(gamepad_event_message_key)
  .add_message(raw_gamepad_event_message_key)
  .add_message(gamepad_connection_event_message_key)
  .add_message(raw_gamepad_axis_changed_event_message_key)
  .add_message(gamepad_axis_changed_event_message_key)
  .add_message(raw_gamepad_button_changed_event_message_key)
  .add_message(gamepad_button_changed_event_message_key)
  .add_message(gamepad_button_state_changed_event_message_key)
}

///|
pub fn input_poll_gamepad_system(world : @ecs.World) -> Unit {
  host_input_gamepad_poll()

  previous_gamepads_ref.val = current_gamepads_ref.val

  let next_gamepads : Array[GamepadSnapshot] = []
  let n = host_input_gamepad_count()
  for i in 0..<n {
    let gamepad_id = host_input_gamepad_id(i)
    if gamepad_id >= 0 {
      let snapshot = read_gamepad_snapshot(gamepad_id)
      if snapshot.connected {
        next_gamepads.push(snapshot)
      }
    }
  }

  current_gamepads_ref.val = next_gamepads
  rebuild_gamepad_events(
    previous_gamepads_ref.val,
    current_gamepads_ref.val,
    world,
  )
}

///|
pub fn input_gamepad_finish_frame() -> Unit {
  previous_gamepads_ref.val = current_gamepads_ref.val
}
