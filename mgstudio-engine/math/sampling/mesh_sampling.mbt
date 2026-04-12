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
// Bevy source: `bevy/crates/bevy_math/src/sampling/mesh_sampling.rs`.

///|
pub(all) suberror UniformMeshSamplerError {
  Empty
  ZeroSurfaceArea
}

///|
pub struct UniformMeshSampler {
  triangles : Array[@math.Triangle3d]
  cumulative_areas : Array[Float]
  total_area : Float
}

///|
pub fn UniformMeshSampler::try_new(
  triangles : Array[@math.Triangle3d],
) -> UniformMeshSampler raise UniformMeshSamplerError {
  if triangles.is_empty() {
    raise Empty
  }
  let cumulative_areas : Array[Float] = []
  let mut total_area = 0.0F
  for triangle in triangles {
    total_area = total_area + triangle.area()
    cumulative_areas.push(total_area)
  }
  if total_area <= 0.0F {
    raise ZeroSurfaceArea
  }
  UniformMeshSampler::{ triangles, cumulative_areas, total_area }
}

///|
pub fn UniformMeshSampler::sample(
  self : UniformMeshSampler,
  rng : @random.Rand,
) -> @math.Vec3 {
  let target = rng.float() * self.total_area
  let mut index = 0
  while index + 1 < self.cumulative_areas.length() &&
        target > self.cumulative_areas[index] {
    index = index + 1
  }
  self.triangles[index].sample_interior(rng)
}

///|
pub fn UniformMeshSampler::sample_iter(
  self : UniformMeshSampler,
  rng : @random.Rand,
) -> Iter[@math.Vec3] {
  Iter::new(fn() { Some(self.sample(rng)) })
}
