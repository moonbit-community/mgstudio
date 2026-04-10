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
// Bevy source: `bevy/crates/bevy_solari/src/pathtracer/mod.rs`.

///|
pub const PATHTRACING_PLUGIN_ID : String = "bevy_solari::pathtracer::PathtracingPlugin"

///|
pub struct PathtracingPlugin {}

///|
pub fn PathtracingPlugin::default() -> PathtracingPlugin {
  PathtracingPlugin::{  }
}

///|
pub struct Pathtracer {
  samples_per_pixel : Int
}

///|
pub fn Pathtracer::default() -> Pathtracer {
  Pathtracer::{ samples_per_pixel: 1 }
}

///|
pub fn pathtracing_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
