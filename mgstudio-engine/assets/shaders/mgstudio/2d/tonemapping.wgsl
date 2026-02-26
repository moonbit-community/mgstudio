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
// Derived from Bevy:
// - bevy/crates/bevy_core_pipeline/src/tonemapping/tonemapping.wgsl
// - bevy/crates/bevy_core_pipeline/src/tonemapping/tonemapping_shared.wgsl

#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput

struct BloomUniforms {
    threshold_precomputations: vec4<f32>,
    viewport: vec4<f32>,
    scale: vec2<f32>,
    aspect: f32,
    _padding: f32,
    // x: tonemapping mode, y: deband dither enabled, z: bloom weight
    options: vec4<f32>,
};

@group(0) @binding(0) var hdr_texture: texture_2d<f32>;
@group(0) @binding(1) var hdr_sampler: sampler;
@group(0) @binding(2) var<uniform> uniforms: BloomUniforms;
@group(0) @binding(3) var scene_texture: texture_2d<f32>;

fn tonemapping_luminance(v: vec3<f32>) -> f32 {
    return dot(v, vec3<f32>(0.2126, 0.7152, 0.0722));
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
    // Bevy's AgX/TonyMcMapface/BlenderFilmic paths require LUT textures.
    // Current runtime falls back to Bevy's SBDT branch until LUT bindings are wired.
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
        return somewhat_boring_display_transform(max(color, vec3<f32>(0.0)));
    }
    if mode < 5.5 {
        return somewhat_boring_display_transform(max(color, vec3<f32>(0.0)));
    }
    if mode < 6.5 {
        return somewhat_boring_display_transform(max(color, vec3<f32>(0.0)));
    }
    return somewhat_boring_display_transform(max(color, vec3<f32>(0.0)));
}

fn sample_input_3x3_tent(uv: vec2<f32>) -> vec3<f32> {
    let frag_size = uniforms.scale / vec2<f32>(textureDimensions(hdr_texture));
    let x = frag_size.x;
    let y = frag_size.y;

    let a = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x - x, uv.y + y)).rgb;
    let b = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x, uv.y + y)).rgb;
    let c = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x + x, uv.y + y)).rgb;

    let d = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x - x, uv.y)).rgb;
    let e = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x, uv.y)).rgb;
    let f = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x + x, uv.y)).rgb;

    let g = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x - x, uv.y - y)).rgb;
    let h = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x, uv.y - y)).rgb;
    let i = textureSample(hdr_texture, hdr_sampler, vec2<f32>(uv.x + x, uv.y - y)).rgb;

    var sample = e * 0.25;
    sample += (b + d + f + h) * 0.125;
    sample += (a + c + g + i) * 0.0625;

    return sample;
}

@fragment
fn final_fragment(
    @location(0) uv: vec2<f32>,
    @builtin(position) position: vec4<f32>,
) -> @location(0) vec4<f32> {
    let bloom_color = sample_input_3x3_tent(uv) * uniforms.options.z;
    let scene_color = textureSample(scene_texture, hdr_sampler, uv).rgb;
    var output_rgb = tonemap_color(scene_color + bloom_color, uniforms.options.x);

    if uniforms.options.y > 0.5 {
        var dither_rgb = pow(max(output_rgb, vec3<f32>(0.0)), vec3<f32>(1.0 / 2.2));
        dither_rgb = dither_rgb + screen_space_dither(position.xy);
        output_rgb = pow(max(dither_rgb, vec3<f32>(0.0)), vec3<f32>(2.2));
    }

    return vec4<f32>(output_rgb, 1.0);
}
