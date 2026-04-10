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
pub fn sample_dir2(rng : @random.Rand) -> @math.Dir2 {
  @math.Dir2::from_rng(rng)
}

///|
pub fn sample_dir3(rng : @random.Rand) -> @math.Dir3 {
  @math.Dir3::from_rng(rng)
}

///|
pub fn sample_quat(rng : @random.Rand) -> @math.Quat {
  @math.Quat::from_rng(rng)
}

///|
pub fn sample_rot2(rng : @random.Rand) -> @math.Rot2 {
  @math.Rot2::from_rng(rng)
}
