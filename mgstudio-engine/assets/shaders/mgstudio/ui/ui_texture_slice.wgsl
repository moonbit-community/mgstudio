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
// Adapted from Bevy UI texture slicing shader (bevy_ui, v0.15.3):
// crates/bevy_ui/src/render/ui_texture_slice.wgsl

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) uv : vec2<f32>,
  @location(1) color : vec4<f32>,
  // Normalized texture slice dividing lines: left, top, right, bottom.
  @location(2) @interpolate(flat) texture_slices : vec4<f32>,
  // Normalized target slice dividing lines: left, top, right, bottom.
  @location(3) @interpolate(flat) target_slices : vec4<f32>,
  // Repeat factors: side_x, side_y, center_x, center_y.
  @location(4) @interpolate(flat) repeat : vec4<f32>,
  // Normalized atlas rect: left, top, right, bottom.
  @location(5) @interpolate(flat) atlas_rect : vec4<f32>,
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
  texture_slices : vec4<f32>,
  target_slices : vec4<f32>,
  repeat : vec4<f32>,
  atlas_rect : vec4<f32>,
};

// Keep the same bind group layout as `ui.wgsl` for runtime simplicity.
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

  out.position = vec4<f32>(ndc, 0.0, 1.0);
  out.uv = uv;
  out.color = inst.color;
  out.texture_slices = inst.texture_slices;
  out.target_slices = inst.target_slices;
  out.repeat = inst.repeat;
  out.atlas_rect = inst.atlas_rect;
  return out;
}

fn map_axis_with_repeat(
  p : f32,
  il : f32,
  ih : f32,
  tl : f32,
  th : f32,
  r : f32,
) -> f32 {
  if p < il {
    return (p / il) * tl;
  } else if ih < p {
    return th + ((p - ih) / (1.0 - ih)) * (1.0 - th);
  } else {
    return tl + fract((r * (p - il)) / (ih - il)) * (th - tl);
  }
}

fn map_uvs_to_slice(
  uv : vec2<f32>,
  target_slices : vec4<f32>,
  texture_slices : vec4<f32>,
  repeat : vec4<f32>,
) -> vec2<f32> {
  var r : vec2<f32>;
  if target_slices.x <= uv.x &&
    uv.x <= target_slices.z &&
    target_slices.y <= uv.y &&
    uv.y <= target_slices.w {
    r = repeat.zw;
  } else {
    r = repeat.xy;
  }
  let x = map_axis_with_repeat(
    uv.x,
    target_slices.x,
    target_slices.z,
    texture_slices.x,
    texture_slices.z,
    r.x,
  );
  let y = map_axis_with_repeat(
    uv.y,
    target_slices.y,
    target_slices.w,
    texture_slices.y,
    texture_slices.w,
    r.y,
  );
  return vec2(x, y);
}

@fragment
fn fs_main(in : VertexOut) -> @location(0) vec4<f32> {
  let slice_uv = map_uvs_to_slice(
    in.uv,
    in.target_slices,
    in.texture_slices,
    in.repeat,
  );
  let atlas_uv = in.atlas_rect.xy +
    slice_uv * (in.atlas_rect.zw - in.atlas_rect.xy);
  return in.color * textureSample(tex, samp, atlas_uv);
}

