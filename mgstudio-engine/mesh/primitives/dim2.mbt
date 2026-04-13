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
// Bevy source: `bevy/crates/bevy_mesh/src/primitives/dim2.rs`.
// `Milky2018/mgstudio/mesh` runtime owners.

///|
pub fn circle(radius : Float) -> @math.Circle {
  @math.Circle::new(radius)
}

///|
pub fn circle_mesh(radius : Float, segments : Int) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::circle(radius, segments)
}

///|
pub fn circle_line_strip_mesh(
  radius : Float,
  segments : Int,
) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::circle_line_strip(radius, segments)
}

///|
pub fn rectangle(width : Float, height : Float) -> @math.Rectangle {
  @math.Rectangle::new(width, height)
}

///|
pub fn rectangle_mesh(width : Float, height : Float) -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::rectangle(width, height)
}
