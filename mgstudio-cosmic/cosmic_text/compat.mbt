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
/// Compatibility layer for Bevy-style Text2d concepts.
///
/// Upstream cosmic-text uses `Wrap` + `Align`. Bevy exposes similar concepts as
/// line-break and justification; we provide a small mapping layer here.

pub(all) enum LineBreak {
  NoWrap
  AnyCharacter
  WordBoundary
}

pub(all) enum Justify {
  Left
  Right
  Center
  Justified
}

///|
pub fn line_break_to_wrap(lb : LineBreak) -> Wrap {
  match lb {
    NoWrap => Wrap::None
    AnyCharacter => Wrap::Glyph
    WordBoundary => Wrap::WordOrGlyph
  }
}

///|
pub fn justify_to_align(j : Justify) -> Align {
  match j {
    Left => Align::Left
    Right => Align::Right
    Center => Align::Center
    Justified => Align::Justified
  }
}

