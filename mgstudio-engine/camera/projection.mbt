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
// Bevy source: `bevy/crates/bevy_camera/src/projection.rs`.

///|
pub type PerspectiveProjection3d = @pbr.PerspectiveProjection3d

///|
pub type OrthographicProjection3d = @pbr.OrthographicProjection3d

///|
pub type OrthographicScalingMode3d = @pbr.OrthographicScalingMode3d

///|
pub type SubCameraView3d = @pbr.SubCameraView3d

///|
pub type ProjectionMatrix3d = @pbr.ProjectionMatrix3d

///|
pub type Projection = @pbr.Projection

///|
pub type PerspectiveProjection = PerspectiveProjection3d

///|
pub type OrthographicProjection2d = @sprite.OrthographicProjection

///|
pub fn orthographic_projection_2d_default() -> OrthographicProjection2d {
  @sprite.OrthographicProjection::default_2d()
}

///|
pub fn orthographic_projection_2d_with_scale(
  scale : Float,
) -> OrthographicProjection2d {
  @sprite.OrthographicProjection::new(scale)
}

///|
pub fn perspective_projection_3d_default() -> PerspectiveProjection {
  PerspectiveProjection3d::default()
}

///|
pub fn perspective_projection_3d_update(
  projection : PerspectiveProjection,
  width : Float,
  height : Float,
) -> PerspectiveProjection {
  projection.update(width, height)
}

///|
pub fn perspective_projection_3d_with_aspect_ratio(
  projection : PerspectiveProjection,
  aspect_ratio : Float,
) -> PerspectiveProjection {
  projection.with_aspect_ratio(aspect_ratio)
}

///|
pub fn perspective_projection_3d_compute_frustum(
  projection : PerspectiveProjection3d,
  camera_transform : @transform.Transform,
) -> @pbr.Frustum {
  @pbr.render3d_perspective_projection_compute_frustum(
    projection, camera_transform,
  )
}

///|
pub fn orthographic_projection_3d_compute_frustum(
  projection : OrthographicProjection3d,
  camera_transform : @transform.Transform,
) -> @pbr.Frustum {
  @pbr.render3d_orthographic_projection_compute_frustum(
    projection, camera_transform,
  )
}
