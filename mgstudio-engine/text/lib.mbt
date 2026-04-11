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
// Bevy source: `bevy/crates/bevy_text/src/text.rs`.
// Runtime wrappers live in this file while the broader text implementation stays split across the package.

///|
pub(all) struct Text {
  mut content : String
}

///|
pub fn Text::default() -> Text {
  Text::new("")
}

///|
pub fn Text::new(content : String) -> Text {
  Text::{ content, }
}

///|
pub(all) struct Text2d {
  mut content : String
}

///|
pub fn Text2d::default() -> Text2d {
  Text2d::new("")
}

///|
pub fn Text2d::new(content : String) -> Text2d {
  Text2d::{ content, }
}

///|
pub(all) struct TextSpan {
  mut content : String
}

///|
pub fn TextSpan::default() -> TextSpan {
  TextSpan::new("")
}

///|
pub fn TextSpan::new(content : String) -> TextSpan {
  TextSpan::{ content, }
}

///|
pub fn text_bundle(
  content : String,
  font : TextFont,
  transform : @transform.Transform,
) -> Text2dBundle {
  Text2dBundle::new(Text2d::new(content), font, transform)
}
