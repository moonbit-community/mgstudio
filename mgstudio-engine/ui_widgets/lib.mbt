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
  entity : @core.Entity
} derive(ToJson, FromJson)

///|
let activate_event_key : @ecs.EventKey[Activate] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::Activate",
)

///|
pub impl @ecs.TriggerEvent for Activate with fn observer_event() {
  activate_event_key
}

///|
pub impl @ecs.TriggerEvent for Activate with fn observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for Activate with fn set_observer_entity(
  _self,
  entity,
) {
  { entity, }
}

///|
pub impl @ecs.TriggerEvent for Activate with fn auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for Activate with fn debug_name() {
  "Activate"
}

///|
pub struct ValueChange[T] {
  source : @core.Entity
  value : T
} derive(ToJson, FromJson)

///|
pub(open) trait ValueChangeValue {
  fn value_change_value_debug_name() -> String
  fn value_change_event_key() -> @ecs.EventKey[ValueChange[Self]]
}

///|
let bool_value_change_event_key : @ecs.EventKey[ValueChange[Bool]] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::ValueChange<Bool>",
)

///|
pub impl ValueChangeValue for Bool with fn value_change_value_debug_name() {
  "Bool"
}

///|
pub impl ValueChangeValue for Bool with fn value_change_event_key() {
  bool_value_change_event_key
}

///|
let float_value_change_event_key : @ecs.EventKey[ValueChange[Float]] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::ValueChange<Float>",
)

///|
pub impl ValueChangeValue for Float with fn value_change_value_debug_name() {
  "Float"
}

///|
pub impl ValueChangeValue for Float with fn value_change_event_key() {
  float_value_change_event_key
}

///|
let entity_value_change_event_key : @ecs.EventKey[ValueChange[@core.Entity]] = @ecs.register_event(
  debug_name="mgstudio_ui_widgets::ValueChange<mgstudio_core::Entity>",
)

///|
pub impl ValueChangeValue for @core.Entity with fn value_change_value_debug_name() {
  "mgstudio_core::Entity"
}

///|
pub impl ValueChangeValue for @core.Entity with fn value_change_event_key() {
  entity_value_change_event_key
}

///|
fn[T : ValueChangeValue] value_change_event_key() -> @ecs.EventKey[
  ValueChange[T],
] {
  T::value_change_event_key()
}

///|
pub impl[T : ValueChangeValue] @ecs.TriggerEvent for ValueChange[T] with fn observer_event() {
  value_change_event_key()
}

///|
pub impl[T : ValueChangeValue] @ecs.TriggerEvent for ValueChange[T] with fn observer_entity(
  self,
) {
  Some(self.source)
}

///|
pub impl[T : ValueChangeValue] @ecs.TriggerEvent for ValueChange[T] with fn set_observer_entity(
  self,
  entity,
) {
  { source: entity, value: self.value }
}

///|
pub impl[T : ValueChangeValue] @ecs.TriggerEvent for ValueChange[T] with fn auto_propagate(
  _self,
) {
  false
}

///|
pub impl[T : ValueChangeValue] @ecs.TriggerEvent for ValueChange[T] with fn debug_name() {
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
#warnings("-unnecessary_annotation")
pub fn PopoverWidgetPlugin::PopoverWidgetPlugin() -> PopoverWidgetPlugin {
  PopoverWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for PopoverWidgetPlugin with fn name(_self) {
  UI_WIDGETS_POPOVER_PLUGIN_NAME
}

///|
pub impl @app.Plugin for PopoverWidgetPlugin with fn build(_self, app) {
  popover_plugin(app)
}

///|
pub struct ButtonWidgetPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn ButtonWidgetPlugin::ButtonWidgetPlugin() -> ButtonWidgetPlugin {
  ButtonWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for ButtonWidgetPlugin with fn name(_self) {
  UI_WIDGETS_BUTTON_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ButtonWidgetPlugin with fn build(_self, app) {
  button_plugin(app)
}

///|
pub struct CheckboxWidgetPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn CheckboxWidgetPlugin::CheckboxWidgetPlugin() -> CheckboxWidgetPlugin {
  CheckboxWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for CheckboxWidgetPlugin with fn name(_self) {
  UI_WIDGETS_CHECKBOX_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CheckboxWidgetPlugin with fn build(_self, app) {
  checkbox_plugin(app)
}

///|
pub struct MenuWidgetPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn MenuWidgetPlugin::MenuWidgetPlugin() -> MenuWidgetPlugin {
  MenuWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for MenuWidgetPlugin with fn name(_self) {
  UI_WIDGETS_MENU_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MenuWidgetPlugin with fn build(_self, app) {
  menu_plugin(app)
}

///|
pub struct RadioGroupWidgetPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn RadioGroupWidgetPlugin::RadioGroupWidgetPlugin() -> RadioGroupWidgetPlugin {
  RadioGroupWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for RadioGroupWidgetPlugin with fn name(_self) {
  UI_WIDGETS_RADIO_GROUP_PLUGIN_NAME
}

///|
pub impl @app.Plugin for RadioGroupWidgetPlugin with fn build(_self, app) {
  radio_group_plugin(app)
}

///|
pub struct ScrollbarWidgetPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn ScrollbarWidgetPlugin::ScrollbarWidgetPlugin() -> ScrollbarWidgetPlugin {
  ScrollbarWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for ScrollbarWidgetPlugin with fn name(_self) {
  UI_WIDGETS_SCROLLBAR_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ScrollbarWidgetPlugin with fn build(_self, app) {
  scrollbar_plugin(app)
}

///|
pub struct SliderWidgetPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn SliderWidgetPlugin::SliderWidgetPlugin() -> SliderWidgetPlugin {
  SliderWidgetPlugin::{  }
}

///|
pub impl @app.Plugin for SliderWidgetPlugin with fn name(_self) {
  UI_WIDGETS_SLIDER_PLUGIN_NAME
}

///|
pub impl @app.Plugin for SliderWidgetPlugin with fn build(_self, app) {
  slider_plugin(app)
}

///|
pub struct UiWidgetsPlugins {}

///|
#warnings("-unnecessary_annotation")
pub fn UiWidgetsPlugins::UiWidgetsPlugins() -> UiWidgetsPlugins {
  UiWidgetsPlugins::{  }
}

///|
pub fn UiWidgetsPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named("UiWidgetsPlugins")
  .add(PopoverWidgetPlugin::PopoverWidgetPlugin())
  .add(ButtonWidgetPlugin::ButtonWidgetPlugin())
  .add(CheckboxWidgetPlugin::CheckboxWidgetPlugin())
  .add(MenuWidgetPlugin::MenuWidgetPlugin())
  .add(RadioGroupWidgetPlugin::RadioGroupWidgetPlugin())
  .add(ScrollbarWidgetPlugin::ScrollbarWidgetPlugin())
  .add(SliderWidgetPlugin::SliderWidgetPlugin())
}

///|
pub impl @app.Plugin for UiWidgetsPlugins with fn name(_self) {
  UI_WIDGETS_PLUGINS_NAME
}

///|
pub impl @app.Plugin for UiWidgetsPlugins with fn build(_self, app) {
  app.add_plugins(UiWidgetsPlugins::build())
}

///|
pub fn ui_widgets_plugins() -> UiWidgetsPlugins {
  UiWidgetsPlugins()
}

///|
pub struct UiWidgetsPluginMarker {}

///|
let ui_widgets_plugin_marker_key : @ecs.ResourceKey[UiWidgetsPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_ui_widgets::UiWidgetsPluginMarker",
)

///|
pub impl @app.Resource for UiWidgetsPluginMarker with fn resource() {
  ui_widgets_plugin_marker_key
}

///|
#warnings("-unnecessary_annotation")
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
