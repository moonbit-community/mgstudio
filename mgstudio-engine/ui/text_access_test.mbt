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
test "ui text writer addresses root and TextSpan children by Bevy flattened index" {
  let world = @ecs.World::new()
  defer world.close()
  let root = world.spawn_empty()
  let first = world.spawn_empty()
  let nested = world.spawn_empty()
  let second = world.spawn_empty()
  try! world.set_by_key(root, @text.ecs_key_text, @text.Text::new("root"))
  try! world.set_by_key(
    first,
    @text.ecs_key_text_span,
    @text.TextSpan::new("first"),
  )
  try! world.set_by_key(
    nested,
    @text.ecs_key_text_span,
    @text.TextSpan::new("nested"),
  )
  try! world.set_by_key(
    second,
    @text.ecs_key_text_span,
    @text.TextSpan::new("second"),
  )
  for entity in [root, first, nested, second] {
    try! world.set_by_key(
      entity,
      @text.ecs_key_text_font,
      @text.TextFont::TextFont(),
    )
    try! world.set_by_key(
      entity,
      @text.ecs_key_text_color,
      @text.TextColor::TextColor(),
    )
    try! world.set_by_key(
      entity,
      @text.ecs_key_text_line_height,
      @text.LineHeight::default(),
    )
  }
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

  let reader = TextUiReader::new(world)
  debug_inspect(reader.text(root, 0), content="\"root\"")
  debug_inspect(reader.text(root, 1), content="\"first\"")
  debug_inspect(reader.text(root, 2), content="\"nested\"")
  debug_inspect(reader.text(root, 3), content="\"second\"")
  debug_inspect(reader.get(root, 2).unwrap().1, content="2")
  debug_inspect(reader.get_font(root, 2) is Some(_), content="true")

  let writer = TextUiWriter::new(world)
  debug_inspect(writer.set_text(root, 0, "R"), content="true")
  debug_inspect(writer.set_text(root, 1, "A"), content="true")
  debug_inspect(writer.set_text(root, 2, "B"), content="true")
  debug_inspect(writer.set_text(root, 3, "C"), content="true")
  debug_inspect(writer.set_text(root, 4, "missing"), content="false")
  debug_inspect(
    writer.set_line_height(root, 2, @text.LineHeight::Px(7.0F)),
    content="true",
  )

  let updated = TextUiReader::new(world)
  debug_inspect(updated.text(root, 0), content="\"R\"")
  debug_inspect(updated.text(root, 1), content="\"A\"")
  debug_inspect(updated.text(root, 2), content="\"B\"")
  debug_inspect(updated.text(root, 3), content="\"C\"")
  debug_inspect(updated.line_height(root, 2).eval(10.0F), content="7")
}
