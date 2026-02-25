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

// Bloom works by creating an intermediate texture with a bunch of mip levels, each half the size of the previous.
// You then downsample each mip (starting with the original texture) to the lower resolution mip under it, going in order.
// You then upsample each mip (starting from the smallest mip) and blend with the higher resolution mip above it (ending on the original texture).
//
// References:
// * [COD] - Next Generation Post Processing in Call of Duty - http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
// * [PBB] - Physically Based Bloom - https://learnopengl.com/Guest-Articles/2022/Phys.-Based-Bloom

struct BloomUniforms {
    threshold_precomputations: vec4<f32>,
    viewport: vec4<f32>,
    scale: vec2<f32>,
    aspect: f32,
    _padding: f32,
    options: vec4<f32>, // x: tonemapping mode, y: deband dither enabled
};

@group(0) @binding(0) var input_texture: texture_2d<f32>;
@group(0) @binding(1) var s: sampler;

@group(0) @binding(2) var<uniform> uniforms: BloomUniforms;
@group(0) @binding(3) var scene_texture: texture_2d<f32>;

#ifdef FIRST_DOWNSAMPLE
// https://catlikecoding.com/unity/tutorials/advanced-rendering/bloom/#3.4
fn soft_threshold(color: vec3<f32>) -> vec3<f32> {
    let brightness = max(color.r, max(color.g, color.b));
    var softness = brightness - uniforms.threshold_precomputations.y;
    softness = clamp(softness, 0.0, uniforms.threshold_precomputations.z);
    softness = softness * softness * uniforms.threshold_precomputations.w;
    var contribution = max(brightness - uniforms.threshold_precomputations.x, softness);
    contribution /= max(brightness, 0.00001); // Prevent division by 0
    return color * contribution;
}
#endif

// luminance coefficients from Rec. 709.
// https://en.wikipedia.org/wiki/Rec._709
fn tonemapping_luminance(v: vec3<f32>) -> f32 {
    return dot(v, vec3<f32>(0.2126, 0.7152, 0.0722));
}

// http://graphicrants.blogspot.com/2013/12/tone-mapping.html
fn karis_average(color: vec3<f32>) -> f32 {
    // Luminance calculated based on Rec. 709 color primaries.
    // This must be done in *linear* color space.
    let luma = tonemapping_luminance(color) / 4.0;
    return 1.0 / (1.0 + luma);
}

// [COD] slide 153
fn sample_input_13_tap(uv: vec2<f32>) -> vec3<f32> {
#ifdef UNIFORM_SCALE
    // This is the fast path. When the bloom scale is uniform, the 13 tap sampling kernel can be
    // expressed with constant offsets.
    //
    // It's possible that this isn't meaningfully faster than the "slow" path. However, because it
    // is hard to test performance on all platforms, and uniform bloom is the most common case, this
    // path was retained when adding non-uniform (anamorphic) bloom. This adds a small, but nonzero,
    // cost to maintainability, but it does help me sleep at night.
    let a = textureSample(input_texture, s, uv, vec2<i32>(-2, 2)).rgb;
    let b = textureSample(input_texture, s, uv, vec2<i32>(0, 2)).rgb;
    let c = textureSample(input_texture, s, uv, vec2<i32>(2, 2)).rgb;
    let d = textureSample(input_texture, s, uv, vec2<i32>(-2, 0)).rgb;
    let e = textureSample(input_texture, s, uv).rgb;
    let f = textureSample(input_texture, s, uv, vec2<i32>(2, 0)).rgb;
    let g = textureSample(input_texture, s, uv, vec2<i32>(-2, -2)).rgb;
    let h = textureSample(input_texture, s, uv, vec2<i32>(0, -2)).rgb;
    let i = textureSample(input_texture, s, uv, vec2<i32>(2, -2)).rgb;
    let j = textureSample(input_texture, s, uv, vec2<i32>(-1, 1)).rgb;
    let k = textureSample(input_texture, s, uv, vec2<i32>(1, 1)).rgb;
    let l = textureSample(input_texture, s, uv, vec2<i32>(-1, -1)).rgb;
    let m = textureSample(input_texture, s, uv, vec2<i32>(1, -1)).rgb;
#else
    // This is the flexible, but potentially slower, path for non-uniform sampling. Because the
    // sample is not a constant, and it can fall outside of the limits imposed on constant sample
    // offsets (-8..8), we have to compute the pixel offset in uv coordinates using the size of the
    // texture.
    //
    // It isn't clear if this is meaningfully slower than using the offset syntax, the spec doesn't
    // mention it anywhere: https://www.w3.org/TR/WGSL/#texturesample, but the fact that the offset
    // syntax uses a const-expr implies that it allows some compiler optimizations - maybe more
    // impactful on mobile?
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
#endif

#ifdef FIRST_DOWNSAMPLE
    // [COD] slide 168
    //
    // The first downsample pass reads from the rendered frame which may exhibit
    // 'fireflies' (individual very bright pixels) that should not cause the bloom effect.
    //
    // The first downsample uses a firefly-reduction method proposed by Brian Karis
    // which takes a weighted-average of the samples to limit their luma range to [0, 1].
    // This implementation matches the LearnOpenGL article [PBB].
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
#else
    var sample = (a + c + g + i) * 0.03125;
    sample += (b + d + f + h) * 0.0625;
    sample += (e + j + k + l + m) * 0.125;
    return sample;
#endif
}

// [COD] slide 162
fn sample_input_3x3_tent(uv: vec2<f32>) -> vec3<f32> {
    // While this is probably technically incorrect, it makes nonuniform bloom smoother, without
    // having any impact on uniform bloom, which simply evaluates to 1.0 here.
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

fn tonemapping_change_luminance(c_in: vec3<f32>, l_out: f32) -> vec3<f32> {
    let l_in = tonemapping_luminance(c_in);
    return c_in * (l_out / max(l_in, 0.00001));
}

fn tonemapping_reinhard(color: vec3<f32>) -> vec3<f32> {
    return color / (1.0 + color);
}

fn tonemapping_reinhard_luminance(color: vec3<f32>) -> vec3<f32> {
    let l_old = tonemapping_luminance(color);
    let l_new = l_old / (1.0 + l_old);
    return tonemapping_change_luminance(color, l_new);
}

fn rrt_and_odt_fit(v: vec3<f32>) -> vec3<f32> {
    let a = v * (v + 0.0245786) - 0.000090537;
    let b = v * (0.983729 * v + 0.4329510) + 0.238081;
    return a / b;
}

fn aces_fitted(color: vec3<f32>) -> vec3<f32> {
    var fitted_color = color;
    let rgb_to_rrt = mat3x3<f32>(
        vec3<f32>(0.59719, 0.35458, 0.04823),
        vec3<f32>(0.07600, 0.90834, 0.01566),
        vec3<f32>(0.02840, 0.13383, 0.83777),
    );
    let odt_to_rgb = mat3x3<f32>(
        vec3<f32>(1.60475, -0.53108, -0.07367),
        vec3<f32>(-0.10208, 1.10813, -0.00605),
        vec3<f32>(-0.00327, -0.07276, 1.07602),
    );
    fitted_color = rgb_to_rrt * fitted_color;
    fitted_color = rrt_and_odt_fit(fitted_color);
    fitted_color = odt_to_rgb * fitted_color;
    return clamp(fitted_color, vec3<f32>(0.0), vec3<f32>(1.0));
}

fn rgb_to_ycbcr(col: vec3<f32>) -> vec3<f32> {
    let m = mat3x3<f32>(
        vec3<f32>(0.2126, 0.7152, 0.0722),
        vec3<f32>(-0.1146, -0.3854, 0.5),
        vec3<f32>(0.5, -0.4542, -0.0458),
    );
    return m * col;
}

fn tonemap_curve(v: f32) -> f32 {
    return 1.0 - exp(-v);
}

fn tonemap_curve3(v: vec3<f32>) -> vec3<f32> {
    return vec3<f32>(tonemap_curve(v.r), tonemap_curve(v.g), tonemap_curve(v.b));
}

fn somewhat_boring_display_transform(col: vec3<f32>) -> vec3<f32> {
    var boring_color = col;
    let ycbcr = rgb_to_ycbcr(boring_color);
    let bt = tonemap_curve(length(ycbcr.yz) * 2.4);
    var desat = max((bt - 0.7) * 0.8, 0.0);
    desat = desat * desat;
    let desat_col = mix(boring_color.rgb, ycbcr.xxx, vec3<f32>(desat));
    let tm_luma = tonemap_curve(ycbcr.x);
    let tm0 = boring_color.rgb * max(0.0, tm_luma / max(1e-5, tonemapping_luminance(boring_color.rgb)));
    let tm1 = tonemap_curve3(desat_col);
    boring_color = mix(tm0, tm1, vec3<f32>(bt * bt));
    return boring_color * 0.97;
}

fn screen_space_dither(frag_coord: vec2<f32>) -> vec3<f32> {
    var dither = vec3<f32>(dot(vec2<f32>(171.0, 231.0), frag_coord)).xxx;
    dither = fract(dither.rgb / vec3<f32>(103.0, 71.0, 97.0));
    return (dither - 0.5) / 255.0;
}

fn tonemap_color(color: vec3<f32>, mode: f32) -> vec3<f32> {
    // Bevy's AgX/TonyMcMapface/BlenderFilmic require 3D LUTs.
    // Until LUT path is wired for this bloom final pass, we keep these mapped to ACES.
    if mode < 0.5 {
        return max(color, vec3<f32>(0.0));
    }
    if mode < 1.5 {
        return tonemapping_reinhard(max(color, vec3<f32>(0.0)));
    }
    if mode < 2.5 {
        return tonemapping_reinhard_luminance(max(color, vec3<f32>(0.0)));
    }
    if mode < 3.5 {
        return aces_fitted(max(color, vec3<f32>(0.0)));
    }
    if mode < 4.5 {
        return aces_fitted(max(color, vec3<f32>(0.0)));
    }
    if mode < 5.5 {
        return somewhat_boring_display_transform(max(color, vec3<f32>(0.0)));
    }
    if mode < 6.5 {
        return aces_fitted(max(color, vec3<f32>(0.0)));
    }
    return aces_fitted(max(color, vec3<f32>(0.0)));
}

#ifdef FIRST_DOWNSAMPLE
@fragment
fn downsample_first(@location(0) output_uv: vec2<f32>) -> @location(0) vec4<f32> {
    let sample_uv = uniforms.viewport.xy + output_uv * uniforms.viewport.zw;
    var sample = sample_input_13_tap(sample_uv);
    // Lower bound of 0.0001 is to avoid propagating multiplying by 0.0 through the
    // downscaling and upscaling which would result in black boxes.
    // The upper bound is to prevent NaNs.
    // with f32::MAX (E+38) Chrome fails with ":value 340282346999999984391321947108527833088.0 cannot be represented as 'f32'"
    sample = clamp(sample, vec3<f32>(0.0001), vec3<f32>(3.40282347E+37));

#ifdef USE_THRESHOLD
    sample = soft_threshold(sample);
#endif

    return vec4<f32>(sample, 1.0);
}
#endif

@fragment
fn downsample(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    return vec4<f32>(sample_input_13_tap(uv), 1.0);
}

@fragment
fn upsample(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    return vec4<f32>(sample_input_3x3_tent(uv), 1.0);
}

@fragment
fn fragment(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    return vec4<f32>(sample_input_3x3_tent(uv), 1.0);
}

@fragment
fn final_fragment(
    @location(0) uv: vec2<f32>,
    @builtin(position) position: vec4<f32>,
) -> @location(0) vec4<f32> {
    let bloom_color = sample_input_3x3_tent(uv);
    let scene_color = textureSample(scene_texture, s, uv).rgb;
    var output_rgb = tonemap_color(scene_color + bloom_color, uniforms.options.x);
    if uniforms.options.y > 0.5 {
        var dither_rgb = pow(max(output_rgb, vec3<f32>(0.0)), vec3<f32>(1.0 / 2.2));
        dither_rgb = dither_rgb + screen_space_dither(position.xy);
        output_rgb = pow(max(dither_rgb, vec3<f32>(0.0)), vec3<f32>(2.2));
    }
    return vec4<f32>(output_rgb, 1.0);
}
