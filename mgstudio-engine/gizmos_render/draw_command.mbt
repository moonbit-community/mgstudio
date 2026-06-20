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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/lib.rs`.

///|
pub(all) enum LineGizmoDrawBufferKind {
  ListPosition
  ListColor
  StripPosition
  StripColor
} derive(Eq, Debug)

///|
pub struct LineGizmoVertexBufferBindingPlan {
  slot : UInt
  buffer_kind : LineGizmoDrawBufferKind
  offset_bytes : UInt64
  size_bytes : UInt64
}

///|
pub fn LineGizmoVertexBufferBindingPlan::slot(
  self : LineGizmoVertexBufferBindingPlan,
) -> UInt {
  self.slot
}

///|
pub fn LineGizmoVertexBufferBindingPlan::buffer_kind(
  self : LineGizmoVertexBufferBindingPlan,
) -> LineGizmoDrawBufferKind {
  self.buffer_kind
}

///|
pub fn LineGizmoVertexBufferBindingPlan::offset_bytes(
  self : LineGizmoVertexBufferBindingPlan,
) -> UInt64 {
  self.offset_bytes
}

///|
pub fn LineGizmoVertexBufferBindingPlan::size_bytes(
  self : LineGizmoVertexBufferBindingPlan,
) -> UInt64 {
  self.size_bytes
}

///|
pub struct LineGizmoDrawPlan {
  bindings : Array[LineGizmoVertexBufferBindingPlan]
  vertex_count : UInt
  instance_count : UInt
}

///|
pub fn LineGizmoDrawPlan::bindings(
  self : LineGizmoDrawPlan,
) -> Array[LineGizmoVertexBufferBindingPlan] {
  self.bindings
}

///|
pub fn LineGizmoDrawPlan::vertex_count(self : LineGizmoDrawPlan) -> UInt {
  self.vertex_count
}

///|
pub fn LineGizmoDrawPlan::instance_count(self : LineGizmoDrawPlan) -> UInt {
  self.instance_count
}

///|
fn line_gizmo_bytes_for_vertices(vertex_count : Int, stride : Int) -> UInt64 {
  (vertex_count * stride).to_uint64()
}

///|
fn line_gizmo_binding(
  slot : UInt,
  buffer_kind : LineGizmoDrawBufferKind,
  offset_bytes : UInt64,
  size_bytes : UInt64,
) -> LineGizmoVertexBufferBindingPlan {
  LineGizmoVertexBufferBindingPlan::{
    slot,
    buffer_kind,
    offset_bytes,
    size_bytes,
  }
}

///|
pub fn draw_line_gizmo_plan(
  strip~ : Bool,
  list_vertex_count~ : Int,
  strip_vertex_count~ : Int,
) -> LineGizmoDrawPlan? {
  let vertex_count = if strip { strip_vertex_count } else { list_vertex_count }
  if vertex_count < 2 {
    return None
  }
  if strip {
    let position_item_size = LINE_GIZMO_VEC3_SIZE_BYTES.to_uint64()
    let color_item_size = LINE_GIZMO_RGBA_SIZE_BYTES.to_uint64()
    let position_size = line_gizmo_bytes_for_vertices(
        strip_vertex_count,
        LINE_GIZMO_VEC3_SIZE_BYTES,
      ) -
      position_item_size
    let color_size = line_gizmo_bytes_for_vertices(
        strip_vertex_count,
        LINE_GIZMO_RGBA_SIZE_BYTES,
      ) -
      color_item_size
    Some(LineGizmoDrawPlan::{
      bindings: [
        line_gizmo_binding(0U, StripPosition, 0UL, position_size),
        line_gizmo_binding(1U, StripPosition, position_item_size, position_size),
        line_gizmo_binding(2U, StripColor, 0UL, color_size),
        line_gizmo_binding(3U, StripColor, color_item_size, color_size),
      ],
      vertex_count: 6U,
      instance_count: (strip_vertex_count - 1).reinterpret_as_uint(),
    })
  } else {
    Some(LineGizmoDrawPlan::{
      bindings: [
        line_gizmo_binding(
          0U,
          ListPosition,
          0UL,
          line_gizmo_bytes_for_vertices(
            list_vertex_count,
            LINE_GIZMO_VEC3_SIZE_BYTES,
          ),
        ),
        line_gizmo_binding(
          1U,
          ListColor,
          0UL,
          line_gizmo_bytes_for_vertices(
            list_vertex_count,
            LINE_GIZMO_RGBA_SIZE_BYTES,
          ),
        ),
      ],
      vertex_count: 6U,
      instance_count: (list_vertex_count / 2).reinterpret_as_uint(),
    })
  }
}

///|
pub fn draw_line_joint_gizmo_vertex_count(
  joints : @gizmos.GizmoLineJoint,
) -> UInt? {
  match joints {
    None => None
    Miter => Some(6U)
    Round(resolution) => Some((resolution * 3).reinterpret_as_uint())
    Bevel => Some(3U)
  }
}

///|
pub fn draw_line_joint_gizmo_plan(
  strip_vertex_count~ : Int,
  joints~ : @gizmos.GizmoLineJoint,
) -> LineGizmoDrawPlan? {
  if strip_vertex_count <= 2 {
    return None
  }
  guard draw_line_joint_gizmo_vertex_count(joints) is Some(vertex_count) else {
    return None
  }
  let position_item_size = LINE_GIZMO_VEC3_SIZE_BYTES.to_uint64()
  let color_item_size = LINE_GIZMO_RGBA_SIZE_BYTES.to_uint64()
  let position_size = line_gizmo_bytes_for_vertices(
      strip_vertex_count,
      LINE_GIZMO_VEC3_SIZE_BYTES,
    ) -
    position_item_size * 2UL
  let color_size = line_gizmo_bytes_for_vertices(
      strip_vertex_count,
      LINE_GIZMO_RGBA_SIZE_BYTES,
    ) -
    color_item_size * 2UL
  Some(LineGizmoDrawPlan::{
    bindings: [
      line_gizmo_binding(0U, StripPosition, 0UL, position_size),
      line_gizmo_binding(1U, StripPosition, position_item_size, position_size),
      line_gizmo_binding(
        2U,
        StripPosition,
        position_item_size * 2UL,
        position_size,
      ),
      line_gizmo_binding(3U, StripColor, color_item_size, color_size),
    ],
    vertex_count,
    instance_count: (strip_vertex_count - 2).reinterpret_as_uint(),
  })
}
