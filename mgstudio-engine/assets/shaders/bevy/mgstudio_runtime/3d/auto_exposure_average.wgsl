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

#import mgstudio::3d::auto_exposure_shared::{
    compensation_curve,
    histogram,
    histogram_shared,
    settings,
    state,
    tex_compensation,
}

@compute @workgroup_size(1, 1, 1)
fn main() {
    var histogram_sum = 0u;
    for (var i = 0u; i < 64u; i += 1u) {
        histogram_sum += atomicLoad(&histogram[i]);
        histogram_shared[i] = histogram_sum;
        atomicStore(&histogram[i], 0u);
    }

    let first_index = u32(f32(histogram_sum) * settings.low_percent);
    let last_index = u32(f32(histogram_sum) * settings.high_percent);

    var count = 0u;
    var sum = 0.0;
    for (var i = 1u; i < 64u; i += 1u) {
        let bin_count =
            clamp(atomicLoad(&histogram_shared[i]), first_index, last_index) -
            clamp(atomicLoad(&histogram_shared[i - 1u]), first_index, last_index);
        sum += f32(bin_count) * f32(i);
        count += bin_count;
    }

    var avg_lum = settings.min_log_lum;
    if count > 0u {
        avg_lum = sum / (f32(count) * 63.0) * settings.log_lum_range + settings.min_log_lum;
    }

    let u = clamp(
        (avg_lum - compensation_curve.min_log_lum) * compensation_curve.inv_log_lum_range,
        0.0,
        1.0,
    );
    let compensation = textureLoad(tex_compensation, i32(u * 255.0), 0).r
        * compensation_curve.compensation_range
        + compensation_curve.min_compensation;
    let target_exposure = compensation - avg_lum;
    let delta = target_exposure - state.exposure;

    if target_exposure > state.exposure {
        let speed_down = settings.speed_down * settings.delta_time;
        let exp_down = speed_down / settings.exponential_transition_distance;
        state.exposure = state.exposure + min(speed_down, delta * exp_down);
    } else {
        let speed_up = settings.speed_up * settings.delta_time;
        let exp_up = speed_up / settings.exponential_transition_distance;
        state.exposure = state.exposure + max(-speed_up, delta * exp_up);
    }
}
