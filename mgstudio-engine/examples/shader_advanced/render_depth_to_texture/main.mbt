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
const SHADER_PATH : String = "shaders/custom/render_depth_to_texture_3d.wgsl"

///|
struct OffscreenObject {}

///|
let offscreen_object_key : @ecs.ComponentKey[OffscreenObject] = @ecs.register_component(
  debug_name="examples.shader_advanced.render_depth_to_texture.OffscreenObject",
)

///|
pub impl @ecs.Component for OffscreenObject with component() {
  offscreen_object_key
}

///|
fn setup(
  commands : @app.Commands,
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let offscreen_layer = @sprite.RenderLayers::layer(1)
  let render_target = images.get_ref().val.add(
    @asset.Image::new_target_texture(
      768,
      768,
      @asset.TextureFormat::Rgba8Unorm,
      Some(@asset.TextureFormat::Rgba8UnormSrgb),
    ),
  )

  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @sprite.Camera::default().with_order(-1),
      @sprite.RenderTarget::Image(render_target),
      @transform.Transform::from_xyz(0.0F, 2.0F, 6.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      offscreen_layer,
    ),
  )
  |> ignore

  let offscreen_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Sphere::new(1.1F))
  let offscreen_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.85F, 0.92F, 1.0F)),
  )
  commands.spawn(
    (
      OffscreenObject::{  },
      @pbr.Mesh3d::new(offscreen_mesh),
      @pbr.MeshMaterial3d::new(offscreen_material),
      @transform.Transform::identity(),
      offscreen_layer,
    ),
  )
  |> ignore

  let preview_mesh = meshes.get_ref().val.add(
    @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(5.0F, 5.0F)),
  )
  let preview_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_base_color_texture(
      Some(render_target),
    ),
  )
  commands.spawn(
    (
      @pbr.Mesh3d::new(preview_mesh),
      @pbr.MeshMaterial3d::new(preview_material).with_extension_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::from_xyz(0.0F, 1.5F, 0.0F),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_500_000.0F, 40.0F, false),
      @transform.Transform::from_xyz(0.0F, 8.0F, 6.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(0.0F, 3.0F, 10.0F).looking_at(
        @math.Vec3::new(0.0F, 1.5F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
}

///|
fn spin_offscreen_object(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[OffscreenObject]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.get_ref().val.rotate_y(delta * 0.8F)
    transform.get_ref().val.rotate_z(delta * 0.5F)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(spin_offscreen_object)),
  )
  .run()
}
