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
const SHADER_PATH : String = "shaders/custom/shader_material_screenspace_texture_3d.wgsl"

///|
struct OrbitCamera {}

///|
let orbit_camera_key : @ecs.ComponentKey[OrbitCamera] = @ecs.register_component(
  debug_name="examples.shader.shader_material_screenspace_texture.OrbitCamera",
)

///|
pub impl @ecs.Component for OrbitCamera with component() {
  orbit_camera_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let mesh = meshes.get_ref().val |> @pbr.add_mesh(@math.Sphere::new(1.1F))
  let material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_base_color_texture(
      Some(asset_server.get().load_image("branding/banner.png")),
    )
    .with_reflectance(0.45F),
  )
  commands.spawn(
    (
      @pbr.Mesh3d::new(mesh),
      @pbr.MeshMaterial3d::new(material).with_extension_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Mesh3d::new(
        meshes.get_ref().val.add(
          @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(8.0F, 8.0F)),
        ),
      ),
      @pbr.MeshMaterial3d::new(
        materials.get_ref().val.add(
          @pbr.StandardMaterial::from_color(
            @sprite.Color::srgb(0.08F, 0.1F, 0.14F),
          ),
        ),
      ),
      @transform.Transform::identity(),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_100_000.0F, 26.0F, false),
      @transform.Transform::from_xyz(5.0F, 6.0F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      OrbitCamera::{  },
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 2.5F, 6.0F).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn orbit_camera_system(
  time : @app.Res[@time.Time[Unit]],
  cameras : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[OrbitCamera]],
) -> Unit {
  let elapsed = time.get().elapsed_seconds()
  try! cameras.view(fn(_entity, transform) {
    let radius = 6.0F
    let x = radius * @math.cos(elapsed * 0.45F)
    let z = radius * @math.sin(elapsed * 0.45F)
    transform.set(
      @transform.Transform::from_xyz(x, 2.5F, z).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(orbit_camera_system)),
  )
  .run()
}
