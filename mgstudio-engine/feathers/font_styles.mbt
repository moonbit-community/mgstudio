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
// Bevy source: `bevy/crates/bevy_feathers/src/font_styles.rs`.

///|
pub struct InheritableFont {
  font : HandleOrPath[String]
  font_size_px : Float
}

///|
pub fn InheritableFont::default() -> InheritableFont {
  InheritableFont::{ font: Path(FONT_REGULAR), font_size_px: 16.0 }
}

///|
pub fn InheritableFont::from_handle(handle : String) -> InheritableFont {
  InheritableFont::{ font: Handle(handle), font_size_px: 16.0 }
}

///|
pub fn InheritableFont::from_path(path : String) -> InheritableFont {
  InheritableFont::{ font: Path(path), font_size_px: 16.0 }
}

///|
let inheritable_font_component_key : @ecs.ComponentKey[InheritableFont] = @ecs.register_component(
  debug_name="mgstudio_feathers::InheritableFont",
)

///|
pub impl @ecs.Component for InheritableFont with component() {
  inheritable_font_component_key
}
