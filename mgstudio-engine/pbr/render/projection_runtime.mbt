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
pub(open) trait CameraProjection3d {
  get_clip_from_view(self : Self) -> ProjectionMatrix3d
  get_clip_from_view_for_sub(self : Self, sub_view : SubCameraView3d) -> ProjectionMatrix3d
  update(self : Self, width : Float, height : Float) -> Self
  far(self : Self) -> Float
  compute_frustum(self : Self, camera_transform : @transform.Transform) -> Frustum
  get_frustum_corners(self : Self, z_near : Float, z_far : Float) -> Array[
    @math.Vec3,
  ]
}

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
pub struct CustomProjection3d {
  type_name : String
  payload : @any.Any
  get_clip_from_view_fn : (@any.Any) -> ProjectionMatrix3d
  get_clip_from_view_for_sub_fn : (@any.Any, SubCameraView3d) -> ProjectionMatrix3d
  update_fn : (@any.Any, Float, Float) -> @any.Any
  far_fn : (@any.Any) -> Float
  get_frustum_corners_fn : (@any.Any, Float, Float) -> Array[@math.Vec3]
}

///|
pub fn[T : CameraProjection3d] CustomProjection3d::new(
  projection : T,
) -> CustomProjection3d {
  let payload = @any.of(projection)
  custom_projection3d_from_callbacks(
    payload.type_name(),
    payload,
    fn(payload) {
      let projection : T = try! payload.to()
      projection.get_clip_from_view()
    },
    fn(payload, sub_view) {
      let projection : T = try! payload.to()
      projection.get_clip_from_view_for_sub(sub_view)
    },
    fn(payload, width, height) {
      let projection : T = try! payload.to()
      @any.of(projection.update(width, height))
    },
    fn(payload) {
      let projection : T = try! payload.to()
      projection.far()
    },
    fn(payload, z_near, z_far) {
      let projection : T = try! payload.to()
      projection.get_frustum_corners(z_near, z_far)
    },
  )
}

///|
pub fn custom_projection3d_from_callbacks(
  type_name : String,
  payload : @any.Any,
  get_clip_from_view_fn : (@any.Any) -> ProjectionMatrix3d,
  get_clip_from_view_for_sub_fn : (@any.Any, SubCameraView3d) -> ProjectionMatrix3d,
  update_fn : (@any.Any, Float, Float) -> @any.Any,
  far_fn : (@any.Any) -> Float,
  get_frustum_corners_fn : (@any.Any, Float, Float) -> Array[@math.Vec3],
) -> CustomProjection3d {
  CustomProjection3d::{
    type_name,
    payload,
    get_clip_from_view_fn,
    get_clip_from_view_for_sub_fn,
    update_fn,
    far_fn,
    get_frustum_corners_fn,
  }
}

///|
pub fn CustomProjection3d::default() -> CustomProjection3d {
  let projection = PerspectiveProjection3d::default()
  let payload = @any.of(projection)
  custom_projection3d_from_callbacks(
    payload.type_name(),
    payload,
    fn(payload) {
      let projection : PerspectiveProjection3d = try! payload.to()
      projection.get_clip_from_view()
    },
    fn(payload, sub_view) {
      let projection : PerspectiveProjection3d = try! payload.to()
      projection.get_clip_from_view_for_sub(sub_view)
    },
    fn(payload, width, height) {
      let projection : PerspectiveProjection3d = try! payload.to()
      @any.of(projection.update(width, height))
    },
    fn(payload) {
      let projection : PerspectiveProjection3d = try! payload.to()
      projection.far
    },
    fn(payload, z_near, z_far) {
      let projection : PerspectiveProjection3d = try! payload.to()
      projection.get_frustum_corners(z_near, z_far)
    },
  )
}

///|
pub fn[T] CustomProjection3d::get(self : CustomProjection3d) -> T? {
  self.payload.try_to()
}

///|
pub fn CustomProjection3d::type_name(self : CustomProjection3d) -> String {
  self.type_name
}

///|
pub fn CustomProjection3d::get_clip_from_view(
  self : CustomProjection3d,
) -> ProjectionMatrix3d {
  (self.get_clip_from_view_fn)(self.payload)
}

///|
pub fn CustomProjection3d::get_clip_from_view_for_sub(
  self : CustomProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  (self.get_clip_from_view_for_sub_fn)(self.payload, sub_view)
}

///|
pub fn CustomProjection3d::update(
  self : CustomProjection3d,
  width : Float,
  height : Float,
) -> CustomProjection3d {
  CustomProjection3d::{
    type_name: self.type_name,
    payload: (self.update_fn)(self.payload, width, height),
    get_clip_from_view_fn: self.get_clip_from_view_fn,
    get_clip_from_view_for_sub_fn: self.get_clip_from_view_for_sub_fn,
    update_fn: self.update_fn,
    far_fn: self.far_fn,
    get_frustum_corners_fn: self.get_frustum_corners_fn,
  }
}

///|
pub fn CustomProjection3d::far(self : CustomProjection3d) -> Float {
  (self.far_fn)(self.payload)
}

///|
pub fn CustomProjection3d::get_frustum_corners(
  self : CustomProjection3d,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  (self.get_frustum_corners_fn)(self.payload, z_near, z_far)
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
pub enum Projection {
  Perspective(PerspectiveProjection3d)
  Orthographic(OrthographicProjection3d)
  Custom(CustomProjection3d)
}

///|
pub fn Projection::default() -> Projection {
  Perspective(PerspectiveProjection3d::default())
}

///|
pub fn[T : CameraProjection3d] Projection::custom(projection : T) -> Projection {
  Custom(CustomProjection3d::new(projection))
}

///|
pub fn projection_from_custom(projection : CustomProjection3d) -> Projection {
  Custom(projection)
}

///|
pub fn Projection::is_perspective(self : Projection) -> Bool {
  match self {
    Perspective(_) => true
    Orthographic(_) => false
    Custom(projection) => projection.get_clip_from_view().w_axis_w() == 0.0F
  }
}

///|
pub fn Projection::get_clip_from_view(self : Projection) -> ProjectionMatrix3d {
  match self {
    Perspective(projection) => projection.get_clip_from_view()
    Orthographic(projection) => projection.get_clip_from_view()
    Custom(projection) => projection.get_clip_from_view()
  }
}

///|
pub fn Projection::get_clip_from_view_for_sub(
  self : Projection,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  match self {
    Perspective(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Orthographic(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Custom(projection) => projection.get_clip_from_view_for_sub(sub_view)
  }
}

///|
pub fn Projection::update(
  self : Projection,
  width : Float,
  height : Float,
) -> Projection {
  match self {
    Perspective(projection) => Perspective(projection.update(width, height))
    Orthographic(projection) => Orthographic(projection.update(width, height))
    Custom(projection) => Custom(projection.update(width, height))
  }
}

///|
pub fn Projection::far(self : Projection) -> Float {
  match self {
    Perspective(projection) => projection.far
    Orthographic(projection) => projection.far
    Custom(projection) => projection.far()
  }
}

///|
pub fn Projection::get_frustum_corners(
  self : Projection,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  match self {
    Perspective(projection) => projection.get_frustum_corners(z_near, z_far)
    Orthographic(projection) => projection.get_frustum_corners(z_near, z_far)
    Custom(projection) => projection.get_frustum_corners(z_near, z_far)
  }
}

///|
pub fn Projection::compute_frustum(
  self : Projection,
  camera_transform : @transform.Transform,
) -> Frustum {
  match self {
    Perspective(projection) =>
      render3d_perspective_projection_compute_frustum(
        projection, camera_transform,
      )
    Orthographic(projection) =>
      render3d_orthographic_projection_compute_frustum(
        projection, camera_transform,
      )
    Custom(projection) => projection.compute_frustum(camera_transform)
  }
}

///|
pub impl CameraProjection3d for CustomProjection3d with get_clip_from_view(self) {
  (self.get_clip_from_view_fn)(self.payload)
}

///|
pub impl CameraProjection3d for CustomProjection3d with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  (self.get_clip_from_view_for_sub_fn)(self.payload, sub_view)
}

///|
pub impl CameraProjection3d for CustomProjection3d with update(
  self,
  width,
  height,
) {
  self.update(width, height)
}

///|
pub impl CameraProjection3d for CustomProjection3d with far(self) {
  self.far()
}

///|
pub impl CameraProjection3d for CustomProjection3d with compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for CustomProjection3d with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  self.get_frustum_corners(z_near, z_far)
}

///|
pub impl CameraProjection3d for Projection with get_clip_from_view(self) {
  self.get_clip_from_view()
}

///|
pub impl CameraProjection3d for Projection with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  self.get_clip_from_view_for_sub(sub_view)
}

///|
pub impl CameraProjection3d for Projection with update(self, width, height) {
  self.update(width, height)
}

///|
pub impl CameraProjection3d for Projection with far(self) {
  self.far()
}

///|
pub impl CameraProjection3d for Projection with compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for Projection with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  self.get_frustum_corners(z_near, z_far)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_clip_from_view(
  self,
) {
  render3d_perspective_projection_matrix(self)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  render3d_perspective_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with update(
  self,
  width,
  height,
) {
  self.aspect_ratio = render3d_projection_aspect_ratio(width, height)
  self
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with far(self) {
  self.far
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with compute_frustum(
  self,
  camera_transform,
) {
  render3d_perspective_projection_compute_frustum(self, camera_transform)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  render3d_perspective_frustum_corners(
    self.aspect_ratio,
    self.fov,
    z_near,
    z_far,
  )
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with get_clip_from_view(
  self,
) {
  render3d_orthographic_projection_matrix(
    self.area.min.x,
    self.area.max.x,
    self.area.min.y,
    self.area.max.y,
    self.far,
    self.near,
  )
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  render3d_orthographic_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with update(
  self,
  width,
  height,
) {
  self.area = render3d_orthographic_area(self, width, height)
  self
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with far(self) {
  self.far
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with compute_frustum(
  self,
  camera_transform,
) {
  render3d_orthographic_projection_compute_frustum(self, camera_transform)
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  [
    @math.Vec3::new(self.area.max.x, self.area.min.y, z_near),
    @math.Vec3::new(self.area.max.x, self.area.max.y, z_near),
    @math.Vec3::new(self.area.min.x, self.area.max.y, z_near),
    @math.Vec3::new(self.area.min.x, self.area.min.y, z_near),
    @math.Vec3::new(self.area.max.x, self.area.min.y, z_far),
    @math.Vec3::new(self.area.max.x, self.area.max.y, z_far),
    @math.Vec3::new(self.area.min.x, self.area.max.y, z_far),
    @math.Vec3::new(self.area.min.x, self.area.min.y, z_far),
  ]
}

///|
pub(all) struct ProjectionRuntime3d {
  last_view_width : Float
  last_view_height : Float
  is_orthographic : Bool
  orthographic_first_slice_depth : Float
}

///|
pub let ecs_key_projection_runtime3d : @ecs.ComponentKey[ProjectionRuntime3d] = @ecs.register_component(
  debug_name="render3d.projection_runtime3d",
)

///|
pub impl @ecs.Component for ProjectionRuntime3d with component() {
  ecs_key_projection_runtime3d
}

///|
pub let ecs_key_frustum : @ecs.ComponentKey[Frustum] = @ecs.register_component(
  debug_name="render3d.frustum",
)

///|
pub impl @ecs.Component for Frustum with component() {
  ecs_key_frustum
}
