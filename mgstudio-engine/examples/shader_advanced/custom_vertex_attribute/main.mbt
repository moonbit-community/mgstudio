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
const SHADER_ASSET_PATH : String = "shaders/custom_vertex_attribute.wgsl"

///|
const ATTRIBUTE_BLEND_COLOR : String = "BlendColor"

///|
struct Rotates {}

///|
let rotates_key : @ecs.ComponentKey[Rotates] = @ecs.register_component(
  debug_name="examples.shader_advanced.custom_vertex_attribute.Rotates",
)

///|
pub impl @ecs.Component for Rotates with component() {
  rotates_key
}

///|
fn custom_attribute_cube_geometry() -> @mesh.Mesh3dGeometry {
  let base = @mesh.Mesh3dGeometry::cuboid(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
  let blend_colors : Array[@math.Vec3] = []
  let vertex_colors : Array[@math.Vec4] = []
  for position in base.positions {
    let blend = @math.Vec3::new(
      position.x + 0.5F,
      position.y + 0.5F,
      position.z + 0.5F,
    )
    blend_colors.push(blend)
    vertex_colors.push(@math.Vec4::new(blend.x, blend.y, blend.z, 1.0F))
  }
  base
  .with_colors(Some(vertex_colors))
  .with_custom_attribute_vec3(ATTRIBUTE_BLEND_COLOR, blend_colors)
}

///|
fn setup(
  commands : @app.Commands,
  mesh_assets : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  material_assets : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let plane_mesh = mesh_assets
    .peek()
    .add(@pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)))
  let cube_mesh = mesh_assets
    .peek()
    .add(@pbr.Mesh::from_3d_geometry(custom_attribute_cube_geometry()))

  let plane_material = material_assets
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.18F, 0.2F, 0.24F)),
    )
  let cube_material = material_assets
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_reflectance(
        0.31F,
      ),
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
        @pbr.Mesh3d::new(cube_mesh),
        @pbr.MeshMaterial3d::new(cube_material).with_extension_shader_path(
          Some(SHADER_ASSET_PATH),
        ),
        Rotates::{  },
        @transform.Transform::from_xyz(0.0F, 0.8F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::new(@sprite.Color::white(), 1_000_000.0F, 20.0F, false),
        @transform.Transform::from_xyz(4.0F, 5.0F, 4.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotate_cube(
  time : @app.Res[@time.Time[Unit]],
  cube_query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Rotates]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! cube_query.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotation = value.rotation
        .mul(@math.Quat::from_rotation_y(delta * 0.9F))
        .normalize()
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_cube)))
  .run()
}
