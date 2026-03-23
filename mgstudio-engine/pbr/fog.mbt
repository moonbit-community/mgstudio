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
pub(all) enum FogFalloff3d {
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
let distance_fog_state : Ref[DistanceFog] = Ref::new(
  DistanceFog::new(
    @sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    FogFalloff3d::linear(0.0F, 0.0F),
  ),
)

///|
pub fn render3d_set_distance_fog(fog : DistanceFog) -> Unit {
  distance_fog_state.val = fog
}

///|
pub fn render3d_distance_fog() -> DistanceFog {
  distance_fog_state.val
}
