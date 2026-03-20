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
pub impl FromRng for Dir2 with from_rng(rng) {
  Dir2::from_angle(rng.float() * 2.0F * pi())
}

///|
pub impl FromRng for Dir3 with from_rng(rng) {
  let value = Sphere::new(1.0F).sample_boundary(rng)
  Dir3::new_unchecked(value)
}

///|
pub impl FromRng for Rot2 with from_rng(rng) {
  Rot2::radians(rng.float() * 2.0F * pi())
}

///|
pub impl FromRng for Quat with from_rng(rng) {
  let u1 = rng.float()
  let u2 = rng.float()
  let u3 = rng.float()
  let r1 = sqrt(1.0F - u1)
  let r2 = sqrt(u1)
  let theta1 = 2.0F * pi() * u2
  let theta2 = 2.0F * pi() * u3
  Quat::new(
    r1 * sin(theta1),
    r1 * cos(theta1),
    r2 * sin(theta2),
    r2 * cos(theta2),
  ).normalize()
}
