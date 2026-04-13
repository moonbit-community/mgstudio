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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/checkbox.rs`.
pub struct Checkbox {} derive(ToJson, FromJson)

///|
pub let ecs_key_checkbox : @ecs.ComponentKey[Checkbox] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::Checkbox",
)

///|
pub impl @ecs.Component for Checkbox with component() {
  ecs_key_checkbox
}

///|
pub struct SetChecked {
  mut entity : @core.Entity
  checked : Bool
} derive(ToJson, FromJson)

///|
let set_checked_event_key : @ecs.EventKey[SetChecked] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::SetChecked",
)

///|
pub impl @ecs.TriggerEvent for SetChecked with observer_event() {
  set_checked_event_key
}

///|
pub impl @ecs.TriggerEvent for SetChecked with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for SetChecked with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.entity = entity
}

///|
pub impl @ecs.TriggerEvent for SetChecked with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for SetChecked with debug_name() {
  "SetChecked"
}

///|
pub struct ToggleChecked {
  mut entity : @core.Entity
} derive(ToJson, FromJson)

///|
let toggle_checked_event_key : @ecs.EventKey[ToggleChecked] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::ToggleChecked",
)

///|
pub impl @ecs.TriggerEvent for ToggleChecked with observer_event() {
  toggle_checked_event_key
}

///|
pub impl @ecs.TriggerEvent for ToggleChecked with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for ToggleChecked with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.entity = entity
}

///|
pub impl @ecs.TriggerEvent for ToggleChecked with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for ToggleChecked with debug_name() {
  "ToggleChecked"
}

///|
fn checkbox_on_key_input(
  keyboard : @input.ButtonInput[@window.KeyCode],
  focus : @app.Res[@input_focus.InputFocus],
  checkbox_query : @ecs.Query[
    (@ecs.Has[Checkbox], @ecs.Has[InteractionDisabled], @ecs.Has[Checked]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Enter) &&
    !keyboard.just_pressed(@window.KeyCode::Space) {
    return
  }
  guard focus.get().get() is Some(entity) else { return }
  guard (checkbox_query.get(entity) catch { _ => None })
    is Some((is_checkbox, disabled, is_checked)) else {
    return
  }
  if !is_checkbox.present() || disabled.present() {
    return
  }
  commands.trigger(ValueChange::{ source: entity, value: !is_checked.present() })
}

///|
fn checkbox_on_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  checkbox_query : @ecs.Query[
    (@ecs.Has[Checkbox], @ecs.Has[InteractionDisabled], @ecs.Has[Checked]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (checkbox_query.get(entity) catch { _ => None })
    is Some((is_checkbox, disabled, is_checked)) else {
    return
  }
  if !is_checkbox.present() || disabled.present() {
    return
  }
  commands.trigger(ValueChange::{ source: entity, value: !is_checked.present() })
}

///|
fn checkbox_on_set_checked(
  event : @ecs.On[SetChecked],
  checkbox_query : @ecs.Query[
    (@ecs.Has[Checkbox], @ecs.Has[InteractionDisabled], @ecs.Has[Checked]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  let payload = event.event()
  let entity = payload.entity
  guard (checkbox_query.get(entity) catch { _ => None })
    is Some((is_checkbox, disabled, is_checked)) else {
    return
  }
  if !is_checkbox.present() ||
    disabled.present() ||
    is_checked.present() == payload.checked {
    return
  }
  commands.trigger(ValueChange::{ source: entity, value: payload.checked })
}

///|
fn checkbox_on_toggle_checked(
  event : @ecs.On[ToggleChecked],
  checkbox_query : @ecs.Query[
    (@ecs.Has[Checkbox], @ecs.Has[InteractionDisabled], @ecs.Has[Checked]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  let payload = event.event()
  let entity = payload.entity
  guard (checkbox_query.get(entity) catch { _ => None })
    is Some((is_checkbox, disabled, is_checked)) else {
    return
  }
  if !is_checkbox.present() || disabled.present() {
    return
  }
  commands.trigger(ValueChange::{ source: entity, value: !is_checked.present() })
}

///|
pub fn checkbox_self_update(
  value_change : @ecs.On[ValueChange[Bool]],
  checkbox_query : @ecs.Query[@ecs.Has[Checkbox], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  let payload = value_change.event()
  let entity = payload.source
  guard (checkbox_query.get(entity) catch { _ => None }) is Some(is_checkbox) else {
    return
  }
  if !is_checkbox.present() {
    return
  }
  if payload.value {
    commands.entity(entity).insert_component(Checked::{  })
  } else {
    commands.entity(entity).remove_component(ecs_key_checked)
  }
}

///|
pub fn checkbox_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(checkbox_on_key_input)),
  )
  .add_pointer_observer3(checkbox_on_pointer_click)
  .add_observer3(checkbox_on_set_checked)
  .add_observer3(checkbox_on_toggle_checked)
}
