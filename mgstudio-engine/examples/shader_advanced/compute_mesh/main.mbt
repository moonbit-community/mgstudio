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
const SHADER_PATH : String = "shaders/custom/compute_mesh_3d.wgsl"

///|
const GRID_RESOLUTION : Int = 28

///|
struct ComputeMeshTarget {}

///|
let compute_mesh_target_key : @ecs.ComponentKey[ComputeMeshTarget] = @ecs.register_component(
  debug_name="examples.shader_advanced.compute_mesh.ComputeMeshTarget",
)

///|
pub impl @ecs.Component for ComputeMeshTarget with component() {
  compute_mesh_target_key
}

///|
fn build_wave_geometry(time : Float) -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []
  for y in 0..<(GRID_RESOLUTION + 1) {
    for x in 0..<(GRID_RESOLUTION + 1) {
      let fx = Float::from_int(x) / Float::from_int(GRID_RESOLUTION) * 2.0F -
        1.0F
      let fy = Float::from_int(y) / Float::from_int(GRID_RESOLUTION) * 2.0F -
        1.0F
      let wave = @math.sin(fx * 4.0F + time) *
        @math.cos(fy * 4.0F + time * 0.7F)
      positions.push(@math.Vec3::new(fx * 2.5F, wave * 0.35F, fy * 2.5F))
      uvs.push(@math.Vec2::new((fx + 1.0F) * 0.5F, (fy + 1.0F) * 0.5F))
    }
  }
  for y in 0..<GRID_RESOLUTION {
    for x in 0..<GRID_RESOLUTION {
      let row = y * (GRID_RESOLUTION + 1)
      let i0 = row + x
      let i1 = i0 + 1
      let i2 = i0 + GRID_RESOLUTION + 1
      let i3 = i2 + 1
      indices.push(i0)
      indices.push(i2)
      indices.push(i1)
      indices.push(i1)
      indices.push(i2)
      indices.push(i3)
    }
  }
  @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices))
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_handle = meshes.get_ref().val.add(
    @mesh.Mesh::from_3d_geometry(build_wave_geometry(0.0F)),
  )
  let material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.22F, 0.82F, 0.7F)).with_perceptual_roughness(
      0.55F,
    ),
  )
  commands.spawn(
    (
      ComputeMeshTarget::{  },
      @pbr.Mesh3d::new(mesh_handle),
      @pbr.MeshMaterial3d::new(material).with_extension_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::identity(),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_400_000.0F, 40.0F, false),
      @transform.Transform::from_xyz(0.0F, 8.0F, 6.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 4.2F, 8.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn compute_mesh_system(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Comp[@pbr.Mesh3d], @ecs.With[ComputeMeshTarget]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  let t = time.get().elapsed_seconds()
  try! query.view(fn(_entity, mesh3d) {
    let handle = mesh3d.value().mesh()
    meshes.get_ref().val.set(
      handle,
      @mesh.Mesh::from_3d_geometry(build_wave_geometry(t)),
    )
    |> ignore
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(compute_mesh_system)),
  )
  .run()
}
