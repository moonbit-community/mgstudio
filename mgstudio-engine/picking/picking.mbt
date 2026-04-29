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
/// Picking framework (UI + 2D sprite + 3D mesh).
///
/// The runtime implementation is split across `lib`, `pointer`, `input`,
/// `hover`, `backend`, `events`, and `window` following the Bevy file shape.

///|
pub fn picking_plugin_entry(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  picking_plugin(app)
}

///|
pub fn picking_pre_update_sets() -> (
  @app.SystemSet,
  @app.SystemSet,
  @app.SystemSet,
) {
  (picking_set_process_input, picking_set_backend, picking_set_hover)
}
