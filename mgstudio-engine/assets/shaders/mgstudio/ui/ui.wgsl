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
// Adapted from Bevy UI shader (bevy_ui, v0.15.3): crates/bevy_ui/src/render/ui.wgsl

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) uv : vec2<f32>,
  @location(1) color : vec4<f32>,
  // Rect size in local space (logical pixels).
  @location(2) @interpolate(flat) size : vec2<f32>,
  @location(3) @interpolate(flat) flags : u32,
  // Corner radii: top-left, top-right, bottom-right, bottom-left.
  @location(4) @interpolate(flat) radius : vec4<f32>,
  // Border thickness: left, top, right, bottom.
  @location(5) @interpolate(flat) border : vec4<f32>,
  // Position relative to the center of the rectangle (local space).
  @location(6) point : vec2<f32>,
};

struct Globals {
  view : vec4<f32>,
  ndc_scale : vec4<f32>,
};

struct InstanceData {
  // model(x,y,cos,sin)
  model : vec4<f32>,
  // scale(x,y,_,_)
  scale : vec4<f32>,
  color : vec4<f32>,
  // uv(min_x, min_y, scale_x, scale_y)
  uv : vec4<f32>,
  // flags in x (encoded as f32), remaining lanes unused.
  flags : vec4<f32>,
  // x: top left, y: top right, z: bottom right, w: bottom left.
  radius : vec4<f32>,
  // x: left, y: top, z: right, w: bottom.
  border : vec4<f32>,
};

@group(0) @binding(0) var samp : sampler;
@group(0) @binding(1) var tex : texture_2d<f32>;
@group(1) @binding(0) var<uniform> u_globals : Globals;
@group(1) @binding(1) var<storage, read> instances : array<InstanceData>;

// Flag bitset (must match engine extraction).
const TEXTURED : u32 = 1u;
const BORDER : u32 = 2u;
const ANTI_ALIAS : u32 = 4u;

fn enabled(flags : u32, mask : u32) -> bool {
  return (flags & mask) != 0u;
}

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
  let flags = u32(inst.flags.x);

  let cosv = inst.model.z;
  let sinv = inst.model.w;
  let scaled = vec2<f32>(position.x * inst.scale.x, position.y * inst.scale.y);

  // UI SDF functions assume +Y is down (top < 0, bottom > 0).
  let point = vec2<f32>(scaled.x, -scaled.y);

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
  out.flags = flags;
  out.radius = inst.radius;
  out.border = inst.border;
  out.point = point;
  out.size = vec2<f32>(abs(inst.scale.x) * 128.0, abs(inst.scale.y) * 128.0);
  return out;
}

// Signed distance from `point` to the boundary of a rounded box of `size`.
// Negative inside, positive outside, zero on edge.
fn sd_rounded_box(point : vec2<f32>, size : vec2<f32>, corner_radii : vec4<f32>) -> f32 {
  // If 0.0 < y then select bottom left (w) and bottom right (z); else select top.
  let rs = select(corner_radii.xy, corner_radii.wz, 0.0 < point.y);
  // Pick left/right radius.
  let radius = select(rs.x, rs.y, 0.0 < point.x);
  let corner_to_point = abs(point) - 0.5 * size;
  let q = corner_to_point + radius;
  let l = length(max(q, vec2(0.0)));
  let m = min(max(q.x, q.y), 0.0);
  return l + m - radius;
}

fn sd_inset_rounded_box(point : vec2<f32>, size : vec2<f32>, radius : vec4<f32>, inset : vec4<f32>) -> f32 {
  let inner_size = size - inset.xy - inset.zw;
  let inner_center = inset.xy + 0.5 * inner_size - 0.5 * size;
  let inner_point = point - inner_center;

  var r = radius;
  r.x = r.x - max(inset.x, inset.y); // top left
  r.y = r.y - max(inset.z, inset.y); // top right
  r.z = r.z - max(inset.z, inset.w); // bottom right
  r.w = r.w - max(inset.x, inset.w); // bottom left

  let half_size = inner_size * 0.5;
  let min_size = min(half_size.x, half_size.y);
  r = min(max(r, vec4(0.0)), vec4<f32>(min_size));

  return sd_rounded_box(inner_point, inner_size, r);
}

fn antialias(distance : f32) -> f32 {
  return saturate(0.5 - distance);
}

fn draw_border(in : VertexOut, texture_color : vec4<f32>) -> vec4<f32> {
  let color = select(in.color, in.color * texture_color, enabled(in.flags, TEXTURED));
  let external_distance = sd_rounded_box(in.point, in.size, in.radius);
  let internal_distance = sd_inset_rounded_box(in.point, in.size, in.radius, in.border);
  let border_distance = max(external_distance, -internal_distance);

  var t : f32;
  if enabled(in.flags, ANTI_ALIAS) {
    // Only anti-alias the border when a non-zero border exists.
    t = select(1.0 - step(0.0, border_distance), antialias(border_distance), external_distance < internal_distance);
  } else {
    t = 1.0 - step(0.0, border_distance);
  }
  return vec4(color.rgb, saturate(color.a * t));
}

fn draw_background(in : VertexOut, texture_color : vec4<f32>) -> vec4<f32> {
  let color = select(in.color, in.color * texture_color, enabled(in.flags, TEXTURED));
  let internal_distance = sd_inset_rounded_box(in.point, in.size, in.radius, in.border);
  let t = if enabled(in.flags, ANTI_ALIAS) { antialias(internal_distance) } else { 1.0 - step(0.0, internal_distance) };
  return vec4(color.rgb, saturate(color.a * t));
}

@fragment
fn fs_main(in : VertexOut) -> @location(0) vec4<f32> {
  let texture_color = textureSample(tex, samp, in.uv);
  if enabled(in.flags, BORDER) {
    return draw_border(in, texture_color);
  } else {
    return draw_background(in, texture_color);
  }
}
