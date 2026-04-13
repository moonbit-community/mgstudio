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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/radio.rs`.
pub struct RadioGroup {} derive(ToJson, FromJson)

///|
pub struct RadioButton {} derive(ToJson, FromJson)

///|
pub let ecs_key_radio_group : @ecs.ComponentKey[RadioGroup] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::RadioGroup",
)

///|
pub let ecs_key_radio_button : @ecs.ComponentKey[RadioButton] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::RadioButton",
)

///|
pub impl @ecs.Component for RadioGroup with component() {
  ecs_key_radio_group
}

///|
pub impl @ecs.Component for RadioButton with component() {
  ecs_key_radio_button
}

///|
fn trigger_radio_selection(
  entity : @core.Entity,
  radio_query : @ecs.Query[
    (
      @ecs.Has[RadioButton],
      @ecs.Has[InteractionDisabled],
      @ecs.Has[Checked],
      @ecs.Comp[@hierarchy.Parent]?,
    ),
    @ecs.All,
  ],
  group_query : @ecs.Query[@ecs.Has[RadioGroup], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  guard (radio_query.get(entity) catch { _ => None })
    is Some((is_radio, disabled, checked, parent_comp)) else {
    return
  }
  if !is_radio.present() {
    return
  }
  if disabled.present() || checked.present() {
    return
  }
  commands.trigger(ValueChange::{ source: entity, value: true })
  guard parent_comp is Some(parent_comp) else { return }
  let parent_entity = parent_comp.value().entity()
  if (group_query.get(parent_entity) catch { _ => None }) is Some(is_group) &&
    is_group.present() {
    commands.trigger(ValueChange::{ source: parent_entity, value: entity })
  }
}

///|
fn radio_button_on_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  radio_query : @ecs.Query[
    (
      @ecs.Has[RadioButton],
      @ecs.Has[InteractionDisabled],
      @ecs.Has[Checked],
      @ecs.Comp[@hierarchy.Parent]?,
    ),
    @ecs.All,
  ],
  group_query : @ecs.Query[@ecs.Has[RadioGroup], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  trigger_radio_selection(entity, radio_query, group_query, commands)
}

///|
fn radio_button_on_key_input(
  keyboard : @input.ButtonInput[@window.KeyCode],
  focus : @app.Res[@input_focus.InputFocus],
  radio_query : @ecs.Query[
    (
      @ecs.Has[RadioButton],
      @ecs.Has[InteractionDisabled],
      @ecs.Has[Checked],
      @ecs.Comp[@hierarchy.Parent]?,
    ),
    @ecs.All,
  ],
  group_query : @ecs.Query[@ecs.Has[RadioGroup], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Enter) &&
    !keyboard.just_pressed(@window.KeyCode::Space) {
    return
  }
  guard focus.get().get() is Some(entity) else { return }
  trigger_radio_selection(entity, radio_query, group_query, commands)
}

///|
pub fn radio_group_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_systems(
    @app.Update,
    @app.system(@app.system_param5(radio_button_on_key_input)),
  )
  .add_pointer_observer4(radio_button_on_pointer_click)
}
