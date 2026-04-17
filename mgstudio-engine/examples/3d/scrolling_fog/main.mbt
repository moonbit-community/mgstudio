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
///
/// Parity note:
/// - `FogVolume` / `VolumetricLight` follow the Bevy-shaped component API in mgstudio.
///   The example keeps Bevy-equivalent scene/setup structure and update flow.

///|
const FOG_DENSITY_TEXTURE_SCROLL_SPEED : Float = 0.04F

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_directional_light_shadow_map,
    @pbr.DirectionalLightShadowMap::new(4096),
  )

  let camera = @camera.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(0.0F, 2.0F, 0.0F).looking_at(
        @math.Vec3::new(-5.0F, 3.5F, -6.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
    .with_camera3d(
      @camera.Camera3d::default().with_volumetric_fog(
        Some(
          @pbr.VolumetricFog::default()
          .with_ambient_intensity(0.0F)
          .with_jitter(0.5F),
        ),
      ),
    )
    .spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_anti_aliasing,
    @post_process.TemporalAntiAliasing::default(),
  )
  try! world.set_by_key(camera, @pbr.ecs_key_msaa, @pbr.Msaa::Off)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_temporal_anti_aliasing,
    @post_process.TemporalAntiAliasing::default(),
  )
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_bloom,
    @post_process.Bloom::default(),
  )

  let directional_light = world.spawn_empty()
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 10000.0F, true),
  )
  try! world.set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-5.0F, 5.0F, -7.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_volumetric_light,
    @pbr.VolumetricLight::default(),
  )

  let black_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::black()).with_perceptual_roughness(
      1.0F,
    ),
  )
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(64.0F, 1.0F, 64.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(black_material),
    @transform.Transform::from_xyz(0.0F, -0.5F, 0.0F),
  ).spawn(world)
  |> ignore
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(2.0F, 9.0F, 2.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(black_material),
    @transform.Transform::from_xyz(-10.0F, 4.5F, -11.0F),
  ).spawn(world)
  |> ignore

  let asset_server = @asset.AssetServer::new()
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
  let fog_volume = world.spawn_empty()
  try! world.set_by_key(
    fog_volume,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 32.0F, 0.0F).with_scale(
      @math.Vec3::splat(64.0F),
    ),
  )
  try! world.set_by_key(
    fog_volume,
    @pbr.ecs_key_fog_volume,
    @pbr.FogVolume::default()
    .with_density_texture(Some(noise_texture))
    .with_density_factor(0.05F),
  )
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in scrolling_fog example")
  }
}

///|
fn scroll_fog(world : @ecs.World) -> Unit {
  let offset_delta = @math.Vec3::new(
    0.0F,
    0.0F,
    FOG_DENSITY_TEXTURE_SCROLL_SPEED,
  ).mul_scalar(world_time(world).delta_seconds())
  world.for_each_component(@pbr.ecs_key_fog_volume, fn(entity, fog_volume) {
    try! (world.replace(
      entity,
      @pbr.ecs_key_fog_volume,
      fog_volume.with_density_texture_offset(
        fog_volume.density_texture_offset.add(offset_delta),
      ),
    )
    |> ignore)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(scroll_fog))
  .run()
}
