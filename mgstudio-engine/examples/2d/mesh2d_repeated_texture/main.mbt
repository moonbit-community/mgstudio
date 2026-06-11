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
const RECTANGLE_OFFSET : Float = 250.0F

///|
const RECTANGLE_SIDE : Float = 200.0F

///|
const LABEL_OFFSET : Float = 125.0F

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[
    @asset.Assets[@sprite_render_mesh2d_color_material.ColorMaterial],
  ],
) -> Unit {
  let image_with_default_sampler = asset_server
    .get()
    .load("textures/fantasy_ui_borders/panel-border-010.png")
  let image_with_repeated_sampler = asset_server
    .get()
    .load_with_settings(
      "textures/fantasy_ui_borders/panel-border-010-repeated.png",
      fn(settings) {
        let descriptor = @asset.ImageSamplerDescriptor::ImageSamplerDescriptor()
        descriptor.address_mode_u = @asset.ImageAddressMode::Repeat
        descriptor.address_mode_v = @asset.ImageAddressMode::Repeat
        settings.sampler = @asset.ImageSampler::Descriptor(descriptor)
      },
    )

  let center_panel = commands.spawn(
    (
      @mesh.Mesh2d::new(
        @mesh_primitives.add_mesh(
          meshes.peek(),
          @math.Rectangle::new(RECTANGLE_SIDE, RECTANGLE_SIDE),
        ),
      ),
      @sprite_render_mesh2d_material.MeshMaterial2d::new(
        materials
        .peek()
        .add(
          @sprite_render_mesh2d_color_material.ColorMaterial::from_image(
            image_with_default_sampler,
          ),
        ),
      ),
      @transform.Transform::from_translation(@math.Vec3::zero()),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(center_panel),
        @text.Text2d::new("Control"),
        @transform.Transform::from_xyz(0.0F, LABEL_OFFSET, 0.0F),
      ),
    ),
  )

  let left_panel = commands.spawn(
    (
      @mesh.Mesh2d::new(
        @mesh_primitives.add_mesh(
          meshes.peek(),
          @math.Rectangle::new(RECTANGLE_SIDE, RECTANGLE_SIDE),
        ),
      ),
      @sprite_render_mesh2d_material.MeshMaterial2d::new(
        materials
        .peek()
        .add(
          @sprite_render_mesh2d_color_material.ColorMaterial::from_image(
            image_with_repeated_sampler,
          ).with_uv_transform(
            @transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)),
          ),
        ),
      ),
      @transform.Transform::from_xyz(-RECTANGLE_OFFSET, 0.0F, 0.0F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(left_panel),
        @text.Text2d::new("Repeat On"),
        @transform.Transform::from_xyz(0.0F, LABEL_OFFSET, 0.0F),
      ),
    ),
  )

  let right_panel = commands.spawn(
    (
      @mesh.Mesh2d::new(
        @mesh_primitives.add_mesh(
          meshes.peek(),
          @math.Rectangle::new(RECTANGLE_SIDE, RECTANGLE_SIDE),
        ),
      ),
      @sprite_render_mesh2d_material.MeshMaterial2d::new(
        materials
        .peek()
        .add(
          @sprite_render_mesh2d_color_material.ColorMaterial::from_image(
            image_with_default_sampler,
          ).with_uv_transform(
            @transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F)),
          ),
        ),
      ),
      @transform.Transform::from_xyz(RECTANGLE_OFFSET, 0.0F, 0.0F),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(right_panel),
        @text.Text2d::new("Repeat Off"),
        @transform.Transform::from_xyz(0.0F, LABEL_OFFSET, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera_components2d.Camera2d::Camera2d(),
        @transform.Transform::identity().looking_at(
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
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param4(@app.Startup, setup)
  .run()
}
