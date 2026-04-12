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

///|
pub enum TextError {
  NoSuchFont
  NoSuchFontFamily(String)
  FailedToAddGlyph(UInt)
  FailedToGetGlyphImage(UInt)
  MissingAtlasLayout
  MissingAtlasTexture
  InconsistentAtlasState
  DegenerateScaleFactor
} derive(Eq, Debug)

///|
pub fn text_error_from_code(
  code : Int,
  message? : String = "",
  glyph? : UInt = 0U,
) -> TextError {
  match code {
    0 => NoSuchFont
    1 => NoSuchFontFamily(message)
    2 => FailedToAddGlyph(glyph)
    3 => FailedToGetGlyphImage(glyph)
    4 => MissingAtlasLayout
    5 => MissingAtlasTexture
    6 => InconsistentAtlasState
    _ => DegenerateScaleFactor
  }
}
