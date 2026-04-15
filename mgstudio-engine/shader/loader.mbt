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
pub fn ShaderLoader::default() -> ShaderLoader {
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
fn ShaderAssetPaths::default() -> ShaderAssetPaths {
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
fn ShaderAssetPaths::remove(
  self : ShaderAssetPaths,
  canonical_path : String,
) -> Unit {
  let retained : Array[(String, @asset.Handle[Shader])] = []
  for entry in self.entries {
    if entry.0 != canonical_path {
      retained.push(entry)
    }
  }
  self.entries.clear()
  for entry in retained {
    self.entries.push(entry)
  }
}

///|
let shader_asset_paths_resource_key : @ecs.ResourceKey[ShaderAssetPaths] = @ecs.register_resource(
  debug_name="mgstudio_shader::ShaderAssetPaths",
)

///|
pub impl @app.Resource for ShaderAssetPaths with resource() {
  shader_asset_paths_resource_key
}

///|
fn shader_assets_ref_mut_or_abort() -> Ref[@asset.Assets[Shader]] {
  let assets_ref : Ref[@asset.Assets[Shader]] = @asset.asset_assets_ref_mut_or_abort()
  assets_ref
}

///|
fn shader_asset_paths_ref_mut_or_abort() -> Ref[ShaderAssetPaths] {
  let registry_ref : Ref[ShaderAssetPaths] = @asset.asset_resource_ref_mut_or_abort()
  registry_ref
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
  path[found + 1:path.length()].to_string()
}

///|
fn shader_blob_read_text_or_error(
  blob : @asset.Handle[@asset.Blob],
  canonical_path : String,
) -> String raise ShaderLoaderError {
  match @asset.asset_blob_read_text(blob) {
    Some(source) => source
    None =>
      raise ShaderLoaderError::Parse(
        "failed to decode shader text: \{canonical_path}",
      )
  }
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
  let extension = shader_path_extension(canonical_path)
  let blob = asset_server.load_bytes(canonical_path)
  if extension != "wgsl" && !settings.shader_defs.is_empty() {
    settings |> ignore
  }
  let shader = match extension {
    "spv" =>
      Shader::from_spirv(
        shader_blob_read_bytes_or_error(blob, canonical_path),
        canonical_path,
      )
    "wgsl" =>
      Shader::from_wgsl_with_defs(
        shader_blob_read_text_or_error(blob, canonical_path),
        canonical_path,
        settings.shader_defs,
      )
    "wesl" =>
      Shader::from_wesl(
        shader_blob_read_text_or_error(blob, canonical_path),
        canonical_path,
      )
    "vert" =>
      Shader::from_glsl(
        shader_blob_read_text_or_error(blob, canonical_path),
        ShaderStage::Vertex,
        canonical_path,
      )
    "frag" =>
      Shader::from_glsl(
        shader_blob_read_text_or_error(blob, canonical_path),
        ShaderStage::Fragment,
        canonical_path,
      )
    "comp" =>
      Shader::from_glsl(
        shader_blob_read_text_or_error(blob, canonical_path),
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
fn shader_load_registered(
  asset_server : @asset.AssetServer,
  path : String,
) -> @asset.Handle[Shader] {
  if @app.current_world() is None {
    abort(
      "AssetServer::load[Shader] requires an active app world; load the shader plugin and call it from a scheduled system",
    )
  }

  let canonical_path = @asset.asset_canonical_path(path)
  let registry_ref = shader_asset_paths_ref_mut_or_abort()
  match registry_ref.val.find(canonical_path) {
    Some(handle) => handle
    None => {
      let assets_ref = shader_assets_ref_mut_or_abort()
      let handle = assets_ref.val.reserve_handle()
      registry_ref.val.insert(canonical_path, handle)
      let shader = ShaderLoader::default().load(
        asset_server,
        canonical_path,
        ShaderSettings::default(),
      ) catch {
        error => {
          registry_ref.val.remove(canonical_path)
          abort(error.message())
        }
      }
      ignore(assets_ref.val.set(handle, shader))
      handle
    }
  }
}

///|
pub fn shader_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @asset.asset_register_loader(fn(asset_server, path) {
    shader_load_registered(asset_server, path)
  })
  app
  .init_resource(fn() {
    let assets : @asset.Assets[Shader] = @asset.Assets::new()
    assets
  })
  .init_resource(fn() { ShaderAssetPaths::default() })
  .init_resource(fn() { ShaderRuntimeCache::default() })
}
