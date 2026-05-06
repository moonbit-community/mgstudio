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
pub struct GpuClipMatrix {
  x_axis_x : Float
  x_axis_y : Float
  x_axis_z : Float
  x_axis_w : Float
  y_axis_x : Float
  y_axis_y : Float
  y_axis_z : Float
  y_axis_w : Float
  z_axis_x : Float
  z_axis_y : Float
  z_axis_z : Float
  z_axis_w : Float
  w_axis_x : Float
  w_axis_y : Float
  w_axis_z : Float
  w_axis_w : Float
}

///|
pub fn gpu_clip_matrix(
  x_axis_x : Float,
  x_axis_y : Float,
  x_axis_z : Float,
  x_axis_w : Float,
  y_axis_x : Float,
  y_axis_y : Float,
  y_axis_z : Float,
  y_axis_w : Float,
  z_axis_x : Float,
  z_axis_y : Float,
  z_axis_z : Float,
  z_axis_w : Float,
  w_axis_x : Float,
  w_axis_y : Float,
  w_axis_z : Float,
  w_axis_w : Float,
) -> GpuClipMatrix {
  GpuClipMatrix::{
    x_axis_x,
    x_axis_y,
    x_axis_z,
    x_axis_w,
    y_axis_x,
    y_axis_y,
    y_axis_z,
    y_axis_w,
    z_axis_x,
    z_axis_y,
    z_axis_z,
    z_axis_w,
    w_axis_x,
    w_axis_y,
    w_axis_z,
    w_axis_w,
  }
}

///|
fn gpu_clip_matrix_identity() -> GpuClipMatrix {
  gpu_clip_matrix(
    1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 1.0F,
  )
}

///|
fn gpu_clip_matrix_mul_vec4(
  matrix : GpuClipMatrix,
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> (Float, Float, Float, Float) {
  (
    matrix.x_axis_x * x +
    matrix.y_axis_x * y +
    matrix.z_axis_x * z +
    matrix.w_axis_x * w,
    matrix.x_axis_y * x +
    matrix.y_axis_y * y +
    matrix.z_axis_y * z +
    matrix.w_axis_y * w,
    matrix.x_axis_z * x +
    matrix.y_axis_z * y +
    matrix.z_axis_z * z +
    matrix.w_axis_z * w,
    matrix.x_axis_w * x +
    matrix.y_axis_w * y +
    matrix.z_axis_w * z +
    matrix.w_axis_w * w,
  )
}

///|
fn gpu_clip_matrix_mul(
  lhs : GpuClipMatrix,
  rhs : GpuClipMatrix,
) -> GpuClipMatrix {
  let x = gpu_clip_matrix_mul_vec4(
    lhs,
    rhs.x_axis_x,
    rhs.x_axis_y,
    rhs.x_axis_z,
    rhs.x_axis_w,
  )
  let y = gpu_clip_matrix_mul_vec4(
    lhs,
    rhs.y_axis_x,
    rhs.y_axis_y,
    rhs.y_axis_z,
    rhs.y_axis_w,
  )
  let z = gpu_clip_matrix_mul_vec4(
    lhs,
    rhs.z_axis_x,
    rhs.z_axis_y,
    rhs.z_axis_z,
    rhs.z_axis_w,
  )
  let w = gpu_clip_matrix_mul_vec4(
    lhs,
    rhs.w_axis_x,
    rhs.w_axis_y,
    rhs.w_axis_z,
    rhs.w_axis_w,
  )
  gpu_clip_matrix(
    x.0,
    x.1,
    x.2,
    x.3,
    y.0,
    y.1,
    y.2,
    y.3,
    z.0,
    z.1,
    z.2,
    z.3,
    w.0,
    w.1,
    w.2,
    w.3,
  )
}

///|
fn gpu_clip_matrix_inverse(matrix : GpuClipMatrix) -> GpuClipMatrix? {
  let augmented : Array[Float] = [
    matrix.x_axis_x,
    matrix.y_axis_x,
    matrix.z_axis_x,
    matrix.w_axis_x,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    matrix.x_axis_y,
    matrix.y_axis_y,
    matrix.z_axis_y,
    matrix.w_axis_y,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    matrix.x_axis_z,
    matrix.y_axis_z,
    matrix.z_axis_z,
    matrix.w_axis_z,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    matrix.x_axis_w,
    matrix.y_axis_w,
    matrix.z_axis_w,
    matrix.w_axis_w,
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
    gpu_clip_matrix(
      augmented[4],
      augmented[12],
      augmented[20],
      augmented[28],
      augmented[5],
      augmented[13],
      augmented[21],
      augmented[29],
      augmented[6],
      augmented[14],
      augmented[22],
      augmented[30],
      augmented[7],
      augmented[15],
      augmented[23],
      augmented[31],
    ),
  )
}

///|
fn gpu_quat_normalize(
  x : Float,
  y : Float,
  z : Float,
  w : Float,
) -> (Float, Float, Float, Float) {
  let len_sq = x * x + y * y + z * z + w * w
  if len_sq <= 0.0F {
    (0.0F, 0.0F, 0.0F, 1.0F)
  } else {
    let inv_len = 1.0F / Float::sqrt(len_sq)
    (x * inv_len, y * inv_len, z * inv_len, w * inv_len)
  }
}

///|
fn gpu_quat_rotate_vec3(
  qx : Float,
  qy : Float,
  qz : Float,
  qw : Float,
  vx : Float,
  vy : Float,
  vz : Float,
) -> (Float, Float, Float) {
  let tx = 2.0F * (qy * vz - qz * vy)
  let ty = 2.0F * (qz * vx - qx * vz)
  let tz = 2.0F * (qx * vy - qy * vx)
  (
    vx + qw * tx + (qy * tz - qz * ty),
    vy + qw * ty + (qz * tx - qx * tz),
    vz + qw * tz + (qx * ty - qy * tx),
  )
}

///|
fn gpu_clip_matrix_world_from_view(
  x : Float,
  y : Float,
  z : Float,
  rot_x : Float,
  rot_y : Float,
  rot_z : Float,
  rot_w : Float,
) -> GpuClipMatrix {
  let q = gpu_quat_normalize(rot_x, rot_y, rot_z, rot_w)
  let x_axis = gpu_quat_rotate_vec3(q.0, q.1, q.2, q.3, 1.0F, 0.0F, 0.0F)
  let y_axis = gpu_quat_rotate_vec3(q.0, q.1, q.2, q.3, 0.0F, 1.0F, 0.0F)
  let z_axis = gpu_quat_rotate_vec3(q.0, q.1, q.2, q.3, 0.0F, 0.0F, 1.0F)
  gpu_clip_matrix(
    x_axis.0,
    x_axis.1,
    x_axis.2,
    0.0F,
    y_axis.0,
    y_axis.1,
    y_axis.2,
    0.0F,
    z_axis.0,
    z_axis.1,
    z_axis.2,
    0.0F,
    x,
    y,
    z,
    1.0F,
  )
}

///|
fn gpu_clip_matrix_view_parts_3d(
  clip_from_world : GpuClipMatrix,
  camera_x : Float,
  camera_y : Float,
  camera_z : Float,
  camera_rot_x : Float,
  camera_rot_y : Float,
  camera_rot_z : Float,
  camera_rot_w : Float,
) -> (GpuClipMatrix, GpuClipMatrix, GpuClipMatrix, GpuClipMatrix, GpuClipMatrix) {
  let world_from_view = gpu_clip_matrix_world_from_view(
    camera_x, camera_y, camera_z, camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w,
  )
  let view_from_world = match gpu_clip_matrix_inverse(world_from_view) {
    Some(value) => value
    None => gpu_clip_matrix_identity()
  }
  let clip_from_view = gpu_clip_matrix_mul(clip_from_world, world_from_view)
  let view_from_clip = match gpu_clip_matrix_inverse(clip_from_view) {
    Some(value) => value
    None => gpu_clip_matrix_identity()
  }
  let world_from_clip = gpu_clip_matrix_mul(world_from_view, view_from_clip)
  (
    world_from_clip, world_from_view, view_from_world, clip_from_view, view_from_clip,
  )
}

///|
fn gpu_clip_matrix_2d(
  width_logical : Float,
  height_logical : Float,
  camera_x : Float,
  camera_y : Float,
  camera_rot : Float,
  camera_scale : Float,
) -> GpuClipMatrix {
  let safe_scale = if camera_scale == 0.0F { 1.0F } else { camera_scale }
  let scale_x = if width_logical > 0.0F {
    2.0F / width_logical / safe_scale
  } else {
    0.0F
  }
  let scale_y = if height_logical > 0.0F {
    2.0F / height_logical / safe_scale
  } else {
    0.0F
  }
  let cosv = cosf(-camera_rot)
  let sinv = sinf(-camera_rot)
  gpu_clip_matrix(
    scale_x * cosv,
    scale_y * sinv,
    0.0F,
    0.0F,
    -scale_x * sinv,
    scale_y * cosv,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    scale_x * (-cosv * camera_x + sinv * camera_y),
    scale_y * (-sinv * camera_x - cosv * camera_y),
    0.0F,
    1.0F,
  )
}
