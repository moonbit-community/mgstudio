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
fn render3d_projection_matrix_apply_temporal_jitter(
  clip_from_view : ProjectionMatrix3d,
  temporal_jitter : TemporalJitter,
  view_width : Int,
  view_height : Int,
) -> ProjectionMatrix3d {
  @pbr_render.render3d_projection_matrix_apply_temporal_jitter(
    clip_from_view, temporal_jitter, view_width, view_height,
  )
}

///|
fn render3d_projection_near_from_clip_matrix(
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  @pbr_render.render3d_projection_near_from_clip_matrix(clip_from_view)
}

///|
fn render3d_projection_near(
  projection : Projection,
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  match projection {
    Perspective(perspective) => maxf(0.0001F, perspective.near)
    Orthographic(orthographic) => orthographic.near
    Custom(_) => render3d_projection_near_from_clip_matrix(clip_from_view)
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
      render3d_projection_matrix_apply_temporal_jitter(
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
fn render3d_point_shadow_pass_projection(
  near : Float,
  far : Float,
) -> Render3dPassProjection {
  @pbr_render.render3d_point_shadow_pass_projection(near, far)
}

///|
fn render3d_view_from_world_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  @pbr_render.render3d_view_from_world_matrix(transform)
}

///|
fn render3d_pass_projection_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  @pbr_render.render3d_pass_projection_clip_from_world(
    pass_projection, camera_transform,
  )
}

///|
fn render3d_pass_projection_unjittered_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  @pbr_render.render3d_pass_projection_unjittered_clip_from_world(
    pass_projection, camera_transform,
  )
}

///|
fn render3d_orthographic_projection_matrix(
  left : Float,
  right : Float,
  bottom : Float,
  top : Float,
  near : Float,
  far : Float,
) -> ProjectionMatrix3d {
  @pbr_render.render3d_orthographic_projection_matrix(
    left, right, bottom, top, near, far,
  )
}

///|
fn render3d_orthographic_projection_matrix_for_sub(
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
fn render3d_projection_matrix_inverse(
  matrix : ProjectionMatrix3d,
) -> ProjectionMatrix3d? {
  @pbr_render.render3d_projection_matrix_inverse(matrix)
}

///|
fn render3d_camera_viewport_rect_logical(
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Float, Float, Float, Float)? {
  @pbr_render.render3d_camera_viewport_rect_logical(
    camera, target_size, scale_factor,
  )
}

///|
fn render3d_orthographic_area(
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
fn render3d_projection_runtime_projection(
  projection : Projection,
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> Projection {
  match
    render3d_camera_viewport_rect_logical(camera, target_size, scale_factor) {
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
    render3d_camera_viewport_rect_logical(camera, target_size, scale_factor) {
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
fn render3d_perspective_projection_matrix_raw(
  near : Float,
  fov : Float,
  aspect_ratio : Float,
) -> ProjectionMatrix3d {
  @pbr_render.render3d_perspective_projection_matrix_raw(
    near, fov, aspect_ratio,
  )
}

///|
fn render3d_perspective_projection_matrix(
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
fn render3d_perspective_projection_matrix_for_sub(
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
fn render3d_perspective_frustum_corners(
  aspect_ratio : Float,
  fov : Float,
  z_near : Float,
  z_far : Float,
) -> Array[@math.Vec3] {
  @pbr_render.render3d_perspective_frustum_corners(
    aspect_ratio, fov, z_near, z_far,
  )
}
