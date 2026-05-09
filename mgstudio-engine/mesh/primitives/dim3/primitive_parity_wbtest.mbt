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
  let normals = match geometry.normals() {
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
fn primitive_parity_assert_y_bounds(
  name : String,
  geometry : @mesh.Mesh3dGeometry,
  expected_min : Float,
  expected_max : Float,
) -> Unit {
  let mut min_y = 1000000.0F
  let mut max_y = -1000000.0F
  for i in 0..<geometry.vertex_count() {
    match geometry.vertex_position(i) {
      Some(value) => {
        if value.y < min_y {
          min_y = value.y
        }
        if value.y > max_y {
          max_y = value.y
        }
      }
      None => abort("\{name}: missing vertex position")
    }
  }
  if (min_y - expected_min).abs() > 0.0001F ||
    (max_y - expected_max).abs() > 0.0001F {
    abort("\{name}: unexpected y bounds")
  }
}

///|
test "dim3 primitives: triangle winding matches generated normals" {
  primitive_parity_assert_triangle_winding_matches_normals(
    "cuboid",
    cuboid_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F)),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "tetrahedron",
    tetrahedron_mesh(@math.Tetrahedron::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "capsule3d",
    capsule3d_mesh(@math.Capsule3d::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "torus",
    torus_mesh(@math.Torus::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "cylinder",
    cylinder_mesh(@math.Cylinder::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "cone",
    cone_mesh(@math.Cone::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "conical_frustum",
    conical_frustum_mesh(@math.ConicalFrustum::default()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "icosphere",
    icosphere_mesh(0.5F, 2),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "uv_sphere",
    uv_sphere_mesh(0.5F, 16, 8),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "plane3d",
    plane3d_mesh_from_size(50.0F, 50.0F, 10),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "triangle3d",
    triangle3d_mesh(@math.Triangle3d::default()),
  )
}

///|
test "dim3 primitives: cuboid mesh builder builds the cuboid mesh" {
  let direct = cuboid_mesh(@math.Cuboid::new(1.0F, 2.0F, 3.0F))
  let built = CuboidMeshBuilder::new(1.0F, 2.0F, 3.0F).build()
  debug_inspect(built.vertex_count(), content="24")
  debug_inspect(built.indices_or_sequential().length(), content="36")
  debug_inspect(built.vertex_count() == direct.vertex_count(), content="true")
}

///|
test "dim3 primitives: simple mesh builders match direct mesh functions" {
  let triangle = @math.Triangle3d::default()
  let triangle_direct = triangle3d_mesh(triangle)
  let triangle_built = Triangle3dMeshBuilder::new(triangle).build()
  debug_inspect(triangle_built.vertex_count(), content="3")
  debug_inspect(
    triangle_built.indices_or_sequential().length() ==
    triangle_direct.indices_or_sequential().length(),
    content="true",
  )
  let tetrahedron = @math.Tetrahedron::default()
  let tetrahedron_direct = tetrahedron_mesh(tetrahedron)
  let tetrahedron_built = TetrahedronMeshBuilder::new(tetrahedron).build()
  debug_inspect(tetrahedron_built.vertex_count(), content="12")
  debug_inspect(
    tetrahedron_built.indices_or_sequential().length() ==
    tetrahedron_direct.indices_or_sequential().length(),
    content="true",
  )
  let segment = @math.Segment3d::default()
  let segment_built = Segment3dMeshBuilder::new(segment).build()
  debug_inspect(segment_built.vertex_count(), content="2")
  debug_inspect(segment_built.indices_or_sequential().length(), content="2")
  let polyline = @math.Polyline3d::default()
  let polyline_built = Polyline3dMeshBuilder::new(polyline).build()
  debug_inspect(polyline_built.vertex_count(), content="2")
  debug_inspect(polyline_built.indices_or_sequential().length(), content="2")
}

///|
test "dim3 primitives: cone and cylinder mesh builders expose source options" {
  let cone_direct = cone_mesh_with_anchor(@math.Cone::new(0.5F, 1.0F), 4, Tip)
  let cone_built = ConeMeshBuilder::new(0.5F, 1.0F, 4).anchor(Tip).build()
  debug_inspect(cone_built.vertex_count(), content="9")
  debug_inspect(cone_built.indices_or_sequential().length(), content="18")
  debug_inspect(
    cone_built.indices_or_sequential().length() ==
    cone_direct.indices_or_sequential().length(),
    content="true",
  )
  let cylinder_direct = cylinder_mesh_with_anchor(
    @math.Cylinder::new(0.5F, 1.0F),
    4,
    1,
    true,
    Top,
  )
  let cylinder_built = CylinderMeshBuilder::new(0.5F, 1.0F, 4)
    .segments(1)
    .anchor(Top)
    .build()
  debug_inspect(cylinder_built.vertex_count(), content="18")
  debug_inspect(cylinder_built.indices_or_sequential().length(), content="36")
  debug_inspect(
    cylinder_built.indices_or_sequential().length() ==
    cylinder_direct.indices_or_sequential().length(),
    content="true",
  )
  let uncapped = CylinderMeshBuilder::new(0.5F, 1.0F, 4).without_caps().build()
  debug_inspect(uncapped.vertex_count(), content="10")
  debug_inspect(uncapped.indices_or_sequential().length(), content="24")
}

///|
test "dim3 primitives: cone and cylinder anchors match builder offsets" {
  primitive_parity_assert_y_bounds(
    "cone_tip_anchor",
    cone_mesh_with_anchor(@math.Cone::default(), 32, Tip),
    -1.0F,
    0.0F,
  )
  primitive_parity_assert_y_bounds(
    "cone_base_anchor",
    cone_mesh_with_anchor(@math.Cone::default(), 32, Base),
    0.0F,
    1.0F,
  )
  primitive_parity_assert_y_bounds(
    "cylinder_top_anchor",
    cylinder_mesh_with_anchor(@math.Cylinder::default(), 32, 1, true, Top),
    -1.0F,
    0.0F,
  )
  primitive_parity_assert_y_bounds(
    "cylinder_bottom_anchor",
    cylinder_mesh_with_anchor(@math.Cylinder::default(), 32, 1, true, Bottom),
    0.0F,
    1.0F,
  )
}
