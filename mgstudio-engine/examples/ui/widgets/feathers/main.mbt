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
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore

  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_flex_direction(@ui.FlexDirection::Column)
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_row_gap(@ui.Val::Px(8.0F)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.11F, 0.12F, 0.15F)),
    ),
  )

  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @text.Text::new("Feathers plugins loaded"),
      @text.TextFont::default().with_font(font).with_font_size(28.0F),
      @text.TextColor::new(@sprite.Color::srgb(0.86F, 0.92F, 1.0F)),
    ),
  )
  |> ignore

  for label in ["Primary", "Secondary", "Disabled"] {
    let button = commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Button::default(),
        @ui.Node::default()
        .with_width(@ui.Val::Px(220.0F))
        .with_height(@ui.Val::Px(46.0F))
        .with_border(@ui.UiRect::all(@ui.Val::Px(2.0F)))
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::Center),
        @ui.BorderColor::new(@sprite.Color::srgb(0.58F, 0.62F, 0.72F)),
        @ui.BackgroundColor::new(@sprite.Color::srgb(0.2F, 0.22F, 0.28F)),
      ),
    )
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new(label),
        @text.TextFont::default().with_font(font).with_font_size(18.0F),
        @text.TextColor::new(@sprite.Color::white()),
      ),
    )
    |> ignore
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
