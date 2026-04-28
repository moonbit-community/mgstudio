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
test "render3d: triangle helper builds valid geometry" {
  let geometry = mesh3d_geometry_triangle(
    @math.Triangle3d::new(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(2.0F, 0.0F, 0.0F),
      @math.Vec3::new(-1.0F, 1.0F, 0.0F),
    ),
  )
  debug_inspect(geometry.validate(), content="None")
  debug_inspect(geometry.vertex_count(), content="3")
  debug_inspect(geometry.triangle_count(), content="Some(1)")
}

///|
test "render3d: cylinder helper builds valid geometry" {
  let geometry = mesh3d_geometry_cylinder_shape(@math.Cylinder::new(0.5F, 1.0F))
  debug_inspect(geometry.validate(), content="None")
  debug_inspect(geometry.vertex_count() > 0, content="true")
  debug_inspect(
    match geometry.triangle_count() {
      Some(_) => true
      None => false
    },
    content="true",
  )
}

///|
test "render3d: capsule helper builds valid geometry" {
  let geometry = mesh3d_geometry_capsule_shape(@math.Capsule3d::new(0.5F, 1.0F))
  debug_inspect(geometry.validate(), content="None")
  debug_inspect(geometry.vertex_count() > 0, content="true")
  debug_inspect(
    match geometry.triangle_count() {
      Some(_) => true
      None => false
    },
    content="true",
  )
}

///|
test "render3d: plane helper winds upward like Bevy Plane3d" {
  let geometry = mesh3d_geometry_plane(2.0F, 2.0F)
  guard geometry.vertex_position(0) is Some(a) else {
    abort("missing plane vertex 0")
  }
  guard geometry.vertex_position(1) is Some(b) else {
    abort("missing plane vertex 1")
  }
  guard geometry.vertex_position(2) is Some(c) else {
    abort("missing plane vertex 2")
  }
  let ab = b.sub(a)
  let ac = c.sub(a)
  let normal = ab.cross(ac)
  debug_inspect(normal.y > 0.0F, content="true")
}

///|
test "render3d: tetrahedron-shape helper builds valid geometry" {
  let geometry = mesh3d_geometry_tetrahedron_shape(
    @math.Tetrahedron::new(
      @math.Vec3::new(-1.0F, -0.67F, 0.5F),
      @math.Vec3::new(1.0F, -0.67F, 0.5F),
      @math.Vec3::new(0.0F, -0.67F, -1.17F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  debug_inspect(geometry.validate(), content="None")
  debug_inspect(geometry.vertex_count(), content="12")
  debug_inspect(geometry.triangle_count(), content="Some(4)")
}

///|
test "render3d: Assets::add accepts common primitive authoring values" {
  let meshes : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
  let cuboid = meshes |> add_mesh(@math.Cuboid::new(1.0F, 2.0F, 3.0F))
  let plane = meshes |> add_mesh(@math.Plane3d::default())
  let sphere = meshes |> add_mesh(@math.Sphere::new(0.5F))
  let tetrahedron = meshes
    |> add_mesh(
      @math.Tetrahedron::new(
        @math.Vec3::new(-1.0F, -0.67F, 0.5F),
        @math.Vec3::new(1.0F, -0.67F, 0.5F),
        @math.Vec3::new(0.0F, -0.67F, -1.17F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    )
  let ok = if meshes.get(cuboid) is Some(cuboid_mesh) {
    if meshes.get(plane) is Some(plane_mesh) {
      if meshes.get(sphere) is Some(sphere_mesh) {
        if meshes.get(tetrahedron) is Some(tetrahedron_mesh) {
          cuboid_mesh.as_3d_geometry() is Some(cuboid_geometry) &&
          cuboid_geometry.validate() is None &&
          plane_mesh.as_3d_geometry() is Some(plane_geometry) &&
          plane_geometry.validate() is None &&
          plane_geometry.vertex_count() == 6 &&
          sphere_mesh.as_3d_geometry() is Some(sphere_geometry) &&
          sphere_geometry.validate() is None &&
          tetrahedron_mesh.as_3d_geometry() is Some(tetrahedron_geometry) &&
          tetrahedron_geometry.triangle_count() == Some(4)
        } else {
          false
        }
      } else {
        false
      }
    } else {
      false
    }
  } else {
    false
  }
  debug_inspect(ok, content="true")
}
