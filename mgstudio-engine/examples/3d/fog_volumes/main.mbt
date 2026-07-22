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
    let translation = @math.Quat::from_rotation_y(0.01F).mul_vec3(
      camera_transform.value().translation,
    )
    camera_transform.set(
      @transform.Transform::from_translation(translation).looking_at(
        fog_center(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
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
      exit_condition: OnAllClosed,
      close_when_requested: true,
    }),
  )
  .add_systems_world(Startup, setup_global_ambient_light)
  .add_systems_param2(Startup, setup)
  .add_systems_param(Update, rotate_camera)
}

///|
fn main {
  fog_volumes_app().run()
}

///|
fn fog_volumes_approx_eq(lhs : Float, rhs : Float) -> Bool {
  (lhs - rhs).abs() <= 1.0e-5F
}

///|
fn fog_volumes_vec3_approx_eq(lhs : @math.Vec3, rhs : @math.Vec3) -> Bool {
  fog_volumes_approx_eq(lhs.x, rhs.x) &&
  fog_volumes_approx_eq(lhs.y, rhs.y) &&
  fog_volumes_approx_eq(lhs.z, rhs.z)
}

///|
fn fog_volumes_uniform_u32_at(bytes : Bytes, byte_offset : Int) -> UInt {
  (bytes[byte_offset].to_uint() & 0xFFU) |
  ((bytes[byte_offset + 1].to_uint() & 0xFFU) << 8) |
  ((bytes[byte_offset + 2].to_uint() & 0xFFU) << 16) |
  ((bytes[byte_offset + 3].to_uint() & 0xFFU) << 24)
}

///|
fn fog_volumes_uniform_f32_bits_at(bytes : Bytes, byte_offset : Int) -> UInt {
  fog_volumes_uniform_u32_at(bytes, byte_offset)
}

///|
fn fog_volumes_uniform_word_range_changed(
  lhs : Bytes,
  rhs : Bytes,
  byte_start : Int,
  byte_end : Int,
) -> Bool {
  let mut offset = byte_start
  while offset < byte_end {
    if fog_volumes_uniform_u32_at(lhs, offset) !=
      fog_volumes_uniform_u32_at(rhs, offset) {
      return true
    }
    offset = offset + 4
  }
  false
}

///|
fn fog_volumes_read_camera_translation(world : @ecs.World) -> @math.Vec3 {
  let translation = Ref(@math.Vec3::zero())
  let query : @ecs.Query[
    @ecs.Read[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ] = @ecs.query_filtered(world, @ecs.With::new(@camera.ecs_key_camera3d))
  try! query.view(fn(_entity, transform) {
    translation.val = transform.value().translation
  })
  translation.val
}

///|
fn fog_volumes_identity_volumetric_mat4() -> @pbr_volumetric_fog.VolumetricFogMat4 {
  @pbr_volumetric_fog.VolumetricFogMat4::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
  )
}

///|
fn fog_volumes_prepared_uniform_bytes_for_camera(
  fog_volume : @pbr.FogVolume,
  volumetric_fog : @pbr.VolumetricFog,
  fog_volume_translation : @math.Vec3,
  camera_transform : @transform.Transform,
) -> Bytes {
  let buffer = @pbr_volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
  ignore(
    @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
      buffer,
      volumetric_fog,
      @math.Affine3::from_scale_rotation_translation(
        camera_transform.scale,
        camera_transform.rotation,
        camera_transform.translation,
      ),
      fog_volumes_identity_volumetric_mat4(),
      [
        (
          fog_volume,
          @math.Affine3::from_translation(fog_volume_translation).inverse(),
        ),
      ],
    ),
  )
  buffer.bytes()
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
  let fog_volume_density_texture : Ref[@asset.Handle[@asset.Image]?] = Ref(None)
  let fog_volume_component : Ref[@pbr.FogVolume?] = Ref(None)
  try! fog_volume_query.view(fn(_entity, data) {
    let (fog_volume, transform) = data
    fog_volume_component.val = Some(fog_volume.value())
    fog_volume_has_density_texture.val = fog_volume.value().density_texture
      is Some(_)
    fog_volume_density_texture.val = fog_volume.value().density_texture
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
  let fog_volume_density_texture_resolves = match
    fog_volume_density_texture.val {
    Some(texture) =>
      @asset.asset_is_texture_loaded(texture) &&
      @asset.asset_texture_width(texture) == 64 &&
      @asset.asset_texture_height(texture) == 64
    None => false
  }
  debug_inspect(fog_volume_density_texture_resolves, content="true")

  let directional_light_query : @ecs.Query[
    (@ecs.Read[@pbr.DirectionalLight], @ecs.Read[@transform.Transform]),
    @ecs.With[@pbr.DirectionalLight],
  ] = @ecs.query_filtered(world, @ecs.With::new(@pbr.ecs_key_directional_light))
  let directional_light_matches = Ref(false)
  let directional_light_transform_matches = Ref(false)
  let directional_light_has_volumetric_marker = Ref(false)
  try! directional_light_query.view(fn(entity, data) {
    let (directional_light, transform) = data
    directional_light_matches.val = directional_light.value().shadow_maps_enabled &&
      fog_volumes_approx_eq(directional_light.value().illuminance, 32_000.0F)
    directional_light_transform_matches.val = fog_volumes_vec3_approx_eq(
      transform.value().translation,
      @math.Vec3::new(1.0F, 1.0F, -0.3F),
    )
    directional_light_has_volumetric_marker.val = (try! world.get_by_key(
        entity, @pbr.ecs_key_volumetric_light,
      ))
      is Some(_)
  })
  debug_inspect(directional_light_matches.val, content="true")
  debug_inspect(directional_light_transform_matches.val, content="true")
  debug_inspect(directional_light_has_volumetric_marker.val, content="true")

  let camera_query : @ecs.Query[
    (
      @ecs.Read[@camera.Camera3d],
      @ecs.Read[@transform.Transform],
      @ecs.Read[@pbr.Hdr],
      @ecs.Read[@pbr.VolumetricFog],
    ),
    @ecs.With[@camera.Camera3d],
  ] = @ecs.query_filtered(world, @ecs.With::new(@camera.ecs_key_camera3d))
  let camera_transform_matches = Ref(false)
  let volumetric_fog_matches = Ref(false)
  let camera_transform_component : Ref[@transform.Transform?] = Ref(None)
  let volumetric_fog_component : Ref[@pbr.VolumetricFog?] = Ref(None)
  try! camera_query.view(fn(_entity, data) {
    let (_, transform, _, volumetric_fog) = data
    camera_transform_component.val = Some(transform.value())
    volumetric_fog_component.val = Some(volumetric_fog.value())
    camera_transform_matches.val = fog_volumes_vec3_approx_eq(
      transform.value().translation,
      @math.Vec3::new(-0.75F, 1.0F, 2.0F),
    )
    volumetric_fog_matches.val = volumetric_fog.value().step_count == 64 &&
      fog_volumes_approx_eq(volumetric_fog.value().ambient_intensity, 0.0F) &&
      fog_volumes_approx_eq(volumetric_fog.value().jitter, 0.0F)
  })
  debug_inspect(camera_transform_matches.val, content="true")
  debug_inspect(volumetric_fog_matches.val, content="true")
  let prepared_fog_matches = match
    (fog_volume_component.val, volumetric_fog_component.val) {
    (Some(fog_volume), Some(volumetric_fog)) => {
      let buffer = @pbr_volumetric_fog.VolumetricFogUniformBuffer::VolumetricFogUniformBuffer()
      let view_fog = @pbr_volumetric_fog.prepare_volumetric_fog_view_uniforms(
        buffer,
        volumetric_fog,
        @math.Affine3::identity(),
        fog_volumes_identity_volumetric_mat4(),
        [
          (
            fog_volume,
            @math.Affine3::from_translation(fog_volume_translation.val).inverse(),
          ),
        ],
      )
      let uniform_bytes = buffer.bytes()
      let density_texture_id_matches = match fog_volume.density_texture {
        Some(texture) =>
          view_fog.volumes()[0].density_texture_id() == texture.id()
        None => false
      }
      buffer.count() == 1 &&
      view_fog.count() == 1 &&
      view_fog.volumes()[0].has_density_texture() &&
      density_texture_id_matches &&
      uniform_bytes.length() == 512 &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 112) ==
      0.5F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 116) ==
      0.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 120) ==
      0.5F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 124) ==
      1.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 208) ==
      1.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 212) ==
      1.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 216) ==
      1.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 220) ==
      0.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_u32_at(uniform_bytes, 224) == 64U &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 236) ==
      1.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 240) ==
      1.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 256) ==
      0.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 260) ==
      0.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 264) ==
      0.0F.reinterpret_as_uint() &&
      fog_volumes_uniform_f32_bits_at(uniform_bytes, 276) ==
      0.0F.reinterpret_as_uint()
    }
    _ => false
  }
  debug_inspect(prepared_fog_matches, content="true")
  app = app.update()
  let render_world = app.sub_app(RenderApp).world()
  let render_storage_counts = @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(
    render_world,
  )
  debug_inspect(render_storage_counts.view_count(), content="1")
  debug_inspect(render_storage_counts.volume_count(), content="1")
  debug_inspect(render_storage_counts.light_count(), content="1")
  debug_inspect(
    @pbr_render.render3d_collect_extracted_directional_lights(render_world).length(),
    content="1",
  )
  let extracted_directional_lights = @pbr_render.render3d_collect_extracted_directional_lights(
    render_world,
  )
  let extracted_directional_matches = extracted_directional_lights.length() == 1 &&
    extracted_directional_lights[0].volumetric &&
    extracted_directional_lights[0].shadow_maps_enabled &&
    fog_volumes_approx_eq(
      extracted_directional_lights[0].illuminance,
      32_000.0F,
    ) &&
    fog_volumes_vec3_approx_eq(
      extracted_directional_lights[0].transform.translation,
      @math.Vec3::new(1.0F, 1.0F, -0.3F),
    )
  debug_inspect(extracted_directional_matches, content="true")
  let gpu_lights = @pbr_render.render3d_collect_gpu_lights(render_world)
  debug_inspect(gpu_lights.n_directional_lights, content="1")
  debug_inspect(
    (gpu_lights.directional_lights[0].flags & (1U << 1)) != 0U,
    content="true",
  )
  let camera_rotation_changes_prepared_uniform = match
    (
      fog_volume_component.val,
      volumetric_fog_component.val,
      camera_transform_component.val,
    ) {
    (Some(fog_volume), Some(volumetric_fog), Some(camera_transform)) => {
      let initial_bytes = fog_volumes_prepared_uniform_bytes_for_camera(
        fog_volume,
        volumetric_fog,
        fog_volume_translation.val,
        camera_transform,
      )
      let rotated_translation = @math.Quat::from_rotation_y(0.01F).mul_vec3(
        camera_transform.translation,
      )
      let rotated_transform = @transform.Transform::from_translation(
        rotated_translation,
      ).looking_at(fog_center(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
      let rotated_bytes = fog_volumes_prepared_uniform_bytes_for_camera(
        fog_volume,
        volumetric_fog,
        fog_volume_translation.val,
        rotated_transform,
      )
      fog_volumes_uniform_word_range_changed(
        initial_bytes, rotated_bytes, 0, 64,
      ) ||
      fog_volumes_uniform_word_range_changed(
        initial_bytes, rotated_bytes, 128, 176,
      ) ||
      fog_volumes_uniform_u32_at(initial_bytes, 228) !=
      fog_volumes_uniform_u32_at(rotated_bytes, 228)
    }
    _ => false
  }
  debug_inspect(camera_rotation_changes_prepared_uniform, content="true")
}

///|
test "fog_volumes: camera rotation system matches upstream orbit step" {
  let mut app = fog_volumes_app()
  app = app.run_startup()
  let world = app.world()
  let initial_translation = fog_volumes_read_camera_translation(world)
  let camera_query : @ecs.Query[
    @ecs.Write[@transform.Transform],
    @ecs.With[@camera.Camera3d],
  ] = @ecs.query_filtered(world, @ecs.With::new(@camera.ecs_key_camera3d))
  rotate_camera(camera_query)
  let rotated_translation = fog_volumes_read_camera_translation(world)
  let expected = @math.Quat::from_rotation_y(0.01F).mul_vec3(
    initial_translation,
  )
  debug_inspect(
    fog_volumes_vec3_approx_eq(rotated_translation, expected),
    content="true",
  )
}

///|
test "fog_volumes: update schedule rotates camera every rendered frame" {
  let mut app = fog_volumes_app()
  app = app.run_startup()
  let initial_translation = fog_volumes_read_camera_translation(app.world())
  app = app.update()
  let first_frame_translation = fog_volumes_read_camera_translation(app.world())
  app = app.update()
  let second_frame_translation = fog_volumes_read_camera_translation(
    app.world(),
  )
  let rotation_step = @math.Quat::from_rotation_y(0.01F)
  let expected_first = rotation_step.mul_vec3(initial_translation)
  let expected_second = rotation_step.mul_vec3(expected_first)
  debug_inspect(
    fog_volumes_vec3_approx_eq(first_frame_translation, expected_first),
    content="true",
  )
  debug_inspect(
    fog_volumes_vec3_approx_eq(second_frame_translation, expected_second),
    content="true",
  )
  debug_inspect(
    !fog_volumes_vec3_approx_eq(
      first_frame_translation, second_frame_translation,
    ),
    content="true",
  )
  let render_world = app.sub_app(RenderApp).world()
  let render_storage_counts = @pbr_volumetric_fog.volumetric_fog_render_world_storage_counts(
    render_world,
  )
  debug_inspect(render_storage_counts.view_count(), content="1")
  debug_inspect(render_storage_counts.volume_count(), content="1")
  debug_inspect(render_storage_counts.light_count(), content="1")
}
