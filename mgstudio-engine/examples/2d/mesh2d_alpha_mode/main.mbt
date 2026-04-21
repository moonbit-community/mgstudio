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
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .run()
}

///|
fn spawn_quad(
  commands : @app.Commands,
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  mesh : @asset.Handle[@mesh.Mesh],
  texture : @asset.Handle[@asset.Image],
  position : @math.Vec2,
  color : @sprite.Color,
  alpha_mode : @sprite.AlphaMode2d,
  z : Float,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(mesh),
        @sprite.MeshMaterial2d::new(
          materials
          .peek()
          .add(
            @sprite.ColorMaterialAsset::new(
              color,
              alpha_mode,
              texture=Some(texture),
            ),
          ),
        ),
        @transform.Transform::from_xyz(position.x, position.y, z),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let texture = asset_server.get().load("branding/icon.png")
  let mesh = meshes
    .peek()
    .add(
      @sprite.mesh2d_geometry_rectangle(
        @sprite.Rectangle::from_size(@math.Vec2::new(256.0F, 256.0F)),
      ).to_mesh(),
    )
  let white = @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F)
  let blue = @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F)
  let blue_blend = @sprite.Color::new(0.0F, 0.0F, 1.0F, 0.7F)
  let green = @sprite.Color::new(0.0F, 0.5019608F, 0.0F, 1.0F)
  let green_blend = @sprite.Color::new(0.0F, 0.5019608F, 0.0F, 0.7F)

  // Opaque: black background from icon texture should remain visible.
  spawn_quad(
    commands,
    materials,
    mesh,
    texture,
    @math.Vec2::new(-400.0F, 0.0F),
    white,
    @sprite.AlphaMode2d::Opaque,
    0.0F,
  )
  spawn_quad(
    commands,
    materials,
    mesh,
    texture,
    @math.Vec2::new(-300.0F, 0.0F),
    blue,
    @sprite.AlphaMode2d::Opaque,
    1.0F,
  )
  spawn_quad(
    commands,
    materials,
    mesh,
    texture,
    @math.Vec2::new(-200.0F, 0.0F),
    green,
    @sprite.AlphaMode2d::Opaque,
    -1.0F,
  )
  spawn_quad(
    commands,
    materials,
    mesh,
    texture,
    @math.Vec2::new(200.0F, 0.0F),
    white,
    @sprite.AlphaMode2d::Mask(0.5F),
    0.0F,
  )
  spawn_quad(
    commands,
    materials,
    mesh,
    texture,
    @math.Vec2::new(300.0F, 0.0F),
    blue_blend,
    @sprite.AlphaMode2d::Blend,
    1.0F,
  )
  spawn_quad(
    commands,
    materials,
    mesh,
    texture,
    @math.Vec2::new(400.0F, 0.0F),
    green_blend,
    @sprite.AlphaMode2d::Blend,
    -1.0F,
  )
}
