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
/// Exact parity target: rotate `Skybox` and `EnvironmentMapLight` together.
/// Tracking note: parity patch pass.

///|
const PI : Float = 3.141592653589793F

///|
fn create_sphere_mesh(
  meshes : @asset.Assets[@mesh.Mesh],
) -> @asset.Handle[@mesh.Mesh] {
  let sphere_mesh = @mesh_primitives_dim3.Meshable::mesh(
    @math.Sphere::new(1.0F),
  )
  sphere_mesh.generate_tangents() |> ignore
  meshes.add(@mesh.Mesh::from_3d_geometry(sphere_mesh))
}

///|
fn spawn_sphere(
  commands : @app.Commands,
  materials : @asset.Assets[@pbr.StandardMaterial],
  asset_server : @asset.AssetServer,
  sphere_mesh : @asset.Handle[@mesh.Mesh],
) -> Unit {
  let sphere_material = materials.add(
    @pbr.StandardMaterial::from_color(
      @color.Color::new(1.0F, 0.843F, 0.0F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.3F)
    .with_clearcoat_normal_texture(
      Some(
        asset_server.load_with_settings("textures/ScratchedGold-Normal.png", fn(
          settings,
        ) {
          settings.is_srgb = false
        }),
      ),
    )
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.1F),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_mesh),
        @pbr.MeshMaterial3dTyped::new(sphere_material),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(1.25F)),
      ),
    ),
  )
}

///|
fn spawn_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::PointLight()
        .with_color(@color.Color::white())
        .with_intensity(100_000.0F),
        @transform.Transform::identity(),
      ),
    ),
  )
}

///|
fn spawn_camera(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let camera = commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @pbr.Hdr::Hdr(),
      @camera_camera.Camera::Camera(),
      @camera.Projection::Perspective({
        ..PerspectiveProjection3d(),
        fov: 27.0F * PI / 180.0F,
      }),
      @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F),
      @post_process.Tonemapping::AcesFitted,
      @pbr.Skybox::new(
        asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
        5000.0F,
      ),
      @pbr.EnvironmentMapLight::new(
        Some(
          asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
        ),
        Some(
          asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
        ),
        2000.0F,
      ),
    ),
  )
  ignore(camera)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let sphere_mesh = create_sphere_mesh(meshes.peek())
  spawn_sphere(commands, materials.peek(), asset_server.get(), sphere_mesh)
  spawn_light(commands)
  spawn_camera(commands, asset_server.get())
}

///|
fn rotate_skybox_and_environment_map(
  environments : @ecs.Query[
    (@ecs.Write[@pbr.Skybox], @ecs.Write[@pbr.EnvironmentMapLight]),
    @ecs.All,
  ],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let now = time.get().elapsed_seconds()
  let angle = 0.2F * now
  let rotation = @math.Quat::from_rotation_y(angle)
  environments.view(fn(_entity, pair) {
    let (skybox, environment_map_light) = pair
    skybox.set(skybox.value().with_rotation(rotation))
    environment_map_light.set(
      environment_map_light.value().with_rotation(rotation),
    )
  }) catch {
    _ => return
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param4(Startup, setup)
  .add_systems_param2(Update, rotate_skybox_and_environment_map)
  .run()
}
