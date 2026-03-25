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
fn align_items_color() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.066F, 0.349F)
}

///|
fn justify_content_color() -> @sprite.Color {
  @sprite.Color::srgb(0.102F, 0.522F, 1.0F)
}

///|
fn panel_gap() -> @ui.Val {
  @ui.Val::Px(12.0F)
}

///|
fn margin_right(value : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(
    @ui.Val::Px(0.0F),
    @ui.Val::Px(0.0F),
    value,
    @ui.Val::Px(0.0F),
  )
}

///|
fn margin_top(value : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(
    @ui.Val::Px(0.0F),
    value,
    @ui.Val::Px(0.0F),
    @ui.Val::Px(0.0F),
  )
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
fn spawn_label_chip(
  world : @ecs.World,
  parent : @core.Entity,
  label : String,
  background : @sprite.Color,
  margin : @ui.UiRect,
  font : @asset.Handle[@asset.Font],
) -> @core.Entity {
  let chip = spawn_node(
    world,
    Some(parent),
    @ui.Node::default()
    .with_margin(margin)
    .with_padding(
      @ui.UiRect::new(
        @ui.Val::Px(5.0F),
        @ui.Val::Px(1.0F),
        @ui.Val::Px(5.0F),
        @ui.Val::Px(1.0F),
      ),
    ),
    Some(@ui.BackgroundColor::new(background)),
  )
  let text = world.spawn_empty()
  try! world.set_by_key(
    text,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(chip),
  )
  try! world.set_by_key(text, @text.ecs_key_text, @text.Text::new(label))
  try! world.set_by_key(
    text,
    @text.ecs_key_text_font,
    @text.TextFont::default()
    .with_font(font)
    .with_font_size(@text.FontSize::Px(14.0F)),
  )
  try! world.set_by_key(
    text,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::black()),
  )
  chip
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.advance_sequence()
  ignore(tick)
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
    .with_align_items(@ui.AlignItems::Center)
    .with_padding(@ui.UiRect::all(panel_gap()))
    .with_row_gap(panel_gap()),
    Some(@ui.BackgroundColor::new(@sprite.Color::black())),
  )
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())

  let legend = spawn_node(
    world,
    Some(root),
    @ui.Node::default().with_flex_direction(@ui.FlexDirection::Row),
    None,
  )
  ignore(
    spawn_label_chip(
      world,
      legend,
      "AlignItems",
      align_items_color(),
      margin_right(panel_gap()),
      font,
    ),
  )
  ignore(
    spawn_label_chip(
      world,
      legend,
      "JustifyContent",
      justify_content_color(),
      @ui.UiRect::default(),
      font,
    ),
  )

  let content = spawn_node(
    world,
    Some(root),
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F))
    .with_flex_direction(@ui.FlexDirection::Column)
    .with_row_gap(panel_gap()),
    None,
  )

  let justifications : Array[@ui.JustifyContent] = [
    @ui.JustifyContent::FlexStart,
    @ui.JustifyContent::Center,
    @ui.JustifyContent::FlexEnd,
    @ui.JustifyContent::SpaceEvenly,
    @ui.JustifyContent::SpaceAround,
    @ui.JustifyContent::SpaceBetween,
  ]
  let alignments : Array[@ui.AlignItems] = [
    @ui.AlignItems::Baseline,
    @ui.AlignItems::FlexStart,
    @ui.AlignItems::Center,
    @ui.AlignItems::FlexEnd,
    @ui.AlignItems::Stretch,
  ]

  for alignment in alignments {
    let row = spawn_node(
      world,
      Some(content),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Row)
      .with_column_gap(panel_gap())
      .with_flex_grow(1.0F),
      None,
    )

    for justification in justifications {
      let cell = spawn_node(
        world,
        Some(row),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Percent(100.0F))
        .with_flex_direction(@ui.FlexDirection::Column)
        .with_align_items(alignment)
        .with_justify_content(justification)
        .with_flex_grow(1.0F),
        Some(@ui.BackgroundColor::new(@sprite.Color::srgb(0.25F, 0.25F, 0.25F))),
      )
      ignore(
        spawn_label_chip(
          world,
          cell,
          alignment.to_string(),
          align_items_color(),
          @ui.UiRect::default(),
          font,
        ),
      )
      ignore(
        spawn_label_chip(
          world,
          cell,
          justification.to_string(),
          justify_content_color(),
          margin_top(@ui.Val::Px(3.0F)),
          font,
        ),
      )
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_startup_system(setup)
  .run()
}
