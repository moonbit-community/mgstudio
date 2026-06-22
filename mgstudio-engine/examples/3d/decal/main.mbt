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
///
/// Forward decal example.

///|
const PI : Float = 3.141592653589793F

///|
const FRAC_PI_2 : Float = 1.5707963267948966F

///|
const GRID_COUNT : Int = 10

///|
const CUBE_SIZE : Float = 0.6F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  standard_materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  decal_standard_materials : @app.ResMut[
    @asset.Assets[@pbr.ForwardDecalMaterial],
  ],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let decal_material = decal_standard_materials
    .peek()
    .add(
      @pbr.ForwardDecalMaterial::new(
        @pbr.StandardMaterial::StandardMaterial().with_base_color_texture(
          Some(asset_server.get().load("textures/uv_checker_bw.png")),
        ),
        @pbr.ForwardDecalMaterialExt::new(1.0F),
      ),
    )

  commands.spawn(
    (
      @ecs.Name::new("Decal"),
      @pbr.ForwardDecal::ForwardDecal(),
      @pbr.forward_decal_mesh_material3d(decal_material),
      @transform.Transform::identity().with_scale(@math.Vec3::splat(4.0F)),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @ecs.Name::new("Camera"),
      @camera.Camera3d::Camera3d(),
      @camera_controller.FreeCamera::FreeCamera(),
      @pbr.DepthPrepass::DepthPrepass(),
      @transform.Transform::from_xyz(2.0F, 9.5F, 2.5F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore

  let white_material = standard_materials
    .peek()
    .add(@pbr.StandardMaterial::from_color(@color.Color::white()))

  commands.spawn(
    (
      @ecs.Name::new("Floor"),
      @mesh.Mesh3d::new(
        meshes.peek()
        |> @pbr.add_mesh(
          @mesh_primitives.RectangleMeshBuilder::new(10.0F, 10.0F).build(),
        ),
      ),
      @pbr.MeshMaterial3d::new(white_material),
      @transform.Transform::identity().with_rotation(
        @math.Quat::from_rotation_x(-FRAC_PI_2),
      ),
    ),
  )
  |> ignore

  let center_offset = (float_from_int(GRID_COUNT) - 1.0F) * 0.5F
  let rng = @chacha_rng.ChaCha8Rng::seed_from_u64(19878367467713UL)
  for i in 0..<GRID_COUNT {
    for j in 0..<GRID_COUNT {
      let rotation_vec = @math.Vec3::new(
        rng.random_float(),
        rng.random_float(),
        rng.random_float(),
      )
      let rotation = rng.random_range(360)
      let x = float_from_int(i) - center_offset
      let z = float_from_int(j) - center_offset
      let transform = @transform.Transform::from_xyz(x, -0.2F, z).with_rotation(
        @math.Quat::from_axis_angle(
          rotation_vec.normalize_or_zero(),
          float_from_int(rotation) * PI / 180.0F,
        ),
      )
      commands.spawn(
        (
          @mesh.Mesh3d::new(
            meshes.peek()
            |> @pbr.add_mesh(@math.Cuboid::new(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)),
          ),
          @pbr.MeshMaterial3d::new(white_material),
          transform,
        ),
      )
      |> ignore
    }
  }

  commands.spawn(
    (
      @ecs.Name::new("Light"),
      @pbr.PointLight::PointLight().with_shadow_maps_enabled(true),
      @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
    ),
  )
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(@camera_controller.FreeCameraPlugin::FreeCameraPlugin())
  .add_systems_param5(@app.Startup, setup)
  .run()
}
