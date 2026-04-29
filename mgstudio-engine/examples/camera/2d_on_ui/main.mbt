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
  ignore(
    commands.spawn(
      (@sprite.Camera2d::default(), @ui.IsDefaultUiCamera::default()),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Camera2d::default(),
        @sprite.Camera::default().with_order(1).with_clear_color_none(),
        @sprite.RenderLayers::layer(1),
      ),
    ),
  )

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::{
        ..@ui.Node::default(),
        width: @ui.Val::Percent(100.0F),
        height: @ui.Val::Percent(100.0F),
        justify_content: @ui.JustifyContent::Center,
        align_items: @ui.AlignItems::Center,
      },
      @ui.BackgroundColor::new(@sprite.Color::new(0.98F, 0.44F, 0.58F, 1.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::{
          ..@ui.Node::default(),
          width: @ui.Val::Percent(20.0F),
          height: @ui.Val::Percent(30.0F),
          min_width: @ui.Val::Px(150.0F),
          min_height: @ui.Val::Px(150.0F),
          border: @ui.UiRect::all(@ui.Val::Px(2.0F)),
          border_radius: @ui.BorderRadius::all(@ui.Val::Percent(25.0F)),
        },
        @ui.BorderColor::new(@sprite.Color::white()),
      ),
    ),
  )

  ignore(
    commands.spawn(
      @sprite.SpriteBundle::new_with_layers(
        @sprite.Sprite::from_image(
          asset_server.get().load("textures/rpg/chars/sensei/sensei.png"),
        ).with_custom_size(Some(@math.Vec2::new(100.0F, 100.0F))),
        @transform.Transform::identity(),
        @sprite.RenderLayers::layer(1),
      ),
    ),
  )
}

///|
fn rotate_sprite(
  time : @app.Res[@time.Time[Unit]],
  sprite : @app.Single[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Sprite],
  ],
) -> Unit {
  let delta_seconds = time.get().delta_seconds()
  let rotation = @math.Quat::from_rotation_z(delta_seconds * 0.5F).mul(
    @math.Quat::from_rotation_y(delta_seconds),
  )
  let transform = sprite.get()
  let current = transform.value()
  transform.set(
    current.with_rotation(rotation.mul(current.rotation).normalize()),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_sprite)))
  .run()
}
