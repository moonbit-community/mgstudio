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
/// Port of `bevy/examples/3d/texture.rs`.

///|
const PI : Float = 3.141592653589793F

///|
fn rectangle_mesh(width : Float, height : Float) -> @render3d.Mesh3d {
  let hw = width / 2.0F
  let hh = height / 2.0F
  let positions = [
    @math.Vec3::new(-hw, -hh, 0.0F),
    @math.Vec3::new(hw, -hh, 0.0F),
    @math.Vec3::new(hw, hh, 0.0F),
    @math.Vec3::new(-hw, hh, 0.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  ]
  let indices = [0, 1, 2, 0, 2, 3]
  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_logo_dark_big.png")
  let aspect = 0.25F
  let quad_width = 8.0F
  let quad = rectangle_mesh(quad_width, quad_width * aspect)

  let base_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::default()
    .with_base_color_texture(Some(texture))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )

  let red_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.0F, 0.0F, 0.5F),
    )
    .with_base_color_texture(Some(texture))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )

  let blue_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 0.0F, 1.0F, 0.5F),
    )
    .with_base_color_texture(Some(texture))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )

  let rotation = @math.Quat::from_rotation_x(-PI / 5.0F)

  @render3d.MeshMaterial3dBundle::new(
    quad,
    @render3d.MeshMaterial3d::new(base_material),
    @math.Transform::from_xyz(0.0F, 0.0F, 1.5F).with_rotation(rotation),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    quad,
    @render3d.MeshMaterial3d::new(red_material),
    @math.Transform::identity().with_rotation(rotation),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    quad,
    @render3d.MeshMaterial3d::new(blue_material),
    @math.Transform::from_xyz(0.0F, 0.0F, -1.5F).with_rotation(rotation),
  ).spawn(world)
  |> ignore

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(3.0F, 5.0F, 8.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .run()
}
