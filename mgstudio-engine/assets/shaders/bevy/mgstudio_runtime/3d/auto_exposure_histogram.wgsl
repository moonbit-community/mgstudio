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
    HISTOGRAM_BIN_COUNT,
    color_to_bin,
    histogram,
    histogram_shared,
    metering_weight,
    tex_color,
}

@compute @workgroup_size(16, 16, 1)
fn main(
    @builtin(global_invocation_id) global_invocation_id: vec3<u32>,
    @builtin(local_invocation_index) local_invocation_index: u32,
) {
    if local_invocation_index < HISTOGRAM_BIN_COUNT {
        histogram_shared[local_invocation_index] = 0u;
    }
    workgroupBarrier();

    let dim = vec2<u32>(textureDimensions(tex_color));
    let uv = vec2<f32>(global_invocation_id.xy) / max(vec2<f32>(dim), vec2<f32>(1.0, 1.0));

    if global_invocation_id.x < dim.x && global_invocation_id.y < dim.y {
        let color = textureLoad(tex_color, vec2<i32>(global_invocation_id.xy), 0).rgb;
        let index = color_to_bin(color);
        let weight = metering_weight(uv);
        atomicAdd(&histogram_shared[index], weight);
    }

    workgroupBarrier();

    if local_invocation_index < HISTOGRAM_BIN_COUNT {
        atomicAdd(
            &histogram[local_invocation_index],
            atomicLoad(&histogram_shared[local_invocation_index]),
        );
    }
}
