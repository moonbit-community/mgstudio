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
struct Spin {}

///|
let spin_key : @ecs.ComponentKey[Spin] = @ecs.register_component(
  debug_name="examples.math.render_primitives.Spin",
)

///|
pub impl @ecs.Component for Spin with component() {
  spin_key
}

///|
fn spawn_primitive(
  commands : @app.Commands,
  mesh : @asset.Handle[@mesh.Mesh],
  material : @asset.Handle[@pbr.StandardMaterial],
  x : Float,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(mesh),
        @pbr.MeshMaterial3d::new(material),
        Spin::{  },
        @transform.Transform::from_xyz(x, 1.0F, 0.0F),
      ),
    ),
  )
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
    |> @pbr.add_mesh(@pbr.mesh3d_geometry_plane(26.0F, 10.0F))
  let plane_material = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.09F, 0.10F, 0.13F))

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(plane_mesh),
        @pbr.MeshMaterial3d::new(plane_material),
        @transform.Transform::identity(),
      ),
    ),
  )

  let cuboid_mesh = mesh_assets
    |> @pbr.add_mesh(@math.Cuboid::new(1.2F, 1.2F, 1.2F))
  let sphere_mesh = mesh_assets |> @pbr.add_mesh(@math.Sphere::new(0.7F))
  let capsule_mesh = mesh_assets
    |> @pbr.add_mesh(@math.Capsule3d::new(0.45F, 0.65F))
  let cylinder_mesh = mesh_assets
    |> @pbr.add_mesh(@math.Cylinder::new(0.55F, 0.55F))
  let tetrahedron_mesh = mesh_assets
    |> @pbr.add_mesh(
      @math.Tetrahedron::new(
        @math.Vec3::new(-0.7F, 0.0F, 0.45F),
        @math.Vec3::new(0.7F, 0.0F, 0.45F),
        @math.Vec3::new(0.0F, 0.0F, -0.85F),
        @math.Vec3::new(0.0F, 1.2F, 0.0F),
      ),
    )
  let icosphere_mesh = mesh_assets
    |> @pbr.add_mesh(@pbr.mesh3d_geometry_icosphere(0.75F, 3))

  let mat_red = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.88F, 0.32F, 0.35F))
  let mat_orange = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.94F, 0.58F, 0.27F))
  let mat_yellow = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.95F, 0.85F, 0.30F))
  let mat_green = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.45F, 0.78F, 0.36F))
  let mat_blue = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.32F, 0.54F, 0.92F))
  let mat_purple = material_assets
    |> @pbr.add_material(@sprite.Color::srgb(0.73F, 0.44F, 0.86F))

  spawn_primitive(commands, cuboid_mesh, mat_red, -7.5F)
  spawn_primitive(commands, sphere_mesh, mat_orange, -4.5F)
  spawn_primitive(commands, capsule_mesh, mat_yellow, -1.5F)
  spawn_primitive(commands, cylinder_mesh, mat_green, 1.5F)
  spawn_primitive(commands, tetrahedron_mesh, mat_blue, 4.5F)
  spawn_primitive(commands, icosphere_mesh, mat_purple, 7.5F)

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default().with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(0.0F, 10.0F, 8.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 4.8F, 13.0F).looking_at(
          @math.Vec3::new(0.0F, 0.8F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotate(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Spin]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    let value = transform.get_ref()
    value.val.rotation = value.val.rotation
      .mul(@math.Quat::from_rotation_y(delta * 0.8F))
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
