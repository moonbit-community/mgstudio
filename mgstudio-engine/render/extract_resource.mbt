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
// Bevy source: `bevy/crates/bevy_render/src/extract_resource.rs`.

///|
pub struct ExtractResourcePlugin[_, _] {}

///|
pub fn[R, F] ExtractResourcePlugin::default() -> ExtractResourcePlugin[R, F] {
  ExtractResourcePlugin::{  }
}

///|
pub struct ExtractedResourceState[R] {
  mut has_value : Bool
  mut value : R?
}

///|
pub fn[R] ExtractedResourceState::default() -> ExtractedResourceState[R] {
  ExtractedResourceState::{ has_value: false, value: None }
}

///|
pub fn[R] ExtractedResourceState::replace(
  self : ExtractedResourceState[R],
  value : R,
) -> Unit {
  self.has_value = true
  self.value = Some(value)
}

///|
pub fn[R] ExtractedResourceState::get(self : ExtractedResourceState[R]) -> R? {
  self.value
}

///|
pub fn[R, S] extract_resource_once(source : S, extract : (S) -> R) -> R {
  extract(source)
}

///|
pub fn extract_resource_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_plugin(app)
}

///|
pub fn extract_resource_source_world(world : @ecs.World) -> @ecs.World {
  render_source_world(world)
}
