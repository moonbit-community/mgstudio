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
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.Res[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let cube_handle : @asset.Handle[@mesh.Mesh] = asset_server
    .get()
    .load(
      @gltf.GltfAssetLabel::Primitive(0, 0).from_asset("models/cube/cube.gltf"),
    )
  let sphere_handle : @asset.Handle[@mesh.Mesh] = asset_server
    .get()
    .load(
      @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(
        "models/sphere/sphere.gltf",
      ),
    )

  if meshes.get().get(sphere_handle) is Some(sphere) {
    let topology = if sphere.as_3d_geometry() is Some(geometry) {
      to_repr(geometry.primitive_topology()).to_string()
    } else {
      "Unknown"
    }
    @app.log_info(topology)
  } else {
    @app.log_info("sphere hasn't loaded yet")
  }

  let loaded_folder : @asset.Handle[@asset.LoadedFolder] = asset_server
    .get()
    .load_folder("models/torus")
  loaded_folder |> ignore

  let torus_handle : @asset.Handle[@mesh.Mesh] = asset_server
    .get()
    .load(
      @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(
        "models/torus/torus.gltf",
      ),
    )

  let material_handle = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.8F, 0.7F, 0.6F)),
    )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(torus_handle),
        @pbr.MeshMaterial3d::new(material_handle),
        @transform.Transform::from_xyz(-3.0F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_handle),
        @pbr.MeshMaterial3d::new(material_handle),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(sphere_handle),
        @pbr.MeshMaterial3d::new(material_handle),
        @transform.Transform::from_xyz(3.0F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default(),
        @transform.Transform::from_xyz(4.0F, 5.0F, 4.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 3.0F, 10.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}
