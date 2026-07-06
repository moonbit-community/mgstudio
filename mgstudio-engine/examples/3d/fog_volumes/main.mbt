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
/// Demonstrates fog volumes with voxel density textures.

///|
const FOG_VOLUME_DENSITY_TEXTURE : String = "volumes/bunny.ktx2"

///|
fn fog_center() -> @math.Vec3 {
  @math.Vec3::new(0.0F, 0.5F, 0.0F)
}

///|
fn configured_window() -> @window.Window {
  let window = @window.Window::Window()
  window.title = "Mgstudio Fog Volumes Example"
  window
}

///|
fn spawn_fog_volume(
  commands : @app.Commands,
  asset_server : @asset.AssetServer,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
        @pbr.FogVolume::FogVolume()
        .with_density_texture(
          Some(asset_server.load(FOG_VOLUME_DENSITY_TEXTURE)),
        )
        .with_density_factor(1.0F)
        .with_scattering(1.0F),
      ),
    ),
  )
}

///|
fn spawn_directional_light(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @transform.Transform::from_xyz(1.0F, 1.0F, -0.3F).looking_at(
          fog_center(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.DirectionalLight::DirectionalLight()
        .with_shadow_maps_enabled(true)
        .with_illuminance(32_000.0F),
        @pbr.VolumetricLight::VolumetricLight(),
      ),
    ),
  )
}

///|
fn spawn_camera(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @camera.Camera3d::Camera3d(),
        @transform.Transform::from_xyz(-0.75F, 1.0F, 2.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
        @pbr.Hdr::Hdr(),
        @pbr.VolumetricFog::VolumetricFog()
        .with_step_count(64)
        .with_ambient_intensity(0.0F),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  spawn_fog_volume(commands, asset_server.get())
  spawn_directional_light(commands)
  spawn_camera(commands)
}

///|
fn setup_global_ambient_light(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::none(),
  )
}

///|
fn rotate_camera(
  cameras : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ],
) -> Unit {
  try! cameras.view(fn(_entity, camera_transform) {
    let transform = camera_transform.value()
    let translation = @math.Quat::from_rotation_y(0.01F).mul_vec3(
      transform.translation,
    )
    camera_transform.set(
      @transform.Transform::from_xyz(
        translation.x,
        translation.y,
        translation.z,
      ).looking_at(fog_center(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
    )
  })
}

///|
fn fog_volumes_app() -> @app.App[@ecs.World] {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: None,
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_systems_world(@app.Startup, setup_global_ambient_light)
  .add_systems_param2(@app.Startup, setup)
  .add_systems_param(@app.Update, rotate_camera)
}

///|
fn main {
  fog_volumes_app().run()
}

///|
test "fog_volumes: scene matches upstream volumetric fog volume shape" {
  let mut app = fog_volumes_app()
  app = app.run_startup()
  let world = app.world()
  debug_inspect(world.component_count(@pbr.ecs_key_fog_volume), content="1")
  debug_inspect(
    world.component_count(@pbr.ecs_key_volumetric_light),
    content="1",
  )
  debug_inspect(world.component_count(@pbr.ecs_key_volumetric_fog), content="1")
  debug_inspect(world.component_count(@pbr.ecs_key_hdr), content="1")

  let fog_volume_query : @ecs.Query[
    (@ecs.Read[@pbr.FogVolume], @ecs.Read[@transform.Transform]),
    @ecs.With[@pbr.FogVolume],
  ] = @ecs.query_filtered(world, @ecs.With::new(@pbr.ecs_key_fog_volume))
  let fog_volume_has_density_texture = Ref(false)
  let fog_volume_density_factor = Ref(0.0F)
  let fog_volume_scattering = Ref(0.0F)
  let fog_volume_translation = Ref(@math.Vec3::zero())
  try! fog_volume_query.view(fn(_entity, data) {
    let (fog_volume, transform) = data
    fog_volume_has_density_texture.val = fog_volume.value().density_texture
      is Some(_)
    fog_volume_density_factor.val = fog_volume.value().density_factor
    fog_volume_scattering.val = fog_volume.value().scattering
    fog_volume_translation.val = transform.value().translation
  })
  debug_inspect(fog_volume_has_density_texture.val, content="true")
  debug_inspect(fog_volume_density_factor.val, content="1")
  debug_inspect(fog_volume_scattering.val, content="1")
  debug_inspect(fog_volume_translation.val.x, content="0")
  debug_inspect(fog_volume_translation.val.y, content="0.5")
  debug_inspect(fog_volume_translation.val.z, content="0")
}
