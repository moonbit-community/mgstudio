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
pub type HalfSpace = @camera_primitives.HalfSpace

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = @camera_primitives.VIEW_FRUSTUM_NEAR_PLANE_IDX

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = @camera_primitives.VIEW_FRUSTUM_FAR_PLANE_IDX

///|
pub(open) trait CameraProjection3d {
  fn get_clip_from_view(self : Self) -> ProjectionMatrix3d
  fn get_clip_from_view_for_sub(self : Self, sub_view : SubCameraView3d) -> ProjectionMatrix3d
  fn update(self : Self, width : Float, height : Float) -> Self
  fn far(self : Self) -> Float
  fn compute_frustum(self : Self, camera_transform : @transform.Transform) -> Frustum
  fn get_frustum_corners(self : Self, z_near : Float, z_far : Float) -> Array[
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
  inner : @camera_primitives.ViewFrustum
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
  ViewFrustum::{ inner: @camera_primitives.ViewFrustum::new(half_spaces) }
}

///|
pub fn ViewFrustum::half_spaces(self : ViewFrustum) -> Array[HalfSpace] {
  self.inner.half_spaces()
}

///|
pub fn ViewFrustum::corners(self : ViewFrustum) -> Array[@math.Vec3]? {
  self.inner.corners()
}

///|
pub type Frustum = @camera_primitives.Frustum

///|
pub fn render3d_frustum_from_view_frustum(
  view_frustum : ViewFrustum,
) -> Frustum {
  @camera_primitives.Frustum::new(view_frustum.inner)
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
  render3d_frustum_from_view_frustum(
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
  get_clip_from_view_fn : () -> ProjectionMatrix3d
  get_clip_from_view_for_sub_fn : (SubCameraView3d) -> ProjectionMatrix3d
  update_fn : (Float, Float) -> CustomProjection3d
  far_fn : () -> Float
  get_frustum_corners_fn : (Float, Float) -> Array[@math.Vec3]
}

///|
pub fn[T : CameraProjection3d] CustomProjection3d::new(
  projection : T,
) -> CustomProjection3d {
  custom_projection3d_from_callbacks(
    "CustomProjection3d",
    fn() { projection.get_clip_from_view() },
    fn(sub_view) { projection.get_clip_from_view_for_sub(sub_view) },
    fn(width, height) {
      CustomProjection3d::new(projection.update(width, height))
    },
    fn() { projection.far() },
    fn(z_near, z_far) { projection.get_frustum_corners(z_near, z_far) },
  )
}

///|
pub fn custom_projection3d_from_callbacks(
  type_name : String,
  get_clip_from_view_fn : () -> ProjectionMatrix3d,
  get_clip_from_view_for_sub_fn : (SubCameraView3d) -> ProjectionMatrix3d,
  update_fn : (Float, Float) -> CustomProjection3d,
  far_fn : () -> Float,
  get_frustum_corners_fn : (Float, Float) -> Array[@math.Vec3],
) -> CustomProjection3d {
  CustomProjection3d::{
    type_name,
    get_clip_from_view_fn,
    get_clip_from_view_for_sub_fn,
    update_fn,
    far_fn,
    get_frustum_corners_fn,
  }
}

///|
pub fn CustomProjection3d::CustomProjection3d() -> CustomProjection3d {
  CustomProjection3d::new(PerspectiveProjection3d::PerspectiveProjection3d())
}

///|
pub fn CustomProjection3d::type_name(self : CustomProjection3d) -> String {
  self.type_name
}

///|
pub fn CustomProjection3d::get_clip_from_view(
  self : CustomProjection3d,
) -> ProjectionMatrix3d {
  (self.get_clip_from_view_fn)()
}

///|
pub fn CustomProjection3d::get_clip_from_view_for_sub(
  self : CustomProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  (self.get_clip_from_view_for_sub_fn)(sub_view)
}

///|
pub fn CustomProjection3d::update(
  self : CustomProjection3d,
  width : Float,
  height : Float,
) -> CustomProjection3d {
  (self.update_fn)(width, height)
}

///|
pub fn CustomProjection3d::far(self : CustomProjection3d) -> Float {
  (self.far_fn)()
}

///|
pub fn CustomProjection3d::get_frustum_corners(
  self : CustomProjection3d,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  (self.get_frustum_corners_fn)(z_near, z_far)
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
  Perspective(PerspectiveProjection3d::PerspectiveProjection3d())
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
pub impl CameraProjection3d for CustomProjection3d with fn get_clip_from_view(
  self,
) {
  self.get_clip_from_view()
}

///|
pub impl CameraProjection3d for CustomProjection3d with fn get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  self.get_clip_from_view_for_sub(sub_view)
}

///|
pub impl CameraProjection3d for CustomProjection3d with fn update(
  self,
  width,
  height,
) {
  self.update(width, height)
}

///|
pub impl CameraProjection3d for CustomProjection3d with fn far(self) {
  self.far()
}

///|
pub impl CameraProjection3d for CustomProjection3d with fn compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for CustomProjection3d with fn get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  self.get_frustum_corners(z_near, z_far)
}

///|
pub impl CameraProjection3d for Projection with fn get_clip_from_view(self) {
  self.get_clip_from_view()
}

///|
pub impl CameraProjection3d for Projection with fn get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  self.get_clip_from_view_for_sub(sub_view)
}

///|
pub impl CameraProjection3d for Projection with fn update(self, width, height) {
  self.update(width, height)
}

///|
pub impl CameraProjection3d for Projection with fn far(self) {
  self.far()
}

///|
pub impl CameraProjection3d for Projection with fn compute_frustum(
  self,
  camera_transform,
) {
  self.compute_frustum(camera_transform)
}

///|
pub impl CameraProjection3d for Projection with fn get_frustum_corners(
  self,
  z_near,
  z_far,
) {
  self.get_frustum_corners(z_near, z_far)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with fn get_clip_from_view(
  self,
) {
  render3d_perspective_projection_matrix(self)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with fn get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  render3d_perspective_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with fn update(
  self,
  width,
  height,
) {
  self.aspect_ratio = render3d_projection_aspect_ratio(width, height)
  self
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with fn far(self) {
  self.far
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with fn compute_frustum(
  self,
  camera_transform,
) {
  render3d_perspective_projection_compute_frustum(self, camera_transform)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with fn get_frustum_corners(
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
pub impl CameraProjection3d for OrthographicProjection3d with fn get_clip_from_view(
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
pub impl CameraProjection3d for OrthographicProjection3d with fn get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  render3d_orthographic_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with fn update(
  self,
  width,
  height,
) {
  self.area = render3d_orthographic_area(self, width, height)
  self
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with fn far(self) {
  self.far
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with fn compute_frustum(
  self,
  camera_transform,
) {
  render3d_orthographic_projection_compute_frustum(self, camera_transform)
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with fn get_frustum_corners(
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
pub impl @ecs.Component for ProjectionRuntime3d with fn component() {
  ecs_key_projection_runtime3d
}

///|
pub let ecs_key_frustum : @ecs.ComponentKey[Frustum] = @camera_primitives.ecs_key_frustum
