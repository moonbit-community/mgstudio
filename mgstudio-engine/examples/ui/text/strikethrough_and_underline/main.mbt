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
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_row_gap(@ui.Val::Px(16.0F)),
    ),
  )

  let corner = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @text.Text::new("struck\nstruck"),
      @text.Strikethrough::default(),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(67.0F)),
      @text.TextLayout::new_with_justify(@text.Justify::Center),
      @text.TextBackgroundColor::black(),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_bottom(@ui.Val::Px(5.0F))
      .with_right(@ui.Val::Px(5.0F)),
    ),
  )
  ignore(corner)

  let group = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_align_items(@ui.AlignItems::Center)
      .with_row_gap(@ui.Val::Px(12.0F)),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(group),
        @text.Text::new("struck\nstruckstruck\nstruckstruckstruck"),
        @text.Strikethrough::default(),
        @text.StrikethroughColor::new(@sprite.Color::srgb(0.9F, 0.1F, 0.1F)),
        @text.TextBackgroundColor::new(@sprite.Color::srgb(0.2F, 0.75F, 0.35F)),
        @ui.Node::default().with_margin(@ui.UiRect::all(@ui.Val::Px(6.0F))),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(group),
        @text.Text::new("underline"),
        @text.Underline::default(),
        @ui.Node::default().with_margin(@ui.UiRect::all(@ui.Val::Px(6.0F))),
      ),
    ),
  )

  let mixed = commands.spawn(
    (
      @hierarchy.Parent::new(group),
      @text.Text::new("struck"),
      @text.Strikethrough::default(),
      @text.TextBackgroundColor::new(@sprite.Color::srgb(0.2F, 0.75F, 0.35F)),
      @ui.Node::default().with_margin(@ui.UiRect::all(@ui.Val::Px(6.0F))),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(mixed),
        @text.TextSpan::new("underline"),
        @text.Underline::default(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(mixed),
        @text.TextSpan::new(" struck"),
        @text.Strikethrough::default(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(group),
        @text.Text::new("struck struck"),
        @text.Strikethrough::default(),
        @text.TextFont::default().with_font_size(@text.FontSize::Px(67.0F)),
        @ui.Node::default().with_margin(@ui.UiRect::all(@ui.Val::Px(6.0F))),
      ),
    ),
  )

  let colorful = commands.spawn(
    (
      @hierarchy.Parent::new(group),
      @text.Text::default(),
      @ui.Node::default().with_margin(@ui.UiRect::all(@ui.Val::Px(6.0F))),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(colorful),
        @text.TextSpan::new("struck"),
        @text.Strikethrough::default(),
        @text.TextFont::default().with_font_size(@text.FontSize::Px(15.0F)),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.1F, 0.1F)),
        @text.TextBackgroundColor::black(),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(colorful),
        @text.TextSpan::new("\nunderline"),
        @text.Underline::default(),
        @text.UnderlineColor::new(@sprite.Color::srgb(1.0F, 0.9F, 0.1F)),
        @text.TextFont::default().with_font_size(@text.FontSize::Px(30.0F)),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.1F, 0.1F)),
        @text.TextBackgroundColor::new(@sprite.Color::srgb(0.2F, 0.75F, 0.35F)),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(colorful),
        @text.TextSpan::new("\nstruck"),
        @text.Strikethrough::default(),
        @text.TextFont::default().with_font_size(@text.FontSize::Px(50.0F)),
        @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.1F, 0.1F)),
        @text.TextBackgroundColor::new(@sprite.Color::srgb(0.07F, 0.1F, 0.35F)),
      ),
    ),
  )
  let combined = commands.spawn(
    (
      @hierarchy.Parent::new(colorful),
      @text.TextSpan::new("\nunderlined and struck"),
      @text.Strikethrough::default(),
      @text.Underline::default(),
      @text.StrikethroughColor::new(@sprite.Color::white()),
      @text.TextFont::default().with_font_size(@text.FontSize::Px(70.0F)),
      @text.TextColor::new(@sprite.Color::srgb(0.9F, 0.1F, 0.1F)),
      @text.TextBackgroundColor::new(@sprite.Color::srgb(0.07F, 0.1F, 0.35F)),
    ),
  )
  commands
  .entity(combined)
  .insert_component(@text.UnderlineColor::new(@sprite.Color::white()))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
