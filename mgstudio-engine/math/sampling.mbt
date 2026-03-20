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
/// Root surface for random sampling helpers.

///|
pub(open) trait FromRng {
  from_rng(@random.Rand) -> Self
}

///|
pub(open) trait ShapeSample {}

///|
pub impl ShapeSample for Sphere

///|
pub impl ShapeSample for Cuboid

///|
pub impl ShapeSample for Cylinder

///|
pub impl ShapeSample for Capsule3d

///|
pub impl ShapeSample for Triangle3d

///|
pub impl ShapeSample for Tetrahedron

///|
pub fn[T] sample_points(
  distribution : SamplingDistribution[T],
  rng : @random.Rand,
  count : Int,
) -> Array[T] {
  let samples : Array[T] = []
  for _ in 0..<count {
    samples.push(distribution.sample(rng))
  }
  samples
}
