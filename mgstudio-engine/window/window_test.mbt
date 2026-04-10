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
fn primary_window_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  try! world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.With::new(ecs_key_primary_window)),
  )
  .view(fn(_query_entity, entity) {
    if result.val is None {
      result.val = Some(entity)
    }
  })
  result.val
}

///|
fn window_component_value(world : @ecs.World, entity : @core.Entity) -> Window? {
  try! world.entity(entity).get()
}

///|
fn cursor_options_value(
  world : @ecs.World,
  entity : @core.Entity,
) -> CursorOptions? {
  try! world.entity(entity).get()
}

///|
fn cursor_icon_value(world : @ecs.World, entity : @core.Entity) -> CursorIcon? {
  try! world.entity(entity).get()
}

///|
fn raw_handle_holder_value(
  world : @ecs.World,
  entity : @core.Entity,
) -> RawHandleWrapperHolder? {
  try! world.entity(entity).get()
}

///|
fn has_closing_window(world : @ecs.World, entity : @core.Entity) -> Bool {
  match (try! world.entity(entity).get() : ClosingWindow?) {
    Some(_) => true
    None => false
  }
}

///|
fn monitor_component_value(
  world : @ecs.World,
  entity : @core.Entity,
) -> Monitor? {
  try! world.entity(entity).get()
}

///|
fn has_primary_monitor(world : @ecs.World, entity : @core.Entity) -> Bool {
  match (try! world.entity(entity).get() : PrimaryMonitor?) {
    Some(_) => true
    None => false
  }
}

///|
fn read_window_closing(world : @ecs.World) -> Array[WindowClosing] {
  let reader = world.message_reader(ecs_key_window_closing, Ref::new(0))
  try! reader.read()
}

///|
fn read_window_created(world : @ecs.World) -> Array[WindowCreated] {
  let reader = world.message_reader(ecs_key_window_created, Ref::new(0))
  try! reader.read()
}

///|
fn read_window_destroyed(world : @ecs.World) -> Array[WindowDestroyed] {
  let reader = world.message_reader(ecs_key_window_destroyed, Ref::new(0))
  try! reader.read()
}

///|
fn read_window_events(world : @ecs.World) -> Array[WindowEvent] {
  let reader = world.message_reader(ecs_key_window_event, Ref::new(0))
  try! reader.read()
}

///|
test "window: default window fields align with bevy defaults" {
  let window = Window::default()
  debug_inspect(window.composite_alpha_mode, content="Auto")
  debug_inspect(window.resize_constraints.min_width, content="180")
  debug_inspect(window.resize_constraints.min_height, content="120")
  debug_inspect(window.canvas, content="None")
  debug_inspect(window.skip_taskbar, content="false")
  debug_inspect(window.clip_children, content="true")
  debug_inspect(window.desired_maximum_frame_latency, content="None")
  debug_inspect(window.movable_by_window_background, content="false")
  debug_inspect(window.fullsize_content_view, content="false")
  debug_inspect(window.has_shadow, content="true")
  debug_inspect(window.titlebar_shown, content="true")
  debug_inspect(window.titlebar_transparent, content="false")
  debug_inspect(window.titlebar_show_title, content="true")
  debug_inspect(window.titlebar_show_buttons, content="true")
  debug_inspect(window.borderless_game, content="true")
  debug_inspect(window.prefers_home_indicator_hidden, content="false")
  debug_inspect(window.prefers_status_bar_hidden, content="false")
  debug_inspect(
    window.preferred_screen_edges_deferring_system_gestures,
    content="None",
  )
}

///|
test "window: resize constraints clamp invalid values" {
  let checked = WindowResizeConstraints::{
    min_width: 0.0F,
    min_height: 0.0F,
    max_width: 0.5F,
    max_height: -2.0F,
  }.check_constraints()

  debug_inspect(checked.min_width, content="1")
  debug_inspect(checked.min_height, content="1")
  debug_inspect(checked.max_width, content="1")
  debug_inspect(checked.max_height, content="1")
}

///|
test "window: plugin spawns configured primary window entity and messages" {
  let configured_window = Window::default()
  configured_window.title = "Configured Window"
  configured_window.resolution.set_physical_resolution(800, 600)
  configured_window.resolution.set_scale_factor(2.0F)
  configured_window.present_mode = PresentMode::AutoNoVsync
  configured_window.position = WindowPosition::new(12, 34)
  configured_window.mode = WindowMode::BorderlessFullscreen(
    MonitorSelection::Primary,
  )
  configured_window.resizable = false
  configured_window.enabled_buttons.minimize = false
  configured_window.enabled_buttons.maximize = false
  configured_window.enabled_buttons.close = false
  configured_window.decorations = false
  configured_window.transparent = true
  configured_window.focused = false
  configured_window.window_level = WindowLevel::AlwaysOnTop
  configured_window.window_theme = Some(WindowTheme::Dark)
  configured_window.visible = false
  let configured_cursor = CursorOptions::default()
  configured_cursor.visible = false
  configured_cursor.grab_mode = CursorGrabMode::GrabLocked

  let app = window_plugin_with(@app.App::new(@ecs.World::new()), WindowPlugin::{
    primary_window: Some(configured_window),
    primary_cursor_options: Some(configured_cursor),
    exit_condition: ExitCondition::DontExit,
    close_when_requested: false,
  }).run_once()

  debug_inspect(
    app.world().contains_message(ecs_key_window_created),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_event),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_request_redraw),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_close_requested),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_closing),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_closed),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_destroyed),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_cursor_moved),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_cursor_entered),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_cursor_left),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_file_drag_and_drop),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_moved),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_scale_factor_changed),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_backend_scale_factor_changed),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_focused),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_occluded),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_window_theme_changed),
    content="true",
  )
  debug_inspect(
    app.world().contains_message(ecs_key_app_lifecycle),
    content="true",
  )

  let entity = match primary_window_entity(app.world()) {
    Some(entity) => entity
    None => abort("missing primary window entity")
  }
  debug_inspect(app.world().is_alive(entity), content="true")

  let stored_window = match window_component_value(app.world(), entity) {
    Some(window) => window
    None => abort("missing window component")
  }
  debug_inspect(stored_window.title, content="Configured Window")
  debug_inspect(stored_window.physical_width(), content="800")
  debug_inspect(stored_window.physical_height(), content="600")
  debug_inspect(stored_window.scale_factor(), content="2")
  debug_inspect(stored_window.present_mode, content="AutoNoVsync")
  debug_inspect(
    stored_window.position == WindowPosition::new(12, 34),
    content="true",
  )
  debug_inspect(
    stored_window.mode ==
    WindowMode::BorderlessFullscreen(MonitorSelection::Primary),
    content="true",
  )
  debug_inspect(stored_window.resizable, content="false")
  debug_inspect(stored_window.enabled_buttons.minimize, content="false")
  debug_inspect(stored_window.enabled_buttons.maximize, content="false")
  debug_inspect(stored_window.enabled_buttons.close, content="false")
  debug_inspect(stored_window.decorations, content="false")
  debug_inspect(stored_window.transparent, content="true")
  debug_inspect(stored_window.focused, content="false")
  debug_inspect(stored_window.window_level.to_string(), content="AlwaysOnTop")
  debug_inspect(stored_window.window_theme.to_string(), content="Some(Dark)")
  debug_inspect(stored_window.visible, content="false")

  let stored_cursor = match cursor_options_value(app.world(), entity) {
    Some(cursor) => cursor
    None => abort("missing cursor options")
  }
  debug_inspect(stored_cursor.visible, content="false")
  debug_inspect(stored_cursor.grab_mode, content="GrabLocked")

  let raw_handle_holder = match raw_handle_holder_value(app.world(), entity) {
    Some(holder) => holder
    None => abort("missing raw handle holder")
  }
  debug_inspect(raw_handle_holder.handle.val is Some(_), content="false")
}

///|
test "window: compatibility helpers read and write ECS primary window state" {
  let configured_window = Window::default()
  configured_window.title = "Primary"
  configured_window.resolution.set_physical_resolution(320, 180)
  configured_window.resolution.set_scale_factor(2.0F)
  configured_window.position = WindowPosition::new(3, 4)
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(configured_window) |> ignore)
  try! (world.entity_mut(entity).insert_component(PrimaryWindow::{  }) |> ignore)

  let seen_width : Ref[Int] = Ref::new(0)
  let seen_height : Ref[Int] = Ref::new(0)
  let seen_position_x : Ref[Int] = Ref::new(0)
  let seen_position_y : Ref[Int] = Ref::new(0)
  let seen_scale_factor : Ref[Float] = Ref::new(0.0F)

  let app = @app.App::new(world).add_systems(
    @app.Update,
    @app.system(fn(_world : @ecs.World) {
      seen_width.val = window_width()
      seen_height.val = window_height()
      seen_position_x.val = window_position_x()
      seen_position_y.val = window_position_y()
      seen_scale_factor.val = window_scale_factor()
      window_set_title(title="Updated")
      window_set_size(width=640, height=360)
      window_set_resizable(resizable=false)
      window_set_visible(visible=false)
      window_set_decorations(decorations=false)
      window_set_transparent(transparent=true)
      window_set_cursor_visible(visible=false)
      window_set_cursor_grab_mode(mode=CursorGrabMode::GrabConfined)
      window_set_cursor_icon(icon=CursorIcon::from(SystemCursorIcon::EwResize))
      window_set_present_mode(mode=PresentMode::AutoNoVsync)
      window_set_enabled_buttons(minimize=false, maximize=false, close=false)
      window_set_window_level(level=WindowLevel::AlwaysOnTop)
      window_set_theme(theme=Some(WindowTheme::Dark))
      window_set_position(x=30, y=40)
      window_set_mode(
        mode=WindowMode::Fullscreen(
          MonitorSelection::Primary,
          VideoModeSelection::Current,
        ),
      )
    }),
  )
  let app = app.run_once()

  debug_inspect(seen_width.val, content="320")
  debug_inspect(seen_height.val, content="180")
  debug_inspect(seen_position_x.val, content="3")
  debug_inspect(seen_position_y.val, content="4")
  debug_inspect(seen_scale_factor.val, content="2")

  let stored_window = match window_component_value(app.world(), entity) {
    Some(window) => window
    None => abort("missing updated window")
  }
  debug_inspect(stored_window.title, content="Updated")
  debug_inspect(stored_window.physical_width(), content="640")
  debug_inspect(stored_window.physical_height(), content="360")
  debug_inspect(stored_window.present_mode, content="AutoNoVsync")
  debug_inspect(
    stored_window.position == WindowPosition::new(30, 40),
    content="true",
  )
  debug_inspect(
    stored_window.mode ==
    WindowMode::Fullscreen(
      MonitorSelection::Primary,
      VideoModeSelection::Current,
    ),
    content="true",
  )
  debug_inspect(stored_window.resizable, content="false")
  debug_inspect(stored_window.visible, content="false")
  debug_inspect(stored_window.decorations, content="false")
  debug_inspect(stored_window.transparent, content="true")
  debug_inspect(stored_window.enabled_buttons.minimize, content="false")
  debug_inspect(stored_window.enabled_buttons.maximize, content="false")
  debug_inspect(stored_window.enabled_buttons.close, content="false")
  debug_inspect(stored_window.window_level.to_string(), content="AlwaysOnTop")
  debug_inspect(stored_window.window_theme.to_string(), content="Some(Dark)")

  let stored_cursor = match cursor_options_value(app.world(), entity) {
    Some(cursor) => cursor
    None => abort("missing updated cursor options")
  }
  debug_inspect(stored_cursor.visible, content="false")
  debug_inspect(stored_cursor.grab_mode, content="GrabConfined")
  debug_inspect(
    match cursor_icon_value(app.world(), entity) {
      Some(System(icon)) => icon == SystemCursorIcon::EwResize
      Some(_) => false
      None => false
    },
    content="true",
  )
}

///|
test "window: drag request helpers write pending requests" {
  let window = Window::default()
  window.set_maximized(true)
  window.set_minimized(true)
  window.start_drag_move()
  window.start_drag_resize(@math.CompassOctant::North)
  debug_inspect(window.maximize_request, content="Some(true)")
  debug_inspect(window.minimize_request, content="Some(true)")
  debug_inspect(window.drag_move_request, content="true")
  debug_inspect(window.drag_resize_request, content="Some(North)")
}

///|
test "window: window refs resolve entity-backed metrics" {
  let primary_window = Window::default()
  primary_window.resolution.set_physical_resolution(320, 180)
  primary_window.resolution.set_scale_factor(1.0F)
  let secondary_window = Window::default()
  secondary_window.title = "Secondary"
  secondary_window.resolution.set_physical_resolution(640, 360)
  secondary_window.resolution.set_scale_factor_override(Some(2.0F))

  let world = @ecs.World::new()
  let primary = world.spawn()
  try! (world.entity_mut(primary).insert_component(primary_window) |> ignore)
  try! (world.entity_mut(primary).insert_component(PrimaryWindow::{  })
  |> ignore)
  let secondary = world.spawn()
  try! (world.entity_mut(secondary).insert_component(secondary_window) |> ignore)

  debug_inspect(
    window_entity_for_ref(world, WindowRef::Primary) == Some(primary),
    content="true",
  )
  debug_inspect(
    window_entity_for_ref(world, WindowRef::Entity(secondary)) ==
    Some(secondary),
    content="true",
  )
  debug_inspect(
    window_physical_width_for(world, WindowRef::Primary),
    content="320",
  )
  debug_inspect(
    window_physical_height_for(world, WindowRef::Entity(secondary)),
    content="360",
  )
  debug_inspect(
    window_scale_factor_for(world, WindowRef::Entity(secondary)),
    content="2",
  )
}

///|
test "window: primary refs do not fall back to secondary windows" {
  let secondary_window = Window::default()
  secondary_window.title = "Secondary"
  secondary_window.resolution.set_physical_resolution(640, 360)
  secondary_window.resolution.set_scale_factor_override(Some(2.0F))

  let world = @ecs.World::new()
  let secondary = world.spawn()
  try! (world.entity_mut(secondary).insert_component(secondary_window) |> ignore)

  debug_inspect(
    window_entity_for_ref(world, WindowRef::Primary) is None,
    content="true",
  )
  debug_inspect(
    window_physical_width_for(world, WindowRef::Primary),
    content="0",
  )
  debug_inspect(
    window_physical_height_for(world, WindowRef::Primary),
    content="0",
  )
  debug_inspect(window_scale_factor_for(world, WindowRef::Primary), content="1")
  debug_inspect(window_ensure_primary_host(world), content="None")
}

///|
test "window: singleton helpers no-op when no primary window exists" {
  let world = @ecs.World::new()
  let secondary = world.spawn()
  let secondary_window = Window::default()
  secondary_window.title = "Secondary"
  secondary_window.resolution.set_physical_resolution(640, 360)
  try! (world.entity_mut(secondary).insert_component(secondary_window) |> ignore)
  let width = Ref::new(-1)
  let height = Ref::new(-1)
  let scale_factor = Ref::new(-1.0F)
  let position_x = Ref::new(-1)
  let position_y = Ref::new(-1)

  let app = @app.App::new(world).add_systems(
    @app.Update,
    @app.system(fn(_world : @ecs.World) {
      width.val = window_width()
      height.val = window_height()
      scale_factor.val = window_scale_factor()
      position_x.val = window_position_x()
      position_y.val = window_position_y()
      window_set_title(title="Updated")
      window_set_size(width=800, height=600)
      window_set_resizable(resizable=false)
      window_set_cursor_visible(visible=false)
      window_set_cursor_grab_mode(mode=CursorGrabMode::GrabConfined)
      window_set_cursor_icon(icon=CursorIcon::from(SystemCursorIcon::EwResize))
      window_set_position(x=30, y=40)
      window_set_mode(
        mode=WindowMode::Fullscreen(
          MonitorSelection::Primary,
          VideoModeSelection::Current,
        ),
      )
    }),
  )
  let app = app.run_once()
  debug_inspect(width.val, content="0")
  debug_inspect(height.val, content="0")
  debug_inspect(scale_factor.val, content="1")
  debug_inspect(position_x.val, content="0")
  debug_inspect(position_y.val, content="0")
  let stored_window = match window_component_value(app.world(), secondary) {
    Some(window) => window
    None => abort("missing secondary window")
  }

  debug_inspect(stored_window.title, content="Secondary")
  debug_inspect(stored_window.physical_width(), content="640")
  debug_inspect(stored_window.physical_height(), content="360")
  debug_inspect(
    stored_window.position == WindowPosition::Automatic,
    content="true",
  )
  debug_inspect(stored_window.mode == WindowMode::Windowed, content="true")
  debug_inspect(stored_window.resizable, content="true")
  debug_inspect(cursor_options_value(app.world(), secondary), content="None")
  debug_inspect(
    cursor_icon_value(app.world(), secondary) is None,
    content="true",
  )
}

///|
test "window: scale-factor helper prefers override over observed host scale" {
  let configured_window = Window::default()
  configured_window.resolution.set_physical_resolution(500, 300)
  configured_window.resolution.set_scale_factor_override(Some(1.0F))
  let seen_scale_factor : Ref[Float] = Ref::new(0.0F)

  let app = window_plugin_with(@app.App::new(@ecs.World::new()), WindowPlugin::{
    primary_window: Some(configured_window),
    primary_cursor_options: Some(CursorOptions::default()),
    exit_condition: ExitCondition::DontExit,
    close_when_requested: false,
  }).add_systems(
    @app.Update,
    @app.system(fn(_world : @ecs.World) {
      seen_scale_factor.val = window_scale_factor()
    }),
  )
  let app = app.run_once()
  let entity = match primary_window_entity(app.world()) {
    Some(entity) => entity
    None => abort("missing primary window entity")
  }
  let stored_window = match window_component_value(app.world(), entity) {
    Some(window) => window
    None => abort("missing updated window")
  }

  debug_inspect(seen_scale_factor.val, content="1")
  debug_inspect(stored_window.scale_factor(), content="1")
}

///|
test "window: plugin does not own backend window synchronization" {
  let app = window_plugin(@app.App::new(@ecs.World::new())).run_once()
  debug_inspect(read_window_created(app.world()).length(), content="0")
}

///|
test "window: close_when_requested marks windows without immediate despawn" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Window::default()) |> ignore)
  let mut app = @app.App::new(world)
    .add_message(ecs_key_window_close_requested)
    .add_message(ecs_key_window_closing)
    .add_message(ecs_key_window_closed)
    .add_message(ecs_key_window_destroyed)
    .add_systems(
      @app.Update,
      @app.system(@app.system_param2(close_when_requested)),
    )
  ignore(
    app
    .world()
    .send_message(ecs_key_window_close_requested, WindowCloseRequested::{
      window: entity,
    }),
  )

  app = app.run_once()
  debug_inspect(app.world().is_alive(entity), content="true")
  debug_inspect(has_closing_window(app.world(), entity), content="true")
  debug_inspect(read_window_closing(app.world()).length(), content="0")
  debug_inspect(read_window_destroyed(app.world()).length(), content="0")
}

///|
test "window: exit_on_all_closed sends AppExit when no windows remain" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_message(@app.AppExit::message())
    .add_systems(
      @app.PostUpdate,
      @app.system(@app.system_param2(exit_on_all_closed)),
    )

  app = app.run_once()
  debug_inspect(app.should_exit(), content="Some(Success)")
}

///|
test "window: exit_on_primary_closed only exits after primary window disappears" {
  let world = @ecs.World::new()
  let primary = world.spawn()
  let secondary = world.spawn()
  try! (world.entity_mut(primary).insert_component(Window::default()) |> ignore)
  try! (world.entity_mut(primary).insert_component(PrimaryWindow::{  })
  |> ignore)
  try! (world.entity_mut(secondary).insert_component(Window::default())
  |> ignore)
  let mut app = @app.App::new(world)
    .add_message(@app.AppExit::message())
    .add_message(ecs_key_window_closed)
    .add_systems(
      @app.PostUpdate,
      @app.system(@app.system_param2(exit_on_primary_closed)),
    )

  app = app.run_once()
  debug_inspect(app.should_exit() is None, content="true")

  try! app.world().despawn(primary)
  app = app.run_once()
  debug_inspect(app.should_exit(), content="Some(Success)")
}

///|
test "window: keycode supports Eq/Hash/Show for map-backed indexing" {
  let key_index : @hashmap.HashMap[KeyCode, Int] = @hashmap.HashMap::new()
  key_index.set(KeyCode::KeyA, 1)
  key_index.set(KeyCode::Space, 2)

  debug_inspect(key_index.get(KeyCode::KeyA), content="Some(1)")
  debug_inspect(key_index.get(KeyCode::Space), content="Some(2)")
  debug_inspect(KeyCode::KeyA == KeyCode::KeyA, content="true")
  debug_inspect(to_repr(KeyCode::KeyA).to_string(), content="KeyA")
}

///|
test "window: monitor ECS types align with bevy monitor data model" {
  let world = @ecs.World::new()
  let monitor_entity = world.spawn()
  let video_mode = VideoMode::new(@math.UVec2::new(1920, 1080), 24, 60000)
  let monitor = Monitor::{
    name: Some("Main Display"),
    physical_height: 1080,
    physical_width: 1920,
    physical_position: @math.IVec2::new(0, 0),
    refresh_rate_millihertz: Some(60000),
    scale_factor: 2.0,
    video_modes: [video_mode],
  }

  try! (world.entity_mut(monitor_entity).insert_component(monitor) |> ignore)
  try! (world.entity_mut(monitor_entity).insert_component(PrimaryMonitor::{  })
  |> ignore)

  let stored_monitor = match monitor_component_value(world, monitor_entity) {
    Some(value) => value
    None => abort("missing monitor component")
  }
  let physical_size = stored_monitor.physical_size()
  assert_eq(physical_size.x, 1920)
  assert_eq(physical_size.y, 1080)
  assert_eq(stored_monitor.video_modes.length(), 1)
  assert_eq(
    stored_monitor.video_modes[0].physical_size.x,
    video_mode.physical_size.x,
  )
  assert_eq(
    stored_monitor.video_modes[0].physical_size.y,
    video_mode.physical_size.y,
  )
  assert_eq(stored_monitor.video_modes[0].bit_depth, video_mode.bit_depth)
  assert_eq(
    stored_monitor.video_modes[0].refresh_rate_millihertz,
    video_mode.refresh_rate_millihertz,
  )
  assert_true(has_primary_monitor(world, monitor_entity))
}

///|
test "window: app lifecycle active states align with bevy semantics" {
  debug_inspect(AppLifecycle::Idle.is_active(), content="false")
  debug_inspect(AppLifecycle::Running.is_active(), content="true")
  debug_inspect(AppLifecycle::WillSuspend.is_active(), content="true")
  debug_inspect(AppLifecycle::Suspended.is_active(), content="false")
  debug_inspect(AppLifecycle::WillResume.is_active(), content="true")
}

///|
test "window: aggregate event bus mirrors window-owned emit helpers" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! (world.entity_mut(entity).insert_component(Window::default()) |> ignore)
  try! (world.entity_mut(entity).insert_component(PrimaryWindow::{  }) |> ignore)

  let app = window_plugin(@app.App::new(world)).run_once()
  let world0 = app.world()

  window_emit_cursor_moved(world0, CursorMoved::{
    window: entity,
    position: @math.Vec2::new(1.0F, 2.0F),
    delta: None,
  })
  window_emit_cursor_entered(world0, CursorEntered::{ window: entity })
  window_emit_cursor_left(world0, CursorLeft::{ window: entity })
  window_emit_file_drag_and_drop(
    world0,
    FileDragAndDrop::HoveredFile(entity, "assets/icon.png"),
  )
  window_emit_ime(world0, Ime::Enabled(entity))
  window_emit_mouse_button_input(world0, MouseButtonInput::{
    button: MouseButton::Left,
    state: ButtonState::Pressed,
  })
  window_emit_mouse_motion(world0, MouseMotion::{
    delta: @math.Vec2::new(3.0F, -1.0F),
  })
  window_emit_mouse_wheel(world0, MouseWheel::{
    unit: MouseScrollUnit::Line,
    x: 1.0F,
    y: -2.0F,
  })
  window_emit_pinch_gesture(world0, PinchGesture::{ delta: 0.5F })
  window_emit_rotation_gesture(world0, RotationGesture::{ delta: -0.25F })
  window_emit_double_tap_gesture(world0, DoubleTapGesture::{  })
  window_emit_pan_gesture(world0, PanGesture::{
    delta: @math.Vec2::new(2.0F, -3.0F),
  })
  window_emit_touch_input(world0, TouchInput::{
    id: 7,
    phase: TouchPhase::Started,
    position: @math.Vec2::new(5.0F, 6.0F),
  })
  window_emit_keyboard_input(world0, KeyboardInput::{
    key_code: KeyCode::Space,
    logical_key: Key::Character(" "),
    state: ButtonState::Pressed,
    repeat: false,
    text: Some(" "),
  })
  window_emit_keyboard_focus_lost(world0, KeyboardFocusLost::{  })

  let events = read_window_events(world0)
  let mut cursor_moved_count = 0
  let mut cursor_entered_count = 0
  let mut cursor_left_count = 0
  let mut drag_count = 0
  let mut ime_count = 0
  let mut mouse_button_count = 0
  let mut mouse_motion_count = 0
  let mut mouse_wheel_count = 0
  let mut pinch_count = 0
  let mut rotation_count = 0
  let mut double_tap_count = 0
  let mut pan_count = 0
  let mut touch_count = 0
  let mut keyboard_input_count = 0
  let mut keyboard_focus_lost_count = 0
  for event in events {
    match event {
      WindowEvent::CursorMoved(_) => cursor_moved_count = cursor_moved_count + 1
      WindowEvent::CursorEntered(_) =>
        cursor_entered_count = cursor_entered_count + 1
      WindowEvent::CursorLeft(_) => cursor_left_count = cursor_left_count + 1
      WindowEvent::FileDragAndDrop(_) => drag_count = drag_count + 1
      WindowEvent::Ime(_) => ime_count = ime_count + 1
      WindowEvent::MouseButtonInput(_) =>
        mouse_button_count = mouse_button_count + 1
      WindowEvent::MouseMotion(_) => mouse_motion_count = mouse_motion_count + 1
      WindowEvent::MouseWheel(_) => mouse_wheel_count = mouse_wheel_count + 1
      WindowEvent::PinchGesture(_) => pinch_count = pinch_count + 1
      WindowEvent::RotationGesture(_) => rotation_count = rotation_count + 1
      WindowEvent::DoubleTapGesture(_) =>
        double_tap_count = double_tap_count + 1
      WindowEvent::PanGesture(_) => pan_count = pan_count + 1
      WindowEvent::TouchInput(_) => touch_count = touch_count + 1
      WindowEvent::KeyboardInput(_) =>
        keyboard_input_count = keyboard_input_count + 1
      WindowEvent::KeyboardFocusLost(_) =>
        keyboard_focus_lost_count = keyboard_focus_lost_count + 1
      _ => ()
    }
  }

  debug_inspect(cursor_moved_count, content="1")
  debug_inspect(cursor_entered_count, content="1")
  debug_inspect(cursor_left_count, content="1")
  debug_inspect(drag_count, content="1")
  debug_inspect(ime_count, content="1")
  debug_inspect(mouse_button_count, content="1")
  debug_inspect(mouse_motion_count, content="1")
  debug_inspect(mouse_wheel_count, content="1")
  debug_inspect(pinch_count, content="1")
  debug_inspect(rotation_count, content="1")
  debug_inspect(double_tap_count, content="1")
  debug_inspect(pan_count, content="1")
  debug_inspect(touch_count, content="1")
  debug_inspect(keyboard_input_count, content="1")
  debug_inspect(keyboard_focus_lost_count, content="1")
}
