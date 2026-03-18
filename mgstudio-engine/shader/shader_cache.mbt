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
