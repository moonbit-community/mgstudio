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
  world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_window), @ecs.With::new(ecs_key_primary_window)),
  )
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
  result.val
}

///|
fn window_component_value(world : @ecs.World, entity : @core.Entity) -> Window? {
  try! world.get_component(entity)
}

///|
fn cursor_options_value(
  world : @ecs.World,
  entity : @core.Entity,
) -> CursorOptions? {
  try! world.get_component(entity)
}

///|
fn cursor_icon_value(world : @ecs.World, entity : @core.Entity) -> CursorIcon? {
  try! world.get_component(entity)
}

///|
fn has_closing_window(world : @ecs.World, entity : @core.Entity) -> Bool {
  match (try! world.get_component(entity) : ClosingWindow?) {
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
fn read_window_focused(world : @ecs.World) -> Array[WindowFocused] {
  let reader = world.message_reader(ecs_key_window_focused, Ref::new(0))
  try! reader.read()
}

///|
test "window: plugin spawns configured primary window entity and messages" {
  let configured_window = Window::default()
  configured_window.title = "Configured Window"
  configured_window.resolution.set_physical_resolution(800, 600)
  configured_window.resolution.set_scale_factor(2.0F)
  configured_window.position = WindowPosition::new(12, 34)
  configured_window.mode = WindowMode::BorderlessFullscreen
  configured_window.resizable = false
  configured_window.focused = false
  let configured_cursor = CursorOptions::default()
  configured_cursor.visible = false
  configured_cursor.grab_mode = CursorGrabMode::GrabLocked

  let app = window_plugin_with(@app.App::new(@ecs.World::new()), WindowPlugin::{
    primary_window: Some(configured_window),
    primary_cursor_options: Some(configured_cursor),
    exit_condition: ExitCondition::DontExit,
    close_when_requested: false,
  }).run_once()

  inspect(app.world().contains_message(ecs_key_window_created), content="true")
  inspect(
    app.world().contains_message(ecs_key_window_close_requested),
    content="true",
  )
  inspect(app.world().contains_message(ecs_key_window_closing), content="true")
  inspect(app.world().contains_message(ecs_key_window_closed), content="true")
  inspect(app.world().contains_message(ecs_key_window_moved), content="true")
  inspect(
    app.world().contains_message(ecs_key_window_backend_scale_factor_changed),
    content="true",
  )
  inspect(app.world().contains_message(ecs_key_window_focused), content="true")

  let entity = match primary_window_entity(app.world()) {
    Some(entity) => entity
    None => abort("missing primary window entity")
  }
  inspect(app.world().is_alive(entity), content="true")

  let stored_window = match window_component_value(app.world(), entity) {
    Some(window) => window
    None => abort("missing window component")
  }
  inspect(stored_window.title, content="Configured Window")
  inspect(stored_window.physical_width(), content="800")
  inspect(stored_window.physical_height(), content="600")
  inspect(stored_window.scale_factor(), content="2")
  inspect(stored_window.position, content="At(12, 34)")
  inspect(stored_window.mode, content="BorderlessFullscreen")
  inspect(stored_window.resizable, content="false")
  inspect(stored_window.focused, content="true")

  let stored_cursor = match cursor_options_value(app.world(), entity) {
    Some(cursor) => cursor
    None => abort("missing cursor options")
  }
  inspect(stored_cursor.visible, content="false")
  inspect(stored_cursor.grab_mode, content="GrabLocked")
  let focused_messages = read_window_focused(app.world())
  inspect(focused_messages.length(), content="1")
  inspect(focused_messages[0].window == entity, content="true")
  inspect(focused_messages[0].focused, content="true")
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
  try! world.set_component(entity, configured_window)
  try! world.set_component(entity, PrimaryWindow::{  })

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
      window_set_cursor_visible(visible=false)
      window_set_cursor_grab_mode(mode=CursorGrabMode::GrabConfined)
      window_set_cursor_icon(icon=CursorIcon::from(SystemCursorIcon::EwResize))
      window_set_position(x=30, y=40)
      window_set_mode(mode=WindowMode::Fullscreen)
    }),
  )
  let app = app.run_once()

  inspect(seen_width.val, content="320")
  inspect(seen_height.val, content="180")
  inspect(seen_position_x.val, content="3")
  inspect(seen_position_y.val, content="4")
  inspect(seen_scale_factor.val, content="2")

  let stored_window = match window_component_value(app.world(), entity) {
    Some(window) => window
    None => abort("missing updated window")
  }
  inspect(stored_window.title, content="Updated")
  inspect(stored_window.physical_width(), content="640")
  inspect(stored_window.physical_height(), content="360")
  inspect(stored_window.position, content="At(30, 40)")
  inspect(stored_window.mode, content="Fullscreen")
  inspect(stored_window.resizable, content="false")

  let stored_cursor = match cursor_options_value(app.world(), entity) {
    Some(cursor) => cursor
    None => abort("missing updated cursor options")
  }
  inspect(stored_cursor.visible, content="false")
  inspect(stored_cursor.grab_mode, content="GrabConfined")
  inspect(
    cursor_icon_value(app.world(), entity),
    content="Some(System(EwResize))",
  )
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
  try! world.set_component(primary, primary_window)
  try! world.set_component(primary, PrimaryWindow::{  })
  let secondary = world.spawn()
  try! world.set_component(secondary, secondary_window)

  inspect(
    window_entity_for_ref(world, WindowRef::Primary) == Some(primary),
    content="true",
  )
  inspect(
    window_entity_for_ref(world, WindowRef::Entity(secondary)) ==
    Some(secondary),
    content="true",
  )
  inspect(window_physical_width_for(world, WindowRef::Primary), content="320")
  inspect(
    window_physical_height_for(world, WindowRef::Entity(secondary)),
    content="360",
  )
  inspect(
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
  try! world.set_component(secondary, secondary_window)

  inspect(
    window_entity_for_ref(world, WindowRef::Primary) is None,
    content="true",
  )
  inspect(window_physical_width_for(world, WindowRef::Primary), content="0")
  inspect(window_physical_height_for(world, WindowRef::Primary), content="0")
  inspect(window_scale_factor_for(world, WindowRef::Primary), content="1")
  inspect(window_ensure_primary_host(world), content="None")
}

///|
test "window: singleton helpers no-op when no primary window exists" {
  let world = @ecs.World::new()
  let secondary = world.spawn()
  let secondary_window = Window::default()
  secondary_window.title = "Secondary"
  secondary_window.resolution.set_physical_resolution(640, 360)
  try! world.set_component(secondary, secondary_window)
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
      window_set_mode(mode=WindowMode::Fullscreen)
    }),
  )
  let app = app.run_once()
  inspect(width.val, content="0")
  inspect(height.val, content="0")
  inspect(scale_factor.val, content="1")
  inspect(position_x.val, content="0")
  inspect(position_y.val, content="0")
  let stored_window = match window_component_value(app.world(), secondary) {
    Some(window) => window
    None => abort("missing secondary window")
  }

  inspect(stored_window.title, content="Secondary")
  inspect(stored_window.physical_width(), content="640")
  inspect(stored_window.physical_height(), content="360")
  inspect(stored_window.position, content="Automatic")
  inspect(stored_window.mode, content="Windowed")
  inspect(stored_window.resizable, content="true")
  inspect(cursor_options_value(app.world(), secondary), content="None")
  inspect(cursor_icon_value(app.world(), secondary), content="None")
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

  inspect(seen_scale_factor.val, content="1")
  inspect(stored_window.scale_factor(), content="1")
}

///|
test "window: backend sync creates host runtime for secondary window entities" {
  let configured_window = Window::default()
  configured_window.title = "Primary"
  let world = @ecs.World::new()
  let secondary = world.spawn()
  let secondary_window = Window::default()
  secondary_window.title = "Second window"
  try! world.set_component(secondary, secondary_window)

  let mut app = window_plugin_with(@app.App::new(world), WindowPlugin::{
    primary_window: Some(configured_window),
    primary_cursor_options: Some(CursorOptions::default()),
    exit_condition: ExitCondition::DontExit,
    close_when_requested: false,
  })
  app = app.run_once()
  let stored_window = match window_component_value(app.world(), secondary) {
    Some(window) => window
    None => abort("missing secondary window")
  }
  let created_messages = read_window_created(app.world())
  let mut secondary_created = false
  for message in created_messages {
    if message.window == secondary {
      secondary_created = true
    }
  }
  inspect(secondary_created, content="true")
  inspect(stored_window.title, content="Second window")
}

///|
test "window: close_when_requested marks then despawns windows across updates" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  try! world.set_component(entity, Window::default())
  let mut app = @app.App::new(world)
    .add_message(ecs_key_window_close_requested)
    .add_message(ecs_key_window_closing)
    .add_message(ecs_key_window_closed)
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
  inspect(app.world().is_alive(entity), content="true")
  inspect(has_closing_window(app.world(), entity), content="true")
  inspect(read_window_closing(app.world()).length(), content="1")

  app = app.run_once()
  inspect(app.world().is_alive(entity), content="false")
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
  inspect(app.should_exit(), content="Some(Success)")
}

///|
test "window: exit_on_primary_closed only exits after primary window disappears" {
  let world = @ecs.World::new()
  let primary = world.spawn()
  let secondary = world.spawn()
  try! world.set_component(primary, Window::default())
  try! world.set_component(primary, PrimaryWindow::{  })
  try! world.set_component(secondary, Window::default())
  let mut app = @app.App::new(world)
    .add_message(@app.AppExit::message())
    .add_message(ecs_key_window_closed)
    .add_systems(
      @app.PostUpdate,
      @app.system(@app.system_param2(exit_on_primary_closed)),
    )

  app = app.run_once()
  inspect(app.should_exit() is None, content="true")

  try! app.world().despawn(primary)
  app = app.run_once()
  inspect(app.should_exit(), content="Some(Success)")
}
