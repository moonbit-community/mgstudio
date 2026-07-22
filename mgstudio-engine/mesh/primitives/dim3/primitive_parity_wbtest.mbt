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
  guard geometry.primitive_topology() == TriangleList else { return }
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
    tetrahedron_mesh(Tetrahedron()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "capsule3d",
    capsule3d_mesh(Capsule3d()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "torus",
    torus_mesh(Torus()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "cylinder",
    cylinder_mesh(Cylinder()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "cone",
    cone_mesh(Cone()),
  )
  primitive_parity_assert_triangle_winding_matches_normals(
    "conical_frustum",
    conical_frustum_mesh(ConicalFrustum()),
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
    triangle3d_mesh(Triangle3d()),
  )
}

///|
test "dim3 primitives: cuboid mesh builder builds the cuboid mesh" {
  let direct = cuboid_mesh(@math.Cuboid::new(1.0F, 2.0F, 3.0F))
  let built = CuboidMeshBuilder::new(1.0F, 2.0F, 3.0F).build()
  debug_inspect(built.vertex_count(), content="24")
  debug_inspect(built.indices_or_sequential().length(), content="36")
  debug_inspect(built.index_format(), content="Some(Uint32)")
  debug_inspect(built.vertex_count() == direct.vertex_count(), content="true")
}

///|
test "dim3 primitives: simple mesh builders match direct mesh functions" {
  let triangle = @math.Triangle3d::Triangle3d()
  let triangle_direct = triangle3d_mesh(triangle)
  let triangle_built = Triangle3dMeshBuilder::new(triangle).build()
  debug_inspect(triangle_built.vertex_count(), content="3")
  debug_inspect(
    triangle_built.indices_or_sequential().length() ==
    triangle_direct.indices_or_sequential().length(),
    content="true",
  )
  let tetrahedron = @math.Tetrahedron::Tetrahedron()
  let tetrahedron_direct = tetrahedron_mesh(tetrahedron)
  let tetrahedron_built = TetrahedronMeshBuilder::new(tetrahedron).build()
  debug_inspect(tetrahedron_built.vertex_count(), content="12")
  debug_inspect(
    tetrahedron_built.indices_or_sequential().length() ==
    tetrahedron_direct.indices_or_sequential().length(),
    content="true",
  )
  let segment = @math.Segment3d::Segment3d()
  let segment_built = Segment3dMeshBuilder::new(segment).build()
  debug_inspect(segment_built.vertex_count(), content="2")
  debug_inspect(segment_built.indices_or_sequential().length(), content="2")
  let polyline = @math.Polyline3d::Polyline3d()
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
test "dim3 primitives: remaining mesh builders match direct mesh functions" {
  let frustum = @math.ConicalFrustum::new(0.25F, 0.5F, 1.0F)
  let frustum_direct = conical_frustum_mesh_with_options(frustum, 4, 1)
  let frustum_built = ConicalFrustumMeshBuilder::new(0.25F, 0.5F, 1.0F, 4)
    .segments(1)
    .build()
  debug_inspect(frustum_built.vertex_count(), content="18")
  debug_inspect(frustum_built.indices_or_sequential().length(), content="36")
  debug_inspect(
    frustum_built.indices_or_sequential().length() ==
    frustum_direct.indices_or_sequential().length(),
    content="true",
  )
  let capsule = @math.Capsule3d::new(0.5F, 1.0F)
  let capsule_direct = capsule3d_mesh_with_uv_profile(
    capsule,
    1,
    8,
    8,
    CapsuleUvProfile::fixed(),
  )
  let capsule_built = Capsule3dMeshBuilder::new(0.5F, 1.0F, 8, 8)
    .rings(1)
    .uv_profile(CapsuleUvProfile::fixed())
    .build()
  debug_inspect(
    capsule_built.vertex_count() == capsule_direct.vertex_count(),
    content="true",
  )
  debug_inspect(
    capsule_built.indices_or_sequential().length() ==
    capsule_direct.indices_or_sequential().length(),
    content="true",
  )
  let torus = @math.Torus::new(0.75F, 0.25F)
  let torus_direct = torus_mesh_with_resolution(torus, 4, 4)
  let torus_built = TorusMeshBuilder::from_torus(torus)
    .minor_resolution(4)
    .major_resolution(4)
    .build()
  debug_inspect(torus_built.vertex_count(), content="25")
  debug_inspect(torus_built.indices_or_sequential().length(), content="96")
  debug_inspect(
    torus_built.indices_or_sequential().length() ==
    torus_direct.indices_or_sequential().length(),
    content="true",
  )
  let plane_direct = plane3d_mesh_from_size(2.0F, 2.0F, 1)
  let plane_built = PlaneMeshBuilder::from_length(2.0F).subdivisions(1).build()
  debug_inspect(plane_built.vertex_count(), content="9")
  debug_inspect(plane_built.indices_or_sequential().length(), content="24")
  debug_inspect(
    plane_built.indices_or_sequential().length() ==
    plane_direct.indices_or_sequential().length(),
    content="true",
  )
  let sphere_direct = sphere_mesh_with_kind(0.5F, SphereKind::uv(8, 4))
  let sphere_built = SphereMeshBuilder::new(0.5F, SphereKind::uv(8, 4)).build()
  debug_inspect(
    sphere_built.vertex_count() == sphere_direct.vertex_count(),
    content="true",
  )
  debug_inspect(
    sphere_built.indices_or_sequential().length() ==
    sphere_direct.indices_or_sequential().length(),
    content="true",
  )
  let ico_mesh = SphereMeshBuilder::new(0.5F, SphereKind::default()).ico(1) catch {
    _ => abort("sphere ico builder should succeed")
  }
  debug_inspect(ico_mesh.vertex_count() > 0, content="true")
  let too_large = try {
    ignore(SphereMeshBuilder::new(0.5F, SphereKind::default()).ico(80))
    false
  } catch {
    TooManyVertices(80, 65612) => true
    _ => false
  }
  guard too_large else {
    abort("sphere ico builder should return TooManyVertices")
  }
}

///|
test "dim3 primitives: cone and cylinder anchors match builder offsets" {
  primitive_parity_assert_y_bounds(
    "cone_tip_anchor",
    cone_mesh_with_anchor(Cone(), 32, Tip),
    -1.0F,
    0.0F,
  )
  primitive_parity_assert_y_bounds(
    "cone_base_anchor",
    cone_mesh_with_anchor(Cone(), 32, Base),
    0.0F,
    1.0F,
  )
  primitive_parity_assert_y_bounds(
    "cylinder_top_anchor",
    cylinder_mesh_with_anchor(Cylinder(), 32, 1, true, Top),
    -1.0F,
    0.0F,
  )
  primitive_parity_assert_y_bounds(
    "cylinder_bottom_anchor",
    cylinder_mesh_with_anchor(Cylinder(), 32, 1, true, Bottom),
    0.0F,
    1.0F,
  )
}
