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

///|
pub using @ui {type ContentSize}

///|
pub using @ui {type ScrollPosition}

///|
pub using @ui {type UiLayout}

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_computed_ui_render_target_info : @ecs.ComponentKey[
  @ui.ComputedUiRenderTargetInfo,
] = @ui.ecs_key_computed_ui_render_target_info

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_content_size : @ecs.ComponentKey[@ui.ContentSize] = @ui.ecs_key_content_size

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_scroll_position : @ecs.ComponentKey[@ui.ScrollPosition] = @ui.ecs_key_scroll_position

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_ui_layout : @ecs.ComponentKey[@ui.UiLayout] = @ui.ecs_key_ui_layout

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
// Bridge surface to the root `ui` package implementation.
pub let ui_set_text_content : @app.SystemSet = @ui.ui_set_text_content

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_prepare : @app.SystemSet = @ui.ui_set_prepare

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_context : @app.SystemSet = @ui.ui_set_context

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_interaction : @app.SystemSet = @ui.ui_set_interaction

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_content : @app.SystemSet = @ui.ui_set_content

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_measure : @app.SystemSet = @ui.ui_set_measure

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_layout : @app.SystemSet = @ui.ui_set_layout

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_post_layout : @app.SystemSet = @ui.ui_set_post_layout

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_stack : @app.SystemSet = @ui.ui_set_stack

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_propagate : @app.SystemSet = @ui.ui_set_propagate

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_scroll : @app.SystemSet = @ui.ui_set_scroll

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_clip : @app.SystemSet = @ui.ui_set_clip

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_a11y : @app.SystemSet = @ui.ui_set_a11y

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_a11y_apply : @app.SystemSet = @ui.ui_set_a11y_apply
