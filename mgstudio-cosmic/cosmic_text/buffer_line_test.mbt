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

test "BufferLine.set_text returns changed flag" {
  let defaults = Attrs::new()
  let attrs = AttrsList::new(defaults)
  let line0 = BufferLine::new("abc", Lf, attrs, Advanced)

  let (line1, changed1) = line0.set_text("abc", Lf, attrs)
  inspect(changed1, content="false")
  inspect(line1.text(), content="abc")

  let (line2, changed2) = line1.set_text("abcd", Lf, attrs)
  inspect(changed2, content="true")
  inspect(line2.text(), content="abcd")
}

test "BufferLine.split_off follows upstream ending/align rules" {
  let attrs = AttrsList::new(Attrs::new())
  let line0 = BufferLine::new("hello", CrLf, attrs, Advanced)
  let (left, right) = line0.split_off(2)
  inspect(left.text(), content="he")
  inspect(left.ending().as_str(), content="")
  inspect(right.text(), content="llo")
  inspect(right.ending().as_str(), content="\r\n")
}

test "BufferLine.append concatenates text and shifts spans" {
  let a0 = AttrsList::new(Attrs::new()).add_span(0, 1, Attrs::with_metadata(1))
  let b0 = AttrsList::new(Attrs::with_metadata(9)).add_span(0, 1, Attrs::with_metadata(2))
  let line0 = BufferLine::new("A", Lf, a0, Advanced)
  let line1 = BufferLine::new("B", None, b0, Advanced)
  let out = line0.append(line1)
  inspect(out.text(), content="AB")
  inspect(out.ending().as_str(), content="")
  // "B" comes from other defaults (metadata=9), and shifted span overrides at pos 1.
  inspect(out.attrs_list().get_span(1).metadata(), content="2")
}
