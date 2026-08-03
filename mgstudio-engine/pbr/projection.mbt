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

///|
// Compatibility projection surface for `Milky2018/mgstudio/pbr`.
// Canonical Bevy `bevy_camera/src/projection.rs` ownership lives in
// `Milky2018/mgstudio/camera/projection3d`.

///|
pub type PerspectiveProjection3d = @camera_projection3d.PerspectiveProjection3d

///|
pub type OrthographicProjection3d = @camera_projection3d.OrthographicProjection3d

///|
pub type OrthographicScalingMode3d = @camera_projection3d.OrthographicScalingMode3d

///|
pub type SubCameraView3d = @camera_projection3d.SubCameraView3d

///|
pub type ProjectionMatrix3d = @camera_projection3d.ProjectionMatrix3d

///|
pub type CustomProjection3d = @camera_projection3d.CustomProjection3d

///|
pub type Projection = @camera_projection3d.Projection

///|
pub type ProjectionRuntime3d = @camera_projection3d.ProjectionRuntime3d

///|
pub fn render3d_perspective_projection_compute_frustum(
  projection : PerspectiveProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  @camera_projection3d.render3d_perspective_projection_compute_frustum(
    projection, camera_transform,
  )
}

///|
pub fn render3d_orthographic_projection_compute_frustum(
  projection : OrthographicProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  @camera_projection3d.render3d_orthographic_projection_compute_frustum(
    projection, camera_transform,
  )
}

///|
fn render3d_projection_near(
  projection : Projection,
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  match projection {
    Perspective(perspective) =>
      @camera_projection3d.maxf(0.0001F, perspective.near)
    Orthographic(orthographic) => orthographic.near
    Custom(_) =>
      @camera_projection3d.render3d_projection_near_from_clip_matrix(
        clip_from_view,
      )
  }
}

///|
fn render3d_camera_pass_projection(
  projection : Projection,
  sub_camera_view : SubCameraView3d?,
  temporal_jitter : TemporalJitter?,
  view_width : Int,
  view_height : Int,
) -> @pbr_render.Render3dPassProjection {
  let unjittered_clip_from_view = match sub_camera_view {
    Some(sub_view) => projection.get_clip_from_view_for_sub(sub_view)
    None => projection.get_clip_from_view()
  }
  let clip_from_view = match temporal_jitter {
    Some(temporal_jitter) =>
      @render.render3d_projection_matrix_apply_temporal_jitter(
        unjittered_clip_from_view, temporal_jitter, view_width, view_height,
      )
    None => unjittered_clip_from_view
  }
  @pbr_render.render3d_pass_projection(
    clip_from_view,
    unjittered_clip_from_view,
    render3d_projection_near(projection, unjittered_clip_from_view),
    projection.far(),
  )
}

///|
fn render3d_projection_runtime_projection(
  projection : Projection,
  camera : @camera_camera.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> Projection {
  @camera_projection_math.projection_runtime_projection(
    projection, camera, target_size, scale_factor,
  )
}
