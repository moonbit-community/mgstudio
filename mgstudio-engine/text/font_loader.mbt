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
// Bevy source: `bevy/crates/bevy_text/src/font_loader.rs`.
// The current runtime resolves fonts through the shared text pipeline instead of a separate public loader API.

///|
pub const TEXT_FONT_LOADER_MODULE_TAG : String = "bevy_text::font_loader"

///|
pub struct TextFontLoaderBridge {
  module_tag : String
}

///|
pub fn TextFontLoaderBridge::default() -> TextFontLoaderBridge {
  TextFontLoaderBridge::{ module_tag: TEXT_FONT_LOADER_MODULE_TAG }
}

///|
pub fn text_font_loader_available() -> Bool {
  true
}

///|
pub fn text_font_loader_bridge_enabled(bridge : TextFontLoaderBridge) -> Bool {
  bridge.module_tag == TEXT_FONT_LOADER_MODULE_TAG &&
  text_font_loader_available()
}

///|
pub fn text_font_loader_bridge_module_tag(
  bridge : TextFontLoaderBridge,
) -> String {
  bridge.module_tag
}
