// Copyright 2026 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/node.rs`.

///|
pub type Atmosphere = @light.Atmosphere

///|
pub fn pbr_atmosphere_default() -> Atmosphere {
  Atmosphere::default()
}

///|
pub fn pbr_atmosphere_earthlike(medium : @light.ScatteringMedium) -> Atmosphere {
  Atmosphere::earthlike(medium)
}

///|
pub fn pbr_atmosphere_with_radii(
  atmosphere : Atmosphere,
  bottom_radius : Float,
  top_radius : Float,
) -> Atmosphere {
  atmosphere.with_radii(bottom_radius, top_radius)
}
