// Copyright 2025 International Digital Economy Academy
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
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@pbr.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let image_with_default_sampler = asset_server
    .get()
    .load("textures/fantasy_ui_borders/panel-border-010.png")

  let center_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
  let left_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))
  let right_mesh = meshes.get_ref().val
    |> @pbr.add_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F))

  let center_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::default().with_base_color_texture(
      Some(image_with_default_sampler),
    ),
  )
  let left_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::default()
    .with_base_color_texture(
      Some(
        asset_server
        .get()
        .load_with_settings(
          "textures/fantasy_ui_borders/panel-border-010-repeated.png",
          fn(settings) {
            settings.sampler = @asset.ImageSampler::Descriptor(
              @asset.ImageSamplerDescriptor::default().set_address_mode(
                @asset.ImageAddressMode::Repeat,
              ),
            )
          },
        ),
      ),
    )
    .with_uv_transform(
      @transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)),
    ),
  )
  let right_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::default()
    .with_base_color_texture(Some(image_with_default_sampler))
    .with_uv_transform(
      @transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)),
    ),
  )

  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(center_mesh),
        @pbr.MeshMaterial3d::new(center_material),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(left_mesh),
        @pbr.MeshMaterial3d::new(left_material),
        @transform.Transform::from_xyz(-1.5F, 0.0F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @pbr.Mesh3d::new(right_mesh),
        @pbr.MeshMaterial3d::new(right_material),
        @transform.Transform::from_xyz(1.5F, 0.0F, 0.0F),
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
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 1.5F, 4.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .run()
}
