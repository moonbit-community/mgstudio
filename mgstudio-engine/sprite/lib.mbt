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
// Bevy source: `bevy/crates/bevy_sprite/src/lib.rs`.
// Package-level plugin boundary aligned with Bevy crate responsibilities.
pub const SPRITE_PLUGIN_ID : String = "bevy_sprite::SpritePlugin"

///|
/// Keep an explicit sprite plugin boundary so default plugins can mirror
/// Bevy's `SpritePlugin` + `SpriteRenderPlugin` layering.
pub fn sprite_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}

///|
pub fn sprite_plugin_boundary_id() -> String {
  SPRITE_PLUGIN_ID
}
