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
// Bevy source: `bevy/crates/bevy_feathers/src/cursor.rs`.

///|
pub(all) enum EntityCursor {
  System(String)
  Hidden
} derive(Eq, Debug)

///|
pub struct DefaultCursor {
  cursor : EntityCursor
}

///|
pub struct OverrideCursor {
  cursor : EntityCursor?
}

///|
pub fn DefaultCursor::default() -> DefaultCursor {
  DefaultCursor::{ cursor: System("default") }
}

///|
pub fn OverrideCursor::default() -> OverrideCursor {
  OverrideCursor::{ cursor: None }
}

///|
pub struct CursorIconPlugin {}

///|
pub fn CursorIconPlugin::default() -> CursorIconPlugin {
  CursorIconPlugin::{  }
}

///|
pub fn cursor_icon_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
