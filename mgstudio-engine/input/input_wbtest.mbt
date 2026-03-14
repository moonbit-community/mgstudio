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
let input_probe_before_set : @app.SystemSet = @app.system_set(
  "input.test.before_input_systems",
)

///|
let input_probe_after_set : @app.SystemSet = @app.system_set(
  "input.test.after_input_systems",
)

///|
let input_probe_before_ran_ref : Ref[Bool] = Ref::new(false)

///|
let input_probe_before_stage_ref : Ref[String] = Ref::new("none")

///|
let input_probe_after_stage_ref : Ref[String] = Ref::new("none")

///|
let input_probe_after_raw_event_count_ref : Ref[Int] = Ref::new(-1)

///|
let input_probe_update_stage_ref : Ref[String] = Ref::new("none")

///|
let input_probe_update_previous_snapshot_count_ref : Ref[Int] = Ref::new(-1)

///|
fn current_stage_label() -> String {
  match @app.current_schedule_stage() {
    Some(@app.PreUpdate) => "pre_update"
    Some(@app.Update) => "update"
    Some(@app.PostUpdate) => "post_update"
    Some(_) => "other"
    None => "none"
  }
}

///|
fn reset_input_runtime_state() -> Unit {
  current_gamepads_ref.val = []
  previous_gamepads_ref.val = []
  host_gamepad_entities_ref.val = []
  input_last_mouse_position_ref.val = None
  input_active_touches_ref.val = []
  input_primary_pointer_position_ref.val = None
  input_primary_pointer_delta_ref.val = @math.Vec2::new(0.0, 0.0)
  input_window_focused_event_cursor_ref.val = 0
  input_probe_before_ran_ref.val = false
  input_probe_before_stage_ref.val = "none"
  input_probe_after_stage_ref.val = "none"
  input_probe_after_raw_event_count_ref.val = -1
  input_probe_update_stage_ref.val = "none"
  input_probe_update_previous_snapshot_count_ref.val = -1
}

///|
fn input_probe_before_system(world : @ecs.World) -> Unit {
  input_probe_before_ran_ref.val = true
  input_probe_before_stage_ref.val = current_stage_label()
  world.clear_messages(raw_gamepad_event_message_key)
}

///|
fn input_probe_after_system(world : @ecs.World) -> Unit {
  input_probe_after_stage_ref.val = current_stage_label()
  input_probe_after_raw_event_count_ref.val = (try! world
  .message_reader(raw_gamepad_event_message_key, Ref::new(0))
  .read()).length()
}

///|
fn input_probe_update_system(_world : @ecs.World) -> Unit {
  input_probe_update_stage_ref.val = current_stage_label()
  input_probe_update_previous_snapshot_count_ref.val = previous_gamepads_ref.val.length()
}

///|
fn zero_floats(length : Int) -> Array[Float] {
  let values : Array[Float] = []
  for _ in 0..<length {
    values.push(0.0)
  }
  values
}

///|
fn synthetic_snapshot(entity : @core.Entity) -> GamepadSnapshot {
  {
    host_id: 998,
    entity,
    name: "Synthetic",
    vendor_id: None,
    product_id: None,
    connected: true,
    button_values: zero_floats(GAMEPAD_BUTTON_COUNT),
    axis_values: zero_floats(GAMEPAD_AXIS_COUNT),
  }
}

///|
test "input: InputSystems set gates pre-update polling systems" {
  reset_input_runtime_state()
  @gilrs.gamepad_test_reset_state()
  @gilrs.gamepad_test_use_ff_mock(1)

  let app = input_plugin(@time.time_plugin(@app.App::new(@ecs.World::new())))
    .add_pre_update_system_config(
      @app.system(input_probe_before_system).in_set(input_probe_before_set),
    )
    .add_pre_update_system_config(
      @app.system(input_probe_after_system).in_set(input_probe_after_set),
    )
    .configure_set(@app.PreUpdate, input_probe_before_set, before=[
      input_systems_set,
    ])
    .configure_set(@app.PreUpdate, input_probe_after_set, after=[
      input_systems_set,
    ])
    .run_once()

  inspect(input_probe_before_ran_ref.val, content="true")
  inspect(input_probe_before_stage_ref.val, content="pre_update")
  inspect(input_probe_after_stage_ref.val, content="pre_update")
  inspect(input_probe_after_raw_event_count_ref.val > 0, content="true")
  inspect(mapped_gamepad_entity(0) is Some(_), content="true")
  app |> ignore
}

///|
test "input: finish-frame runs after Update and clears previous gamepad snapshots" {
  reset_input_runtime_state()
  @gilrs.gamepad_test_reset_state()

  current_gamepads_ref.val = [synthetic_snapshot(@core.Entity::new(42, 1))]
  previous_gamepads_ref.val = []

  let app = input_plugin(@time.time_plugin(@app.App::new(@ecs.World::new())))
    .add_system(input_probe_update_system)
    .run_once()

  inspect(input_probe_update_stage_ref.val, content="update")
  inspect(input_probe_update_previous_snapshot_count_ref.val, content="1")
  inspect(current_gamepads_ref.val.length(), content="0")
  inspect(previous_gamepads_ref.val.length(), content="0")
  app |> ignore
}

///|
test "input: keyboard focus loss emits KeyboardFocusLost and WindowEvent" {
  reset_input_runtime_state()
  @gilrs.gamepad_test_reset_state()

  let world = @ecs.World::new()
  let window_entity = world.spawn()
  let window = @window.Window::default()
  window.focused = false
  try! world.set_component(window_entity, window)
  try! world.set_component(window_entity, @window.PrimaryWindow::{  })

  let mut app = input_plugin(@time.time_plugin(@app.App::new(world)))
    .add_message(@window.WindowFocused::message())
    .add_message(@window.WindowEvent::message())
  ignore(
    app
    .world()
    .send_message(@window.WindowFocused::message(), @window.WindowFocused::{
      window: window_entity,
      focused: false,
    }),
  )

  app = app.run_once()
  let focus_lost_reader = app
    .world()
    .message_reader(keyboard_focus_lost_message_key, Ref::new(0))
  inspect((try! focus_lost_reader.read()).length(), content="1")

  let window_event_reader = app
    .world()
    .message_reader(@window.WindowEvent::message(), Ref::new(0))
  let mut aggregate_focus_lost_count = 0
  let window_events = try! window_event_reader.read()
  for event in window_events {
    if event is @window.WindowEvent::KeyboardFocusLost(_) {
      aggregate_focus_lost_count = aggregate_focus_lost_count + 1
    }
  }
  inspect(aggregate_focus_lost_count, content="1")
}
