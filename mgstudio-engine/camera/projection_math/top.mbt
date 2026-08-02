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
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs`
// (`Camera::world_to_viewport`, `Camera::viewport_to_world`) and the projection
// helpers they use.
//
// Bevy owns this math in `bevy_camera`, and `bevy_pbr` depends on `bevy_camera`
// rather than the reverse. mgstudio had it in `pbr`, with `camera` importing
// `pbr` to forward to it. That inversion is what closed the
// `light -> gizmos -> camera -> pbr -> ... -> light` package cycle. This leaf
// package holds the real owner so both `camera` and `pbr` can use it, and so
// consumers that only need camera projection do not have to pull in `pbr`.

///|
pub using @camera_projection3d {type Projection, type ProjectionMatrix3d}

///|
pub fn camera_viewport_rect_logical(
  camera : @camera_camera.Camera,
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
pub fn projection_matrix_inverse(
  matrix : ProjectionMatrix3d,
) -> ProjectionMatrix3d? {
  @camera_projection3d.render3d_projection_matrix_inverse(matrix)
}

///|
pub fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
pub fn quat_conjugate(value : @math.Quat) -> @math.Quat {
  @math.Quat::new(-value.x, -value.y, -value.z, value.w)
}

///|
pub fn projection_runtime_projection(
  projection : Projection,
  camera : @camera_camera.Camera,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> Projection {
  match camera_viewport_rect_logical(camera, target_size, scale_factor) {
    Some((_, _, viewport_width, viewport_height)) =>
      projection.update(viewport_width, viewport_height)
    None => projection
  }
}

///|
pub fn camera_viewport_to_world_ray(
  screen : @math.Vec2,
  camera : @camera_camera.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> (@math.Vec3, @math.Vec3)? {
  guard camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  if screen.x < viewport_x ||
    screen.y < viewport_y ||
    screen.x > viewport_x + viewport_width ||
    screen.y > viewport_y + viewport_height {
    return None
  }
  let viewport_local_x = (screen.x - viewport_x) / viewport_width
  let viewport_local_y = (screen.y - viewport_y) / viewport_height
  let ndc_x = viewport_local_x * 2.0F - 1.0F
  let ndc_y = 1.0F - viewport_local_y * 2.0F
  let runtime_projection = projection_runtime_projection(
    projection, camera, target_size, scale_factor,
  )
  let clip_from_view = runtime_projection.get_clip_from_view()
  guard projection_matrix_inverse(clip_from_view) is Some(view_from_clip) else {
    return None
  }
  let near_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 1.0F, 1.0F),
  )
  let far_view_h = view_from_clip.mul_vec4(
    @math.Vec4::new(ndc_x, ndc_y, 1.1920929e-7F, 1.0F),
  )
  if near_view_h.w == 0.0F || far_view_h.w == 0.0F {
    return None
  }
  let near_view = @math.Vec3::new(
    near_view_h.x / near_view_h.w,
    near_view_h.y / near_view_h.w,
    near_view_h.z / near_view_h.w,
  )
  let far_view = @math.Vec3::new(
    far_view_h.x / far_view_h.w,
    far_view_h.y / far_view_h.w,
    far_view_h.z / far_view_h.w,
  )
  let ray_camera = far_view.sub(near_view).normalize_or_zero()
  if ray_camera.length_squared() <= 1.0e-12F {
    return None
  }
  let ray_world = quat_rotate_vec3(camera_transform.rotation, ray_camera).normalize_or_zero()
  if ray_world.length_squared() <= 1.0e-12F {
    return None
  }
  Some(
    (
      camera_transform.translation.add(
        quat_rotate_vec3(camera_transform.rotation, near_view),
      ),
      ray_world,
    ),
  )
}

///|
pub fn camera_world_to_viewport(
  world : @math.Vec3,
  camera : @camera_camera.Camera,
  projection : Projection,
  camera_transform : @transform.Transform,
  target_size : @math.IVec2,
  scale_factor : Float,
) -> @math.Vec2? {
  guard camera_viewport_rect_logical(camera, target_size, scale_factor)
    is Some((viewport_x, viewport_y, viewport_width, viewport_height)) else {
    return None
  }
  let to_world = world.sub(camera_transform.translation)
  let inv_rotation = quat_conjugate(camera_transform.rotation).normalize()
  let view_pos = quat_rotate_vec3(inv_rotation, to_world)
  let runtime_projection = projection_runtime_projection(
    projection, camera, target_size, scale_factor,
  )
  guard runtime_projection.get_clip_from_view().project_point3(view_pos)
    is Some(ndc_point) else {
    return None
  }
  if ndc_point.z < 0.0F || ndc_point.z > 1.0F {
    return None
  }
  let ndc_x = ndc_point.x
  let ndc_y = ndc_point.y
  let local_x = (ndc_x + 1.0F) * 0.5F * viewport_width
  let local_y = (1.0F - ndc_y) * 0.5F * viewport_height
  if local_x < 0.0F ||
    local_y < 0.0F ||
    local_x > viewport_width ||
    local_y > viewport_height {
    return None
  }
  Some(@math.Vec2::new(local_x + viewport_x, local_y + viewport_y))
}
