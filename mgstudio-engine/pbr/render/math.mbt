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
pub fn cmp_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
pub fn cmp_float(a : Float, b : Float) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
pub fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
pub fn render3d_quat_inverse(q : @math.Quat) -> @math.Quat {
  let length_squared = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w
  if length_squared <= 1.0e-8F {
    return @math.Quat::identity()
  }
  let inv = 1.0F / length_squared
  @math.Quat::new(-q.x * inv, -q.y * inv, -q.z * inv, q.w * inv)
}

///|
pub fn render3d_quat_conjugate(value : @math.Quat) -> @math.Quat {
  @math.Quat::new(-value.x, -value.y, -value.z, value.w)
}

///|
pub fn render3d_projection_aspect_ratio(width : Float, height : Float) -> Float {
  if width <= 0.0F || height <= 0.0F {
    1.0F
  } else {
    width / height
  }
}

///|
pub fn render3d_signum(value : Float) -> Float {
  if value < 0.0F {
    -1.0F
  } else if value > 0.0F {
    1.0F
  } else {
    0.0F
  }
}

///|
pub fn render3d_vec4_dot(lhs : @math.Vec4, rhs : @math.Vec4) -> Float {
  lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z + lhs.w * rhs.w
}

///|
pub fn render3d_default_near_clip_plane(near : Float) -> @math.Vec4 {
  let safe_near = if near <= 0.0F { 0.0001F } else { near }
  @math.Vec4::new(0.0F, 0.0F, -1.0F, -safe_near)
}

///|
pub fn render3d_transform_forward(
  transform : @transform.Transform,
) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
pub fn render3d_float_clamp(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
pub fn minf(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
pub fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub fn clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
pub fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
pub fn render3d_lightmap_uv_transform(
  uv_rect : @math.Rect,
) -> @transform.Affine2 {
  let size = uv_rect.size()
  @transform.Affine2::from_scale_translation(size, uv_rect.min)
}

///|
pub fn render3d_inverse_transform_point(
  transform : @transform.Transform,
  world_point : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let translated = world_point.sub(transform.translation)
  let rotated = quat_rotate_vec3(
    render3d_quat_inverse(transform.rotation),
    translated,
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
pub fn render3d_inverse_transform_direction(
  transform : @transform.Transform,
  world_direction : @math.Vec3,
) -> @math.Vec3? {
  if absf(transform.scale.x) <= 1.0e-9F ||
    absf(transform.scale.y) <= 1.0e-9F ||
    absf(transform.scale.z) <= 1.0e-9F {
    return None
  }
  let rotated = quat_rotate_vec3(
    render3d_quat_inverse(transform.rotation),
    world_direction,
  )
  Some(
    @math.Vec3::new(
      rotated.x / transform.scale.x,
      rotated.y / transform.scale.y,
      rotated.z / transform.scale.z,
    ),
  )
}

///|
pub fn render3d_transform_local_normal(
  transform : @transform.Transform,
  local_normal : @math.Vec3,
) -> @math.Vec3 {
  let inv_scale = @math.Vec3::new(
    if absf(transform.scale.x) <= 1.0e-9F {
      0.0F
    } else {
      1.0F / transform.scale.x
    },
    if absf(transform.scale.y) <= 1.0e-9F {
      0.0F
    } else {
      1.0F / transform.scale.y
    },
    if absf(transform.scale.z) <= 1.0e-9F {
      0.0F
    } else {
      1.0F / transform.scale.z
    },
  )
  quat_rotate_vec3(
    transform.rotation,
    @math.Vec3::new(
      local_normal.x * inv_scale.x,
      local_normal.y * inv_scale.y,
      local_normal.z * inv_scale.z,
    ),
  ).normalize_or_zero()
}
