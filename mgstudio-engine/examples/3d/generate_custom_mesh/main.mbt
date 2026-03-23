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
/// Port of `bevy/examples/3d/generate_custom_mesh.rs`.

///|
struct CustomUV {}

///|
let custom_uv_key : @ecs.ComponentKey[CustomUV] = @ecs.register_component(
  debug_name="examples.3d.generate_custom_mesh.CustomUV",
)

///|
pub impl @ecs.Component for CustomUV with component() {
  custom_uv_key
}

///|
fn create_cube_positions() -> Array[@math.Vec3] {
  [
    // Top (+y)
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    // Bottom (-y)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    // Right (+x)
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    // Left (-x)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    // Back (+z)
    @math.Vec3::new(-0.5F, -0.5F, 0.5F),
    @math.Vec3::new(-0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, 0.5F, 0.5F),
    @math.Vec3::new(0.5F, -0.5F, 0.5F),
    // Forward (-z)
    @math.Vec3::new(-0.5F, -0.5F, -0.5F),
    @math.Vec3::new(-0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, 0.5F, -0.5F),
    @math.Vec3::new(0.5F, -0.5F, -0.5F),
  ]
}

///|
fn create_cube_uvs(upper_uv : Bool) -> Array[@math.Vec2] {
  let y_offset = if upper_uv { 0.0F } else { 0.5F }
  [
    // Top (+y)
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(0.0F, 0.0F + y_offset),
    @math.Vec2::new(1.0F, 0.0F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    // Bottom (-y)
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.25F + y_offset),
    @math.Vec2::new(1.0F, 0.25F + y_offset),
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    // Right (+x)
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    // Left (-x)
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    // Back (+z)
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.45F + y_offset),
    // Forward (-z)
    @math.Vec2::new(0.0F, 0.45F + y_offset),
    @math.Vec2::new(0.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.2F + y_offset),
    @math.Vec2::new(1.0F, 0.45F + y_offset),
  ]
}

///|
fn create_cube_indices() -> Array[Int] {
  [
    0, 3, 1, 1, 3, 2, 4, 5, 7, 5, 6, 7, 8, 11, 9, 9, 11, 10, 12, 13, 15, 13, 14,
    15, 16, 19, 17, 17, 19, 18, 20, 21, 23, 21, 22, 23,
  ]
}

///|
fn create_cube_mesh(upper_uv : Bool) -> @mesh.Mesh {
  @mesh.Mesh::from_3d_geometry(
    @mesh.Mesh3dGeometry::new(
      create_cube_positions(),
      create_cube_uvs(upper_uv),
      Some(create_cube_indices()),
    ),
  )
}

///|
fn toggle_texture(mesh : @mesh.Mesh) -> @mesh.Mesh {
  guard mesh.as_3d_geometry() is Some(geometry) else { return mesh }
  let next_uvs : Array[@math.Vec2] = []
  for uv in geometry.uvs {
    let next_y = if uv.y + 0.5F < 1.0F { uv.y + 0.5F } else { uv.y - 0.5F }
    next_uvs.push(@math.Vec2::new(uv.x, next_y))
  }
  guard geometry.replace_uvs(next_uvs) else { return mesh }
  geometry.clear_tangents()
  @mesh.Mesh::from_3d_geometry(geometry)
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  let custom_texture = asset_server.get().load("textures/array_texture.png")
  let material = materials.get_ref().val
    |> @pbr.add_material(
      @pbr.StandardMaterial::default().with_base_color_texture(
        Some(custom_texture),
      ),
    )
  let cube_mesh_handle = meshes.get_ref().val.add(create_cube_mesh(true))

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_mesh_handle),
        @pbr.MeshMaterial3d::new(material),
        CustomUV::{  },
      ),
    ),
  )

  let camera_and_light_transform = @transform.Transform::from_xyz(
    1.8F, 1.8F, 1.8F,
  ).looking_at(
    @math.Vec3::new(0.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )

  ignore(commands.spawn((@pbr.Camera3d::default(), camera_and_light_transform)))
  ignore(
    commands.spawn((@pbr.PointLight::default(), camera_and_light_transform)),
  )
  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Controls:\nSpace: Change UVs\nX/Y/Z: Rotate\nR: Reset orientation",
        ),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          top: @ui.Val::Px(12.0F),
          left: @ui.Val::Px(12.0F),
        },
      ),
    ),
  )
}

///|
fn input_handler(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  mesh_query : @ecs.Query1Filtered[@pbr.Mesh3d, @ecs.With[CustomUV]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  query : @ecs.Query1Filtered[@transform.Transform, @ecs.With[CustomUV]],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let mesh_assets = meshes.get_ref().val
  if keyboard_input.just_pressed(@window.KeyCode::Space) {
    guard (try! mesh_query.single()) is Some(mesh_handle) else { return }
    if mesh_assets.get(mesh_handle.mesh) is Some(mesh) {
      mesh_assets.set(mesh_handle.mesh, toggle_texture(mesh)) |> ignore
    }
  }
  if keyboard_input.pressed(@window.KeyCode::KeyX) {
    try! query.view(fn(_entity, transform) {
      transform.rotation = transform.rotation
        .mul(@math.Quat::from_rotation_x(time.get().delta_seconds() / 1.2F))
        .normalize()
    })
  }
  if keyboard_input.pressed(@window.KeyCode::KeyY) {
    try! query.view(fn(_entity, transform) {
      transform.rotation = transform.rotation
        .mul(@math.Quat::from_rotation_y(time.get().delta_seconds() / 1.2F))
        .normalize()
    })
  }
  if keyboard_input.pressed(@window.KeyCode::KeyZ) {
    try! query.view(fn(_entity, transform) {
      transform.rotation = transform.rotation
        .mul(@math.Quat::from_rotation_z(time.get().delta_seconds() / 1.2F))
        .normalize()
    })
  }
  if keyboard_input.pressed(@window.KeyCode::KeyR) {
    try! query.view(fn(_entity, transform) {
      transform.rotation = @math.Quat::identity()
    })
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param5(input_handler)))
  .run()
}
