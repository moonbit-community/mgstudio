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
// Bevy source: `bevy/crates/bevy_camera/src/primitives.rs`.

///|
pub struct Aabb {
  inner : @math.Aabb3d
}

///|
pub type Sphere = @math.BoundingSphere

///|
pub type Frustum = @pbr.Frustum

///|
pub let ecs_key_aabb : @ecs.ComponentKey[Aabb] = @ecs.register_component(
  debug_name="mgstudio_camera::Aabb",
)

///|
pub impl @ecs.Component for Aabb with component() {
  ecs_key_aabb
}

///|
pub fn Aabb::from_math(inner : @math.Aabb3d) -> Aabb {
  Aabb::{ inner, }
}

///|
pub fn Aabb::to_math(self : Aabb) -> @math.Aabb3d {
  self.inner
}

///|
pub fn Aabb::from_min_max(min : @math.Vec3, max : @math.Vec3) -> Aabb {
  Aabb::from_math(@math.Aabb3d::from_min_max(min, max))
}

///|
pub fn Aabb::center(self : Aabb) -> @math.Vec3 {
  self.inner.center()
}

///|
pub fn Aabb::half_size(self : Aabb) -> @math.Vec3 {
  self.inner.half_size()
}

///|
pub(open) trait MeshAabb {
  compute_aabb(self : Self) -> Aabb?
}

///|
fn mesh3d_geometry_compute_aabb(geometry : @mesh.Mesh3dGeometry) -> Aabb? {
  let vertex_count = geometry.vertex_count()
  if vertex_count == 0 {
    return None
  }
  guard geometry.vertex_position(0) is Some(first) else { return None }
  let mut min_x = first.x
  let mut min_y = first.y
  let mut min_z = first.z
  let mut max_x = first.x
  let mut max_y = first.y
  let mut max_z = first.z
  for index in 1..<vertex_count {
    guard geometry.vertex_position(index) is Some(position) else { continue }
    if position.x < min_x {
      min_x = position.x
    }
    if position.y < min_y {
      min_y = position.y
    }
    if position.z < min_z {
      min_z = position.z
    }
    if position.x > max_x {
      max_x = position.x
    }
    if position.y > max_y {
      max_y = position.y
    }
    if position.z > max_z {
      max_z = position.z
    }
  }
  Some(
    Aabb::from_min_max(
      @math.Vec3::new(min_x, min_y, min_z),
      @math.Vec3::new(max_x, max_y, max_z),
    ),
  )
}

///|
pub impl MeshAabb for @mesh.Mesh3dGeometry with compute_aabb(self) {
  mesh3d_geometry_compute_aabb(self)
}

///|
pub impl MeshAabb for @mesh.Mesh with compute_aabb(self) {
  match self.as_3d_geometry() {
    Some(geometry) => mesh3d_geometry_compute_aabb(geometry)
    None => None
  }
}

///|
pub fn mesh_compute_aabb(mesh : @mesh.Mesh) -> Aabb? {
  match mesh.as_3d_geometry() {
    Some(geometry) => mesh3d_geometry_compute_aabb(geometry)
    None => None
  }
}
