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
pub type HalfSpace = @math.HalfSpace

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = @math.VIEW_FRUSTUM_NEAR_PLANE_IDX

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = @math.VIEW_FRUSTUM_FAR_PLANE_IDX

///|
fn view_frustum_vec4_add(a : @math.Vec4, b : @math.Vec4) -> @math.Vec4 {
  @math.Vec4::new(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
}

///|
fn view_frustum_vec4_sub(a : @math.Vec4, b : @math.Vec4) -> @math.Vec4 {
  @math.Vec4::new(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
}

///|
pub struct ViewFrustum {
  inner : @math.ViewFrustum
} derive(Eq, ToJson, FromJson)

///|
pub fn ViewFrustum::from_clip_from_world(
  clip_from_world : ProjectionMatrix3d,
) -> ViewFrustum {
  let row0 = clip_from_world.row(0)
  let row1 = clip_from_world.row(1)
  let row2 = clip_from_world.row(2)
  let row3 = clip_from_world.row(3)
  ViewFrustum::new([
    HalfSpace::new(view_frustum_vec4_add(row3, row0)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row0)),
    HalfSpace::new(view_frustum_vec4_add(row3, row1)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row1)),
    HalfSpace::new(view_frustum_vec4_add(row3, row2)),
    HalfSpace::new(row2),
  ])
}

///|
pub fn ViewFrustum::from_clip_from_world_custom_far(
  clip_from_world : ProjectionMatrix3d,
  view_translation : @math.Vec3,
  view_backward : @math.Vec3,
  far : Float,
) -> ViewFrustum {
  let row0 = clip_from_world.row(0)
  let row1 = clip_from_world.row(1)
  let row2 = clip_from_world.row(2)
  let row3 = clip_from_world.row(3)
  let far_center = view_translation.sub(view_backward.mul_scalar(far))
  ViewFrustum::new([
    HalfSpace::new(view_frustum_vec4_add(row3, row0)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row0)),
    HalfSpace::new(view_frustum_vec4_add(row3, row1)),
    HalfSpace::new(view_frustum_vec4_sub(row3, row1)),
    HalfSpace::new(view_frustum_vec4_add(row3, row2)),
    HalfSpace::new(
      @math.Vec4::new(
        view_backward.x,
        view_backward.y,
        view_backward.z,
        -view_backward.dot(far_center),
      ),
    ),
  ])
}

///|
pub fn ViewFrustum::new(half_spaces : Array[HalfSpace]) -> ViewFrustum {
  ViewFrustum::{ inner: @math.ViewFrustum::new(half_spaces) }
}

///|
pub fn ViewFrustum::corners(self : ViewFrustum) -> Array[@math.Vec3]? {
  @math.ViewFrustum::corners(self.inner)
}

///|
pub struct Frustum {
  half_spaces : Array[HalfSpace]
} derive(Eq, ToJson, FromJson)

///|
pub fn Frustum::new(view_frustum : ViewFrustum) -> Frustum {
  Frustum::{ half_spaces: view_frustum.inner.half_spaces }
}

///|
pub fn Frustum::view_frustum(self : Frustum) -> ViewFrustum {
  ViewFrustum::new(self.half_spaces)
}

///|
pub fn Frustum::corners(self : Frustum) -> Array[@math.Vec3]? {
  self.view_frustum().corners()
}

///|
pub fn render3d_compute_frustum(
  clip_from_view : ProjectionMatrix3d,
  camera_transform : @transform.Transform,
  far : Float,
) -> Frustum {
  let clip_from_world = clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
  Frustum::new(
    ViewFrustum::from_clip_from_world_custom_far(
      clip_from_world,
      camera_transform.translation,
      camera_transform.back(),
      far,
    ),
  )
}

///|
pub fn render3d_perspective_projection_compute_frustum(
  projection : PerspectiveProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  render3d_compute_frustum(
    projection.get_clip_from_view(),
    camera_transform,
    projection.far,
  )
}

///|
pub fn render3d_orthographic_projection_compute_frustum(
  projection : OrthographicProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  render3d_compute_frustum(
    projection.get_clip_from_view(),
    camera_transform,
    projection.far,
  )
}

///|
pub(all) struct ProjectionRuntime3d {
  last_view_width : Float
  last_view_height : Float
}

///|
pub let ecs_key_projection_runtime3d : @ecs.ComponentKey[ProjectionRuntime3d] = @ecs.register_component(
  debug_name="render3d.projection_runtime3d",
)

///|
pub let ecs_key_frustum : @ecs.ComponentKey[Frustum] = @ecs.register_component(
  debug_name="render3d.frustum",
)

///|
pub impl @ecs.Component for Frustum with component() {
  ecs_key_frustum
}
