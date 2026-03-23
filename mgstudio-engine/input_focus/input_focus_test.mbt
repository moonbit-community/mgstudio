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
fn read_focus_resource(world : @ecs.World) -> @input_focus.InputFocus {
  match (try! world.get_resource(@input_focus.InputFocus::resource())) {
    Some(focus) => focus
    None => abort("missing InputFocus resource")
  }
}

///|
fn read_focus_visible_resource(
  world : @ecs.World,
) -> @input_focus.InputFocusVisible {
  match (try! world.get_resource(@input_focus.InputFocusVisible::resource())) {
    Some(visible) => visible
    None => abort("missing InputFocusVisible resource")
  }
}

///|
fn input_focus_resource_ref_mut(
  world : @ecs.World,
) -> Ref[@input_focus.InputFocus] {
  match (try! world.get_resource_ref_mut(@input_focus.InputFocus::resource())) {
    Some(value) => value
    None => abort("missing mutable InputFocus resource")
  }
}

///|
fn input_focus_visible_resource_ref_mut(
  world : @ecs.World,
) -> Ref[@input_focus.InputFocusVisible] {
  match
    (try! world.get_resource_ref_mut(@input_focus.InputFocusVisible::resource())) {
    Some(value) => value
    None => abort("missing mutable InputFocusVisible resource")
  }
}

///|
struct MockInput {
  id : Int
}

///|
let mock_input_message_key : @ecs.MessageKey[MockInput] = @ecs.register_message(
  debug_name="input_focus_test::MockInput",
)

///|
pub impl @ecs.Message for MockInput with message() {
  mock_input_message_key
}

///|
fn read_focused_mock_inputs(
  world : @ecs.World,
) -> Array[@input_focus.FocusedInput[MockInput]] {
  let key : @ecs.MessageKey[@input_focus.FocusedInput[MockInput]] = @input_focus.focused_input_message_key()
  let reader = world.message_reader(key, Ref::new(0))
  try! reader.read()
}

///|
fn dispatch_mock_input(
  input_reader : @ecs.MessageReader[MockInput],
  focus : @app.ResMut[@input_focus.InputFocus],
) -> Unit {
  @input_focus.dispatch_focused_input(input_reader, focus)
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
test "input_focus runtime plugin initializes resources and focused message queues" {
  let app = @app.App::new(@ecs.World::new())
    .add_message(@input.KeyboardInput::message())
    .add_message(@input.GamepadButtonChangedEvent::message())
    .add_message(@input.MouseWheel::message())
    .add_plugin(@input_focus.input_dispatch_plugin)
    .run_once()

  inspect(read_focus_resource(app.world()).get() is None, content="true")
  inspect(read_focus_visible_resource(app.world()).visible(), content="false")
  let keyboard_key : @ecs.MessageKey[
    @input_focus.FocusedInput[@input.KeyboardInput],
  ] = @input_focus.focused_input_message_key()
  let gamepad_key : @ecs.MessageKey[
    @input_focus.FocusedInput[@input.GamepadButtonChangedEvent],
  ] = @input_focus.focused_input_message_key()
  let wheel_key : @ecs.MessageKey[@input_focus.FocusedInput[@input.MouseWheel]] = @input_focus.focused_input_message_key()
  inspect(app.world().contains_message(keyboard_key), content="true")
  inspect(app.world().contains_message(gamepad_key), content="true")
  inspect(app.world().contains_message(wheel_key), content="true")
}

///|
test "input_focus runtime sets initial focus to primary window" {
  let app = @window.window_plugin_with(
    @app.App::new(@ecs.World::new())
    .add_message(@input.KeyboardInput::message())
    .add_message(@input.GamepadButtonChangedEvent::message())
    .add_message(@input.MouseWheel::message())
    .add_plugin(@input_focus.input_dispatch_plugin),
    @window.WindowPlugin::default(),
  ).run_once()
  let primary = match primary_window_entity(app.world()) {
    Some(entity) => entity
    None => abort("missing primary window")
  }
  inspect(
    read_focus_resource(app.world()).get() == Some(primary),
    content="true",
  )
}

///|
test "input_focus runtime dispatches and clears stale focus" {
  let world = @ecs.World::new()
  let primary = world.spawn()
  try! world.set_component(primary, @window.Window::default())
  try! world.set_component(primary, @window.PrimaryWindow::{  })
  world.init_message(@input.KeyboardInput::message())
  world.init_message(@input.GamepadButtonChangedEvent::message())
  world.init_message(@input.MouseWheel::message())
  world.init_message(MockInput::message())
  let focused = world.spawn()

  let app = @app.App::new(world)
    .add_plugin(@input_focus.input_dispatch_plugin)
    .add_systems(
      @app.PreUpdate,
      @app.system(@app.system_param2(dispatch_mock_input)).in_set(
        @input_focus.input_focus_system_set_name(
          @input_focus.InputFocusSystems::Dispatch,
        ),
      ),
    )
    .run_once()

  let focused_key : @ecs.MessageKey[@input_focus.FocusedInput[MockInput]] = @input_focus.focused_input_message_key()
  app.world().init_message(focused_key)
  let focus_ref = input_focus_resource_ref_mut(app.world())
  focus_ref.val.set(focused)
  ignore(app.world().send_message(MockInput::message(), MockInput::{ id: 7 }))

  let app = app.update()
  let focused_messages = read_focused_mock_inputs(app.world())
  inspect(focused_messages.length(), content="1")
  inspect(focused_messages[0].focused_entity == focused, content="true")
  inspect(focused_messages[0].window == primary, content="true")
  inspect(focused_messages[0].input.id, content="7")

  app.world().clear_messages(focused_key)
  app.world().despawn(focused)
  ignore(app.world().send_message(MockInput::message(), MockInput::{ id: 11 }))

  let app = app.update()
  let focused_messages = read_focused_mock_inputs(app.world())
  inspect(focused_messages.length(), content="1")
  inspect(focused_messages[0].focused_entity == primary, content="true")
  inspect(focused_messages[0].window == primary, content="true")
  inspect(focused_messages[0].input.id, content="11")
  inspect(read_focus_resource(app.world()).get() is None, content="true")
}

///|
test "input_focus runtime IsFocusedHelper follows hierarchy and visibility" {
  let world = @ecs.World::new()
  let primary = world.spawn()
  try! world.set_component(primary, @window.Window::default())
  try! world.set_component(primary, @window.PrimaryWindow::{  })
  world.init_message(@input.KeyboardInput::message())
  world.init_message(@input.GamepadButtonChangedEvent::message())
  world.init_message(@input.MouseWheel::message())

  let parent = world.spawn()
  let child = world.spawn()
  try! world.set_component(child, @hierarchy.Parent::new(parent))

  let helper_focus_within_parent : Ref[Bool] = Ref::new(false)
  let helper_focus_visible_parent : Ref[Bool] = Ref::new(false)
  let helper_focus_visible_child : Ref[Bool] = Ref::new(false)

  let app = @app.App::new(world)
    .add_plugin(@input_focus.input_dispatch_plugin)
    .add_systems(
      @app.Update,
      @app.system(
        @app.system_param(fn(helper : @input_focus.IsFocusedHelper) {
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

  inspect(
    @input_focus.IsFocused::is_focused(app.world(), child),
    content="true",
  )
  inspect(
    @input_focus.IsFocused::is_focus_within(app.world(), parent),
    content="true",
  )
  inspect(
    @input_focus.IsFocused::is_focus_within_visible(app.world(), parent),
    content="true",
  )
  inspect(helper_focus_within_parent.val, content="true")
  inspect(helper_focus_visible_parent.val, content="true")
  inspect(helper_focus_visible_child.val, content="true")
}
