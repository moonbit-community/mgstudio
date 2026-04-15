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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/lib.rs`.

///|
pub struct Activate {
  mut entity : @core.Entity
} derive(ToJson, FromJson)

///|
let activate_event_key : @ecs.EventKey[Activate] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::Activate",
)

///|
pub impl @ecs.TriggerEvent for Activate with observer_event() {
  activate_event_key
}

///|
pub impl @ecs.TriggerEvent for Activate with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for Activate with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.entity = entity
}

///|
pub impl @ecs.TriggerEvent for Activate with auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for Activate with debug_name() {
  "Activate"
}

///|
pub struct ValueChange[T] {
  mut source : @core.Entity
  value : T
} derive(ToJson, FromJson)

///|
fn[T] value_change_debug_name(_sample : T?) -> String {
  let type_name = @any.of(_sample).type_name()
  "mgstudio_ui_widgets::ValueChange<\{type_name}>"
}

///|
let value_change_event_id_by_debug_name_ref : Ref[Map[String, Int]] = Ref::new({})

///|
fn[T] value_change_event_key() -> @ecs.EventKey[ValueChange[T]] {
  let debug_name = value_change_debug_name((None : T?))
  match value_change_event_id_by_debug_name_ref.val.get(debug_name) {
    Some(id) => @ecs.event_key_from_id(id, debug_name~)
    None => {
      let key : @ecs.EventKey[ValueChange[T]] = @ecs.register_event(debug_name~)
      value_change_event_id_by_debug_name_ref.val.set(debug_name, key.id())
      key
    }
  }
}

///|
pub impl[T] @ecs.TriggerEvent for ValueChange[T] with observer_event() {
  value_change_event_key()
}

///|
pub impl[T] @ecs.TriggerEvent for ValueChange[T] with observer_entity(self) {
  Some(self.source)
}

///|
pub impl[T] @ecs.TriggerEvent for ValueChange[T] with set_observer_entity(
  event_ref,
  entity,
) {
  event_ref.val.source = entity
}

///|
pub impl[T] @ecs.TriggerEvent for ValueChange[T] with auto_propagate(_self) {
  false
}

///|
pub impl[T] @ecs.TriggerEvent for ValueChange[T] with debug_name() {
  "ValueChange"
}

///|
const UI_WIDGETS_PLUGINS_NAME : String = "mgstudio.ui_widgets.UiWidgetsPlugins"

///|
const UI_WIDGETS_POPOVER_PLUGIN_NAME : String = "mgstudio.ui_widgets.PopoverPlugin"

///|
const UI_WIDGETS_BUTTON_PLUGIN_NAME : String = "mgstudio.ui_widgets.ButtonPlugin"

///|
const UI_WIDGETS_CHECKBOX_PLUGIN_NAME : String = "mgstudio.ui_widgets.CheckboxPlugin"

///|
const UI_WIDGETS_MENU_PLUGIN_NAME : String = "mgstudio.ui_widgets.MenuPlugin"

///|
const UI_WIDGETS_RADIO_GROUP_PLUGIN_NAME : String = "mgstudio.ui_widgets.RadioGroupPlugin"

///|
const UI_WIDGETS_SCROLLBAR_PLUGIN_NAME : String = "mgstudio.ui_widgets.ScrollbarPlugin"

///|
const UI_WIDGETS_SLIDER_PLUGIN_NAME : String = "mgstudio.ui_widgets.SliderPlugin"

///|
pub struct PopoverWidgetPlugin {}

///|
pub fn PopoverWidgetPlugin::default() -> PopoverWidgetPlugin {
  PopoverWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for PopoverWidgetPlugin with name(_self) {
  UI_WIDGETS_POPOVER_PLUGIN_NAME
}

///|
pub impl @app.Plugin for PopoverWidgetPlugin with build(_self, app) {
  popover_plugin(app)
}

///|
pub struct ButtonWidgetPlugin {}

///|
pub fn ButtonWidgetPlugin::default() -> ButtonWidgetPlugin {
  ButtonWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for ButtonWidgetPlugin with name(_self) {
  UI_WIDGETS_BUTTON_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ButtonWidgetPlugin with build(_self, app) {
  button_plugin(app)
}

///|
pub struct CheckboxWidgetPlugin {}

///|
pub fn CheckboxWidgetPlugin::default() -> CheckboxWidgetPlugin {
  CheckboxWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for CheckboxWidgetPlugin with name(_self) {
  UI_WIDGETS_CHECKBOX_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CheckboxWidgetPlugin with build(_self, app) {
  checkbox_plugin(app)
}

///|
pub struct MenuWidgetPlugin {}

///|
pub fn MenuWidgetPlugin::default() -> MenuWidgetPlugin {
  MenuWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for MenuWidgetPlugin with name(_self) {
  UI_WIDGETS_MENU_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MenuWidgetPlugin with build(_self, app) {
  menu_plugin(app)
}

///|
pub struct RadioGroupWidgetPlugin {}

///|
pub fn RadioGroupWidgetPlugin::default() -> RadioGroupWidgetPlugin {
  RadioGroupWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for RadioGroupWidgetPlugin with name(_self) {
  UI_WIDGETS_RADIO_GROUP_PLUGIN_NAME
}

///|
pub impl @app.Plugin for RadioGroupWidgetPlugin with build(_self, app) {
  radio_group_plugin(app)
}

///|
pub struct ScrollbarWidgetPlugin {}

///|
pub fn ScrollbarWidgetPlugin::default() -> ScrollbarWidgetPlugin {
  ScrollbarWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for ScrollbarWidgetPlugin with name(_self) {
  UI_WIDGETS_SCROLLBAR_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ScrollbarWidgetPlugin with build(_self, app) {
  scrollbar_plugin(app)
}

///|
pub struct SliderWidgetPlugin {}

///|
pub fn SliderWidgetPlugin::default() -> SliderWidgetPlugin {
  SliderWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for SliderWidgetPlugin with name(_self) {
  UI_WIDGETS_SLIDER_PLUGIN_NAME
}

///|
pub impl @app.Plugin for SliderWidgetPlugin with build(_self, app) {
  slider_plugin(app)
}

///|
pub struct UiWidgetsPlugins {}

///|
pub fn UiWidgetsPlugins::default() -> UiWidgetsPlugins {
  UiWidgetsPlugins::{  }
}

///|
pub fn UiWidgetsPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named("UiWidgetsPlugins")
  .add(PopoverWidgetPlugin::default())
  .add(ButtonWidgetPlugin::default())
  .add(CheckboxWidgetPlugin::default())
  .add(MenuWidgetPlugin::default())
  .add(RadioGroupWidgetPlugin::default())
  .add(ScrollbarWidgetPlugin::default())
  .add(SliderWidgetPlugin::default())
}

///|
pub impl @app.Plugin for UiWidgetsPlugins with name(_self) {
  UI_WIDGETS_PLUGINS_NAME
}

///|
pub impl @app.Plugin for UiWidgetsPlugins with build(_self, app) {
  app.add_plugins(UiWidgetsPlugins::build())
}

///|
pub fn ui_widgets_plugins() -> UiWidgetsPlugins {
  UiWidgetsPlugins::default()
}

///|
pub struct UiWidgetsPluginMarker {}

///|
let ui_widgets_plugin_marker_key : @ecs.ResourceKey[UiWidgetsPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_ui_widgets::UiWidgetsPluginMarker",
)

///|
pub impl @app.Resource for UiWidgetsPluginMarker with resource() {
  ui_widgets_plugin_marker_key
}

///|
pub fn ui_widgets_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(ui_widgets_plugin_marker_key) {
    app
  } else {
    app
    .world()
    .insert_resource(ui_widgets_plugin_marker_key, UiWidgetsPluginMarker::{  })
    @ui.ui_plugin(app).add_plugins(ui_widgets_plugins())
  }
}
