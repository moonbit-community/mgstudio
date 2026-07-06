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
const SHADER_PATH : String = "shaders/show_depth_texture_material.wgsl"

///|
struct OffscreenObject {}

///|
let offscreen_object_key : @ecs.ComponentKey[OffscreenObject] = @ecs.register_component(
  debug_name="examples.shader_advanced.render_depth_to_texture.OffscreenObject",
)

///|
pub impl @ecs.Component for OffscreenObject with fn component() {
  offscreen_object_key
}

///|
fn setup(
  commands : @app.Commands,
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let offscreen_layer = @camera_render_layers.RenderLayers::layer(1)
  let render_target = images
    .peek()
    .add(
      @asset.Image::new_target_texture(
        768,
        768,
        @asset.TextureFormat::Rgba8Unorm,
        Some(@asset.TextureFormat::Rgba8UnormSrgb),
      ),
    )

  commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
      @camera_camera.Camera::Camera().with_order(-1),
      @camera_camera.RenderTarget::Image(render_target),
      @transform.Transform::from_xyz(0.0F, 2.0F, 6.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
      offscreen_layer,
    ),
  )
  |> ignore

  let offscreen_mesh = meshes.modify(fn(meshes) {
    meshes |> @pbr.add_mesh(@math.Sphere::new(1.1F))
  })
  let offscreen_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::srgb(0.85F, 0.92F, 1.0F)),
    )
  commands.spawn(
    (
      OffscreenObject::{  },
      @mesh.Mesh3d::new(offscreen_mesh),
      @pbr.MeshMaterial3dTyped::new(offscreen_material),
      @transform.Transform::identity(),
      offscreen_layer,
    ),
  )
  |> ignore

  let preview_mesh = meshes.peek()
    |> @pbr.add_mesh(
      @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
        @math.Vec2::new(5.0F, 5.0F),
      ).build(),
    )
  let preview_material = materials
    .peek()
    .add(
      @pbr.StandardMaterial::from_color(@color.Color::white()).with_base_color_texture(
        Some(render_target),
      ),
    )
  commands.spawn(
    (
      @mesh.Mesh3d::new(preview_mesh),
      @pbr.MeshMaterial3d::new(preview_material).with_extension_fragment_shader_path(
        Some(SHADER_PATH),
      ),
      @transform.Transform::from_xyz(0.0F, 1.5F, 0.0F),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.PointLight::new(@color.Color::white(), 1_500_000.0F, 40.0F, false),
      @transform.Transform::from_xyz(0.0F, 8.0F, 6.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @camera.Camera3d::Camera3d(),
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
  query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[OffscreenObject],
  ],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotate_y(delta * 0.8F)
      value.rotate_z(delta * 0.5F)
    })
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param4(@app.Startup, setup)
  .add_systems_param2(@app.Update, spin_offscreen_object)
  .run()
}
