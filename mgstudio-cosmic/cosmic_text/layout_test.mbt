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

test "layout_ascii: Wrap::Word splits on spaces" {
  let text = "hello world"
  let lines = layout_ascii(text, 10.0F, Some(60.0F), Wrap::Word)
  inspect(lines.length(), content="2")
  inspect(lines[0].start, content="0")
  inspect(lines[0].end, content="5")
  inspect(lines[0].w, content="50")
  inspect(lines[1].start, content="6")
  inspect(lines[1].end, content="11")
  inspect(lines[1].w, content="50")
}

test "layout_ascii: Wrap::WordOrGlyph falls back for long words" {
  let text = "abcdefghij" // 10 glyphs
  let lines = layout_ascii(text, 10.0F, Some(30.0F), Wrap::WordOrGlyph)
  inspect(lines.length(), content="4")
  inspect(lines[0].start, content="0")
  inspect(lines[0].end, content="3")
  inspect(lines[1].start, content="3")
  inspect(lines[1].end, content="6")
  inspect(lines[2].start, content="6")
  inspect(lines[2].end, content="9")
  inspect(lines[3].start, content="9")
  inspect(lines[3].end, content="10")
}
