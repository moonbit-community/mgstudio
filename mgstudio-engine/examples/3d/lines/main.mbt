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
fn color_green() -> @sprite.Color {
  @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F)
}

///|
fn color_blue() -> @sprite.Color {
  @sprite.Color::new(0.2F, 0.5F, 1.0F, 1.0F)
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
fn line_mesh_from_line_list(line_list : LineList) -> @mesh.Mesh3dGeometry {
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
  @mesh.Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    None,
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}

///|
fn line_mesh_from_line_strip(line_strip : LineStrip) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  for point in line_strip.points {
    positions.push(point)
    uvs.push(@math.Vec2::new(0.0F, 0.0F))
  }
  @mesh.Mesh3dGeometry::new_with_topology(
    positions,
    uvs,
    None,
    @mesh.Mesh3dPrimitiveTopology::LineStrip,
  )
}

///|
fn line_material(color : @sprite.Color) -> @pbr.StandardMaterial {
  @pbr.StandardMaterial::from_color(color).with_unlit(true)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets
          |> @pbr.add_mesh(
            line_mesh_from_line_list(LineList::{
              lines: [
                (@math.Vec3::zero(), @math.Vec3::new(1.0F, 1.0F, 0.0F)),
                (
                  @math.Vec3::new(1.0F, 1.0F, 0.0F),
                  @math.Vec3::new(1.0F, 0.0F, 0.0F),
                ),
              ],
            }),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          material_assets |> @pbr.add_material(line_material(color_green())),
        ),
        @transform.Transform::from_xyz(-1.5F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(
          mesh_assets
          |> @pbr.add_mesh(
            line_mesh_from_line_strip(LineStrip::{
              points: [
                @math.Vec3::zero(),
                @math.Vec3::new(1.0F, 1.0F, 0.0F),
                @math.Vec3::new(1.0F, 0.0F, 0.0F),
              ],
            }),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          material_assets |> @pbr.add_material(line_material(color_blue())),
        ),
        @transform.Transform::from_xyz(0.5F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .run()
}
