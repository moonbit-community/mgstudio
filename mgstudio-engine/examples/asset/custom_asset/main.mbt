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
struct CustomAsset {
  value : Int
}

///|
struct Blob {
  bytes : Bytes
}

///|
struct State {
  mut handle : @asset.Handle[CustomAsset]
  mut other_handle : @asset.Handle[CustomAsset]
  mut blob : @asset.Handle[Blob]
  mut printed : Bool
}

///|
let state_key : @ecs.ResourceKey[State] = @ecs.register_resource(
  debug_name="examples.asset.custom_asset.State",
)

///|
pub impl @app.Resource for State with resource() {
  state_key
}

///|
fn State::default() -> State {
  State::{
    handle: @asset.Handle::new(-1),
    other_handle: @asset.Handle::new(-1),
    blob: @asset.Handle::new(-1),
    printed: false,
  }
}

///|
fn bytes_to_text(bytes : Bytes) -> String {
  let chars : Array[Char] = []
  for byte in bytes {
    chars.push(Int::unsafe_to_char(byte.to_int() & 0xFF))
  }
  String::from_array(chars)
}

///|
fn find_substring_or_abort(content : String, pattern : String) -> Int {
  guard pattern.length() > 0 else {
    abort("Expected a non-empty substring pattern")
  }
  let limit = content.length() - pattern.length()
  guard limit >= 0 else {
    abort("Custom asset payload is missing the expected value field")
  }
  for start in 0..<=limit {
    let mut matches = true
    for offset in 0..<pattern.length() {
      if content.code_unit_at(start + offset) != pattern.code_unit_at(offset) {
        matches = false
        break
      }
    }
    if matches {
      return start
    }
  }
  abort("Custom asset payload is missing the expected value field")
}

///|
fn parse_decimal_or_abort(digits : Array[Char]) -> Int {
  guard digits.length() > 0 else {
    abort("Custom asset payload did not contain a numeric value")
  }
  let mut index = 0
  let mut sign = 1
  if digits[0] == '-' {
    sign = -1
    index = 1
  }
  guard index < digits.length() else {
    abort("Custom asset payload did not contain a numeric value")
  }
  let mut value = 0
  for i in index..<digits.length() {
    let code = digits[i].to_int()
    guard code >= 48 && code <= 57 else {
      abort("Custom asset payload did not contain a numeric value")
    }
    value = value * 10 + (code - 48)
  }
  sign * value
}

///|
fn parse_int_after_label(content : String, label : String) -> Int {
  let start = find_substring_or_abort(content, label) + label.length()
  let digits : Array[Char] = []
  let mut seen_digit = false
  for i in start..<content.length() {
    let code = content.code_unit_at(i).to_int()
    let is_digit = code >= 48 && code <= 57
    if is_digit || (!seen_digit && code == 45) {
      digits.push(Int::unsafe_to_char(code))
      seen_digit = true
      continue
    }
    if seen_digit {
      break
    }
  }
  if digits.length() == 0 {
    abort("Custom asset payload did not contain a numeric value")
  }
  parse_decimal_or_abort(digits)
}

///|
fn load_custom_asset(
  _asset_server : @asset.AssetServer,
  _path : @asset.AssetPath,
  bytes : Bytes,
) -> CustomAsset {
  CustomAsset::{ value: parse_int_after_label(bytes_to_text(bytes), "value:") }
}

///|
fn load_blob_asset(
  _asset_server : @asset.AssetServer,
  _path : @asset.AssetPath,
  bytes : Bytes,
) -> Blob {
  Blob::{ bytes, }
}

///|
fn custom_asset_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @asset.init_asset_loader(
    @asset.init_asset_loader(
      app,
      @asset.AssetLoader::new(["custom"], load_custom_asset),
    ),
    @asset.AssetLoader::new([], load_blob_asset),
  )
}

///|
fn setup(
  state : @app.ResMut[State],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  state.modify(fn(value) {
    value.handle = asset_server.get().load("data/asset.custom")
    value.other_handle = asset_server.get().load("data/asset_no_extension")
    value.blob = asset_server.get().load("data/asset.custom")
  })
}

///|
fn print_on_load(
  state : @app.ResMut[State],
  custom_assets : @app.Res[@asset.Assets[CustomAsset]],
  blob_assets : @app.Res[@asset.Assets[Blob]],
) -> Unit {
  let current_state = state.peek()
  if current_state.printed {
    return
  }

  guard custom_assets.get().get(current_state.handle) is Some(custom_asset) else {
    println("Custom Asset Not Ready")
    return
  }
  guard custom_assets.get().get(current_state.other_handle)
    is Some(other_custom_asset) else {
    println("Other Custom Asset Not Ready")
    return
  }
  guard blob_assets.get().get(current_state.blob) is Some(blob) else {
    println("Blob Not Ready")
    return
  }

  println("Custom asset loaded: value=\{custom_asset.value}")
  println("Custom asset loaded: value=\{other_custom_asset.value}")
  println("Blob Size: \{blob.bytes.length()} Bytes")
  state.modify(fn(value) { value.printed = true })
}

///|
fn main {
  custom_asset_plugin(
    @app.App::new(@ecs.World::new()).add_plugins(
      @mgstudio.DefaultPlugins::default(),
    ),
  )
  .init_resource(fn() { State::default() })
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_on_load)))
  .run()
}
