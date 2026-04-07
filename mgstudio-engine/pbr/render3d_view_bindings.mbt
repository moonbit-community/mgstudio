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
priv struct Render3dPassProjection {
  clip_from_view : ProjectionMatrix3d
  unjittered_clip_from_view : ProjectionMatrix3d
  camera_near : Float
  camera_far : Float
}

///|
fn render3d_projection_matrix_apply_temporal_jitter(
  clip_from_view : ProjectionMatrix3d,
  temporal_jitter : TemporalJitter,
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
fn render3d_projection_near_from_clip_matrix(
  clip_from_view : ProjectionMatrix3d,
) -> Float {
  if clip_from_view.w_axis.w == 0.0F {
    maxf(0.0001F, clip_from_view.w_axis.z)
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
  Render3dPassProjection::{
    clip_from_view,
    unjittered_clip_from_view,
    camera_near: render3d_projection_near(projection, unjittered_clip_from_view),
    camera_far: projection.far(),
  }
}

///|
fn render3d_point_shadow_pass_projection(
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
  Render3dPassProjection::{
    clip_from_view,
    unjittered_clip_from_view: clip_from_view,
    camera_near: shadow_near,
    camera_far: shadow_far,
  }
}

///|
fn render3d_view_from_world_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  let inverse_rotation = render3d_quat_conjugate(transform.rotation.normalize())
  let x_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
  )
  let y_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let z_axis = quat_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
  )
  let translation = transform.translation
  // `x_axis/y_axis/z_axis` are columns of the inverse rotation matrix.
  // Translation in view space is `-(R_inv * world_translation)`.
  let offset_x = -(x_axis.x * translation.x +
    y_axis.x * translation.y +
    z_axis.x * translation.z)
  let offset_y = -(x_axis.y * translation.x +
    y_axis.y * translation.y +
    z_axis.y * translation.z)
  let offset_z = -(x_axis.z * translation.x +
    y_axis.z * translation.y +
    z_axis.z * translation.z)
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(x_axis.x, x_axis.y, x_axis.z, 0.0F),
    @math.Vec4::new(y_axis.x, y_axis.y, y_axis.z, 0.0F),
    @math.Vec4::new(z_axis.x, z_axis.y, z_axis.z, 0.0F),
    @math.Vec4::new(offset_x, offset_y, offset_z, 1.0F),
  )
}

///|
fn render3d_pass_projection_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  pass_projection.clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
}

///|
fn render3d_pass_projection_unjittered_clip_from_world(
  pass_projection : Render3dPassProjection,
  camera_transform : @transform.Transform,
) -> ProjectionMatrix3d {
  pass_projection.unjittered_clip_from_view.mul(
    render3d_view_from_world_matrix(camera_transform),
  )
}

///|
fn render3d_mesh_view_depth(
  mesh_transform : @transform.Transform,
  camera_transform : @transform.Transform,
) -> Float {
  let to_mesh = @math.Vec3::new(
    mesh_transform.translation.x - camera_transform.translation.x,
    mesh_transform.translation.y - camera_transform.translation.y,
    mesh_transform.translation.z - camera_transform.translation.z,
  )
  let camera_forward = render3d_transform_forward(camera_transform)
  to_mesh.x * camera_forward.x +
  to_mesh.y * camera_forward.y +
  to_mesh.z * camera_forward.z
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
fn render3d_camera_viewport_rect_logical(
  camera : @sprite.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (Float, Float, Float, Float)? {
  let target_width = target_size.x
  let target_height = target_size.y
  if target_width <= 0 || target_height <= 0 {
    return None
  }
  let mut viewport_x = 0
  let mut viewport_y = 0
  let mut viewport_width = target_width
  let mut viewport_height = target_height
  if camera.viewport is Some(viewport) {
    viewport_x = if viewport.physical_position.x < 0 {
      0
    } else {
      viewport.physical_position.x
    }
    viewport_y = if viewport.physical_position.y < 0 {
      0
    } else {
      viewport.physical_position.y
    }
    viewport_width = if viewport.physical_size.x < 0 {
      0
    } else {
      viewport.physical_size.x
    }
    viewport_height = if viewport.physical_size.y < 0 {
      0
    } else {
      viewport.physical_size.y
    }
    let max_width = if target_width - viewport_x < 0 {
      0
    } else {
      target_width - viewport_x
    }
    let max_height = if target_height - viewport_y < 0 {
      0
    } else {
      target_height - viewport_y
    }
    if viewport_width > max_width {
      viewport_width = max_width
    }
    if viewport_height > max_height {
      viewport_height = max_height
    }
  }
  if viewport_width <= 0 || viewport_height <= 0 {
    return None
  }
  let sf = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
  let logical_x = Float::from_double(viewport_x.to_double()) / sf
  let logical_y = Float::from_double(viewport_y.to_double()) / sf
  let logical_width = Float::from_double(viewport_width.to_double()) / sf
  let logical_height = Float::from_double(viewport_height.to_double()) / sf
  if logical_width <= 0.0F || logical_height <= 0.0F {
    return None
  }
  Some((logical_x, logical_y, logical_width, logical_height))
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
