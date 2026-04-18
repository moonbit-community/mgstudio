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
// Camera-facing owner lives in `Milky2018/mgstudio/camera/projection`.
pub type PerspectiveProjection3d = @pbr_render.PerspectiveProjection3d

///|
pub type OrthographicProjection3d = @pbr_render.OrthographicProjection3d

///|
pub type OrthographicScalingMode3d = @pbr_render.OrthographicScalingMode3d

///|
pub type SubCameraView3d = @pbr_render.SubCameraView3d

///|
pub type ProjectionMatrix3d = @pbr_render.ProjectionMatrix3d

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
struct CustomProjection3d {
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
  CustomProjection3d::{
    type_name: payload.type_name(),
    payload,
    get_clip_from_view_fn: fn(payload) {
      let projection : T = try! payload.to()
      projection.get_clip_from_view()
    },
    get_clip_from_view_for_sub_fn: fn(payload, sub_view) {
      let projection : T = try! payload.to()
      projection.get_clip_from_view_for_sub(sub_view)
    },
    update_fn: fn(payload, width, height) {
      let projection : T = try! payload.to()
      @any.of(projection.update(width, height))
    },
    far_fn: fn(payload) {
      let projection : T = try! payload.to()
      projection.far()
    },
    get_frustum_corners_fn: fn(payload, z_near, z_far) {
      let projection : T = try! payload.to()
      projection.get_frustum_corners(z_near, z_far)
    },
  }
}

///|
pub fn CustomProjection3d::default() -> CustomProjection3d {
  CustomProjection3d::new(PerspectiveProjection3d::default())
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
pub(all) enum Projection {
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
    Perspective(projection) => projection.far()
    Orthographic(projection) => projection.far()
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
pub fn render3d_perspective_projection_compute_frustum(
  projection : PerspectiveProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  @pbr_render.render3d_perspective_projection_compute_frustum(
    projection, camera_transform,
  )
}

///|
pub fn render3d_orthographic_projection_compute_frustum(
  projection : OrthographicProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  @pbr_render.render3d_orthographic_projection_compute_frustum(
    projection, camera_transform,
  )
}

///|
pub fn CustomProjection3d::compute_frustum(
  self : CustomProjection3d,
  camera_transform : @transform.Transform,
) -> Frustum {
  @pbr_render.render3d_compute_frustum(
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
pub impl CameraProjection3d for CustomProjection3d with far(self) {
  (self.far_fn)(self.payload)
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
  (self.get_frustum_corners_fn)(self.payload, z_near, z_far)
}

///|
pub impl CameraProjection3d for Projection with get_clip_from_view(self) {
  match self {
    Perspective(projection) => projection.get_clip_from_view()
    Orthographic(projection) => projection.get_clip_from_view()
    Custom(projection) => projection.get_clip_from_view()
  }
}

///|
pub impl CameraProjection3d for Projection with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  match self {
    Perspective(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Orthographic(projection) => projection.get_clip_from_view_for_sub(sub_view)
    Custom(projection) => projection.get_clip_from_view_for_sub(sub_view)
  }
}

///|
pub impl CameraProjection3d for Projection with update(self, width, height) {
  match self {
    Perspective(projection) => Perspective(projection.update(width, height))
    Orthographic(projection) => Orthographic(projection.update(width, height))
    Custom(projection) => Custom(projection.update(width, height))
  }
}

///|
pub impl CameraProjection3d for Projection with far(self) {
  match self {
    Perspective(projection) => projection.far()
    Orthographic(projection) => projection.far()
    Custom(projection) => projection.far()
  }
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
  match self {
    Perspective(projection) => projection.get_frustum_corners(z_near, z_far)
    Orthographic(projection) => projection.get_frustum_corners(z_near, z_far)
    Custom(projection) => projection.get_frustum_corners(z_near, z_far)
  }
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_clip_from_view(
  self,
) {
  @pbr_render.render3d_perspective_projection_matrix(self)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  @pbr_render.render3d_perspective_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for PerspectiveProjection3d with update(
  self,
  width,
  height,
) {
  self.aspect_ratio = @pbr_render.render3d_projection_aspect_ratio(
    width, height,
  )
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
  @pbr_render.render3d_perspective_frustum_corners(
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
  @pbr_render.render3d_orthographic_projection_matrix(
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
  @pbr_render.render3d_orthographic_projection_matrix_for_sub(self, sub_view)
}

///|
pub impl CameraProjection3d for OrthographicProjection3d with update(
  self,
  width,
  height,
) {
  self.area = @pbr_render.render3d_orthographic_area(self, width, height)
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
fn render3d_projection_near(
  projection : Projection,
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  match projection {
    Perspective(perspective) => @pbr_render.maxf(0.0001F, perspective.near)
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
) -> @pbr_render.Render3dPassProjection {
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
      let updated_projection = projection.update(
        viewport_width, viewport_height,
      )
      let is_orthographic = !updated_projection.is_perspective()
      let orthographic_first_slice_depth = if is_orthographic {
        let clip_from_view = updated_projection.get_clip_from_view()
        let row_two = clip_from_view.row(2)
        let safe_row_two_z = if row_two.z.abs() <= 1.0e-6F {
          1.0e-6F
        } else {
          row_two.z
        }
        (row_two.w - 1.0F) / safe_row_two_z
      } else {
        0.0F
      }
      let next_runtime = ProjectionRuntime3d::{
        last_view_width: viewport_width,
        last_view_height: viewport_height,
        is_orthographic,
        orthographic_first_slice_depth,
      }
      if runtime is Some(previous_runtime) &&
        previous_runtime.last_view_width == viewport_width &&
        previous_runtime.last_view_height == viewport_height &&
        previous_runtime.is_orthographic == is_orthographic &&
        previous_runtime.orthographic_first_slice_depth ==
        orthographic_first_slice_depth &&
        !force_update {
        (projection, None)
      } else {
        (updated_projection, Some(next_runtime))
      }
    }
    None => (projection, None)
  }
}
