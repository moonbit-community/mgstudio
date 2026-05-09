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
fn primitive_parity_normal_at(
  normals : Array[@math.Vec3],
  index : Int,
) -> @math.Vec3 {
  if index >= 0 && index < normals.length() {
    normals[index]
  } else {
    @math.Vec3::zero()
  }
}

///|
fn primitive_parity_assert_triangle_winding_matches_normals(
  name : String,
  geometry : @mesh.Mesh3dGeometry,
) -> Unit {
  guard geometry.primitive_topology() ==
    @mesh.Mesh3dPrimitiveTopology::TriangleList else {
    return
  }
  let normals = match
    geometry.custom_attribute_vec3(@mesh.MESH3D_ATTRIBUTE_NORMAL_NAME) {
    Some(values) => values
    None => abort("\{name}: missing normal attribute")
  }
  let indices = geometry.indices_or_sequential()
  let mut triangle = 0
  while triangle + 2 < indices.length() {
    let ia = indices[triangle]
    let ib = indices[triangle + 1]
    let ic = indices[triangle + 2]
    let a = match geometry.vertex_position(ia) {
      Some(value) => value
      None => abort("\{name}: missing triangle position")
    }
    let b = match geometry.vertex_position(ib) {
      Some(value) => value
      None => abort("\{name}: missing triangle position")
    }
    let c = match geometry.vertex_position(ic) {
      Some(value) => value
      None => abort("\{name}: missing triangle position")
    }
    let geometric = b.sub(a).cross(c.sub(a))
    if geometric.length_squared() > 1.0e-10F {
      let vertex_normal = primitive_parity_normal_at(normals, ia)
        .add(primitive_parity_normal_at(normals, ib))
        .add(primitive_parity_normal_at(normals, ic))
      if vertex_normal.length_squared() > 1.0e-10F {
        let dot = geometric.normalize().dot(vertex_normal.normalize())
        if dot < -1.0e-4F {
          abort(
            "\{name}: triangle \{triangle / 3} winding opposes vertex normals",
          )
        }
      }
    }
    triangle = triangle + 3
  }
}

///|
test "dim2 and extrusion primitives: triangle winding matches generated normals" {
  primitive_parity_assert_triangle_winding_matches_normals(
    "rectangle",
    rectangle_mesh(1.0F, 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "circle",
    circle_mesh(0.5F, 32),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "annulus",
    annulus_mesh(@math.Annulus::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "circular_sector",
    circular_sector_mesh(@math.CircularSector::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "circular_segment",
    circular_segment_mesh(@math.CircularSegment::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "rhombus",
    rhombus_mesh(@math.Rhombus::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "triangle2d",
    triangle2d_mesh(@math.Triangle2d::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_rectangle",
    extrusion_rectangle_mesh(@math.Rectangle::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_capsule2d",
    extrusion_capsule2d_mesh(@math.Capsule2d::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_annulus",
    extrusion_annulus_mesh(@math.Annulus::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_circular_sector",
    extrusion_circular_sector_mesh(@math.CircularSector::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_circular_segment",
    extrusion_circular_segment_mesh(@math.CircularSegment::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_circle",
    extrusion_circle_mesh(@math.Circle::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_ellipse",
    extrusion_ellipse_mesh(@math.Ellipse::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_regular_polygon",
    extrusion_regular_polygon_mesh(@math.RegularPolygon::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_rhombus",
    extrusion_rhombus_mesh(@math.Rhombus::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_triangle2d",
    extrusion_triangle2d_mesh(@math.Triangle2d::default(), 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_rectangle_ring",
    extrusion_rectangle_ring_mesh(@math.Rectangle::default(), 0.1F, 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_circle_ring",
    extrusion_circle_ring_mesh(@math.Circle::default(), 0.1F, 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_rhombus_ring",
    extrusion_rhombus_ring_mesh(@math.Rhombus::default(), 0.1F, 1.0F),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "extrusion_triangle2d_ring",
    extrusion_triangle2d_ring_mesh(@math.Triangle2d::default(), 1.0F),
  )
}
