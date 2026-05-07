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
pub struct PipelineCache {
  render_pipelines : Map[String, RenderPipelineId]
  compute_pipelines : Map[String, ComputePipelineId]
}

///|
pub fn PipelineCache::new() -> PipelineCache {
  PipelineCache::{ render_pipelines: Map([]), compute_pipelines: Map([]) }
}

///|
pub fn PipelineCache::insert_render(
  self : PipelineCache,
  key : String,
  pipeline_id : RenderPipelineId,
) -> Unit {
  self.render_pipelines[key] = pipeline_id
}

///|
pub fn PipelineCache::insert_compute(
  self : PipelineCache,
  key : String,
  pipeline_id : ComputePipelineId,
) -> Unit {
  self.compute_pipelines[key] = pipeline_id
}

///|
pub fn PipelineCache::render_pipeline(
  self : PipelineCache,
  key : String,
) -> RenderPipelineId? {
  self.render_pipelines.get(key)
}

///|
pub fn PipelineCache::compute_pipeline(
  self : PipelineCache,
  key : String,
) -> ComputePipelineId? {
  self.compute_pipelines.get(key)
}

///|
pub fn PipelineCache::clear(self : PipelineCache) -> Unit {
  self.render_pipelines.clear()
  self.compute_pipelines.clear()
}
