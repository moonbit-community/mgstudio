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
struct Rotates {}

///|
let rotates_key : @ecs.ComponentKey[Rotates] = @ecs.register_component(
  debug_name="examples.math.custom_primitives.Rotates",
)

///|
pub impl @ecs.Component for Rotates with component() {
  rotates_key
}

///|
fn custom_pyramid_mesh() -> @mesh.Mesh3dGeometry {
  let positions : Array[@math.Vec3] = [
    @math.Vec3::new(0.0F, 1.2F, 0.0F),
    @math.Vec3::new(-1.0F, 0.0F, -1.0F),
    @math.Vec3::new(1.0F, 0.0F, -1.0F),
    @math.Vec3::new(1.0F, 0.0F, 1.0F),
    @math.Vec3::new(-1.0F, 0.0F, 1.0F),
  ]
  let uvs : Array[@math.Vec2] = [
    @math.Vec2::new(0.5F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 0.0F),
  ]
  let indices : Array[Int] = [
    1, 2, 3, 1, 3, 4, 0, 1, 2, 0, 2, 3, 0, 3, 4, 0, 4, 1,
  ]
  @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices))
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val

  let plane_mesh = mesh_assets
    |> @pbr.add_mesh(@pbr.mesh3d_geometry_plane(16.0F, 16.0F))
  let pyramid_mesh = mesh_assets |> @pbr.add_mesh(custom_pyramid_mesh())

  let plane_material = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.13F, 0.14F, 0.16F))
  let pyramid_material = material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::srgb(0.88F, 0.18F, 0.36F),
      )
      .with_reflectance(0.28F)
      .with_perceptual_roughness(0.48F),
    )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::identity(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(pyramid_mesh),
        @pbr.MeshMaterial3d::new(pyramid_material),
        Rotates::{  },
        @transform.Transform::from_xyz(0.0F, 0.7F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default().with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(4.0F, 3.8F, 6.5F).looking_at(
          @math.Vec3::new(0.0F, 0.7F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotate(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Rotates]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    let value = transform.get_ref()
    value.val.rotation = value.val.rotation
      .mul(@math.Quat::from_rotation_y(delta * 0.9F))
      .normalize()
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate)))
  .run()
}
