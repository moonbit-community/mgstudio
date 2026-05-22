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
fn text_access_test_insert_style(
  world : @ecs.World,
  entity : @core.Entity,
  font_size : Float,
  line_height : LineHeight,
) -> Unit {
  try! world.set_by_key(
    entity,
    ecs_key_text_font,
    TextFont::from_font_size(font_size),
  )
  try! world.set_by_key(entity, ecs_key_text_color, TextColor::TextColor())
  try! world.set_by_key(entity, ecs_key_text_line_height, line_height)
}

///|
test "text writer addresses root and TextSpan children by Bevy flattened index" {
  let world = @ecs.World::new()
  let root = world.spawn_empty()
  let first = world.spawn_empty()
  let nested = world.spawn_empty()
  let second = world.spawn_empty()
  try! world.set_by_key(root, ecs_key_text, Text::new("root"))
  try! world.set_by_key(first, ecs_key_text_span, TextSpan::new("first"))
  try! world.set_by_key(nested, ecs_key_text_span, TextSpan::new("nested"))
  try! world.set_by_key(second, ecs_key_text_span, TextSpan::new("second"))
  text_access_test_insert_style(world, root, 20.0F, LineHeight::Px(20.0F))
  text_access_test_insert_style(world, first, 21.0F, LineHeight::Px(21.0F))
  text_access_test_insert_style(world, nested, 22.0F, LineHeight::Px(22.0F))
  text_access_test_insert_style(world, second, 23.0F, LineHeight::Px(23.0F))
  try! world.set_by_key(
    first,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    nested,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(first),
  )
  try! world.set_by_key(
    second,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    root,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([first, second]),
  )
  try! world.set_by_key(
    first,
    @hierarchy.ecs_key_children,
    @hierarchy.Children::new([nested]),
  )

  let reader = TextReader::new(world)
  debug_inspect(reader.text(root, 0), content="\"root\"")
  debug_inspect(reader.text(root, 1), content="\"first\"")
  debug_inspect(reader.text(root, 2), content="\"nested\"")
  debug_inspect(reader.text(root, 3), content="\"second\"")
  let nested_item = reader.get(root, 2).unwrap()
  debug_inspect(nested_item.0.id == nested.id, content="true")
  debug_inspect(nested_item.1, content="2")
  debug_inspect(nested_item.2, content="\"nested\"")
  debug_inspect(
    reader.font(root, 2).font_size.eval(@math.Vec2::zero(), 20.0F),
    content="22",
  )
  debug_inspect(reader.get_color(root, 2) is Some(_), content="true")
  debug_inspect(reader.line_height(root, 2).eval(10.0F), content="22")

  let writer = TextWriter::new(world)
  debug_inspect(writer.set_text(root, 0, "R"), content="true")
  debug_inspect(writer.set_text(root, 1, "A"), content="true")
  debug_inspect(writer.set_text(root, 2, "B"), content="true")
  debug_inspect(writer.set_text(root, 3, "C"), content="true")
  debug_inspect(writer.set_text(root, 4, "missing"), content="false")
  debug_inspect(
    writer.set_font(root, 2, TextFont::from_font_size(42.0F)),
    content="true",
  )
  debug_inspect(
    writer.set_line_height(root, 2, LineHeight::Px(7.0F)),
    content="true",
  )
  debug_inspect(writer.set_color(root, 2, TextColor::white()), content="true")
  debug_inspect(
    writer.set_font(root, 4, TextFont::from_font_size(99.0F)),
    content="false",
  )

  let updated = TextReader::new(world)
  debug_inspect(updated.text(root, 0), content="\"R\"")
  debug_inspect(updated.text(root, 1), content="\"A\"")
  debug_inspect(updated.text(root, 2), content="\"B\"")
  debug_inspect(updated.text(root, 3), content="\"C\"")
  debug_inspect(
    updated.font(root, 2).font_size.eval(@math.Vec2::zero(), 20.0F),
    content="42",
  )
  debug_inspect(updated.line_height(root, 2).eval(10.0F), content="7")
}
