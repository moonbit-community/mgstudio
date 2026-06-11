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
pub struct Wireframe3dThinImmediates {
  color : @color.Color
}

///|
pub fn Wireframe3dThinImmediates::from_material(
  material : RenderWireframeMaterial,
) -> Wireframe3dThinImmediates {
  Wireframe3dThinImmediates::{ color: material.color }
}

///|
pub fn Wireframe3dThinImmediates::color(
  self : Wireframe3dThinImmediates,
) -> @color.Color {
  self.color
}

///|
pub fn Wireframe3dThinImmediates::float_count(
  self : Wireframe3dThinImmediates,
) -> Int {
  ignore(self)
  4
}

///|
pub struct Wireframe3dWideImmediates {
  color : @color.Color
  line_width : Float
  smoothing : Float
}

///|
pub fn Wireframe3dWideImmediates::from_material(
  material : RenderWireframeMaterial,
) -> Wireframe3dWideImmediates {
  Wireframe3dWideImmediates::{
    color: material.color,
    line_width: material.line_width,
    smoothing: if material.line_width <= 1.0F {
      0.5F
    } else {
      1.0F
    },
  }
}

///|
pub fn Wireframe3dWideImmediates::color(
  self : Wireframe3dWideImmediates,
) -> @color.Color {
  self.color
}

///|
pub fn Wireframe3dWideImmediates::line_width(
  self : Wireframe3dWideImmediates,
) -> Float {
  self.line_width
}

///|
pub fn Wireframe3dWideImmediates::smoothing(
  self : Wireframe3dWideImmediates,
) -> Float {
  self.smoothing
}

///|
pub fn Wireframe3dWideImmediates::float_count(
  self : Wireframe3dWideImmediates,
) -> Int {
  ignore(self)
  8
}

///|
pub struct WireframeVertexPullParams {
  index_offset : UInt
  vertex_stride_u32s : UInt
  position_offset_u32s : UInt
} derive(Eq, Debug)

///|
pub fn WireframeVertexPullParams::new(
  index_offset : UInt,
  vertex_stride_u32s : UInt,
  position_offset_u32s : UInt,
) -> WireframeVertexPullParams {
  WireframeVertexPullParams::{
    index_offset,
    vertex_stride_u32s,
    position_offset_u32s,
  }
}

///|
pub fn WireframeVertexPullParams::index_offset(
  self : WireframeVertexPullParams,
) -> UInt {
  self.index_offset
}

///|
pub fn WireframeVertexPullParams::vertex_stride_u32s(
  self : WireframeVertexPullParams,
) -> UInt {
  self.vertex_stride_u32s
}

///|
pub fn WireframeVertexPullParams::position_offset_u32s(
  self : WireframeVertexPullParams,
) -> UInt {
  self.position_offset_u32s
}
