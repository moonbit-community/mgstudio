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
fn read_winit_monitors(world : @ecs.World) -> WinitMonitors? {
  try world.get_resource(WinitMonitors::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn read_winit_windows(world : @ecs.World) -> WinitWindows? {
  try world.get_resource(WinitWindows::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn read_monitor_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> @window.Monitor? {
  try! world.get_component(entity)
}

///|
fn has_primary_monitor(world : @ecs.World, entity : @core.Entity) -> Bool {
  match (try! world.get_component(entity) : @window.PrimaryMonitor?) {
    Some(_) => true
    None => false
  }
}

///|
fn read_keyboard_focus_lost(
  world : @ecs.World,
) -> Array[@window.KeyboardFocusLost] {
  let reader = world.message_reader(
    @window.ecs_key_keyboard_focus_lost,
    Ref::new(0),
  )
  try! reader.read()
}

///|
fn read_window_closing(world : @ecs.World) -> Array[@window.WindowClosing] {
  let reader = world.message_reader(@window.ecs_key_window_closing, Ref::new(0))
  try! reader.read()
}

///|
fn read_window_closed(world : @ecs.World) -> Array[@window.WindowClosed] {
  let reader = world.message_reader(@window.ecs_key_window_closed, Ref::new(0))
  try! reader.read()
}

///|
fn read_window_destroyed(world : @ecs.World) -> Array[@window.WindowDestroyed] {
  let reader = world.message_reader(
    @window.ecs_key_window_destroyed,
    Ref::new(0),
  )
  try! reader.read()
}

///|
test "winit: plugin replacement id aligns with bevy_winit" {
  let plugin = WinitPlugin::default()
  inspect(plugin.replacement_id(), content=WINIT_PLUGIN_ID)
}

///|
test "winit: plugin forwards run_on_any_thread setting to native backend" {
  @windowing.set_event_loop_any_thread(false)
  let _app = winit_plugin_with(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
    WinitPlugin::{ run_on_any_thread: true },
  ).run_once()
  inspect(@windowing.event_loop_any_thread_requested(), content="true")
  @windowing.set_event_loop_any_thread(false)
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
test "winit: plugin initializes bevy-aligned monitors resource" {
  let native_monitor_count = @windowing.available_monitors().length()
  let app_with_winit = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  let monitors = match read_winit_monitors(app_with_winit.world()) {
    Some(monitors) => monitors
    None => abort("missing WinitMonitors resource")
  }

  assert_eq(monitors.monitors.length(), native_monitor_count)
  if native_monitor_count == 0 {
    inspect(monitors.nth(0) is None, content="true")
  } else {
    inspect(monitors.nth(0) is Some(_), content="true")
  }
}

///|
test "winit: plugin initializes bevy-aligned windows resource" {
  let app_with_winit = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  let windows = match read_winit_windows(app_with_winit.world()) {
    Some(windows) => windows
    None => abort("missing WinitWindows resource")
  }
  let host_entries = @window.window_host_entries(app_with_winit.world())
  assert_eq(windows.windows.length(), host_entries.length())
}

///|
test "winit: windows resource mirrors host window runtime mapping" {
  let app = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  let world = app.world()
  let windows = match read_winit_windows(world) {
    Some(windows) => windows
    None => abort("missing WinitWindows resource")
  }
  let host_entries = @window.window_host_entries(world)

  assert_eq(windows.windows.length(), host_entries.length())
  for entry in host_entries {
    assert_eq(windows.get_window(entry.entity), Some(entry.host_window))
    inspect(
      windows.get_window_entity(entry.host_window) is Some(entity) &&
      entity == entry.entity,
      content="true",
    )
  }
}

///|
test "winit: windows resource supports remove by entity" {
  let world = @ecs.World::new()
  let entity_a = world.spawn()
  let entity_b = world.spawn()
  let windows = WinitWindows::default()
  windows.windows.push(WinitWindowEntry::new(entity_a, 101))
  windows.windows.push(WinitWindowEntry::new(entity_b, 202))

  assert_eq(windows.remove_window(entity_a), Some(101))
  assert_eq(windows.get_window(entity_a), None)
  inspect(windows.get_window_entity(101) is None, content="true")
  assert_eq(windows.get_window(entity_b), Some(202))
  assert_eq(windows.windows.length(), 1)
}

///|
test "winit: monitors resource provides nth and find_entity accessors" {
  let world = @ecs.World::new()
  let missing_entity = world.spawn()
  let monitors = WinitMonitors::default()
  inspect(monitors.nth(0) is None, content="true")
  inspect(monitors.nth(-1) is None, content="true")
  inspect(monitors.find_entity(world.spawn()) is None, content="true")
  inspect(monitors.find_entity(missing_entity) is None, content="true")
}

///|
test "winit: select_monitor aligns with bevy monitor selection semantics" {
  let native_monitors = @windowing.available_monitors()
  if native_monitors.length() == 0 {
    inspect(true, content="true")
    return
  }

  let world = @ecs.World::new()
  let entity_a = world.spawn()
  let entity_b = world.spawn()
  let monitor_a = native_monitors[0]
  let monitor_b = if native_monitors.length() > 1 {
    native_monitors[1]
  } else {
    native_monitors[0]
  }
  let monitors = WinitMonitors::default()
  monitors.monitors.push(WinitMonitorEntry::new(monitor_a, entity_a))
  monitors.monitors.push(WinitMonitorEntry::new(monitor_b, entity_b))
  let primary_monitor = @windowing.primary_monitor()

  assert_eq(
    select_monitor(
      monitors,
      primary_monitor,
      Some(monitor_b),
      @window.MonitorSelection::Current,
    ),
    Some(monitor_b),
  )
  assert_eq(
    select_monitor(
      monitors,
      primary_monitor,
      Some(monitor_b),
      @window.MonitorSelection::Primary,
    ),
    primary_monitor,
  )
  assert_eq(
    select_monitor(
      monitors,
      primary_monitor,
      Some(monitor_b),
      @window.MonitorSelection::Index(1),
    ),
    Some(monitor_b),
  )
  assert_eq(
    select_monitor(
      monitors,
      primary_monitor,
      Some(monitor_b),
      @window.MonitorSelection::Entity(entity_a),
    ),
    Some(monitor_a),
  )
  inspect(
    select_monitor(
      monitors,
      primary_monitor,
      Some(monitor_b),
      @window.MonitorSelection::Index(9),
    )
    is None,
    content="true",
  )
  inspect(
    select_monitor(
      monitors,
      primary_monitor,
      Some(monitor_b),
      @window.MonitorSelection::Entity(world.spawn()),
    )
    is None,
    content="true",
  )
  inspect(
    select_monitor(
      monitors,
      primary_monitor,
      None,
      @window.MonitorSelection::Current,
    )
    is None,
    content="true",
  )
}

///|
test "winit: get_selected_videomode aligns with bevy fullscreen selection" {
  let native_monitors = @windowing.available_monitors()
  if native_monitors.length() == 0 {
    inspect(true, content="true")
    return
  }

  let monitor = native_monitors[0]
  match monitor.current_video_mode() {
    Some(current_mode) =>
      assert_eq(
        get_selected_videomode(monitor, @window.VideoModeSelection::Current),
        Some(current_mode),
      )
    None =>
      inspect(
        get_selected_videomode(monitor, @window.VideoModeSelection::Current)
        is None,
        content="true",
      )
  }
  let modes = monitor.video_modes()
  if modes.length() > 0 {
    let mode = modes[0]
    assert_eq(
      get_selected_videomode(
        monitor,
        @window.VideoModeSelection::Specific(mode),
      ),
      Some(mode),
    )
  }
}

///|
test "winit: monitor sync mirrors native monitor snapshot" {
  let native_monitors = @windowing.available_monitors()
  let native_primary = @windowing.primary_monitor()
  let app = winit_plugin(
    @window.window_plugin(@app.App::new(@ecs.World::new())),
  ).run_once()
  let world = app.world()
  let monitors = match read_winit_monitors(world) {
    Some(monitors) => monitors
    None => abort("missing WinitMonitors resource")
  }

  assert_eq(monitors.monitors.length(), native_monitors.length())

  let mut primary_count = 0
  for entry in monitors.monitors {
    assert_true(world.is_alive(entry.entity))
    assert_true(read_monitor_component(world, entry.entity) is Some(_))

    let mut found = false
    for native_monitor in native_monitors {
      if native_monitor == entry.monitor {
        found = true
      }
    }
    assert_true(found)

    if has_primary_monitor(world, entry.entity) {
      primary_count = primary_count + 1
    }
  }

  match native_primary {
    Some(primary_monitor) => {
      inspect(primary_count, content="1")
      let mut primary_matched = false
      for entry in monitors.monitors {
        if has_primary_monitor(world, entry.entity) &&
          entry.monitor == primary_monitor {
          primary_matched = true
        }
      }
      assert_true(primary_matched)
    }
    None => inspect(primary_count, content="0")
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
test "winit: keyboard focus-loss check runs in winit plugin lifecycle" {
  @windowing.set_accessibility_requested(false)
  ignore(@windowing.take_accessibility_actions())

  let world = @ecs.World::new()
  let window_entity = world.spawn()
  let window = @window.Window::default()
  window.focused = false
  try! world.set_component(window_entity, window)
  try! world.set_component(window_entity, @window.PrimaryWindow::{  })

  let mut app = winit_plugin(@window.window_plugin(@app.App::new(world)))
    .add_message(@window.ecs_key_keyboard_focus_lost)
    .add_message(@window.WindowFocused::message())
    .run_once()

  ignore(
    app
    .world()
    .send_message(@window.WindowFocused::message(), @window.WindowFocused::{
      window: window_entity,
      focused: false,
    }),
  )

  app = app.run_once()

  inspect(read_keyboard_focus_lost(app.world()).length(), content="1")

  let window_event_reader = app
    .world()
    .message_reader(@window.WindowEvent::message(), Ref::new(0))
  let window_events = try! window_event_reader.read()
  let mut focus_lost_count = 0
  for event in window_events {
    if event is @window.WindowEvent::KeyboardFocusLost(_) {
      focus_lost_count = focus_lost_count + 1
    }
  }
  inspect(focus_lost_count, content="1")
}

///|
test "winit: close request is despawned by Last-stage winit system" {
  let world = @ecs.World::new()
  let window_entity = world.spawn()
  try! world.set_component(window_entity, @window.Window::default())

  let mut app = winit_plugin(
    @window.window_plugin_with(@app.App::new(world), @window.WindowPlugin::{
      primary_window: None,
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::DontExit,
      close_when_requested: true,
    }),
  ).run_once()

  ignore(
    app
    .world()
    .send_message(@window.ecs_key_window_close_requested, @window.WindowCloseRequested::{
      window: window_entity,
    }),
  )

  app = app.run_once()

  inspect(app.world().is_alive(window_entity), content="false")
  inspect(read_window_closing(app.world()).length(), content="1")
  inspect(read_window_closed(app.world()).length(), content="1")
  inspect(read_window_destroyed(app.world()).length(), content="1")
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
