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
fn zero_button_values() -> Array[Float] {
  let values : Array[Float] = []
  for _ in 0..<GAMEPAD_BUTTON_COUNT {
    values.push(0.0F)
  }
  values
}

///|
fn zero_button_pressed() -> Array[Bool] {
  let values : Array[Bool] = []
  for _ in 0..<GAMEPAD_BUTTON_COUNT {
    values.push(false)
  }
  values
}

///|
fn zero_axis_values() -> Array[Float] {
  let values : Array[Float] = []
  for _ in 0..<GAMEPAD_AXIS_COUNT {
    values.push(0.0F)
  }
  values
}

///|
fn snapshot_with_changes(
  gamepad_id : Int,
  button : GamepadButton,
  button_value : Float,
  button_pressed : Bool,
  axis : GamepadAxis,
  axis_value : Float,
) -> GamepadSnapshot {
  let button_values = zero_button_values()
  let button_states = zero_button_pressed()
  let axis_values = zero_axis_values()
  button_values[button.to_index()] = button_value
  button_states[button.to_index()] = button_pressed
  axis_values[axis.to_index()] = axis_value
  GamepadSnapshot::{
    id: gamepad_id,
    name: "Test Pad",
    vendor_id: Some(1000),
    product_id: Some(2000),
    connected: true,
    button_values,
    button_pressed: button_states,
    axis_values,
  }
}

///|
fn gamepad_processing_test_app() -> @app.App[@ecs.World] {
  input_gamepad_plugin(@app.App::new(@ecs.World::new())).add_pre_update_system_config(
    @app.system(@app.system_param2(gamepad_event_processing_system)).in_set(
      input_gamepad_event_processing_system_set,
    ),
  )
}

///|
fn reset_gamepad_processing_state() -> Unit {
  current_gamepads_ref.val = []
  previous_gamepads_ref.val = []
}

///|
test "input gamepad: processing raw button and axis events preserves ordered stream" {
  reset_gamepad_processing_state()
  let gamepad_id = 7
  let button = GamepadButton::South
  let axis = GamepadAxis::LeftStickX
  previous_gamepads_ref.val = [
    snapshot_with_changes(gamepad_id, button, 0.0F, false, axis, 0.0F),
  ]
  current_gamepads_ref.val = [
    snapshot_with_changes(gamepad_id, button, 1.0F, true, axis, 0.75F),
  ]

  let mut app = gamepad_processing_test_app()
  let world = app.world()
  ignore(
    world.send_message(
      raw_gamepad_event_message_key,
      RawGamepadEvent::Button(
        RawGamepadButtonChangedEvent::new(gamepad_id, button, 1.0F),
      ),
    ),
  )
  ignore(
    world.send_message(
      raw_gamepad_event_message_key,
      RawGamepadEvent::Axis(
        RawGamepadAxisChangedEvent::new(gamepad_id, axis, 0.75F),
      ),
    ),
  )

  app = app.run_once()

  let button_events = try! world
    .message_reader(gamepad_button_changed_event_message_key, Ref::new(0))
    .read()
  inspect(button_events.length(), content="1")
  inspect(button_events[0].gamepad_id, content="7")
  inspect(button_events[0].button, content="South")
  inspect(button_events[0].state, content="Pressed")
  inspect(button_events[0].value, content="1")

  let button_state_events = try! world
    .message_reader(gamepad_button_state_changed_event_message_key, Ref::new(0))
    .read()
  inspect(button_state_events.length(), content="1")
  inspect(button_state_events[0].state, content="Pressed")

  let axis_events = try! world
    .message_reader(gamepad_axis_changed_event_message_key, Ref::new(0))
    .read()
  inspect(axis_events.length(), content="1")
  inspect(axis_events[0].gamepad_id, content="7")
  inspect(axis_events[0].axis, content="LeftStickX")
  inspect(axis_events[0].value, content="0.75")

  let ordered_events = try! world
    .message_reader(gamepad_event_message_key, Ref::new(0))
    .read()
  inspect(ordered_events.length(), content="2")
  match ordered_events[0] {
    Button(event) => {
      inspect(event.button, content="South")
      inspect(event.state, content="Pressed")
    }
    _ => fail("expected ordered button event")
  }
  match ordered_events[1] {
    Axis(event) => {
      inspect(event.axis, content="LeftStickX")
      inspect(event.value, content="0.75")
    }
    _ => fail("expected ordered axis event")
  }
}

///|
test "input gamepad: processing raw button event only emits digital event on state change" {
  reset_gamepad_processing_state()
  let gamepad_id = 11
  let button = GamepadButton::East
  previous_gamepads_ref.val = [
    snapshot_with_changes(
      gamepad_id,
      button,
      0.4F,
      true,
      GamepadAxis::LeftStickX,
      0.0F,
    ),
  ]
  current_gamepads_ref.val = [
    snapshot_with_changes(
      gamepad_id,
      button,
      0.8F,
      true,
      GamepadAxis::LeftStickX,
      0.0F,
    ),
  ]

  let mut app = gamepad_processing_test_app()
  let world = app.world()
  ignore(
    world.send_message(
      raw_gamepad_event_message_key,
      RawGamepadEvent::Button(
        RawGamepadButtonChangedEvent::new(gamepad_id, button, 0.8F),
      ),
    ),
  )

  app = app.run_once()

  let button_state_events = try! world
    .message_reader(gamepad_button_state_changed_event_message_key, Ref::new(0))
    .read()
  inspect(button_state_events.length(), content="0")

  let button_events = try! world
    .message_reader(gamepad_button_changed_event_message_key, Ref::new(0))
    .read()
  inspect(button_events.length(), content="1")
  inspect(button_events[0].state, content="Pressed")
  inspect(button_events[0].value == 0.8F, content="true")
}

///|
test "input gamepad: processing raw connection event forwards to ordered gamepad stream" {
  reset_gamepad_processing_state()
  let mut app = gamepad_processing_test_app()
  let world = app.world()
  ignore(
    world.send_message(
      raw_gamepad_event_message_key,
      RawGamepadEvent::Connection(
        GamepadConnectionEvent::new(
          3,
          GamepadConnection::Connected(
            GamepadConnectionInfo::new("Connected Pad", Some(12), Some(34)),
          ),
        ),
      ),
    ),
  )

  app = app.run_once()

  let ordered_events = try! world
    .message_reader(gamepad_event_message_key, Ref::new(0))
    .read()
  inspect(ordered_events.length(), content="1")
  match ordered_events[0] {
    Connection(event) => {
      inspect(event.gamepad_id, content="3")
      match event.connection {
        Connected(info) => {
          inspect(info.name, content="Connected Pad")
          inspect(info.vendor_id, content="Some(12)")
          inspect(info.product_id, content="Some(34)")
        }
        Disconnected => fail("expected connected gamepad")
      }
    }
    _ => fail("expected ordered connection event")
  }
}
