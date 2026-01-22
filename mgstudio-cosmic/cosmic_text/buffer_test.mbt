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

test "Buffer.set_text splits lines using LineIter endings" {
  let buf0 = Buffer::new(Metrics::new(12.0F, 14.0F))
  let attrs = AttrsList::new(Attrs::new())
  let buf1 = buf0.set_text("A\nB\r\nC", attrs, Advanced)
  let lines = buf1.lines()
  inspect(lines.length(), content="3")
  inspect(lines[0].text(), content="A")
  inspect(lines[0].ending().as_str(), content="\n")
  inspect(lines[1].text(), content="B")
  inspect(lines[1].ending().as_str(), content="\r\n")
  inspect(lines[2].text(), content="C")
  inspect(lines[2].ending().as_str(), content="")
}

test "Buffer.set_size marks redraw on change" {
  let buf0 = Buffer::new(Metrics::new(12.0F, 14.0F))
  let buf1 = buf0.set_size(Some(100.0F), None)
  inspect(buf1.redraw(), content="true")
}

test "Buffer defaults align with upstream new_empty" {
  let buf0 = Buffer::new_empty(Metrics::new(12.0F, 14.0F))
  inspect(buf0.redraw(), content="false")
  inspect(match buf0.wrap() { WordOrGlyph => true; _ => false }, content="true")
  inspect(buf0.tab_width, content="8")
  inspect(match buf0.hinting() { Disabled => true; _ => false }, content="true")
  inspect(buf0.scroll().line, content="0")
}

test "Buffer setters mark redraw when value changes" {
  let buf0 = Buffer::new_empty(Metrics::new(12.0F, 14.0F))
  let buf1 = buf0.set_wrap(Wrap::Glyph)
  inspect(buf1.redraw(), content="true")
  let buf2 = buf1.set_tab_width(2)
  inspect(buf2.redraw(), content="true")
  let buf3 = buf2.set_hinting(Hinting::Enabled)
  inspect(buf3.redraw(), content="true")
  let buf4 = buf3.set_monospace_width(Some(8.0F))
  inspect(buf4.redraw(), content="true")
  let buf5 = buf4.set_metrics(Metrics::new(13.0F, 15.0F))
  inspect(buf5.redraw(), content="true")
}
