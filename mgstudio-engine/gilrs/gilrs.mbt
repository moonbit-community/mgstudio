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
let gilrs_ref : Ref[@gamepad.Gilrs?] = Ref::new(None)

///|
let connected_gamepad_ids_ref : Ref[Array[Int]] = Ref::new([])

///|
fn ensure_gilrs() -> @gamepad.Gilrs {
  match gilrs_ref.val {
    Some(gilrs) => gilrs
    None => {
      let gilrs = @gamepad.Gilrs::new()
      gilrs_ref.val = Some(gilrs)
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
  connected_gamepad_ids_ref.val = connected_ids
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
let record_gamepad_rumble_commands_ref : Ref[Bool] = Ref::new(false)

///|
let gamepad_test_ff_supported_override_ref : Ref[Bool?] = Ref::new(None)

///|
let recorded_gamepad_rumble_commands_ref : Ref[Array[GamepadRumbleCommand]] = Ref::new([],
)

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
  match gamepad_test_ff_supported_override_ref.val {
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
    None => return GamepadRumbleResult::NotFound
  }
  if !gamepad_ff_supported_for_rumble(gamepad) {
    return GamepadRumbleResult::Unsupported
  }

  let strong = clamp_rumble_motor(strong_motor)
  let weak = clamp_rumble_motor(weak_motor)
  let clamped_duration_ms = if duration_ms <= 0L { 0L } else { duration_ms }

  if record_gamepad_rumble_commands_ref.val {
    recorded_gamepad_rumble_commands_ref.val.push({
      gamepad_id,
      strong_motor: Float::from_double(strong),
      weak_motor: Float::from_double(weak),
      duration_ms: clamped_duration_ms,
    })
    return GamepadRumbleResult::Applied
  }

  let effect = @gamepad.EffectBuilder::new()
    .add_gamepad(gamepad)
    .duration(clamped_duration_ms)
    .rumble(strong, weak)
    .finish(ensure_gilrs()) catch {
      _ => return GamepadRumbleResult::Unsupported
    }

  if strong == 0.0 && weak == 0.0 {
    effect.stop() catch {
      _ => return GamepadRumbleResult::Unsupported
    }
  } else {
    effect.play() catch {
      _ => return GamepadRumbleResult::Unsupported
    }
  }
  GamepadRumbleResult::Applied
}

///|
pub fn gamepad_test_use_mock_gilrs(gilrs : @gamepad.Gilrs) -> Unit {
  gilrs_ref.val = Some(gilrs)
  connected_gamepad_ids_ref.val = []
}

///|
pub fn gamepad_test_use_ff_mock(gamepad_count : Int) -> Unit {
  let gilrs = @gamepad.Gilrs::new_mock(gamepad_count)
  gamepad_test_use_mock_gilrs(gilrs)
  gamepad_test_ff_supported_override_ref.val = Some(true)
}

///|
pub fn gamepad_test_set_mock_ff_supported(
  gamepad_id : Int,
  supported : Bool,
) -> Unit {
  ignore(gamepad_id)
  gamepad_test_ff_supported_override_ref.val = Some(supported)
}

///|
pub fn gamepad_test_record_rumble_commands(enabled : Bool) -> Unit {
  record_gamepad_rumble_commands_ref.val = enabled
  if !enabled {
    recorded_gamepad_rumble_commands_ref.val.clear()
  }
}

///|
pub fn gamepad_test_take_recorded_rumble_commands() -> Array[
  GamepadRumbleCommand,
] {
  let commands = recorded_gamepad_rumble_commands_ref.val
  recorded_gamepad_rumble_commands_ref.val = []
  commands
}

///|
pub fn gamepad_test_reset_state() -> Unit {
  gilrs_ref.val = None
  connected_gamepad_ids_ref.val = []
  record_gamepad_rumble_commands_ref.val = false
  gamepad_test_ff_supported_override_ref.val = None
  recorded_gamepad_rumble_commands_ref.val.clear()
}

///|
fn gamepad_button_from_index(index : Int) -> @gamepad.Button {
  match index {
    0 => @gamepad.Button::South
    1 => @gamepad.Button::East
    2 => @gamepad.Button::C
    3 => @gamepad.Button::North
    4 => @gamepad.Button::West
    5 => @gamepad.Button::Z
    6 => @gamepad.Button::LeftTrigger
    7 => @gamepad.Button::RightTrigger
    8 => @gamepad.Button::LeftTrigger2
    9 => @gamepad.Button::RightTrigger2
    10 => @gamepad.Button::Select
    11 => @gamepad.Button::Start
    12 => @gamepad.Button::Mode
    13 => @gamepad.Button::LeftThumb
    14 => @gamepad.Button::RightThumb
    15 => @gamepad.Button::DPadUp
    16 => @gamepad.Button::DPadDown
    17 => @gamepad.Button::DPadLeft
    18 => @gamepad.Button::DPadRight
    _ => @gamepad.Button::Unknown
  }
}

///|
fn gamepad_axis_from_index(index : Int) -> @gamepad.Axis {
  match index {
    0 => @gamepad.Axis::LeftStickX
    1 => @gamepad.Axis::LeftStickY
    2 => @gamepad.Axis::LeftZ
    3 => @gamepad.Axis::RightStickX
    4 => @gamepad.Axis::RightStickY
    5 => @gamepad.Axis::RightZ
    6 => @gamepad.Axis::DPadX
    7 => @gamepad.Axis::DPadY
    _ => @gamepad.Axis::Unknown
  }
}

///|
pub fn gamepad_poll() -> Unit {
  refresh_gamepads()
}

///|
pub fn gamepad_count() -> Int {
  connected_gamepad_ids_ref.val.length()
}

///|
pub fn gamepad_id(index : Int) -> Int {
  if index < 0 || index >= connected_gamepad_ids_ref.val.length() {
    -1
  } else {
    connected_gamepad_ids_ref.val[index]
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
