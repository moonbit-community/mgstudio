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
//
// Derived from Bevy:
// - bevy/crates/bevy_post_process/src/auto_exposure/auto_exposure.wgsl

const RGB_TO_LUM = vec3<f32>(0.2125, 0.7154, 0.0721);
const HISTOGRAM_BIN_COUNT : u32 = 64u;

struct AutoExposureSettings {
    min_log_lum: f32,
    inv_log_lum_range: f32,
    log_lum_range: f32,
    low_percent: f32,
    high_percent: f32,
    speed_up: f32,
    speed_down: f32,
    exponential_transition_distance: f32,
    delta_time: f32,
    _pad0: f32,
    _pad1: f32,
    _pad2: f32,
}

struct CompensationCurve {
    min_log_lum: f32,
    inv_log_lum_range: f32,
    min_compensation: f32,
    compensation_range: f32,
}

struct AutoExposureState {
    exposure: f32,
}

@group(0) @binding(0) var<uniform> settings: AutoExposureSettings;
@group(0) @binding(1) var tex_color: texture_2d<f32>;
@group(0) @binding(2) var tex_mask: texture_2d<f32>;
@group(0) @binding(3) var tex_compensation: texture_1d<f32>;
@group(0) @binding(4) var<uniform> compensation_curve: CompensationCurve;
@group(0) @binding(5) var<storage, read_write> histogram: array<atomic<u32>, 64>;
@group(0) @binding(6) var<storage, read_write> state: AutoExposureState;

var<workgroup> histogram_shared: array<atomic<u32>, 64>;

fn color_to_bin(hdr: vec3<f32>) -> u32 {
    let lum = dot(hdr, RGB_TO_LUM);
    if lum < exp2(settings.min_log_lum) {
        return 0u;
    }
    let log_lum = clamp(
        (log2(lum) - settings.min_log_lum) * settings.inv_log_lum_range,
        0.0,
        1.0,
    );
    return u32(log_lum * 62.0 + 1.0);
}

fn metering_weight(coords: vec2<f32>) -> u32 {
    let dims = textureDimensions(tex_mask);
    let dim = max(vec2<f32>(vec2<u32>(1u, 1u)), vec2<f32>(dims));
    let pos = min(vec2<i32>(coords * dim), vec2<i32>(dims) - vec2<i32>(1, 1));
    let mask = textureLoad(tex_mask, pos, 0).r;
    return u32(mask * 16.0);
}
