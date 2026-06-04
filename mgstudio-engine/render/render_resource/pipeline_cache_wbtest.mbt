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
test "pipeline cache: queued render and compute pipelines allocate stable ids" {
  let cache = PipelineCache::new()
  let render_id = cache.queue_render_pipeline(
    RenderPipelineDescriptor::RenderPipelineDescriptor().with_label(
      Some("render"),
    ),
  )
  let compute_id = cache.queue_compute_pipeline(
    ComputePipelineDescriptor::ComputePipelineDescriptor(),
  )
  debug_inspect(render_id.id(), content="0")
  debug_inspect(compute_id.id(), content="1")
  debug_inspect(cache.pipeline_count(), content="0")
  debug_inspect(cache.queued_pipeline_count(), content="2")
  debug_inspect(
    cache.get_render_pipeline_state(render_id).is_queued(),
    content="true",
  )
}

///|
test "pipeline cache: accepting new pipelines exposes descriptors and waiting ids" {
  let cache = PipelineCache::new()
  let render_id = cache.queue_render_pipeline(
    RenderPipelineDescriptor::RenderPipelineDescriptor().with_label(
      Some("render"),
    ),
  )
  let compute_id = cache.queue_compute_pipeline(
    ComputePipelineDescriptor::ComputePipelineDescriptor(),
  )
  cache.accept_new_pipelines_for_processing()
  debug_inspect(cache.pipeline_count(), content="2")
  debug_inspect(cache.queued_pipeline_count(), content="0")
  debug_inspect(cache.waiting_pipelines(), content="[0, 1]")
  let render_descriptor = cache.get_render_pipeline_descriptor(render_id)
  debug_inspect(render_descriptor.label, content="Some(\"render\")")
  let compute_descriptor = cache.get_compute_pipeline_descriptor(compute_id)
  debug_inspect(
    compute_descriptor.zero_initialize_workgroup_memory,
    content="true",
  )
}

///|
test "pipeline cache: waiting pipeline ids drain once" {
  let cache = PipelineCache::new()
  ignore(
    cache.queue_render_pipeline(
      RenderPipelineDescriptor::RenderPipelineDescriptor(),
    ),
  )
  ignore(
    cache.queue_compute_pipeline(
      ComputePipelineDescriptor::ComputePipelineDescriptor(),
    ),
  )
  cache.accept_new_pipelines_for_processing()
  debug_inspect(cache.drain_waiting_pipelines(), content="[0, 1]")
  debug_inspect(cache.waiting_pipelines(), content="[]")
  debug_inspect(cache.drain_waiting_pipelines(), content="[]")
}

///|
test "pipeline cache: descriptor access rejects unprocessed ids and wrong kinds" {
  let cache = PipelineCache::new()
  let render_id = cache.queue_render_pipeline(
    RenderPipelineDescriptor::RenderPipelineDescriptor(),
  )
  try {
    cache.get_render_pipeline_descriptor(render_id) |> ignore
    fail("descriptor should not be accessible before processing")
  } catch {
    PipelineNotProcessed(id) => debug_inspect(id, content="0")
    _ => fail("expected PipelineNotProcessed")
  }
  cache.accept_new_pipelines_for_processing()
  try {
    cache.get_compute_pipeline_descriptor(CachedComputePipelineId::new(0UL))
    |> ignore
    fail("render pipeline should not be readable as compute")
  } catch {
    WrongPipelineKind(id) => debug_inspect(id, content="0")
    _ => fail("expected WrongPipelineKind")
  }
}
