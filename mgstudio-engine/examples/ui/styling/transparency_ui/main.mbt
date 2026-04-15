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
fn button_node() -> @ui.Node {
  @ui.Node::default()
  .with_width(@ui.Val::Px(150.0F))
  .with_height(@ui.Val::Px(65.0F))
  .with_justify_content(@ui.JustifyContent::Center)
  .with_align_items(@ui.AlignItems::Center)
}

///|
fn transparent_text_color() -> @text.TextColor {
  @text.TextColor::new(@sprite.Color::srgba(1.0F, 1.0F, 1.0F, 0.2F))
}

///|
fn spawn_button(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
  background : @sprite.Color,
) -> Unit {
  let button = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(button)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @ui.Button::default(),
        button_node(),
        @ui.BackgroundColor::new(background),
      ),
    ),
  )

  let text = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(text)
    .insert(
      (
        @hierarchy.Parent::new(button),
        @text.Text::new(label),
        @text.TextFont::from_font_size(@text.FontSize::Px(33.0F)).with_font(
          font,
        ),
        transparent_text_color(),
      ),
    ),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  ignore(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::identity(),
    ).spawn(world),
  )

  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")

  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert(
      (
        @ui.UiRoot::default(),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Percent(100.0F))
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::SpaceAround),
      ),
    ),
  )

  spawn_button(
    world,
    root,
    font,
    "Button 1",
    @sprite.Color::srgb(0.1F, 0.5F, 0.1F),
  )
  spawn_button(
    world,
    root,
    font,
    "Button 2",
    @sprite.Color::srgb(0.5F, 0.1F, 0.5F),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .insert_resource(
    @sprite.ClearColor::new(@sprite.Color::srgb(0.0F, 0.0F, 0.0F)),
  )
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
