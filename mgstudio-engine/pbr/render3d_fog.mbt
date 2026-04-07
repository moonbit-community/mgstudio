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
fn render3d_distance_fog_enabled(fog : DistanceFog) -> Bool {
  if fog.color.a <= 0.0F {
    return false
  }
  match fog.falloff {
    FogFalloff3d::Linear(start, end_) => end_ > start
    FogFalloff3d::Exponential(density) => density > 0.0F
    FogFalloff3d::ExponentialSquared(density) => density > 0.0F
    FogFalloff3d::Atmospheric(extinction, inscattering) =>
      extinction.x +
      extinction.y +
      extinction.z +
      inscattering.x +
      inscattering.y +
      inscattering.z >
      0.0001F
  }
}

///|
fn render3d_color_lerp(
  from_ : @sprite.Color,
  to_ : @sprite.Color,
  t : Float,
) -> @sprite.Color {
  @sprite.Color::new(
    from_.r + (to_.r - from_.r) * t,
    from_.g + (to_.g - from_.g) * t,
    from_.b + (to_.b - from_.b) * t,
    from_.a + (to_.a - from_.a) * t,
  )
}

///|
fn render3d_camera_distance_fog(
  base_fog : DistanceFog,
  volumetric_fog : VolumetricFog?,
  atmosphere : Atmosphere?,
  atmosphere_settings : AtmosphereSettings?,
) -> DistanceFog {
  let mut fog = base_fog
  if volumetric_fog is Some(volumetric_fog_value) {
    let ambient_mix = render3d_float_clamp(
      volumetric_fog_value.ambient_intensity,
      0.0F,
      1.0F,
    )
    fog = DistanceFog::{
      ..fog,
      color: render3d_color_lerp(
        fog.color,
        volumetric_fog_value.ambient_color,
        ambient_mix,
      ),
      directional_light_color: render3d_color_lerp(
        fog.directional_light_color,
        volumetric_fog_value.ambient_color,
        ambient_mix * 0.6F,
      ),
      directional_light_exponent: fog.directional_light_exponent +
      Float::from_double(volumetric_fog_value.step_count.to_double()) /
      64.0F *
      0.5F,
    }
  }
  if atmosphere is Some(atmosphere_value) {
    let albedo_color = @sprite.Color::new(
      render3d_float_clamp(atmosphere_value.ground_albedo.x, 0.0F, 1.0F),
      render3d_float_clamp(atmosphere_value.ground_albedo.y, 0.0F, 1.0F),
      render3d_float_clamp(atmosphere_value.ground_albedo.z, 0.0F, 1.0F),
      1.0F,
    )
    fog = DistanceFog::{
      ..fog,
      color: render3d_color_lerp(fog.color, albedo_color, 0.15F),
    }
  }
  if atmosphere_settings is Some(atmosphere_settings_value) {
    let unit_scale = if atmosphere_settings_value.scene_units_to_m <= 0.0F {
      0.0001F
    } else {
      atmosphere_settings_value.scene_units_to_m
    }
    let falloff = match fog.falloff {
      FogFalloff3d::Linear(start, end_) =>
        FogFalloff3d::linear(start * unit_scale, end_ * unit_scale)
      FogFalloff3d::Exponential(density) =>
        FogFalloff3d::exponential(density / unit_scale)
      FogFalloff3d::ExponentialSquared(density) =>
        FogFalloff3d::exponential_squared(density / @math.sqrt(unit_scale))
      FogFalloff3d::Atmospheric(extinction, inscattering) =>
        FogFalloff3d::atmospheric(
          extinction.mul_scalar(1.0F / unit_scale),
          inscattering.mul_scalar(1.0F / unit_scale),
        )
    }
    fog = DistanceFog::{ ..fog, falloff, }
    if atmosphere_settings_value.rendering_method is AtmosphereMode::Raymarched {
      fog = DistanceFog::{
        ..fog,
        directional_light_exponent: fog.directional_light_exponent + 1.0F,
      }
    }
  }
  fog
}

///|
fn render3d_pow_e(value : Float) -> Float {
  @math.pow(FOG_FALLOFF_E, value)
}

///|
fn render3d_fog_channel_factor(density : Float, distance : Float) -> Float {
  let safe_density = if density < 0.0F { 0.0F } else { density }
  1.0F - render3d_pow_e(-(safe_density * distance))
}

///|
fn render3d_fog_falloff_factor(
  falloff : FogFalloff3d,
  distance : Float,
) -> Float {
  let safe_distance = if distance < 0.0F { 0.0F } else { distance }
  match falloff {
    Linear(start, end_) => {
      let safe_start = if start < 0.0F { 0.0F } else { start }
      let safe_end = if end_ < safe_start { safe_start } else { end_ }
      if safe_end <= safe_start {
        if safe_distance >= safe_end {
          1.0F
        } else {
          0.0F
        }
      } else if safe_distance <= safe_start {
        0.0F
      } else if safe_distance >= safe_end {
        1.0F
      } else {
        (safe_distance - safe_start) / (safe_end - safe_start)
      }
    }
    Exponential(density) => {
      let safe_density = if density < 0.0F { 0.0F } else { density }
      1.0F - render3d_pow_e(-safe_density * safe_distance)
    }
    ExponentialSquared(density) => {
      let safe_density = if density < 0.0F { 0.0F } else { density }
      let d = safe_density * safe_distance
      1.0F - render3d_pow_e(-(d * d))
    }
    Atmospheric(extinction, inscattering) => {
      let extinction_max = maxf(maxf(extinction.x, extinction.y), extinction.z)
      let inscattering_max = maxf(
        maxf(inscattering.x, inscattering.y),
        inscattering.z,
      )
      let extinction_factor = render3d_fog_channel_factor(
        extinction_max, safe_distance,
      )
      let inscattering_factor = render3d_fog_channel_factor(
        inscattering_max, safe_distance,
      )
      clamp01((extinction_factor + inscattering_factor) * 0.5F)
    }
  }
}

///|
fn render3d_distance_fog_mix_factor(
  fog : DistanceFog,
  distance : Float,
) -> Float {
  let falloff_factor = render3d_fog_falloff_factor(fog.falloff, distance)
  clamp01(falloff_factor * clamp01(fog.color.a))
}

///|
fn render3d_distance_fog_directional_mix(
  fog : DistanceFog,
  fog_presence : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
  lighting : Render3dLightingState,
) -> Float {
  let directional_alpha = clamp01(fog.directional_light_color.a)
  if directional_alpha <= 0.0F {
    return 0.0F
  }
  if fog.directional_light_exponent <= 0.0F {
    return 0.0F
  }
  if lighting.directional_illuminance <= 0.0F {
    return 0.0F
  }
  let view_direction = mesh_position.sub(camera_position).normalize_or_zero()
  let light_direction = lighting.directional_dir.neg().normalize_or_zero()
  let alignment = clamp01(light_direction.dot(view_direction) * 0.5F + 0.5F)
  let phase = @math.pow(alignment, fog.directional_light_exponent)
  let illuminance_mix = clamp01(lighting.directional_illuminance / 50_000.0F)
  clamp01(phase * directional_alpha * illuminance_mix * fog_presence)
}

///|
fn render3d_apply_distance_fog(
  fog : DistanceFog,
  distance : Float,
  base_r : Float,
  base_g : Float,
  base_b : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
  lighting : Render3dLightingState,
) -> (Float, Float, Float) {
  let fog_alpha = clamp01(fog.color.a)
  let mut fogged_r = base_r
  let mut fogged_g = base_g
  let mut fogged_b = base_b
  let mut fog_presence = 0.0F

  match fog.falloff {
    Atmospheric(extinction, inscattering) => {
      let extinction_r = clamp01(
        render3d_fog_channel_factor(extinction.x, distance) * fog_alpha,
      )
      let extinction_g = clamp01(
        render3d_fog_channel_factor(extinction.y, distance) * fog_alpha,
      )
      let extinction_b = clamp01(
        render3d_fog_channel_factor(extinction.z, distance) * fog_alpha,
      )
      let inscattering_r = clamp01(
        render3d_fog_channel_factor(inscattering.x, distance) * fog_alpha,
      )
      let inscattering_g = clamp01(
        render3d_fog_channel_factor(inscattering.y, distance) * fog_alpha,
      )
      let inscattering_b = clamp01(
        render3d_fog_channel_factor(inscattering.z, distance) * fog_alpha,
      )

      fogged_r = base_r * (1.0F - extinction_r) + fog.color.r * inscattering_r
      fogged_g = base_g * (1.0F - extinction_g) + fog.color.g * inscattering_g
      fogged_b = base_b * (1.0F - extinction_b) + fog.color.b * inscattering_b

      let extinction_peak = maxf(maxf(extinction_r, extinction_g), extinction_b)
      let inscattering_peak = maxf(
        maxf(inscattering_r, inscattering_g),
        inscattering_b,
      )
      fog_presence = clamp01((extinction_peak + inscattering_peak) * 0.5F)
    }
    _ => {
      let fog_mix = render3d_distance_fog_mix_factor(fog, distance)
      fogged_r = base_r * (1.0F - fog_mix) + fog.color.r * fog_mix
      fogged_g = base_g * (1.0F - fog_mix) + fog.color.g * fog_mix
      fogged_b = base_b * (1.0F - fog_mix) + fog.color.b * fog_mix
      fog_presence = fog_mix
    }
  }

  let directional_mix = render3d_distance_fog_directional_mix(
    fog, fog_presence, camera_position, mesh_position, lighting,
  )
  if directional_mix > 0.0F {
    let directional_tint_r = clamp01(
      fog.directional_light_color.r * lighting.directional_color.r,
    )
    let directional_tint_g = clamp01(
      fog.directional_light_color.g * lighting.directional_color.g,
    )
    let directional_tint_b = clamp01(
      fog.directional_light_color.b * lighting.directional_color.b,
    )
    fogged_r = fogged_r * (1.0F - directional_mix) +
      directional_tint_r * directional_mix
    fogged_g = fogged_g * (1.0F - directional_mix) +
      directional_tint_g * directional_mix
    fogged_b = fogged_b * (1.0F - directional_mix) +
      directional_tint_b * directional_mix
  }

  (clamp01(fogged_r), clamp01(fogged_g), clamp01(fogged_b))
}
