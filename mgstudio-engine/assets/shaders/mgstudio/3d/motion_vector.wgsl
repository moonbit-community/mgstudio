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
  camera_pos : vec4<f32>,
  camera_rot : vec4<f32>,
  previous_camera_pos : vec4<f32>,
  previous_camera_rot : vec4<f32>,
  projection : vec4<f32>, // (fov_y, aspect, near, far)
  subview : vec4<f32>, // (scale_x, scale_y, bias_x, bias_y)
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

fn quat_conjugate(q : vec4<f32>) -> vec4<f32> {
  return vec4<f32>(-q.xyz, q.w);
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

fn project_world(
  world_pos : vec3<f32>,
  camera_pos : vec3<f32>,
  camera_rot : vec4<f32>,
  projection : vec4<f32>,
  subview : vec4<f32>,
) -> vec4<f32> {
  let camera_q = quat_normalize(camera_rot);
  let inv_camera_q = quat_conjugate(camera_q);
  let camera_space = quat_rotate_vec3(inv_camera_q, world_pos - camera_pos);
  let aspect = max(projection.y, 0.001);
  var clip_x_full = 0.0;
  var clip_y_full = 0.0;
  var clip_z = 0.0;
  var clip_w = 1.0;
  if projection.x > 0.0 {
    let fov_y = max(projection.x, 0.001);
    let near_z = max(projection.z, 0.0001);
    let far_z = max(projection.w, near_z + 0.0001);
    let f = 1.0 / tan(0.5 * fov_y);
    clip_x_full = camera_space.x * f / aspect;
    clip_y_full = camera_space.y * f;
    clip_z = camera_space.z * (far_z / (near_z - far_z)) +
      (near_z * far_z) / (near_z - far_z);
    clip_w = -camera_space.z;
  } else {
    let half_height = max(-projection.x, 1e-5);
    let half_width = max(half_height * aspect, 1e-5);
    let near_z = projection.z;
    let far_z = select(
      near_z + 0.0001,
      projection.w,
      projection.w > near_z + 0.0001,
    );
    clip_x_full = camera_space.x / half_width;
    clip_y_full = camera_space.y / half_height;
    let z01 = (camera_space.z - near_z) / (far_z - near_z);
    clip_z = z01 * 2.0 - 1.0;
    clip_w = 1.0;
  }
  let clip_x = clip_x_full * subview.x + subview.z * clip_w;
  let clip_y = clip_y_full * subview.y + subview.w * clip_w;
  return vec4<f32>(clip_x, clip_y, clip_z, clip_w);
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

  let clip_current = project_world(
    world_pos_current,
    u_mv.camera_pos.xyz,
    u_mv.camera_rot,
    u_mv.projection,
    u_mv.subview,
  );
  let clip_previous = project_world(
    world_pos_previous,
    u_mv.previous_camera_pos.xyz,
    u_mv.previous_camera_rot,
    u_mv.projection,
    u_mv.subview,
  );

  out.position = clip_current;
  out.current_clip = safe_project_xy(clip_current);
  out.previous_clip = safe_project_xy(clip_previous);
  return out;
}

@fragment
fn fs_main(in : VertexOut) -> @location(0) vec4<f32> {
  let motion = (in.current_clip - in.previous_clip) * vec2<f32>(0.5, -0.5);
  let encoded_motion = clamp(motion * 0.5 + vec2<f32>(0.5, 0.5), vec2<f32>(0.0), vec2<f32>(1.0));
  let depth = clamp(in.position.z, 0.0, 1.0);
  return vec4<f32>(encoded_motion, depth, 1.0);
}
