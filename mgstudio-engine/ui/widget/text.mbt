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
// Bevy source: `bevy/crates/bevy_ui/src/widget/text.rs`.
// Bridge surface to the root `ui` package implementation.
pub using @ui {type AccessibilityLabel}

///|
// Bridge surface to the root `ui` package implementation.
pub let ecs_key_accessibility_label : @ecs.ComponentKey[@ui.AccessibilityLabel] = @ui.ecs_key_accessibility_label

///|
// Bridge surface to the root `ui` package implementation.
pub let ui_set_text_content : @app.SystemSet = @ui.ui_set_text_content

///|
///|
pub struct UiWidgetTextBridge {
}

///|
pub fn UiWidgetTextBridge::default() -> UiWidgetTextBridge {
  UiWidgetTextBridge::{  }
}

///|
pub fn ui_widget_text_bridge_enabled(_ : UiWidgetTextBridge) -> Bool {
  true
}

