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
/// Default plugin bundle, aligned with Bevy's `DefaultPlugins` concept.
///
/// Implementation lives in `Milky2018/mgstudio/internal` (similar to Bevy's
/// `bevy_internal`) and is forwarded here for a stable user-facing API.
pub fn[W : @internal.DefaultPluginsWorld] default_plugins() -> Array[
  @app.Plugin[W],
] {
  @internal.default_plugins()
}

///|
/// Default plugin bundle with "nearest" sampling for textures (useful for pixel art).
pub fn[W : @internal.DefaultPluginsWorld] default_plugins_nearest() -> Array[
  @app.Plugin[W],
] {
  @internal.default_plugins_nearest()
}
