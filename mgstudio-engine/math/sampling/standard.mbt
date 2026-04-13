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
// Bevy source: `bevy/crates/bevy_math/src/sampling/standard.rs`.

///|
pub impl FromRng for @math.Dir2 with from_rng(rng) {
  @math.Dir2::from_angle(rng.float() * 2.0F * @math.pi())
}

///|
pub impl FromRng for @math.Dir3 with from_rng(rng) {
  let value = @math.Sphere::new(1.0F).sample_boundary(rng)
  @math.Dir3::new_unchecked(value)
}

///|
pub impl FromRng for @math.Rot2 with from_rng(rng) {
  @math.Rot2::radians(rng.float() * 2.0F * @math.pi())
}

///|
pub impl FromRng for @math.Quat with from_rng(rng) {
  let u1 = rng.float()
  let u2 = rng.float()
  let u3 = rng.float()
  let r1 = @math.sqrt(1.0F - u1)
  let r2 = @math.sqrt(u1)
  let theta1 = 2.0F * @math.pi() * u2
  let theta2 = 2.0F * @math.pi() * u3
  @math.Quat::new(
    r1 * @math.sin(theta1),
    r1 * @math.cos(theta1),
    r2 * @math.sin(theta2),
    r2 * @math.cos(theta2),
  ).normalize()
}

///|
pub fn sample_dir2(rng : @random.Rand) -> @math.Dir2 {
  FromRng::from_rng(rng)
}

///|
pub fn sample_dir3(rng : @random.Rand) -> @math.Dir3 {
  FromRng::from_rng(rng)
}

///|
pub fn sample_quat(rng : @random.Rand) -> @math.Quat {
  FromRng::from_rng(rng)
}

///|
pub fn sample_rot2(rng : @random.Rand) -> @math.Rot2 {
  FromRng::from_rng(rng)
}
