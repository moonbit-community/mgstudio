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
/// Port of `bevy/examples/input/gamepad_input_events.rs`.
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system_param4(gamepad_events)
  .add_system_param(gamepad_ordered_events)
  .run()
}

///|
fn gamepad_events(
  connection_events : @ecs.MessageReader[@input.GamepadConnectionEvent],
  axis_changed_events : @ecs.MessageReader[@input.GamepadAxisChangedEvent],
  button_changed_events : @ecs.MessageReader[@input.GamepadButtonChangedEvent],
  button_input_events : @ecs.MessageReader[
    @input.GamepadButtonStateChangedEvent,
  ],
) -> Unit {
  for connection_event in (try! connection_events.read()) {
    log_line(format_connection_event(connection_event))
  }
  for axis_changed_event in (try! axis_changed_events.read()) {
    log_line(
      "\{format_axis(axis_changed_event.axis)} of \{axis_changed_event.gamepad_id} is changed to \{axis_changed_event.value}",
    )
  }
  for button_changed_event in (try! button_changed_events.read()) {
    log_line(
      "\{format_button(button_changed_event.button)} of \{button_changed_event.gamepad_id} is changed to \{button_changed_event.value}",
    )
  }
  for button_input_event in (try! button_input_events.read()) {
    log_line(format_button_state_changed_event(button_input_event))
  }
}

///|
// If you require in-frame relative event ordering, you can also read the
// `GamepadEvent` stream directly.
fn gamepad_ordered_events(
  gamepad_events : @ecs.MessageReader[@input.GamepadEvent],
) -> Unit {
  for gamepad_event in (try! gamepad_events.read()) {
    match gamepad_event {
      Connection(connection_event) =>
        log_line(format_connection_event(connection_event))
      Button(button_event) =>
        log_line(format_button_changed_event(button_event))
      Axis(axis_event) => log_line(format_axis_changed_event(axis_event))
    }
  }
}

///|
fn format_button_state_changed_event(
  event : @input.GamepadButtonStateChangedEvent,
) -> String {
  "GamepadButtonStateChangedEvent(gamepad=\{event.gamepad_id}, button=\{format_button(event.button)}, pressed=\{event.pressed})"
}

///|
fn format_button(button : @input.GamepadButton) -> String {
  match button {
    South => "South"
    East => "East"
    C => "C"
    North => "North"
    West => "West"
    Z => "Z"
    LeftTrigger => "LeftTrigger"
    RightTrigger => "RightTrigger"
    LeftTrigger2 => "LeftTrigger2"
    RightTrigger2 => "RightTrigger2"
    Select => "Select"
    Start => "Start"
    Mode => "Mode"
    LeftThumb => "LeftThumb"
    RightThumb => "RightThumb"
    DPadUp => "DPadUp"
    DPadDown => "DPadDown"
    DPadLeft => "DPadLeft"
    DPadRight => "DPadRight"
    Unknown => "Unknown"
  }
}

///|
fn format_axis(axis : @input.GamepadAxis) -> String {
  match axis {
    LeftStickX => "LeftStickX"
    LeftStickY => "LeftStickY"
    LeftZ => "LeftZ"
    RightStickX => "RightStickX"
    RightStickY => "RightStickY"
    RightZ => "RightZ"
    DPadX => "DPadX"
    DPadY => "DPadY"
    Unknown => "Unknown"
  }
}

///|
fn format_axis_changed_event(axis : @input.GamepadAxisChangedEvent) -> String {
  "GamepadAxisChangedEvent(gamepad=\{axis.gamepad_id}, axis=\{format_axis(axis.axis)}, value=\{axis.value})"
}

///|
fn maybe_int_text(value : Int?) -> String {
  if value is Some(v) {
    v.to_string()
  } else {
    "unknown"
  }
}

///|
fn format_connection_event(
  connection : @input.GamepadConnectionEvent,
) -> String {
  let id = connection.gamepad_id
  match connection.connection {
    Connected(info) =>
      "GamepadConnectionEvent(gamepad=\{id}, connected=true, name=\{info.name}, vendor=\{maybe_int_text(info.vendor_id)}, product=\{maybe_int_text(info.product_id)})"
    Disconnected => "GamepadConnectionEvent(gamepad=\{id}, connected=false)"
  }
}

///|
fn format_button_changed_event(
  button : @input.GamepadButtonChangedEvent,
) -> String {
  "GamepadButtonChangedEvent(gamepad=\{button.gamepad_id}, button=\{format_button(button.button)}, value=\{button.value})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[gamepad_input_events] " + text)
}
