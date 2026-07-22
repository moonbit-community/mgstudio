// Copyright 2026 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_ui/src/widget/text.rs` aliases
// `TextUiReader` / `TextUiWriter` to `bevy_text`'s text access system params.

///|
pub struct TextUiReader {
  inner : @text.TextReader
}

///|
pub fn TextUiReader::new(world : @ecs.World) -> TextUiReader {
  { inner: @text.TextReader::new(world) }
}

///|
pub fn TextUiReader::get_text(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> String? {
  self.inner.get_text(root_entity, index)
}

///|
pub fn TextUiReader::get_font(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> @text.TextFont? {
  self.inner.get_font(root_entity, index)
}

///|
pub fn TextUiReader::get_color(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> @text.TextColor? {
  self.inner.get_color(root_entity, index)
}

///|
pub fn TextUiReader::get_line_height(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> @text.LineHeight? {
  self.inner.get_line_height(root_entity, index)
}

///|
pub fn TextUiReader::get(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> (
  @core.Entity,
  Int,
  String,
  @text.TextFont,
  @text.TextColor,
  @text.LineHeight,
)? {
  self.inner.get(root_entity, index)
}

///|
pub fn TextUiReader::text(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> String {
  self.inner.text(root_entity, index)
}

///|
pub fn TextUiReader::font(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> @text.TextFont {
  self.inner.font(root_entity, index)
}

///|
pub fn TextUiReader::color(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> @text.TextColor {
  self.inner.color(root_entity, index)
}

///|
pub fn TextUiReader::line_height(
  self : TextUiReader,
  root_entity : @core.Entity,
  index : Int,
) -> @text.LineHeight {
  self.inner.line_height(root_entity, index)
}

///|
pub struct TextUiWriter {
  inner : @text.TextWriter
}

///|
pub fn TextUiWriter::new(world : @ecs.World) -> TextUiWriter {
  { inner: @text.TextWriter::new(world) }
}

///|
pub fn TextUiWriter::set_text(
  self : TextUiWriter,
  root_entity : @core.Entity,
  index : Int,
  content : String,
) -> Bool {
  self.inner.set_text(root_entity, index, content)
}

///|
pub fn TextUiWriter::set_font(
  self : TextUiWriter,
  root_entity : @core.Entity,
  index : Int,
  font : @text.TextFont,
) -> Bool {
  self.inner.set_font(root_entity, index, font)
}

///|
pub fn TextUiWriter::set_color(
  self : TextUiWriter,
  root_entity : @core.Entity,
  index : Int,
  color : @text.TextColor,
) -> Bool {
  self.inner.set_color(root_entity, index, color)
}

///|
pub fn TextUiWriter::set_line_height(
  self : TextUiWriter,
  root_entity : @core.Entity,
  index : Int,
  line_height : @text.LineHeight,
) -> Bool {
  self.inner.set_line_height(root_entity, index, line_height)
}

///|
pub fn text_ui_reader(world : @ecs.World) -> TextUiReader {
  TextUiReader::new(world)
}

///|
pub fn text_ui_writer(world : @ecs.World) -> TextUiWriter {
  TextUiWriter::new(world)
}

///|
pub impl @app.SystemParam for TextUiReader with fn init_state(world) {
  @app.system_param_empty_state(world)
}

///|
pub impl @app.SystemParam for TextUiReader with fn get(_state) {
  match @app.current_world() {
    Some(world) => TextUiReader::new(world)
    None =>
      abort("TextUiReader requires an active world during system execution")
  }
}

///|
pub impl @app.SystemParam for TextUiReader with fn store(self, state) {
  @app.system_param_store_no_state(self, state)
}

///|
pub impl @app.SystemParam for TextUiWriter with fn init_state(world) {
  @app.system_param_empty_state(world)
}

///|
pub impl @app.SystemParam for TextUiWriter with fn get(_state) {
  match @app.current_world() {
    Some(world) => TextUiWriter::new(world)
    None =>
      abort("TextUiWriter requires an active world during system execution")
  }
}

///|
pub impl @app.SystemParam for TextUiWriter with fn store(self, state) {
  @app.system_param_store_no_state(self, state)
}
