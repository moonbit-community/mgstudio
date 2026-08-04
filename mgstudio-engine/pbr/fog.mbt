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
pub const FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD : Float = 0.05F

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
  @math.pow(value, FOG_FALLOFF_E)
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
  extinction_color : @color.Color,
  inscattering_color : @color.Color,
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

  Atmospheric(extinction, inscattering)
}

///|
pub fn FogFalloff3d::revised_koschmieder_contrast_threshold() -> Float {
  FOG_FALLOFF_REVISED_KOSCHMIEDER_CONTRAST_THRESHOLD
}

///|
pub fn FogFalloff3d::koschmieder(
  visibility : Float,
  contrast_threshold : Float,
) -> Float {
  fog_falloff_koschmieder(visibility, contrast_threshold)
}

///|
pub fn FogFalloff3d::linear(start : Float, end_ : Float) -> FogFalloff3d {
  let safe_start = if start < 0.0F { 0.0F } else { start }
  let safe_end = if end_ < safe_start { safe_start } else { end_ }
  Linear(safe_start, safe_end)
}

///|
pub fn FogFalloff3d::exponential(density : Float) -> FogFalloff3d {
  let safe_density = fog_falloff_sanitize_density(density)
  Exponential(safe_density)
}

///|
pub fn FogFalloff3d::exponential_squared(density : Float) -> FogFalloff3d {
  let safe_density = fog_falloff_sanitize_density(density)
  ExponentialSquared(safe_density)
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
  Atmospheric(safe_extinction, safe_inscattering)
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
  Exponential(fog_falloff_koschmieder(visibility, contrast_threshold))
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
  ExponentialSquared(fog_falloff_sanitize_density(density))
}

///|
pub fn FogFalloff3d::from_visibility_color(
  visibility : Float,
  extinction_inscattering_color : @color.Color,
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
  extinction_color : @color.Color,
  inscattering_color : @color.Color,
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
  extinction_inscattering_color : @color.Color,
) -> FogFalloff3d {
  FogFalloff3d::from_visibility_contrast_colors(
    visibility, contrast_threshold, extinction_inscattering_color, extinction_inscattering_color,
  )
}

///|
pub fn FogFalloff3d::from_visibility_contrast_colors(
  visibility : Float,
  contrast_threshold : Float,
  extinction_color : @color.Color,
  inscattering_color : @color.Color,
) -> FogFalloff3d {
  fog_falloff_atmospheric_from_colors(
    visibility, contrast_threshold, extinction_color, inscattering_color,
  )
}

///|
pub struct DistanceFog {
  color : @color.Color
  directional_light_color : @color.Color
  directional_light_exponent : Float
  falloff : FogFalloff3d
} derive(ToJson, FromJson)

///|
pub fn DistanceFog::DistanceFog() -> DistanceFog {
  {
    color: @color.Color::white(),
    directional_light_color: @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    directional_light_exponent: 8.0F,
    falloff: FogFalloff3d::linear(0.0F, 100.0F),
  }
}

///|
pub fn DistanceFog::new(
  color : @color.Color,
  falloff : FogFalloff3d,
) -> DistanceFog {
  {
    color,
    directional_light_color: @color.Color::new(0.0F, 0.0F, 0.0F, 0.0F),
    directional_light_exponent: 8.0F,
    falloff,
  }
}

///|
pub fn DistanceFog::with_color(
  self : DistanceFog,
  color : @color.Color,
) -> DistanceFog {
  { ..self, color, }
}

///|
pub fn DistanceFog::with_directional_light_color(
  self : DistanceFog,
  directional_light_color : @color.Color,
) -> DistanceFog {
  { ..self, directional_light_color, }
}

///|
pub fn DistanceFog::with_directional_light_exponent(
  self : DistanceFog,
  directional_light_exponent : Float,
) -> DistanceFog {
  {
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
  { ..self, falloff, }
}

///|
fn render3d_distance_fog_enabled(fog : DistanceFog) -> Bool {
  if fog.color.a <= 0.0F {
    return false
  }
  match fog.falloff {
    Linear(start, end_) => end_ > start
    Exponential(density) => density > 0.0F
    ExponentialSquared(density) => density > 0.0F
    Atmospheric(extinction, inscattering) =>
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
  from_ : @color.Color,
  to_ : @color.Color,
  t : Float,
) -> @color.Color {
  @color.Color::new(
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
  atmosphere : @pbr_atmosphere.ExtractedAtmosphere?,
  atmosphere_settings : @pbr_atmosphere.GpuAtmosphereSettings?,
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
  if atmosphere is Some(extracted_atmosphere) {
    let albedo_color = @color.Color::new(
      @pbr_render.render3d_float_clamp(
        extracted_atmosphere.ground_albedo.x,
        0.0F,
        1.0F,
      ),
      @pbr_render.render3d_float_clamp(
        extracted_atmosphere.ground_albedo.y,
        0.0F,
        1.0F,
      ),
      @pbr_render.render3d_float_clamp(
        extracted_atmosphere.ground_albedo.z,
        0.0F,
        1.0F,
      ),
      1.0F,
    )
    fog = fog.with_color(render3d_color_lerp(fog.color, albedo_color, 0.15F))
  }
  if atmosphere_settings is Some(atmosphere_settings_value) {
    if atmosphere_settings_value.rendering_method == 1 {
      fog = fog.with_directional_light_exponent(
        fog.directional_light_exponent + 1.0F,
      )
    }
  }
  fog
}

///|
fn render3d_view_fog_falloff(
  falloff : FogFalloff3d,
) -> @pbr_render.Render3dFogFalloff {
  match falloff {
    Linear(start, end_) => @pbr_render.Render3dFogFalloff::linear(start, end_)
    Exponential(density) => @pbr_render.Render3dFogFalloff::exponential(density)
    ExponentialSquared(density) =>
      @pbr_render.Render3dFogFalloff::exponential_squared(density)
    Atmospheric(extinction, inscattering) =>
      @pbr_render.Render3dFogFalloff::atmospheric(extinction, inscattering)
  }
}

///|
pub fn render3d_view_fog_data(
  fog : DistanceFog,
) -> @pbr_render.Render3dViewFogData {
  @pbr_render.Render3dViewFogData::new(
    fog.color,
    fog.directional_light_color,
    fog.directional_light_exponent,
    render3d_view_fog_falloff(fog.falloff),
  )
}

///|
pub fn render3d_prepare_camera_fog_uniforms(
  world : @ecs.World,
  view_entities : Array[@core.Entity],
  fog_meta : @pbr_render.FogMeta,
) -> Array[(@core.Entity, @pbr_render.ViewFogUniformOffset)] {
  let view_fogs : Array[(@core.Entity, @pbr_render.Render3dViewFogData?)] = []
  for entity in view_entities {
    if !world.is_alive(entity) {
      continue
    }
    let view_fog = match (try! world.get_by_key(entity, ecs_key_distance_fog)) {
      Some(fog) => Some(render3d_view_fog_data(fog))
      None => None
    }
    view_fogs.push((entity, view_fog))
  }
  @pbr_render.render3d_prepare_fog_uniforms(view_fogs, fog_meta)
}

///|
pub fn render3d_prepare_fog_system(world : @ecs.World) -> Unit {
  let sorted_cameras = @render.sorted_cameras_or_default(world)
  let fog_meta = @pbr_render.render3d_fog_meta_mut_or_init(world)
  let fog_offsets = fog_meta.modify(fn(value) {
    render3d_prepare_camera_fog_uniforms(
      world,
      sorted_cameras.camera_entities(),
      value,
    )
  })
  @pbr_render.render3d_apply_view_fog_uniform_offsets(world, fog_offsets)
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/fog.rs` `prepare_fog` writes the
// per-view `GpuFog` uniform; the mesh-view bind group exposes it at binding
// 13 and `pbr_functions.wgsl` applies it per fragment under `DISTANCE_FOG`.
// The renderer keeps a single 64-byte fog uniform, so each camera uploads
// its own prepared `GpuFog` (or `off`) before its passes, the same shape as
// the other per-camera mesh-view uniforms.
fn render3d_prepare_camera_fog_binding(
  world : @ecs.World,
  view_entity : @core.Entity,
) -> Unit {
  let gpu_fog = match
    (try! world.get_by_key(
      view_entity,
      @pbr_render.ViewFogUniformOffset::component(),
    )) {
    Some(offset) =>
      match
        @pbr_render.render3d_fog_meta_mut_or_init(world)
        .peek()
        .fog_at(offset.offset()) {
        Some(fog) => fog
        None => @pbr_render.GpuFog::off()
      }
    None => @pbr_render.GpuFog::off()
  }
  @render.host_gpu_prepare_mesh3d_fog(
    base_color_r=gpu_fog.base_color.x,
    base_color_g=gpu_fog.base_color.y,
    base_color_b=gpu_fog.base_color.z,
    base_color_a=gpu_fog.base_color.w,
    directional_light_color_r=gpu_fog.directional_light_color.x,
    directional_light_color_g=gpu_fog.directional_light_color.y,
    directional_light_color_b=gpu_fog.directional_light_color.z,
    directional_light_color_a=gpu_fog.directional_light_color.w,
    be_x=gpu_fog.be.x,
    be_y=gpu_fog.be.y,
    be_z=gpu_fog.be.z,
    directional_light_exponent=gpu_fog.directional_light_exponent,
    bi_x=gpu_fog.bi.x,
    bi_y=gpu_fog.bi.y,
    bi_z=gpu_fog.bi.z,
    mode=gpu_fog.mode,
  )
}
