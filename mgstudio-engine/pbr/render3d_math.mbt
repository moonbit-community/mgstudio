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

///|
fn cmp_int(a : Int, b : Int) -> Int {
  @pbr_render.cmp_int(a, b)
}

///|
fn cmp_float(a : Float, b : Float) -> Int {
  @pbr_render.cmp_float(a, b)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  @pbr_render.quat_rotate_vec3(q, v)
}

///|
fn render3d_quat_inverse(q : @math.Quat) -> @math.Quat {
  @pbr_render.render3d_quat_inverse(q)
}

///|
fn render3d_quat_conjugate(value : @math.Quat) -> @math.Quat {
  @pbr_render.render3d_quat_conjugate(value)
}

///|
fn render3d_projection_aspect_ratio(width : Float, height : Float) -> Float {
  @pbr_render.render3d_projection_aspect_ratio(width, height)
}

///|
fn render3d_signum(value : Float) -> Float {
  @pbr_render.render3d_signum(value)
}

///|
fn render3d_vec4_dot(lhs : @math.Vec4, rhs : @math.Vec4) -> Float {
  @pbr_render.render3d_vec4_dot(lhs, rhs)
}

///|
fn render3d_default_near_clip_plane(near : Float) -> @math.Vec4 {
  @pbr_render.render3d_default_near_clip_plane(near)
}

///|
fn render3d_transform_forward(transform : @transform.Transform) -> @math.Vec3 {
  @pbr_render.render3d_transform_forward(transform)
}

///|
fn render3d_float_clamp(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  @pbr_render.render3d_float_clamp(value, min_value, max_value)
}

///|
fn minf(a : Float, b : Float) -> Float {
  @pbr_render.minf(a, b)
}

///|
fn maxf(a : Float, b : Float) -> Float {
  @pbr_render.maxf(a, b)
}

///|
fn clamp01(value : Float) -> Float {
  @pbr_render.clamp01(value)
}

///|
fn absf(value : Float) -> Float {
  @pbr_render.absf(value)
}

///|
fn render3d_lightmap_uv_transform(uv_rect : @math.Rect) -> @transform.Affine2 {
  @pbr_render.render3d_lightmap_uv_transform(uv_rect)
}

///|
fn render3d_inverse_transform_point(
  transform : @transform.Transform,
  world_point : @math.Vec3,
) -> @math.Vec3? {
  @pbr_render.render3d_inverse_transform_point(transform, world_point)
}

///|
fn render3d_inverse_transform_direction(
  transform : @transform.Transform,
  world_direction : @math.Vec3,
) -> @math.Vec3? {
  @pbr_render.render3d_inverse_transform_direction(transform, world_direction)
}

///|
fn render3d_transform_local_normal(
  transform : @transform.Transform,
  local_normal : @math.Vec3,
) -> @math.Vec3 {
  @pbr_render.render3d_transform_local_normal(transform, local_normal)
}
