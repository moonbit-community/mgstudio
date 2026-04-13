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
// Bevy source: `bevy/crates/bevy_math/src/sampling/shape_sampling.rs`.

///|
pub fn sphere_boundary_distribution(
  shape : @math.Sphere,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_boundary(rng) })
}

///|
pub fn sphere_interior_distribution(
  shape : @math.Sphere,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_interior(rng) })
}

///|
pub fn sphere_sample_boundary(
  shape : @math.Sphere,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_boundary(rng)
}

///|
pub fn sphere_sample_interior(
  shape : @math.Sphere,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_interior(rng)
}

///|
pub fn cylinder_boundary_distribution(
  shape : @math.Cylinder,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_boundary(rng) })
}

///|
pub fn cylinder_interior_distribution(
  shape : @math.Cylinder,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_interior(rng) })
}

///|
pub fn cylinder_sample_boundary(
  shape : @math.Cylinder,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_boundary(rng)
}

///|
pub fn cylinder_sample_interior(
  shape : @math.Cylinder,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_interior(rng)
}

///|
pub fn capsule3d_boundary_distribution(
  shape : @math.Capsule3d,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_boundary(rng) })
}

///|
pub fn capsule3d_interior_distribution(
  shape : @math.Capsule3d,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_interior(rng) })
}

///|
pub fn capsule3d_sample_boundary(
  shape : @math.Capsule3d,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_boundary(rng)
}

///|
pub fn capsule3d_sample_interior(
  shape : @math.Capsule3d,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_interior(rng)
}

///|
pub fn triangle3d_boundary_distribution(
  shape : @math.Triangle3d,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_boundary(rng) })
}

///|
pub fn triangle3d_interior_distribution(
  shape : @math.Triangle3d,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_interior(rng) })
}

///|
pub fn triangle3d_sample_boundary(
  shape : @math.Triangle3d,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_boundary(rng)
}

///|
pub fn triangle3d_sample_interior(
  shape : @math.Triangle3d,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_interior(rng)
}

///|
pub fn tetrahedron_boundary_distribution(
  shape : @math.Tetrahedron,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_boundary(rng) })
}

///|
pub fn tetrahedron_interior_distribution(
  shape : @math.Tetrahedron,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_interior(rng) })
}

///|
pub fn tetrahedron_sample_boundary(
  shape : @math.Tetrahedron,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_boundary(rng)
}

///|
pub fn tetrahedron_sample_interior(
  shape : @math.Tetrahedron,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_interior(rng)
}

///|
pub fn cuboid_boundary_distribution(
  shape : @math.Cuboid,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_boundary(rng) })
}

///|
pub fn cuboid_interior_distribution(
  shape : @math.Cuboid,
) -> SamplingDistribution[@math.Vec3] {
  SamplingDistribution::new(fn(rng) { shape.sample_interior(rng) })
}

///|
pub fn cuboid_sample_boundary(
  shape : @math.Cuboid,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_boundary(rng)
}

///|
pub fn cuboid_sample_interior(
  shape : @math.Cuboid,
  rng : @random.Rand,
) -> @math.Vec3 {
  shape.sample_interior(rng)
}
