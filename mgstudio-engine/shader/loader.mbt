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
pub struct ShaderLoader {}

///|
pub fn ShaderLoader::ShaderLoader() -> ShaderLoader {
  ShaderLoader::{  }
}

///|
pub(all) suberror ShaderLoaderError {
  Io(String)
  Parse(String)
}

///|
pub fn ShaderLoaderError::message(self : ShaderLoaderError) -> String {
  match self {
    Io(reason) => "Could not load shader: \{reason}"
    Parse(reason) => "Could not parse shader: \{reason}"
  }
}

///|
struct ShaderAssetPaths {
  entries : Array[(String, @asset.Handle[Shader])]
}

///|
fn ShaderAssetPaths::ShaderAssetPaths() -> ShaderAssetPaths {
  { entries: [] }
}

///|
fn ShaderAssetPaths::find(
  self : ShaderAssetPaths,
  canonical_path : String,
) -> @asset.Handle[Shader]? {
  for entry in self.entries {
    if entry.0 == canonical_path {
      return Some(entry.1)
    }
  }
  None
}

///|
fn ShaderAssetPaths::insert(
  self : ShaderAssetPaths,
  canonical_path : String,
  handle : @asset.Handle[Shader],
) -> Unit {
  for i in 0..<self.entries.length() {
    if self.entries[i].0 == canonical_path {
      self.entries[i] = (canonical_path, handle)
      return
    }
  }
  self.entries.push((canonical_path, handle))
}

///|
let shader_asset_paths_resource_key : @ecs.ResourceKey[ShaderAssetPaths] = @ecs.register_resource(
  debug_name="mgstudio_shader::ShaderAssetPaths",
)

///|
pub impl @app.Resource for ShaderAssetPaths with fn resource() {
  shader_asset_paths_resource_key
}

///|
priv struct ShaderPluginMarker {}

///|
let shader_plugin_marker_key : @ecs.ResourceKey[ShaderPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_shader::ShaderPluginMarker",
)

///|
fn shader_asset_paths_mut_or_abort_in_world(
  world : @ecs.World,
) -> @ecs.ResourceMut[ShaderAssetPaths] {
  match world.get_resource_mut(ShaderAssetPaths::resource()) {
    Some(paths) => paths
    None =>
      abort(
        "ShaderAssetPaths resource is missing; ShaderPlugin must initialize shader path tracking before recording shader assets",
      )
  }
}

///|
fn shader_path_extension(path : String) -> String {
  let mut found = -1
  for i in 0..<path.length() {
    if path.code_unit_at(i).to_int() == 46 { // '.'
      found = i
    }
  }
  if found < 0 || found + 1 >= path.length() {
    return ""
  }
  path[found + 1:path.length()].to_owned()
}

///|
fn shader_bytes_read_text_or_error(
  bytes : Bytes,
  canonical_path : String,
) -> String raise ShaderLoaderError {
  bytes |> ignore
  let chars : Array[Char] = []
  for byte in bytes {
    let code = byte.to_int() & 0xFF
    if code.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  if chars.length() == 0 {
    raise ShaderLoaderError::Parse(
      "failed to decode shader text: \{canonical_path}",
    )
  }
  String::from_array(chars)
}

///|
fn shader_blob_read_bytes_or_error(
  blob : @asset.Handle[@asset.Blob],
  canonical_path : String,
) -> Bytes raise ShaderLoaderError {
  match @asset.asset_blob_read_bytes(blob) {
    Some(bytes) => bytes
    None =>
      raise ShaderLoaderError::Io(
        "failed to read shader bytes: \{canonical_path}",
      )
  }
}

///|
pub fn ShaderLoader::extensions(self : ShaderLoader) -> Array[String] {
  self |> ignore
  ["spv", "wgsl", "wesl", "vert", "frag", "comp"]
}

///|
pub fn ShaderLoader::load(
  self : ShaderLoader,
  asset_server : @asset.AssetServer,
  path : String,
  settings : ShaderSettings,
) -> Shader raise ShaderLoaderError {
  self |> ignore
  let canonical_path = @asset.asset_canonical_path(path)
  let blob = asset_server.load_bytes(canonical_path)
  self.load_from_bytes(
    asset_server,
    canonical_path,
    shader_blob_read_bytes_or_error(blob, canonical_path),
    settings,
  )
}

///|
pub fn ShaderLoader::load_from_bytes(
  self : ShaderLoader,
  asset_server : @asset.AssetServer,
  path : String,
  bytes : Bytes,
  settings : ShaderSettings,
) -> Shader raise ShaderLoaderError {
  self |> ignore
  let canonical_path = @asset.asset_canonical_path(path)
  let extension = shader_path_extension(canonical_path)
  if extension != "wgsl" && !settings.shader_defs.is_empty() {
    settings |> ignore
  }
  let shader = match extension {
    "spv" => Shader::from_spirv(bytes, canonical_path)
    "wgsl" =>
      Shader::from_wgsl_with_defs(
        shader_bytes_read_text_or_error(bytes, canonical_path),
        canonical_path,
        settings.shader_defs,
      )
    "wesl" =>
      Shader::from_wesl(
        shader_bytes_read_text_or_error(bytes, canonical_path),
        canonical_path,
      )
    "vert" =>
      Shader::from_glsl(
        shader_bytes_read_text_or_error(bytes, canonical_path),
        ShaderStage::Vertex,
        canonical_path,
      )
    "frag" =>
      Shader::from_glsl(
        shader_bytes_read_text_or_error(bytes, canonical_path),
        ShaderStage::Fragment,
        canonical_path,
      )
    "comp" =>
      Shader::from_glsl(
        shader_bytes_read_text_or_error(bytes, canonical_path),
        ShaderStage::Compute,
        canonical_path,
      )
    _ => abort("unhandled extension: \{extension}")
  }

  for import_path in shader.imports {
    match import_path {
      AssetPath(asset_path) =>
        shader.file_dependencies.push(asset_server.load(asset_path))
      Custom(_) => ()
    }
  }
  shader
}

///|
fn shader_load_typed(
  asset_server : @asset.AssetServer,
  path : @asset.AssetPath,
  bytes : Bytes,
) -> Shader {
  let canonical_path = @asset.asset_canonical_path(
    @asset.asset_format_path(path),
  )
  ShaderLoader::ShaderLoader().load_from_bytes(
    asset_server,
    canonical_path,
    bytes,
    ShaderSettings::ShaderSettings(),
  ) catch {
    error => abort(error.message())
  }
}

///|
pub fn shader_record_asset_path(
  world : @ecs.World,
  path : String,
  handle : @asset.Handle[Shader],
) -> Unit {
  let canonical_path = @asset.asset_canonical_path(path)
  let registry = shader_asset_paths_mut_or_abort_in_world(world)
  if registry.peek().find(canonical_path) is None {
    registry.modify(fn(value) { value.insert(canonical_path, handle) })
  }
}

///|
pub fn shader_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(shader_plugin_marker_key) {
    return app
  }
  @asset.init_asset_loader(
    @asset.init_asset(app, fn() { Shader::new("") }),
    @asset.AssetLoader::new(
      ShaderLoader::ShaderLoader().extensions(),
      shader_load_typed,
    ),
  )
  .insert_world_resource(shader_plugin_marker_key, ShaderPluginMarker::{  })
  .init_resource(fn() { ShaderAssetPaths::ShaderAssetPaths() })
  .init_resource(fn() { ShaderRuntimeCache::ShaderRuntimeCache() })
}
