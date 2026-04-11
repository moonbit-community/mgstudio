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
// Bevy source: `bevy/crates/bevy_anti_alias/src/fxaa/mod.rs`.

///|
pub type Fxaa = @post_process.Fxaa

///|
pub type FxaaSensitivity = @post_process.FxaaSensitivity

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @post_process.ecs_key_fxaa

///|
pub struct FxaaPlugin {}

///|
pub fn FxaaPlugin::default() -> FxaaPlugin {
  FxaaPlugin::{  }
}

///|
pub fn fxaa_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
