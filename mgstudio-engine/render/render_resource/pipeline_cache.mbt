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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/pipeline_cache.rs`.

///|
pub(all) enum Pipeline {
  RenderPipeline(RenderPipeline)
  ComputePipeline(ComputePipeline)
}

///|
pub struct CachedPipeline {
  descriptor : PipelineDescriptor
  state : CachedPipelineState
}

///|
pub(all) enum CachedPipelineState {
  Queued
  Ok(Pipeline)
  Err(String)
}

///|
pub fn CachedPipelineState::is_queued(self : CachedPipelineState) -> Bool {
  self is Queued
}

///|
pub fn CachedPipelineState::is_ok(self : CachedPipelineState) -> Bool {
  self is Ok(_)
}

///|
pub fn CachedPipelineState::is_err(self : CachedPipelineState) -> Bool {
  self is Err(_)
}

///|
pub fn CachedPipeline::descriptor(self : CachedPipeline) -> PipelineDescriptor {
  self.descriptor
}

///|
pub fn CachedPipeline::state(self : CachedPipeline) -> CachedPipelineState {
  self.state
}

///|
pub struct PipelineCache {
  pipelines : Array[CachedPipeline]
  waiting_pipelines : Array[UInt64]
  new_pipelines : Array[CachedPipeline]
}

///|
pub fn PipelineCache::new() -> PipelineCache {
  PipelineCache::{ pipelines: [], waiting_pipelines: [], new_pipelines: [] }
}

///|
pub fn PipelineCache::pipelines(self : PipelineCache) -> Array[CachedPipeline] {
  self.pipelines.copy()
}

///|
pub fn PipelineCache::waiting_pipelines(self : PipelineCache) -> Array[UInt64] {
  self.waiting_pipelines.copy()
}

///|
pub fn PipelineCache::drain_waiting_pipelines(
  self : PipelineCache,
) -> Array[UInt64] {
  let waiting = self.waiting_pipelines.copy()
  self.waiting_pipelines.clear()
  waiting
}

///|
pub fn PipelineCache::queued_pipeline_count(self : PipelineCache) -> Int {
  self.new_pipelines.length()
}

///|
pub fn PipelineCache::pipeline_count(self : PipelineCache) -> Int {
  self.pipelines.length()
}

///|
pub fn PipelineCache::queue_render_pipeline(
  self : PipelineCache,
  descriptor : RenderPipelineDescriptor,
) -> CachedRenderPipelineId {
  let id = CachedRenderPipelineId::new(
    (self.pipelines.length() + self.new_pipelines.length()).to_uint64(),
  )
  self.new_pipelines.push(CachedPipeline::{
    descriptor: PipelineDescriptor::RenderPipelineDescriptor(descriptor),
    state: CachedPipelineState::Queued,
  })
  id
}

///|
pub fn PipelineCache::queue_compute_pipeline(
  self : PipelineCache,
  descriptor : ComputePipelineDescriptor,
) -> CachedComputePipelineId {
  let id = CachedComputePipelineId::new(
    (self.pipelines.length() + self.new_pipelines.length()).to_uint64(),
  )
  self.new_pipelines.push(CachedPipeline::{
    descriptor: PipelineDescriptor::ComputePipelineDescriptor(descriptor),
    state: CachedPipelineState::Queued,
  })
  id
}

///|
fn PipelineCache::pipeline_state_by_index(
  self : PipelineCache,
  id : UInt64,
) -> CachedPipelineState {
  let index = id.to_int()
  if index < 0 || index >= self.pipelines.length() {
    CachedPipelineState::Queued
  } else {
    self.pipelines[index].state
  }
}

///|
pub fn PipelineCache::get_render_pipeline_state(
  self : PipelineCache,
  id : CachedRenderPipelineId,
) -> CachedPipelineState {
  self.pipeline_state_by_index(id.id())
}

///|
pub fn PipelineCache::get_compute_pipeline_state(
  self : PipelineCache,
  id : CachedComputePipelineId,
) -> CachedPipelineState {
  self.pipeline_state_by_index(id.id())
}

///|
pub suberror PipelineCacheAccessError {
  PipelineNotProcessed(UInt64)
  WrongPipelineKind(UInt64)
}

///|
pub fn PipelineCache::get_render_pipeline_descriptor(
  self : PipelineCache,
  id : CachedRenderPipelineId,
) -> RenderPipelineDescriptor raise PipelineCacheAccessError {
  let index = id.id().to_int()
  if index < 0 || index >= self.pipelines.length() {
    raise PipelineCacheAccessError::PipelineNotProcessed(id.id())
  }
  match self.pipelines[index].descriptor {
    RenderPipelineDescriptor(descriptor) => descriptor
    ComputePipelineDescriptor(_) =>
      raise PipelineCacheAccessError::WrongPipelineKind(id.id())
  }
}

///|
pub fn PipelineCache::get_compute_pipeline_descriptor(
  self : PipelineCache,
  id : CachedComputePipelineId,
) -> ComputePipelineDescriptor raise PipelineCacheAccessError {
  let index = id.id().to_int()
  if index < 0 || index >= self.pipelines.length() {
    raise PipelineCacheAccessError::PipelineNotProcessed(id.id())
  }
  match self.pipelines[index].descriptor {
    RenderPipelineDescriptor(_) =>
      raise PipelineCacheAccessError::WrongPipelineKind(id.id())
    ComputePipelineDescriptor(descriptor) => descriptor
  }
}

///|
pub fn PipelineCache::get_render_pipeline(
  self : PipelineCache,
  id : CachedRenderPipelineId,
) -> RenderPipeline? {
  let index = id.id().to_int()
  if index < 0 || index >= self.pipelines.length() {
    return None
  }
  match self.pipelines[index].state {
    Ok(RenderPipeline(pipeline)) => Some(pipeline)
    _ => None
  }
}

///|
pub fn PipelineCache::get_compute_pipeline(
  self : PipelineCache,
  id : CachedComputePipelineId,
) -> ComputePipeline? {
  let index = id.id().to_int()
  if index < 0 || index >= self.pipelines.length() {
    return None
  }
  match self.pipelines[index].state {
    Ok(ComputePipeline(pipeline)) => Some(pipeline)
    _ => None
  }
}

///|
pub fn PipelineCache::accept_new_pipelines_for_processing(
  self : PipelineCache,
) -> Unit {
  for new_pipeline in self.new_pipelines {
    let id = self.pipelines.length().to_uint64()
    self.pipelines.push(new_pipeline)
    self.waiting_pipelines.push(id)
  }
  self.new_pipelines.clear()
}
