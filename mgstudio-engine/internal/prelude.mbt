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
//
// Adapted from Bevy's `bevy_internal` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
/// MoonBit exports package-level public symbols directly, so the internal
/// prelude is represented by this file while the actual public items remain
/// available from the `internal` package namespace.
pub fn internal_prelude_plugin_groups() -> (
  Array[(@app.App[@ecs.World]) -> @app.App[@ecs.World]],
  Array[(@app.App[@ecs.World]) -> @app.App[@ecs.World]],
  Array[(@app.App[@ecs.World]) -> @app.App[@ecs.World]],
) {
  (default_plugins(), default_plugins_nearest(), minimal_plugins())
}
