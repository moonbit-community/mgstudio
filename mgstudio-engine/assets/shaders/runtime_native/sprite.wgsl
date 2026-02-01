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

// Native runtime sprite pipeline shader.
//
// This shader matches the current mgstudio native bring-up pipeline:
// - Fullscreen-quad geometry is generated from @builtin(vertex_index)
// - One uniform block (group 1) is used to drive transform + UV + color
// - Texture/sampler are provided in group 0

struct U {
  center: vec2<f32>,
  half_size_view: vec2<f32>,
  rot: f32,
  inv_half_w: f32,
  inv_half_h: f32,
  _pad0: f32,
  uv_min: vec2<f32>,
  uv_max: vec2<f32>,
  color: vec4<f32>,
};

struct VSOut {
  @builtin(position) pos: vec4<f32>,
  @location(0) uv: vec2<f32>,
  @location(1) color: vec4<f32>,
};

@group(0) @binding(0) var samp : sampler;
@group(0) @binding(1) var tex : texture_2d<f32>;
@group(1) @binding(0) var<uniform> u : U;

@vertex
fn vs_main(@builtin(vertex_index) vid: u32) -> VSOut {
  var p = array<vec2<f32>, 6>(
    vec2<f32>(-1.0, -1.0),
    vec2<f32>( 1.0, -1.0),
    vec2<f32>( 1.0,  1.0),
    vec2<f32>(-1.0, -1.0),
    vec2<f32>( 1.0,  1.0),
    vec2<f32>(-1.0,  1.0),
  );
  let base = p[vid];
  let c = cos(u.rot);
  let s = sin(u.rot);
  // Rotate in view space (logical pixels / world units), then map to NDC
  // with per-axis scales. Rotating in NDC would distort when the viewport
  // aspect ratio is not 1 (anisotropic viewport transform).
  let view = vec2<f32>(base.x * u.half_size_view.x, base.y * u.half_size_view.y);
  let rot_view = vec2<f32>(
    view.x * c - view.y * s,
    view.x * s + view.y * c,
  );
  let off = vec2<f32>(rot_view.x * u.inv_half_w, rot_view.y * u.inv_half_h);
  var out: VSOut;
  out.pos = vec4<f32>(u.center + off, 0.0, 1.0);
  // Note: NDC Y grows upward, but texture V grows downward (v=0 at top).
  // Flip the interpolation Y to match WebGPU/wgpu UV conventions.
  let t0 = (base + vec2<f32>(1.0, 1.0)) * 0.5;
  let t = vec2<f32>(t0.x, 1.0 - t0.y);
  out.uv = mix(u.uv_min, u.uv_max, t);
  out.color = u.color;
  return out;
}

@fragment
fn fs_main(in: VSOut) -> @location(0) vec4<f32> {
  let texel = textureSample(tex, samp, in.uv);
  return texel * in.color;
}

