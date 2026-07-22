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
fn approx_eq(a : Float, b : Float, eps : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta <= eps
  } else {
    delta <= eps
  }
}

///|
test "light boundary re-exports direct light component APIs" {
  let point = @light.PointLight::PointLight()
    .with_intensity(321.0)
    .with_range(45.0)
  let spot = @light.SpotLight::SpotLight()
    .with_inner_angle(0.25)
    .with_outer_angle(0.5)
  let directional = @light.DirectionalLight::DirectionalLight().with_illuminance(
    1000.0,
  )
  debug_inspect(point.intensity.to_double(), content="321")
  debug_inspect(point.range.to_double(), content="45")
  debug_inspect(spot.inner_angle.to_double(), content="0.25")
  debug_inspect(spot.outer_angle.to_double(), content="0.5")
  debug_inspect(directional.illuminance.to_double(), content="1000")
}

///|
test "light boundary re-exports shadow maps and volumetric APIs" {
  let point_shadow = @light.PointLightShadowMap::new(2048)
  let directional_shadow = @light.DirectionalLightShadowMap::new(1024)
  let medium = @light.ScatteringMedium::earth(8, 4).with_density_multiplier(
    2.0F,
  )
  let fog = @light.VolumetricFog::VolumetricFog().with_step_count(96)
  debug_inspect(point_shadow.size, content="2048")
  debug_inspect(directional_shadow.size, content="1024")
  debug_inspect(medium.falloff_resolution, content="8")
  debug_inspect(medium.phase_resolution, content="4")
  debug_inspect(medium.terms.length(), content="3")
  inspect(
    approx_eq(medium.terms[0].scattering.x, 11.604e-6F, 0.000000001F),
    content="true",
  )
  debug_inspect(fog.step_count, content="96")
}

///|
test "scattering medium earth terms match Bevy source shape" {
  let medium = @light.ScatteringMedium::earth(8, 4)
  debug_inspect(medium.label, content="Some(\"earth_atmosphere\")")
  debug_inspect(medium.falloff_resolution, content="8")
  debug_inspect(medium.phase_resolution, content="4")
  debug_inspect(medium.terms.length(), content="3")
  inspect(
    if medium.terms[0].falloff is Exponential(scale) {
      approx_eq(scale, 8.0F / 60.0F, 0.000001F)
    } else {
      false
    },
    content="true",
  )
  inspect(
    if medium.terms[0].phase is Rayleigh {
      true
    } else {
      false
    },
    content="true",
  )
  inspect(
    if medium.terms[1].phase is Mie(asymmetry) {
      approx_eq(asymmetry, 0.8F, 0.000001F)
    } else {
      false
    },
    content="true",
  )
  inspect(
    if medium.terms[2].falloff is Tent(center, width) {
      approx_eq(center, 0.75F, 0.000001F) && approx_eq(width, 0.3F, 0.000001F)
    } else {
      false
    },
    content="true",
  )
}

///|
test "scattering sampled curves follow Bevy curve sample semantics" {
  let scalar = @light.SampledFloatCurve::new(0.0F, 1.0F, [0.0F, 10.0F])
  inspect(
    approx_eq(scalar.sample(0.5F).unwrap(), 5.0F, 1.0e-6F),
    content="true",
  )
  inspect(scalar.sample(-0.1F) is None, content="true")
  let vector = @light.SampledVec3Curve::new(-1.0F, 1.0F, [
    @math.Vec3::new(1.0F, 2.0F, 3.0F),
    @math.Vec3::new(3.0F, 6.0F, 9.0F),
  ])
  let sampled = vector.sample(0.0F).unwrap()
  inspect(approx_eq(sampled.x, 2.0F, 1.0e-6F), content="true")
  inspect(approx_eq(sampled.y, 4.0F, 1.0e-6F), content="true")
  inspect(approx_eq(sampled.z, 6.0F, 1.0e-6F), content="true")
}

///|
test "scattering medium mars terms match Bevy source shape" {
  let dust_phase : @asset.Handle[@asset.Image] = @asset.Handle::new(42)
  let medium = @light.ScatteringMedium::mars(8, 4, dust_phase)
  debug_inspect(medium.label, content="Some(\"mars_atmosphere\")")
  debug_inspect(medium.falloff_resolution, content="8")
  debug_inspect(medium.phase_resolution, content="4")
  debug_inspect(medium.terms.length(), content="2")
  inspect(
    if medium.terms[0].falloff is Exponential(scale) {
      approx_eq(scale, 8_000.0F / 120_000.0F, 1.0e-6F)
    } else {
      false
    },
    content="true",
  )
  inspect(
    if medium.terms[0].phase is Rayleigh {
      true
    } else {
      false
    },
    content="true",
  )
  inspect(
    if medium.terms[1].falloff is Curve(curve) {
      curve.samples.length() == 8 &&
      approx_eq(curve.sample(1.0F).unwrap(), 1.0F, 1.0e-6F)
    } else {
      false
    },
    content="true",
  )
  inspect(
    if medium.terms[1].phase is ChromaticTexture(handle) {
      handle.id() == dust_phase.id()
    } else {
      false
    },
    content="true",
  )
  inspect(medium.terms[1].phase.sample(0.0F) is None, content="true")
}

///|
test "scattering term defaults match Bevy" {
  let term = @light.ScatteringTerm::ScatteringTerm()
  inspect(approx_eq(term.absorption.x, 0.0F, 0.000001F), content="true")
  inspect(approx_eq(term.scattering.x, 0.0F, 0.000001F), content="true")
  inspect(if term.falloff is Linear { true } else { false }, content="true")
  inspect(
    if term.phase is Mie(asymmetry) {
      approx_eq(asymmetry, 0.8F, 0.000001F)
    } else {
      false
    },
    content="true",
  )
}

///|
test "point shadow map constructor preserves Bevy plain field semantics" {
  let authored = @light.PointLightShadowMap::new(0).with_size(-7)
  debug_inspect(authored.size, content="-7")
}

///|
test "volumetric fog setters preserve Bevy plain field semantics" {
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_ambient_intensity(-2.5F)
    .with_jitter(-0.75F)
    .with_step_count(0)
  inspect(approx_eq(fog.ambient_intensity, -2.5F, 0.0001F), content="true")
  inspect(approx_eq(fog.jitter, -0.75F, 0.0001F), content="true")
  debug_inspect(fog.step_count, content="0")
  let volume = @light.FogVolume::FogVolume()
    .with_density_factor(-0.1F)
    .with_absorption(-0.2F)
    .with_scattering(-0.3F)
    .with_scattering_asymmetry(1.5F)
    .with_light_intensity(-0.4F)
  inspect(approx_eq(volume.density_factor, -0.1F, 0.0001F), content="true")
  inspect(approx_eq(volume.absorption, -0.2F, 0.0001F), content="true")
  inspect(approx_eq(volume.scattering, -0.3F, 0.0001F), content="true")
  inspect(approx_eq(volume.scattering_asymmetry, 1.5F, 0.0001F), content="true")
  inspect(approx_eq(volume.light_intensity, -0.4F, 0.0001F), content="true")
}

///|
test "volumetric fog and fog volume defaults match Bevy source" {
  let fog = @light.VolumetricFog::VolumetricFog()
  let fog_color = fog.ambient_color.to_srgba_tuple()
  inspect(approx_eq(fog_color.0, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(fog_color.1, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(fog_color.2, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(fog_color.3, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(fog.ambient_intensity, 0.1F, 0.0001F), content="true")
  inspect(approx_eq(fog.jitter, 0.0F, 0.0001F), content="true")
  debug_inspect(fog.step_count, content="64")

  let volume = @light.FogVolume::FogVolume()
  let fog_volume_color = volume.fog_color.to_srgba_tuple()
  let light_tint = volume.light_tint.to_srgba_tuple()
  inspect(approx_eq(fog_volume_color.0, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(fog_volume_color.1, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(fog_volume_color.2, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(fog_volume_color.3, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(volume.density_factor, 0.1F, 0.0001F), content="true")
  debug_inspect(volume.density_texture is None, content="true")
  inspect(
    approx_eq(volume.density_texture_offset.x, 0.0F, 0.0001F),
    content="true",
  )
  inspect(
    approx_eq(volume.density_texture_offset.y, 0.0F, 0.0001F),
    content="true",
  )
  inspect(
    approx_eq(volume.density_texture_offset.z, 0.0F, 0.0001F),
    content="true",
  )
  inspect(approx_eq(volume.absorption, 0.3F, 0.0001F), content="true")
  inspect(approx_eq(volume.scattering, 0.3F, 0.0001F), content="true")
  inspect(approx_eq(volume.scattering_asymmetry, 0.5F, 0.0001F), content="true")
  inspect(approx_eq(light_tint.0, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(light_tint.1, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(light_tint.2, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(light_tint.3, 1.0F, 0.0001F), content="true")
  inspect(approx_eq(volume.light_intensity, 1.0F, 0.0001F), content="true")
}

///|
test "light gizmo config group defaults align with light kinds" {
  let config = @light.LightGizmoConfigGroup::LightGizmoConfigGroup()
  debug_inspect(config.draw_all, content="false")
  debug_inspect(
    if config.color is MatchLightColor {
      true
    } else {
      false
    },
    content="true",
  )
  debug_inspect(config.point_light_color.r.to_double(), content="1")
  debug_inspect(config.spot_light_color.g.to_double(), content="1")
  debug_inspect(config.directional_light_color.b.to_double(), content="1")
  debug_inspect(
    config.rect_light_color.r.to_double(),
    content="0.21404114365577698",
  )
}

///|
test "rect light constructor preserves Bevy plain field semantics" {
  let rect = @light.RectLight::new(
    @color.Color::white(),
    -10.0F,
    -20.0F,
    -1.5F,
    -2.5F,
  )
  debug_inspect(rect.intensity().to_double(), content="-10")
  debug_inspect(rect.range().to_double(), content="-20")
  debug_inspect(rect.width().to_double(), content="-1.5")
  debug_inspect(rect.height().to_double(), content="-2.5")
}

///|
test "spot light default angles match Bevy" {
  let spot = @light.SpotLight::SpotLight()
  debug_inspect(spot.inner_angle.to_double(), content="0")
  debug_inspect(
    approx_eq(spot.outer_angle, @math.pi() / 4.0F, 1.0e-6F),
    content="true",
  )
}

///|
test "spot light angle setters preserve plain field semantics" {
  let spot = @light.SpotLight::SpotLight()
    .with_inner_angle(-0.25F)
    .with_outer_angle(-0.5F)
  debug_inspect(spot.inner_angle.to_double(), content="-0.25")
  debug_inspect(spot.outer_angle.to_double(), content="-0.5")
  let inverted = @light.SpotLight::SpotLight()
    .with_inner_angle(1.5F)
    .with_outer_angle(0.25F)
  debug_inspect(inverted.inner_angle.to_double(), content="1.5")
  debug_inspect(inverted.outer_angle.to_double(), content="0.25")
}

///|
test "spot light helpers match Bevy source shape" {
  let basis = @light.orthonormalize(@math.Vec3::new(0.0F, 0.0F, 1.0F))
  inspect(approx_eq(basis.x_axis.x, 1.0F, 1.0e-6F), content="true")
  inspect(approx_eq(basis.y_axis.y, 1.0F, 1.0e-6F), content="true")
  inspect(approx_eq(basis.z_axis.z, 1.0F, 1.0e-6F), content="true")

  let negative_zero = Float::reinterpret_from_uint(0x8000_0000U)
  let negative_zero_basis = @light.orthonormalize(
    @math.Vec3::new(1.0F, 0.0F, negative_zero),
  )
  inspect(
    approx_eq(negative_zero_basis.x_axis.z, 1.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(negative_zero_basis.y_axis.y, -1.0F, 1.0e-6F),
    content="true",
  )

  let transform = @transform.GlobalTransform::from_transform(
    @transform.Transform::from_xyz(3.0F, 4.0F, 5.0F),
  )
  let world_from_view = @light.spot_light_world_from_view(transform)
  inspect(
    approx_eq(world_from_view.translation.x, 3.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(world_from_view.translation.y, 4.0F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(world_from_view.translation.z, 5.0F, 1.0e-6F),
    content="true",
  )

  let clip = @light.spot_light_clip_from_view(0.5F, 0.25F)
  inspect(approx_eq(clip.z_axis().w, -1.0F, 1.0e-6F), content="true")
  inspect(approx_eq(clip.w_axis().z, 0.25F, 1.0e-6F), content="true")
}

///|
test "spot light scalar setters preserve Bevy plain field semantics" {
  let spot = @light.SpotLight::SpotLight()
    .with_intensity(-10.0F)
    .with_radius(-0.5F)
    .with_shadow_depth_bias(-0.1F)
    .with_shadow_normal_bias(-0.2F)
    .with_shadow_map_near_z(-0.3F)
  debug_inspect(spot.intensity.to_double(), content="-10")
  debug_inspect(spot.radius.to_double(), content="-0.5")
  inspect(approx_eq(spot.shadow_depth_bias, -0.1F, 1.0e-6F), content="true")
  inspect(approx_eq(spot.shadow_normal_bias, -0.2F, 1.0e-6F), content="true")
  inspect(approx_eq(spot.shadow_map_near_z, -0.3F, 1.0e-6F), content="true")
}

///|
test "point light setters preserve Bevy plain field semantics" {
  let point = @light.PointLight::PointLight()
    .with_intensity(-10.0F)
    .with_range(-20.0F)
    .with_radius(-0.5F)
    .with_shadow_depth_bias(-0.1F)
    .with_shadow_normal_bias(-0.2F)
    .with_shadow_map_near_z(-0.3F)
  debug_inspect(point.intensity.to_double(), content="-10")
  debug_inspect(point.range.to_double(), content="-20")
  debug_inspect(point.radius.to_double(), content="-0.5")
  inspect(approx_eq(point.shadow_depth_bias, -0.1F, 1.0e-6F), content="true")
  inspect(approx_eq(point.shadow_normal_bias, -0.2F, 1.0e-6F), content="true")
  inspect(approx_eq(point.shadow_map_near_z, -0.3F, 1.0e-6F), content="true")
}

///|
test "directional light setters preserve Bevy plain field semantics" {
  let directional = @light.DirectionalLight::DirectionalLight()
    .with_illuminance(-10.0F)
    .with_soft_shadow_size(Some(-0.5F))
    .with_shadow_depth_bias(-0.1F)
    .with_shadow_normal_bias(-0.2F)
  debug_inspect(directional.illuminance.to_double(), content="-10")
  match directional.soft_shadow_size {
    Some(value) => debug_inspect(value.to_double(), content="-0.5")
    None => inspect(false, content="true")
  }
  inspect(
    approx_eq(directional.shadow_depth_bias, -0.1F, 1.0e-6F),
    content="true",
  )
  inspect(
    approx_eq(directional.shadow_normal_bias, -0.2F, 1.0e-6F),
    content="true",
  )
}

///|
test "show light gizmo stores optional color override" {
  let gizmo = @light.ShowLightGizmo::ShowLightGizmo().with_color(
    Some(ByLightType),
  )
  debug_inspect(
    if gizmo.color is Some(ByLightType) {
      true
    } else {
      false
    },
    content="true",
  )
}

///|
test "directional and spot support explicit shadow map toggles" {
  let directional = @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(
    true,
  )
  let spot = @light.SpotLight::SpotLight().with_shadow_maps_enabled(true)
  debug_inspect(directional.shadow_maps_enabled, content="true")
  debug_inspect(spot.shadow_maps_enabled, content="true")
}

///|
test "global ambient light supports affects_lightmapped_meshes toggle" {
  let camera_ambient = @light.AmbientLight::AmbientLight().with_affects_lightmapped_meshes(
    false,
  )
  debug_inspect(camera_ambient.brightness, content="80")
  debug_inspect(camera_ambient.affects_lightmapped_meshes, content="false")
  let ambient = @light.GlobalAmbientLight::GlobalAmbientLight().with_affects_lightmapped_meshes(
    false,
  )
  debug_inspect(ambient.affects_lightmapped_meshes, content="false")
  let none = @light.GlobalAmbientLight::none()
  debug_inspect(none.color.r.to_double(), content="1")
  debug_inspect(none.color.g.to_double(), content="1")
  debug_inspect(none.color.b.to_double(), content="1")
  debug_inspect(none.color.a.to_double(), content="1")
  debug_inspect(none.brightness, content="0")
  debug_inspect(none.affects_lightmapped_meshes, content="true")
}

///|
test "sun disk defaults and off profile align with bevy intent" {
  let earth = @light.SunDisk::SunDisk()
  debug_inspect(
    approx_eq(earth.angular_size, 0.00930842F, 1.0e-6F),
    content="true",
  )
  debug_inspect(approx_eq(earth.intensity, 1.0F, 1.0e-6F), content="true")
  let off = @light.SunDisk::off()
  debug_inspect(approx_eq(off.angular_size, 0.0F, 1.0e-6F), content="true")
  debug_inspect(approx_eq(off.intensity, 0.0F, 1.0e-6F), content="true")
  let custom = @light.SunDisk::new(-0.25F, -2.0F)
    .with_angular_size(-0.5F)
    .with_intensity(-3.0F)
  debug_inspect(custom.angular_size.to_double(), content="-0.5")
  debug_inspect(custom.intensity.to_double(), content="-3")
}

///|
test "light probe intensities preserve Bevy plain field semantics" {
  let atmosphere = @light.AtmosphereEnvironmentMapLight::new(
    -1.5F,
    false,
    @math.UVec2::new(256, 256),
  ).with_intensity(-2.5F)
  debug_inspect(atmosphere.intensity.to_double(), content="-2.5")
  let environment = @light.EnvironmentMapLight::new(None, None, -3.5F)
  debug_inspect(environment.intensity.to_double(), content="-3.5")
  let generated = @light.GeneratedEnvironmentMapLight::new(None, -4.5F)
  debug_inspect(generated.intensity.to_double(), content="-4.5")
  let irradiance_default = @light.IrradianceVolume::IrradianceVolume()
  debug_inspect(irradiance_default.intensity.to_double(), content="0")
  let irradiance = @light.IrradianceVolume::new(None, -5.5F).with_intensity(
    -6.5F,
  )
  debug_inspect(irradiance.intensity.to_double(), content="-6.5")
}

///|
test "atmosphere environment map size preserves Bevy authoring semantics" {
  let atmosphere = @light.AtmosphereEnvironmentMapLight::new(
    1.0F,
    true,
    @math.UVec2::new(0, 333),
  ).with_size(@math.UVec2::new(777, 0))
  inspect(atmosphere.size.x, content="777")
  inspect(atmosphere.size.y, content="0")
}

///|
test "atmosphere radii preserve Bevy plain field semantics" {
  let atmosphere = @light.Atmosphere::earth(@asset.Handle::new(1)).with_radii(
    -1.0F,
    -2.0F,
  )
  inspect(atmosphere.inner_radius.to_double(), content="-1")
  inspect(atmosphere.outer_radius.to_double(), content="-2")
}

///|
test "atmosphere constructors preserve Bevy planet constants" {
  let earth = @light.Atmosphere::earth(@asset.Handle::new(2))
  inspect(earth.inner_radius.to_double(), content="6360000")
  inspect(earth.outer_radius.to_double(), content="6460000")
  debug_inspect(approx_eq(earth.ground_albedo.x, 0.3F, 1.0e-6F), content="true")
  let mars = @light.Atmosphere::mars(@asset.Handle::new(3))
  inspect(mars.inner_radius.to_double(), content="3389500")
  inspect(mars.outer_radius.to_double(), content="3509500")
  debug_inspect(approx_eq(mars.ground_albedo.x, 0.1F, 1.0e-6F), content="true")
}

///|
test "skybox brightness preserves Bevy plain field semantics" {
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(17)
  let skybox = @light.Skybox::new(image, -1.5F).with_brightness(-2.5F)
  debug_inspect(skybox.brightness.to_double(), content="-2.5")
}

///|
fn spawn_light_test_camera(
  world : @ecs.World,
  x : Float,
  y : Float,
  z : Float,
  target : @camera_camera.RenderTarget,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(entity, @camera_camera.ecs_key_camera, Camera())
  try! world.set_by_key(entity, @camera_camera.ecs_key_render_target, target)
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(x, y, z),
    ),
  )
  entity
}

///|
test "shadow LOD origin selection follows Bevy priority order" {
  let world = @ecs.World::new()
  defer world.close()
  let image_camera = spawn_light_test_camera(
    world,
    1.0F,
    0.0F,
    0.0F,
    Image(@asset.Handle::new(1)),
  )
  let screen_camera = spawn_light_test_camera(world, 2.0F, 0.0F, 0.0F, Screen)
  let explicit_origin = world.spawn_empty()
  try! world.set_by_key(
    explicit_origin,
    @camera_visibility.ecs_key_shadow_lod_origin,
    ShadowLodOrigin(),
  )

  let selected = get_shadow_lod_origin(world).unwrap()
  debug_inspect(selected.to_bits() == explicit_origin.to_bits(), content="true")

  ignore(
    try! world.remove_by_key(
      explicit_origin, @camera_visibility.ecs_key_shadow_lod_origin,
    ),
  )
  let window_selected = get_shadow_lod_origin(world).unwrap()
  debug_inspect(
    window_selected.to_bits() == screen_camera.to_bits(),
    content="true",
  )

  ignore(
    try! world.remove_by_key(
      screen_camera, @camera_camera.ecs_key_render_target,
    ),
  )
  try! world.set_by_key(
    screen_camera,
    @camera_camera.ecs_key_render_target,
    Image(@asset.Handle::new(2)),
  )
  let fallback_selected = get_shadow_lod_origin(world).unwrap()
  debug_inspect(
    fallback_selected.to_bits() == image_camera.to_bits(),
    content="true",
  )
}

///|
test "shadow LOD origin selection returns none without cameras or explicit origin" {
  let world = @ecs.World::new()
  defer world.close()
  debug_inspect(get_shadow_lod_origin(world) is None, content="true")
}

///|
test "directional shadow map validation produces next power-of-two size" {
  let authored = @light.DirectionalLightShadowMap::new(1500).with_size(1537)
  debug_inspect(authored.size, content="1537")
  debug_inspect(
    @light.directional_light_validated_shadow_map_size(1500),
    content="2048",
  )
  debug_inspect(
    @light.directional_light_validated_shadow_map_size(2048),
    content="2048",
  )
}

///|
test "directional cascade calculation follows Bevy stable texel snapping" {
  let cascade = @light.calculate_directional_light_cascade(
    [
      @math.Vec3::new(1.0F, -1.0F, -1.0F),
      @math.Vec3::new(1.0F, 1.0F, -1.0F),
      @math.Vec3::new(-1.0F, 1.0F, -1.0F),
      @math.Vec3::new(-1.0F, -1.0F, -1.0F),
      @math.Vec3::new(2.0F, -2.0F, -3.0F),
      @math.Vec3::new(2.0F, 2.0F, -3.0F),
      @math.Vec3::new(-2.0F, 2.0F, -3.0F),
      @math.Vec3::new(-2.0F, -2.0F, -3.0F),
    ],
    12.0F,
    @math.Mat4::identity(),
    @math.Mat4::identity(),
  )
  debug_inspect(approx_eq(cascade.texel_size, 0.5F, 1.0e-6F), content="true")
  let world_translation = cascade.world_from_cascade.w_axis()
  debug_inspect(
    approx_eq(world_translation.x, 0.0F, 1.0e-6F) &&
    approx_eq(world_translation.y, 0.0F, 1.0e-6F) &&
    approx_eq(world_translation.z, -1.0F, 1.0e-6F) &&
    approx_eq(world_translation.w, 1.0F, 1.0e-6F),
    content="true",
  )
  let clip_from_cascade = cascade.clip_from_cascade
  debug_inspect(
    approx_eq(clip_from_cascade.x_axis().x, 1.0F / 3.0F, 1.0e-6F),
    content="true",
  )
  debug_inspect(
    approx_eq(clip_from_cascade.z_axis().z, 0.5F, 1.0e-6F),
    content="true",
  )
}

///|
test "directional cascade builder filters active cameras and writes cascades" {
  let world = @ecs.World::new()
  defer world.close()
  world.insert_resource(
    @light.ecs_key_directional_light_shadow_map,
    @light.DirectionalLightShadowMap::new(1024),
  )
  let active_view = world.spawn()
  let inactive_view = world.spawn()
  let light = world.spawn()
  try! world.set_by_key(active_view, @camera_camera.ecs_key_camera, Camera())
  try! world.set_by_key(
    active_view,
    @camera_projection3d.ecs_key_projection,
    @camera_projection3d.Projection::default(),
  )
  try! world.set_by_key(
    active_view,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    inactive_view,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )
  try! world.set_by_key(
    inactive_view,
    @camera_projection3d.ecs_key_projection,
    @camera_projection3d.Projection::default(),
  )
  try! world.set_by_key(
    inactive_view,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    light,
    @light.ecs_key_directional_light,
    @light.DirectionalLight::DirectionalLight().with_shadow_maps_enabled(true),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_rotation(@math.Quat::identity()),
    ),
  )
  try! world.set_by_key(
    light,
    @light.ecs_key_cascade_shadow_config,
    @light.CascadeShadowConfigBuilder::CascadeShadowConfigBuilder()
    .with_num_cascades(2)
    .with_first_cascade_far_bound(4.0F)
    .with_maximum_distance(16.0F)
    .build(),
  )
  try! world.set_by_key(light, @light.ecs_key_cascades, Cascades())

  @light.build_directional_light_cascades(world)

  let cascades = (try! world.get_by_key(light, @light.ecs_key_cascades)).unwrap()
  debug_inspect(cascades.get(active_view).length(), content="2")
  debug_inspect(cascades.get(inactive_view).length(), content="0")
  debug_inspect(cascades.get(active_view)[0].texel_size > 0.0F, content="true")
}
