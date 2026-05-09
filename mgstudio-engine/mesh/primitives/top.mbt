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

// `Milky2018/mgstudio/mesh` runtime owners.

///|
pub type Annulus = @math.Annulus

///|
pub type Capsule2d = @math.Capsule2d

///|
pub type Circle = @math.Circle

///|
pub type CircularMeshUvMode = @math.CircularMeshUvMode

///|
pub type CircularSector = @math.CircularSector

///|
pub type CircularSegment = @math.CircularSegment

///|
pub type ConvexPolygon = @math.ConvexPolygon

///|
pub type Ellipse = @math.Ellipse

///|
pub type Polyline2d = @math.Polyline2d

///|
pub type Rectangle = @math.Rectangle

///|
pub type RegularPolygon = @math.RegularPolygon

///|
pub type Rhombus = @math.Rhombus

///|
pub type Ring[P] = @math.Ring[P]

///|
pub type Segment2d = @math.Segment2d

///|
pub type Triangle2d = @math.Triangle2d

///|
pub using @mesh {type Mesh2dGeometry}

///|
pub using @mesh {type Mesh3dGeometry}

///|
pub using @mesh {type Mesh3dPrimitiveTopology}

///|
pub(open) trait MeshBuilder {
  build(Self) -> @mesh.Mesh3dGeometry
}
