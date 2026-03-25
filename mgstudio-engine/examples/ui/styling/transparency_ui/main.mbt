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
fn spawn_button(
  commands : @app.Commands,
  parent : @core.Entity,
  label : String,
  background : @sprite.Color,
  font : @asset.Handle[@asset.Font],
) -> Unit {
  let button = commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @ui.Button::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Px(150.0F))
      .with_height(@ui.Val::Px(65.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BackgroundColor::new(background),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new(label),
        @text.TextFont::default()
        .with_font(font)
        .with_font_size(@text.FontSize::Px(33.0F)),
        @text.TextColor::new(@sprite.Color::new(1.0F, 1.0F, 1.0F, 0.2F)),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::SpaceAround),
    ),
  )
  spawn_button(
    commands,
    root,
    "Button 1",
    @sprite.Color::srgb(0.1F, 0.5F, 0.1F),
    font,
  )
  spawn_button(
    commands,
    root,
    "Button 2",
    @sprite.Color::srgb(0.5F, 0.1F, 0.5F),
    font,
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
