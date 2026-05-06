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
// Bevy source: `bevy/crates/bevy_light/src/cluster/assign.rs` consumes
// `Camera::clip_from_view()` from `bevy_camera`. Mgstudio keeps the concrete
// 3D projection type in pbr today, so the pbr camera extraction stage writes
// this minimal camera-facing cache for cluster assignment.

///|
pub(all) struct ClusterProjectionMatrix3d {
  x_axis : @math.Vec4
  y_axis : @math.Vec4
  z_axis : @math.Vec4
  w_axis : @math.Vec4
}

///|
pub fn ClusterProjectionMatrix3d::from_cols(
  x_axis : @math.Vec4,
  y_axis : @math.Vec4,
  z_axis : @math.Vec4,
  w_axis : @math.Vec4,
) -> ClusterProjectionMatrix3d {
  ClusterProjectionMatrix3d::{ x_axis, y_axis, z_axis, w_axis }
}

///|
pub fn ClusterProjectionMatrix3d::from_rows(
  row0 : @math.Vec4,
  row1 : @math.Vec4,
  row2 : @math.Vec4,
  row3 : @math.Vec4,
) -> ClusterProjectionMatrix3d {
  ClusterProjectionMatrix3d::from_cols(
    @math.Vec4::new(row0.x, row1.x, row2.x, row3.x),
    @math.Vec4::new(row0.y, row1.y, row2.y, row3.y),
    @math.Vec4::new(row0.z, row1.z, row2.z, row3.z),
    @math.Vec4::new(row0.w, row1.w, row2.w, row3.w),
  )
}

///|
pub fn ClusterProjectionMatrix3d::mul_vec4(
  self : ClusterProjectionMatrix3d,
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
pub fn ClusterProjectionMatrix3d::mul(
  self : ClusterProjectionMatrix3d,
  other : ClusterProjectionMatrix3d,
) -> ClusterProjectionMatrix3d {
  ClusterProjectionMatrix3d::from_cols(
    self.mul_vec4(other.x_axis),
    self.mul_vec4(other.y_axis),
    self.mul_vec4(other.z_axis),
    self.mul_vec4(other.w_axis),
  )
}

///|
pub fn ClusterProjectionMatrix3d::row(
  self : ClusterProjectionMatrix3d,
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
    _ => abort("ClusterProjectionMatrix3d::row index out of bounds")
  }
}

///|
pub fn ClusterProjectionMatrix3d::project_point3(
  self : ClusterProjectionMatrix3d,
  value : @math.Vec3,
) -> @math.Vec3? {
  let clip = self.mul_vec4(@math.Vec4::new(value.x, value.y, value.z, 1.0F))
  if clip.w == 0.0F {
    return None
  }
  Some(@math.Vec3::new(clip.x / clip.w, clip.y / clip.w, clip.z / clip.w))
}

///|
pub fn ClusterProjectionMatrix3d::inverse(
  self : ClusterProjectionMatrix3d,
) -> ClusterProjectionMatrix3d? {
  let augmented : Array[Float] = [
    self.x_axis.x,
    self.y_axis.x,
    self.z_axis.x,
    self.w_axis.x,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    self.x_axis.y,
    self.y_axis.y,
    self.z_axis.y,
    self.w_axis.y,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    self.x_axis.z,
    self.y_axis.z,
    self.z_axis.z,
    self.w_axis.z,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    self.x_axis.w,
    self.y_axis.w,
    self.z_axis.w,
    self.w_axis.w,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
  ]
  for pivot in 0..<4 {
    let mut pivot_row = pivot
    let pivot_index = pivot * 8 + pivot
    let mut pivot_abs = augmented[pivot_index].abs()
    for row in (pivot + 1)..<4 {
      let value_abs = augmented[row * 8 + pivot].abs()
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
    ClusterProjectionMatrix3d::from_cols(
      @math.Vec4::new(augmented[4], augmented[12], augmented[20], augmented[28]),
      @math.Vec4::new(augmented[5], augmented[13], augmented[21], augmented[29]),
      @math.Vec4::new(augmented[6], augmented[14], augmented[22], augmented[30]),
      @math.Vec4::new(augmented[7], augmented[15], augmented[23], augmented[31]),
    ),
  )
}

///|
pub struct ClusterCameraProjection {
  clip_from_view : ClusterProjectionMatrix3d
  is_orthographic : Bool
  far : Float
  orthographic_first_slice_depth : Float
}

///|
pub fn ClusterCameraProjection::new(
  clip_from_view : ClusterProjectionMatrix3d,
  is_orthographic : Bool,
  far : Float,
  orthographic_first_slice_depth : Float,
) -> ClusterCameraProjection {
  ClusterCameraProjection::{
    clip_from_view,
    is_orthographic,
    far,
    orthographic_first_slice_depth,
  }
}

///|
pub fn ClusterCameraProjection::clip_from_view(
  self : ClusterCameraProjection,
) -> ClusterProjectionMatrix3d {
  self.clip_from_view
}

///|
pub fn ClusterCameraProjection::is_orthographic(
  self : ClusterCameraProjection,
) -> Bool {
  self.is_orthographic
}

///|
pub fn ClusterCameraProjection::far(self : ClusterCameraProjection) -> Float {
  self.far
}

///|
pub fn ClusterCameraProjection::orthographic_first_slice_depth(
  self : ClusterCameraProjection,
) -> Float {
  self.orthographic_first_slice_depth
}

///|
let ecs_key_cluster_camera_projection : @ecs.ComponentKey[
  ClusterCameraProjection,
] = @ecs.register_component(debug_name="light.cluster.camera_projection")

///|
pub impl @ecs.Component for ClusterCameraProjection with component() {
  ecs_key_cluster_camera_projection
}
