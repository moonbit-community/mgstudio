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
/// Fully composed source code of a shader module, with all shader defs applied.
/// This mirrors Bevy's `ShaderCacheSource` surface inside `bevy_shader`.
pub(all) enum ShaderCacheSource {
  SpirV(Bytes)
  Wgsl(String)
} derive(Eq, Show)

///|
/// An id of a cached pipeline, typically representing a unique shader +
/// shader-def combination inside a pipeline cache.
pub type CachedPipelineId = Int

///|
/// Shader cache bookkeeping owned by the `shader` package.
/// `ShaderId` stays generic here because exact `AssetId<Shader>` ownership is
/// still blocked by the current `shader <-> asset` package cycle.
struct ShaderData[ShaderModule, ShaderId] {
  pipelines : @hashset.HashSet[CachedPipelineId]
  processed_shaders : @hashmap.HashMap[Array[ShaderDefVal], ShaderModule]
  resolved_imports : @hashmap.HashMap[ShaderImport, ShaderId]
  dependents : @hashset.HashSet[ShaderId]
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::default() -> ShaderData[
  ShaderModule,
  ShaderId,
] {
  {
    pipelines: @hashset.HashSet::new(),
    processed_shaders: @hashmap.HashMap::new(),
    resolved_imports: @hashmap.HashMap::new(),
    dependents: @hashset.HashSet::new(),
  }
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::track_pipeline(
  self : ShaderData[ShaderModule, ShaderId],
  pipeline : CachedPipelineId,
) -> Unit {
  self.pipelines.add(pipeline)
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::pipeline_count(
  self : ShaderData[ShaderModule, ShaderId],
) -> Int {
  self.pipelines.length()
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::cache_processed_shader(
  self : ShaderData[ShaderModule, ShaderId],
  shader_defs : Array[ShaderDefVal],
  shader_module : ShaderModule,
) -> Unit {
  self.processed_shaders.set(shader_defs, shader_module)
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::get_processed_shader(
  self : ShaderData[ShaderModule, ShaderId],
  shader_defs : Array[ShaderDefVal],
) -> ShaderModule? {
  self.processed_shaders.get(shader_defs)
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::processed_shader_count(
  self : ShaderData[ShaderModule, ShaderId],
) -> Int {
  self.processed_shaders.length()
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::resolve_import(
  self : ShaderData[ShaderModule, ShaderId],
  shader_import : ShaderImport,
  shader_id : ShaderId,
) -> Unit {
  self.resolved_imports.set(shader_import, shader_id)
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::resolved_import(
  self : ShaderData[ShaderModule, ShaderId],
  shader_import : ShaderImport,
) -> ShaderId? {
  self.resolved_imports.get(shader_import)
}

///|
pub fn[ShaderModule, ShaderId : Hash + Eq] ShaderData::track_dependent(
  self : ShaderData[ShaderModule, ShaderId],
  shader_id : ShaderId,
) -> Unit {
  self.dependents.add(shader_id)
}

///|
pub fn[ShaderModule, ShaderId] ShaderData::dependent_count(
  self : ShaderData[ShaderModule, ShaderId],
) -> Int {
  self.dependents.length()
}

///|
pub(all) suberror ShaderCacheError {
  ShaderNotLoaded(@asset.AssetId[Shader])
  ProcessShaderError(String)
  ShaderImportNotYetAvailable
  CreateShaderModule(String)
}

///|
pub fn ShaderCacheError::message(self : ShaderCacheError) -> String {
  match self {
    ShaderNotLoaded(asset_id) =>
      "Pipeline could not be compiled because the shader was not loaded: " +
      asset_id.index().to_string()
    ProcessShaderError(reason) => reason
    ShaderImportNotYetAvailable => "Shader import not yet available."
    CreateShaderModule(reason) => "Could not create shader module: " + reason
  }
}

///|
pub struct ShaderCache[ShaderModule, RenderDevice] {
  device : RenderDevice
  load_module : (RenderDevice, ShaderCacheSource, ValidateShader) -> Result[
    ShaderModule,
    ShaderCacheError,
  ]
  data : @hashmap.HashMap[Int, ShaderData[ShaderModule, Int]]
  shaders : @hashmap.HashMap[Int, Shader]
  import_path_shaders : @hashmap.HashMap[ShaderImport, @asset.AssetId[Shader]]
  waiting_on_import : @hashmap.HashMap[
    ShaderImport,
    Array[@asset.AssetId[Shader]],
  ]
  composer : @naga_oil.Composer
}

///|
fn shader_cache_asset_key(asset_id : @asset.AssetId[Shader]) -> Int {
  asset_id.index()
}

///|
fn shader_cache_copy_asset_id_array(
  items : Array[@asset.AssetId[Shader]],
) -> Array[@asset.AssetId[Shader]] {
  let copied : Array[@asset.AssetId[Shader]] = []
  for item in items {
    copied.push(item)
  }
  copied
}

///|
fn[ShaderModule, RenderDevice] shader_cache_data_or_default(
  cache : ShaderCache[ShaderModule, RenderDevice],
  shader_key : Int,
) -> ShaderData[ShaderModule, Int] {
  match cache.data.get(shader_key) {
    Some(data) => data
    None => ShaderData::default()
  }
}

///|
fn[ShaderModule, RenderDevice] shader_cache_clear(
  cache : ShaderCache[ShaderModule, RenderDevice],
  asset_id : @asset.AssetId[Shader],
) -> Array[CachedPipelineId] {
  let shaders_to_clear : Array[Int] = [shader_cache_asset_key(asset_id)]
  let pipelines_to_queue : Array[CachedPipelineId] = []
  while shaders_to_clear.length() > 0 {
    let shader_key = shaders_to_clear.pop().unwrap()
    match cache.data.get(shader_key) {
      Some(shader_data) => {
        shader_data.processed_shaders.clear()
        for pipeline_id in shader_data.pipelines.iter() {
          pipelines_to_queue.push(pipeline_id)
        }
        for dependent_key in shader_data.dependents.iter() {
          shaders_to_clear.push(dependent_key)
        }
        cache.data.set(shader_key, shader_data)
      }
      None => ()
    }
  }
  pipelines_to_queue
}

///|
pub fn[ShaderModule, RenderDevice] ShaderCache::new(
  device : RenderDevice,
  load_module : (RenderDevice, ShaderCacheSource, ValidateShader) -> Result[
    ShaderModule,
    ShaderCacheError,
  ],
) -> ShaderCache[ShaderModule, RenderDevice] {
  {
    device,
    load_module,
    data: @hashmap.HashMap::new(),
    shaders: @hashmap.HashMap::new(),
    import_path_shaders: @hashmap.HashMap::new(),
    waiting_on_import: @hashmap.HashMap::new(),
    composer: @naga_oil.Composer::default(),
  }
}

///|
pub fn[ShaderModule, RenderDevice] ShaderCache::contains_shader(
  self : ShaderCache[ShaderModule, RenderDevice],
  asset_id : @asset.AssetId[Shader],
) -> Bool {
  self.shaders.contains(shader_cache_asset_key(asset_id))
}

///|
pub fn[ShaderModule, RenderDevice] ShaderCache::set_shader(
  self : ShaderCache[ShaderModule, RenderDevice],
  asset_id : @asset.AssetId[Shader],
  shader : Shader,
) -> Array[CachedPipelineId] {
  let shader_key = shader_cache_asset_key(asset_id)
  let pipelines_to_queue = shader_cache_clear(self, asset_id)
  let import_path = shader.import_path
  self.import_path_shaders.set(import_path, asset_id)

  match self.waiting_on_import.get(import_path) {
    Some(waiting_shaders) => {
      for waiting_shader in waiting_shaders {
        let waiting_key = shader_cache_asset_key(waiting_shader)
        let waiting_data = shader_cache_data_or_default(self, waiting_key)
        waiting_data.resolve_import(import_path, shader_key)
        self.data.set(waiting_key, waiting_data)

        let import_data = shader_cache_data_or_default(self, shader_key)
        import_data.track_dependent(waiting_key)
        self.data.set(shader_key, import_data)
      }
      ignore(self.waiting_on_import.remove(import_path))
    }
    None => ()
  }

  for shader_import in shader.imports {
    match self.import_path_shaders.get(shader_import) {
      Some(import_asset_id) => {
        let shader_data = shader_cache_data_or_default(self, shader_key)
        let import_key = shader_cache_asset_key(import_asset_id)
        shader_data.resolve_import(shader_import, import_key)
        self.data.set(shader_key, shader_data)

        let import_data = shader_cache_data_or_default(self, import_key)
        import_data.track_dependent(shader_key)
        self.data.set(import_key, import_data)
      }
      None => {
        let waiting_shaders = match self.waiting_on_import.get(shader_import) {
          Some(items) => shader_cache_copy_asset_id_array(items)
          None => []
        }
        waiting_shaders.push(asset_id)
        self.waiting_on_import.set(shader_import, waiting_shaders)
      }
    }
  }

  self.shaders.set(shader_key, shader)
  pipelines_to_queue
}

///|
pub fn[ShaderModule, RenderDevice] ShaderCache::remove(
  self : ShaderCache[ShaderModule, RenderDevice],
  asset_id : @asset.AssetId[Shader],
) -> Array[CachedPipelineId] {
  let pipelines_to_queue = shader_cache_clear(self, asset_id)
  match self.shaders.get(shader_cache_asset_key(asset_id)) {
    Some(shader) => self.import_path_shaders.remove(shader.import_path)
    None => ()
  }
  self.shaders.remove(shader_cache_asset_key(asset_id))
  pipelines_to_queue
}
