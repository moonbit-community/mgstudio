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
fn add_mesh(
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  geometry : @mesh.Mesh3dGeometry,
) -> @asset.Handle[@mesh.Mesh] {
  meshes.modify(fn(assets) {
    assets.add(@mesh.Mesh::from_3d_geometry(geometry))
  })
}

///|
fn add_material(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  material : @pbr.StandardMaterial,
) -> @asset.Handle[@pbr.StandardMaterial] {
  materials.modify(fn(assets) { assets.add(material) })
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  // Opaque plane, uses `alpha_mode: Opaque` by default.
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          add_mesh(
            meshes,
            @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
              @math.Vec2::new(6.0F, 6.0F),
            ).build(),
          ),
        ),
        @pbr.MeshMaterial3dTyped::new(
          add_material(
            materials,
            @pbr.StandardMaterial::from_color(
              @color.Color::srgb(0.3F, 0.5F, 0.3F),
            ),
          ),
        ),
      ),
    ),
  )

  let sphere_geometry = @mesh_primitives_dim3.SphereMeshBuilder::from_sphere(
    @math.Sphere::new(0.5F),
  ).ico(3) catch {
    _ => abort("transparency_3d sphere subdivisions should be valid")
  }
  let sphere_mesh = add_mesh(meshes, sphere_geometry)

  // Transparent sphere, uses `alpha_mode: Mask(f32)`.
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_mesh),
        @pbr.MeshMaterial3dTyped::new(
          add_material(
            materials,
            @pbr.StandardMaterial::from_color(
              @color.Color::srgba(0.2F, 0.7F, 0.1F, 0.0F),
            ).with_alpha_mode(Mask(0.5F)),
          ),
        ),
        @transform.Transform::from_xyz(1.0F, 0.5F, -1.5F),
      ),
    ),
  )

  // Transparent unlit sphere, uses `alpha_mode: Mask(f32)`.
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_mesh),
        @pbr.MeshMaterial3dTyped::new(
          add_material(
            materials,
            @pbr.StandardMaterial::from_color(
              @color.Color::srgba(0.2F, 0.7F, 0.1F, 0.0F),
            )
            .with_alpha_mode(Mask(0.1F))
            .with_unlit(true),
          ),
        ),
        @transform.Transform::from_xyz(-1.0F, 0.5F, -1.5F),
      ),
    ),
  )

  let cube_mesh = add_mesh(
    meshes,
    @mesh_primitives_dim3.Meshable::mesh(@math.Cuboid::Cuboid()),
  )

  // Transparent cube, uses `alpha_mode: Blend`.
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3dTyped::new(
          add_material(
            materials,
            @pbr.StandardMaterial::from_color(
              @color.Color::srgba(0.5F, 0.5F, 1.0F, 0.0F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
      ),
    ),
  )

  // Transparent cube, uses `alpha_mode: AlphaToCoverage`.
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3dTyped::new(
          add_material(
            materials,
            @pbr.StandardMaterial::from_color(
              @color.Color::srgba(0.5F, 1.0F, 0.5F, 0.0F),
            ).with_alpha_mode(AlphaToCoverage),
          ),
        ),
        @transform.Transform::from_xyz(-1.5F, 0.5F, 0.0F),
      ),
    ),
  )

  // Opaque sphere.
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(sphere_mesh),
        @pbr.MeshMaterial3dTyped::new(
          add_material(
            materials,
            @pbr.StandardMaterial::from_color(
              @color.Color::srgb(0.7F, 0.2F, 0.1F),
            ),
          ),
        ),
        @transform.Transform::from_xyz(0.0F, 0.5F, -1.5F),
      ),
    ),
  )

  // Light.
  ignore(
    commands.spawn(
      (
        @pbr.PointLight::PointLight().with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )

  // Camera.
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-2.0F, 3.0F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
/// Fades the alpha channel of all materials between 0 and 1.
fn fade_transparency(
  time : @app.Res[@time.Time[Unit]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let alpha = @math.sin(time.get().elapsed_seconds()) / 2.0F + 0.5F
  materials.modify(fn(assets) {
    let entries = assets.iter()
    for entry in entries {
      let (handle, material) = entry
      ignore(
        assets.set(
          handle,
          material.with_base_color(material.base_color.with_alpha(alpha)),
        ),
      )
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param3(Startup, setup)
  .add_systems_param2(Update, fade_transparency)
  .run()
}
