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
fn sampling_test_absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
test "sampling: from_rng stays deterministic for seeded sources" {
  let rng0 = @random.Rand::chacha8(seed=b"mathfromrngseed00000000000000000")
  let rng1 = @random.Rand::chacha8(seed=b"mathfromrngseed00000000000000000")
  let dir0 = Dir3::from_rng(rng0)
  let dir1 = Dir3::from_rng(rng1)
  inspect(
    sampling_test_absf(dir0.as_vec3().x - dir1.as_vec3().x) < 0.000001F,
    content="true",
  )
  inspect(
    sampling_test_absf(dir0.as_vec3().y - dir1.as_vec3().y) < 0.000001F,
    content="true",
  )
  inspect(
    sampling_test_absf(dir0.as_vec3().z - dir1.as_vec3().z) < 0.000001F,
    content="true",
  )
}

///|
test "sampling: uniform mesh sampler produces points on triangle faces" {
  let sampler = UniformMeshSampler::try_new([
    Triangle3d::new(
      Vec3::new(0.0F, 0.0F, 0.0F),
      Vec3::new(1.0F, 0.0F, 0.0F),
      Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    Triangle3d::new(
      Vec3::new(0.0F, 0.0F, 1.0F),
      Vec3::new(1.0F, 0.0F, 1.0F),
      Vec3::new(0.0F, 1.0F, 1.0F),
    ),
  ]).unwrap()
  let point = sampler.sample(
    @random.Rand::chacha8(seed=b"uniformmeshsamplerseed0000000000"),
  )
  inspect(point.z == 0.0F || point.z == 1.0F, content="true")
}
