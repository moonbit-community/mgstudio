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
// Bevy source: `bevy/crates/bevy_anti_alias/src/dlss/mod.rs`.

///|
pub const DLSS_RUNTIME_SUPPORTED : Bool = false

///|
pub(all) enum DlssPerfQualityMode {
  Auto
  Dlaa
  Quality
  Balanced
  Performance
  UltraPerformance
} derive(Eq, Debug)

///|
pub fn DlssPerfQualityMode::default() -> DlssPerfQualityMode {
  Auto
}

///|
pub struct DlssProjectId {
  value : String
}

///|
pub fn DlssProjectId::new(value : String) -> DlssProjectId {
  DlssProjectId::{ value, }
}

///|
pub fn DlssProjectId::value(self : DlssProjectId) -> String {
  self.value
}

///|
pub struct DlssInitPlugin {}

///|
pub fn DlssInitPlugin::default() -> DlssInitPlugin {
  DlssInitPlugin::{  }
}

///|
pub struct DlssPlugin {}

///|
pub fn DlssPlugin::default() -> DlssPlugin {
  DlssPlugin::{  }
}

///|
pub struct Dlss {
  perf_quality_mode : DlssPerfQualityMode
  reset : Bool
}

///|
pub fn Dlss::default() -> Dlss {
  Dlss::{ perf_quality_mode: DlssPerfQualityMode::default(), reset: false }
}

///|
pub struct DlssSuperResolutionSupported {} derive(Default, Eq, Debug)

///|
pub struct DlssRayReconstructionSupported {} derive(Default, Eq, Debug)

///|
let dlss_project_id_resource_key : @ecs.ResourceKey[DlssProjectId] = @ecs.register_resource(
  debug_name="bevy_anti_alias::DlssProjectId",
)

///|
pub impl @app.Resource for DlssProjectId with resource() {
  dlss_project_id_resource_key
}

///|
pub fn dlss_init_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}

///|
pub fn dlss_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
