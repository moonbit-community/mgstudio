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
pub type BackgroundColor = @ui.BackgroundColor

///|
pub type BorderColor = @ui.BorderColor

///|
pub type BoxShadow = @ui.BoxShadow

///|
pub type Outline = @ui.Outline

///|
pub type CalculatedClip = @ui.CalculatedClip

///|
pub type ComputedUiTargetCamera = @ui.ComputedUiTargetCamera

///|
pub type ComputedUiRenderTargetInfo = @ui.ComputedUiRenderTargetInfo

///|
pub type ImageNode = @ui.ImageNode

///|
pub type BorderRect = @ui.BorderRect

///|
pub type SliceScaleMode = @ui.SliceScaleMode

///|
pub type NodeImageMode = @ui.NodeImageMode

///|
pub type TextureSlicer = @ui.TextureSlicer

///|
pub let ecs_key_ui_anti_alias : @ecs.ComponentKey[UiAntiAlias] = @ui.ecs_key_ui_anti_alias

///|
pub let ecs_key_ui_box_shadow_samples : @ecs.ComponentKey[BoxShadowSamples] = @ui.ecs_key_ui_box_shadow_samples

///|
pub let ecs_key_background_color : @ecs.ComponentKey[BackgroundColor] = @ui.ecs_key_background_color

///|
pub let ecs_key_border_color : @ecs.ComponentKey[BorderColor] = @ui.ecs_key_border_color

///|
pub let ecs_key_box_shadow : @ecs.ComponentKey[BoxShadow] = @ui.ecs_key_box_shadow

///|
pub let ecs_key_outline : @ecs.ComponentKey[Outline] = @ui.ecs_key_outline

///|
pub let ecs_key_calculated_clip : @ecs.ComponentKey[CalculatedClip] = @ui.ecs_key_calculated_clip

///|
pub let ecs_key_computed_ui_target_camera : @ecs.ComponentKey[
  ComputedUiTargetCamera,
] = @ui.ecs_key_computed_ui_target_camera

///|
pub let ecs_key_computed_ui_render_target_info : @ecs.ComponentKey[
  ComputedUiRenderTargetInfo,
] = @ui.ecs_key_computed_ui_render_target_info

///|
pub let ecs_key_image_node : @ecs.ComponentKey[ImageNode] = @ui.ecs_key_image_node

///|
pub let ui_render_set_extract : @app.SystemSet = @ui.ui_set_render_extract

///|
pub fn ui_render_extract_system(world : @ecs.World) -> Unit {
  @ui.ui_render_extract_system(world)
}

///|
pub fn ui_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_post_update_system_config(
    @app.system(ui_render_extract_system).in_set(ui_render_set_extract),
  )
}
