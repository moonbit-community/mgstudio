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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/observe.rs`.
pub using @ui {type Interaction}

///|
pub let ecs_key_interaction : @ecs.ComponentKey[@ui.Interaction] = @ui.ecs_key_interaction

///|
pub let ui_widgets_set_interaction : @app.SystemSet = @ui.ui_set_interaction

///|
pub fn ui_interaction_system(world : @ecs.World) -> Unit {
  @ui.ui_interaction_system(world)
}

///|
pub struct InteractionDisabled {} derive(ToJson, FromJson)

///|
pub struct Pressed {} derive(ToJson, FromJson)

///|
pub struct Checkable {} derive(ToJson, FromJson)

///|
pub struct Checked {} derive(ToJson, FromJson)

///|
pub let ecs_key_interaction_disabled : @ecs.ComponentKey[InteractionDisabled] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::InteractionDisabled",
)

///|
pub let ecs_key_pressed : @ecs.ComponentKey[Pressed] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::Pressed",
)

///|
pub let ecs_key_checkable : @ecs.ComponentKey[Checkable] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::Checkable",
)

///|
pub let ecs_key_checked : @ecs.ComponentKey[Checked] = @ecs.register_component(
  debug_name="mgstudio_ui_widgets::Checked",
)

///|
pub impl @ecs.Component for InteractionDisabled with component() {
  ecs_key_interaction_disabled
}

///|
pub impl @ecs.Component for Pressed with component() {
  ecs_key_pressed
}

///|
pub impl @ecs.Component for Checkable with component() {
  ecs_key_checkable
}

///|
pub impl @ecs.Component for Checked with component() {
  ecs_key_checked
}

///|
pub fn[E : @ecs.TriggerEvent] observe(
  commands : @app.EntityCommands,
  observer : (@ecs.On[E]) -> Unit raise,
) -> @app.EntityCommands {
  commands.observe_fallible(observer)
}
