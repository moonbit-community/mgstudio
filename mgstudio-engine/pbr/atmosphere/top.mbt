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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/mod.rs`.

///|
pub const ATMOSPHERE_PLUGIN_ID : String = "bevy_pbr::AtmospherePlugin"

///|
pub fn atmosphere_plugin_id() -> String {
  ATMOSPHERE_PLUGIN_ID
}

///|
pub fn atmosphere_runtime_available() -> Bool {
  true
}

///|
pub struct AtmospherePlugin {
  enabled : Bool
}

///|
pub fn AtmospherePlugin::default() -> AtmospherePlugin {
  AtmospherePlugin::{ enabled: atmosphere_runtime_available() }
}

///|
pub fn atmosphere_plugin() -> AtmospherePlugin {
  AtmospherePlugin::default()
}
