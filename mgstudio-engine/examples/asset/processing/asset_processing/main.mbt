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
const SOURCE_ASSET_PATH : String = "examples/asset/processing/assets"

///|
const PROCESSED_ASSET_PATH : String = "examples/asset/processing/imported_assets/Default"

///|
const EMBEDDED_TEXT_ASSET_PATH : String = "embedded://asset_processing/e.txt"

///|
struct Text {
  value : String
}

///|
fn Text::new(value : String) -> Text {
  Text::{ value, }
}

///|
struct TextSettings {
  text_override : String?
}

///|
fn TextSettings::default() -> TextSettings {
  TextSettings::{ text_override: None }
}

///|
struct CoolText {
  text : String
  dependencies : Array[@asset.Handle[Text]]
}

///|
struct CoolTextSource {
  text : String
  dependencies : Array[String]
  embedded_dependencies : Array[String]
  dependencies_with_settings : Array[(String, TextSettings)]
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
pub impl @app.Resource for TextAssets with resource() {
  text_assets_key
}

///|
fn bytes_to_text(bytes : Bytes) -> String {
  @utf8.decode_lossy(bytes[:], ignore_bom=true)
}

///|
fn text_to_bytes(text : String) -> Bytes {
  @utf8.encode(text[:])
}

///|
fn is_whitespace(code : Int) -> Bool {
  code == 32 || code == 9 || code == 10 || code == 13
}

///|
fn skip_whitespace(content : String, start : Int) -> Int {
  let mut index = start
  while index < content.length() &&
        is_whitespace(content.code_unit_at(index).to_int()) {
    index = index + 1
  }
  index
}

///|
fn find_substring(content : String, pattern : String, start : Int) -> Int {
  if pattern.length() == 0 {
    return start
  }
  let end = content.length() - pattern.length()
  if end < start {
    return -1
  }
  for i in start..<=end {
    let mut matched = true
    for j in 0..<pattern.length() {
      if content.code_unit_at(i + j) != pattern.code_unit_at(j) {
        matched = false
        break
      }
    }
    if matched {
      return i
    }
  }
  -1
}

///|
fn read_balanced_block(
  content : String,
  start : Int,
  open_code : Int,
  close_code : Int,
) -> (String, Int)? {
  if start >= content.length() ||
    content.code_unit_at(start).to_int() != open_code {
    return None
  }
  let mut index = start
  let mut depth = 0
  let mut in_string = false
  while index < content.length() {
    let code = content.code_unit_at(index).to_int()
    if in_string {
      if code == 92 { // '\'
        index = index + 2
        continue
      }
      if code == 34 {
        in_string = false
      }
      index = index + 1
      continue
    }
    if code == 34 {
      in_string = true
      index = index + 1
      continue
    }
    if code == open_code {
      depth = depth + 1
    } else if code == close_code {
      depth = depth - 1
      if depth == 0 {
        return Some((content[start + 1:index].to_string(), index + 1))
      }
    }
    index = index + 1
  }
  None
}

///|
fn read_quoted_string(content : String, start : Int) -> (String, Int)? {
  if start >= content.length() || content.code_unit_at(start).to_int() != 34 {
    return None
  }
  let chars : Array[Char] = []
  let mut index = start + 1
  while index < content.length() {
    let code = content.code_unit_at(index).to_int()
    if code == 92 && index + 1 < content.length() {
      let escaped = content.code_unit_at(index + 1).to_int()
      let next_char = match escaped {
        34 => '"'
        92 => '\\'
        110 => '\n'
        114 => '\r'
        116 => '\t'
        _ => Int::unsafe_to_char(escaped)
      }
      chars.push(next_char)
      index = index + 2
      continue
    }
    if code == 34 {
      return Some((String::from_array(chars), index + 1))
    }
    chars.push(Int::unsafe_to_char(code))
    index = index + 1
  }
  None
}

///|
fn field_marker(field_name : String) -> String {
  "\{field_name}:"
}

///|
fn field_index(content : String, field_name : String) -> Int {
  find_substring(content, field_marker(field_name), 0)
}

///|
fn string_field(content : String, field_name : String) -> String {
  let marker_index = field_index(content, field_name)
  if marker_index < 0 {
    return ""
  }
  let string_index = find_substring(content, "\"", marker_index)
  if string_index < 0 {
    return ""
  }
  match read_quoted_string(content, string_index) {
    Some((value, _)) => value
    None => ""
  }
}

///|
fn array_field_block(content : String, field_name : String) -> String {
  let marker_index = field_index(content, field_name)
  if marker_index < 0 {
    return ""
  }
  let array_index = find_substring(content, "[", marker_index)
  if array_index < 0 {
    return ""
  }
  match read_balanced_block(content, array_index, 91, 93) {
    Some((block, _)) => block
    None => ""
  }
}

///|
fn parse_string_array(block : String) -> Array[String] {
  let out : Array[String] = []
  let mut index = 0
  while index < block.length() {
    let string_index = find_substring(block, "\"", index)
    if string_index < 0 {
      break
    }
    match read_quoted_string(block, string_index) {
      Some((value, next_index)) => {
        out.push(value)
        index = next_index
      }
      None => break
    }
  }
  out
}

///|
fn parse_dependencies_with_settings(
  block : String,
) -> Array[(String, TextSettings)] {
  let out : Array[(String, TextSettings)] = []
  let mut index = 0
  while index < block.length() {
    let open_index = find_substring(block, "(", index)
    if open_index < 0 {
      break
    }
    match read_balanced_block(block, open_index, 40, 41) {
      Some((tuple_block, next_index)) => {
        let path_string = match
          read_quoted_string(tuple_block, skip_whitespace(tuple_block, 0)) {
          Some((value, _)) => value
          None => ""
        }
        let override_value = if field_index(tuple_block, "text_override") >= 0 {
          let some_index = find_substring(tuple_block, "Some(", 0)
          if some_index >= 0 {
            let string_index = find_substring(tuple_block, "\"", some_index)
            if string_index >= 0 {
              match read_quoted_string(tuple_block, string_index) {
                Some((value, _)) => Some(value)
                None => None
              }
            } else {
              None
            }
          } else {
            None
          }
        } else {
          None
        }
        out.push((path_string, TextSettings::{ text_override: override_value }))
        index = next_index
      }
      None => break
    }
  }
  out
}

///|
fn parse_cool_text_source(content : String) -> CoolTextSource {
  CoolTextSource::{
    text: string_field(content, "text"),
    dependencies: parse_string_array(array_field_block(content, "dependencies")),
    embedded_dependencies: parse_string_array(
      array_field_block(content, "embedded_dependencies"),
    ),
    dependencies_with_settings: parse_dependencies_with_settings(
      array_field_block(content, "dependencies_with_settings"),
    ),
  }
}

///|
fn load_text_asset(
  _asset_server : @asset.AssetServer,
  _path : @asset.AssetPath,
  bytes : Bytes,
) -> Text {
  Text::new(bytes_to_text(bytes))
}

///|
fn load_text_with_settings(bytes : Bytes, settings : TextSettings) -> Text {
  match settings.text_override {
    Some(text_override) => Text::new(text_override)
    None => Text::new(bytes_to_text(bytes))
  }
}

///|
fn transformer_appended_suffix(path : @asset.AssetPath) -> String {
  match
    @asset.load_optional_asset_source_text(
      @asset.AssetPath::from_path("\{@asset.asset_format_path(path)}.meta"),
    ) {
    Some(meta) => string_field(meta, "appended")
    None => ""
  }
}

///|
fn processed_text_from_path(
  asset_server : @asset.AssetServer,
  path : String,
  settings : TextSettings,
) -> Text {
  if path.length() >= 4 &&
    path[path.length() - 4:path.length()].to_string() == ".txt" {
    return load_text_with_settings(
      @asset.load_asset_source_bytes(path),
      settings,
    )
  }
  if path.length() >= 9 &&
    path[path.length() - 9:path.length()].to_string() == ".cool.ron" {
    let asset_path = @asset.asset_parse_path(path)
    let bytes = @asset.load_asset_source_bytes(asset_path)
    let processed = process_cool_text(asset_server, asset_path, bytes) catch {
      err =>
        abort("Failed to process dependent cool text asset: \{err.message()}")
    }
    let text = processed.asset()
    match settings.text_override {
      Some(text_override) => Text::new(text_override)
      None => text
    }
  } else {
    abort("Unsupported processed text dependency path \{path}")
  }
}

///|
fn load_cool_text_asset(
  asset_server : @asset.AssetServer,
  path : @asset.AssetPath,
  bytes : Bytes,
) -> CoolText {
  let parsed = parse_cool_text_source(bytes_to_text(bytes))
  let dependencies : Array[@asset.Handle[Text]] = []
  for dependency_path in parsed.dependencies {
    dependencies.push(asset_server.load(dependency_path))
  }
  let base_text = Ref::new(parsed.text)
  for embedded in parsed.embedded_dependencies {
    base_text.val = base_text.val +
      processed_text_from_path(asset_server, embedded, TextSettings::default()).value
  }
  for entry in parsed.dependencies_with_settings {
    base_text.val = base_text.val +
      processed_text_from_path(asset_server, entry.0, entry.1).value
  }
  ignore(path)
  CoolText::{ text: base_text.val, dependencies }
}

///|
fn process_cool_text(
  asset_server : @asset.AssetServer,
  path : @asset.AssetPath,
  bytes : Bytes,
) -> @asset.ProcessedAsset[Text] raise @asset.AssetProcessError {
  if @asset.asset_format_path(path).trim() == "" {
    raise @asset.AssetProcessError::Message(
      "cool text processor received an empty asset path",
    )
  }
  let cool_text = load_cool_text_asset(asset_server, path, bytes)
  ignore(cool_text.dependencies.length())
  let final_value = cool_text.text + transformer_appended_suffix(path)
  @asset.ProcessedAsset::new(Text::new(final_value)).with_saved_bytes(
    text_to_bytes(final_value),
  )
}

///|
fn text_loader() -> @asset.AssetLoader[Text] {
  @asset.AssetLoader::new(["txt"], load_text_asset)
}

///|
fn cool_text_loader() -> @asset.AssetLoader[CoolText] {
  @asset.AssetLoader::new(["cool.ron"], load_cool_text_asset)
}

///|
struct CoolTextSaver {}

///|
fn cool_text_processor() -> @asset.LoadTransformAndSave[Text] {
  CoolTextSaver::{  } |> ignore
  @asset.LoadTransformAndSave::new(["cool.ron"], process_cool_text)
}

///|
fn text_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let processor : @asset.LoadTransformAndSave[Text] = cool_text_processor()
  @asset.set_default_asset_processor(
    @asset.register_asset_processor(
      @asset.init_asset_processor(
        @asset.init_asset_loader(
          @asset.init_asset_loader(
            @asset.init_asset(
              @asset.init_asset(
                @asset.embedded_asset(
                  app,
                  @asset.asset_parse_path(EMBEDDED_TEXT_ASSET_PATH),
                  "examples/asset/processing/e.txt",
                ),
                fn() { CoolText::{ text: "", dependencies: [] } },
              ),
              fn() { Text::new("") },
            ),
            text_loader(),
          ),
          cool_text_loader(),
        ),
        processor,
      ),
      processor,
    ),
    "cool.ron",
  )
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
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  commands.insert_resource(TextAssets::{
    a: asset_server.get().load("a.cool.ron"),
    b: asset_server.get().load("foo/b.cool.ron"),
    c: asset_server.get().load("foo/c.cool.ron"),
    d: asset_server.get().load("d.cool.ron"),
    e: asset_server
    .get()
    .load(@asset.asset_parse_path(EMBEDDED_TEXT_ASSET_PATH)),
  })
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
    "(You can modify source assets and their .meta files to hot-reload changes!)",
  )
  println("")
  asset_events.clear()
}

///|
fn main {
  let asset_plugin = @asset.AssetPlugin::{
    ..@asset.AssetPlugin::default(),
    mode: @asset.AssetMode::Processed,
    file_path: Some(SOURCE_ASSET_PATH),
    processed_file_path: Some(PROCESSED_ASSET_PATH),
  }

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::set(asset_plugin).build())
  .add_plugins([text_plugin])
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(print_text)))
  .run()
}
