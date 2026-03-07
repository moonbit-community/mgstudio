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
/// Port of `bevy/examples/3d/lines.rs`.

///|
fn color_green() -> @render2d.Color {
  @render2d.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_blue() -> @render2d.Color {
  @render2d.Color::new(0.2F, 0.5F, 1.0F, 1.0F)
}

///|
priv struct LineList {
  lines : Array[(@math.Vec3, @math.Vec3)]
}

///|
priv struct LineStrip {
  points : Array[@math.Vec3]
}

///|
fn line_mesh_from_line_list(line_list : LineList) -> @render3d.Mesh3d {
  let positions : Array[@math.Vec3] = []
  for i in 0..<line_list.lines.length() {
    let (start, end_) = line_list.lines[i]
    positions.push(start)
    positions.push(end_)
  }
  let uvs : Array[@math.Vec2] = []
  for _ in 0..<positions.length() {
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new_with_topology(
      positions,
      uvs,
      None,
      @mesh.Mesh3dPrimitiveTopology::LineList,
    ),
  )
}

///|
fn line_mesh_from_line_strip(line_strip : LineStrip) -> @render3d.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for point in line_strip.points {
    positions.push(point)
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new_with_topology(
      positions,
      uvs,
      None,
      @mesh.Mesh3dPrimitiveTopology::LineStrip,
    ),
  )
}

///|
fn line_material(
  color : @render2d.Color,
) -> @asset.Handle[@render3d.StandardMaterial] {
  @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(color).with_unlit(true),
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  @render3d.MeshMaterial3dBundle::new(
    line_mesh_from_line_list(LineList::{
      lines: [
        (@math.Vec3::zero(), @math.Vec3::new(1.0F, 1.0F, 0.0F)),
        (@math.Vec3::new(1.0F, 1.0F, 0.0F), @math.Vec3::new(1.0F, 0.0F, 0.0F)),
      ],
    }),
    @render3d.MeshMaterial3d::new(line_material(color_green())),
    @math.Transform::from_xyz(-1.5F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    line_mesh_from_line_strip(LineStrip::{
      points: [
        @math.Vec3::zero(),
        @math.Vec3::new(1.0F, 1.0F, 0.0F),
        @math.Vec3::new(1.0F, 0.0F, 0.0F),
      ],
    }),
    @render3d.MeshMaterial3d::new(line_material(color_blue())),
    @math.Transform::from_xyz(0.5F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
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
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
