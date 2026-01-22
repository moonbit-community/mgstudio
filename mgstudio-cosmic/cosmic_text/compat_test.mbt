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

test "LineBreak/Justify mapping" {
  inspect(match line_break_to_wrap(LineBreak::NoWrap) { None => true; _ => false }, content="true")
  inspect(match line_break_to_wrap(LineBreak::AnyCharacter) { Glyph => true; _ => false }, content="true")
  inspect(match line_break_to_wrap(LineBreak::WordBoundary) { WordOrGlyph => true; _ => false }, content="true")

  inspect(match justify_to_align(Justify::Left) { Left => true; _ => false }, content="true")
  inspect(match justify_to_align(Justify::Right) { Right => true; _ => false }, content="true")
  inspect(match justify_to_align(Justify::Center) { Center => true; _ => false }, content="true")
  inspect(match justify_to_align(Justify::Justified) { Justified => true; _ => false }, content="true")
}

test "apply_align centers lines" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("hi", Lf, attrs, Advanced)
  let (line1, _) = line0.set_align(Some(Align::Center))
  let line2 = line1.layout(10.0F, Some(40.0F), Wrap::None, None, 4, Hinting::Disabled)
  if line2.layout_opt() is Some(layout) {
    // "hi" => w = 20, center in 40 => x offset 10
    inspect(layout[0].glyphs[0].x, content="10")
  } else {
    fail("expected Some(layout)")
  }
}

test "apply_align justifies spaces (MVP)" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("a a", Lf, attrs, Advanced)
  let (line1, _) = line0.set_align(Some(Align::Justified))
  let line2 = line1.layout(10.0F, Some(50.0F), Wrap::None, None, 4, Hinting::Disabled)
  if line2.layout_opt() is Some(layout) {
    inspect(layout[0].w, content="50")
    // space is glyph[1], gets widened by extra 20
    inspect(layout[0].glyphs[1].w, content="30")
    // last glyph shifts right by extra 20: x=40
    inspect(layout[0].glyphs[2].x, content="40")
  } else {
    fail("expected Some(layout)")
  }
}
