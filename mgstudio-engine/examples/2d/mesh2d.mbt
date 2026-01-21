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
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new().add_plugins(plugins).add_startup_system(mesh2d_setup).run()
}

///|
fn mesh2d_setup() -> Unit {
  let mesh = @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::default())
  let material = @render2d.ColorMaterial::new(
    @render2d.Color::new(0.62F, 0.33F, 0.83F, 1.0F),
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
