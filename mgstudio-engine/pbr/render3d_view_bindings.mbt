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
type Render3dPassProjection = @pbr_render.Render3dPassProjection

///|
fn render3d_projection_near(
  projection : Projection,
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  match projection {
    Perspective(perspective) => maxf(0.0001F, perspective.near)
    Orthographic(orthographic) => orthographic.near
    Custom(_) =>
      @pbr_render.render3d_projection_near_from_clip_matrix(clip_from_view)
  }
}

///|
fn render3d_camera_pass_projection(
  projection : Projection,
  sub_camera_view : SubCameraView3d?,
  temporal_jitter : TemporalJitter?,
  view_width : Int,
  view_height : Int,
) -> Render3dPassProjection {
  let unjittered_clip_from_view = match sub_camera_view {
    Some(sub_view) => projection.get_clip_from_view_for_sub(sub_view)
    None => projection.get_clip_from_view()
  }
  let clip_from_view = match temporal_jitter {
    Some(temporal_jitter) =>
      @pbr_render.render3d_projection_matrix_apply_temporal_jitter(
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
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> Projection {
  match
    @pbr_render.render3d_camera_viewport_rect_logical(
      camera, target_size, scale_factor,
    ) {
    Some((_, _, viewport_width, viewport_height)) =>
      projection.update(viewport_width, viewport_height)
    None => projection
  }
}

///|
fn render3d_projection_runtime_update(
  projection : Projection,
  runtime : ProjectionRuntime3d?,
  force_update : Bool,
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Projection, ProjectionRuntime3d?) {
  match
    @pbr_render.render3d_camera_viewport_rect_logical(
      camera, target_size, scale_factor,
    ) {
    Some((_, _, viewport_width, viewport_height)) => {
      let next_runtime = ProjectionRuntime3d::{
        last_view_width: viewport_width,
        last_view_height: viewport_height,
      }
      if runtime is Some(previous_runtime) &&
        previous_runtime.last_view_width == viewport_width &&
        previous_runtime.last_view_height == viewport_height &&
        !force_update {
        (projection, None)
      } else {
        (projection.update(viewport_width, viewport_height), Some(next_runtime))
      }
    }
    None => (projection, None)
  }
}
