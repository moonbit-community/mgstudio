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
/// UI-render API boundary aligned with Bevy crate responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/ui`.

///|
pub type UiAntiAlias = @ui.UiAntiAlias

///|
pub type BoxShadowSamples = @ui.UiBoxShadowSamples

///|
pub let ecs_key_ui_anti_alias : @ecs.ComponentKey[UiAntiAlias] = @ui.ecs_key_ui_anti_alias

///|
pub let ecs_key_ui_box_shadow_samples : @ecs.ComponentKey[BoxShadowSamples] = @ui.ecs_key_ui_box_shadow_samples

///|
pub let ui_render_set_extract : @app.SystemSet = @ui.ui_set_render_extract

///|
pub fn ui_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
  .add_post_update_system_config(
    @app.system(@ui.ui_render_extract_system).in_set(ui_render_set_extract),
  )
  .configure_set(
    @app.PostUpdate,
    ui_render_set_extract,
    after=[@ui.ui_set_stack],
    before=[@sprite_render.render2d_set_extract],
  )
}
