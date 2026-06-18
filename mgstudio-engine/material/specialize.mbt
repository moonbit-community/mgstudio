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
  vertex_layouts : Array[VertexBufferLayout]
  key : ErasedMaterialPipelineKey
  pipeline_id : CachedRenderPipelineId
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
pub impl Default for SpecializedMeshPipelines with fn default() {
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
  vertex_layouts : Array[VertexBufferLayout],
  key : ErasedMaterialPipelineKey,
) -> CachedRenderPipelineId? {
  for entry in cache {
    if vertex_buffer_layouts_equal(entry.vertex_layouts, vertex_layouts) &&
      entry.key == key {
      return Some(entry.pipeline_id)
    }
  }
  None
}

///|
fn vertex_buffer_layouts_equal(
  left : Array[VertexBufferLayout],
  right : Array[VertexBufferLayout],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for index in 0..<left.length() {
    if !left[index].equal(right[index]) {
      return false
    }
  }
  true
}

///|
pub fn SpecializedMeshPipelines::specialize(
  self : SpecializedMeshPipelines,
  pipeline_cache : @render_resource.PipelineCache,
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
  let pipeline_id = match
    specialized_mesh_pipeline_find_vertex_layout_cache(
      self.vertex_layout_cache,
      descriptor.vertex.buffers,
      key,
    ) {
    Some(pipeline_id) => pipeline_id
    None => {
      let id = pipeline_cache.queue_render_pipeline(descriptor)
      self.vertex_layout_cache.push(SpecializedMeshPipelineVertexLayoutCacheEntry::{
        vertex_layouts: descriptor.vertex.buffers,
        key,
        pipeline_id: id,
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
