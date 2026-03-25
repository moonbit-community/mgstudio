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

///|
fn spawn_text(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  camera : @ecs.Query[@ecs.Comp[@sprite.PanCamera], @ecs.All],
) -> Unit {
  guard (try! camera.single()) is Some(controller_comp) else { return }
  let controller = controller_comp.value()
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_top(@ui.Val::Px(-16.0F))
        .with_left(@ui.Val::Px(12.0F)),
        @text.Text::new(controller.to_string()),
        @text.TextFont::default().with_font(font).with_font_size(20.0F),
        @text.TextColor::new(@sprite.Color::white()),
        @text.TextLayout::new_with_justify(@text.Justify::Left),
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
    commands.spawn((@sprite.Camera2d::default(), @sprite.PanCamera::default())),
  )
  ignore(
    commands.spawn_component(
      @sprite.Sprite::from_image(
        asset_server.get().load("branding/bevy_bird_dark.png"),
      ),
    ),
  )
}

///|
fn main {
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(setup),
  )
  let spawn_text_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(spawn_text),
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugins([@sprite.pan_camera_plugin])
  .add_systems(@app.Startup, (setup_system, spawn_text_system) |> @app.chain())
  .run()
}
