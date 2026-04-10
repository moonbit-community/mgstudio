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
// Bevy source: `bevy/crates/bevy_pbr/src/light_probe/mod.rs`.

///|
pub const MAX_VIEW_LIGHT_PROBES : Int = 8

///|
pub const LIGHT_PROBE_MODULE_TAG : String = "bevy_pbr::light_probe"

///|
pub fn max_view_light_probes() -> Int {
  MAX_VIEW_LIGHT_PROBES
}

///|
pub struct LightProbePlugin {}

///|
pub fn LightProbePlugin::default() -> LightProbePlugin {
  LightProbePlugin::{  }
}

///|
pub struct LightProbesUniform {
  reflection_probe_count : Int
  irradiance_volume_count : Int
  view_cubemap_index : Int
}

///|
pub fn LightProbesUniform::default() -> LightProbesUniform {
  LightProbesUniform::{
    reflection_probe_count: 0,
    irradiance_volume_count: 0,
    view_cubemap_index: -1,
  }
}

///|
pub struct ViewLightProbesUniformOffset {
  offset : UInt
}

///|
pub fn ViewLightProbesUniformOffset::default() -> ViewLightProbesUniformOffset {
  ViewLightProbesUniformOffset::{ offset: 0U }
}
