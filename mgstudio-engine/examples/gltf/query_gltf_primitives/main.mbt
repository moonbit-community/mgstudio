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
const GLTF_PRIMITIVES_SCENE_ASSET : String = "models/GltfPrimitives/gltf_primitives.glb"

///|
const FRAC_PI_4 : Float = 0.7853981633974483F

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(4.0F, 4.0F, 12.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.5F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @transform.Transform::from_rotation(
          @math.Quat::from_euler(@math.EulerRot::ZYX, 0.0F, 1.0F, -FRAC_PI_4),
        ),
        @pbr.DirectionalLight::default(),
      ),
    ),
  )

  ignore(
    commands.spawn_component(
      @scene.SceneRoot::new(
        server.load(
          @gltf.GltfAssetLabel::Scene(0).from_asset(GLTF_PRIMITIVES_SCENE_ASSET),
        ),
      ),
    ),
  )
}

///|
fn find_top_material_and_mesh(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[
    (
      @ecs.Comp[@pbr.MeshMaterial3d],
      @ecs.Comp[@pbr.Mesh3d],
      @ecs.Comp[@gltf.GltfPrimitiveIndex],
      @ecs.Comp[@gltf.GltfMaterialName],
    ),
    @ecs.All,
  ],
) -> Unit {
  let elapsed = time.get().elapsed_secs()
  let target_color = @sprite.Color::hsl(elapsed * 100.0F, 0.9F, 0.7F)
  let target_y = 1.5F + 0.5F * @math.sin(elapsed / 2.0F)
  let material_assets = materials.peek()
  let mesh_assets = meshes.peek()

  try! query.view(fn(_entity, data) {
    let (material_comp, mesh_comp, primitive_index_comp, material_name_comp) = data
    if material_name_comp.value().as_str() != "Top" {
      return
    }
    let primitive_offset = Float::from_double(
      primitive_index_comp.value().primitive_index().to_double(),
    )

    let material_handle = material_comp.value().material
    guard material_assets.get(material_handle) is Some(material) else { return }
    material_assets.set(material_handle, material.with_base_color(target_color))
    |> ignore

    let mesh_handle = mesh_comp.value().mesh
    guard mesh_assets.get_mut(mesh_handle) is Some(mesh_asset) else { return }
    guard mesh_asset.as_3d_geometry() is Some(geometry) else { return }

    for i in 0..<geometry.positions.length() {
      let position = geometry.positions[i]
      geometry.positions[i] = @math.Vec3::new(
        position.x,
        target_y + primitive_offset * 0.15F,
        position.z,
      )
    }

    if mesh_asset.with_3d_geometry(geometry) is Some(updated) {
      ignore(mesh_assets.set(mesh_handle, updated))
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param4(find_top_material_and_mesh)),
  )
  .run()
}
