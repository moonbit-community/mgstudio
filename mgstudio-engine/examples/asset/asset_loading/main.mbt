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
/// Port of `bevy/examples/asset/asset_loading.rs`.

///|
fn main {
  let plugins = @mgstudio.DefaultPlugins::build().build()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .run()
}

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.Res[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@render3d.StandardMaterial]],
) -> Unit {
  let world = @app.current_world().unwrap()
  let cube_handle : @asset.Handle[@mesh.Mesh] = asset_server
    .get()
    .load(
      @scene.GltfAssetLabel::Primitive(0, 0).from_asset("models/cube/cube.gltf"),
    )
  let sphere_handle : @asset.Handle[@mesh.Mesh] = asset_server
    .get()
    .load(
      @scene.GltfAssetLabel::Primitive(0, 0).from_asset(
        "models/sphere/sphere.gltf",
      ),
    )

  if meshes.get().get(sphere_handle) is Some(sphere) {
    let topology = if sphere.as_3d_geometry() is Some(geometry) {
      geometry.primitive_topology().to_string()
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
      @scene.GltfAssetLabel::Primitive(0, 0).from_asset(
        "models/torus/torus.gltf",
      ),
    )
  let material_handle = materials.get_ref().val.add(
    @render3d.StandardMaterial::from_color(
      @sprite.Color::srgb(0.8F, 0.7F, 0.6F),
    ),
  )
  let material = @render3d.MeshMaterial3d::new(material_handle)

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::new(torus_handle),
    material,
    @math.Transform::from_xyz(-3.0F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::new(cube_handle),
    material,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::new(sphere_handle),
    @render3d.MeshMaterial3d::new(material_handle),
    @math.Transform::from_xyz(3.0F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let tick = world.read_change_tick()
  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_point_light)
  .insert(light, @render3d.PointLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(light, @math.Transform::from_xyz(4.0F, 5.0F, 4.0F), tick)

  @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.0F, 3.0F, 10.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}
