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
// Bevy source: `bevy/crates/bevy_anti_alias/src/smaa/mod.rs`.

///|
pub const SMAA_RUNTIME_SUPPORTED : Bool = false

///|
pub struct SmaaPlugin {}

///|
pub fn SmaaPlugin::default() -> SmaaPlugin {
  SmaaPlugin::{  }
}

///|
pub(all) enum SmaaPreset {
  Low
  Medium
  High
  Ultra
} derive(Eq, Debug)

///|
pub fn SmaaPreset::default() -> SmaaPreset {
  High
}

///|
pub struct Smaa {
  preset : SmaaPreset
} derive(Eq, Debug)

///|
pub fn Smaa::default() -> Smaa {
  Smaa::{ preset: SmaaPreset::default() }
}

///|
let ecs_key_smaa : @ecs.ComponentKey[Smaa] = @ecs.register_component(
  debug_name="mgstudio_anti_alias::Smaa",
)

///|
pub impl @ecs.Component for Smaa with component() {
  ecs_key_smaa
}

///|
pub fn smaa_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
