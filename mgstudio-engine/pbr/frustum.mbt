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
pub fn ProjectionMatrix3d::row(
  self : ProjectionMatrix3d,
  index : Int,
) -> @math.Vec4 {
  match index {
    0 =>
      @math.Vec4::new(
        self.x_axis.x,
        self.y_axis.x,
        self.z_axis.x,
        self.w_axis.x,
      )
    1 =>
      @math.Vec4::new(
        self.x_axis.y,
        self.y_axis.y,
        self.z_axis.y,
        self.w_axis.y,
      )
    2 =>
      @math.Vec4::new(
        self.x_axis.z,
        self.y_axis.z,
        self.z_axis.z,
        self.w_axis.z,
      )
    3 =>
      @math.Vec4::new(
        self.x_axis.w,
        self.y_axis.w,
        self.z_axis.w,
        self.w_axis.w,
      )
    _ => abort("ProjectionMatrix3d::row index out of bounds")
  }
}

///|
fn render3d_compute_frustum(
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
pub fn PerspectiveProjection3d::compute_frustum(
  self : PerspectiveProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  render3d_compute_frustum(
    self.get_clip_from_view(),
    camera_transform,
    self.far,
  )
}

///|
pub fn OrthographicProjection3d::compute_frustum(
  self : OrthographicProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  render3d_compute_frustum(
    self.get_clip_from_view(),
    camera_transform,
    self.far,
  )
}

///|
pub fn CustomProjection3d::compute_frustum(
  self : CustomProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  render3d_compute_frustum(
    self.get_clip_from_view(),
    camera_transform,
    self.far(),
  )
}

///|
pub fn Projection::compute_frustum(
  self : Projection,
  camera_transform : @transform.Transform,
) -> Frustum {
  match self {
    Perspective(projection) => projection.compute_frustum(camera_transform)
    Orthographic(projection) => projection.compute_frustum(camera_transform)
    Custom(projection) => projection.compute_frustum(camera_transform)
  }
}

///|
pub fn render3d_update_frusta_system(world : @ecs.World) -> Unit {
  let query : @ecs.Query[
    (@ecs.Comp[@transform.Transform], @ecs.Comp[Projection]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let (transform, projection) = data
    let next = projection.value().compute_frustum(transform.value())
    if (try! world.get_by_key(entity, ecs_key_frustum)) is Some(current) {
      if current != next {
        try! (world.replace(entity, ecs_key_frustum, next) |> ignore)
      }
    } else {
      try! world.set_by_key(entity, ecs_key_frustum, next)
    }
  })
}
