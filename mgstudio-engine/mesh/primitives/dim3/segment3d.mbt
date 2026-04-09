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
// Bevy source: `bevy/crates/bevy_mesh/src/primitives/dim3/segment3d.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` and
// `Milky2018/mgstudio/mesh` runtime owners.

///|
pub fn segment3d(point_a : @math.Vec3, point_b : @math.Vec3) -> @math.Segment3d {
  @math.Segment3d::new(point_a, point_b)
}

///|
pub fn segment3d_line_list(shape : @math.Segment3d) -> @mesh.Mesh3dGeometry {
  let zero_uv = @math.Vec2::new(0.0F, 0.0F)
  @mesh.Mesh3dGeometry::new_with_topology(
    [shape.point1(), shape.point2()],
    [zero_uv, zero_uv],
    None,
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}
