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
pub(all) struct Cuboid {
  half_size : Vec3
}

///|
pub fn Cuboid::Cuboid() -> Cuboid {
  { half_size: Vec3::splat(0.5F) }
}

///|
pub impl Default for Cuboid with fn default() {
  Cuboid()
}

///|
pub fn Cuboid::new(
  x_length : Float,
  y_length : Float,
  z_length : Float,
) -> Cuboid {
  Cuboid::from_size(Vec3::new(x_length, y_length, z_length))
}

///|
pub fn Cuboid::from_size(size : Vec3) -> Cuboid {
  { half_size: size.mul_scalar(0.5F) }
}

///|
pub fn Cuboid::from_corners(point1 : Vec3, point2 : Vec3) -> Cuboid {
  Cuboid::from_size(
    Vec3::new(
      dim3_abs_float(point2.x - point1.x),
      dim3_abs_float(point2.y - point1.y),
      dim3_abs_float(point2.z - point1.z),
    ),
  )
}

///|
pub fn Cuboid::from_length(length : Float) -> Cuboid {
  { half_size: Vec3::splat(length * 0.5F) }
}

///|
pub fn Cuboid::size(self : Cuboid) -> Vec3 {
  self.half_size.mul_scalar(2.0F)
}

///|
pub fn Cuboid::sample_interior(self : Cuboid, rng : @random.Rand) -> Vec3 {
  Vec3::new(
    dim3_sample_axis(rng, self.half_size.x),
    dim3_sample_axis(rng, self.half_size.y),
    dim3_sample_axis(rng, self.half_size.z),
  )
}

///|
pub impl ToJson for Cuboid with fn to_json(self) {
  self.half_size |> ToJson::to_json
}

///|
pub impl @json.FromJson for Cuboid with fn from_json(json, path) {
  { half_size: @json.from_json(json, path~) }
}

///|
pub(all) struct Extrusion[T] {
  base_shape : T
  half_depth : Float
}

///|
pub fn[T] Extrusion::new(base_shape : T, depth : Float) -> Extrusion[T] {
  { base_shape, half_depth: depth / 2.0F }
}

///|
pub(all) struct Sphere {
  radius : Float
} derive(ToJson, FromJson)

///|
pub fn Sphere::Sphere() -> Sphere {
  { radius: 0.5F }
}

///|
pub impl Default for Sphere with fn default() {
  Sphere()
}

///|
pub fn Sphere::new(radius : Float) -> Sphere {
  { radius, }
}

///|
pub fn Sphere::diameter(self : Sphere) -> Float {
  self.radius * 2.0F
}

///|
pub(all) struct Cylinder {
  radius : Float
  half_height : Float
} derive(ToJson, FromJson)

///|
pub fn Cylinder::Cylinder() -> Cylinder {
  { radius: 0.5F, half_height: 0.5F }
}

///|
pub impl Default for Cylinder with fn default() {
  Cylinder()
}

///|
pub fn Cylinder::new(radius : Float, height : Float) -> Cylinder {
  { radius, half_height: height * 0.5F }
}

///|
pub struct Plane3d {
  normal : Dir3
  half_size : Vec2
}

///|
pub fn Plane3d::new(normal : Vec3, half_size : Vec2) -> Plane3d {
  let direction = Dir3::new(normal) catch { _ => Dir3::y() }
  { normal: direction, half_size }
}

///|
pub fn Plane3d::Plane3d() -> Plane3d {
  { normal: Dir3::y(), half_size: Vec2::new(0.5F, 0.5F) }
}

///|
pub fn Plane3d::normal(self : Plane3d) -> Dir3 {
  self.normal
}

///|
pub fn Plane3d::half_size(self : Plane3d) -> Vec2 {
  self.half_size
}

///|
pub struct InfinitePlane3d {
  normal : Dir3
}

///|
pub fn InfinitePlane3d::new(normal : Vec3) -> InfinitePlane3d {
  let direction = Dir3::new(normal) catch { _ => Dir3::y() }
  { normal: direction }
}

///|
pub fn InfinitePlane3d::InfinitePlane3d() -> InfinitePlane3d {
  { normal: Dir3::y() }
}

///|
pub fn InfinitePlane3d::signed_distance(
  self : InfinitePlane3d,
  isometry : Isometry3d,
  point : Vec3,
) -> Float {
  let local_point = isometry.inverse().transform_point3(point)
  self.normal.as_vec3().dot(local_point)
}

///|
pub fn InfinitePlane3d::project_point(
  self : InfinitePlane3d,
  isometry : Isometry3d,
  point : Vec3,
) -> Vec3 {
  point.sub(
    self.normal.as_vec3().mul_scalar(self.signed_distance(isometry, point)),
  )
}

///|
pub struct Line3d {
  direction : Dir3
}

///|
pub fn Line3d::new(direction : Vec3) -> Line3d {
  let unit = Dir3::new(direction) catch { _ => Dir3::y() }
  { direction: unit }
}

///|
pub fn Line3d::from_dir(direction : Dir3) -> Line3d {
  { direction, }
}

///|
pub struct Segment3d {
  point_a : Vec3
  point_b : Vec3
} derive(ToJson, FromJson)

///|
pub fn Segment3d::Segment3d() -> Segment3d {
  {
    point_a: Vec3::new(-0.5F, 0.0F, 0.0F),
    point_b: Vec3::new(0.5F, 0.0F, 0.0F),
  }
}

///|
pub impl Default for Segment3d with fn default() {
  Segment3d()
}

///|
pub fn Segment3d::new(point_a : Vec3, point_b : Vec3) -> Segment3d {
  { point_a, point_b }
}

///|
pub fn Segment3d::point1(self : Segment3d) -> Vec3 {
  self.point_a
}

///|
pub fn Segment3d::point2(self : Segment3d) -> Vec3 {
  self.point_b
}

///|
pub fn Segment3d::center(self : Segment3d) -> Vec3 {
  self.point_a.add(self.point_b).mul_scalar(0.5F)
}

///|
pub fn Segment3d::length(self : Segment3d) -> Float {
  self.point_b.sub(self.point_a).length()
}

///|
pub struct Polyline3d {
  vertices : Array[Vec3]
} derive(ToJson, FromJson)

///|
pub fn Polyline3d::Polyline3d() -> Polyline3d {
  Polyline3d::new([Vec3::new(-0.5F, 0.0F, 0.0F), Vec3::new(0.5F, 0.0F, 0.0F)])
}

///|
pub impl Default for Polyline3d with fn default() {
  Polyline3d()
}

///|
pub fn Polyline3d::new(vertices : Array[Vec3]) -> Polyline3d {
  { vertices, }
}

///|
pub(all) struct Capsule3d {
  radius : Float
  half_length : Float
} derive(ToJson, FromJson)

///|
pub fn Capsule3d::Capsule3d() -> Capsule3d {
  { radius: 0.5F, half_length: 0.5F }
}

///|
pub impl Default for Capsule3d with fn default() {
  Capsule3d()
}

///|
pub fn Capsule3d::new(radius : Float, length : Float) -> Capsule3d {
  { radius, half_length: length * 0.5F }
}

///|
pub struct Cone {
  radius : Float
  height : Float
} derive(ToJson, FromJson)

///|
pub fn Cone::new(radius : Float, height : Float) -> Cone {
  { radius, height }
}

///|
pub fn Cone::Cone() -> Cone {
  { radius: 0.5F, height: 1.0F }
}

///|
pub struct ConicalFrustum {
  radius_top : Float
  radius_bottom : Float
  height : Float
} derive(ToJson, FromJson)

///|
pub fn ConicalFrustum::new(
  radius_top : Float,
  radius_bottom : Float,
  height : Float,
) -> ConicalFrustum {
  { radius_top, radius_bottom, height }
}

///|
pub fn ConicalFrustum::ConicalFrustum() -> ConicalFrustum {
  { radius_top: 0.25F, radius_bottom: 0.5F, height: 1.0F }
}

///|
pub struct Torus {
  major_radius : Float
  minor_radius : Float
} derive(ToJson, FromJson)

///|
pub fn Torus::new(major_radius : Float, minor_radius : Float) -> Torus {
  { major_radius, minor_radius }
}

///|
pub fn Torus::Torus() -> Torus {
  { major_radius: 0.75F, minor_radius: 0.25F }
}

///|
pub fn Torus::outer_radius(self : Torus) -> Float {
  self.major_radius + self.minor_radius
}

///|
pub(all) struct Triangle3d {
  vertices : Array[Vec3]
} derive(ToJson, FromJson)

///|
pub fn Triangle3d::Triangle3d() -> Triangle3d {
  {
    vertices: [
      Vec3::new(0.0F, 0.5F, 0.0F),
      Vec3::new(-0.5F, -0.5F, 0.0F),
      Vec3::new(0.5F, -0.5F, 0.0F),
    ],
  }
}

///|
pub impl Default for Triangle3d with fn default() {
  Triangle3d()
}

///|
pub fn Triangle3d::new(a : Vec3, b : Vec3, c : Vec3) -> Triangle3d {
  { vertices: [a, b, c] }
}

///|
pub(all) struct Tetrahedron {
  vertices : Array[Vec3]
} derive(ToJson, FromJson)

///|
pub fn Tetrahedron::Tetrahedron() -> Tetrahedron {
  {
    vertices: [
      Vec3::new(0.5F, 0.5F, 0.5F),
      Vec3::new(-0.5F, 0.5F, -0.5F),
      Vec3::new(-0.5F, -0.5F, 0.5F),
      Vec3::new(0.5F, -0.5F, -0.5F),
    ],
  }
}

///|
pub impl Default for Tetrahedron with fn default() {
  Tetrahedron()
}

///|
pub fn Tetrahedron::new(a : Vec3, b : Vec3, c : Vec3, d : Vec3) -> Tetrahedron {
  { vertices: [a, b, c, d] }
}

///|
pub fn Tetrahedron::faces(self : Tetrahedron) -> Array[Triangle3d] {
  if self.vertices.length() != 4 {
    return []
  }
  let a = self.vertices[0]
  let b = self.vertices[1]
  let c = self.vertices[2]
  let d = self.vertices[3]
  [
    Triangle3d::new(b, c, d),
    Triangle3d::new(a, d, c),
    Triangle3d::new(a, b, d),
    Triangle3d::new(a, c, b),
  ]
}

///|
fn dim3_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn dim3_sample_axis(rng : @random.Rand, half_extent : Float) -> Float {
  (rng.float() * 2.0F - 1.0F) * half_extent
}
