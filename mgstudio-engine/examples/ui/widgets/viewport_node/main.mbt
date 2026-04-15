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
struct ViewportMesh {}

///|
let viewport_mesh_key : @ecs.ComponentKey[ViewportMesh] = @ecs.register_component(
  debug_name="examples.ui.widgets.viewport_node.ViewportMesh",
)

///|
pub impl @ecs.Component for ViewportMesh with component() {
  viewport_mesh_key
}

///|
fn setup(
  commands : @app.Commands,
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let target = images.get_ref().val.add(
    @asset.Image::new_target_texture(
      512,
      512,
      @asset.TextureFormat::Rgba8Unorm,
      Some(@asset.TextureFormat::Rgba8UnormSrgb),
    ),
  )

  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @sprite.Camera::default().with_order(-1),
      @sprite.RenderTarget::Image(target),
      @transform.Transform::from_xyz(0.0F, 2.5F, 5.5F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore

  let viewport_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.8F, 1.8F, 1.8F))
  let viewport_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.87F, 0.93F, 1.0F)),
  )
  commands.spawn(
    (
      ViewportMesh::{  },
      @pbr.Mesh3d::new(viewport_mesh),
      @pbr.MeshMaterial3d::new(viewport_material),
      @transform.Transform::identity(),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.PointLight::new(@sprite.Color::white(), 1_200_000.0F, 25.0F, false),
      @transform.Transform::from_xyz(0.0F, 5.0F, 5.0F),
    ),
  )
  |> ignore

  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F))
      .with_align_items(@ui.AlignItems::Center)
      .with_justify_content(@ui.JustifyContent::Center),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.1F, 0.1F, 0.12F)),
    ),
  )
  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_width(@ui.Val::Px(260.0F))
      .with_height(@ui.Val::Px(260.0F))
      .with_border(@ui.UiRect::all(@ui.Val::Px(4.0F)))
      .with_padding(@ui.UiRect::all(@ui.Val::Px(8.0F))),
      @ui.BorderColor::new(@sprite.Color::srgb(0.9F, 0.9F, 0.95F)),
      @ui.ImageNode::new(target),
    ),
  )
  |> ignore
}

///|
fn rotate_mesh(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[ViewportMesh]],
) -> Unit {
  let delta = time.get().delta_seconds()
  try! query.view(fn(_entity, transform) {
    transform.get_ref().val.rotate_y(delta * 1.1F)
    transform.get_ref().val.rotate_z(delta * 0.4F)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(rotate_mesh)))
  .run()
}
