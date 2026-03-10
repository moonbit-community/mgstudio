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
/// Port of `bevy/examples/asset/repeated_texture.rs`.

///|
fn setup(
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@render3d.StandardMaterial]],
) -> Unit {
  let world = @app.current_world().unwrap()
  let tick = world.read_change_tick()
  let image_with_default_sampler = asset_server
    .get()
    .load("textures/fantasy_ui_borders/panel-border-010.png")
  let image_with_repeat_sampler = asset_server
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
    )

  let uv_transform = @transform.Affine2::from_scale(@math.Vec2::new(2.0F, 3.0F))
  let center_material = materials.get_ref().val.add(
    @render3d.StandardMaterial::default().with_base_color_texture(
      Some(image_with_default_sampler),
    ),
  )
  let left_material = materials.get_ref().val.add(
    @render3d.StandardMaterial::default()
    .with_base_color_texture(Some(image_with_repeat_sampler))
    .with_uv_transform(uv_transform),
  )
  let right_material = materials.get_ref().val.add(
    @render3d.StandardMaterial::default()
    .with_base_color_texture(Some(image_with_default_sampler))
    .with_uv_transform(uv_transform),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(center_material),
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(left_material),
    @math.Transform::from_xyz(-1.5F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(right_material),
    @math.Transform::from_xyz(1.5F, 0.0F, 0.0F),
  ).spawn(world)
  |> ignore

  let light = world.spawn_empty()
  world
  .component(@render3d.PointLight::component())
  .insert(
    light,
    @render3d.PointLight::default().with_shadow_maps_enabled(true),
    tick,
  )
  world
  .component(@math.Transform::component())
  .insert(light, @math.Transform::from_xyz(4.0F, 8.0F, 4.0F), tick)

  @render3d.Camera3dBundle::new(
    @sprite.Camera::default(),
    @math.Transform::from_xyz(0.0F, 1.5F, 4.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn main {
  let plugins = @mgstudio.DefaultPlugins::build().build()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
