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
