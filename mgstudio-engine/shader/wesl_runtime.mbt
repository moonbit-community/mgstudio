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
pub(all) struct ShaderRuntimeCache {
  cache : ShaderCache[String, Unit]
}

///|
fn shader_runtime_load_module(
  _device : Unit,
  source : ShaderCacheSource,
  _validate : ValidateShader,
) -> String raise ShaderCacheError {
  match source {
    Wgsl(text) => text
    SpirV(_) =>
      raise ShaderCacheError::CreateShaderModule(
        "runtime wesl registration does not support spirv modules",
      )
  }
}

///|
fn ShaderRuntimeCache::ShaderRuntimeCache() -> ShaderRuntimeCache {
  { cache: ShaderCache::new((), shader_runtime_load_module) }
}

///|
let shader_runtime_cache_resource_key : @ecs.ResourceKey[ShaderRuntimeCache] = @ecs.register_resource(
  debug_name="mgstudio_shader::ShaderRuntimeCache",
)

///|
pub impl @app.Resource for ShaderRuntimeCache with fn resource() {
  shader_runtime_cache_resource_key
}

///|
pub fn shader_path_is_wesl(path : String) -> Bool {
  path.trim().to_owned().has_suffix(".wesl")
}

///|
fn shader_asset_server_or_abort(world : @ecs.World) -> @asset.AssetServer {
  match world.get_resource(@asset.AssetServer::resource()) {
    Some(asset_server) => asset_server
    None =>
      abort(
        "AssetServer resource is missing; DefaultPlugins/AssetPlugin/ShaderPlugin must be initialized before loading shader assets",
      )
  }
}

///|
fn shader_runtime_cache_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[ShaderRuntimeCache] {
  match world.get_resource_mut(ShaderRuntimeCache::resource()) {
    Some(cache) => cache
    None =>
      abort(
        "ShaderRuntimeCache resource is missing; ShaderPlugin must initialize it before WESL compilation",
      )
  }
}

///|
fn shader_assets_or_abort(world : @ecs.World) -> @asset.Assets[Shader] {
  let key : @ecs.ResourceKey[@asset.Assets[Shader]] = @asset.assets_resource_key()
  match world.get_resource(key) {
    Some(assets) => assets
    None =>
      abort(
        "Assets<Shader> resource is missing; ShaderPlugin must initialize shader assets before WESL compilation",
      )
  }
}

///|
fn shader_asset_paths_or_abort(world : @ecs.World) -> ShaderAssetPaths {
  match world.get_resource(ShaderAssetPaths::resource()) {
    Some(paths) => paths
    None =>
      abort(
        "ShaderAssetPaths resource is missing; ShaderPlugin must initialize shader path tracking before WESL compilation",
      )
  }
}

///|
fn shader_runtime_cache_sync_loaded_assets(world : @ecs.World) -> Unit {
  let shader_assets = shader_assets_or_abort(world)
  let loaded_shaders = shader_assets.iter()
  for entry in loaded_shaders {
    let handle = entry.0
    let shader = entry.1
    if shader.path != "" {
      shader_record_asset_path(world, shader.path, handle)
    }
  }
  let shader_paths = shader_asset_paths_or_abort(world)
  let cache = shader_runtime_cache_mut_or_abort(world)
  for entry in loaded_shaders {
    let handle = entry.0
    let shader = entry.1
    if cache.peek().cache.contains_shader(handle.asset_id()) {
      continue
    }
    ignore(
      cache.modify(fn(value) {
        value.cache.set_shader(handle.asset_id(), shader)
      }),
    )
  }
  for entry in shader_paths.entries {
    let handle = entry.1
    if cache.peek().cache.contains_shader(handle.asset_id()) {
      continue
    }
    match shader_assets.get(handle) {
      Some(shader) =>
        ignore(
          cache.modify(fn(value) {
            value.cache.set_shader(handle.asset_id(), shader)
          }),
        )
      None => ()
    }
  }
}

///|
pub fn shader_runtime_loaded_wgsl_sources(
  world : @ecs.World,
) -> Array[(String, String)] {
  let shader_assets = shader_assets_or_abort(world)
  let shader_paths = shader_asset_paths_or_abort(world)
  let sources : Array[(String, String)] = []
  for entry in shader_paths.entries {
    let canonical_path = entry.0
    let handle = entry.1
    match shader_assets.get(handle) {
      Some(shader) =>
        match shader.source {
          Source::Wgsl(source) => sources.push((canonical_path, source))
          _ => ()
        }
      None => ()
    }
  }
  sources
}

///|
fn shader_runtime_push_wgsl_source_closure(
  shader_assets : @asset.Assets[Shader],
  handle : @asset.Handle[Shader],
  fallback_path : String,
  visited : @hashset.HashSet[Int],
  sources : Array[(String, String)],
) -> Unit {
  let handle_id = handle.id()
  if visited.contains(handle_id) {
    return
  }
  visited.add(handle_id)
  guard shader_assets.get(handle) is Some(shader) else { return }
  let source_path = if shader.path == "" { fallback_path } else { shader.path }
  match shader.source {
    Source::Wgsl(source) =>
      sources.push((@asset.asset_canonical_path(source_path), source))
    _ => ()
  }
  for dependency in shader.file_dependencies {
    shader_runtime_push_wgsl_source_closure(
      shader_assets, dependency, "", visited, sources,
    )
  }
}

///|
fn shader_record_asset_and_dependencies(
  world : @ecs.World,
  path : String,
  handle : @asset.Handle[Shader],
  shader : Shader,
  shader_assets : @asset.Assets[Shader],
) -> Unit {
  shader_record_asset_path(world, path, handle)
  let mut dependency_index = 0
  for import_path in shader.imports {
    match import_path {
      AssetPath(asset_path) => {
        if dependency_index < shader.file_dependencies.length() {
          let dependency_handle = shader.file_dependencies[dependency_index]
          if shader_assets.get(dependency_handle) is Some(_) {
            shader_record_asset_path(world, asset_path, dependency_handle)
          }
        }
        dependency_index = dependency_index + 1
      }
      Custom(_) => ()
    }
  }
}

///|
pub fn shader_runtime_load_wgsl_sources(
  world : @ecs.World,
  path : String,
) -> Array[(String, String)] {
  if shader_path_is_wesl(path) {
    abort(
      "shader_runtime_load_wgsl_sources only supports .wgsl assets: \{path}",
    )
  }
  let handle : @asset.Handle[Shader] = @asset.asset_with_world(world, fn() {
    let asset_server = shader_asset_server_or_abort(world)
    asset_server.load(path)
  })
  let shader_assets = shader_assets_or_abort(world)
  let shader = match shader_assets.get(handle) {
    Some(shader) => {
      shader_record_asset_and_dependencies(
        world, path, handle, shader, shader_assets,
      )
      shader
    }
    None => {
      @app.log_warn(
        "shader runtime registration deferred because asset is unavailable: \{path}",
      )
      return []
    }
  }
  match shader.source {
    Source::Wgsl(_) => {
      shader_runtime_cache_sync_loaded_assets(world)
      let sources : Array[(String, String)] = []
      shader_runtime_push_wgsl_source_closure(
        shader_assets,
        handle,
        path,
        @hashset.HashSet([]),
        sources,
      )
      sources
    }
    Source::Wesl(_) =>
      abort("shader_runtime_load_wgsl_sources received a WESL asset: \{path}")
    Source::Glsl(_, _) =>
      abort(
        "shader_runtime_load_wgsl_sources only supports WGSL assets: \{path}",
      )
    Source::SpirV(_) =>
      abort(
        "shader_runtime_load_wgsl_sources only supports WGSL assets: \{path}",
      )
  }
}

///|
pub fn shader_runtime_compile_wesl_source(
  world : @ecs.World,
  path : String,
  shader_defs : Array[ShaderDefVal],
) -> String? raise ShaderCacheError {
  if !shader_path_is_wesl(path) {
    return None
  }
  let handle : @asset.Handle[Shader] = @asset.asset_with_world(world, fn() {
    let asset_server = shader_asset_server_or_abort(world)
    asset_server.load(path)
  })
  let assets_key : @ecs.ResourceKey[@asset.Assets[Shader]] = @asset.assets_resource_key()
  if world.get_resource(assets_key) is Some(shader_assets) {
    if shader_assets.get(handle) is Some(shader) {
      shader_record_asset_and_dependencies(
        world, path, handle, shader, shader_assets,
      )
    }
  }
  shader_runtime_cache_sync_loaded_assets(world)
  let cache = shader_runtime_cache_mut_or_abort(world)
  if !cache.peek().cache.contains_shader(handle.asset_id()) {
    @app.log_warn(
      "WESL shader runtime registration deferred because asset is unavailable: \{path}",
    )
    return None
  }
  Some(cache.peek().cache.get(0, handle.asset_id(), shader_defs)) catch {
    ShaderImportNotYetAvailable => None
    err => raise err
  }
}

///|
pub fn shader_runtime_compile_source(
  world : @ecs.World,
  path : String,
  shader_defs : Array[ShaderDefVal],
) -> String? raise ShaderCacheError {
  if shader_path_is_wesl(path) {
    return shader_runtime_compile_wesl_source(world, path, shader_defs)
  }
  let sources = shader_runtime_load_wgsl_sources(world, path)
  for source in sources {
    if source.0 == @asset.asset_canonical_path(path) {
      return Some(source.1)
    }
  }
  None
}
