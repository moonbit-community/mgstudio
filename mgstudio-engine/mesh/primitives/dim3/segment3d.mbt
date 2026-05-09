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
pub fn segment3d(point_a : @math.Vec3, point_b : @math.Vec3) -> @math.Segment3d {
  @math.Segment3d::new(point_a, point_b)
}

///|
pub fn segment3d_line_list(shape : @math.Segment3d) -> @mesh.Mesh3dGeometry {
  primitive_geometry_with_normals_and_topology(
    [shape.point1(), shape.point2()],
    [@math.Vec3::new(0.0F, 1.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F)],
    primitive_zero_uvs(2),
    Some([0, 1]),
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
}
