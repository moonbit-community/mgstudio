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
const FONT_SIZE : Float = 20.0F

///|
fn title_font(asset_server : @asset.AssetServer) -> @text.TextFont {
  @text.TextFont::from_font_size(FONT_SIZE).with_font(
    asset_server.load_font("fonts/FiraSans-Bold.ttf"),
  )
}

///|
fn body_font(asset_server : @asset.AssetServer) -> @text.TextFont {
  @text.TextFont::from_font_size(16.0F).with_font(
    asset_server.load_font("fonts/FiraMono-Medium.ttf"),
  )
}

///|
fn text_color() -> @text.TextColor {
  @text.TextColor::new(@sprite.Color::srgb(0.92F, 0.92F, 0.92F))
}

///|
fn spawn_text(
  commands : @app.Commands,
  parent : @core.Entity,
  content : String,
  font : @text.TextFont,
  node : @ui.Node,
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      node,
      @text.Text::new(content),
      font,
      text_color(),
    ),
  )
}

///|
fn panel_node(width : Float, height : Float) -> @ui.Node {
  @ui.Node::default()
  .with_width(@ui.Val::Px(width))
  .with_height(@ui.Val::Px(height))
  .with_margin(@ui.UiRect::all(@ui.Val::Px(8.0F)))
  .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F)))
  .with_flex_direction(@ui.FlexDirection::Column)
}

///|
fn scroll_container(
  width : Float,
  height : Float,
  overflow : @ui.Overflow,
) -> @ui.Node {
  @ui.Node::default()
  .with_width(@ui.Val::Px(width))
  .with_height(@ui.Val::Px(height))
  .with_padding(@ui.UiRect::all(@ui.Val::Px(6.0F)))
  .with_overflow(overflow)
}

///|
fn row_item_node(width : Float) -> @ui.Node {
  @ui.Node::{
    ..@ui.Node::default(),
    width: @ui.Val::Px(width),
    min_height: @ui.Val::Px(56.0F),
    margin: @ui.UiRect::new(
      @ui.Val::Px(0.0F),
      @ui.Val::Px(8.0F),
      @ui.Val::Px(0.0F),
      @ui.Val::Px(0.0F),
    ),
    padding: @ui.UiRect::all(@ui.Val::Px(10.0F)),
  }
}

///|
fn column_item_node() -> @ui.Node {
  @ui.Node::{ ..@ui.Node::default(), min_height: @ui.Val::Px(30.0F) }
}

///|
fn spawn_vertical_panel(
  commands : @app.Commands,
  parent : @core.Entity,
  asset_server : @asset.AssetServer,
) -> Unit {
  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      panel_node(280.0F, 360.0F),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.14F, 0.16F, 0.20F)),
    ),
  )
  let title = "Vertical scroll"
  let hint = "Use MouseWheel while hovering this list."
  spawn_text(
    commands,
    panel,
    title,
    title_font(asset_server),
    @ui.Node::default(),
  )
  |> ignore
  spawn_text(
    commands,
    panel,
    hint,
    body_font(asset_server),
    @ui.Node::default().with_margin(
      @ui.UiRect::new(
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(0.0F),
        @ui.Val::Px(8.0F),
      ),
    ),
  )
  |> ignore
  let list = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      scroll_container(
        248.0F,
        280.0F,
        @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Scroll),
      ).with_flex_direction(@ui.FlexDirection::Column),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.08F, 0.09F, 0.11F)),
    ),
  )
  for i in 0..<28 {
    spawn_text(
      commands,
      list,
      "Item \{i.to_string()}",
      body_font(asset_server),
      column_item_node(),
    )
    |> ignore
  }
}

///|
fn spawn_horizontal_panel(
  commands : @app.Commands,
  parent : @core.Entity,
  asset_server : @asset.AssetServer,
) -> Unit {
  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      panel_node(520.0F, 200.0F),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.18F, 0.16F, 0.12F)),
    ),
  )
  spawn_text(
    commands,
    panel,
    "Horizontal scroll",
    title_font(asset_server),
    @ui.Node::default(),
  )
  |> ignore
  let list = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      scroll_container(
        488.0F,
        112.0F,
        @ui.Overflow::new(@ui.OverflowAxis::Scroll, @ui.OverflowAxis::Hidden),
      ).with_flex_direction(@ui.FlexDirection::Row),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.10F, 0.08F, 0.06F)),
    ),
  )
  for i in 0..<12 {
    let item = commands.spawn(
      (
        @hierarchy.Parent::new(list),
        row_item_node(180.0F),
        @ui.BackgroundColor::new(
          @sprite.Color::hsl(Float::from_int(i) * 23.0F, 0.65F, 0.52F),
        ),
      ),
    )
    spawn_text(
      commands,
      item,
      "Card \{i.to_string()}",
      body_font(asset_server),
      @ui.Node::default(),
    )
    |> ignore
  }
}

///|
fn spawn_bidirectional_panel(
  commands : @app.Commands,
  parent : @core.Entity,
  asset_server : @asset.AssetServer,
) -> Unit {
  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      panel_node(520.0F, 360.0F),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.12F, 0.17F, 0.14F)),
    ),
  )
  spawn_text(
    commands,
    panel,
    "Bidirectional scroll",
    title_font(asset_server),
    @ui.Node::default(),
  )
  |> ignore
  let grid = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      scroll_container(
        488.0F,
        280.0F,
        @ui.Overflow::new(@ui.OverflowAxis::Scroll, @ui.OverflowAxis::Scroll),
      )
      .with_display(@ui.Display::Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(10), [
          @ui.GridTrack::Px(120.0F),
        ]),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(8), [
          @ui.GridTrack::Px(72.0F),
        ]),
      ]),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.06F, 0.10F, 0.08F)),
    ),
  )
  for y in 0..<8 {
    for x in 0..<10 {
      let cell = commands.spawn(
        (
          @hierarchy.Parent::new(grid),
          @ui.Node::{
            ..@ui.Node::default(),
            grid_column: @ui.GridPlacement::start(x + 1),
            grid_row: @ui.GridPlacement::start(y + 1),
            padding: @ui.UiRect::all(@ui.Val::Px(8.0F)),
          },
          @ui.BackgroundColor::new(
            @sprite.Color::hsl(Float::from_int(x * 20 + y * 12), 0.55F, 0.45F),
          ),
        ),
      )
      spawn_text(
        commands,
        cell,
        "Cell \{x.to_string()},\{y.to_string()}",
        body_font(asset_server),
        @ui.Node::default(),
      )
      |> ignore
    }
  }
}

///|
fn spawn_nested_panel(
  commands : @app.Commands,
  parent : @core.Entity,
  asset_server : @asset.AssetServer,
) -> Unit {
  let panel = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      panel_node(280.0F, 360.0F),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.16F, 0.13F, 0.18F)),
    ),
  )
  spawn_text(
    commands,
    panel,
    "Nested scroll",
    title_font(asset_server),
    @ui.Node::default(),
  )
  |> ignore
  let outer = commands.spawn(
    (
      @hierarchy.Parent::new(panel),
      scroll_container(
        248.0F,
        280.0F,
        @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Scroll),
      ).with_flex_direction(@ui.FlexDirection::Column),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.09F, 0.07F, 0.10F)),
    ),
  )
  for i in 0..<10 {
    spawn_text(
      commands,
      outer,
      "Outer row \{i.to_string()}",
      body_font(asset_server),
      @ui.Node::{
        ..@ui.Node::default(),
        min_height: @ui.Val::Px(28.0F),
        margin: @ui.UiRect::new(
          @ui.Val::Px(0.0F),
          @ui.Val::Px(0.0F),
          @ui.Val::Px(0.0F),
          @ui.Val::Px(6.0F),
        ),
      },
    )
    |> ignore
  }
  let inner = commands.spawn(
    (
      @hierarchy.Parent::new(outer),
      scroll_container(
        220.0F,
        120.0F,
        @ui.Overflow::new(@ui.OverflowAxis::Hidden, @ui.OverflowAxis::Scroll),
      )
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_margin(
        @ui.UiRect::new(
          @ui.Val::Px(0.0F),
          @ui.Val::Px(0.0F),
          @ui.Val::Px(10.0F),
          @ui.Val::Px(10.0F),
        ),
      ),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.13F, 0.11F, 0.16F)),
    ),
  )
  for i in 0..<18 {
    spawn_text(
      commands,
      inner,
      "Inner row \{i.to_string()}",
      body_font(asset_server),
      column_item_node(),
    )
    |> ignore
  }
  for i in 10..<20 {
    spawn_text(
      commands,
      outer,
      "Outer row \{i.to_string()}",
      body_font(asset_server),
      @ui.Node::{
        ..@ui.Node::default(),
        min_height: @ui.Val::Px(28.0F),
        margin: @ui.UiRect::new(
          @ui.Val::Px(0.0F),
          @ui.Val::Px(0.0F),
          @ui.Val::Px(0.0F),
          @ui.Val::Px(6.0F),
        ),
      },
    )
    |> ignore
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(16.0F)))
      .with_display(@ui.Display::Grid)
      .with_grid_template_columns([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(2), [
          @ui.GridTrack::Fr(1.0F),
        ]),
      ])
      .with_grid_template_rows([
        @ui.RepeatedGridTrack::new(@ui.GridTrackRepetition::Count(2), [
          @ui.GridTrack::Auto,
        ]),
      ]),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.05F, 0.05F, 0.06F)),
    ),
  )

  spawn_vertical_panel(commands, root, asset_server.get())
  spawn_horizontal_panel(commands, root, asset_server.get())
  spawn_bidirectional_panel(commands, root, asset_server.get())
  spawn_nested_panel(commands, root, asset_server.get())
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
