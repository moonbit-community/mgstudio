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
/// This lives in the top-level `Milky2018/mgstudio` package to avoid dependency
/// cycles (`app` cannot depend on `window/asset/render2d/...`).
pub fn[W] default_plugins() -> Array[@app.Plugin[W]] {
  [
    fn(app : @app.App[W]) -> @app.App[W] { @window.window_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @time.time_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @asset.asset_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @render2d.render2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @text.text_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @input.input_plugin(app) },
  ]
}

///|
/// Default plugin bundle with "nearest" sampling for textures (useful for pixel art).
pub fn[W] default_plugins_nearest() -> Array[@app.Plugin[W]] {
  [
    fn(app : @app.App[W]) -> @app.App[W] { @window.window_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @time.time_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @asset.asset_plugin_nearest(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @render2d.render2d_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @text.text_plugin(app) },
    fn(app : @app.App[W]) -> @app.App[W] { @input.input_plugin(app) },
  ]
}
