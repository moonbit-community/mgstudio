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
// Adapted from Bevy UI box shadow shader (bevy_ui, v0.15.3): crates/bevy_ui/src/render/box_shadow.wgsl

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) point : vec2<f32>,
  @location(1) color : vec4<f32>,
  @location(2) @interpolate(flat) size : vec2<f32>,
  @location(3) @interpolate(flat) radius : vec4<f32>,
  @location(4) @interpolate(flat) blur : f32,
  @location(5) @interpolate(flat) samples : u32,
};

struct Globals {
  view : vec4<f32>,
  ndc_scale : vec4<f32>,
};

struct InstanceData {
  // model(x,y,cos,sin)
  model : vec4<f32>,
  // scale(x,y,_,_) where x/y represent bounds / 128.
  scale : vec4<f32>,
  color : vec4<f32>,
  // size(x,y,blur,samples) in world units; `samples` encoded as f32.
  size_blur_samples : vec4<f32>,
  // radius(tl,tr,br,bl) in world units.
  radius : vec4<f32>,
};

// Keep the same bind group layout as `ui.wgsl` for runtime simplicity.
@group(0) @binding(0) var samp : sampler;
@group(0) @binding(1) var tex : texture_2d<f32>;
@group(1) @binding(0) var<uniform> u_globals : Globals;
@group(1) @binding(1) var<storage, read> instances : array<InstanceData>;

const BASE_SIZE : f32 = 128.0;

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
  let scaled = vec2<f32>(position.x * inst.scale.x, position.y * inst.scale.y);
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

  let bounds = vec2<f32>(abs(inst.scale.x) * BASE_SIZE, abs(inst.scale.y) * BASE_SIZE);
  out.position = vec4<f32>(ndc, 0.0, 1.0);
  out.point = (uv - vec2<f32>(0.5, 0.5)) * bounds;
  out.color = inst.color;
  out.size = inst.size_blur_samples.xy;
  out.blur = inst.size_blur_samples.z;
  out.samples = u32(inst.size_blur_samples.w);
  out.radius = inst.radius;
  return out;
}

const PI : f32 = 3.14159265358979323846;

fn gaussian(x : f32, sigma : f32) -> f32 {
  return exp(-(x * x) / (2.0 * sigma * sigma)) / (sqrt(2.0 * PI) * sigma);
}

// Approximates the Gauss error function: https://en.wikipedia.org/wiki/Error_function
fn erf(p : vec2<f32>) -> vec2<f32> {
  let s = sign(p);
  let a = abs(p);
  // Fourth degree polynomial approximation for erf.
  var result = 1.0 + (0.278393 + (0.230389 + 0.078108 * (a * a)) * a) * a;
  result = result * result;
  return s - s / (result * result);
}

// Returns the closest corner radius based on the signs of the components of p.
fn select_corner(p : vec2<f32>, c : vec4<f32>) -> f32 {
  return mix(
    mix(c.x, c.y, step(0.0, p.x)),
    mix(c.w, c.z, step(0.0, p.x)),
    step(0.0, p.y)
  );
}

fn horizontal_rounded_box_shadow(
  x : f32,
  y : f32,
  blur : f32,
  corner : f32,
  half_size : vec2<f32>,
) -> f32 {
  let d = min(half_size.y - corner - abs(y), 0.0);
  let c = half_size.x - corner + sqrt(max(0.0, corner * corner - d * d));
  let integral = 0.5 + 0.5 * erf((x + vec2(-c, c)) * (sqrt(0.5) / blur));
  return integral.y - integral.x;
}

fn rounded_box_shadow(
  lower : vec2<f32>,
  upper : vec2<f32>,
  point : vec2<f32>,
  blur : f32,
  corners : vec4<f32>,
  samples : i32,
) -> f32 {
  let center = (lower + upper) * 0.5;
  let half_size = (upper - lower) * 0.5;
  let p = point - center;
  let low = p.y - half_size.y;
  let high = p.y + half_size.y;
  let start = clamp(-3.0 * blur, low, high);
  let end = clamp(3.0 * blur, low, high);
  let step_size = (end - start) / f32(samples);
  var y = start + step_size * 0.5;
  var value : f32 = 0.0;
  for (var i = 0; i < samples; i++) {
    let corner = select_corner(p, corners);
    value += horizontal_rounded_box_shadow(p.x, p.y - y, blur, corner, half_size) *
      gaussian(y, blur) *
      step_size;
    y += step_size;
  }
  return value;
}

@fragment
fn fs_main(in : VertexOut) -> @location(0) vec4<f32> {
  // Keep the same minimum as Bevy to avoid divide-by-zero.
  let blur = max(in.blur, 0.01);
  let samples = max(1, min(64, i32(in.samples)));
  let g = in.color.a *
    rounded_box_shadow(
      -0.5 * in.size,
      0.5 * in.size,
      in.point,
      blur,
      in.radius,
      samples,
    );
  return vec4(in.color.rgb, g);
}

