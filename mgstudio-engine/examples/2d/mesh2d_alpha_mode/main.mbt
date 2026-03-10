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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(mesh2d_alpha_mode_setup))
  .run()
}

///|
fn spawn_quad(
  world : @ecs.World,
  mesh : @sprite.Mesh2d,
  texture : @asset.Handle[@asset.Image],
  position : @math.Vec2,
  color : @sprite.Color,
  alpha_mode : @sprite.AlphaMode2d,
  z : Float,
) -> Unit {
  let material = @sprite.ColorMaterial::new_with_alpha_mode(color, alpha_mode).with_texture(
    texture,
  )
  let transform = @math.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
    z~,
  )
  @sprite.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn mesh2d_alpha_mode_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let mesh = @sprite.Mesh2d::from_rectangle(
    @sprite.Rectangle::from_size(@math.Vec2::new(256.0F, 256.0F)),
  )
  let white = @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F)
  let blue = @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F)
  let blue_blend = @sprite.Color::new(0.0F, 0.0F, 1.0F, 0.7F)
  let green = @sprite.Color::new(0.0F, 0.5019608F, 0.0F, 1.0F)
  let green_blend = @sprite.Color::new(0.0F, 0.5019608F, 0.0F, 0.7F)

  // Opaque: black background from icon texture should remain visible.
  spawn_quad(
    world,
    mesh,
    texture,
    @math.Vec2::new(-400.0F, 0.0F),
    white,
    @sprite.AlphaMode2d::Opaque,
    0.0F,
  )
  spawn_quad(
    world,
    mesh,
    texture,
    @math.Vec2::new(-300.0F, 0.0F),
    blue,
    @sprite.AlphaMode2d::Opaque,
    1.0F,
  )
  spawn_quad(
    world,
    mesh,
    texture,
    @math.Vec2::new(-200.0F, 0.0F),
    green,
    @sprite.AlphaMode2d::Opaque,
    -1.0F,
  )
  spawn_quad(
    world,
    mesh,
    texture,
    @math.Vec2::new(200.0F, 0.0F),
    white,
    @sprite.AlphaMode2d::Mask(0.5F),
    0.0F,
  )
  spawn_quad(
    world,
    mesh,
    texture,
    @math.Vec2::new(300.0F, 0.0F),
    blue_blend,
    @sprite.AlphaMode2d::Blend,
    1.0F,
  )
  spawn_quad(
    world,
    mesh,
    texture,
    @math.Vec2::new(400.0F, 0.0F),
    green_blend,
    @sprite.AlphaMode2d::Blend,
    -1.0F,
  )

  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(world)
  |> ignore
}
