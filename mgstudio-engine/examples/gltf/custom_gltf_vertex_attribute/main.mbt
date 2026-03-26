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
const GLTF_PATH : String = "models/barycentric/barycentric.gltf"

///|
struct ConvertedMeshState {
  source_handle : @asset.Handle[@mesh.Mesh]
  spawned : Bool
}

///|
let converted_mesh_state_key : @ecs.ResourceKey[ConvertedMeshState] = @ecs.register_resource(
  debug_name="examples.gltf.custom_gltf_vertex_attribute.ConvertedMeshState",
)

///|
pub impl @app.Resource for ConvertedMeshState with resource() {
  converted_mesh_state_key
}

///|
fn barycentric_colors(values : Array[@math.Vec3]) -> Array[@math.Vec4] {
  let colors : Array[@math.Vec4] = []
  for value in values {
    colors.push(@math.Vec4::new(value.x, value.y, value.z, 1.0F))
  }
  colors
}

///|
fn mesh3d_to_mesh2d(mesh_asset : @mesh.Mesh) -> @mesh.Mesh? {
  guard mesh_asset.as_3d_geometry() is Some(geometry) else { return None }
  let positions2d : Array[@math.Vec2] = []
  for position in geometry.positions {
    positions2d.push(@math.Vec2::new(position.x, position.y))
  }
  let colors = match geometry.custom_attribute_vec3("Barycentric") {
    Some(values) => barycentric_colors(values)
    None =>
      match geometry.colors {
        Some(existing) => existing
        None =>
          [
            @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
            @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
            @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F),
          ]
      }
  }
  Some(
    @mesh.Mesh::from_2d_geometry(
      @mesh.Mesh2dGeometry::new_with_colors(
        positions2d,
        geometry.uvs,
        colors,
        geometry.indices,
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  @gltf.gltf_clear_custom_vertex_attributes()
  @gltf.gltf_add_custom_vertex_attribute("_BARYCENTRIC", "Barycentric")
  commands.insert_resource(ConvertedMeshState::{
    source_handle: asset_server
    .get()
    .load(@gltf.GltfAssetLabel::Primitive(0, 0).from_asset(GLTF_PATH)),
    spawned: false,
  })
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default())),
  )
}

///|
fn spawn_converted_mesh(
  commands : @app.Commands,
  state : @app.ResMut[ConvertedMeshState],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  if state.get_ref().val.spawned {
    return
  }
  guard meshes.get_ref().val.get(state.get_ref().val.source_handle)
    is Some(source_mesh) else {
    return
  }
  guard mesh3d_to_mesh2d(source_mesh) is Some(converted) else { return }

  let mesh_handle = meshes.get_ref().val.add(converted)
  let material_handle = materials.get_ref().val
    |> @sprite.add_material(@sprite.Color::white())
  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(mesh_handle),
        @sprite.MeshMaterial2d::new(material_handle),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(180.0F)),
      ),
    ),
  )
  state.get_ref().val = ConvertedMeshState::{
    ..state.get_ref().val,
    spawned: true,
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(spawn_converted_mesh)),
  )
  .run()
}
