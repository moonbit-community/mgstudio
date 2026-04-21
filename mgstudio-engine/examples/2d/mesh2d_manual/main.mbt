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
const PI : Float = 3.141592653589793F

///|
const STAR_OUTER_RADIUS : Float = 200.0F

///|
const STAR_INNER_RADIUS : Float = 100.0F

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  let star = meshes.peek().add(build_star_mesh())
  let material = materials
    .peek()
    .add(@sprite.ColorMaterialAsset::from_color(@sprite.Color::white()))

  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (@sprite.Mesh2d::new(star), @sprite.MeshMaterial2d::new(material)),
    ),
  )
}

///|
fn build_star_mesh() -> @mesh.Mesh {
  let positions : Array[@math.Vec2] = []
  let uvs : Array[@math.Vec2] = []
  let colors : Array[@math.Vec4] = []
  let indices : Array[Int] = []

  // center vertex
  positions.push(@math.Vec2::new(0.0F, 0.0F))
  uvs.push(@math.Vec2::new(0.5F, 0.5F))
  colors.push(@math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F))

  // ring vertices (alternating outer/inner radius)
  for i in 0..<10 {
    let angle = Float::from_double(i.to_double()) * PI / 5.0F
    let radius = if i % 2 == 0 { STAR_OUTER_RADIUS } else { STAR_INNER_RADIUS }
    let x = radius * @math.sin(angle)
    let y = radius * @math.cos(angle)
    positions.push(@math.Vec2::new(x, y))
    uvs.push(
      @math.Vec2::new(
        x / (STAR_OUTER_RADIUS * 2.0F) + 0.5F,
        y / (STAR_OUTER_RADIUS * 2.0F) + 0.5F,
      ),
    )
    colors.push(@math.Vec4::new(1.0F, 0.92F, 0.016F, 1.0F))
  }

  // fan triangles around center
  indices.push(0)
  indices.push(1)
  indices.push(10)
  for i in 2..<11 {
    indices.push(0)
    indices.push(i)
    indices.push(i - 1)
  }

  let geometry = @mesh.Mesh2dGeometry::new_with_colors(
    positions,
    uvs,
    colors,
    Some(indices),
  )
  @mesh.Mesh::from_2d_geometry(geometry)
}
