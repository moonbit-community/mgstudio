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
pub struct SubCameraView3d {
  full_size : @math.IVec2
  offset : @math.Vec2
  size : @math.IVec2
} derive(ToJson, FromJson)

///|
fn sub_camera_view3d_sanitize(
  full_size : @math.IVec2,
  offset : @math.Vec2,
  size : @math.IVec2,
) -> SubCameraView3d {
  let safe_full_width = if full_size.x <= 0 { 1 } else { full_size.x }
  let safe_full_height = if full_size.y <= 0 { 1 } else { full_size.y }
  let safe_size_width = if size.x <= 0 { 1 } else { size.x }
  let safe_size_height = if size.y <= 0 { 1 } else { size.y }
  SubCameraView3d::{
    full_size: @math.IVec2::new(safe_full_width, safe_full_height),
    offset,
    size: @math.IVec2::new(safe_size_width, safe_size_height),
  }
}

///|
pub fn SubCameraView3d::new(
  full_size : @math.IVec2,
  offset : @math.Vec2,
  size : @math.IVec2,
) -> SubCameraView3d {
  sub_camera_view3d_sanitize(full_size, offset, size)
}

///|
pub fn SubCameraView3d::with_offset(
  self : SubCameraView3d,
  offset : @math.Vec2,
) -> SubCameraView3d {
  sub_camera_view3d_sanitize(self.full_size, offset, self.size)
}

///|
pub let ecs_key_sub_camera_view3d : @ecs.ComponentKey[SubCameraView3d] = @ecs.register_component(
  debug_name="bevy_core_pipeline::core_3d::SubCameraView",
)

///|
pub impl @ecs.Component for SubCameraView3d with component() {
  ecs_key_sub_camera_view3d
}

///|
pub(all) enum OrthographicScalingMode3d {
  WindowSize
  Fixed(Float, Float)
  AutoMin(Float, Float)
  AutoMax(Float, Float)
  FixedVertical(Float)
  FixedHorizontal(Float)
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn orthographic_scaling_mode_sanitize(
  mode : OrthographicScalingMode3d,
) -> OrthographicScalingMode3d {
  match mode {
    WindowSize => WindowSize
    Fixed(width, height) =>
      Fixed(
        if width <= 0.0F {
          1.0F
        } else {
          width
        },
        if height <= 0.0F {
          1.0F
        } else {
          height
        },
      )
    AutoMin(min_width, min_height) =>
      AutoMin(
        if min_width <= 0.0F {
          1.0F
        } else {
          min_width
        },
        if min_height <= 0.0F {
          1.0F
        } else {
          min_height
        },
      )
    AutoMax(max_width, max_height) =>
      AutoMax(
        if max_width <= 0.0F {
          1.0F
        } else {
          max_width
        },
        if max_height <= 0.0F {
          1.0F
        } else {
          max_height
        },
      )
    FixedVertical(viewport_height) =>
      FixedVertical(
        if viewport_height <= 0.0F {
          1.0F
        } else {
          viewport_height
        },
      )
    FixedHorizontal(viewport_width) =>
      FixedHorizontal(
        if viewport_width <= 0.0F {
          1.0F
        } else {
          viewport_width
        },
      )
  }
}

///|
pub(all) struct PerspectiveProjection3d {
  mut fov : Float
  mut near : Float
  mut far : Float
  mut aspect_ratio : Float
  mut near_clip_plane : @math.Vec4
} derive(ToJson, FromJson)

///|
pub fn PerspectiveProjection3d::default() -> PerspectiveProjection3d {
  PerspectiveProjection3d::{
    // Match Bevy's PerspectiveProjection::default() (PI / 4.0).
    fov: @math.pi_half() * 0.5F,
    near: 0.1F,
    far: 1000.0F,
    aspect_ratio: 1.0F,
    near_clip_plane: @math.Vec4::new(0.0F, 0.0F, -1.0F, -0.1F),
  }
}

///|
pub fn PerspectiveProjection3d::with_aspect_ratio(
  self : PerspectiveProjection3d,
  aspect_ratio : Float,
) -> PerspectiveProjection3d {
  let safe_aspect = if aspect_ratio <= 0.0F { 1.0F } else { aspect_ratio }
  PerspectiveProjection3d::{
    fov: self.fov,
    near: self.near,
    far: self.far,
    aspect_ratio: safe_aspect,
    near_clip_plane: self.near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::with_fov(
  self : PerspectiveProjection3d,
  fov : Float,
) -> PerspectiveProjection3d {
  let safe_fov = if fov <= 0.0F { @math.pi_half() * 0.5F } else { fov }
  PerspectiveProjection3d::{
    fov: safe_fov,
    near: self.near,
    far: self.far,
    aspect_ratio: self.aspect_ratio,
    near_clip_plane: self.near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::with_near(
  self : PerspectiveProjection3d,
  near : Float,
) -> PerspectiveProjection3d {
  let previous_default_near_clip_plane = @math.Vec4::new(
    0.0F,
    0.0F,
    -1.0F,
    -self.near,
  )
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  let safe_far = if self.far <= safe_near {
    safe_near + 0.0001F
  } else {
    self.far
  }
  let near_clip_plane = if self.near_clip_plane ==
    previous_default_near_clip_plane {
    @math.Vec4::new(0.0F, 0.0F, -1.0F, -safe_near)
  } else {
    self.near_clip_plane
  }
  PerspectiveProjection3d::{
    fov: self.fov,
    near: safe_near,
    far: safe_far,
    aspect_ratio: self.aspect_ratio,
    near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::with_far(
  self : PerspectiveProjection3d,
  far : Float,
) -> PerspectiveProjection3d {
  let safe_far = if far <= self.near { self.near + 0.0001F } else { far }
  PerspectiveProjection3d::{
    fov: self.fov,
    near: self.near,
    far: safe_far,
    aspect_ratio: self.aspect_ratio,
    near_clip_plane: self.near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::with_near_clip_plane(
  self : PerspectiveProjection3d,
  near_clip_plane : @math.Vec4,
) -> PerspectiveProjection3d {
  PerspectiveProjection3d::{
    fov: self.fov,
    near: self.near,
    far: self.far,
    aspect_ratio: self.aspect_ratio,
    near_clip_plane,
  }
}

///|
pub fn PerspectiveProjection3d::fov(self : PerspectiveProjection3d) -> Float {
  self.fov
}

///|
pub fn PerspectiveProjection3d::near(self : PerspectiveProjection3d) -> Float {
  self.near
}

///|
pub fn PerspectiveProjection3d::far(self : PerspectiveProjection3d) -> Float {
  self.far
}

///|
pub fn PerspectiveProjection3d::aspect_ratio(
  self : PerspectiveProjection3d,
) -> Float {
  self.aspect_ratio
}

///|
pub fn PerspectiveProjection3d::near_clip_plane(
  self : PerspectiveProjection3d,
) -> @math.Vec4 {
  self.near_clip_plane
}

///|
pub(all) struct OrthographicProjection3d {
  mut near : Float
  mut far : Float
  mut viewport_origin : @math.Vec2
  mut scaling_mode : OrthographicScalingMode3d
  mut scale : Float
  mut area : @math.Rect
} derive(ToJson, FromJson)

///|
pub fn OrthographicProjection3d::default_2d() -> OrthographicProjection3d {
  OrthographicProjection3d::{
    ..OrthographicProjection3d::default_3d(),
    near: -1000.0F,
  }
}

///|
pub fn OrthographicProjection3d::default_3d() -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: 0.0F,
    far: 1000.0F,
    viewport_origin: @math.Vec2::new(0.5F, 0.5F),
    scaling_mode: WindowSize,
    scale: 1.0F,
    area: @math.Rect::new(
      @math.Vec2::new(-1.0F, -1.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ),
  }
}

///|
pub fn OrthographicProjection3d::default() -> OrthographicProjection3d {
  OrthographicProjection3d::default_3d()
}

///|
pub fn OrthographicProjection3d::with_scale(
  self : OrthographicProjection3d,
  scale : Float,
) -> OrthographicProjection3d {
  let safe_scale = if scale <= 0.0F { 1.0F } else { scale }
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    scale: safe_scale,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_near(
  self : OrthographicProjection3d,
  near : Float,
) -> OrthographicProjection3d {
  let safe_far = if self.far <= near { near + 0.0001F } else { self.far }
  OrthographicProjection3d::{
    scale: self.scale,
    near,
    far: safe_far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_far(
  self : OrthographicProjection3d,
  far : Float,
) -> OrthographicProjection3d {
  let safe_far = if far <= self.near { self.near + 0.0001F } else { far }
  OrthographicProjection3d::{
    scale: self.scale,
    near: self.near,
    far: safe_far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_scaling_mode(
  self : OrthographicProjection3d,
  scaling_mode : OrthographicScalingMode3d,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin: self.viewport_origin,
    scaling_mode: orthographic_scaling_mode_sanitize(scaling_mode),
    scale: self.scale,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_viewport_origin(
  self : OrthographicProjection3d,
  viewport_origin : @math.Vec2,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin,
    scaling_mode: self.scaling_mode,
    scale: self.scale,
    area: self.area,
  }
}

///|
pub fn OrthographicProjection3d::with_area(
  self : OrthographicProjection3d,
  area : @math.Rect,
) -> OrthographicProjection3d {
  OrthographicProjection3d::{
    near: self.near,
    far: self.far,
    viewport_origin: self.viewport_origin,
    scaling_mode: self.scaling_mode,
    scale: self.scale,
    area,
  }
}

///|
pub fn OrthographicProjection3d::scale(
  self : OrthographicProjection3d,
) -> Float {
  self.scale
}

///|
pub fn OrthographicProjection3d::near(self : OrthographicProjection3d) -> Float {
  self.near
}

///|
pub fn OrthographicProjection3d::far(self : OrthographicProjection3d) -> Float {
  self.far
}

///|
pub fn OrthographicProjection3d::scaling_mode(
  self : OrthographicProjection3d,
) -> OrthographicScalingMode3d {
  self.scaling_mode
}

///|
pub fn OrthographicProjection3d::viewport_origin(
  self : OrthographicProjection3d,
) -> @math.Vec2 {
  self.viewport_origin
}

///|
pub fn OrthographicProjection3d::area(
  self : OrthographicProjection3d,
) -> @math.Rect {
  self.area
}

///|
pub fn render3d_orthographic_projection_matrix_for_sub(
  orthographic : OrthographicProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  let full_width = Float::from_double(sub_view.full_size.x.to_double())
  let full_height = Float::from_double(sub_view.full_size.y.to_double())
  let sub_width = Float::from_double(sub_view.size.x.to_double())
  let sub_height = Float::from_double(sub_view.size.y.to_double())
  if full_width <= 0.0F ||
    full_height <= 0.0F ||
    sub_width <= 0.0F ||
    sub_height <= 0.0F {
    return orthographic.get_clip_from_view()
  }
  let top = orthographic.area.max.y
  let bottom = orthographic.area.min.y
  let orthographic_height = top - bottom
  let orthographic_width = orthographic_height *
    render3d_projection_aspect_ratio(full_width, full_height)
  let center_x = (orthographic.area.max.x + orthographic.area.min.x) * 0.5F
  let left = center_x - orthographic_width * 0.5F
  let right = center_x + orthographic_width * 0.5F
  let scale_w = (right - left) / full_width
  let scale_h = (top - bottom) / full_height
  let left_prime = left + scale_w * sub_view.offset.x
  let right_prime = left_prime + scale_w * sub_width
  let top_prime = top - scale_h * sub_view.offset.y
  let bottom_prime = top_prime - scale_h * sub_height
  render3d_orthographic_projection_matrix(
    left_prime,
    right_prime,
    bottom_prime,
    top_prime,
    orthographic.far,
    orthographic.near,
  )
}

///|
pub fn render3d_orthographic_area(
  orthographic : OrthographicProjection3d,
  view_width : Float,
  view_height : Float,
) -> @math.Rect {
  let safe_view_width = if view_width <= 0.0F { 1.0F } else { view_width }
  let safe_view_height = if view_height <= 0.0F { 1.0F } else { view_height }
  let (projection_width, projection_height) = match orthographic.scaling_mode {
    WindowSize => (safe_view_width, safe_view_height)
    AutoMin(min_width, min_height) =>
      if safe_view_width * min_height > min_width * safe_view_height {
        (safe_view_width * min_height / safe_view_height, min_height)
      } else {
        (min_width, safe_view_height * min_width / safe_view_width)
      }
    AutoMax(max_width, max_height) =>
      if safe_view_width * max_height < max_width * safe_view_height {
        (safe_view_width * max_height / safe_view_height, max_height)
      } else {
        (max_width, safe_view_height * max_width / safe_view_width)
      }
    FixedVertical(viewport_height) =>
      (safe_view_width * viewport_height / safe_view_height, viewport_height)
    FixedHorizontal(viewport_width) =>
      (viewport_width, safe_view_height * viewport_width / safe_view_width)
    Fixed(width, height) => (width, height)
  }
  let origin_x = projection_width * orthographic.viewport_origin.x
  let origin_y = projection_height * orthographic.viewport_origin.y
  @math.Rect::new(
    @math.Vec2::new(
      orthographic.scale * -origin_x,
      orthographic.scale * -origin_y,
    ),
    @math.Vec2::new(
      orthographic.scale * (projection_width - origin_x),
      orthographic.scale * (projection_height - origin_y),
    ),
  )
}

///|
fn render3d_adjust_perspective_matrix_for_clip_plane(
  projection : PerspectiveProjection3d,
  matrix : ProjectionMatrix3d,
) -> ProjectionMatrix3d {
  let clip_plane = projection.near_clip_plane
  if clip_plane == render3d_default_near_clip_plane(projection.near) {
    return matrix
  }
  match render3d_projection_matrix_inverse(matrix) {
    None => matrix
    Some(inverse) => {
      let q_prime = @math.Vec4::new(
        render3d_signum(clip_plane.x),
        render3d_signum(clip_plane.y),
        0.0F,
        1.0F,
      )
      let q = inverse.mul_vec4(q_prime)
      let denominator = render3d_vec4_dot(clip_plane, q)
      let safe_denominator = if denominator >= -1.0e-12F &&
        denominator <= 1.0e-12F {
        1.0F
      } else {
        denominator
      }
      let a = -q.z / safe_denominator
      let m3_prime = @math.Vec4::new(
        -clip_plane.x * a,
        -clip_plane.y * a,
        -1.0F - clip_plane.z * a,
        -clip_plane.w * a,
      )
      ProjectionMatrix3d::{
        x_axis: @math.Vec4::new(
          matrix.x_axis.x,
          matrix.x_axis.y,
          m3_prime.x,
          matrix.x_axis.w,
        ),
        y_axis: @math.Vec4::new(
          matrix.y_axis.x,
          matrix.y_axis.y,
          m3_prime.y,
          matrix.y_axis.w,
        ),
        z_axis: @math.Vec4::new(
          matrix.z_axis.x,
          matrix.z_axis.y,
          m3_prime.z,
          matrix.z_axis.w,
        ),
        w_axis: @math.Vec4::new(
          matrix.w_axis.x,
          matrix.w_axis.y,
          m3_prime.w,
          matrix.w_axis.w,
        ),
      }
    }
  }
}

///|
pub fn render3d_perspective_projection_matrix(
  projection : PerspectiveProjection3d,
) -> ProjectionMatrix3d {
  render3d_adjust_perspective_matrix_for_clip_plane(
    projection,
    render3d_perspective_projection_matrix_raw(
      projection.near,
      projection.fov,
      projection.aspect_ratio,
    ),
  )
}

///|
pub fn render3d_perspective_projection_matrix_for_sub(
  projection : PerspectiveProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  let full_width = Float::from_double(sub_view.full_size.x.to_double())
  let full_height = Float::from_double(sub_view.full_size.y.to_double())
  let sub_width = Float::from_double(sub_view.size.x.to_double())
  let sub_height = Float::from_double(sub_view.size.y.to_double())
  if full_width <= 0.0F ||
    full_height <= 0.0F ||
    sub_width <= 0.0F ||
    sub_height <= 0.0F {
    return projection.get_clip_from_view()
  }
  let near = if projection.near <= 0.0F { 0.0001F } else { projection.near }
  let offset_x = sub_view.offset.x
  let offset_y = full_height - (sub_view.offset.y + sub_height)
  let full_aspect = full_width / full_height
  let half_fov = projection.fov * 0.5F
  let cos_half_fov = @math.cos(half_fov)
  let tan_half_fov = if cos_half_fov == 0.0F {
    1.0F
  } else {
    @math.sin(half_fov) / cos_half_fov
  }
  let top = near * tan_half_fov
  let bottom = -top
  let right = top * full_aspect
  let left = -right
  let width = right - left
  let height = top - bottom
  let left_prime = left + width * offset_x / full_width
  let right_prime = left + width * (offset_x + sub_width) / full_width
  let bottom_prime = bottom + height * offset_y / full_height
  let top_prime = bottom + height * (offset_y + sub_height) / full_height
  let x = 2.0F * near / (right_prime - left_prime)
  let y = 2.0F * near / (top_prime - bottom_prime)
  let a = (right_prime + left_prime) / (right_prime - left_prime)
  let b = (top_prime + bottom_prime) / (top_prime - bottom_prime)
  render3d_adjust_perspective_matrix_for_clip_plane(
    projection,
    ProjectionMatrix3d::from_cols(
      @math.Vec4::new(x, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, y, 0.0F, 0.0F),
      @math.Vec4::new(a, b, 0.0F, -1.0F),
      @math.Vec4::new(0.0F, 0.0F, near, 0.0F),
    ),
  )
}

///|
pub fn PerspectiveProjection3d::get_clip_from_view(
  self : PerspectiveProjection3d,
) -> ProjectionMatrix3d {
  render3d_perspective_projection_matrix(self)
}

///|
pub fn PerspectiveProjection3d::get_clip_from_view_for_sub(
  self : PerspectiveProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  render3d_perspective_projection_matrix_for_sub(self, sub_view)
}

///|
pub fn PerspectiveProjection3d::update(
  self : PerspectiveProjection3d,
  width : Float,
  height : Float,
) -> PerspectiveProjection3d {
  self.aspect_ratio = render3d_projection_aspect_ratio(width, height)
  self
}

///|
pub fn PerspectiveProjection3d::get_frustum_corners(
  self : PerspectiveProjection3d,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  render3d_perspective_frustum_corners(
    self.aspect_ratio,
    self.fov,
    z_near,
    z_far,
  )
}

///|
pub fn OrthographicProjection3d::get_clip_from_view(
  self : OrthographicProjection3d,
) -> ProjectionMatrix3d {
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
pub fn OrthographicProjection3d::get_clip_from_view_for_sub(
  self : OrthographicProjection3d,
  sub_view : SubCameraView3d,
) -> ProjectionMatrix3d {
  render3d_orthographic_projection_matrix_for_sub(self, sub_view)
}

///|
pub fn OrthographicProjection3d::update(
  self : OrthographicProjection3d,
  width : Float,
  height : Float,
) -> OrthographicProjection3d {
  self.area = render3d_orthographic_area(self, width, height)
  self
}

///|
pub fn OrthographicProjection3d::get_frustum_corners(
  self : OrthographicProjection3d,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
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
pub(all) struct ProjectionMatrix3d {
  x_axis : @math.Vec4
  y_axis : @math.Vec4
  z_axis : @math.Vec4
  w_axis : @math.Vec4
}

///|
pub fn ProjectionMatrix3d::from_cols(
  x_axis : @math.Vec4,
  y_axis : @math.Vec4,
  z_axis : @math.Vec4,
  w_axis : @math.Vec4,
) -> ProjectionMatrix3d {
  ProjectionMatrix3d::{ x_axis, y_axis, z_axis, w_axis }
}

///|
pub fn ProjectionMatrix3d::mul_vec4(
  self : ProjectionMatrix3d,
  value : @math.Vec4,
) -> @math.Vec4 {
  @math.Vec4::new(
    self.x_axis.x * value.x +
    self.y_axis.x * value.y +
    self.z_axis.x * value.z +
    self.w_axis.x * value.w,
    self.x_axis.y * value.x +
    self.y_axis.y * value.y +
    self.z_axis.y * value.z +
    self.w_axis.y * value.w,
    self.x_axis.z * value.x +
    self.y_axis.z * value.y +
    self.z_axis.z * value.z +
    self.w_axis.z * value.w,
    self.x_axis.w * value.x +
    self.y_axis.w * value.y +
    self.z_axis.w * value.z +
    self.w_axis.w * value.w,
  )
}

///|
pub fn ProjectionMatrix3d::mul(
  self : ProjectionMatrix3d,
  other : ProjectionMatrix3d,
) -> ProjectionMatrix3d {
  ProjectionMatrix3d::from_cols(
    self.mul_vec4(other.x_axis),
    self.mul_vec4(other.y_axis),
    self.mul_vec4(other.z_axis),
    self.mul_vec4(other.w_axis),
  )
}

///|
pub fn ProjectionMatrix3d::project_point3(
  self : ProjectionMatrix3d,
  value : @math.Vec3,
) -> @math.Vec3? {
  let clip = self.mul_vec4(@math.Vec4::new(value.x, value.y, value.z, 1.0F))
  if clip.w == 0.0F {
    return None
  }
  Some(@math.Vec3::new(clip.x / clip.w, clip.y / clip.w, clip.z / clip.w))
}

///|
pub fn ProjectionMatrix3d::w_axis_w(self : ProjectionMatrix3d) -> Float {
  self.w_axis.w
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
pub fn render3d_projection_matrix_inverse(
  matrix : ProjectionMatrix3d,
) -> ProjectionMatrix3d? {
  let augmented : Array[Float] = [
    matrix.x_axis.x,
    matrix.y_axis.x,
    matrix.z_axis.x,
    matrix.w_axis.x,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    matrix.x_axis.y,
    matrix.y_axis.y,
    matrix.z_axis.y,
    matrix.w_axis.y,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    matrix.x_axis.z,
    matrix.y_axis.z,
    matrix.z_axis.z,
    matrix.w_axis.z,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    matrix.x_axis.w,
    matrix.y_axis.w,
    matrix.z_axis.w,
    matrix.w_axis.w,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
  ]
  for pivot in 0..<4 {
    let mut pivot_row = pivot
    let pivot_index = pivot * 8 + pivot
    let mut pivot_abs = if augmented[pivot_index] < 0.0F {
      -augmented[pivot_index]
    } else {
      augmented[pivot_index]
    }
    for row in (pivot + 1)..<4 {
      let value = augmented[row * 8 + pivot]
      let value_abs = if value < 0.0F { -value } else { value }
      if value_abs > pivot_abs {
        pivot_row = row
        pivot_abs = value_abs
      }
    }
    if pivot_abs <= 1.0e-12F {
      return None
    }
    if pivot_row != pivot {
      for col in 0..<8 {
        let lhs_index = pivot * 8 + col
        let rhs_index = pivot_row * 8 + col
        let tmp = augmented[lhs_index]
        augmented[lhs_index] = augmented[rhs_index]
        augmented[rhs_index] = tmp
      }
    }
    let pivot_value = augmented[pivot * 8 + pivot]
    for col in 0..<8 {
      let index = pivot * 8 + col
      augmented[index] = augmented[index] / pivot_value
    }
    for row in 0..<4 {
      if row == pivot {
        continue
      }
      let factor = augmented[row * 8 + pivot]
      if factor == 0.0F {
        continue
      }
      for col in 0..<8 {
        let row_index = row * 8 + col
        let pivot_row_index = pivot * 8 + col
        augmented[row_index] = augmented[row_index] -
          factor * augmented[pivot_row_index]
      }
    }
  }
  Some(
    ProjectionMatrix3d::from_cols(
      @math.Vec4::new(augmented[4], augmented[12], augmented[20], augmented[28]),
      @math.Vec4::new(augmented[5], augmented[13], augmented[21], augmented[29]),
      @math.Vec4::new(augmented[6], augmented[14], augmented[22], augmented[30]),
      @math.Vec4::new(augmented[7], augmented[15], augmented[23], augmented[31]),
    ),
  )
}

///|
pub(all) struct Render3dPassProjection {
  clip_from_view : ProjectionMatrix3d
  unjittered_clip_from_view : ProjectionMatrix3d
  camera_near : Float
  camera_far : Float
}

///|
pub fn render3d_pass_projection(
  clip_from_view : ProjectionMatrix3d,
  unjittered_clip_from_view : ProjectionMatrix3d,
  camera_near : Float,
  camera_far : Float,
) -> Render3dPassProjection {
  Render3dPassProjection::{
    clip_from_view,
    unjittered_clip_from_view,
    camera_near,
    camera_far,
  }
}

///|
pub fn render3d_point_shadow_pass_projection(
  near : Float,
  far : Float,
) -> Render3dPassProjection {
  let shadow_near = if near > 0.0001F { near } else { 0.0001F }
  let shadow_far = if far > shadow_near { far } else { shadow_near + 1.0F }
  let clip_from_view = render3d_perspective_projection_matrix_raw(
    shadow_near,
    @math.pi_half(),
    1.0F,
  )
  render3d_pass_projection(
    clip_from_view, clip_from_view, shadow_near, shadow_far,
  )
}

///|
pub fn render3d_pass_projection_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  pass_projection.clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
}

///|
pub fn render3d_pass_projection_unjittered_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  pass_projection.unjittered_clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
}

///|
pub fn render3d_projection_matrix_apply_temporal_jitter(
  clip_from_view : ProjectionMatrix3d,
  temporal_jitter : @post_process.TemporalJitter,
  view_width : Int,
  view_height : Int,
) -> ProjectionMatrix3d {
  let width = Float::from_double(view_width.to_double())
  let height = Float::from_double(view_height.to_double())
  if width <= 0.0F || height <= 0.0F {
    return clip_from_view
  }
  let mut jitter_x = temporal_jitter.offset.x * 2.0F / width
  let mut jitter_y = temporal_jitter.offset.y * -2.0F / height
  if clip_from_view.w_axis.w == 1.0F {
    jitter_x = jitter_x * clip_from_view.x_axis.x * 0.5F
    jitter_y = jitter_y * clip_from_view.y_axis.y * 0.5F
  }
  let z_axis = clip_from_view.z_axis
  ProjectionMatrix3d::{
    ..clip_from_view,
    z_axis: @math.Vec4::new(
      z_axis.x + jitter_x,
      z_axis.y + jitter_y,
      z_axis.z,
      z_axis.w,
    ),
  }
}

///|
pub fn render3d_projection_near_from_clip_matrix(
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  if clip_from_view.w_axis.w == 0.0F {
    if clip_from_view.w_axis.z > 0.0001F {
      clip_from_view.w_axis.z
    } else {
      0.0001F
    }
  } else {
    let safe_z = if clip_from_view.z_axis.z == 0.0F {
      1.0F
    } else {
      clip_from_view.z_axis.z
    }
    clip_from_view.w_axis.z / safe_z
  }
}

///|
pub fn render3d_orthographic_projection_matrix(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> ProjectionMatrix3d {
  let width = right - left
  let height = top - bottom
  let depth = near - far
  let safe_width = if width == 0.0F { 1.0F } else { width }
  let safe_height = if height == 0.0F { 1.0F } else { height }
  let safe_depth = if depth == 0.0F { 1.0F } else { depth }
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(2.0F / safe_width, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 2.0F / safe_height, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F / safe_depth, 0.0F),
    @math.Vec4::new(
      -(right + left) / safe_width,
      -(top + bottom) / safe_height,
      near / safe_depth,
      1.0F,
    ),
  )
}

///|
pub fn render3d_perspective_projection_matrix_raw(
  near : Float,
  fov : Float,
  aspect_ratio : Float,
) -> ProjectionMatrix3d {
  let safe_aspect = if aspect_ratio <= 0.0F { 1.0F } else { aspect_ratio }
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  let half_fov = fov * 0.5F
  let cos_half_fov = @math.cos(half_fov)
  let tan_half_fov = if cos_half_fov == 0.0F {
    1.0F
  } else {
    @math.sin(half_fov) / cos_half_fov
  }
  let y = if tan_half_fov == 0.0F { 1.0F } else { 1.0F / tan_half_fov }
  let x = y / safe_aspect
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, y, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 0.0F, -1.0F),
    @math.Vec4::new(0.0F, 0.0F, safe_near, 0.0F),
  )
}

///|
pub fn render3d_perspective_frustum_corners(
  aspect_ratio : Float,
  fov : Float,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  let half_fov = fov * 0.5F
  let cos_half_fov = @math.cos(half_fov)
  let tan_half_fov = if cos_half_fov == 0.0F {
    1.0F
  } else {
    @math.sin(half_fov) / cos_half_fov
  }
  let near_half_height = tan_half_fov *
    (if z_near < 0.0F { -z_near } else { z_near })
  let far_half_height = tan_half_fov *
    (if z_far < 0.0F { -z_far } else { z_far })
  let near_half_width = near_half_height * aspect_ratio
  let far_half_width = far_half_height * aspect_ratio
  [
    @math.Vec3::new(near_half_width, -near_half_height, z_near),
    @math.Vec3::new(near_half_width, near_half_height, z_near),
    @math.Vec3::new(-near_half_width, near_half_height, z_near),
    @math.Vec3::new(-near_half_width, -near_half_height, z_near),
    @math.Vec3::new(far_half_width, -far_half_height, z_far),
    @math.Vec3::new(far_half_width, far_half_height, z_far),
    @math.Vec3::new(-far_half_width, far_half_height, z_far),
    @math.Vec3::new(-far_half_width, -far_half_height, z_far),
  ]
}
