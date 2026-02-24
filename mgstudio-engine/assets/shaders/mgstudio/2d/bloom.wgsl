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
//
// Derived from Bevy bloom implementation:
// - bevy/crates/bevy_post_process/src/bloom/bloom.wgsl

#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

struct Bloom2dUniforms {
  // intensity, low_frequency_boost, low_frequency_boost_curvature, high_pass_frequency
  params0 : vec4<f32>,
  // threshold, threshold_softness, composite_mode(0 energy / 1 additive), enabled
  params1 : vec4<f32>,
  // scale_x, scale_y, max_mip_dimension, reserved
  params2 : vec4<f32>,
  // view_width, view_height, reserved, reserved
  params3 : vec4<f32>,
};

@group(0) @binding(0) var input_texture : texture_2d<f32>;
@group(0) @binding(1) var input_sampler : sampler;
@group(0) @binding(2) var<uniform> uniforms : Bloom2dUniforms;

const MAX_MIPS : i32 = 8;

fn tonemapping_luminance(v : vec3<f32>) -> f32 {
  return dot(v, vec3<f32>(0.2126, 0.7152, 0.0722));
}

fn karis_average(color : vec3<f32>) -> f32 {
  let luma = tonemapping_luminance(color) / 4.0;
  return 1.0 / (1.0 + luma);
}

fn soft_threshold(color : vec3<f32>, threshold : f32, softness_raw : f32) -> vec3<f32> {
  let softness = clamp(softness_raw, 0.0, 1.0);
  let knee = threshold * softness;
  let brightness = max(color.r, max(color.g, color.b));
  var soft = brightness - (threshold - knee);
  soft = clamp(soft, 0.0, 2.0 * knee);
  soft = soft * soft * (0.25 / (knee + 0.00001));
  var contribution = max(brightness - threshold, soft);
  contribution /= max(brightness, 0.00001);
  return color * contribution;
}

fn sample_input_13_tap_scaled(uv : vec2<f32>, sample_scale : vec2<f32>) -> vec3<f32> {
  let dims = vec2<f32>(textureDimensions(input_texture));
  let safe_dims = vec2<f32>(max(dims.x, 1.0), max(dims.y, 1.0));
  let ps = sample_scale / safe_dims;
  let pl = 2.0 * ps;
  let ns = -1.0 * ps;
  let nl = -2.0 * ps;
  let a = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(nl.x, pl.y), 0.0).rgb;
  let b = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(0.0, pl.y), 0.0).rgb;
  let c = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(pl.x, pl.y), 0.0).rgb;
  let d = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(nl.x, 0.0), 0.0).rgb;
  let e = textureSampleLevel(input_texture, input_sampler, uv, 0.0).rgb;
  let f = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(pl.x, 0.0), 0.0).rgb;
  let g = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(nl.x, nl.y), 0.0).rgb;
  let h = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(0.0, nl.y), 0.0).rgb;
  let i = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(pl.x, nl.y), 0.0).rgb;
  let j = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(ns.x, ps.y), 0.0).rgb;
  let k = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(ps.x, ps.y), 0.0).rgb;
  let l = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(ns.x, ns.y), 0.0).rgb;
  let m = textureSampleLevel(input_texture, input_sampler, uv + vec2<f32>(ps.x, ns.y), 0.0).rgb;

  // Matches Bevy first-downsample weighted sampling and firefly reduction.
  var group0 = (a + b + d + e) * (0.125 / 4.0);
  var group1 = (b + c + e + f) * (0.125 / 4.0);
  var group2 = (d + e + g + h) * (0.125 / 4.0);
  var group3 = (e + f + h + i) * (0.125 / 4.0);
  var group4 = (j + k + l + m) * (0.5 / 4.0);
  group0 *= karis_average(group0);
  group1 *= karis_average(group1);
  group2 *= karis_average(group2);
  group3 *= karis_average(group3);
  group4 *= karis_average(group4);
  return group0 + group1 + group2 + group3 + group4;
}

fn compute_blend_factor(
  mip : f32,
  max_mip : f32,
  intensity : f32,
  low_frequency_boost : f32,
  low_frequency_boost_curvature : f32,
  high_pass_frequency : f32,
  composite_mode : f32,
) -> f32 {
  if max_mip <= 0.0 {
    return intensity;
  }
  let mip_ratio = clamp(mip / max_mip, 0.0, 1.0);
  let curvature = clamp(low_frequency_boost_curvature, 0.0, 0.9999);
  let exponent = 1.0 / max(1.0 - curvature, 0.0001);
  var lf_boost = (1.0 - pow(1.0 - mip_ratio, exponent)) * low_frequency_boost;
  let hp = clamp(high_pass_frequency, 0.0, 1.0);
  let high_pass_lq = if hp <= 0.000001 {
    if mip_ratio <= 0.0 {
      1.0
    } else {
      0.0
    }
  } else {
    1.0 - clamp((mip_ratio - hp) / hp, 0.0, 1.0)
  };
  let mode_factor = if composite_mode < 0.5 {
    1.0 - intensity
  } else {
    1.0
  };
  lf_boost *= mode_factor;
  return max((intensity + lf_boost) * high_pass_lq, 0.0);
}

@fragment
fn fragment(in : FullscreenVertexOutput) -> @location(0) vec4<f32> {
  let base_color = textureSampleLevel(input_texture, input_sampler, in.uv, 0.0).rgb;
  let enabled = uniforms.params1.w;
  let intensity = max(uniforms.params0.x, 0.0);
  if enabled < 0.5 || intensity <= 0.00001 {
    return vec4<f32>(base_color, 1.0);
  }

  let threshold = max(uniforms.params1.x, 0.0);
  let threshold_softness = clamp(uniforms.params1.y, 0.0, 1.0);
  let composite_mode = if uniforms.params1.z >= 0.5 { 1.0 } else { 0.0 };
  let scale_xy = vec2<f32>(
    max(uniforms.params2.x, 0.0),
    max(uniforms.params2.y, 0.0),
  );
  let view_size = vec2<f32>(
    max(uniforms.params3.x, 1.0),
    max(uniforms.params3.y, 1.0),
  );
  let max_mip_dimension = max(uniforms.params2.z, 4.0);
  let dimension_limited = min(max(view_size.x, view_size.y), max_mip_dimension);
  let mip_count = max(floor(log2(dimension_limited)) - 1.0, 1.0);
  let max_mip = max(mip_count - 1.0, 1.0);

  var bloom_accum = vec3<f32>(0.0, 0.0, 0.0);
  var bloom_weight_total = 0.0;
  for (var mip_i = 0; mip_i < MAX_MIPS; mip_i = mip_i + 1) {
    let mip = f32(mip_i);
    if mip >= mip_count {
      continue;
    }
    let radius = exp2(mip);
    let sample_scale = vec2<f32>(
      max(scale_xy.x * radius, 0.0001),
      max(scale_xy.y * radius, 0.0001),
    );
    var sample = sample_input_13_tap_scaled(in.uv, sample_scale);
    if mip_i == 0 {
      sample = soft_threshold(sample, threshold, threshold_softness);
    }
    let blend = compute_blend_factor(
      mip,
      max_mip,
      intensity,
      clamp(uniforms.params0.y, 0.0, 1.0),
      clamp(uniforms.params0.z, 0.0, 1.0),
      clamp(uniforms.params0.w, 0.0, 1.0),
      composite_mode,
    );
    bloom_accum += sample * blend;
    bloom_weight_total += blend;
  }

  if bloom_weight_total <= 0.00001 {
    return vec4<f32>(base_color, 1.0);
  }
  let bloom_color = bloom_accum / bloom_weight_total;
  let final_blend = compute_blend_factor(
    0.0,
    max_mip,
    intensity,
    clamp(uniforms.params0.y, 0.0, 1.0),
    clamp(uniforms.params0.z, 0.0, 1.0),
    clamp(uniforms.params0.w, 0.0, 1.0),
    composite_mode,
  );
  let out_color = if composite_mode < 0.5 {
    mix(base_color, bloom_color, clamp(final_blend, 0.0, 1.0))
  } else {
    base_color + bloom_color * max(final_blend, 0.0)
  };
  return vec4<f32>(out_color, 1.0);
}
