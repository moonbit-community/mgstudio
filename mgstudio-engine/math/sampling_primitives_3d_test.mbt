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
fn sampling_test_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn sampling_test_approx_eq(a : Float, b : Float) -> Bool {
  sampling_test_abs_float(a - b) < 0.0001F
}

///|
fn sampling_test_approx_vec3(a : Vec3, b : Vec3) -> Bool {
  sampling_test_approx_eq(a.x, b.x) &&
  sampling_test_approx_eq(a.y, b.y) &&
  sampling_test_approx_eq(a.z, b.z)
}

///|
fn sampling_test_on_cuboid_boundary(value : Vec3, half_size : Vec3) -> Bool {
  sampling_test_approx_eq(sampling_test_abs_float(value.x), half_size.x) ||
  sampling_test_approx_eq(sampling_test_abs_float(value.y), half_size.y) ||
  sampling_test_approx_eq(sampling_test_abs_float(value.z), half_size.z)
}

///|
fn sampling_test_triangle_barycentric(
  a : Vec3,
  b : Vec3,
  c : Vec3,
  point : Vec3,
) -> (Float, Float, Float)? {
  let v0 = b.sub(a)
  let v1 = c.sub(a)
  let v2 = point.sub(a)
  let d00 = v0.dot(v0)
  let d01 = v0.dot(v1)
  let d11 = v1.dot(v1)
  let d20 = v2.dot(v0)
  let d21 = v2.dot(v1)
  let denom = d00 * d11 - d01 * d01
  if sampling_test_abs_float(denom) <= 1.0e-8F {
    return None
  }
  let v = (d11 * d20 - d01 * d21) / denom
  let w = (d00 * d21 - d01 * d20) / denom
  let u = 1.0F - v - w
  Some((u, v, w))
}

///|
fn sampling_test_capsule_distance_to_segment(
  point : Vec3,
  half_length : Float,
) -> Float {
  let clamped_y = if point.y < -half_length {
    -half_length
  } else if point.y > half_length {
    half_length
  } else {
    point.y
  }
  point.sub(Vec3::new(0.0F, clamped_y, 0.0F)).length()
}

///|
test "math: 3d primitive defaults match Bevy sampling primitives" {
  inspect(
    sampling_test_approx_eq(Sphere::default().radius, 0.5F),
    content="true",
  )
  inspect(
    sampling_test_approx_eq(Cylinder::default().radius, 0.5F) &&
    sampling_test_approx_eq(Cylinder::default().half_height, 0.5F),
    content="true",
  )
  inspect(
    sampling_test_approx_eq(Capsule3d::default().radius, 0.5F) &&
    sampling_test_approx_eq(Capsule3d::default().half_length, 0.5F),
    content="true",
  )
  inspect(Triangle3d::default().vertices.length() == 3, content="true")
  inspect(Tetrahedron::default().vertices.length() == 4, content="true")
}

///|
test "math: cuboid boundary and distribution surface are deterministic" {
  let cuboid = Cuboid::new(3.0F, 7.0F, 2.0F)
  let rng0 = @random.Rand::chacha8(seed=b"cuboid-boundary-seed-00000000001")
  let rng1 = @random.Rand::chacha8(seed=b"cuboid-boundary-seed-00000000001")
  let sample0 = cuboid.sample_boundary(rng0)
  let sample1 = cuboid.sample_boundary(rng1)
  inspect(sampling_test_approx_vec3(sample0, sample1), content="true")
  inspect(
    sampling_test_on_cuboid_boundary(sample0, cuboid.half_size),
    content="true",
  )

  let dist = cuboid.boundary_dist()
  let iter0 = dist
    .sample_iter(
      @random.Rand::chacha8(seed=b"cuboid-dist-seed-000000000000001"),
    )
    .take(3)
    .collect()
  let iter1 = dist
    .sample_iter(
      @random.Rand::chacha8(seed=b"cuboid-dist-seed-000000000000001"),
    )
    .take(3)
    .collect()
  inspect(iter0.length() == 3 && iter1.length() == 3, content="true")
  inspect(sampling_test_approx_vec3(iter0[0], iter1[0]), content="true")
  inspect(sampling_test_approx_vec3(iter0[1], iter1[1]), content="true")
  inspect(sampling_test_approx_vec3(iter0[2], iter1[2]), content="true")
}

///|
test "math: sphere sampling stays in volume and on surface" {
  let sphere = Sphere::new(1.25F)
  let interior = sphere.sample_interior(
    @random.Rand::chacha8(seed=b"sphere-interior-seed-00000000001"),
  )
  let boundary = sphere.sample_boundary(
    @random.Rand::chacha8(seed=b"sphere-boundary-seed-00000000001"),
  )
  inspect(interior.length() <= 1.25F + 0.0001F, content="true")
  inspect(sampling_test_approx_eq(boundary.length(), 1.25F), content="true")
}

///|
test "math: cylinder and capsule boundary samples satisfy geometric constraints" {
  let cylinder = Cylinder::{ radius: 0.5F, half_height: 0.75F }
  let cylinder_sample = cylinder.sample_boundary(
    @random.Rand::chacha8(seed=b"cylinder-boundary-seed-000000001"),
  )
  let cylinder_radial = sqrt(
    cylinder_sample.x * cylinder_sample.x +
    cylinder_sample.z * cylinder_sample.z,
  )
  inspect(
    sampling_test_abs_float(cylinder_sample.y) <= 0.75F + 0.0001F,
    content="true",
  )
  inspect(
    sampling_test_approx_eq(sampling_test_abs_float(cylinder_sample.y), 0.75F) ||
    sampling_test_approx_eq(cylinder_radial, 0.5F),
    content="true",
  )

  let capsule = Capsule3d::{ radius: 0.5F, half_length: 1.0F }
  let capsule_interior = capsule.sample_interior(
    @random.Rand::chacha8(seed=b"capsule-interior-seed-0000000001"),
  )
  let capsule_boundary = capsule.sample_boundary(
    @random.Rand::chacha8(seed=b"capsule-boundary-seed-0000000001"),
  )
  inspect(
    sampling_test_capsule_distance_to_segment(capsule_interior, 1.0F) <=
    0.5F + 0.0001F,
    content="true",
  )
  inspect(
    sampling_test_approx_eq(
      sampling_test_capsule_distance_to_segment(capsule_boundary, 1.0F),
      0.5F,
    ),
    content="true",
  )
}

///|
test "math: triangle and tetrahedron sampling respect barycentric bounds" {
  let triangle = Triangle3d::new(
    Vec3::new(0.0F, 0.0F, 0.0F),
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
  )
  let triangle_interior = triangle.sample_interior(
    @random.Rand::chacha8(seed=b"triangle-interior-seed-000000001"),
  )
  let triangle_boundary = triangle.sample_boundary(
    @random.Rand::chacha8(seed=b"triangle-boundary-seed-000000001"),
  )
  inspect(sampling_test_approx_eq(triangle_interior.z, 0.0F), content="true")
  inspect(sampling_test_approx_eq(triangle_boundary.z, 0.0F), content="true")
  guard sampling_test_triangle_barycentric(
      triangle.vertices[0],
      triangle.vertices[1],
      triangle.vertices[2],
      triangle_interior,
    )
    is Some((u0, v0, w0)) else {
    inspect(false, content="true")
    return
  }
  inspect(u0 >= -0.0001F && v0 >= -0.0001F && w0 >= -0.0001F, content="true")
  inspect(u0 <= 1.0001F && v0 <= 1.0001F && w0 <= 1.0001F, content="true")
  guard sampling_test_triangle_barycentric(
      triangle.vertices[0],
      triangle.vertices[1],
      triangle.vertices[2],
      triangle_boundary,
    )
    is Some((u1, v1, w1)) else {
    inspect(false, content="true")
    return
  }
  inspect(
    sampling_test_abs_float(u1) < 0.0001F ||
    sampling_test_abs_float(v1) < 0.0001F ||
    sampling_test_abs_float(w1) < 0.0001F,
    content="true",
  )

  let tetrahedron = Tetrahedron::new(
    Vec3::new(0.0F, 0.0F, 0.0F),
    Vec3::new(1.0F, 0.0F, 0.0F),
    Vec3::new(0.0F, 1.0F, 0.0F),
    Vec3::new(0.0F, 0.0F, 1.0F),
  )
  let tetrahedron_interior = tetrahedron.sample_interior(
    @random.Rand::chacha8(seed=b"tetrahedron-interior-seed-000001"),
  )
  let tetrahedron_boundary = tetrahedron.sample_boundary(
    @random.Rand::chacha8(seed=b"tetrahedron-boundary-seed-000001"),
  )
  inspect(
    tetrahedron_interior.x >= -0.0001F &&
    tetrahedron_interior.y >= -0.0001F &&
    tetrahedron_interior.z >= -0.0001F,
    content="true",
  )
  inspect(
    tetrahedron_interior.x + tetrahedron_interior.y + tetrahedron_interior.z <=
    1.0001F,
    content="true",
  )
  inspect(
    tetrahedron_boundary.x >= -0.0001F &&
    tetrahedron_boundary.y >= -0.0001F &&
    tetrahedron_boundary.z >= -0.0001F,
    content="true",
  )
  inspect(
    sampling_test_abs_float(tetrahedron_boundary.x) < 0.0001F ||
    sampling_test_abs_float(tetrahedron_boundary.y) < 0.0001F ||
    sampling_test_abs_float(tetrahedron_boundary.z) < 0.0001F ||
    sampling_test_approx_eq(
      tetrahedron_boundary.x + tetrahedron_boundary.y + tetrahedron_boundary.z,
      1.0F,
    ),
    content="true",
  )
}
