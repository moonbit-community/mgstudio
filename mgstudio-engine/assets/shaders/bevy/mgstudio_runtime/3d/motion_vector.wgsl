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

#import bevy_render::{
  globals::Globals,
  maths::affine3_to_square,
  view::View,
}
#import bevy_pbr::{
  mesh_types::Mesh,
  prepass_bindings,
}

@group(0) @binding(0) var<uniform> view : View;
@group(0) @binding(1) var<uniform> globals : Globals;
@group(0) @binding(2) var<uniform> previous_view_uniforms : prepass_bindings::PreviousViewUniforms;
#if AVAILABLE_STORAGE_BUFFER_BINDINGS >= 6
@group(0) @binding(14) var<storage> visibility_ranges : array<vec4<f32>>;
#else
@group(0) @binding(14) var<uniform> visibility_ranges : array<vec4<f32>, 1u>;
#endif
@group(2) @binding(0) var<uniform> mesh : array<Mesh, 1u>;

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) world_position : vec4<f32>,
  @location(1) previous_world_position : vec4<f32>,
};

fn safe_project_xy(clip : vec4<f32>) -> vec2<f32> {
  var w = clip.w;
  if abs(w) < 1.0e-6 {
    w = select(-1.0e-6, 1.0e-6, w >= 0.0);
  }
  return clip.xy / w;
}

@vertex
fn vs_main(
  @builtin(instance_index) _instance_index : u32,
  @location(0) position : vec3<f32>,
  @location(1) _uv : vec2<f32>,
  @location(2) _color : vec4<f32>,
) -> VertexOut {
  var out : VertexOut;
  let world_from_local = affine3_to_square(mesh[0].world_from_local);
  let previous_world_from_local = affine3_to_square(mesh[0].previous_world_from_local);
  out.world_position = world_from_local * vec4<f32>(position, 1.0);
  out.previous_world_position = previous_world_from_local * vec4<f32>(position, 1.0);
  out.position = view.unjittered_clip_from_world * out.world_position;
  return out;
}

struct FragmentOut {
  @location(0) unused_prepass_slot0 : vec4<f32>,
  @location(1) motion_vector : vec2<f32>,
};

@fragment
fn fs_main(in : VertexOut) -> FragmentOut {
  let clip_position = safe_project_xy(view.unjittered_clip_from_world * in.world_position);
  let previous_clip_position = safe_project_xy(
    previous_view_uniforms.clip_from_world * in.previous_world_position,
  );
  let motion = (clip_position - previous_clip_position) * vec2<f32>(0.5, -0.5);
  FragmentOut::{
    unused_prepass_slot0: vec4<f32>(0.0),
    motion_vector: motion,
  }
}
