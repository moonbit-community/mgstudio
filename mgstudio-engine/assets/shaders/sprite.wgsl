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

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) uv : vec2<f32>,
};

struct TransformData {
  model : vec4<f32>,
  view : vec4<f32>,
  scale : vec4<f32>,
  color : vec4<f32>,
  uv : vec4<f32>,
};

@group(0) @binding(0) var samp : sampler;
@group(0) @binding(1) var tex : texture_2d<f32>;
@group(0) @binding(2) var<uniform> u_transform : TransformData;

@vertex
fn vs_main(
  @location(0) position : vec2<f32>,
  @location(1) uv : vec2<f32>
) -> VertexOut {
  var out : VertexOut;
  let cosv = u_transform.model.z;
  let sinv = u_transform.model.w;
  let scaled = vec2<f32>(
    position.x * u_transform.scale.z,
    position.y * u_transform.scale.w
  );
  let rotated = vec2<f32>(
    scaled.x * cosv - scaled.y * sinv,
    scaled.x * sinv + scaled.y * cosv
  );
  let translated = rotated + u_transform.model.xy;
  let cam_cos = u_transform.view.z;
  let cam_sin = u_transform.view.w;
  let rel = translated - u_transform.view.xy;
  let view_pos = vec2<f32>(
    rel.x * cam_cos - rel.y * cam_sin,
    rel.x * cam_sin + rel.y * cam_cos
  );
  let ndc = vec2<f32>(
    view_pos.x * u_transform.scale.x,
    view_pos.y * u_transform.scale.y
  );
  out.position = vec4<f32>(ndc, 0.0, 1.0);
  out.uv = u_transform.uv.xy + uv * u_transform.uv.zw;
  return out;
}

@fragment
fn fs_main(@location(0) uv : vec2<f32>) -> @location(0) vec4<f32> {
  return textureSample(tex, samp, uv) * u_transform.color;
}
