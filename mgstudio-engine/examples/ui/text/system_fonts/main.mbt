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
fn page_background() -> @color.Color {
  @color.Color::srgb(0.1F, 0.1F, 0.1F)
}

///|
fn panel_background() -> @color.Color {
  @color.Color::srgb(0.2F, 0.2F, 0.25F)
}

///|
fn label_color() -> @color.Color {
  @color.Color::srgb(0.9F, 0.9F, 0.9F)
}

///|
fn dedup_sorted_families(families : Array[String]) -> Array[String] {
  let next : Array[String] = []
  for family in families {
    next.push(family)
  }
  next.sort()
  let deduped : Array[String] = []
  for family in next {
    if deduped.is_empty() || deduped[deduped.length() - 1] != family {
      deduped.push(family)
    }
  }
  deduped
}

///|
fn root_node() -> @ui.Node {
  @ui.Node::Node()
  .with_width(Percent(100.0F))
  .with_height(Percent(100.0F))
  .with_align_items(Center)
  .with_justify_content(Center)
}

///|
fn page_node() -> @ui.Node {
  @ui.Node::Node()
  .with_width(Percent(100.0F))
  .with_height(Percent(100.0F))
  .with_align_items(Center)
  .with_justify_content(Center)
  .with_padding(@ui.UiRect::all(Px(20.0F)))
}

///|
fn list_node() -> @ui.Node {
  @ui.Node::Node()
  .with_flex_direction(Column)
  .with_row_gap(Px(6.0F))
  .with_width(Percent(100.0F))
  .with_height(Px(600.0F))
  .with_padding(@ui.UiRect::all(Px(8.0F)))
  .with_overflow(@ui.Overflow::new(Hidden, Scroll))
}

///|
fn heading_font() -> @text.TextFont {
  @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(28.0F))
}

///|
fn body_font() -> @text.TextFont {
  @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(22.0F))
}

///|
fn family_preview_font(family : String) -> @text.TextFont {
  @text.TextFont::TextFont()
  .with_family(family)
  .with_font_size(@text.FontSize::Px(22.0F))
}

///|
fn spawn_text(
  commands : @app.Commands,
  parent : @core.Entity,
  content : String,
  font : @text.TextFont,
  color : @color.Color,
  node : @ui.Node,
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      node,
      @text.Text::new(content),
      font,
      @text.TextColor::new(color),
      @text.TextLayout::new_with_no_wrap(),
    ),
  )
}

///|
fn spawn_family_row(
  commands : @app.Commands,
  parent : @core.Entity,
  family : String,
) -> Unit {
  let row = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Node::Node()
      .with_display(Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(Count(2), [Fr(1.0F)]),
      ])
      .with_width(Percent(100.0F))
      .with_padding(@ui.UiRect::all(Px(6.0F)))
      .with_column_gap(Px(50.0F)),
      @ui.BackgroundColor::new(panel_background()),
    ),
  )
  ignore(
    spawn_text(
      commands,
      row,
      family,
      family_preview_font(family),
      label_color(),
      Node(),
    ),
  )
  ignore(spawn_text(commands, row, family, body_font(), label_color(), Node()))
}

///|
fn setup(commands : @app.Commands, font_cx : @app.ResMut[@text.FontCx]) -> Unit {
  commands.spawn(
    (@camera_components2d.Camera2d::Camera2d(), @camera_camera.Camera::Camera()),
  )
  |> ignore

  let families = dedup_sorted_families(font_cx.peek().family_names())
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      root_node(),
      @ui.BackgroundColor::new(page_background()),
    ),
  )
  let page = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      page_node(),
      @ui.BackgroundColor::new(page_background()),
    ),
  )
  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(page),
      @ui.Node::Node()
      .with_width(Px(1000.0F))
      .with_height(Percent(100.0F))
      .with_flex_direction(Column)
      .with_align_items(Center)
      .with_row_gap(Px(10.0F)),
    ),
  )

  ignore(
    spawn_text(
      commands,
      panel,
      "Total available fonts: \{families.length().to_string()}",
      heading_font(),
      label_color(),
      Node(),
    ),
  )

  let list = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      list_node(),
      @ui.BackgroundColor::new(@color.Color::srgb(0.14F, 0.14F, 0.18F)),
    ),
  )
  for family in families {
    spawn_family_row(commands, list, family)
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .run()
}
