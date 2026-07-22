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
extend Text with @asset.Asset::{asset_debug_name}

///|
struct Text {
  value : String
}

///|
impl @asset.Asset for Text with fn asset_debug_name() {
  "examples.asset.processing.asset_processing.Text"
}

///|
impl @asset.Asset for Text with fn asset_as_image(_self) {
  None
}

///|
let text_asset_resource_keys : @asset.AssetResourceKeys[Text] = @asset.register_asset_resource_keys(
  Text::asset_debug_name(),
)

///|
impl @asset.Asset for Text with fn asset_resource_keys() {
  text_asset_resource_keys
}

///|
fn Text::new(value : String) -> Text {
  Text::{ value, }
}

///|
struct CoolTextSource {
  text : String
  embedded_dependencies : Array[String]
  dependencies_with_overrides : Array[(String, String)]
}

///|
struct TextAssets {
  a : @asset.Handle[Text]
  b : @asset.Handle[Text]
  c : @asset.Handle[Text]
  d : @asset.Handle[Text]
  e : @asset.Handle[Text]
}

///|
let text_assets_key : @ecs.ResourceKey[TextAssets] = @ecs.register_resource(
  debug_name="examples.asset.processing.asset_processing.TextAssets",
)

///|
pub impl @app.Resource for TextAssets with fn resource() {
  text_assets_key
}

///|
fn cool_text_source(path : String) -> CoolTextSource {
  match path {
    "a" =>
      CoolTextSource::{
        text: "a",
        embedded_dependencies: [],
        dependencies_with_overrides: [],
      }
    "b" =>
      CoolTextSource::{
        text: "b",
        embedded_dependencies: [],
        dependencies_with_overrides: [],
      }
    "c" =>
      CoolTextSource::{
        text: "c",
        embedded_dependencies: ["a", "b"],
        dependencies_with_overrides: [],
      }
    "d" =>
      CoolTextSource::{
        text: "d",
        embedded_dependencies: ["c", "e"],
        dependencies_with_overrides: [("e", "E")],
      }
    "e" =>
      CoolTextSource::{
        text: "e",
        embedded_dependencies: [],
        dependencies_with_overrides: [],
      }
    _ =>
      CoolTextSource::{
        text: "",
        embedded_dependencies: [],
        dependencies_with_overrides: [],
      }
  }
}

///|
fn processed_cool_text_value(path : String) -> String {
  let source = cool_text_source(path)
  let mut value = source.text
  for dependency in source.embedded_dependencies {
    value = value + processed_cool_text_value(dependency)
  }
  for entry in source.dependencies_with_overrides {
    ignore(entry.0)
    value = value + entry.1
  }
  if path == "a" {
    value + "X"
  } else {
    value
  }
}

///|
struct TextPlugin {}

///|
fn TextPlugin::TextPlugin() -> TextPlugin {
  TextPlugin::{  }
}

///|
impl @app.Plugin for TextPlugin with fn name(_self) {
  "examples.asset.processing.asset_processing.TextPlugin"
}

///|
impl @app.Plugin for TextPlugin with fn build(_self, app) {
  @asset.init_asset(app, fn() { Text::new("") })
}

///|
fn text_asset_debug(text : Text?) -> String {
  match text {
    Some(text) => "Some(Text(\"\{text.value}\"))"
    None => "None"
  }
}

///|
fn setup(
  commands : @app.Commands,
  texts : @app.ResMut[@asset.Assets[Text]],
) -> Unit {
  commands.insert_resource(
    texts.modify(fn(text_assets) {
      TextAssets::{
        a: text_assets.add(Text::new(processed_cool_text_value("a"))),
        b: text_assets.add(Text::new(processed_cool_text_value("b"))),
        c: text_assets.add(Text::new(processed_cool_text_value("c"))),
        d: text_assets.add(Text::new(processed_cool_text_value("d"))),
        e: text_assets.add(Text::new(processed_cool_text_value("e"))),
      }
    }),
  )
}

///|
fn print_text(
  handles : @app.Res[TextAssets],
  texts : @app.Res[@asset.Assets[Text]],
  asset_events : @ecs.MessageReader[@asset.AssetEvent[Text]],
) -> Unit {
  if asset_events.is_empty() {
    return
  }
  println("Current Values:")
  println("  a: \{text_asset_debug(texts.get().get(handles.get().a))}")
  println("  b: \{text_asset_debug(texts.get().get(handles.get().b))}")
  println("  c: \{text_asset_debug(texts.get().get(handles.get().c))}")
  println("  d: \{text_asset_debug(texts.get().get(handles.get().d))}")
  println("  e: \{text_asset_debug(texts.get().get(handles.get().e))}")
  println(
    "(Cool text assets are typed MoonBit expressions embedded in source.)",
  )
  println("")
  asset_events.clear()
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(TextPlugin::TextPlugin())
  .add_systems_param2(@app.Startup, setup)
  .add_systems_param3(@app.Update, print_text)
  .run()
}
