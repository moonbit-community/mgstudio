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
const FOG_DENSITY_TEXTURE_SCROLL_SPEED : Float = 0.04F

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Scrolling Fog"
  window
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  let camera = commands.spawn(
    @camera.Camera3dBundle::new(
      @camera_camera.Camera::Camera(),
      @transform.Transform::from_xyz(0.0F, 2.0F, 0.0F).looking_at(
        @math.Vec3::new(-5.0F, 3.5F, -6.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).with_volumetric_fog(
      Some(
        @pbr.VolumetricFog::VolumetricFog()
        .with_ambient_intensity(0.0F)
        .with_jitter(0.5F),
      ),
    ),
  )
  commands.entity(camera).insert_component(@pbr.Msaa::Off)
  commands
  .entity(camera)
  .insert_component(@post_process.TemporalAntiAliasing::TemporalAntiAliasing())
  commands.entity(camera).insert_component(@post_process.Bloom::Bloom())
}

///|
fn spawn_directional_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @pbr.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
        @transform.Transform::from_xyz(-5.0F, 5.0F, -7.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.VolumetricLight::VolumetricLight(),
      ),
    ),
  )
}

///|
fn spawn_scene_geometry(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let ground_mesh = meshes.modify(fn(mesh_assets) {
    mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(64.0F, 1.0F, 64.0F))
  })
  let pillar_mesh = meshes.modify(fn(mesh_assets) {
    mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(2.0F, 9.0F, 2.0F))
  })
  let ground_material = materials.modify(fn(material_assets) {
    material_assets.add(
      @pbr.StandardMaterial::from_color(@color.Color::black()).with_perceptual_roughness(
        1.0F,
      ),
    )
  })
  let pillar_material = materials.modify(fn(material_assets) {
    material_assets.add(
      @pbr.StandardMaterial::from_color(@color.Color::black()),
    )
  })

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(ground_mesh),
        @pbr.MeshMaterial3d::new(ground_material),
        @transform.Transform::from_xyz(0.0F, -0.5F, 0.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(pillar_mesh),
        @pbr.MeshMaterial3d::new(pillar_material),
        @transform.Transform::from_xyz(-10.0F, 4.5F, -11.0F),
      ),
    ),
  )
}

///|
fn spawn_fog_volume(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  let noise_texture = asset_server.load_with_settings(
    "volumes/fog_noise.ktx2",
    fn(settings) {
      settings.sampler = @asset.ImageSampler::Descriptor(
        @asset.ImageSamplerDescriptor::linear().set_address_mode(
          @asset.ImageAddressMode::Repeat,
        ),
      )
    },
  )
  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(0.0F, 32.0F, 0.0F).with_scale(
          @math.Vec3::splat(64.0F),
        ),
        @pbr.FogVolume::FogVolume()
        .with_density_texture(Some(noise_texture))
        .with_density_factor(0.05F),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  commands.insert_world_resource(
    @pbr.ecs_key_directional_light_shadow_map,
    @pbr.DirectionalLightShadowMap::new(4096),
  )
  spawn_camera(commands)
  spawn_directional_light(commands)
  spawn_scene_geometry(commands, meshes, materials)
  spawn_fog_volume(commands, asset_server.get())
}

///|
fn scroll_fog(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Write[@pbr.FogVolume], @ecs.All],
) -> Unit {
  let offset_delta = @math.Vec3::new(
    0.0F,
    0.0F,
    FOG_DENSITY_TEXTURE_SCROLL_SPEED,
  ).mul_scalar(time.get().delta_seconds())
  try! query.for_each(fn(_entity, fog_volume) {
    let current = fog_volume.value()
    fog_volume.set(
      current.with_density_texture_offset(
        current.density_texture_offset.add(offset_delta),
      ),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_systems_param4(@app.Startup, setup)
  .add_systems_param2(@app.Update, scroll_fog)
  .run()
}
