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
fn gamepad_test_app() -> @app.App[@ecs.World] {
  input_gamepad_plugin(@app.App::new(@ecs.World::new()))
}

///|
fn connected_test_info() -> GamepadConnectionInfo {
  GamepadConnectionInfo::new("Test gamepad", None, None)
}

///|
fn send_connection(world : @ecs.World, entity : @core.Entity) -> Unit {
  let event = GamepadConnectionEvent::new(
    entity,
    GamepadConnection::Connected(connected_test_info()),
  )
  world.send_message(gamepad_connection_event_message_key, event) |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Connection(event),
  )
  |> ignore
}

///|
fn send_disconnection(world : @ecs.World, entity : @core.Entity) -> Unit {
  let event = GamepadConnectionEvent::new(
    entity,
    GamepadConnection::Disconnected,
  )
  world.send_message(gamepad_connection_event_message_key, event) |> ignore
  world.send_message(
    raw_gamepad_event_message_key,
    RawGamepadEvent::Connection(event),
  )
  |> ignore
}

///|
fn send_raw_events(world : @ecs.World, events : Array[RawGamepadEvent]) -> Unit {
  for event in events {
    world.send_message(raw_gamepad_event_message_key, event) |> ignore
  }
}

///|
fn clear_gamepad_messages(world : @ecs.World) -> Unit {
  world.clear_messages(gamepad_event_message_key)
  world.clear_messages(raw_gamepad_event_message_key)
  world.clear_messages(gamepad_connection_event_message_key)
  world.clear_messages(raw_gamepad_axis_changed_event_message_key)
  world.clear_messages(gamepad_axis_changed_event_message_key)
  world.clear_messages(raw_gamepad_button_changed_event_message_key)
  world.clear_messages(gamepad_button_changed_event_message_key)
  world.clear_messages(gamepad_button_state_changed_event_message_key)
}

///|
fn[T : @json.FromJson] read_messages(
  world : @ecs.World,
  key : @ecs.MessageKey[T],
) -> Array[T] {
  try! world.message_reader(key, Ref::new(0)).read()
}

///|
fn world_gamepad(world : @ecs.World, entity : @core.Entity) -> Gamepad? {
  let gamepad : Gamepad? = try! @ecs.World::get_component(world, entity)
  gamepad
}

///|
fn world_gamepad_settings(
  world : @ecs.World,
  entity : @core.Entity,
) -> GamepadSettings? {
  let settings : GamepadSettings? = try! @ecs.World::get_component(
    world, entity,
  )
  settings
}

///|
test "input gamepad: connection event inserts gamepad and settings" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()

  inspect(world_gamepad(world, entity) is Some(_), content="false")
  send_connection(world, entity)
  app = app.run_once()

  inspect(world_gamepad(world, entity) is Some(_), content="true")
  inspect(world_gamepad_settings(world, entity) is Some(_), content="true")
}

///|
test "input gamepad: disconnection removes gamepad but preserves settings" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_disconnection(world, entity)
  app = app.run_once()

  inspect(world_gamepad(world, entity) is Some(_), content="false")
  inspect(world_gamepad_settings(world, entity) is Some(_), content="true")

  send_disconnection(world, entity)
  app = app.run_once()

  inspect(world_gamepad(world, entity) is Some(_), content="false")
  inspect(world_gamepad_settings(world, entity) is Some(_), content="true")
}

///|
test "input gamepad: connection and disconnection in the same frame keeps settings only" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()

  send_connection(world, entity)
  send_disconnection(world, entity)
  app = app.run_once()

  inspect(world_gamepad(world, entity) is Some(_), content="false")
  inspect(world_gamepad_settings(world, entity) is Some(_), content="true")
}

///|
test "input gamepad: reconnection preserves settings component state" {
  let button_settings = ButtonSettings::new(0.7F, 0.2F).unwrap()
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()

  send_connection(world, entity)
  app = app.run_once()

  inspect(
    try! @ecs.World::update_component(world, entity, fn(
      settings : GamepadSettings,
    ) {
      GamepadSettings::{ ..settings, default_button_settings: button_settings }
    }),
    content="true",
  )

  clear_gamepad_messages(world)
  send_disconnection(world, entity)
  app = app.run_once()
  send_connection(world, entity)
  app = app.run_once()

  let settings = world_gamepad_settings(world, entity).unwrap()
  inspect(settings.default_button_settings == button_settings, content="true")
}

///|
test "input gamepad: valid axis changes emit processed axis events" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::LeftStickY, 0.5F),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::RightStickX, 0.6F),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::RightZ, -0.4F),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::RightStickY, -0.8F),
    ),
  ])
  app = app.run_once()

  inspect(
    read_messages(world, gamepad_axis_changed_event_message_key).length(),
    content="4",
  )
}

///|
test "input gamepad: axis threshold filter ignores changes below threshold" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let settings = GamepadSettings::default().default_axis_settings
  let base_value = 0.5F

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        base_value,
      ),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        base_value + settings.threshold - 0.001F,
      ),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        base_value + settings.threshold + 0.001F,
      ),
    ),
  ])
  app = app.run_once()

  inspect(
    read_messages(world, gamepad_axis_changed_event_message_key).length(),
    content="2",
  )
}

///|
test "input gamepad: axis deadzone filter drops zeroed changes" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let settings = GamepadSettings::default().default_axis_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.deadzone_upperbound - 0.01F,
      ),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.deadzone_lowerbound + 0.01F,
      ),
    ),
  ])
  app = app.run_once()

  inspect(
    read_messages(world, gamepad_axis_changed_event_message_key).length(),
    content="0",
  )
}

///|
test "input gamepad: axis deadzone inputs are rounded to zero when crossing from live values" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let settings = GamepadSettings::default().default_axis_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::LeftStickX, 1.0F),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.deadzone_upperbound - 0.01F,
      ),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::LeftStickX, 1.0F),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.deadzone_lowerbound + 0.01F,
      ),
    ),
  ])
  app = app.run_once()

  let events = read_messages(world, gamepad_axis_changed_event_message_key)
  inspect(events.length(), content="4")
  inspect(events[0].value == 1.0F, content="true")
  inspect(events[1].value == 0.0F, content="true")
  inspect(events[2].value == 1.0F, content="true")
  inspect(events[3].value == 0.0F, content="true")
}

///|
test "input gamepad: axis livezone filter ignores clamped changes beyond the edges" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let settings = GamepadSettings::default().default_axis_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::LeftStickX, 1.0F),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.livezone_upperbound + 0.01F,
      ),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(entity, GamepadAxis::LeftStickX, -1.0F),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.livezone_lowerbound - 0.01F,
      ),
    ),
  ])
  app = app.run_once()

  inspect(
    read_messages(world, gamepad_axis_changed_event_message_key).length(),
    content="2",
  )
}

///|
test "input gamepad: axis livezone values are rounded to the extremes" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let settings = GamepadSettings::default().default_axis_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.livezone_upperbound + 0.01F,
      ),
    ),
    RawGamepadEvent::Axis(
      RawGamepadAxisChangedEvent::new(
        entity,
        GamepadAxis::LeftStickX,
        settings.livezone_lowerbound - 0.01F,
      ),
    ),
  ])
  app = app.run_once()

  let events = read_messages(world, gamepad_axis_changed_event_message_key)
  inspect(events.length(), content="2")
  inspect(events[0].value == 1.0F, content="true")
  inspect(events[1].value == -1.0F, content="true")
}

///|
test "input gamepad: button press emits state change and updates digital state" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let digital_settings = GamepadSettings::default().default_button_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.press_threshold,
      ),
    ),
  ])
  app = app.run_once()

  let state_events = read_messages(
    world, gamepad_button_state_changed_event_message_key,
  )
  inspect(state_events.length(), content="1")
  inspect(state_events[0].button, content="DPadDown")
  inspect(state_events[0].state, content="Pressed")
  inspect(
    world_gamepad(world, entity).unwrap().pressed(GamepadButton::DPadDown),
    content="true",
  )

  clear_gamepad_messages(world)
  app = app.run_once()

  inspect(
    read_messages(world, gamepad_button_state_changed_event_message_key).length(),
    content="0",
  )
  inspect(
    world_gamepad(world, entity).unwrap().pressed(GamepadButton::DPadDown),
    content="true",
  )
}

///|
test "input gamepad: just_pressed lasts for one frame" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let digital_settings = GamepadSettings::default().default_button_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.press_threshold,
      ),
    ),
  ])
  app = app.run_once()

  inspect(
    world_gamepad(world, entity).unwrap().just_pressed(GamepadButton::DPadDown),
    content="true",
  )
  clear_gamepad_messages(world)
  app = app.run_once()
  inspect(
    world_gamepad(world, entity).unwrap().just_pressed(GamepadButton::DPadDown),
    content="false",
  )
}

///|
test "input gamepad: button release emits state change and clears digital state" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let digital_settings = GamepadSettings::default().default_button_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.press_threshold,
      ),
    ),
  ])
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.release_threshold - 0.01F,
      ),
    ),
  ])
  app = app.run_once()

  let state_events = read_messages(
    world, gamepad_button_state_changed_event_message_key,
  )
  inspect(state_events.length(), content="1")
  inspect(state_events[0].state, content="Released")
  inspect(
    world_gamepad(world, entity).unwrap().pressed(GamepadButton::DPadDown),
    content="false",
  )

  clear_gamepad_messages(world)
  app = app.run_once()
  inspect(
    read_messages(world, gamepad_button_state_changed_event_message_key).length(),
    content="0",
  )
}

///|
test "input gamepad: just_released lasts for one frame" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let digital_settings = GamepadSettings::default().default_button_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.press_threshold,
      ),
    ),
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.release_threshold - 0.01F,
      ),
    ),
  ])
  app = app.run_once()

  inspect(
    world_gamepad(world, entity).unwrap().just_released(GamepadButton::DPadDown),
    content="true",
  )
  clear_gamepad_messages(world)
  app = app.run_once()
  inspect(
    world_gamepad(world, entity).unwrap().just_released(GamepadButton::DPadDown),
    content="false",
  )
}

///|
test "input gamepad: button axis filtering matches bevy analog and digital counts" {
  let mut app = gamepad_test_app()
  let world = app.world()
  let entity = world.spawn_empty()
  let digital_settings = GamepadSettings::default().default_button_settings
  let analog_settings = GamepadSettings::default().default_button_axis_settings

  send_connection(world, entity)
  app = app.run_once()
  clear_gamepad_messages(world)

  send_raw_events(world, [
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.press_threshold,
      ),
    ),
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.release_threshold,
      ),
    ),
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.release_threshold - analog_settings.threshold * 1.01F,
      ),
    ),
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.release_threshold - analog_settings.threshold * 1.5F,
      ),
    ),
    RawGamepadEvent::Button(
      RawGamepadButtonChangedEvent::new(
        entity,
        GamepadButton::DPadDown,
        digital_settings.release_threshold - analog_settings.threshold * 2.02F,
      ),
    ),
  ])
  app = app.run_once()

  inspect(
    read_messages(world, gamepad_button_state_changed_event_message_key).length(),
    content="2",
  )
  inspect(
    read_messages(world, gamepad_button_changed_event_message_key).length(),
    content="4",
  )
}
