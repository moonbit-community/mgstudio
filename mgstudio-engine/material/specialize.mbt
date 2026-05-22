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
// Bevy source: `bevy/crates/bevy_material/src/specialize.rs`.

///|
pub type MaterialMeshVertexLayout = @mesh.MeshVertexBufferLayoutRef

///|
pub suberror SpecializedMeshPipelineError {
  MissingVertexAttribute(@mesh.MissingVertexAttributeError)
}

///|
pub type BaseSpecializeFn = (
  @ecs.World,
  ErasedMaterialPipelineKey,
  MaterialMeshVertexLayout,
  MaterialProperties,
) -> CachedRenderPipelineId raise SpecializedMeshPipelineError

///|
pub type PrepassSpecializeFn = (
  @ecs.World,
  ErasedMaterialPipelineKey,
  MaterialMeshVertexLayout,
  MaterialProperties,
) -> CachedRenderPipelineId raise SpecializedMeshPipelineError

///|
pub type UserSpecializeFn = (
  String,
  RenderPipelineDescriptor,
  MaterialMeshVertexLayout,
  ErasedMaterialPipelineKey,
) -> RenderPipelineDescriptor raise SpecializedMeshPipelineError

///|
pub fn missing_vertex_attribute_error(
  attribute : String,
) -> SpecializedMeshPipelineError {
  MissingVertexAttribute(
    @mesh.MissingVertexAttributeError::new(
      id=@mesh.MeshVertexAttributeId::new(0UL),
      name=attribute,
    ),
  )
}

///|
pub fn specialized_mesh_pipeline_missing_vertex_attribute_error(
  error : @mesh.MissingVertexAttributeError,
) -> SpecializedMeshPipelineError {
  MissingVertexAttribute(error)
}

///|
pub fn material_specialize_base(
  specialize : BaseSpecializeFn,
  world : @ecs.World,
  key : ErasedMaterialPipelineKey,
  layout : MaterialMeshVertexLayout,
  properties : MaterialProperties,
) -> CachedRenderPipelineId raise {
  specialize(world, key, layout, properties)
}

///|
pub fn material_specialize_prepass(
  specialize : PrepassSpecializeFn,
  world : @ecs.World,
  key : ErasedMaterialPipelineKey,
  layout : MaterialMeshVertexLayout,
  properties : MaterialProperties,
) -> CachedRenderPipelineId raise {
  specialize(world, key, layout, properties)
}

///|
pub fn material_specialize_user(
  specialize : UserSpecializeFn,
  user_key : String,
  descriptor : RenderPipelineDescriptor,
  layout : MaterialMeshVertexLayout,
  key : ErasedMaterialPipelineKey,
) -> RenderPipelineDescriptor raise {
  specialize(user_key, descriptor, layout, key)
}

///|
pub type SpecializedMeshPipelineFn = (
  ErasedMaterialPipelineKey,
  MaterialMeshVertexLayout,
) -> RenderPipelineDescriptor raise SpecializedMeshPipelineError

///|
struct SpecializedMeshPipelineMeshLayoutCacheEntry {
  layout : MaterialMeshVertexLayout
  key : ErasedMaterialPipelineKey
  pipeline_id : CachedRenderPipelineId
}

///|
struct SpecializedMeshPipelineVertexLayoutCacheEntry {
  vertex_layout : VertexBufferLayout
  key : ErasedMaterialPipelineKey
  pipeline_id : CachedRenderPipelineId
  descriptor : RenderPipelineDescriptor
}

///|
pub struct SpecializedMeshPipelines {
  mesh_layout_cache : Array[SpecializedMeshPipelineMeshLayoutCacheEntry]
  vertex_layout_cache : Array[SpecializedMeshPipelineVertexLayoutCacheEntry]
}

///|
pub fn SpecializedMeshPipelines::new() -> SpecializedMeshPipelines {
  SpecializedMeshPipelines::{ mesh_layout_cache: [], vertex_layout_cache: [] }
}

///|
pub fn SpecializedMeshPipelines::SpecializedMeshPipelines() -> SpecializedMeshPipelines {
  SpecializedMeshPipelines::new()
}

///|
pub impl Default for SpecializedMeshPipelines with default() {
  SpecializedMeshPipelines::SpecializedMeshPipelines()
}

///|
pub fn SpecializedMeshPipelines::mesh_layout_cache_len(
  self : SpecializedMeshPipelines,
) -> Int {
  self.mesh_layout_cache.length()
}

///|
pub fn SpecializedMeshPipelines::vertex_layout_cache_len(
  self : SpecializedMeshPipelines,
) -> Int {
  self.vertex_layout_cache.length()
}

///|
pub fn SpecializedMeshPipelines::render_pipeline_descriptor(
  self : SpecializedMeshPipelines,
  pipeline_id : CachedRenderPipelineId,
) -> RenderPipelineDescriptor? {
  for entry in self.vertex_layout_cache {
    if entry.pipeline_id.id() == pipeline_id.id() {
      return Some(entry.descriptor)
    }
  }
  None
}

///|
fn specialized_mesh_pipeline_find_mesh_layout_cache(
  cache : Array[SpecializedMeshPipelineMeshLayoutCacheEntry],
  layout : MaterialMeshVertexLayout,
  key : ErasedMaterialPipelineKey,
) -> CachedRenderPipelineId? {
  for entry in cache {
    if entry.layout.equal(layout) && entry.key == key {
      return Some(entry.pipeline_id)
    }
  }
  None
}

///|
fn specialized_mesh_pipeline_find_vertex_layout_cache(
  cache : Array[SpecializedMeshPipelineVertexLayoutCacheEntry],
  vertex_layout : VertexBufferLayout,
  key : ErasedMaterialPipelineKey,
) -> CachedRenderPipelineId? {
  for entry in cache {
    if entry.vertex_layout.equal(vertex_layout) && entry.key == key {
      return Some(entry.pipeline_id)
    }
  }
  None
}

///|
pub fn SpecializedMeshPipelines::specialize(
  self : SpecializedMeshPipelines,
  specialize_pipeline : SpecializedMeshPipelineFn,
  key : ErasedMaterialPipelineKey,
  layout : MaterialMeshVertexLayout,
) -> CachedRenderPipelineId raise SpecializedMeshPipelineError {
  match
    specialized_mesh_pipeline_find_mesh_layout_cache(
      self.mesh_layout_cache,
      layout,
      key,
    ) {
    Some(pipeline_id) => return pipeline_id
    None => ()
  }
  let descriptor = specialize_pipeline(key, layout)
  if descriptor.vertex.buffers.length() != 1 {
    abort(
      "SpecializedMeshPipeline::specialize must return exactly one vertex buffer layout",
    )
  }
  let vertex_layout = descriptor.vertex.buffers[0]
  let pipeline_id = match
    specialized_mesh_pipeline_find_vertex_layout_cache(
      self.vertex_layout_cache,
      vertex_layout,
      key,
    ) {
    Some(pipeline_id) => pipeline_id
    None => {
      let id = CachedRenderPipelineId::new(
        self.vertex_layout_cache.length().to_uint64(),
      )
      self.vertex_layout_cache.push(SpecializedMeshPipelineVertexLayoutCacheEntry::{
        vertex_layout,
        key,
        pipeline_id: id,
        descriptor,
      })
      id
    }
  }
  self.mesh_layout_cache.push(SpecializedMeshPipelineMeshLayoutCacheEntry::{
    layout,
    key,
    pipeline_id,
  })
  pipeline_id
}
