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
fn align_items_color() -> @color.Color {
  @color.Color::srgb(1.0F, 0.066F, 0.349F)
}

///|
fn justify_content_color() -> @color.Color {
  @color.Color::srgb(0.102F, 0.522F, 1.0F)
}

///|
fn panel_gap() -> @ui.Val {
  Px(12.0F)
}

///|
fn margin_right(value : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(Px(0.0F), Px(0.0F), value, Px(0.0F))
}

///|
fn margin_top(value : @ui.Val) -> @ui.UiRect {
  @ui.UiRect::new(Px(0.0F), value, Px(0.0F), Px(0.0F))
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
  background : @color.Color,
  margin : @ui.UiRect,
  font : @asset.Handle[@asset.Font],
) -> @core.Entity {
  let chip = spawn_node(
    world,
    Some(parent),
    @ui.Node::Node()
    .with_margin(margin)
    .with_padding(@ui.UiRect::new(Px(5.0F), Px(1.0F), Px(5.0F), Px(1.0F))),
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
    @text.TextFont::TextFont()
    .with_font(font)
    .with_font_size(@text.FontSize::Px(14.0F)),
  )
  try! world.set_by_key(
    text,
    @text.ecs_key_text_color,
    @text.TextColor::new(@color.Color::black()),
  )
  chip
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.increment_change_tick()
  ignore(tick)
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
    .with_flex_direction(Column)
    .with_align_items(Center)
    .with_padding(@ui.UiRect::all(panel_gap()))
    .with_row_gap(panel_gap()),
    Some(@ui.BackgroundColor::new(@color.Color::black())),
  )
  try! world.set_by_key(root, @ui.ecs_key_ui_root, UiRoot())

  let legend = spawn_node(
    world,
    Some(root),
    @ui.Node::Node().with_flex_direction(Row),
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
      UiRect(),
      font,
    ),
  )

  let content = spawn_node(
    world,
    Some(root),
    @ui.Node::Node()
    .with_width(Percent(100.0F))
    .with_height(Percent(100.0F))
    .with_flex_direction(Column)
    .with_row_gap(panel_gap()),
    None,
  )

  let justifications : Array[@ui.JustifyContent] = [
    FlexStart,
    Center,
    FlexEnd,
    SpaceEvenly,
    SpaceAround,
    SpaceBetween,
  ]
  let alignments : Array[@ui.AlignItems] = [
    Baseline,
    FlexStart,
    Center,
    FlexEnd,
    Stretch,
  ]

  for alignment in alignments {
    let row = spawn_node(
      world,
      Some(content),
      @ui.Node::Node()
      .with_width(Percent(100.0F))
      .with_flex_direction(Row)
      .with_column_gap(panel_gap())
      .with_flex_grow(1.0F),
      None,
    )

    for justification in justifications {
      let cell = spawn_node(
        world,
        Some(row),
        @ui.Node::Node()
        .with_width(Percent(100.0F))
        .with_height(Percent(100.0F))
        .with_flex_direction(Column)
        .with_align_items(alignment)
        .with_justify_content(justification)
        .with_flex_grow(1.0F),
        Some(@ui.BackgroundColor::new(@color.Color::srgb(0.25F, 0.25F, 0.25F))),
      )
      ignore(
        spawn_label_chip(
          world,
          cell,
          Repr(alignment).to_string(),
          align_items_color(),
          UiRect(),
          font,
        ),
      )
      ignore(
        spawn_label_chip(
          world,
          cell,
          Repr(justification).to_string(),
          justify_content_color(),
          margin_top(Px(3.0F)),
          font,
        ),
      )
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_startup_system(setup)
  .run()
}
