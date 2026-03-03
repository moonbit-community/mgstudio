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
const PANEL_SCALE : Float = 128.0F

///|
const PANEL_OFFSET : Float = 96.0F

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(mesh2d_vertex_color_texture_setup)
  .run()
}

///|
fn mesh2d_vertex_color_texture_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/banner.png")
  let mesh = create_colored_quad_mesh()
  let left_material = @render2d.ColorMaterial::new(@render2d.Color::white())
  let right_material = @render2d.ColorMaterial::from_image(texture)
  spawn_colored_panel(world, mesh, left_material, -PANEL_OFFSET)
  spawn_colored_panel(world, mesh, right_material, PANEL_OFFSET)
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn create_colored_quad_mesh() -> @render2d.Mesh2d {
  let positions = [
    @math.Vec2::new(-0.5F, -0.5F),
    @math.Vec2::new(0.5F, -0.5F),
    @math.Vec2::new(0.5F, 0.5F),
    @math.Vec2::new(-0.5F, 0.5F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let colors = [
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 1.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 1.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
    @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
  ]
  let indices = [0, 1, 2, 0, 2, 3]
  let geometry = @mesh.Mesh2dGeometry::new_with_colors(
    positions,
    uvs,
    colors,
    Some(indices),
  )
  @render2d.Mesh2d::from_geometry(geometry)
}

///|
fn spawn_colored_panel(
  world : @ecs.World,
  mesh : @render2d.Mesh2d,
  material : @render2d.ColorMaterial,
  x : Float,
) -> Unit {
  let transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(x, 0.0F),
    0.0F,
    @math.Vec2::new(PANEL_SCALE, PANEL_SCALE),
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}
