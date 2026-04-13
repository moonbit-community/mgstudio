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

// Bevy source: `bevy/crates/bevy_pbr/src/render/fog.rs`.

///|
const FOG_FALLOFF_E : Float = 2.718281828459045F

///|
fn render3d_fog_sanitize_distance(distance : Float) -> Float {
  if distance < 0.0F {
    0.0F
  } else {
    distance
  }
}

///|
fn render3d_fog_sanitize_density(density : Float) -> Float {
  if density < 0.0F {
    0.0F
  } else {
    density
  }
}

///|
pub fn render3d_fog_pow_e(value : Float) -> Float {
  @math.pow(FOG_FALLOFF_E, value)
}

///|
pub fn render3d_fog_channel_factor(density : Float, distance : Float) -> Float {
  let safe_density = render3d_fog_sanitize_density(density)
  let safe_distance = render3d_fog_sanitize_distance(distance)
  1.0F - render3d_fog_pow_e(-(safe_density * safe_distance))
}

///|
pub fn render3d_fog_linear_factor(
  start : Float,
  end_ : Float,
  distance : Float,
) -> Float {
  let safe_distance = render3d_fog_sanitize_distance(distance)
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

///|
pub fn render3d_fog_exponential_factor(
  density : Float,
  distance : Float,
) -> Float {
  render3d_fog_channel_factor(density, distance)
}

///|
pub fn render3d_fog_exponential_squared_factor(
  density : Float,
  distance : Float,
) -> Float {
  let safe_density = render3d_fog_sanitize_density(density)
  let safe_distance = render3d_fog_sanitize_distance(distance)
  let d = safe_density * safe_distance
  1.0F - render3d_fog_pow_e(-(d * d))
}

///|
pub fn render3d_fog_atmospheric_presence(
  extinction : @math.Vec3,
  inscattering : @math.Vec3,
  distance : Float,
) -> Float {
  let extinction_max = maxf(maxf(extinction.x, extinction.y), extinction.z)
  let inscattering_max = maxf(
    maxf(inscattering.x, inscattering.y),
    inscattering.z,
  )
  let extinction_factor = render3d_fog_channel_factor(extinction_max, distance)
  let inscattering_factor = render3d_fog_channel_factor(
    inscattering_max, distance,
  )
  clamp01((extinction_factor + inscattering_factor) * 0.5F)
}

///|
pub fn render3d_fog_directional_mix(
  directional_light_alpha : Float,
  directional_light_exponent : Float,
  directional_dir : @math.Vec3,
  directional_illuminance : Float,
  fog_presence : Float,
  camera_position : @math.Vec3,
  mesh_position : @math.Vec3,
) -> Float {
  let safe_alpha = clamp01(directional_light_alpha)
  if safe_alpha <= 0.0F {
    return 0.0F
  }
  if directional_light_exponent <= 0.0F {
    return 0.0F
  }
  if directional_illuminance <= 0.0F {
    return 0.0F
  }

  let view_direction = mesh_position.sub(camera_position).normalize_or_zero()
  let light_direction = directional_dir.neg().normalize_or_zero()
  let alignment = clamp01(light_direction.dot(view_direction) * 0.5F + 0.5F)
  let phase = @math.pow(alignment, directional_light_exponent)
  let illuminance_mix = clamp01(directional_illuminance / 50_000.0F)
  clamp01(phase * safe_alpha * illuminance_mix * fog_presence)
}
