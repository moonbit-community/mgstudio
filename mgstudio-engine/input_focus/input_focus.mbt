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
pub struct InputFocus {
  mut focused_entity : @core.Entity?
}

///|
pub fn InputFocus::default() -> InputFocus {
  InputFocus::{ focused_entity: None }
}

///|
pub fn InputFocus::from_entity(entity : @core.Entity) -> InputFocus {
  InputFocus::{ focused_entity: Some(entity) }
}

///|
pub fn InputFocus::set(self : InputFocus, entity : @core.Entity) -> Unit {
  self.focused_entity = Some(entity)
}

///|
pub fn InputFocus::get(self : InputFocus) -> @core.Entity? {
  self.focused_entity
}

///|
pub fn InputFocus::clear(self : InputFocus) -> Unit {
  self.focused_entity = None
}

///|
pub struct InputFocusVisible {
  mut visible : Bool
}

///|
pub fn InputFocusVisible::default() -> InputFocusVisible {
  InputFocusVisible::{ visible: false }
}

///|
pub fn InputFocusVisible::new(visible : Bool) -> InputFocusVisible {
  InputFocusVisible::{ visible, }
}

///|
pub fn InputFocusVisible::visible(self : InputFocusVisible) -> Bool {
  self.visible
}

///|
pub fn InputFocusVisible::set_visible(
  self : InputFocusVisible,
  visible : Bool,
) -> Unit {
  self.visible = visible
}

///|
pub struct FocusedInput[M] {
  focused_entity : @core.Entity
  input : M
  window : @core.Entity
}

///|
pub fn[M] FocusedInput::new(
  focused_entity : @core.Entity,
  input : M,
  window : @core.Entity,
) -> FocusedInput[M] {
  FocusedInput::{ focused_entity, input, window }
}

///|
pub(all) enum InputFocusSystems {
  Dispatch
} derive(Eq, Debug)

///|
pub fn input_focus_system_set_name(
  stage_set : InputFocusSystems,
) -> @app.SystemSet {
  match stage_set {
    Dispatch =>
      @app.system_set("mgstudio.input_focus.InputFocusSystems.Dispatch")
  }
}

///|
pub(open) trait IsFocused {
  is_focused(Self, @core.Entity) -> Bool
  is_focus_within(Self, @core.Entity) -> Bool
  is_focus_visible(Self, @core.Entity) -> Bool
  is_focus_within_visible(Self, @core.Entity) -> Bool
}

///|
pub struct IsFocusedHelper {
  world : @ecs.World
}

///|
pub struct InputDispatchPlugin {}

///|
pub fn InputDispatchPlugin::default() -> InputDispatchPlugin {
  InputDispatchPlugin::{  }
}

///|
pub impl @app.Plugin for InputDispatchPlugin with name(_self) {
  "mgstudio.input_focus.InputDispatchPlugin"
}

///|
pub impl @app.Plugin for InputDispatchPlugin with build(_self, app) {
  input_dispatch_plugin(app)
}

///|
let input_focus_resource_key : @ecs.ResourceKey[InputFocus] = @ecs.register_resource(
  debug_name="mgstudio_input_focus::InputFocus",
)

///|
let input_focus_visible_resource_key : @ecs.ResourceKey[InputFocusVisible] = @ecs.register_resource(
  debug_name="mgstudio_input_focus::InputFocusVisible",
)

///|
let focused_input_message_registry : Ref[@hashmap.HashMap[Int, @any.Any]] = Ref(
  @hashmap.HashMap([]),
)

///|
fn current_input_focus_world_abort_missing() -> @ecs.World {
  match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "mgstudio_input_focus helper functions require an active app world; use direct world resource access outside scheduled systems",
      )
  }
}

///|
fn[T] input_focus_world_resource(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
) -> T? {
  try world.get_resource(key) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn input_focus_world_resource_ref_mut(
  world : @ecs.World,
  key : @ecs.ResourceKey[InputFocus],
) -> @ecs.ResourceMut[InputFocus]? {
  try world.get_resource_mut(key) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn input_focus_primary_window_entity(world : @ecs.World) -> @core.Entity? {
  @window.window_entity_for_ref(world, @window.WindowRef::Primary)
}

///|
fn input_focus_parent_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> @core.Entity? {
  match
    (
      try world.entity(entity).get() catch {
        _ => None
      } noraise {
        value => value
      } : @hierarchy.Parent?) {
    Some(parent) => Some(parent.entity())
    None => None
  }
}

///|
fn input_focus_is_within_ancestor(
  world : @ecs.World,
  current : @core.Entity?,
  entity : @core.Entity,
) -> Bool {
  match current {
    Some(current_entity) =>
      if current_entity == entity {
        true
      } else {
        input_focus_is_within_ancestor(
          world,
          input_focus_parent_entity(world, current_entity),
          entity,
        )
      }
    None => false
  }
}

///|
pub fn[M : @ecs.Message] focused_input_message_key() -> @ecs.MessageKey[
  FocusedInput[M],
] {
  let source_key = M::message()
  let source_id = source_key.id()
  match focused_input_message_registry.val.get(source_id) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "focused input registry contained a mismatched key for \{source_key.debug_name()}",
          )
      }
    None => {
      let key : @ecs.MessageKey[FocusedInput[M]] = @ecs.register_message(
        debug_name="mgstudio_input_focus::FocusedInput<\{source_key.debug_name()}>",
      )
      focused_input_message_registry.val.set(source_id, @any.Any::of(key))
      key
    }
  }
}

///|
pub impl @app.Resource for InputFocus with resource() {
  input_focus_resource_key
}

///|
pub impl @app.Resource for InputFocusVisible with resource() {
  input_focus_visible_resource_key
}

///|
pub impl[M : @ecs.Message] @ecs.Message for FocusedInput[M] with message() {
  focused_input_message_key()
}

///|
pub impl IsFocused for @ecs.World with is_focused(self, entity) {
  match input_focus_world_resource(self, InputFocus::resource()) {
    Some(focus) => focus.get() == Some(entity)
    None => false
  }
}

///|
pub impl IsFocused for @ecs.World with is_focus_within(self, entity) {
  guard input_focus_world_resource(self, InputFocus::resource()) is Some(focus) else {
    return false
  }
  guard focus.get() is Some(focused_entity) else { return false }
  if focused_entity == entity {
    return true
  }
  if !self.is_alive(focused_entity) {
    return false
  }
  input_focus_is_within_ancestor(
    self,
    input_focus_parent_entity(self, focused_entity),
    entity,
  )
}

///|
pub impl IsFocused for @ecs.World with is_focus_visible(self, entity) {
  let focus_visible = match
    input_focus_world_resource(self, InputFocusVisible::resource()) {
    Some(visible) => visible.visible()
    None => false
  }
  focus_visible && IsFocused::is_focused(self, entity)
}

///|
pub impl IsFocused for @ecs.World with is_focus_within_visible(self, entity) {
  let focus_visible = match
    input_focus_world_resource(self, InputFocusVisible::resource()) {
    Some(visible) => visible.visible()
    None => false
  }
  focus_visible && IsFocused::is_focus_within(self, entity)
}

///|
pub impl IsFocused for IsFocusedHelper with is_focused(self, entity) {
  IsFocused::is_focused(self.world, entity)
}

///|
pub impl IsFocused for IsFocusedHelper with is_focus_within(self, entity) {
  IsFocused::is_focus_within(self.world, entity)
}

///|
pub impl IsFocused for IsFocusedHelper with is_focus_visible(self, entity) {
  IsFocused::is_focus_visible(self.world, entity)
}

///|
pub impl IsFocused for IsFocusedHelper with is_focus_within_visible(
  self,
  entity,
) {
  IsFocused::is_focus_within_visible(self.world, entity)
}

///|
pub impl @app.SystemParam for IsFocusedHelper with init_state(world) {
  @app.system_param_empty_state(world)
}

///|
pub impl @app.SystemParam for IsFocusedHelper with get(_state) {
  IsFocusedHelper::{ world: current_input_focus_world_abort_missing() }
}

///|
pub impl @app.SystemParam for IsFocusedHelper with store(self, state) {
  @app.system_param_store_no_state(self, state)
}

///|
pub fn set_initial_focus(world : @ecs.World) -> Unit {
  guard input_focus_primary_window_entity(world) is Some(window) else { return }
  guard input_focus_world_resource_ref_mut(world, InputFocus::resource())
    is Some(focus) else {
    return
  }
  if focus.peek().get() is None {
    focus.modify(fn(value) { value.set(window) })
  }
}

///|
pub fn[M : @ecs.Message] dispatch_focused_input(
  input_reader : @ecs.MessageReader[M],
  focus : @app.ResMut[InputFocus],
) -> Unit {
  let unread = try! input_reader.read()
  if unread.is_empty() {
    return
  }
  let world = current_input_focus_world_abort_missing()
  guard input_focus_primary_window_entity(world) is Some(window) else { return }
  let focused_entity = match focus.peek().get() {
    Some(entity) =>
      if world.is_alive(entity) {
        entity
      } else {
        focus.modify(fn(value) { value.clear() })
        window
      }
    None => window
  }
  let writer = world.message_writer(focused_input_message_key())
  for input in unread {
    ignore(writer.write(FocusedInput::new(focused_entity, input, window)))
  }
}

///|
fn focused_keyboard_input_message_key() -> @ecs.MessageKey[
  FocusedInput[@input.KeyboardInput],
] {
  let key : @ecs.MessageKey[FocusedInput[@input.KeyboardInput]] = focused_input_message_key()
  key
}

///|
fn focused_gamepad_button_input_message_key() -> @ecs.MessageKey[
  FocusedInput[@input.GamepadButtonChangedEvent],
] {
  let key : @ecs.MessageKey[FocusedInput[@input.GamepadButtonChangedEvent]] = focused_input_message_key()
  key
}

///|
fn focused_mouse_wheel_message_key() -> @ecs.MessageKey[
  FocusedInput[@input.MouseWheel],
] {
  let key : @ecs.MessageKey[FocusedInput[@input.MouseWheel]] = focused_input_message_key()
  key
}

///|
fn dispatch_focused_keyboard_input(
  input_reader : @ecs.MessageReader[@input.KeyboardInput],
  focus : @app.ResMut[InputFocus],
) -> Unit {
  dispatch_focused_input(input_reader, focus)
}

///|
fn dispatch_focused_gamepad_button_input(
  input_reader : @ecs.MessageReader[@input.GamepadButtonChangedEvent],
  focus : @app.ResMut[InputFocus],
) -> Unit {
  dispatch_focused_input(input_reader, focus)
}

///|
fn dispatch_focused_mouse_wheel(
  input_reader : @ecs.MessageReader[@input.MouseWheel],
  focus : @app.ResMut[InputFocus],
) -> Unit {
  dispatch_focused_input(input_reader, focus)
}

///|
pub fn input_dispatch_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { InputFocus::default() })
  .init_resource(fn() { InputFocusVisible::default() })
  .add_message(focused_keyboard_input_message_key())
  .add_message(focused_gamepad_button_input_message_key())
  .add_message(focused_mouse_wheel_message_key())
  .add_systems(@app.PostStartup, @app.system(set_initial_focus))
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param2(dispatch_focused_keyboard_input)).in_set(
      input_focus_system_set_name(Dispatch),
    ),
  )
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param2(dispatch_focused_gamepad_button_input)).in_set(
      input_focus_system_set_name(Dispatch),
    ),
  )
  .add_systems(
    @app.PreUpdate,
    @app.system(@app.system_param2(dispatch_focused_mouse_wheel)).in_set(
      input_focus_system_set_name(Dispatch),
    ),
  )
}

///|
pub fn is_focus_visible(world : @ecs.World, entity : @core.Entity) -> Bool {
  IsFocused::is_focus_visible(world, entity)
}

///|
pub fn is_focus_within(world : @ecs.World, entity : @core.Entity) -> Bool {
  IsFocused::is_focus_within(world, entity)
}

///|
pub fn is_focus_within_visible(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  IsFocused::is_focus_within_visible(world, entity)
}

///|
pub fn is_focused(world : @ecs.World, entity : @core.Entity) -> Bool {
  IsFocused::is_focused(world, entity)
}
