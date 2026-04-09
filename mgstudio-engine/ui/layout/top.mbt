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
// Bevy source: `bevy/crates/bevy_ui/src/layout/mod.rs`.
// Bridge surface to the root `ui` package implementation.
pub using @ui {type ComputedUiRenderTargetInfo}
pub using @ui {type ContentSize}
pub using @ui {type ScrollPosition}
pub using @ui {type UiLayout}

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_computed_ui_render_target_info : @ecs.ComponentKey[
  @ui.ComputedUiRenderTargetInfo,
] = @ui.ecs_key_computed_ui_render_target_info

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_content_size : @ecs.ComponentKey[@ui.ContentSize] =
  @ui.ecs_key_content_size

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_scroll_position : @ecs.ComponentKey[@ui.ScrollPosition] =
  @ui.ecs_key_scroll_position

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_ui_layout : @ecs.ComponentKey[@ui.UiLayout] =
  @ui.ecs_key_ui_layout

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_layout_system(world : @ecs.World) -> Unit {
  @ui.ui_layout_system(world)
}

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_image_content_size_system(world : @ecs.World) -> Unit {
  @ui.ui_image_content_size_system(world)
}

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_update_context_system(world : @ecs.World) -> Unit {
  @ui.ui_update_context_system(world)
}

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_clip_system(world : @ecs.World) -> Unit {
  @ui.ui_clip_system(world)
}

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_scroll_system(world : @ecs.World) -> Unit {
  @ui.ui_scroll_system(world)
}

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_stack_system(world : @ecs.World) -> Unit {
  @ui.ui_stack_system(world)
}

///|
// Bridge surface to the root `ui` package implementation.
pub fn ui_propagate_target_cameras_system(world : @ecs.World) -> Unit {
  @ui.ui_propagate_target_cameras_system(world)
}

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_content : String = @ui.ui_set_content

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_measure : String = @ui.ui_set_measure

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_prepare : String = @ui.ui_set_prepare

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_layout : String = @ui.ui_set_layout

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_post_layout : String = @ui.ui_set_post_layout

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_stack : String = @ui.ui_set_stack

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_propagate : String = @ui.ui_set_propagate

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_scroll : String = @ui.ui_set_scroll

///|
// Pending: layout-internal types like `LayoutContext` and `LayoutError` do not
// have a verified root-package bridge yet.
pub let ui_set_clip : String = @ui.ui_set_clip
