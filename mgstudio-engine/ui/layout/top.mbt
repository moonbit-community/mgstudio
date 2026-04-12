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
// and `ui_surface.mbt`.

///|
pub fn ui_layout_system_sets() -> Array[@app.SystemSet] {
  [
    ui_set_prepare, ui_set_context, ui_set_propagate, ui_set_text_content, ui_set_interaction,
    ui_set_content, ui_set_measure, ui_set_layout, ui_set_post_layout, ui_set_stack,
    ui_set_scroll, ui_set_clip, ui_set_a11y, ui_set_a11y_apply,
  ]
}
