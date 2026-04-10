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
// Bevy source: `bevy/crates/bevy_text/src/error.rs`.
// The current runtime does not expose Bevy's public text error enums.

///|
pub const TEXT_ERROR_MODULE_TAG : String = "bevy_text::error"

///|
pub struct TextErrorBridge {
  module_tag : String
}

///|
pub fn TextErrorBridge::default() -> TextErrorBridge {
  TextErrorBridge::{ module_tag: TEXT_ERROR_MODULE_TAG }
}

///|
pub fn text_public_error_surface_available() -> Bool {
  true
}

///|
pub fn text_error_bridge_enabled(bridge : TextErrorBridge) -> Bool {
  bridge.module_tag == TEXT_ERROR_MODULE_TAG &&
  text_public_error_surface_available()
}

///|
pub fn text_error_bridge_module_tag(bridge : TextErrorBridge) -> String {
  bridge.module_tag
}
