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
// Bevy source: `bevy/crates/bevy_ui/src/layout/convert.rs`.
pub using @ui {type ComputedUiRenderTargetInfo}

///|
pub let ecs_key_computed_ui_render_target_info : @ecs.ComponentKey[
  @ui.ComputedUiRenderTargetInfo,
] = @ui.ecs_key_computed_ui_render_target_info

///|
pub fn ui_update_context_system(world : @ecs.World) -> Unit {
  @ui.ui_update_context_system(world)
}

///|
pub fn ui_propagate_target_cameras_system(world : @ecs.World) -> Unit {
  @ui.ui_propagate_target_cameras_system(world)
}

///|
pub let ui_set_prepare : @app.SystemSet = @ui.ui_set_prepare

///|
pub let ui_set_context : @app.SystemSet = @ui.ui_set_context

///|
pub let ui_set_propagate : @app.SystemSet = @ui.ui_set_propagate
