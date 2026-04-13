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
// Bevy source: `bevy/crates/bevy_pbr/src/fog.rs`.

///|
pub enum FogFalloff3d {
  Linear(Float, Float)
  Exponential(Float)
  ExponentialSquared(Float)
  Atmospheric(@math.Vec3, @math.Vec3)
} derive(ToJson, FromJson)

///|
const FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD : Float = 0.05F

///|
const FOG_FALLOFF_E : Float = 2.718281828459045F

///|
const FOG_FALLOFF_LN2 : Float = 0.6931471805599453F

///|
const FOG_FALLOFF_MIN_VISIBILITY : Float = 0.0001F

///|
const FOG_FALLOFF_MIN_CONTRAST : Float = 0.000001F

///|
const FOG_FALLOFF_MAX_CONTRAST : Float = 0.999999F

///|
fn fog_falloff_clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn fog_falloff_sanitize_density(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn fog_falloff_sanitize_visibility(visibility : Float) -> Float {
  if visibility <= FOG_FALLOFF_MIN_VISIBILITY {
    FOG_FALLOFF_MIN_VISIBILITY
  } else {
    visibility
  }
}

///|
fn fog_falloff_sanitize_contrast(contrast_threshold : Float) -> Float {
  if contrast_threshold <= FOG_FALLOFF_MIN_CONTRAST {
    FOG_FALLOFF_MIN_CONTRAST
  } else if contrast_threshold >= FOG_FALLOFF_MAX_CONTRAST {
    FOG_FALLOFF_MAX_CONTRAST
  } else {
    contrast_threshold
  }
}

///|
fn fog_falloff_ln(value : Float) -> Float {
  if value <= 0.0F {
    return -87.3365447505531F
  }
  let mut x = value
  let mut exponent_shift = 0.0F
  while x > 2.0F {
    x = x * 0.5F
    exponent_shift = exponent_shift + FOG_FALLOFF_LN2
  }
  while x < 0.5F {
    x = x * 2.0F
    exponent_shift = exponent_shift - FOG_FALLOFF_LN2
  }
  let y = (x - 1.0F) / (x + 1.0F)
  let y_squared = y * y
  let mut series = 0.0F
  let mut numerator = y
  let mut denominator = 1.0F
  for _ in 0..<8 {
    series = series + numerator / denominator
    numerator = numerator * y_squared
    denominator = denominator + 2.0F
  }
  exponent_shift + 2.0F * series
}

///|
fn fog_falloff_pow_e(value : Float) -> Float {
  @math.pow(FOG_FALLOFF_E, value)
}

///|
fn fog_falloff_koschmieder(
  visibility : Float,
  contrast_threshold : Float,
) -> Float {
  let safe_visibility = fog_falloff_sanitize_visibility(visibility)
  let safe_contrast = fog_falloff_sanitize_contrast(contrast_threshold)
  -fog_falloff_ln(safe_contrast) / safe_visibility
}

///|
fn fog_falloff_atmospheric_from_colors(
  visibility : Float,
  contrast_threshold : Float,
  extinction_color : @sprite.Color,
  inscattering_color : @sprite.Color,
) -> FogFalloff3d {
  let beta = fog_falloff_koschmieder(visibility, contrast_threshold)

  let extinction_alpha = fog_falloff_pow_e(
    fog_falloff_clamp01(extinction_color.a),
  )
  let inscattering_alpha = fog_falloff_pow_e(
    fog_falloff_clamp01(inscattering_color.a),
  )

  let extinction = @math.Vec3::new(
    fog_falloff_pow_e(1.0F - fog_falloff_clamp01(extinction_color.r)) *
    beta *
    extinction_alpha,
    fog_falloff_pow_e(1.0F - fog_falloff_clamp01(extinction_color.g)) *
    beta *
    extinction_alpha,
    fog_falloff_pow_e(1.0F - fog_falloff_clamp01(extinction_color.b)) *
    beta *
    extinction_alpha,
  )

  let inscattering = @math.Vec3::new(
    fog_falloff_pow_e(fog_falloff_clamp01(inscattering_color.r)) *
    beta *
    inscattering_alpha,
    fog_falloff_pow_e(fog_falloff_clamp01(inscattering_color.g)) *
    beta *
    inscattering_alpha,
    fog_falloff_pow_e(fog_falloff_clamp01(inscattering_color.b)) *
    beta *
    inscattering_alpha,
  )

  FogFalloff3d::Atmospheric(extinction, inscattering)
}

///|
pub fn FogFalloff3d::revised_koschmieder_contrast_threshold() -> Float {
  FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD
}

///|
pub fn FogFalloff3d::linear(start : Float, end_ : Float) -> FogFalloff3d {
  let safe_start = if start < 0.0F { 0.0F } else { start }
  let safe_end = if end_ < safe_start { safe_start } else { end_ }
  FogFalloff3d::Linear(safe_start, safe_end)
}

///|
pub fn FogFalloff3d::exponential(density : Float) -> FogFalloff3d {
  let safe_density = fog_falloff_sanitize_density(density)
  FogFalloff3d::Exponential(safe_density)
}

///|
pub fn FogFalloff3d::exponential_squared(density : Float) -> FogFalloff3d {
  let safe_density = fog_falloff_sanitize_density(density)
  FogFalloff3d::ExponentialSquared(safe_density)
}

///|
pub fn FogFalloff3d::atmospheric(
  extinction : @math.Vec3,
  inscattering : @math.Vec3,
) -> FogFalloff3d {
  let safe_extinction = @math.Vec3::new(
    fog_falloff_sanitize_density(extinction.x),
    fog_falloff_sanitize_density(extinction.y),
    fog_falloff_sanitize_density(extinction.z),
  )
  let safe_inscattering = @math.Vec3::new(
    fog_falloff_sanitize_density(inscattering.x),
    fog_falloff_sanitize_density(inscattering.y),
    fog_falloff_sanitize_density(inscattering.z),
  )
  FogFalloff3d::Atmospheric(safe_extinction, safe_inscattering)
}

///|
pub fn FogFalloff3d::from_visibility(visibility : Float) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast(
  visibility : Float,
  contrast_threshold : Float,
) -> FogFalloff3d {
  FogFalloff3d::Exponential(
    fog_falloff_koschmieder(visibility, contrast_threshold),
  )
}

///|
pub fn FogFalloff3d::from_visibility_squared(
  visibility : Float,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_squared(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast_squared(
  visibility : Float,
  contrast_threshold : Float,
) -> FogFalloff3d {
  let safe_visibility = fog_falloff_sanitize_visibility(visibility)
  let density = @math.sqrt(
    fog_falloff_koschmieder(safe_visibility, contrast_threshold) /
    safe_visibility,
  )
  FogFalloff3d::ExponentialSquared(fog_falloff_sanitize_density(density))
}

///|
pub fn FogFalloff3d::from_visibility_color(
  visibility : Float,
  extinction_inscattering_color : @sprite.Color,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_colors(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
    extinction_inscattering_color,
    extinction_inscattering_color,
  )
}

///|
pub fn FogFalloff3d::from_visibility_colors(
  visibility : Float,
  extinction_color : @sprite.Color,
  inscattering_color : @sprite.Color,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_colors(
    visibility,
    FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD,
    extinction_color,
    inscattering_color,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast_color(
  visibility : Float,
  contrast_threshold : Float,
  extinction_inscattering_color : @sprite.Color,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_colors(
    visibility, contrast_threshold, extinction_inscattering_color, extinction_inscattering_color,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast_colors(
  visibility : Float,
  contrast_threshold : Float,
  extinction_color : @sprite.Color,
  inscattering_color : @sprite.Color,
) -> FogFalloff3d {
  fog_falloff_atmospheric_from_colors(
    visibility, contrast_threshold, extinction_color, inscattering_color,
  )
}

///|
pub struct DistanceFog {
  color : @sprite.Color
  directional_light_color : @sprite.Color
  directional_light_exponent : Float
  falloff : FogFalloff3d
} derive(ToJson, FromJson)

///|
pub fn DistanceFog::default() -> DistanceFog {
  DistanceFog::{
    color: @sprite.Color::white(),
    directional_light_color: @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    directional_light_exponent: 8.0F,
    falloff: FogFalloff3d::linear(0.0F, 100.0F),
  }
}

///|
pub fn DistanceFog::new(
  color : @sprite.Color,
  falloff : FogFalloff3d,
) -> DistanceFog {
  DistanceFog::{
    color,
    directional_light_color: @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    directional_light_exponent: 8.0F,
    falloff,
  }
}

///|
pub fn DistanceFog::with_color(
  self : DistanceFog,
  color : @sprite.Color,
) -> DistanceFog {
  DistanceFog::{ ..self, color, }
}

///|
pub fn DistanceFog::with_directional_light_color(
  self : DistanceFog,
  directional_light_color : @sprite.Color,
) -> DistanceFog {
  DistanceFog::{ ..self, directional_light_color, }
}

///|
pub fn DistanceFog::with_directional_light_exponent(
  self : DistanceFog,
  directional_light_exponent : Float,
) -> DistanceFog {
  DistanceFog::{
    ..self,
    directional_light_exponent: if directional_light_exponent < 0.0F {
      0.0F
    } else {
      directional_light_exponent
    },
  }
}

///|
pub fn DistanceFog::with_falloff(
  self : DistanceFog,
  falloff : FogFalloff3d,
) -> DistanceFog {
  DistanceFog::{ ..self, falloff, }
}

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
    let ambient_mix = @pbr_render.render3d_float_clamp(
      volumetric_fog_value.ambient_intensity,
      0.0F,
      1.0F,
    )
    fog = fog.with_color(
      render3d_color_lerp(
        fog.color,
        volumetric_fog_value.ambient_color,
        ambient_mix,
      ),
    )
    fog = fog.with_directional_light_color(
      render3d_color_lerp(
        fog.directional_light_color,
        volumetric_fog_value.ambient_color,
        ambient_mix * 0.6F,
      ),
    )
    fog = fog.with_directional_light_exponent(
      fog.directional_light_exponent +
      Float::from_double(volumetric_fog_value.step_count.to_double()) /
      64.0F *
      0.5F,
    )
  }
  if atmosphere is Some(atmosphere_value) {
    let albedo_color = @sprite.Color::new(
      @pbr_render.render3d_float_clamp(
        atmosphere_value.ground_albedo.x,
        0.0F,
        1.0F,
      ),
      @pbr_render.render3d_float_clamp(
        atmosphere_value.ground_albedo.y,
        0.0F,
        1.0F,
      ),
      @pbr_render.render3d_float_clamp(
        atmosphere_value.ground_albedo.z,
        0.0F,
        1.0F,
      ),
      1.0F,
    )
    fog = fog.with_color(render3d_color_lerp(fog.color, albedo_color, 0.15F))
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
    fog = fog.with_falloff(falloff)
    if atmosphere_settings_value.rendering_method is AtmosphereMode::Raymarched {
      fog = fog.with_directional_light_exponent(
        fog.directional_light_exponent + 1.0F,
      )
    }
  }
  fog
}

///|
fn render3d_fog_channel_factor(density : Float, distance : Float) -> Float {
  @pbr_render.render3d_fog_channel_factor(density, distance)
}

///|
fn render3d_fog_falloff_factor(
  falloff : FogFalloff3d,
  distance : Float,
) -> Float {
  match falloff {
    Linear(start, end_) =>
      @pbr_render.render3d_fog_linear_factor(start, end_, distance)
    Exponential(density) =>
      @pbr_render.render3d_fog_exponential_factor(density, distance)
    ExponentialSquared(density) =>
      @pbr_render.render3d_fog_exponential_squared_factor(density, distance)
    Atmospheric(extinction, inscattering) =>
      @pbr_render.render3d_fog_atmospheric_presence(
        extinction, inscattering, distance,
      )
  }
}

///|
fn render3d_distance_fog_mix_factor(
  fog : DistanceFog,
  distance : Float,
) -> Float {
  let falloff_factor = render3d_fog_falloff_factor(fog.falloff, distance)
  @pbr_render.clamp01(falloff_factor * @pbr_render.clamp01(fog.color.a))
}

///|
fn render3d_distance_fog_directional_mix(
  fog : DistanceFog,
  fog_presence : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
  lighting : Render3dLightingState,
) -> Float {
  @pbr_render.render3d_fog_directional_mix(
    fog.directional_light_color.a,
    fog.directional_light_exponent,
    lighting.directional_dir,
    lighting.directional_illuminance,
    fog_presence,
    camera_position,
    mesh_position,
  )
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
  let fog_alpha = @pbr_render.clamp01(fog.color.a)
  let mut fogged_r = base_r
  let mut fogged_g = base_g
  let mut fogged_b = base_b
  let mut fog_presence = 0.0F

  match fog.falloff {
    Atmospheric(extinction, inscattering) => {
      let extinction_r = @pbr_render.clamp01(
        render3d_fog_channel_factor(extinction.x, distance) * fog_alpha,
      )
      let extinction_g = @pbr_render.clamp01(
        render3d_fog_channel_factor(extinction.y, distance) * fog_alpha,
      )
      let extinction_b = @pbr_render.clamp01(
        render3d_fog_channel_factor(extinction.z, distance) * fog_alpha,
      )
      let inscattering_r = @pbr_render.clamp01(
        render3d_fog_channel_factor(inscattering.x, distance) * fog_alpha,
      )
      let inscattering_g = @pbr_render.clamp01(
        render3d_fog_channel_factor(inscattering.y, distance) * fog_alpha,
      )
      let inscattering_b = @pbr_render.clamp01(
        render3d_fog_channel_factor(inscattering.z, distance) * fog_alpha,
      )

      fogged_r = base_r * (1.0F - extinction_r) + fog.color.r * inscattering_r
      fogged_g = base_g * (1.0F - extinction_g) + fog.color.g * inscattering_g
      fogged_b = base_b * (1.0F - extinction_b) + fog.color.b * inscattering_b

      let extinction_peak = @pbr_render.maxf(
        @pbr_render.maxf(extinction_r, extinction_g),
        extinction_b,
      )
      let inscattering_peak = @pbr_render.maxf(
        @pbr_render.maxf(inscattering_r, inscattering_g),
        inscattering_b,
      )
      fog_presence = @pbr_render.clamp01(
        (extinction_peak + inscattering_peak) * 0.5F,
      )
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
    let directional_tint_r = @pbr_render.clamp01(
      fog.directional_light_color.r * lighting.directional_color.r,
    )
    let directional_tint_g = @pbr_render.clamp01(
      fog.directional_light_color.g * lighting.directional_color.g,
    )
    let directional_tint_b = @pbr_render.clamp01(
      fog.directional_light_color.b * lighting.directional_color.b,
    )
    fogged_r = fogged_r * (1.0F - directional_mix) +
      directional_tint_r * directional_mix
    fogged_g = fogged_g * (1.0F - directional_mix) +
      directional_tint_g * directional_mix
    fogged_b = fogged_b * (1.0F - directional_mix) +
      directional_tint_b * directional_mix
  }

  (
    @pbr_render.clamp01(fogged_r),
    @pbr_render.clamp01(fogged_g),
    @pbr_render.clamp01(fogged_b),
  )
}
