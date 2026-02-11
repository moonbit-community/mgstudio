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
const PANEL_SIDE : Float = 200.0F

///|
const PANEL_OFFSET : Float = 250.0F

///|
fn spawn_panel(
  world : @ecs_world.World,
  x : Float,
  texture : @asset.Handle[@asset.Image],
  uv_scale : @math.Vec2,
) -> Unit {
  let mesh = @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::default())
  let material = @render2d.ColorMaterial::from_image(texture).with_uv_scale(
    uv_scale,
  )
  let transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(x, 0.0F),
    0.0F,
    @math.Vec2::new(PANEL_SIDE, PANEL_SIDE),
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn mesh2d_repeated_texture_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let default_texture = asset_server.load(
    "textures/rpg/ui/generic-rpg-ui-text-box.png",
  )
  let repeated_texture = asset_server.load(
    "textures/rpg/ui/generic-rpg-ui-text-box-repeated.png",
  )
  @asset.asset_set_texture_sampler(default_texture, @asset.ImageSampler::Linear)
  @asset.asset_set_texture_sampler(
    repeated_texture,
    @asset.ImageSampler::LinearRepeat,
  )

  // Left: repeated sampling with scaled UVs.
  spawn_panel(
    world,
    -PANEL_OFFSET,
    repeated_texture,
    @math.Vec2::new(2.0F, 3.0F),
  )
  // Center: baseline UVs.
  spawn_panel(world, 0.0F, default_texture, @math.Vec2::new(1.0F, 1.0F))
  // Right: scaled UVs with clamp sampler (repeat off).
  spawn_panel(world, PANEL_OFFSET, default_texture, @math.Vec2::new(2.0F, 3.0F))
  let camera = @render2d.Camera::new(
    @render2d.Color::new(0.09F, 0.09F, 0.11F, 1.0F),
  )
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
pub fn app_main() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(mesh2d_repeated_texture_setup)
  .run()
}

///|
fn main {
  app_main()
}
