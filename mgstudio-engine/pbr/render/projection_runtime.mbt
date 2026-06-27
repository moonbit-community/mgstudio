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
// Compatibility projection runtime surface for `Milky2018/mgstudio/pbr/render`.
// Canonical 3D projection ownership lives in
// `Milky2018/mgstudio/camera/projection3d`.

///|
pub type HalfSpace = @camera_projection3d.HalfSpace

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = @camera_projection3d.VIEW_FRUSTUM_NEAR_PLANE_IDX

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = @camera_projection3d.VIEW_FRUSTUM_FAR_PLANE_IDX

///|
pub type ViewFrustum = @camera_projection3d.ViewFrustum

///|
pub type Frustum = @camera_projection3d.Frustum

///|
pub type CustomProjection3d = @camera_projection3d.CustomProjection3d

///|
pub type Projection = @camera_projection3d.Projection

///|
pub type ProjectionRuntime3d = @camera_projection3d.ProjectionRuntime3d

///|
pub let ecs_key_projection_runtime3d : @ecs.ComponentKey[ProjectionRuntime3d] = @camera_projection3d.ecs_key_projection_runtime3d

///|
pub let ecs_key_frustum : @ecs.ComponentKey[Frustum] = @camera_projection3d.ecs_key_frustum

///|
pub fn custom_projection3d_from_callbacks(
  type_name : String,
  get_clip_from_view_fn : () -> ProjectionMatrix3d,
  get_clip_from_view_for_sub_fn : (SubCameraView3d) -> ProjectionMatrix3d,
  update_fn : (Float, Float) -> CustomProjection3d,
  far_fn : () -> Float,
  get_frustum_corners_fn : (Float, Float) -> Array[@math.Vec3],
) -> CustomProjection3d {
  @camera_projection3d.custom_projection3d_from_callbacks(
    type_name, get_clip_from_view_fn, get_clip_from_view_for_sub_fn, update_fn, far_fn,
    get_frustum_corners_fn,
  )
}

///|
pub fn projection_from_custom(projection : CustomProjection3d) -> Projection {
  @camera_projection3d.projection_from_custom(projection)
}

///|
pub fn render3d_frustum_from_view_frustum(
  view_frustum : ViewFrustum,
) -> Frustum {
  @camera_projection3d.render3d_frustum_from_view_frustum(view_frustum)
}

///|
pub fn render3d_compute_frustum(
  clip_from_view : ProjectionMatrix3d,
  camera_transform : @transform.Transform,
  far : Float,
) -> Frustum {
  @camera_projection3d.render3d_compute_frustum(
    clip_from_view, camera_transform, far,
  )
}

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
