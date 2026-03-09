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
    exposure: f32,
    // x: tonemapping mode, y: deband dither enabled, z: bloom weight, w: upsample blend factor
    options: vec4<f32>,
    // x: fxaa enabled, y: fxaa edge threshold, z: chromatic aberration strength, w: vignette strength
    postprocess: vec4<f32>,
};

@group(0) @binding(0) var hdr_texture: texture_2d<f32>;
@group(0) @binding(1) var hdr_sampler: sampler;
@group(0) @binding(2) var<uniform> uniforms: BloomUniforms;
@group(0) @binding(3) var scene_texture: texture_2d<f32>;
// KTX2 LUTs are uploaded as vertically stacked 2D slices.
@group(0) @binding(4) var dt_lut_texture: texture_2d<f32>;

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

fn convert_open_domain_to_normalized_log2(
    color: vec3<f32>,
    minimum_ev: f32,
    maximum_ev: f32,
) -> vec3<f32> {
    let in_midgray = 0.18;
    var normalized = max(vec3<f32>(0.0), color);
    normalized = select(
        normalized,
        0.00001525878 + normalized,
        normalized < vec3<f32>(0.00003051757),
    );
    normalized = clamp(
        log2(normalized / in_midgray),
        vec3<f32>(minimum_ev),
        vec3<f32>(maximum_ev),
    );
    let total_exposure = maximum_ev - minimum_ev;
    return (normalized - minimum_ev) / total_exposure;
}

fn apply_agx_log(image: vec3<f32>) -> vec3<f32> {
    var prepared_image = max(vec3<f32>(0.0), image);
    let r = dot(prepared_image, vec3<f32>(0.84247906, 0.0784336, 0.07922375));
    let g = dot(prepared_image, vec3<f32>(0.04232824, 0.87846864, 0.07916613));
    let b = dot(prepared_image, vec3<f32>(0.04237565, 0.0784336, 0.87914297));
    prepared_image = vec3<f32>(r, g, b);
    prepared_image = convert_open_domain_to_normalized_log2(prepared_image, -10.0, 6.5);
    return clamp(prepared_image, vec3<f32>(0.0), vec3<f32>(1.0));
}

fn lut_is_ready() -> bool {
    let dims = textureDimensions(dt_lut_texture);
    return dims.x > 1u && dims.y > dims.x;
}

fn sample_current_lut(p: vec3<f32>) -> vec3<f32> {
    let dims = textureDimensions(dt_lut_texture);
    if dims.x <= 1u || dims.y <= dims.x {
        return p;
    }
    let lut_size = f32(dims.x);
    let slice_count = f32(dims.y) / lut_size;
    let uv_xy = clamp(p.xy, vec2<f32>(0.0), vec2<f32>(1.0))
        * ((lut_size - 1.0) / lut_size)
        + vec2<f32>(0.5 / lut_size);
    let z = clamp(p.z, 0.0, 1.0) * (slice_count - 1.0);
    let z0 = floor(z);
    let z1 = min(z0 + 1.0, slice_count - 1.0);
    let zf = z - z0;
    let uv0 = vec2<f32>(uv_xy.x, (uv_xy.y + z0) / slice_count);
    let uv1 = vec2<f32>(uv_xy.x, (uv_xy.y + z1) / slice_count);
    let c0 = textureSampleLevel(dt_lut_texture, hdr_sampler, uv0, 0.0).rgb;
    let c1 = textureSampleLevel(dt_lut_texture, hdr_sampler, uv1, 0.0).rgb;
    return mix(c0, c1, vec3<f32>(zf));
}

fn apply_lut3d(image: vec3<f32>, block_size: f32) -> vec3<f32> {
    let encoded = image * ((block_size - 1.0) / block_size) + vec3<f32>(0.5 / block_size);
    return sample_current_lut(encoded);
}

const TONY_MC_MAPFACE_LUT_DIMS: f32 = 48.0;

fn sample_tony_mc_mapface_lut(stimulus: vec3<f32>) -> vec3<f32> {
    let uv = (stimulus / (stimulus + vec3<f32>(1.0)))
        * ((TONY_MC_MAPFACE_LUT_DIMS - 1.0) / TONY_MC_MAPFACE_LUT_DIMS)
        + vec3<f32>(0.5 / TONY_MC_MAPFACE_LUT_DIMS);
    return sample_current_lut(clamp(uv, vec3<f32>(0.0), vec3<f32>(1.0)));
}

fn sample_blender_filmic_lut(stimulus: vec3<f32>) -> vec3<f32> {
    let normalized = clamp(
        convert_open_domain_to_normalized_log2(stimulus, -11.0, 12.0),
        vec3<f32>(0.0),
        vec3<f32>(1.0),
    );
    return apply_lut3d(normalized, 64.0);
}

fn screen_space_dither(frag_coord: vec2<f32>) -> vec3<f32> {
    var dither = vec3<f32>(dot(vec2<f32>(171.0, 231.0), frag_coord)).xxx;
    dither = fract(dither.rgb / vec3<f32>(103.0, 71.0, 97.0));
    return (dither - 0.5) / 255.0;
}

fn tonemap_color(color: vec3<f32>, mode: f32) -> vec3<f32> {
    let hdr = max(color, vec3<f32>(0.0));
    if mode < 0.5 {
        return hdr;
    }
    if mode < 1.5 {
        return tonemapping_reinhard(hdr);
    }
    if mode < 2.5 {
        return tonemapping_reinhard_luminance(hdr);
    }
    if mode < 3.5 {
        return aces_fitted(hdr);
    }
    if mode < 4.5 {
        if !lut_is_ready() {
            return somewhat_boring_display_transform(hdr);
        }
        return apply_lut3d(apply_agx_log(hdr), 32.0);
    }
    if mode < 5.5 {
        return somewhat_boring_display_transform(hdr);
    }
    if mode < 6.5 {
        if !lut_is_ready() {
            return somewhat_boring_display_transform(hdr);
        }
        return sample_tony_mc_mapface_lut(hdr);
    }
    if !lut_is_ready() {
        return somewhat_boring_display_transform(hdr);
    }
    return sample_blender_filmic_lut(hdr);
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

fn sample_scene_with_chromatic(uv: vec2<f32>) -> vec3<f32> {
    let chromatic_strength = max(uniforms.postprocess.z, 0.0);
    if chromatic_strength <= 0.00001 {
        return textureSample(scene_texture, hdr_sampler, uv).rgb;
    }

    let inv_dims = 1.0
        / max(vec2<f32>(textureDimensions(scene_texture)), vec2<f32>(1.0));
    let centered = uv * 2.0 - vec2<f32>(1.0);
    let radial = dot(centered, centered);
    let offset = centered * chromatic_strength * radial * inv_dims;
    let uv_r = clamp(uv + offset, vec2<f32>(0.0), vec2<f32>(1.0));
    let uv_b = clamp(uv - offset, vec2<f32>(0.0), vec2<f32>(1.0));
    let red = textureSample(scene_texture, hdr_sampler, uv_r).r;
    let green = textureSample(scene_texture, hdr_sampler, uv).g;
    let blue = textureSample(scene_texture, hdr_sampler, uv_b).b;
    return vec3<f32>(red, green, blue);
}

fn sample_tonemapped_scene_for_fxaa(uv: vec2<f32>) -> vec3<f32> {
    let clamped_uv = clamp(uv, vec2<f32>(0.0), vec2<f32>(1.0));
    // Use explicit LOD so this call is valid under non-uniform FXAA control flow.
    let scene_color = textureSampleLevel(scene_texture, hdr_sampler, clamped_uv, 0.0).rgb;
    let exposure = max(uniforms.exposure, 0.0);
    return tonemap_color(scene_color * exposure, uniforms.options.x);
}

fn apply_lightweight_fxaa(uv: vec2<f32>, base_color: vec3<f32>) -> vec3<f32> {
    if uniforms.postprocess.x <= 0.5 {
        return base_color;
    }

    let edge_threshold = clamp(uniforms.postprocess.y, 0.01, 0.333);
    let inv_dims = 1.0
        / max(vec2<f32>(textureDimensions(scene_texture)), vec2<f32>(1.0));
    let rgb_nw = sample_tonemapped_scene_for_fxaa(uv + vec2<f32>(-1.0, -1.0) * inv_dims);
    let rgb_ne = sample_tonemapped_scene_for_fxaa(uv + vec2<f32>(1.0, -1.0) * inv_dims);
    let rgb_sw = sample_tonemapped_scene_for_fxaa(uv + vec2<f32>(-1.0, 1.0) * inv_dims);
    let rgb_se = sample_tonemapped_scene_for_fxaa(uv + vec2<f32>(1.0, 1.0) * inv_dims);

    let luma_nw = tonemapping_luminance(rgb_nw);
    let luma_ne = tonemapping_luminance(rgb_ne);
    let luma_sw = tonemapping_luminance(rgb_sw);
    let luma_se = tonemapping_luminance(rgb_se);
    let luma_m = tonemapping_luminance(base_color);
    let luma_min = min(luma_m, min(min(luma_nw, luma_ne), min(luma_sw, luma_se)));
    let luma_max = max(luma_m, max(max(luma_nw, luma_ne), max(luma_sw, luma_se)));
    let contrast = luma_max - luma_min;
    if contrast < edge_threshold * max(luma_max, 0.001) {
        return base_color;
    }

    var dir = vec2<f32>(
        -((luma_nw + luma_ne) - (luma_sw + luma_se)),
        (luma_nw + luma_sw) - (luma_ne + luma_se),
    );
    let dir_reduce = max((luma_nw + luma_ne + luma_sw + luma_se) * 0.03125, 1.0 / 128.0);
    let rcp_dir_min = 1.0 / (min(abs(dir.x), abs(dir.y)) + dir_reduce);
    dir = clamp(dir * rcp_dir_min, vec2<f32>(-8.0), vec2<f32>(8.0)) * inv_dims;

    let rgb_a = 0.5 * (
        sample_tonemapped_scene_for_fxaa(uv + dir * (1.0 / 3.0 - 0.5))
            + sample_tonemapped_scene_for_fxaa(uv + dir * (2.0 / 3.0 - 0.5))
    );
    let rgb_b = rgb_a * 0.5 + 0.25 * (
        sample_tonemapped_scene_for_fxaa(uv + dir * -0.5)
            + sample_tonemapped_scene_for_fxaa(uv + dir * 0.5)
    );
    let luma_b = tonemapping_luminance(rgb_b);
    if luma_b < luma_min || luma_b > luma_max {
        return rgb_a;
    }
    return rgb_b;
}

fn apply_vignette(color: vec3<f32>, uv: vec2<f32>) -> vec3<f32> {
    let strength = clamp(uniforms.postprocess.w, 0.0, 1.0);
    if strength <= 0.00001 {
        return color;
    }

    let centered = vec2<f32>(
        (uv.x - 0.5) * 2.0 * max(uniforms.aspect, 0.00001),
        (uv.y - 0.5) * 2.0,
    );
    let dist = dot(centered, centered);
    let vignette = 1.0 - smoothstep(0.35, 1.0, dist) * strength;
    return color * max(vignette, 0.0);
}

@fragment
fn final_fragment(
    @location(0) uv: vec2<f32>,
    @builtin(position) position: vec4<f32>,
) -> @location(0) vec4<f32> {
    let bloom_color = sample_input_3x3_tent(uv) * uniforms.options.z;
    let scene_color = sample_scene_with_chromatic(uv);
    let exposure = max(uniforms.exposure, 0.0);
    var output_rgb = tonemap_color(
        (scene_color + bloom_color) * exposure,
        uniforms.options.x,
    );
    output_rgb = apply_lightweight_fxaa(uv, output_rgb);
    output_rgb = apply_vignette(output_rgb, uv);

    if uniforms.options.y > 0.5 {
        var dither_rgb = pow(max(output_rgb, vec3<f32>(0.0)), vec3<f32>(1.0 / 2.2));
        dither_rgb = dither_rgb + screen_space_dither(position.xy);
        output_rgb = pow(max(dither_rgb, vec3<f32>(0.0)), vec3<f32>(2.2));
    }

    return vec4<f32>(output_rgb, 1.0);
}
