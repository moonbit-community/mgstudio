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
fn read_focus_resource(world : @ecs.World) -> InputFocus {
  match (try! world.get_resource(InputFocus::resource())) {
    Some(focus) => focus
    None => abort("missing InputFocus resource")
  }
}

///|
fn read_focus_visible_resource(world : @ecs.World) -> InputFocusVisible {
  match (try! world.get_resource(InputFocusVisible::resource())) {
    Some(visible) => visible
    None => abort("missing InputFocusVisible resource")
  }
}

///|
fn input_focus_resource_ref_mut(world : @ecs.World) -> Ref[InputFocus] {
  match
    (try! world.get_resource_ref_mut(
      InputFocus::resource(),
      world.increment_change_tick(),
    )) {
    Some(value) => value
    None => abort("missing mutable InputFocus resource")
  }
}

///|
fn input_focus_visible_resource_ref_mut(
  world : @ecs.World,
) -> Ref[InputFocusVisible] {
  match
    (try! world.get_resource_ref_mut(
      InputFocusVisible::resource(),
      world.increment_change_tick(),
    )) {
    Some(value) => value
    None => abort("missing mutable InputFocusVisible resource")
  }
}

///|
fn read_focused_keyboard_inputs(
  world : @ecs.World,
) -> Array[FocusedInput[KeyboardInput]] {
  let key : @ecs.MessageKey[FocusedInput[KeyboardInput]] = focused_input_message_key()
  let reader = world.message_reader(key, Ref::new(0))
  try! reader.read()
}

///|
fn read_focused_mouse_wheels(
  world : @ecs.World,
) -> Array[FocusedInput[MouseWheel]] {
  let key : @ecs.MessageKey[FocusedInput[MouseWheel]] = focused_input_message_key()
  let reader = world.message_reader(key, Ref::new(0))
  try! reader.read()
}

///|
fn key_a_message() -> KeyboardInput {
  KeyboardInput::{
    key_code: @window.KeyCode::KeyA,
    logical_key: Key::Character("A"),
    state: ButtonState::Pressed,
    repeat: false,
  }
}

///|
fn primary_window_entity(world : @ecs.World) -> @core.Entity? {
  let result : Ref[@core.Entity?] = Ref::new(None)
  world
  .query_entities_filtered(
    (
      @ecs.With::new(@window.ecs_key_window),
      @ecs.With::new(@window.ecs_key_primary_window),
    ),
  )
  .view(fn(entity) { if result.val is None { result.val = Some(entity) } })
  result.val
}

///|
test "input focus: plugin initializes resources and focused message queues" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugin(@time.time_plugin)
    .add_plugin(input_plugin)
    .add_plugin(input_dispatch_plugin)
    .run_once()

  inspect(read_focus_resource(app.world()).get() is None, content="true")
  inspect(read_focus_visible_resource(app.world()).visible(), content="false")
  let keyboard_key : @ecs.MessageKey[FocusedInput[KeyboardInput]] = focused_input_message_key()
  let gamepad_key : @ecs.MessageKey[FocusedInput[GamepadButtonChangedEvent]] = focused_input_message_key()
  let wheel_key : @ecs.MessageKey[FocusedInput[MouseWheel]] = focused_input_message_key()
  inspect(app.world().contains_message(keyboard_key), content="true")
  inspect(app.world().contains_message(gamepad_key), content="true")
  inspect(app.world().contains_message(wheel_key), content="true")
}

///|
test "input focus: window plugin integration sets initial focus to primary window" {
  let app = @window.window_plugin_with(
    @app.App::new(@ecs.World::new())
    .add_plugin(@time.time_plugin)
    .add_plugin(input_plugin)
    .add_plugin(input_dispatch_plugin),
    @window.WindowPlugin::default(),
  ).run_once()
  let entity = match primary_window_entity(app.world()) {
    Some(entity) => entity
    None => abort("missing primary window entity")
  }
  inspect(
    read_focus_resource(app.world()).get() == Some(entity),
    content="true",
  )
}

///|
test "input focus: initial focus is not overridden when already set" {
  let world = @ecs.World::new()
  let primary = world.spawn()
  try! world.set_component(primary, @window.Window::default())
  try! world.set_component(primary, @window.PrimaryWindow::{  })
  let custom = world.spawn()
  world.insert_resource(InputFocus::resource(), InputFocus::from_entity(custom))

  let app = @app.App::new(world)
    .add_plugin(@time.time_plugin)
    .add_plugin(input_plugin)
    .add_plugin(input_dispatch_plugin)
    .run_once()

  inspect(
    read_focus_resource(app.world()).get() == Some(custom),
    content="true",
  )
}

///|
test "input focus: dispatch sends keyboard and wheel inputs to focused entity or primary window" {
  let world = @ecs.World::new()
  let primary = world.spawn()
  try! world.set_component(primary, @window.Window::default())
  try! world.set_component(primary, @window.PrimaryWindow::{  })
  world.init_message(KeyboardInput::message())
  world.init_message(MouseWheel::message())
  let focused = world.spawn()

  let app = @app.App::new(world)
    .add_plugin(@time.time_plugin)
    .add_plugin(input_plugin)
    .add_plugin(input_dispatch_plugin)
    .run_once()
  let focus_ref = input_focus_resource_ref_mut(app.world())
  focus_ref.val.set(focused)
  ignore(app.world().send_message(KeyboardInput::message(), key_a_message()))
  ignore(
    app
    .world()
    .send_message(MouseWheel::message(), MouseWheel::{
      unit: MouseScrollUnit::Line,
      x: 2.0F,
      y: -1.0F,
    }),
  )

  let app = app.update()
  let keyboard_messages = read_focused_keyboard_inputs(app.world())
  let wheel_messages = read_focused_mouse_wheels(app.world())

  inspect(keyboard_messages.length(), content="1")
  inspect(keyboard_messages[0].focused_entity == focused, content="true")
  inspect(keyboard_messages[0].window == primary, content="true")
  inspect(
    keycode_to_string(keyboard_messages[0].input.key_code) == "KeyA",
    content="true",
  )

  inspect(wheel_messages.length(), content="1")
  inspect(wheel_messages[0].focused_entity == focused, content="true")
  inspect(wheel_messages[0].window == primary, content="true")
  inspect(wheel_messages[0].input.x, content="2")
  inspect(wheel_messages[0].input.y, content="-1")
  let keyboard_key : @ecs.MessageKey[FocusedInput[KeyboardInput]] = focused_input_message_key()
  let wheel_key : @ecs.MessageKey[FocusedInput[MouseWheel]] = focused_input_message_key()
  app.world().clear_messages(keyboard_key)
  app.world().clear_messages(wheel_key)

  let focus_ref = input_focus_resource_ref_mut(app.world())
  focus_ref.val.clear()
  ignore(app.world().send_message(KeyboardInput::message(), key_a_message()))

  let app = app.update()
  let keyboard_messages = read_focused_keyboard_inputs(app.world())
  inspect(keyboard_messages.length(), content="1")
  inspect(keyboard_messages[0].focused_entity == primary, content="true")
  inspect(keyboard_messages[0].window == primary, content="true")
}

///|
test "input focus: helper follows parent chain and stale focus clears on dispatch" {
  let world = @ecs.World::new()
  let primary = world.spawn()
  try! world.set_component(primary, @window.Window::default())
  try! world.set_component(primary, @window.PrimaryWindow::{  })
  world.init_message(KeyboardInput::message())

  let parent = world.spawn()
  let child = world.spawn()
  try! world.set_component(child, @hierarchy.Parent::new(parent))

  let helper_focus_within_parent : Ref[Bool] = Ref::new(false)
  let helper_focus_visible_parent : Ref[Bool] = Ref::new(false)
  let helper_focus_visible_child : Ref[Bool] = Ref::new(false)

  let app = @app.App::new(world)
    .add_plugin(@time.time_plugin)
    .add_plugin(input_plugin)
    .add_plugin(input_dispatch_plugin)
    .add_systems(
      @app.Update,
      @app.system(
        @app.system_param(fn(helper : IsFocusedHelper) {
          helper_focus_within_parent.val = helper.is_focus_within(parent)
          helper_focus_visible_parent.val = helper.is_focus_within_visible(
            parent,
          )
          helper_focus_visible_child.val = helper.is_focus_visible(child)
        }),
      ),
    )
    .run_once()

  let focus_ref = input_focus_resource_ref_mut(app.world())
  focus_ref.val.set(child)
  let visible_ref = input_focus_visible_resource_ref_mut(app.world())
  visible_ref.val.set_visible(true)

  let app = app.update()

  inspect(IsFocused::is_focused(app.world(), child), content="true")
  inspect(IsFocused::is_focus_within(app.world(), parent), content="true")
  inspect(
    IsFocused::is_focus_within_visible(app.world(), parent),
    content="true",
  )
  inspect(helper_focus_within_parent.val, content="true")
  inspect(helper_focus_visible_parent.val, content="true")
  inspect(helper_focus_visible_child.val, content="true")

  app.world().despawn(child)
  ignore(app.world().send_message(KeyboardInput::message(), key_a_message()))
  let app = app.update()
  let keyboard_messages = read_focused_keyboard_inputs(app.world())
  inspect(keyboard_messages.length(), content="1")
  inspect(keyboard_messages[0].focused_entity == primary, content="true")
  inspect(read_focus_resource(app.world()).get() is None, content="true")
}
