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
struct CursorIcons {
  icons : Array[@window.CursorIcon]
}

///|
let cursor_icons_key : @ecs.ResourceKey[CursorIcons] = @ecs.register_resource(
  debug_name="examples.window.window_settings.CursorIcons",
)

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "I am a window!"
  window.name = Some("mgstudio.app")
  window.resolution.set_physical_resolution(500, 300)
  window.present_mode = AutoVsync
  window.fit_canvas_to_parent = true
  window.prevent_default_event_handling = false
  window.window_theme = Some(Dark)
  window.enabled_buttons.maximize = false
  window.visible = false
  window
}

///|
fn primary_window_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref(None)
  try! world
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(_query_entity, entity) {
    if result.val is None {
      result.val = Some(entity)
    }
  })
  result.val
}

///|
fn update_primary_window(
  world : @ecs.World,
  update : (@window.Window) -> Unit,
) -> Unit {
  guard primary_window_entity(world) is Some(entity) else { return }
  guard (try! world.get_by_key(entity, @window.ecs_key_window)) is Some(window) else {
    return
  }
  update(window)
  try! (world.replace(entity, @window.ecs_key_window, window) |> ignore)
}

///|
fn update_primary_cursor_options(
  world : @ecs.World,
  update : (@window.CursorOptions) -> Unit,
) -> Unit {
  guard primary_window_entity(world) is Some(entity) else { return }
  let options = match
    (try! world.get_by_key(entity, @window.ecs_key_cursor_options)) {
    Some(options) => options
    None => CursorOptions()
  }
  update(options)
  if (try! world.get_by_key(entity, @window.ecs_key_cursor_options)) is Some(_) {
    try! (world.replace(entity, @window.ecs_key_cursor_options, options)
    |> ignore)
  } else {
    try! world.set_by_key(entity, @window.ecs_key_cursor_options, options)
  }
}

///|
fn set_primary_cursor_icon(
  world : @ecs.World,
  icon : @window.CursorIcon,
) -> Unit {
  guard primary_window_entity(world) is Some(entity) else { return }
  if (try! world.get_by_key(entity, @window.ecs_key_cursor_icon)) is Some(_) {
    try! (world.replace(entity, @window.ecs_key_cursor_icon, icon) |> ignore)
  } else {
    try! world.set_by_key(entity, @window.ecs_key_cursor_icon, icon)
  }
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[window_settings] \{text}")
}

///|
fn make_visible(frames : @app.Res[@diagnostic.FrameCount]) -> Unit {
  if frames.get().value != 3 {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  update_primary_window(world, fn(window) { window.visible = true })
}

///|
fn toggle_vsync(input : @input.ButtonInput[@window.KeyCode]) -> Unit {
  if !input.just_pressed(KeyV) {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  let present_mode_ref : Ref[@window.PresentMode] = Ref(AutoVsync)
  update_primary_window(world, fn(window) {
    window.present_mode = if window.present_mode == AutoVsync {
      AutoNoVsync
    } else {
      AutoVsync
    }
    present_mode_ref.val = window.present_mode
  })
  log_line("PRESENT_MODE: \{to_repr(present_mode_ref.val).to_string()}")
}

///|
fn switch_level(input : @input.ButtonInput[@window.KeyCode]) -> Unit {
  if !input.just_pressed(KeyT) {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  let level_ref : Ref[@window.WindowLevel] = Ref(Normal)
  update_primary_window(world, fn(window) {
    window.window_level = match window.window_level {
      AlwaysOnBottom => Normal
      Normal => AlwaysOnTop
      AlwaysOnTop => AlwaysOnBottom
    }
    level_ref.val = window.window_level
  })
  log_line("WINDOW_LEVEL: \{level_ref.val.to_string()}")
}

///|
fn toggle_window_controls(input : @input.ButtonInput[@window.KeyCode]) -> Unit {
  let toggle_minimize = input.just_pressed(Digit1)
  let toggle_maximize = input.just_pressed(Digit2)
  let toggle_close = input.just_pressed(Digit3)
  if !toggle_minimize && !toggle_maximize && !toggle_close {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  update_primary_window(world, fn(window) {
    if toggle_minimize {
      window.enabled_buttons.minimize = !window.enabled_buttons.minimize
    }
    if toggle_maximize {
      window.enabled_buttons.maximize = !window.enabled_buttons.maximize
    }
    if toggle_close {
      window.enabled_buttons.close = !window.enabled_buttons.close
    }
  })
}

///|
fn change_title(world : @ecs.World) -> Unit {
  let time : @time.Time[Unit] = match
    world.get_resource(@time.default_time_resource_key) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in window_settings example")
  }
  let seconds = time.elapsed_seconds().round()
  update_primary_window(world, fn(window) {
    window.title = "Seconds since startup: \{seconds.to_string()}"
  })
}

///|
fn toggle_cursor(input : @input.ButtonInput[@window.KeyCode]) -> Unit {
  if !input.just_pressed(Space) {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  update_primary_cursor_options(world, fn(options) {
    options.visible = !options.visible
    options.grab_mode = match options.grab_mode {
      GrabNone => GrabLocked
      GrabLocked => GrabNone
      GrabConfined => GrabNone
    }
  })
}

///|
fn toggle_theme(input : @input.ButtonInput[@window.KeyCode]) -> Unit {
  if !input.just_pressed(KeyF) {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  update_primary_window(world, fn(window) {
    match window.window_theme {
      Some(Light) => window.window_theme = Some(Dark)
      Some(Dark) => window.window_theme = Some(Light)
      None => ()
    }
  })
}

///|
fn init_cursor_icons(world : @ecs.World) -> Unit {
  let icons = CursorIcons::{
    icons: [
      @window.CursorIcon::from(Default),
      @window.CursorIcon::from(Pointer),
      @window.CursorIcon::from(Wait),
      @window.CursorIcon::from(Text),
    ],
  }
  set_primary_cursor_icon(world, icons.icons[0])
  world.insert_resource(cursor_icons_key, icons)
}

///|
fn cycle_cursor_icon(
  input : @input.ButtonInput[@window.MouseButton],
  index : @app.Local[Int],
) -> Unit {
  let go_next = input.just_pressed(Left)
  let go_prev = input.just_pressed(Right)
  if !go_next && !go_prev {
    return
  }
  guard @app.current_world() is Some(world) else { return }
  guard world.get_resource(cursor_icons_key) is Some(cursor_icons) else {
    return
  }
  if cursor_icons.icons.length() == 0 {
    return
  }
  let count = cursor_icons.icons.length()
  let current_index = index.get()
  let next = if go_next {
    (current_index + 1) % count
  } else if current_index <= 0 {
    count - 1
  } else {
    current_index - 1
  }
  index.set(next)
  set_primary_cursor_icon(world, cursor_icons.icons[next])
}

///|
fn setup_camera(world : @ecs.World) -> Unit {
  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: Some(CursorOptions()),
      exit_condition: OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_plugins(@diagnostic.LogDiagnosticsPlugin::LogDiagnosticsPlugin())
  .add_plugins(
    @diagnostic.FrameTimeDiagnosticsPlugin::FrameTimeDiagnosticsPlugin(),
  )
  .add_systems_world(Startup, setup_camera)
  .add_systems_world(Startup, init_cursor_icons)
  .add_systems_param(Update, toggle_vsync)
  .add_systems_param(Update, switch_level)
  .add_systems_param(Update, toggle_window_controls)
  .add_systems_world(Update, change_title)
  .add_systems_param(Update, toggle_cursor)
  .add_systems_param(Update, toggle_theme)
  .add_systems_param2(Update, cycle_cursor_icon)
  .add_systems_param(Update, make_visible)
  .run()
}
