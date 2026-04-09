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
// Bevy source: `bevy/crates/bevy_ui/src/widget/viewport.rs`.
// Bridge surface to the root `ui` package implementation.
pub using @ui {type ComputedUiRenderTargetInfo}

///|
pub using @ui {type ComputedUiTargetCamera}

///|
pub using @ui {type IsDefaultUiCamera}

///|
pub using @ui {type UiTargetCamera}

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_computed_ui_render_target_info : @ecs.ComponentKey[
  @ui.ComputedUiRenderTargetInfo,
] = @ui.ecs_key_computed_ui_render_target_info

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_computed_ui_target_camera : @ecs.ComponentKey[
  @ui.ComputedUiTargetCamera,
] = @ui.ecs_key_computed_ui_target_camera

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_is_default_ui_camera : @ecs.ComponentKey[@ui.IsDefaultUiCamera] = @ui.ecs_key_is_default_ui_camera

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_ui_target_camera : @ecs.ComponentKey[@ui.UiTargetCamera] = @ui.ecs_key_ui_target_camera

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_propagate_target_cameras_system(world : @ecs.World) -> Unit {
  @ui.ui_propagate_target_cameras_system(world)
}
