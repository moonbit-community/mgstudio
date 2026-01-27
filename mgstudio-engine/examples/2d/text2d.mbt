// Copyright 2025 International Digital Economy Academy
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
pub fn text2d_run() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = [
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @window.window_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @time.time_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @asset.asset_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @render2d.render2d_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @text.text_plugin(app)
    },
    fn(app : @app.App[@ecs_world.World]) -> @app.App[@ecs_world.World] {
      @input.input_plugin(app)
    },
  ]
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(fn(_world : @ecs_world.World) { text2d_setup() })
  .run()
}

///|
fn text2d_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let font_style = @text.TextFont::default()
    .with_font(font)
    .with_font_size(48.0F)
  let text = @text.Text2d::new(
    "Hello, Text2d!\nThis line demonstrates wrapping + centering.",
  )
  @text.Text2dBundle::new(
    text,
    font_style,
    @math.Transform::new(
      @math.Vec2::new(0.0F, 0.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    ),
  )
  .with_bounds(@text.TextBounds::new_horizontal(520.0F))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Center))
  .with_shadow(Some(@text.Text2dShadow::default()))
  .with_color(@text.TextColor::new(@render2d.Color::white()))
  .spawn()
  |> ignore
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
}
