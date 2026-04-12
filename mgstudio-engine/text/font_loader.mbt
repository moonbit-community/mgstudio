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

///|
pub struct FontLoader {}

///|
pub fn FontLoader::default() -> FontLoader {
  FontLoader::{  }
}

///|
pub enum FontLoaderError {
  Content
  Io(String)
} derive(Eq, Debug)

///|
pub fn font_loader_error_content() -> FontLoaderError {
  Content
}

///|
pub fn font_loader_error_io(message : String) -> FontLoaderError {
  Io(message)
}

///|
pub fn font_loader_extensions() -> Array[String] {
  ["ttf", "otf"]
}
