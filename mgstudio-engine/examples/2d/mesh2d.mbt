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
pub fn mesh2d_run() -> Unit {
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
      @input.input_plugin(app)
    },
  ]
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(fn(_world : @ecs_world.World) { mesh2d_setup() })
  .run()
}

///|
fn mesh2d_setup() -> Unit {
  let mesh = @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::default())
  let material = @render2d.ColorMaterial::new(
    @render2d.Color::new(0.5019608F, 0.0F, 0.5019608F, 1.0F),
  )
  let transform = @math.Transform::new(
    @math.Vec2::new(0.0F, 0.0F),
    0.0F,
    @math.Vec2::new(128.0F, 128.0F),
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn() |> ignore
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
}
