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
let connected_gamepad_ids : Array[Int] = []

///|
fn ensure_gilrs() -> @gamepad.Gil {
  match gilrs_runtime_state.gilrs {
    Some(gilrs) => gilrs
    None => {
      let gilrs = @gamepad.Gil::new()
      gilrs_runtime_state.gilrs = Some(gilrs)
      gilrs
    }
  }
}

///|
fn refresh_gamepads() -> Unit {
  let gilrs = ensure_gilrs()
  while true {
    match gilrs.next_event() {
      Some(_) => continue
      None => break
    }
  }

  let connected_ids : Array[Int] = []
  for pair in gilrs.gamepads() {
    let (id, _gamepad) = pair
    connected_ids.push(id.value())
  }
  connected_gamepad_ids.clear()
  for id in connected_ids {
    connected_gamepad_ids.push(id)
  }
}

///|
fn connected_gamepad(gamepad_id : Int) -> @gamepad.Gamepad? {
  ensure_gilrs().connected_gamepad(@gamepad.GamepadId::new(gamepad_id))
}

///|
pub(all) enum GamepadRumbleResult {
  Applied
  Unsupported
  NotFound
}

///|
pub struct GamepadRumbleCommand {
  gamepad_id : Int
  strong_motor : Float
  weak_motor : Float
  duration_ms : Int64
}

///|
priv struct GilrsRuntimeState {
  mut gilrs : @gamepad.Gil?
  mut record_commands : Bool
  mut ff_supported_override : Bool?
}

///|
let gilrs_runtime_state : GilrsRuntimeState = {
  gilrs: None,
  record_commands: false,
  ff_supported_override: None,
}

///|
let recorded_gamepad_rumble_commands : Array[GamepadRumbleCommand] = []

///|
fn clamp_rumble_motor(value : Float) -> Double {
  if value <= 0.0 {
    0.0
  } else if value >= 1.0 {
    1.0
  } else {
    value.to_double()
  }
}

///|
fn gamepad_ff_supported_for_rumble(gamepad : @gamepad.Gamepad) -> Bool {
  match gilrs_runtime_state.ff_supported_override {
    Some(supported) => supported
    None => gamepad.is_ff_supported()
  }
}

///|
pub fn gamepad_set_rumble(
  gamepad_id : Int,
  strong_motor : Float,
  weak_motor : Float,
  duration_ms : Int64,
) -> GamepadRumbleResult {
  let gamepad = match connected_gamepad(gamepad_id) {
    Some(gamepad) => gamepad
    None => return NotFound
  }
  if !gamepad_ff_supported_for_rumble(gamepad) {
    return Unsupported
  }

  let strong = clamp_rumble_motor(strong_motor)
  let weak = clamp_rumble_motor(weak_motor)
  let clamped_duration_ms = if duration_ms <= 0L { 0L } else { duration_ms }

  if gilrs_runtime_state.record_commands {
    recorded_gamepad_rumble_commands.push({
      gamepad_id,
      strong_motor: Float::from_double(strong),
      weak_motor: Float::from_double(weak),
      duration_ms: clamped_duration_ms,
    })
    return Applied
  }

  let effect = @gamepad.EffectBuilder::new()
    .add_gamepad(gamepad)
    .duration(clamped_duration_ms)
    .rumble(strong, weak)
    .finish(ensure_gilrs()) catch {
      _ => return Unsupported
    }

  if strong == 0.0 && weak == 0.0 {
    effect.stop() catch {
      _ => return Unsupported
    }
  } else {
    effect.play() catch {
      _ => return Unsupported
    }
  }
  Applied
}

///|
pub fn gamepad_test_use_mock_gilrs(gilrs : @gamepad.Gil) -> Unit {
  gilrs_runtime_state.gilrs = Some(gilrs)
  connected_gamepad_ids.clear()
}

///|
pub fn gamepad_test_use_ff_mock(gamepad_count : Int) -> Unit {
  let gilrs = @gamepad.Gil::new_mock(gamepad_count)
  gamepad_test_use_mock_gilrs(gilrs)
  gilrs_runtime_state.ff_supported_override = Some(true)
}

///|
pub fn gamepad_test_set_mock_ff_supported(
  gamepad_id : Int,
  supported : Bool,
) -> Unit {
  ignore(gamepad_id)
  gilrs_runtime_state.ff_supported_override = Some(supported)
}

///|
pub fn gamepad_test_record_rumble_commands(enabled : Bool) -> Unit {
  gilrs_runtime_state.record_commands = enabled
  if !enabled {
    recorded_gamepad_rumble_commands.clear()
  }
}

///|
pub fn gamepad_test_take_recorded_rumble_commands() -> Array[
  GamepadRumbleCommand,
] {
  let commands = recorded_gamepad_rumble_commands.copy()
  recorded_gamepad_rumble_commands.clear()
  commands
}

///|
pub fn gamepad_test_reset_state() -> Unit {
  gilrs_runtime_state.gilrs = None
  connected_gamepad_ids.clear()
  gilrs_runtime_state.record_commands = false
  gilrs_runtime_state.ff_supported_override = None
  recorded_gamepad_rumble_commands.clear()
}

///|
fn gamepad_button_from_index(index : Int) -> @gamepad.Button {
  match index {
    0 => South
    1 => East
    2 => C
    3 => North
    4 => West
    5 => Z
    6 => LeftTrigger
    7 => RightTrigger
    8 => LeftTrigger2
    9 => RightTrigger2
    10 => Select
    11 => Start
    12 => Mode
    13 => LeftThumb
    14 => RightThumb
    15 => DPadUp
    16 => DPadDown
    17 => DPadLeft
    18 => DPadRight
    _ => Unknown
  }
}

///|
fn gamepad_axis_from_index(index : Int) -> @gamepad.Axis {
  match index {
    0 => LeftStickX
    1 => LeftStickY
    2 => LeftZ
    3 => RightStickX
    4 => RightStickY
    5 => RightZ
    6 => DPadX
    7 => DPadY
    _ => Unknown
  }
}

///|
pub fn gamepad_poll() -> Unit {
  refresh_gamepads()
}

///|
pub fn gamepad_count() -> Int {
  connected_gamepad_ids.length()
}

///|
pub fn gamepad_id(index : Int) -> Int {
  if index < 0 || index >= connected_gamepad_ids.length() {
    -1
  } else {
    connected_gamepad_ids[index]
  }
}

///|
pub fn gamepad_connected(gamepad_id : Int) -> Bool {
  connected_gamepad(gamepad_id) is Some(_)
}

///|
pub fn gamepad_ff_supported(gamepad_id : Int) -> Bool {
  match connected_gamepad(gamepad_id) {
    Some(gamepad) => gamepad_ff_supported_for_rumble(gamepad)
    None => false
  }
}

///|
pub fn gamepad_name_len(gamepad_id : Int) -> Int {
  match connected_gamepad(gamepad_id) {
    Some(gamepad) => gamepad.name().length()
    None => 0
  }
}

///|
pub fn gamepad_name_code_unit(gamepad_id~ : Int, offset~ : Int) -> Int {
  match connected_gamepad(gamepad_id) {
    Some(gamepad) => {
      let name = gamepad.name()
      if offset < 0 || offset >= name.length() {
        0
      } else {
        name.code_unit_at(offset).to_int()
      }
    }
    None => 0
  }
}

///|
pub fn gamepad_vendor_id(gamepad_id : Int) -> Int {
  match connected_gamepad(gamepad_id) {
    Some(gamepad) => gamepad.vendor_id().unwrap_or(-1)
    None => -1
  }
}

///|
pub fn gamepad_product_id(gamepad_id : Int) -> Int {
  match connected_gamepad(gamepad_id) {
    Some(gamepad) => gamepad.product_id().unwrap_or(-1)
    None => -1
  }
}

///|
pub fn gamepad_button_value(gamepad_id~ : Int, button~ : Int) -> Float {
  let button = gamepad_button_from_index(button)
  match connected_gamepad(gamepad_id) {
    Some(gamepad) =>
      match gamepad.button_data(button) {
        Some(value) => Float::from_double(value.value())
        None => 0.0
      }
    None => 0.0
  }
}

///|
pub fn gamepad_button_pressed(gamepad_id~ : Int, button~ : Int) -> Bool {
  let button = gamepad_button_from_index(button)
  match connected_gamepad(gamepad_id) {
    Some(gamepad) => gamepad.is_pressed(button)
    None => false
  }
}

///|
pub fn gamepad_axis_value(gamepad_id~ : Int, axis~ : Int) -> Float {
  let axis = gamepad_axis_from_index(axis)
  match connected_gamepad(gamepad_id) {
    Some(gamepad) => Float::from_double(gamepad.value(axis))
    None => 0.0
  }
}
