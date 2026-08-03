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
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  commands.spawn(
    (@camera_components2d.Camera2d::Camera2d(), @camera_camera.Camera::Camera()),
  )
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(Percent(100.0F))
      .with_height(Percent(100.0F))
      .with_flex_direction(Column)
      .with_justify_content(Center)
      .with_align_items(Center)
      .with_row_gap(Px(16.0F)),
    ),
  )

  let corner = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @text.Text::new("struck\nstruck"),
      @text.Strikethrough::Strikethrough(),
      @text.TextFont::TextFont()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(67.0F)),
      @text.TextLayout::new_with_justify(Center),
      @text.TextBackgroundColor::black(),
      @ui.Node::Node()
      .with_position_type(Absolute)
      .with_bottom(Px(5.0F))
      .with_right(Px(5.0F)),
    ),
  )
  ignore(corner)

  let group = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::Node()
      .with_flex_direction(Column)
      .with_align_items(Center)
      .with_row_gap(Px(12.0F)),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(group),
        @text.Text::new("struck\nstruckstruck\nstruckstruckstruck"),
        @text.Strikethrough::Strikethrough(),
        @text.StrikethroughColor::new(@palettes.basic_red()),
        @text.TextBackgroundColor::new(@palettes.basic_green()),
        @ui.Node::Node().with_margin(@ui.UiRect::all(Px(6.0F))),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(group),
        @text.Text::new("underline"),
        @text.Underline::Underline(),
        @ui.Node::Node().with_margin(@ui.UiRect::all(Px(6.0F))),
      ),
    ),
  )

  let mixed = commands.spawn(
    (
      @hierarchy.Parent::new(group),
      @text.Text::new("struck"),
      @text.Strikethrough::Strikethrough(),
      @text.TextBackgroundColor::new(@palettes.basic_green()),
      @ui.Node::Node().with_margin(@ui.UiRect::all(Px(6.0F))),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(mixed),
        @text.TextSpan::new("underline"),
        @text.Underline::Underline(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(mixed),
        @text.TextSpan::new(" struck"),
        @text.Strikethrough::Strikethrough(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(group),
        @text.Text::new("struck struck"),
        @text.Strikethrough::Strikethrough(),
        @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(67.0F)),
        @ui.Node::Node().with_margin(@ui.UiRect::all(Px(6.0F))),
      ),
    ),
  )

  let colorful = commands.spawn(
    (
      @hierarchy.Parent::new(group),
      @text.Text::Text(),
      @ui.Node::Node().with_margin(@ui.UiRect::all(Px(6.0F))),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(colorful),
        @text.TextSpan::new("struck"),
        @text.Strikethrough::Strikethrough(),
        @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(15.0F)),
        @text.TextColor::new(@palettes.basic_red()),
        @text.TextBackgroundColor::black(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(colorful),
        @text.TextSpan::new("\nunderline"),
        @text.Underline::Underline(),
        @text.UnderlineColor::new(@palettes.basic_yellow()),
        @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(30.0F)),
        @text.TextColor::new(@palettes.basic_red()),
        @text.TextBackgroundColor::new(@palettes.basic_green()),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(colorful),
        @text.TextSpan::new("\nstruck"),
        @text.Strikethrough::Strikethrough(),
        @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(50.0F)),
        @text.TextColor::new(@palettes.basic_red()),
        @text.TextBackgroundColor::new(@palettes.basic_navy()),
      ),
    ),
  )
  let combined = commands.spawn(
    (
      @hierarchy.Parent::new(colorful),
      @text.TextSpan::new("\nunderlined and struck"),
      @text.Strikethrough::Strikethrough(),
      @text.Underline::Underline(),
      @text.StrikethroughColor::new(@color.Color::white()),
      @text.TextFont::TextFont().with_font_size(@text.FontSize::Px(70.0F)),
      @text.TextColor::new(@palettes.basic_red()),
      @text.TextBackgroundColor::new(@palettes.basic_navy()),
    ),
  )
  commands
  .entity(combined)
  .insert_component(@text.UnderlineColor::new(@color.Color::white()))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .run()
}
