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
// Compatibility projection surface for `Milky2018/mgstudio/pbr/render`.
// Canonical 3D projection ownership lives in
// `Milky2018/mgstudio/camera/projection3d`.

///|
pub type SubCameraView3d = @camera_projection3d.SubCameraView3d

///|
pub type OrthographicScalingMode3d = @camera_projection3d.OrthographicScalingMode3d

///|
pub type PerspectiveProjection3d = @camera_projection3d.PerspectiveProjection3d

///|
pub type OrthographicProjection3d = @camera_projection3d.OrthographicProjection3d

///|
pub type ProjectionMatrix3d = @camera_projection3d.ProjectionMatrix3d

///|
pub type Render3dPassProjection = @camera_projection3d.Render3dPassProjection

///|
pub fn render3d_orthographic_projection_matrix_for_sub(
  orthographic : OrthographicProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_orthographic_projection_matrix_for_sub(
    orthographic, sub_view,
  )
}

///|
pub fn render3d_orthographic_area(
  orthographic : OrthographicProjection3d,
  width : Float,
  height : Float,
) -> @math.Rect {
  @camera_projection3d.render3d_orthographic_area(orthographic, width, height)
}

///|
pub fn render3d_perspective_projection_matrix(
  projection : PerspectiveProjection3d,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_perspective_projection_matrix(projection)
}

///|
pub fn render3d_perspective_projection_matrix_for_sub(
  projection : PerspectiveProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_perspective_projection_matrix_for_sub(
    projection, sub_view,
  )
}

///|
pub fn render3d_projection_matrix_inverse(
  matrix : ProjectionMatrix3d,
) -> ProjectionMatrix3d? {
  @camera_projection_math.projection_matrix_inverse(matrix)
}

///|
pub fn render3d_pass_projection(
  clip_from_view : ProjectionMatrix3d,
  unjittered_clip_from_view : ProjectionMatrix3d,
  camera_near : Float,
  camera_far : Float,
) -> Render3dPassProjection {
  @camera_projection3d.render3d_pass_projection(
    clip_from_view, unjittered_clip_from_view, camera_near, camera_far,
  )
}

///|
pub fn render3d_point_shadow_pass_projection(
  near : Float,
  far : Float,
) -> Render3dPassProjection {
  @camera_projection3d.render3d_point_shadow_pass_projection(near, far)
}

///|
pub fn render3d_pass_projection_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_pass_projection_clip_from_world(
    pass_projection, camera_transform,
  )
}

///|
pub fn render3d_pass_projection_clip_from_view(
  pass_projection : Render3dPassProjection,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_pass_projection_clip_from_view(pass_projection)
}

///|
pub fn render3d_pass_projection_unjittered_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_pass_projection_unjittered_clip_from_world(
    pass_projection, camera_transform,
  )
}

///|
pub fn render3d_projection_matrix_apply_temporal_jitter(
  clip_from_view : ProjectionMatrix3d,
  temporal_jitter : @post_process.TemporalJitter,
  view_width : Int,
  view_height : Int,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_projection_matrix_apply_temporal_jitter(
    clip_from_view, temporal_jitter, view_width, view_height,
  )
}

///|
pub fn render3d_projection_near_from_clip_matrix(
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  @camera_projection3d.render3d_projection_near_from_clip_matrix(clip_from_view)
}

///|
pub fn render3d_orthographic_projection_matrix(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  far : Float,
  near : Float,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_orthographic_projection_matrix(
    left, right, bottom, top, far, near,
  )
}

///|
pub fn render3d_perspective_projection_matrix_raw(
  near : Float,
  fov_y_radians : Float,
  aspect_ratio : Float,
) -> ProjectionMatrix3d {
  @camera_projection3d.render3d_perspective_projection_matrix_raw(
    near, fov_y_radians, aspect_ratio,
  )
}

///|
pub fn render3d_perspective_frustum_corners(
  aspect_ratio : Float,
  fov_y_radians : Float,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  @camera_projection3d.render3d_perspective_frustum_corners(
    aspect_ratio, fov_y_radians, z_near, z_far,
  )
}
