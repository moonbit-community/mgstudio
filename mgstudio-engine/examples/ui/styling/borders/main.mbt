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
fn border_cases() -> Array[(String, @ui.UiRect)] {
  [
    ("None", @ui.UiRect::default()),
    ("All", @ui.UiRect::all(@ui.Val::Px(10.0F))),
    (
      "Left",
      @ui.UiRect::new(
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    (
      "Right",
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    (
      "Top",
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    (
      "Bottom",
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
      ),
    ),
    (
      "Horizontal",
      @ui.UiRect::new(
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    (
      "Vertical",
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
      ),
    ),
    (
      "Top Left",
      @ui.UiRect::new(
        @ui.Val::Px(20.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    (
      "Bottom Left",
      @ui.UiRect::new(
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(20.0F),
      ),
    ),
    (
      "Top Right",
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(20.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    (
      "Bottom Right",
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(10.0F),
      ),
    ),
    (
      "Top Bottom Right",
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(20.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(10.0F),
      ),
    ),
    (
      "Top Bottom Left",
      @ui.UiRect::new(
        @ui.Val::Px(10.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
      ),
    ),
    (
      "Top Left Right",
      @ui.UiRect::new(
        @ui.Val::Px(20.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    (
      "Bottom Left Right",
      @ui.UiRect::new(
        @ui.Val::Px(10.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(10.0F),
        @ui.Val::Px(20.0F),
      ),
    ),
  ]
}

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
fn spawn_text(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(entity, @text.ecs_key_text, @text.Text::new(content))
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(font_size),
  )
  try! world.set_by_key(
    entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::srgb(0.95F, 0.95F, 0.95F)),
  )
  entity
}

///|
fn spawn_label(
  world : @ecs.World,
  parent : @core.Entity,
  label : String,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let label_container = spawn_node(
    world,
    Some(parent),
    @ui.Node::default().with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(8.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
      ),
    ),
    None,
  )
  ignore(spawn_text(world, label_container, label, font, 9.0F))
}

///|
fn spawn_border_example(
  world : @ecs.World,
  parent : @core.Entity,
  label : String,
  border : @ui.UiRect,
  font : @asset.Handle[@asset.Font],
  rounded? : Bool = false,
) -> Unit {
  let cell = spawn_node(
    world,
    Some(parent),
    @ui.Node::default()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_align_items(@ui.AlignItems::Center)
    .with_margin(@ui.UiRect::all(@ui.Val::Px(6.0F))),
    None,
  )
  let box_node = @ui.Node::default()
    .with_width(@ui.Val::Px(56.0F))
    .with_height(@ui.Val::Px(56.0F))
    .with_border(border)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F)))
    .with_align_items(@ui.AlignItems::Center)
    .with_justify_content(@ui.JustifyContent::Center)
  let border_box = spawn_node(
    world,
    Some(cell),
    box_node,
    Some(@ui.BackgroundColor::new(@sprite.Color::srgb(0.45F, 0.05F, 0.18F))),
  )
  try! world.set_by_key(
    border_box,
    @ui.ecs_key_border_color,
    @ui.BorderColor::new(@sprite.Color::srgb(0.0F, 0.7F, 1.0F)),
  )
  try! world.set_by_key(
    border_box,
    @ui.ecs_key_outline,
    @ui.Outline::new(
      @ui.Val::Px(4.0F),
      @ui.Val::Px(6.0F),
      @sprite.Color::white(),
    ),
  )
  if rounded {
    try! world.set_by_key(
      border_box,
      @ui.ecs_key_border_radius,
      @ui.BorderRadius::all(@ui.Val::Px(22.0F)),
    )
  }
  ignore(
    spawn_node(
      world,
      Some(border_box),
      @ui.Node::default()
      .with_width(@ui.Val::Px(12.0F))
      .with_height(@ui.Val::Px(12.0F)),
      Some(@ui.BackgroundColor::new(@sprite.Color::srgb(1.0F, 0.92F, 0.0F))),
    ),
  )
  spawn_label(world, cell, label, font)
}

///|
fn spawn_section(
  world : @ecs.World,
  parent : @core.Entity,
  title : String,
  font : @asset.Handle[@asset.Font],
  rounded : Bool,
) -> Unit {
  let section = spawn_node(
    world,
    Some(parent),
    @ui.Node::default()
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_row_gap(@ui.Val::Px(12.0F)),
    None,
  )
  ignore(spawn_text(world, section, title, font, 22.0F))
  let samples = spawn_node(
    world,
    Some(section),
    @ui.Node::{
      ..@ui.Node::default()
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_padding(@ui.UiRect::all(@ui.Val::Px(12.0F))),
      flex_wrap: @ui.FlexWrap::Wrap,
    },
    Some(@ui.BackgroundColor::new(@sprite.Color::srgb(0.16F, 0.16F, 0.16F))),
  )
  for entry in border_cases() {
    spawn_border_example(world, samples, entry.0, entry.1, font, rounded~)
  }
}

///|
fn setup(world : @ecs.World) -> Unit {
  ignore(world.advance_sequence())
  let font = @asset.AssetServer::new().load_font("fonts/FiraSans-Bold.ttf")

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = spawn_node(
    world,
    None,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_padding(@ui.UiRect::all(@ui.Val::Px(20.0F)))
    .with_row_gap(@ui.Val::Px(24.0F)),
    Some(@ui.BackgroundColor::new(@sprite.Color::srgb(0.08F, 0.08F, 0.08F))),
  )
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())

  spawn_section(world, root, "Borders", font, false)
  spawn_section(world, root, "Borders Rounded", font, true)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
