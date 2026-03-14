// Copyright 2026 International Digital Economy Academy
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
fn read_window_created(world : @ecs.World) -> Array[@window.WindowCreated] {
  let reader = world.message_reader(@window.ecs_key_window_created, Ref::new(0))
  try! reader.read()
}

///|
fn read_raw_winit_window_events(
  world : @ecs.World,
  cursor : Ref[Int],
) -> Array[RawWinitWindowEvent] {
  let reader = world.message_reader(ecs_key_raw_winit_window_event, cursor)
  try! reader.read()
}

///|
fn read_action_requests(world : @ecs.World) -> Array[@a11y.ActionRequest] {
  let reader = world.message_reader(
    @a11y.ecs_msg_key_action_request,
    Ref::new(0),
  )
  try! reader.read()
}

///|
fn read_winit_settings(world : @ecs.World) -> WinitSettings? {
  try world.get_resource(WinitSettings::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
test "winit: plugin replacement id aligns with bevy_winit" {
  let plugin = WinitPlugin::default()
  inspect(plugin.replacement_id(), content=WINIT_PLUGIN_ID)
}

///|
test "winit: backend sync is owned by winit plugin" {
  let app_without_winit = @window.window_plugin(
    @app.App::new(@ecs.World::new()),
  ).run_once()
  inspect(read_window_created(app_without_winit.world()).length(), content="0")

  let app_with_winit = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  inspect(read_window_created(app_with_winit.world()).length(), content="1")
}

///|
test "winit: plugin initializes bevy-aligned default settings resource" {
  let app_with_winit = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  let settings = match read_winit_settings(app_with_winit.world()) {
    Some(settings) => settings
    None => abort("missing WinitSettings resource")
  }

  inspect(settings.update_mode(true), content="Continuous")
  match settings.update_mode(false) {
    Reactive(wait, react_to_device, react_to_user, react_to_window) => {
      inspect(
        wait.as_secs_f64() > 0.016 && wait.as_secs_f64() < 0.017,
        content="true",
      )
      inspect(react_to_device, content="false")
      inspect(react_to_user, content="true")
      inspect(react_to_window, content="true")
    }
    _ => abort("expected reactive unfocused mode")
  }
}

///|
test "winit: update mode constructors align with bevy settings semantics" {
  let reactive = UpdateMode::reactive(@core.Duration::from_secs(5L))
  match reactive {
    Reactive(wait, react_to_device, react_to_user, react_to_window) => {
      assert_eq(wait, @core.Duration::from_secs(5L))
      inspect(react_to_device, content="true")
      inspect(react_to_user, content="true")
      inspect(react_to_window, content="true")
    }
    _ => abort("expected reactive mode")
  }

  let low_power = UpdateMode::reactive_low_power(@core.Duration::from_secs(60L))
  match low_power {
    Reactive(wait, react_to_device, react_to_user, react_to_window) => {
      assert_eq(wait, @core.Duration::from_secs(60L))
      inspect(react_to_device, content="false")
      inspect(react_to_user, content="true")
      inspect(react_to_window, content="true")
    }
    _ => abort("expected reactive_low_power mode")
  }
}

///|
test "winit: typed raw winit events are published as messages" {
  let app = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  let world = app.world()
  let cursor = Ref::new(0)
  let writer = world.message_writer(ecs_key_raw_winit_window_event)

  assert_true(world.contains_message(ecs_key_raw_winit_window_event))

  ignore(
    writer.write(RawWinitWindowEvent::{ window_id: 21, event: CloseRequested }),
  )
  ignore(
    writer.write(RawWinitWindowEvent::{ window_id: 34, event: Focused(true) }),
  )

  let events = read_raw_winit_window_events(world, cursor)
  assert_eq(events.length(), 2)
  assert_eq(events[0].window_id, 21)
  match events[0].event {
    CloseRequested => ()
    _ => abort("expected CloseRequested raw event")
  }

  assert_eq(events[1].window_id, 34)
  match events[1].event {
    Focused(focused) => assert_true(focused)
    _ => abort("expected Focused raw event")
  }

  assert_eq(read_raw_winit_window_events(world, cursor).length(), 0)
}

///|
test "winit: plugin owns accessibility action propagation" {
  @windowing.set_accessibility_requested(false)
  ignore(@windowing.take_accessibility_actions())

  let target = @moon_accesskit.NodeId::from_u64(42UL)
  let request = @moon_accesskit.ActionRequest::new(
    @moon_accesskit.Action::Focus,
    @moon_accesskit.TreeId::root(),
    target,
  )

  let mut app = winit_plugin(
    @a11y.accessibility_plugin(
      @window.window_plugin(@app.App::new(@ecs.World::new())),
    ),
  )
  app = app.run_once()

  @windowing.enqueue_accessibility_action(request)
  app = app.run_once()

  let world = app.world()
  let actions = read_action_requests(world)
  let state = Ref::new(@a11y.get_a11y_state_resource(world).get().unwrap())
  let drained = @a11y.A11yState::drain_actions(state)

  assert_true(world.contains_message(@a11y.ecs_msg_key_action_request))
  assert_eq(actions.length(), 1)
  assert_eq(actions[0].action(), @moon_accesskit.Action::Focus)
  assert_eq(actions[0].target_node(), target)
  assert_eq(state.val.focused_node(), target)
  assert_eq(drained.length(), 1)
  assert_eq(drained[0].target_node(), target)
  assert_true(
    @a11y.get_accessibility_requested_resource(world).get().unwrap().get(),
  )
}

///|
test "winit: plugin owns accessibility update commit" {
  @windowing.set_accessibility_requested(true)
  ignore(@windowing.take_accessibility_actions())

  let mut app = winit_plugin(
    @a11y.accessibility_plugin(
      @window.window_plugin(@app.App::new(@ecs.World::new())),
    ),
  )
  app = app.run_once()

  let payload = "winit-a11y-commit"
  @a11y.a11y_host_apply_update_payload(payload)
  app = app.run_once()

  inspect(@windowing.last_accessibility_update_payload(), content=payload)
}
