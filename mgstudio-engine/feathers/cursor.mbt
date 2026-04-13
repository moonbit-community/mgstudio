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
let default_cursor_resource_key : @ecs.ResourceKey[DefaultCursor] = @ecs.register_resource(
  debug_name="mgstudio.feathers.default_cursor",
)

///|
pub struct OverrideCursor {
  cursor : EntityCursor?
}

///|
pub fn DefaultCursor::default() -> DefaultCursor {
  DefaultCursor::{ cursor: System("default") }
}

///|
pub impl @app.Resource for DefaultCursor with resource() {
  default_cursor_resource_key
}

///|
pub fn OverrideCursor::default() -> OverrideCursor {
  OverrideCursor::{ cursor: None }
}

///|
pub struct CursorIconPlugin {}

///|
pub(all) struct CursorIconPluginMarker {}

///|
let cursor_icon_plugin_marker_key : @ecs.ResourceKey[CursorIconPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio.feathers.cursor_icon.plugin_marker",
)

///|
pub fn CursorIconPlugin::default() -> CursorIconPlugin {
  CursorIconPlugin::{  }
}

///|
pub fn cursor_icon_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(cursor_icon_plugin_marker_key) {
    app
  } else {
    app
    .world()
    .insert_resource(cursor_icon_plugin_marker_key, CursorIconPluginMarker::{  })
    app.init_resource(fn() { DefaultCursor::default() })
  }
}
