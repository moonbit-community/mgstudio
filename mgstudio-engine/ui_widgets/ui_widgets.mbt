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
/// UI-widgets API boundary aligned with Bevy crate responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/ui`.

///|
pub type Interaction = @ui.Interaction

///|
pub type Button = @ui.Button

///|
pub type Label = @ui.Label

///|
pub type ButtonColors = @ui.ButtonColors

///|
pub let ecs_key_interaction : @ecs.ComponentKey[Interaction] = @ui.ecs_key_interaction

///|
pub let ecs_key_button : @ecs.ComponentKey[Button] = @ui.ecs_key_button

///|
pub let ecs_key_label : @ecs.ComponentKey[Label] = @ui.ecs_key_label

///|
pub let ecs_key_button_colors : @ecs.ComponentKey[ButtonColors] = @ui.ecs_key_button_colors

///|
pub let ui_widgets_set_interaction : @app.SystemSet = @ui.ui_set_interaction

///|
pub fn ui_interaction_system(world : @ecs.World) -> Unit {
  @ui.ui_interaction_system(world)
}

///|
pub fn ui_widgets_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_pre_update_system_config(
    @app.system(@ui.ui_update_context_system).in_set(@ui.ui_set_focus),
  )
  .add_pre_update_system_config(
    @app.system(ui_interaction_system).in_set(ui_widgets_set_interaction),
  )
  .configure_set(@app.PreUpdate, ui_widgets_set_interaction)
}
