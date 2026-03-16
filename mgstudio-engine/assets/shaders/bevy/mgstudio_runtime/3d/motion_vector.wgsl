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

struct MotionVectorUniform {
  model_pos : vec4<f32>,
  model_rot : vec4<f32>,
  model_scale : vec4<f32>,
  previous_model_pos : vec4<f32>,
  previous_model_rot : vec4<f32>,
  previous_model_scale : vec4<f32>,
  unjittered_clip_from_world : mat4x4<f32>,
  previous_clip_from_world : mat4x4<f32>,
};

@group(0) @binding(0) var<uniform> u_mv : MotionVectorUniform;

struct VertexOut {
  @builtin(position) position : vec4<f32>,
  @location(0) current_clip : vec2<f32>,
  @location(1) previous_clip : vec2<f32>,
};

fn quat_normalize(q : vec4<f32>) -> vec4<f32> {
  let n = max(dot(q, q), 1e-8);
  return q / sqrt(n);
}

fn quat_rotate_vec3(q : vec4<f32>, v : vec3<f32>) -> vec3<f32> {
  let t = 2.0 * cross(q.xyz, v);
  return v + q.w * t + cross(q.xyz, t);
}

fn safe_project_xy(clip : vec4<f32>) -> vec2<f32> {
  var w = clip.w;
  if abs(w) < 1.0e-6 {
    w = select(-1.0e-6, 1.0e-6, w >= 0.0);
  }
  return clip.xy / w;
}

@vertex
fn vs_main(
  @location(0) position : vec3<f32>,
  @location(1) _uv : vec2<f32>,
  @location(2) _color : vec4<f32>,
) -> VertexOut {
  var out : VertexOut;

  let model_q = quat_normalize(u_mv.model_rot);
  let previous_model_q = quat_normalize(u_mv.previous_model_rot);

  let local_pos_current = position * u_mv.model_scale.xyz;
  let local_pos_previous = position * u_mv.previous_model_scale.xyz;

  let world_pos_current = quat_rotate_vec3(model_q, local_pos_current) +
    u_mv.model_pos.xyz;
  let world_pos_previous = quat_rotate_vec3(previous_model_q, local_pos_previous) +
    u_mv.previous_model_pos.xyz;

  let clip_current = u_mv.unjittered_clip_from_world * vec4<f32>(world_pos_current, 1.0);
  let clip_previous = u_mv.previous_clip_from_world * vec4<f32>(world_pos_previous, 1.0);

  out.position = clip_current;
  out.current_clip = safe_project_xy(clip_current);
  out.previous_clip = safe_project_xy(clip_previous);
  return out;
}

@fragment
fn fs_main(in : VertexOut) -> @location(0) vec4<f32> {
  let motion = (in.current_clip - in.previous_clip) * vec2<f32>(0.5, -0.5);
  return vec4<f32>(motion, 0.0, 1.0);
}
