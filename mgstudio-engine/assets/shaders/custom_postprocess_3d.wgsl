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

struct FullscreenVertexOutput {
  @builtin(position)
  position : vec4<f32>,
  @location(0)
  uv : vec2<f32>,
};

@group(0) @binding(0) var source_texture : texture_2d<f32>;
@group(0) @binding(1) var source_sampler : sampler;

struct CustomPostProcessParams {
  values : vec4<f32>,
};

@group(0) @binding(2) var<uniform> settings : CustomPostProcessParams;

@fragment
fn fragment_main(in : FullscreenVertexOutput) -> @location(0) vec4<f32> {
  let sampled = textureSample(source_texture, source_sampler, in.uv);
  let intensity = max(settings.values.x, 0.0);
  let offset_uv = in.uv - vec2<f32>(0.5, 0.5);
  let radial = clamp(length(offset_uv) * 1.6, 0.0, 1.0);
  let vignette = 1.0 - radial * 0.22;
  let tint = vec3<f32>(
    1.02 + intensity * 4.0,
    0.96 - intensity,
    1.04 + intensity * 2.0,
  );
  return vec4<f32>(sampled.rgb * tint * vignette, sampled.a);
}
