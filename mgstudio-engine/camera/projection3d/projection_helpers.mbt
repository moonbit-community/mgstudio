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
pub fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub fn render3d_view_from_world_matrix(
  transform : @transform.Transform,
) -> ProjectionMatrix3d {
  let view_from_world = @transform.GlobalTransform::from_transform(transform)
    .affine()
    .inverse()
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(
      view_from_world.matrix3.x_axis.x,
      view_from_world.matrix3.x_axis.y,
      view_from_world.matrix3.x_axis.z,
      0.0F,
    ),
    @math.Vec4::new(
      view_from_world.matrix3.y_axis.x,
      view_from_world.matrix3.y_axis.y,
      view_from_world.matrix3.y_axis.z,
      0.0F,
    ),
    @math.Vec4::new(
      view_from_world.matrix3.z_axis.x,
      view_from_world.matrix3.z_axis.y,
      view_from_world.matrix3.z_axis.z,
      0.0F,
    ),
    @math.Vec4::new(
      view_from_world.translation.x,
      view_from_world.translation.y,
      view_from_world.translation.z,
      1.0F,
    ),
  )
}
