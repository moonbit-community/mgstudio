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
/// Port of `bevy/examples/3d/render_to_texture.rs`.

///|
const PI : Float = 3.141592653589793F

///|
struct FirstPassCube {}

///|
let first_pass_cube_key : @ecs.ComponentKey[FirstPassCube] = @ecs.register_component(
  debug_name="examples.3d.render_to_texture.FirstPassCube",
)

///|
pub impl @ecs.Component for FirstPassCube with component() {
  first_pass_cube_key
}

///|
struct MainPassCube {}

///|
let main_pass_cube_key : @ecs.ComponentKey[MainPassCube] = @ecs.register_component(
  debug_name="examples.3d.render_to_texture.MainPassCube",
)

///|
pub impl @ecs.Component for MainPassCube with component() {
  main_pass_cube_key
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  images : @app.ResMut[@asset.Assets[@asset.Image]],
) -> Unit {
  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val
  let image = images.get_ref().val.add(
    @asset.Image::new_target_texture(
      512,
      512,
      @asset.TextureFormat::Rgba8Unorm,
      Some(@asset.TextureFormat::Rgba8UnormSrgb),
    ),
  )
  let first_pass_layer = @sprite.RenderLayers::layer(1)
  let cube_handle = mesh_assets
    |> @pbr.add_mesh(@math.Cuboid::new(4.0F, 4.0F, 4.0F))
  let first_pass_material = material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(
        @sprite.Color::new(0.8F, 0.7F, 0.6F, 1.0F),
      ).with_reflectance(0.02F),
    )
  let main_pass_material = material_assets
    |> @pbr.add_material(
      @pbr.StandardMaterial::from_color(@sprite.Color::white())
      .with_base_color_texture(Some(image))
      .with_reflectance(0.02F),
    )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_handle),
        @pbr.MeshMaterial3d::new(first_pass_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 1.0F),
        FirstPassCube::{  },
        first_pass_layer,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::default(),
        @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F),
        @sprite.RenderLayers::layer(0).with_layer(1),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @sprite.Camera::new(@sprite.Color::white()).with_order(-1),
        @sprite.RenderTarget::Image(image),
        @transform.Transform::from_xyz(0.0F, 0.0F, 15.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        first_pass_layer,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(cube_handle),
        @pbr.MeshMaterial3d::new(main_pass_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 1.5F).with_rotation(
          @math.Quat::from_rotation_x(-PI / 5.0F),
        ),
        MainPassCube::{  },
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 0.0F, 15.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn rotator_system(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query1Filtered[@transform.Transform, @ecs.With[FirstPassCube]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.rotation = transform.rotation
      .mul(@math.Quat::from_rotation_x(1.5F * delta))
      .mul(@math.Quat::from_rotation_z(1.3F * delta))
      .normalize()
  })
}

///|
fn cube_rotator_system(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query1Filtered[@transform.Transform, @ecs.With[MainPassCube]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.rotation = transform.rotation
      .mul(@math.Quat::from_rotation_x(1.0F * delta))
      .mul(@math.Quat::from_rotation_y(0.7F * delta))
      .normalize()
  })
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(cube_rotator_system)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param2(rotator_system)))
  .run()
}
