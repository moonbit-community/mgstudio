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
pub struct ExtractedAtmosphere {
  inner_radius : Float
  outer_radius : Float
  ground_albedo : @math.Vec3
  medium_id : Int
}

///|
pub fn ExtractedAtmosphere::ExtractedAtmosphere() -> ExtractedAtmosphere {
  ExtractedAtmosphere::{
    inner_radius: 6_360_000.0F,
    outer_radius: 6_460_000.0F,
    ground_albedo: @math.Vec3::new(0.3F, 0.3F, 0.3F),
    medium_id: 0,
  }
}

///|
pub fn pbr_extracted_atmosphere(
  inner_radius : Float,
  outer_radius : Float,
  ground_albedo : @math.Vec3,
  medium_id : Int,
) -> ExtractedAtmosphere {
  ExtractedAtmosphere::{ inner_radius, outer_radius, ground_albedo, medium_id }
}

///|
pub struct AtmosphereRenderNodeState {
  luts_ready : Bool
  render_sky_ready : Bool
}

///|
pub fn AtmosphereRenderNodeState::AtmosphereRenderNodeState() -> AtmosphereRenderNodeState {
  AtmosphereRenderNodeState::{ luts_ready: false, render_sky_ready: false }
}

///|
pub fn pbr_atmosphere_default() -> Atmosphere {
  Atmosphere()
}

///|
pub fn pbr_atmosphere_earthlike(medium : @light.ScatteringMedium) -> Atmosphere {
  Atmosphere::earthlike(medium)
}

///|
pub fn pbr_atmosphere_with_radii(
  atmosphere : Atmosphere,
  inner_radius : Float,
  outer_radius : Float,
) -> Atmosphere {
  atmosphere.with_radii(inner_radius, outer_radius)
}
