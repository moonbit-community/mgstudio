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
  let medium = @light.ScatteringMedium::ScatteringMedium().with_density_multiplier(
    -1.5,
  )
  let fog = @light.VolumetricFog::VolumetricFog().with_step_count(96)
  debug_inspect(point_shadow.size, content="2048")
  debug_inspect(directional_shadow.size, content="1024")
  debug_inspect(medium.density_multiplier.to_double(), content="-1.5")
  debug_inspect(fog.step_count, content="96")
}

///|
test "volumetric fog setters preserve Bevy plain field semantics" {
  let fog = @light.VolumetricFog::VolumetricFog()
    .with_ambient_intensity(-2.5F)
    .with_jitter(-0.75F)
  inspect(approx_eq(fog.ambient_intensity, -2.5F, 0.0001F), content="true")
  inspect(approx_eq(fog.jitter, -0.75F, 0.0001F), content="true")
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
    Some(@light.LightGizmoColor::ByLightType),
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
  try! world.set_by_key(
    entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
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
  let image_camera = spawn_light_test_camera(
    world,
    1.0F,
    0.0F,
    0.0F,
    @camera_camera.RenderTarget::Image(@asset.Handle::new(1)),
  )
  let screen_camera = spawn_light_test_camera(
    world,
    2.0F,
    0.0F,
    0.0F,
    @camera_camera.RenderTarget::Screen,
  )
  let explicit_origin = world.spawn_empty()
  try! world.set_by_key(
    explicit_origin,
    @camera_visibility.ecs_key_shadow_lod_origin,
    @camera_visibility.ShadowLodOrigin::ShadowLodOrigin(),
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
    @camera_camera.RenderTarget::Image(@asset.Handle::new(2)),
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
