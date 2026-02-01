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
  @location(1) color : vec4<f32>,
};

struct Globals {
  view : vec4<f32>,
  ndc_scale : vec4<f32>,
};

struct InstanceData {
  model : vec4<f32>,
  scale : vec4<f32>,
  color : vec4<f32>,
  uv : vec4<f32>,
};

@group(0) @binding(0) var samp : sampler;
@group(0) @binding(1) var tex : texture_2d<f32>;
@group(1) @binding(0) var<uniform> u_globals : Globals;
@group(1) @binding(1) var<storage, read> instances : array<InstanceData>;

const QUAD_POS : array<vec2<f32>, 6> = array<vec2<f32>, 6>(
  vec2<f32>(-64.0, 64.0),
  vec2<f32>(-64.0, -64.0),
  vec2<f32>(64.0, -64.0),
  vec2<f32>(-64.0, 64.0),
  vec2<f32>(64.0, -64.0),
  vec2<f32>(64.0, 64.0),
);

const QUAD_UV : array<vec2<f32>, 6> = array<vec2<f32>, 6>(
  vec2<f32>(0.0, 0.0),
  vec2<f32>(0.0, 1.0),
  vec2<f32>(1.0, 1.0),
  vec2<f32>(0.0, 0.0),
  vec2<f32>(1.0, 1.0),
  vec2<f32>(1.0, 0.0),
);

@vertex
fn vs_main(
  @builtin(vertex_index) vertex_index : u32,
  @builtin(instance_index) instance_index : u32,
) -> VertexOut {
  var out : VertexOut;
  let inst = instances[instance_index];
  let position = QUAD_POS[vertex_index];
  let uv = QUAD_UV[vertex_index];
  let cosv = inst.model.z;
  let sinv = inst.model.w;
  let scaled = vec2<f32>(
    position.x * inst.scale.x,
    position.y * inst.scale.y
  );
  let rotated = vec2<f32>(
    scaled.x * cosv - scaled.y * sinv,
    scaled.x * sinv + scaled.y * cosv
  );
  let translated = rotated + inst.model.xy;
  let cam_cos = u_globals.view.z;
  let cam_sin = u_globals.view.w;
  let rel = translated - u_globals.view.xy;
  let view_pos = vec2<f32>(
    rel.x * cam_cos - rel.y * cam_sin,
    rel.x * cam_sin + rel.y * cam_cos
  );
  let ndc = vec2<f32>(
    view_pos.x * u_globals.ndc_scale.x,
    view_pos.y * u_globals.ndc_scale.y
  );
  out.position = vec4<f32>(ndc, 0.0, 1.0);
  out.uv = inst.uv.xy + uv * inst.uv.zw;
  out.color = inst.color;
  return out;
}

@fragment
fn fs_main(
  @location(0) uv : vec2<f32>,
  @location(1) color : vec4<f32>,
) -> @location(0) vec4<f32> {
  return textureSample(tex, samp, uv) * color;
}
