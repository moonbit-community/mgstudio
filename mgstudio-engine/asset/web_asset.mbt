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
const WEB_ASSET_PLUGIN_NAME : String = "mgstudio.asset.io.web.WebAssetPlugin"

///|
pub(all) struct WebAssetPlugin {
  silence_startup_warning : Bool
}

///|
pub fn WebAssetPlugin::default() -> WebAssetPlugin {
  WebAssetPlugin::{ silence_startup_warning: false }
}

///|
pub fn WebAssetPlugin::with_silence_startup_warning(
  _self : WebAssetPlugin,
  enabled : Bool,
) -> WebAssetPlugin {
  WebAssetPlugin::{ silence_startup_warning: enabled }
}

///|
fn web_asset_reader(scheme : String) -> AssetReader {
  AssetReader::new(
    fn(path) { web_asset_fetch("\{scheme}://\{path}") },
    fn(_path) { None },
    fn(_path) { None },
    fn(_path) { false },
  )
}

///|
fn web_asset_source_builder(scheme : String) -> AssetSourceBuilder {
  AssetSourceBuilder::platform_default("", None).with_reader(fn(_base_reader) {
    web_asset_reader(scheme)
  })
}

///|
pub fn web_asset_plugin(plugin : WebAssetPlugin) -> @app.Plugin[@ecs.World] {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    if !plugin.silence_startup_warning {
      println(
        "WebAssetPlugin is potentially insecure. Only load trusted URLs, or silence this warning with silence_startup_warning: true.",
      )
    }
    register_asset_source(
      register_asset_source(
        app,
        AssetSourceId::Named("http"),
        web_asset_source_builder("http"),
      ),
      AssetSourceId::Named("https"),
      web_asset_source_builder("https"),
    )
  }
}

///|
pub impl @app.PluginReplacement for WebAssetPlugin with plugin_name(_self) {
  WEB_ASSET_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for WebAssetPlugin with world_plugin(self) {
  web_asset_plugin(self)
}
