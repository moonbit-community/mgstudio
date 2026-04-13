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
// Bevy source: `bevy/crates/bevy_ui/src/layout/ui_surface.rs`.
pub using @ui {type ContentSize}

///|
pub using @ui {type ScrollPosition}

///|
pub using @ui {type UiLayout}

///|
pub let ecs_key_content_size : @ecs.ComponentKey[@ui.ContentSize] = @ui.ecs_key_content_size

///|
pub let ecs_key_scroll_position : @ecs.ComponentKey[@ui.ScrollPosition] = @ui.ecs_key_scroll_position

///|
pub let ecs_key_ui_layout : @ecs.ComponentKey[@ui.UiLayout] = @ui.ecs_key_ui_layout

///|
pub fn ui_layout_system(world : @ecs.World) -> Unit {
  @ui.ui_layout_system(world)
}

///|
pub fn ui_image_content_size_system(world : @ecs.World) -> Unit {
  @ui.ui_image_content_size_system(world)
}

///|
pub fn ui_clip_system(world : @ecs.World) -> Unit {
  @ui.ui_clip_system(world)
}

///|
pub fn ui_scroll_system(world : @ecs.World) -> Unit {
  @ui.ui_scroll_system(world)
}

///|
pub fn ui_stack_system(world : @ecs.World) -> Unit {
  @ui.ui_stack_system(world)
}
