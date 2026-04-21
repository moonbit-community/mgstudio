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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/menu.rs`.
pub(all) enum MenuAction {
  Open
  Toggle
  Close
  CloseAll
  FocusRoot
} derive(Eq, Debug, ToJson, FromJson)

///|
pub struct MenuEvent {
  source : @core.Entity
  action : MenuAction
} derive(ToJson, FromJson)

///|
let menu_event_key : @ecs.EventKey[MenuEvent] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::MenuEvent",
)

///|
pub impl @ecs.TriggerEvent for MenuEvent with observer_event() {
  menu_event_key
}

///|
pub impl @ecs.TriggerEvent for MenuEvent with observer_entity(self) {
  Some(self.source)
}

///|
pub impl @ecs.TriggerEvent for MenuEvent with set_observer_entity(self, entity) {
  MenuEvent::{ source: entity, action: self.action }
}

///|
pub impl @ecs.TriggerEvent for MenuEvent with auto_propagate(_self) {
  true
}

///|
pub impl @ecs.TriggerEvent for MenuEvent with debug_name() {
  "MenuEvent"
}

///|
pub(all) enum MenuLayout {
  Column
  Row
  Grid
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MenuLayout::default() -> MenuLayout {
  MenuLayout::Column
}

///|
pub struct MenuPopup {
  layout : MenuLayout
} derive(ToJson, FromJson)

///|
pub fn MenuPopup::default() -> MenuPopup {
  MenuPopup::{ layout: MenuLayout::default() }
}

///|
pub struct MenuItem {} derive(ToJson, FromJson)

///|
pub let ecs_key_menu_popup : @ecs.ComponentKey[MenuPopup] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::MenuPopup",
)

///|
pub let ecs_key_menu_item : @ecs.ComponentKey[MenuItem] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::MenuItem",
)

///|
pub impl @ecs.Component for MenuPopup with component() {
  ecs_key_menu_popup
}

///|
pub impl @ecs.Component for MenuItem with component() {
  ecs_key_menu_item
}

///|
fn menu_on_key_input(
  keyboard : @input.ButtonInput[@window.KeyCode],
  focus : @app.Res[@input_focus.InputFocus],
  menu_item_query : @ecs.Query[
    (@ecs.Has[MenuItem], @ecs.Has[InteractionDisabled]),
    @ecs.All,
  ],
  menu_popup_query : @ecs.Query[@ecs.Has[MenuPopup], @ecs.All],
  commands : @app.Commands,
) -> Unit {
  guard focus.get().get() is Some(entity) else { return }
  let is_menu_item = match (menu_item_query.get(entity) catch { _ => None }) {
    Some((is_item, disabled)) => is_item.present() && !disabled.present()
    None => false
  }
  let is_menu_popup = match (menu_popup_query.get(entity) catch { _ => None }) {
    Some(has_popup) => has_popup.present()
    None => false
  }
  if is_menu_item &&
    (
      keyboard.just_pressed(@window.KeyCode::Enter) ||
      keyboard.just_pressed(@window.KeyCode::Space)
    ) {
    commands.trigger(Activate::{ entity, })
    commands.trigger(MenuEvent::{
      source: entity,
      action: MenuAction::FocusRoot,
    })
    commands.trigger(MenuEvent::{ source: entity, action: MenuAction::CloseAll })
    return
  }
  if is_menu_popup && keyboard.just_pressed(@window.KeyCode::Escape) {
    commands.trigger(MenuEvent::{
      source: entity,
      action: MenuAction::FocusRoot,
    })
    commands.trigger(MenuEvent::{ source: entity, action: MenuAction::CloseAll })
  }
}

///|
fn menu_item_on_pointer_down(
  pointer : @app.OnPointer[@app.PointerDown],
  menu_item_query : @ecs.Query[
    (@ecs.Has[MenuItem], @ecs.Has[InteractionDisabled]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (menu_item_query.get(entity) catch { _ => None })
    is Some((is_menu_item, disabled)) else {
    return
  }
  if !is_menu_item.present() || disabled.present() {
    return
  }
  commands.entity(entity).insert_component(Pressed::{  })
}

///|
fn menu_item_on_pointer_up(
  pointer : @app.OnPointer[@app.PointerUp],
  pressed_query : @ecs.Query[(@ecs.Has[MenuItem], @ecs.Has[Pressed]), @ecs.All],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (pressed_query.get(entity) catch { _ => None })
    is Some((is_menu_item, pressed)) else {
    return
  }
  if is_menu_item.present() && pressed.present() {
    commands.entity(entity).remove_component(ecs_key_pressed)
  }
}

///|
fn menu_item_on_pointer_click(
  pointer : @app.OnPointer[@app.PointerClick],
  menu_item_query : @ecs.Query[
    (@ecs.Has[MenuItem], @ecs.Has[InteractionDisabled]),
    @ecs.All,
  ],
  commands : @app.Commands,
) -> Unit {
  guard pointer.target() is Some(entity) else { return }
  guard (menu_item_query.get(entity) catch { _ => None })
    is Some((is_menu_item, disabled)) else {
    return
  }
  if !is_menu_item.present() || disabled.present() {
    return
  }
  commands.trigger(Activate::{ entity, })
  commands.trigger(MenuEvent::{ source: entity, action: MenuAction::FocusRoot })
  commands.trigger(MenuEvent::{ source: entity, action: MenuAction::CloseAll })
}

///|
pub fn menu_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_systems(@app.Update, @app.system(@app.system_param5(menu_on_key_input)))
  .add_pointer_observer3(menu_item_on_pointer_down)
  .add_pointer_observer3(menu_item_on_pointer_up)
  .add_pointer_observer3(menu_item_on_pointer_click)
}
