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

struct BloomUniforms {
    threshold_precomputations: vec4<f32>,
    viewport: vec4<f32>,
    scale: vec2<f32>,
    aspect: f32,
};

@group(0) @binding(0) var input_texture: texture_2d<f32>;
@group(0) @binding(1) var s: sampler;
@group(0) @binding(2) var<uniform> uniforms: BloomUniforms;

// https://catlikecoding.com/unity/tutorials/advanced-rendering/bloom/#3.4
fn soft_threshold(color: vec3<f32>) -> vec3<f32> {
    let brightness = max(color.r, max(color.g, color.b));
    var softness = brightness - uniforms.threshold_precomputations.y;
    softness = clamp(softness, 0.0, uniforms.threshold_precomputations.z);
    softness = softness * softness * uniforms.threshold_precomputations.w;
    var contribution = max(brightness - uniforms.threshold_precomputations.x, softness);
    contribution /= max(brightness, 0.00001);
    return color * contribution;
}

fn tonemapping_luminance(v: vec3<f32>) -> f32 {
    return dot(v, vec3<f32>(0.2126, 0.7152, 0.0722));
}

fn karis_average(color: vec3<f32>) -> f32 {
    let luma = tonemapping_luminance(color) / 4.0;
    return 1.0 / (1.0 + luma);
}

fn sample_input_13_tap_core(uv: vec2<f32>) -> vec3<f32> {
    let scale = uniforms.scale;
    let ps = scale / vec2<f32>(textureDimensions(input_texture));
    let pl = 2.0 * ps;
    let ns = -1.0 * ps;
    let nl = -2.0 * ps;
    let a = textureSample(input_texture, s, uv + vec2<f32>(nl.x, pl.y)).rgb;
    let b = textureSample(input_texture, s, uv + vec2<f32>(0.00, pl.y)).rgb;
    let c = textureSample(input_texture, s, uv + vec2<f32>(pl.x, pl.y)).rgb;
    let d = textureSample(input_texture, s, uv + vec2<f32>(nl.x, 0.00)).rgb;
    let e = textureSample(input_texture, s, uv).rgb;
    let f = textureSample(input_texture, s, uv + vec2<f32>(pl.x, 0.00)).rgb;
    let g = textureSample(input_texture, s, uv + vec2<f32>(nl.x, nl.y)).rgb;
    let h = textureSample(input_texture, s, uv + vec2<f32>(0.00, nl.y)).rgb;
    let i = textureSample(input_texture, s, uv + vec2<f32>(pl.x, nl.y)).rgb;
    let j = textureSample(input_texture, s, uv + vec2<f32>(ns.x, ps.y)).rgb;
    let k = textureSample(input_texture, s, uv + vec2<f32>(ps.x, ps.y)).rgb;
    let l = textureSample(input_texture, s, uv + vec2<f32>(ns.x, ns.y)).rgb;
    let m = textureSample(input_texture, s, uv + vec2<f32>(ps.x, ns.y)).rgb;

    // [COD] slide 168
    var group0 = (a + b + d + e) * (0.125f / 4.0f);
    var group1 = (b + c + e + f) * (0.125f / 4.0f);
    var group2 = (d + e + g + h) * (0.125f / 4.0f);
    var group3 = (e + f + h + i) * (0.125f / 4.0f);
    var group4 = (j + k + l + m) * (0.5f / 4.0f);
    group0 *= karis_average(group0);
    group1 *= karis_average(group1);
    group2 *= karis_average(group2);
    group3 *= karis_average(group3);
    group4 *= karis_average(group4);
    return group0 + group1 + group2 + group3 + group4;
}

fn sample_input_13_tap(uv: vec2<f32>) -> vec3<f32> {
    let scale = uniforms.scale;
    let ps = scale / vec2<f32>(textureDimensions(input_texture));
    let pl = 2.0 * ps;
    let ns = -1.0 * ps;
    let nl = -2.0 * ps;
    let a = textureSample(input_texture, s, uv + vec2<f32>(nl.x, pl.y)).rgb;
    let b = textureSample(input_texture, s, uv + vec2<f32>(0.00, pl.y)).rgb;
    let c = textureSample(input_texture, s, uv + vec2<f32>(pl.x, pl.y)).rgb;
    let d = textureSample(input_texture, s, uv + vec2<f32>(nl.x, 0.00)).rgb;
    let e = textureSample(input_texture, s, uv).rgb;
    let f = textureSample(input_texture, s, uv + vec2<f32>(pl.x, 0.00)).rgb;
    let g = textureSample(input_texture, s, uv + vec2<f32>(nl.x, nl.y)).rgb;
    let h = textureSample(input_texture, s, uv + vec2<f32>(0.00, nl.y)).rgb;
    let i = textureSample(input_texture, s, uv + vec2<f32>(pl.x, nl.y)).rgb;
    let j = textureSample(input_texture, s, uv + vec2<f32>(ns.x, ps.y)).rgb;
    let k = textureSample(input_texture, s, uv + vec2<f32>(ps.x, ps.y)).rgb;
    let l = textureSample(input_texture, s, uv + vec2<f32>(ns.x, ns.y)).rgb;
    let m = textureSample(input_texture, s, uv + vec2<f32>(ps.x, ns.y)).rgb;

    var sample = (a + c + g + i) * 0.03125;
    sample += (b + d + f + h) * 0.0625;
    sample += (e + j + k + l + m) * 0.125;
    return sample;
}

fn sample_input_3x3_tent(uv: vec2<f32>) -> vec3<f32> {
    let frag_size = uniforms.scale / vec2<f32>(textureDimensions(input_texture));
    let x = frag_size.x;
    let y = frag_size.y;

    let a = textureSample(input_texture, s, vec2<f32>(uv.x - x, uv.y + y)).rgb;
    let b = textureSample(input_texture, s, vec2<f32>(uv.x, uv.y + y)).rgb;
    let c = textureSample(input_texture, s, vec2<f32>(uv.x + x, uv.y + y)).rgb;

    let d = textureSample(input_texture, s, vec2<f32>(uv.x - x, uv.y)).rgb;
    let e = textureSample(input_texture, s, vec2<f32>(uv.x, uv.y)).rgb;
    let f = textureSample(input_texture, s, vec2<f32>(uv.x + x, uv.y)).rgb;

    let g = textureSample(input_texture, s, vec2<f32>(uv.x - x, uv.y - y)).rgb;
    let h = textureSample(input_texture, s, vec2<f32>(uv.x, uv.y - y)).rgb;
    let i = textureSample(input_texture, s, vec2<f32>(uv.x + x, uv.y - y)).rgb;

    var sample = e * 0.25;
    sample += (b + d + f + h) * 0.125;
    sample += (a + c + g + i) * 0.0625;
    return sample;
}

@fragment
fn downsample_first(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let sample_uv = uniforms.viewport.xy + in.uv * uniforms.viewport.zw;
    var sample = sample_input_13_tap_core(sample_uv);
    sample = clamp(sample, vec3<f32>(0.0001), vec3<f32>(3.40282347E+37));
    sample = soft_threshold(sample);
    return vec4<f32>(sample, 1.0);
}

@fragment
fn downsample(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    return vec4<f32>(sample_input_13_tap(in.uv), 1.0);
}

@fragment
fn upsample(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    return vec4<f32>(sample_input_3x3_tent(in.uv), 1.0);
}
