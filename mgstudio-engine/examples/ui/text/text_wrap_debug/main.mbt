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
fn spawn_node(
  world : @ecs.World,
  parent : @core.Entity?,
  node : @ui.Node,
  background : @ui.BackgroundColor?,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @ui.ecs_key_node, node)
  if parent is Some(parent_entity) {
    try! world.set_by_key(
      entity,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(parent_entity),
    )
  }
  if background is Some(color) {
    try! world.set_by_key(entity, @ui.ecs_key_background_color, color)
  }
  entity
}

///|
fn spawn_text_block(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  linebreak : @text.LineBreak,
  background : @color.Color,
) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_node,
    @ui.Node::Node()
    .with_width(Percent(100.0F))
    .with_margin(@ui.UiRect::new(Px(0.0F), Px(0.0F), Px(0.0F), Px(4.0F))),
  )
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new(content))
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::TextFont().with_font(font).with_font_size(12.0F),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new(Left, linebreak),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::white()),
  )
  try! world.set_by_key(
    entity,
    @ui.ecs_key_background_color,
    @ui.BackgroundColor::new(background),
  )
}

///|
fn linebreak_name(linebreak : @text.LineBreak) -> String {
  match linebreak {
    WordBoundary => "WordBoundary"
    AnyCharacter => "AnyCharacter"
    WordOrCharacter => "WordOrCharacter"
    NoWrap => "NoWrap"
  }
}

///|
fn justify_content_name(justification : @ui.JustifyContent) -> String {
  match justification {
    Center => "Center"
    FlexStart => "FlexStart"
    FlexEnd => "FlexEnd"
    SpaceAround => "SpaceAround"
    SpaceBetween => "SpaceBetween"
    SpaceEvenly => "SpaceEvenly"
    _ => "Other"
  }
}

///|
fn float_ratio(value : Int, total : Int) -> Float {
  Float::from_double(value.to_double()) / Float::from_double(total.to_double())
}

///|
fn setup(world : @ecs.World) -> Unit {
  ignore(world.increment_change_tick())
  let font = @asset.AssetServer::new().load_font("fonts/FiraSans-Bold.ttf")

  try! (world.spawn_bundle(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera(),
      @transform.Transform::identity(),
    ),
  )
  |> ignore)

  let root = spawn_node(
    world,
    None,
    @ui.Node::Node()
    .with_width(Percent(100.0F))
    .with_height(Percent(100.0F))
    .with_flex_direction(Column),
    Some(@ui.BackgroundColor::new(@color.Color::black())),
  )
  try! world.set_by_key(root, @ui.ecs_key_ui_root, UiRoot())

  let linebreaks : Array[@text.LineBreak] = [
    AnyCharacter,
    WordBoundary,
    WordOrCharacter,
    NoWrap,
  ]
  let justifications : Array[@ui.JustifyContent] = [
    Center,
    FlexStart,
    FlexEnd,
    SpaceAround,
    SpaceBetween,
    SpaceEvenly,
  ]
  let messages : Array[String] = [
    "Line 1\nLine 2", "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas auctor, nunc ac faucibus fringilla.",
    "pneumonoultramicroscopicsilicovolcanoconiosis",
  ]

  for row in 0..<linebreaks.length() {
    let linebreak = linebreaks[row]
    let row_entity = spawn_node(
      world,
      Some(root),
      @ui.Node::Node()
      .with_width(Percent(100.0F))
      .with_flex_grow(1.0F)
      .with_flex_direction(Row)
      .with_justify_content(SpaceAround)
      .with_align_items(Center)
      .with_padding(@ui.UiRect::all(Px(6.0F))),
      None,
    )

    for col in 0..<justifications.length() {
      let justification = justifications[col]
      let mix = float_ratio(col, justifications.length())
      let column_entity = spawn_node(
        world,
        Some(row_entity),
        @ui.Node::Node()
        .with_width(Percent(16.0F))
        .with_height(Percent(95.0F))
        .with_flex_direction(Column)
        .with_justify_content(justification)
        .with_overflow(@ui.Overflow::new(Clip, Visible))
        .with_padding(@ui.UiRect::all(Px(6.0F))),
        Some(
          @ui.BackgroundColor::new(
            @color.Color::srgb(0.35F, 0.25F + mix * 0.35F, 0.95F - mix * 0.45F),
          ),
        ),
      )

      spawn_text_block(
        world,
        column_entity,
        "JustifyContent::\{justify_content_name(justification)}",
        font,
        linebreak,
        @color.Color::srgb(0.55F, 0.0F, 0.0F),
      )
      spawn_text_block(
        world,
        column_entity,
        "LineBreak::\{linebreak_name(linebreak)}",
        font,
        linebreak,
        @color.Color::srgb(0.4F, 0.0F, 0.0F),
      )
      for i in 0..<messages.length() {
        spawn_text_block(
          world,
          column_entity,
          messages[i],
          font,
          linebreak,
          @color.Color::srgb(0.8F - float_ratio(i, 5) * 0.35F, 0.0F, 0.0F),
        )
      }
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_world(Startup, setup)
  .run()
}
