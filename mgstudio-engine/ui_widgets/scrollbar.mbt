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
// Bevy source: `bevy/crates/bevy_ui_widgets/src/scrollbar.rs`.
pub using @ui {type ScrollPosition}

///|
pub let ecs_key_scroll_position : @ecs.ComponentKey[@ui.ScrollPosition] = @ui.ecs_key_scroll_position

///|
pub fn ui_widget_scroll_position_identity(
  value : ScrollPosition,
) -> ScrollPosition {
  value
}
