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
// Bevy source: `bevy/crates/bevy_text/src/text_access.rs`.
// Runtime wrappers live in this file while the broader text implementation stays split across the package.

///|
pub struct TextHandle {
  id : Int
}

///|
pub fn TextHandle::new(id : Int) -> TextHandle {
  { id, }
}

///|
pub fn TextHandle::id(self : TextHandle) -> Int {
  self.id
}

///|
pub struct TextSpanHandle {
  id : Int
}

///|
pub fn TextSpanHandle::new(id : Int) -> TextSpanHandle {
  { id, }
}

///|
pub struct TextReader {
  world : @ecs.World
}

///|
pub fn TextReader::new(world : @ecs.World) -> TextReader {
  { world, }
}

///|
pub struct TextWriter {
  world : @ecs.World
}

///|
pub fn TextWriter::new(world : @ecs.World) -> TextWriter {
  { world, }
}

///|
fn text_direct_children(
  world : @ecs.World,
  entity : @core.Entity,
) -> Array[@core.Entity] {
  match (try! world.get_by_key(entity, @hierarchy.ecs_key_children)) {
    Some(children) => children.entities()
    None => []
  }
}

///|
fn text_find_access_entity_in_subtree(
  world : @ecs.World,
  entity : @core.Entity,
  target_index : Int,
  current_index : Ref[Int],
  depth : Int,
) -> (@core.Entity, Int)? {
  for child in text_direct_children(world, entity) {
    if (try! world.contains_by_key(child, ecs_key_text_span)) {
      current_index.val = current_index.val + 1
      if current_index.val == target_index {
        return Some((child, depth))
      }
      match
        text_find_access_entity_in_subtree(
          world,
          child,
          target_index,
          current_index,
          depth + 1,
        ) {
        Some(found) => return Some(found)
        None => ()
      }
    }
  }
  None
}

///|
fn text_access_entity(
  world : @ecs.World,
  root_entity : @core.Entity,
  index : Int,
) -> (@core.Entity, Int)? {
  if index == 0 {
    if (try! world.contains_by_key(root_entity, ecs_key_text)) {
      return Some((root_entity, 0))
    }
    return None
  }
  if index < 0 {
    return None
  }
  text_find_access_entity_in_subtree(world, root_entity, index, Ref(0), 1)
}

///|
pub fn TextReader::get_text(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> String? {
  if index == 0 {
    return match (try! self.world.get_by_key(root_entity, ecs_key_text)) {
      Some(text) => Some(text.content)
      None => None
    }
  }
  match text_access_entity(self.world, root_entity, index) {
    Some((span_entity, _)) =>
      match (try! self.world.get_by_key(span_entity, ecs_key_text_span)) {
        Some(span) => Some(span.content)
        None => None
      }
    None => None
  }
}

///|
pub fn TextReader::get_font(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> TextFont? {
  match text_access_entity(self.world, root_entity, index) {
    Some((entity, _)) =>
      match (try! self.world.get_by_key(entity, ecs_key_text_font)) {
        Some(font) => Some(font)
        None => None
      }
    None => None
  }
}

///|
pub fn TextReader::get_color(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> TextColor? {
  match text_access_entity(self.world, root_entity, index) {
    Some((entity, _)) =>
      match (try! self.world.get_by_key(entity, ecs_key_text_color)) {
        Some(color) => Some(color)
        None => None
      }
    None => None
  }
}

///|
pub fn TextReader::get_line_height(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> LineHeight? {
  match text_access_entity(self.world, root_entity, index) {
    Some((entity, _)) =>
      match (try! self.world.get_by_key(entity, ecs_key_text_line_height)) {
        Some(line_height) => Some(line_height)
        None => None
      }
    None => None
  }
}

///|
pub fn TextReader::get(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> (@core.Entity, Int, String, TextFont, TextColor, LineHeight)? {
  guard text_access_entity(self.world, root_entity, index)
    is Some((entity, depth)) else {
    return None
  }
  let content = if index == 0 {
    match (try! self.world.get_by_key(entity, ecs_key_text)) {
      Some(text) => text.content
      None => return None
    }
  } else {
    match (try! self.world.get_by_key(entity, ecs_key_text_span)) {
      Some(span) => span.content
      None => return None
    }
  }
  guard (try! self.world.get_by_key(entity, ecs_key_text_font)) is Some(font) else {
    return None
  }
  guard (try! self.world.get_by_key(entity, ecs_key_text_color)) is Some(color) else {
    return None
  }
  guard (try! self.world.get_by_key(entity, ecs_key_text_line_height))
    is Some(line_height) else {
    return None
  }
  Some((entity, depth, content, font, color, line_height))
}

///|
pub fn TextReader::text(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> String {
  match self.get_text(root_entity, index) {
    Some(content) => content
    None => abort("TextReader::text: missing text span")
  }
}

///|
pub fn TextReader::font(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> TextFont {
  match self.get_font(root_entity, index) {
    Some(font) => font
    None => abort("TextReader::font: missing text span")
  }
}

///|
pub fn TextReader::color(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> TextColor {
  match self.get_color(root_entity, index) {
    Some(color) => color
    None => abort("TextReader::color: missing text span")
  }
}

///|
pub fn TextReader::line_height(
  self : TextReader,
  root_entity : @core.Entity,
  index : Int,
) -> LineHeight {
  match self.get_line_height(root_entity, index) {
    Some(line_height) => line_height
    None => abort("TextReader::line_height: missing text span")
  }
}

///|
pub fn TextWriter::set_text(
  self : TextWriter,
  root_entity : @core.Entity,
  index : Int,
  content : String,
) -> Bool {
  if index == 0 {
    return match (try! self.world.get_by_key(root_entity, ecs_key_text)) {
      Some(text) => {
        text.content = content
        ignore(try! self.world.replace(root_entity, ecs_key_text, text))
        true
      }
      None => false
    }
  }
  match text_access_entity(self.world, root_entity, index) {
    Some((span_entity, _)) =>
      match (try! self.world.get_by_key(span_entity, ecs_key_text_span)) {
        Some(span) => {
          span.content = content
          ignore(try! self.world.replace(span_entity, ecs_key_text_span, span))
          true
        }
        None => false
      }
    None => false
  }
}

///|
pub fn TextWriter::set_font(
  self : TextWriter,
  root_entity : @core.Entity,
  index : Int,
  font : TextFont,
) -> Bool {
  match text_access_entity(self.world, root_entity, index) {
    Some((entity, _)) =>
      if (try! self.world.contains_by_key(entity, ecs_key_text_font)) {
        ignore(try! self.world.replace(entity, ecs_key_text_font, font))
        true
      } else {
        false
      }
    None => false
  }
}

///|
pub fn TextWriter::set_color(
  self : TextWriter,
  root_entity : @core.Entity,
  index : Int,
  color : TextColor,
) -> Bool {
  match text_access_entity(self.world, root_entity, index) {
    Some((entity, _)) =>
      if (try! self.world.contains_by_key(entity, ecs_key_text_color)) {
        ignore(try! self.world.replace(entity, ecs_key_text_color, color))
        true
      } else {
        false
      }
    None => false
  }
}

///|
pub fn TextWriter::set_line_height(
  self : TextWriter,
  root_entity : @core.Entity,
  index : Int,
  line_height : LineHeight,
) -> Bool {
  match text_access_entity(self.world, root_entity, index) {
    Some((entity, _)) =>
      if (try! self.world.contains_by_key(entity, ecs_key_text_line_height)) {
        ignore(
          try! self.world.replace(entity, ecs_key_text_line_height, line_height),
        )
        true
      } else {
        false
      }
    None => false
  }
}

///|
pub fn text_reader(world : @ecs.World) -> TextReader {
  TextReader::new(world)
}

///|
pub fn text_writer(world : @ecs.World) -> TextWriter {
  TextWriter::new(world)
}

///|
pub fn text_content(handle : TextHandle) -> String? {
  text_get_content(handle)
}

///|
pub fn text_layout_size(handle : TextHandle) -> @math.Vec2? {
  text_get_layout_size(handle)
}

///|
pub fn text_visual_bounds(handle : TextHandle) -> @math.Rect? {
  text_get_visual_bounds(handle)
}
