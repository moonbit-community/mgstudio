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
