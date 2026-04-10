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
// Bevy source: `bevy/crates/bevy_solari/src/realtime/mod.rs`.

///|
pub const SOLARI_LIGHTING_PLUGIN_ID : String = "bevy_solari::realtime::SolariLightingPlugin"

///|
pub struct SolariLightingPlugin {}

///|
pub fn SolariLightingPlugin::default() -> SolariLightingPlugin {
  SolariLightingPlugin::{  }
}

///|
pub struct SolariLighting {
  enabled : Bool
}

///|
pub fn SolariLighting::default() -> SolariLighting {
  SolariLighting::{ enabled: true }
}

///|
pub fn SolariLighting::enabled(self : SolariLighting) -> Bool {
  self.enabled
}

///|
pub fn solari_lighting_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
}
