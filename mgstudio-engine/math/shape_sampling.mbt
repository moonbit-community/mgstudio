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
pub struct SamplingDistribution[T] {
  sample_one : (@random.Rand) -> T
}

///|
pub fn[T] SamplingDistribution::new(
  sample_one : (@random.Rand) -> T,
) -> SamplingDistribution[T] {
  SamplingDistribution::{ sample_one, }
}

///|
pub fn[T] SamplingDistribution::sample(
  self : SamplingDistribution[T],
  rng : @random.Rand,
) -> T {
  (self.sample_one)(rng)
}

///|
pub fn[T] SamplingDistribution::sample_iter(
  self : SamplingDistribution[T],
  rng : @random.Rand,
) -> Iter[T] {
  let dist = self
  Iter::new(fn() { Some(dist.sample(rng)) })
}

///|
pub fn Sphere::sample_interior(self : Sphere, rng : @random.Rand) -> Vec3 {
  let safe_radius = sampling_non_negative(self.radius)
  if safe_radius <= 0.0F {
    return Vec3::zero()
  }
  let radius_cubed = safe_radius * safe_radius * safe_radius
  let sample_radius = pow(rng.float() * radius_cubed, 0.3333333333333333F)
  sampling_sample_unit_sphere_boundary(rng).mul_scalar(sample_radius)
}

///|
pub fn Sphere::sample_boundary(self : Sphere, rng : @random.Rand) -> Vec3 {
  let safe_radius = sampling_non_negative(self.radius)
  if safe_radius <= 0.0F {
    return Vec3::zero()
  }
  sampling_sample_unit_sphere_boundary(rng).mul_scalar(safe_radius)
}

///|
pub fn Sphere::interior_dist(self : Sphere) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_interior(rng) })
}

///|
pub fn Sphere::boundary_dist(self : Sphere) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_boundary(rng) })
}

///|
pub fn Cylinder::sample_interior(self : Cylinder, rng : @random.Rand) -> Vec3 {
  let safe_radius = sampling_non_negative(self.radius)
  let safe_half_height = sampling_non_negative(self.half_height)
  let (x, z) = sampling_sample_disk_interior(rng, safe_radius)
  let y = shape_sample_axis(rng, safe_half_height)
  Vec3::new(x, y, z)
}

///|
pub fn Cylinder::sample_boundary(self : Cylinder, rng : @random.Rand) -> Vec3 {
  let safe_radius = sampling_non_negative(self.radius)
  let safe_half_height = sampling_non_negative(self.half_height)
  if safe_radius + 2.0F * safe_half_height <= 0.0F {
    return Vec3::zero()
  }
  if rng.float() < safe_radius / (safe_radius + 2.0F * safe_half_height) {
    let (x, z) = sampling_sample_disk_interior(rng, safe_radius)
    let y = if rng.boolean() { safe_half_height } else { -safe_half_height }
    Vec3::new(x, y, z)
  } else {
    let (x, z) = sampling_sample_disk_boundary(rng, safe_radius)
    Vec3::new(x, shape_sample_axis(rng, safe_half_height), z)
  }
}

///|
pub fn Cylinder::interior_dist(self : Cylinder) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_interior(rng) })
}

///|
pub fn Cylinder::boundary_dist(self : Cylinder) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_boundary(rng) })
}

///|
pub fn Capsule3d::sample_interior(self : Capsule3d, rng : @random.Rand) -> Vec3 {
  let safe_radius = sampling_non_negative(self.radius)
  let safe_half_length = sampling_non_negative(self.half_length)
  let cylinder_volume = pi() *
    safe_radius *
    safe_radius *
    2.0F *
    safe_half_length
  let capsule_volume = cylinder_volume +
    1.3333333333333333F * pi() * safe_radius * safe_radius * safe_radius
  if capsule_volume <= 0.0F {
    return Vec3::zero()
  }
  if rng.float() < cylinder_volume / capsule_volume {
    Cylinder::{ radius: safe_radius, half_height: safe_half_length }.sample_interior(
      rng,
    )
  } else {
    let sphere_point = Sphere::{ radius: safe_radius }.sample_interior(rng)
    if sphere_point.y > 0.0F {
      sphere_point.add(Vec3::new(0.0F, safe_half_length, 0.0F))
    } else {
      sphere_point.add(Vec3::new(0.0F, -safe_half_length, 0.0F))
    }
  }
}

///|
pub fn Capsule3d::sample_boundary(self : Capsule3d, rng : @random.Rand) -> Vec3 {
  let safe_radius = sampling_non_negative(self.radius)
  let safe_half_length = sampling_non_negative(self.half_length)
  let cylinder_surface = 2.0F * pi() * safe_radius * 2.0F * safe_half_length
  let capsule_surface = cylinder_surface +
    4.0F * pi() * safe_radius * safe_radius
  if capsule_surface <= 0.0F {
    return Vec3::zero()
  }
  if rng.float() < cylinder_surface / capsule_surface {
    let (x, z) = sampling_sample_disk_boundary(rng, safe_radius)
    Vec3::new(x, shape_sample_axis(rng, safe_half_length), z)
  } else {
    let sphere_point = Sphere::{ radius: safe_radius }.sample_boundary(rng)
    if sphere_point.y > 0.0F {
      sphere_point.add(Vec3::new(0.0F, safe_half_length, 0.0F))
    } else {
      sphere_point.add(Vec3::new(0.0F, -safe_half_length, 0.0F))
    }
  }
}

///|
pub fn Capsule3d::interior_dist(self : Capsule3d) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_interior(rng) })
}

///|
pub fn Capsule3d::boundary_dist(self : Capsule3d) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_boundary(rng) })
}

///|
pub fn Triangle3d::sample_interior(
  self : Triangle3d,
  rng : @random.Rand,
) -> Vec3 {
  guard sampling_triangle_vertices(self.vertices) is Some((a, b, c)) else {
    return Vec3::zero()
  }
  sampling_sample_triangle_interior(a, b, c, rng)
}

///|
pub fn Triangle3d::sample_boundary(
  self : Triangle3d,
  rng : @random.Rand,
) -> Vec3 {
  guard sampling_triangle_vertices(self.vertices) is Some((a, b, c)) else {
    return Vec3::zero()
  }
  sampling_sample_triangle_boundary(a, b, c, rng)
}

///|
pub fn Triangle3d::interior_dist(
  self : Triangle3d,
) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_interior(rng) })
}

///|
pub fn Triangle3d::boundary_dist(
  self : Triangle3d,
) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_boundary(rng) })
}

///|
pub fn Tetrahedron::sample_interior(
  self : Tetrahedron,
  rng : @random.Rand,
) -> Vec3 {
  guard sampling_tetrahedron_vertices(self.vertices) is Some((a, b, c, d)) else {
    return Vec3::zero()
  }
  let x0 = rng.float()
  let x1 = rng.float()
  let x2 = rng.float()
  let (u0, u1, u2) = sampling_sort3(x0, x1, x2)
  let wa = u0
  let wb = u1 - u0
  let wc = u2 - u1
  let wd = 1.0F - u2
  a
  .mul_scalar(wa)
  .add(b.mul_scalar(wb))
  .add(c.mul_scalar(wc))
  .add(d.mul_scalar(wd))
}

///|
pub fn Tetrahedron::sample_boundary(
  self : Tetrahedron,
  rng : @random.Rand,
) -> Vec3 {
  let faces = self.faces()
  if faces.length() != 4 {
    return Vec3::zero()
  }
  let weights = faces.iter().map(sampling_triangle_area).collect()
  guard sampling_weighted_index(weights, rng) is Some(face_index) else {
    return faces[0].sample_interior(rng)
  }
  faces[face_index].sample_interior(rng)
}

///|
pub fn Tetrahedron::interior_dist(
  self : Tetrahedron,
) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_interior(rng) })
}

///|
pub fn Tetrahedron::boundary_dist(
  self : Tetrahedron,
) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_boundary(rng) })
}

///|
pub fn Cuboid::sample_boundary(self : Cuboid, rng : @random.Rand) -> Vec3 {
  let hx = shape_abs_float(self.half_size.x)
  let hy = shape_abs_float(self.half_size.y)
  let hz = shape_abs_float(self.half_size.z)
  let weights = [hy * hz, hx * hz, hx * hy]
  guard sampling_weighted_index(weights, rng) is Some(face_index) else {
    return Vec3::zero()
  }
  let side0 = rng.float() * 2.0F - 1.0F
  let side1 = rng.float() * 2.0F - 1.0F
  let fixed_side = if rng.boolean() { 1.0F } else { -1.0F }
  match face_index {
    0 => Vec3::new(fixed_side * hx, side0 * hy, side1 * hz)
    1 => Vec3::new(side0 * hx, fixed_side * hy, side1 * hz)
    _ => Vec3::new(side0 * hx, side1 * hy, fixed_side * hz)
  }
}

///|
pub fn Cuboid::interior_dist(self : Cuboid) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_interior(rng) })
}

///|
pub fn Cuboid::boundary_dist(self : Cuboid) -> SamplingDistribution[Vec3] {
  SamplingDistribution::new(fn(rng) { self.sample_boundary(rng) })
}

///|
fn sampling_non_negative(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn sampling_sample_unit_sphere_boundary(rng : @random.Rand) -> Vec3 {
  let z = rng.float() * 2.0F - 1.0F
  let angle = (rng.float() * 2.0F - 1.0F) * pi()
  let c = sqrt(1.0F - z * z)
  Vec3::new(sin(angle) * c, cos(angle) * c, z)
}

///|
fn sampling_sample_disk_interior(
  rng : @random.Rand,
  radius : Float,
) -> (Float, Float) {
  if radius <= 0.0F {
    return (0.0F, 0.0F)
  }
  let angle = rng.float() * 2.0F * pi()
  let length = sqrt(rng.float()) * radius
  (cos(angle) * length, sin(angle) * length)
}

///|
fn sampling_sample_disk_boundary(
  rng : @random.Rand,
  radius : Float,
) -> (Float, Float) {
  if radius <= 0.0F {
    return (0.0F, 0.0F)
  }
  let angle = rng.float() * 2.0F * pi()
  (cos(angle) * radius, sin(angle) * radius)
}

///|
fn sampling_triangle_vertices(vertices : Array[Vec3]) -> (Vec3, Vec3, Vec3)? {
  if vertices.length() != 3 {
    return None
  }
  Some((vertices[0], vertices[1], vertices[2]))
}

///|
fn sampling_tetrahedron_vertices(
  vertices : Array[Vec3],
) -> (Vec3, Vec3, Vec3, Vec3)? {
  if vertices.length() != 4 {
    return None
  }
  Some((vertices[0], vertices[1], vertices[2], vertices[3]))
}

///|
fn sampling_sample_triangle_interior(
  a : Vec3,
  b : Vec3,
  c : Vec3,
  rng : @random.Rand,
) -> Vec3 {
  let ab = b.sub(a)
  let ac = c.sub(a)
  let mut u = rng.float()
  let mut v = rng.float()
  if u + v > 1.0F {
    let next_u = 1.0F - v
    let next_v = 1.0F - u
    u = next_u
    v = next_v
  }
  a.add(ab.mul_scalar(u)).add(ac.mul_scalar(v))
}

///|
fn sampling_sample_triangle_boundary(
  a : Vec3,
  b : Vec3,
  c : Vec3,
  rng : @random.Rand,
) -> Vec3 {
  let ab = b.sub(a)
  let ac = c.sub(a)
  let bc = c.sub(b)
  let weights = [ab.length(), ac.length(), bc.length()]
  let t = rng.float()
  guard sampling_weighted_index(weights, rng) is Some(edge_index) else {
    return a
  }
  match edge_index {
    0 => sampling_vec3_lerp(a, b, t)
    1 => sampling_vec3_lerp(a, c, t)
    _ => sampling_vec3_lerp(b, c, t)
  }
}

///|
fn sampling_triangle_area(triangle : Triangle3d) -> Float {
  guard sampling_triangle_vertices(triangle.vertices) is Some((a, b, c)) else {
    return 0.0F
  }
  b.sub(a).cross(c.sub(a)).length() * 0.5F
}

///|
fn sampling_vec3_lerp(a : Vec3, b : Vec3, t : Float) -> Vec3 {
  a.add(b.sub(a).mul_scalar(t))
}

///|
fn sampling_weighted_index(weights : Array[Float], rng : @random.Rand) -> Int? {
  let total = weights
    .iter()
    .fold(init=0.0F, fn(acc, weight) {
      if weight > 0.0F {
        acc + weight
      } else {
        acc
      }
    })
  if total <= 0.0F {
    return None
  }
  let target = rng.float() * total
  let mut accumulated = 0.0F
  for index in 0..<weights.length() {
    let weight = weights[index]
    if weight <= 0.0F {
      continue
    }
    accumulated = accumulated + weight
    if target < accumulated {
      return Some(index)
    }
  }
  Some(weights.length() - 1)
}

///|
fn sampling_sort3(a : Float, b : Float, c : Float) -> (Float, Float, Float) {
  let mut x = a
  let mut y = b
  let mut z = c
  if x > y {
    let next = x
    x = y
    y = next
  }
  if y > z {
    let next = y
    y = z
    z = next
  }
  if x > y {
    let next = x
    x = y
    y = next
  }
  (x, y, z)
}

///|
fn shape_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn shape_sample_axis(rng : @random.Rand, half_extent : Float) -> Float {
  (rng.float() * 2.0F - 1.0F) * half_extent
}
