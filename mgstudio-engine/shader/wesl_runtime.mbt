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
fn ShaderRuntimeCache::default() -> ShaderRuntimeCache {
  { cache: ShaderCache::new((), shader_runtime_load_module) }
}

///|
let shader_runtime_cache_resource_key : @ecs.ResourceKey[ShaderRuntimeCache] = @ecs.register_resource(
  debug_name="mgstudio_shader::ShaderRuntimeCache",
)

///|
pub impl @app.Resource for ShaderRuntimeCache with resource() {
  shader_runtime_cache_resource_key
}

///|
pub fn shader_path_is_wesl(path : String) -> Bool {
  path.trim().to_string().has_suffix(".wesl")
}

///|
fn shader_asset_server_or_abort(world : @ecs.World) -> @asset.AssetServer {
  match (try! world.get_resource(@asset.AssetServer::resource())) {
    Some(asset_server) => asset_server
    None =>
      abort(
        "AssetServer resource is missing; DefaultPlugins/AssetPlugin/ShaderPlugin must be initialized before loading shader assets",
      )
  }
}

///|
fn shader_runtime_cache_ref_mut_or_abort(
  world : @ecs.World,
) -> Ref[ShaderRuntimeCache] {
  match (try! world.get_resource_ref_mut(ShaderRuntimeCache::resource())) {
    Some(cache_ref) => cache_ref
    None =>
      abort(
        "ShaderRuntimeCache resource is missing; ShaderPlugin must initialize it before WESL compilation",
      )
  }
}

///|
fn shader_assets_or_abort(world : @ecs.World) -> @asset.Assets[Shader] {
  let key : @ecs.ResourceKey[@asset.Assets[Shader]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) => assets
    None =>
      abort(
        "Assets<Shader> resource is missing; ShaderPlugin must initialize shader assets before WESL compilation",
      )
  }
}

///|
fn shader_asset_paths_or_abort(world : @ecs.World) -> ShaderAssetPaths {
  match (try! world.get_resource(ShaderAssetPaths::resource())) {
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
  let shader_paths = shader_asset_paths_or_abort(world)
  let cache_ref = shader_runtime_cache_ref_mut_or_abort(world)
  for entry in shader_paths.entries {
    let handle = entry.1
    if cache_ref.val.cache.contains_shader(handle.asset_id()) {
      continue
    }
    match shader_assets.get(handle) {
      Some(shader) =>
        ignore(cache_ref.val.cache.set_shader(handle.asset_id(), shader))
      None => ()
    }
  }
}

///|
fn shader_runtime_register_loaded_wgsl_sources(world : @ecs.World) -> Unit {
  let shader_assets = shader_assets_or_abort(world)
  let shader_paths = shader_asset_paths_or_abort(world)
  for entry in shader_paths.entries {
    let canonical_path = entry.0
    let handle = entry.1
    match shader_assets.get(handle) {
      Some(shader) =>
        match shader.source {
          Source::Wgsl(source) =>
            @render.register_wgsl_source(canonical_path, source)
          _ => ()
        }
      None => ()
    }
  }
}

///|
fn shader_load_runtime_asset_or_abort(
  world : @ecs.World,
  path : String,
) -> Shader {
  let asset_server = shader_asset_server_or_abort(world)
  let handle : @asset.Handle[Shader] = asset_server.load(path)
  let shader_assets = shader_assets_or_abort(world)
  match shader_assets.get(handle) {
    Some(shader) => shader
    None =>
      abort("failed to load shader asset for runtime registration: \{path}")
  }
}

///|
pub fn shader_register_wgsl_runtime_source(
  world : @ecs.World,
  path : String,
) -> Unit {
  if shader_path_is_wesl(path) {
    abort(
      "shader_register_wgsl_runtime_source only supports .wgsl assets: \{path}",
    )
  }
  let shader = shader_load_runtime_asset_or_abort(world, path)
  match shader.source {
    Source::Wgsl(_) => shader_runtime_register_loaded_wgsl_sources(world)
    Source::Wesl(_) =>
      abort(
        "shader_register_wgsl_runtime_source received a WESL asset: \{path}",
      )
    Source::Glsl(_, _) =>
      abort(
        "shader_register_wgsl_runtime_source only supports WGSL assets: \{path}",
      )
    Source::SpirV(_) =>
      abort(
        "shader_register_wgsl_runtime_source only supports WGSL assets: \{path}",
      )
  }
}

///|
pub fn shader_register_wesl_runtime_source(
  world : @ecs.World,
  path : String,
  shader_defs : Array[ShaderDefVal],
) -> Unit raise ShaderCacheError {
  if !shader_path_is_wesl(path) {
    return
  }
  let asset_server = shader_asset_server_or_abort(world)
  let handle : @asset.Handle[Shader] = asset_server.load(path)
  shader_runtime_cache_sync_loaded_assets(world)
  let cache_ref = shader_runtime_cache_ref_mut_or_abort(world)
  let compiled = cache_ref.val.cache.get(0, handle.asset_id(), shader_defs)
  @render.register_wgsl_source(path, compiled)
}

///|
pub fn shader_register_runtime_source(
  world : @ecs.World,
  path : String,
  shader_defs : Array[ShaderDefVal],
) -> Unit raise ShaderCacheError {
  if shader_path_is_wesl(path) {
    shader_register_wesl_runtime_source(world, path, shader_defs)
    return
  }
  shader_register_wgsl_runtime_source(world, path)
}
