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
  let compute_id = cache.queue_compute_pipeline(ComputePipelineDescriptor())
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
test "pipeline cache: creating state is distinct from queued and ok" {
  let state = CachedPipelineState::Creating
  debug_inspect(state.is_creating(), content="true")
  debug_inspect(state.is_queued(), content="false")
  debug_inspect(state.is_ok(), content="false")
  debug_inspect(state.is_err(), content="false")
}

///|
test "pipeline cache: process_queue exposes descriptors and waiting ids" {
  let cache = PipelineCache::new()
  let render_id = cache.queue_render_pipeline(
    RenderPipelineDescriptor::RenderPipelineDescriptor().with_label(
      Some("render"),
    ),
  )
  let compute_id = cache.queue_compute_pipeline(ComputePipelineDescriptor())
  cache.process_queue()
  debug_inspect(cache.pipeline_count(), content="2")
  debug_inspect(cache.queued_pipeline_count(), content="0")
  debug_inspect(cache.waiting_pipelines(), content="[0, 1]")
  debug_inspect(
    cache.get_render_pipeline_state(render_id).is_creating(),
    content="true",
  )
  debug_inspect(
    cache.get_compute_pipeline_state(compute_id).is_creating(),
    content="true",
  )
  let render_descriptor = cache.get_render_pipeline_descriptor(render_id)
  debug_inspect(render_descriptor.label, content="Some(\"render\")")
  let compute_descriptor = cache.get_compute_pipeline_descriptor(compute_id)
  debug_inspect(
    compute_descriptor.zero_initialize_workgroup_memory,
    content="true",
  )
}

///|
test "pipeline cache: waiting pipeline ids are observed without consumption" {
  let cache = PipelineCache::new()
  ignore(cache.queue_render_pipeline(RenderPipelineDescriptor()))
  ignore(cache.queue_compute_pipeline(ComputePipelineDescriptor()))
  cache.process_queue()
  debug_inspect(cache.waiting_pipelines(), content="[0, 1]")
  debug_inspect(cache.waiting_pipelines(), content="[0, 1]")
}

///|
test "pipeline cache: retryable errors requeue through process_queue" {
  let cache = PipelineCache::new()
  let render_id = cache.queue_render_pipeline(RenderPipelineDescriptor())
  let compute_id = cache.queue_compute_pipeline(ComputePipelineDescriptor())
  cache.process_queue()

  try! cache.mark_pipeline_retryable_error(
    render_id.id(),
    "shader import pending",
  )
  debug_inspect(cache.waiting_pipelines(), content="[0, 1]")
  debug_inspect(
    cache.get_render_pipeline_state(render_id).is_err(),
    content="true",
  )
  debug_inspect(
    cache.get_render_pipeline_state(render_id).error_message(),
    content="Some(\"shader import pending\")",
  )

  cache.process_queue()
  debug_inspect(cache.waiting_pipelines(), content="[0, 1]")
  debug_inspect(
    cache.get_render_pipeline_state(render_id).is_queued(),
    content="true",
  )
  cache.process_queue()
  debug_inspect(cache.waiting_pipelines(), content="[0, 1]")
  debug_inspect(
    cache.get_render_pipeline_state(render_id).is_creating(),
    content="true",
  )

  try! cache.mark_pipeline_error(compute_id.id(), "invalid shader module")
  debug_inspect(cache.waiting_pipelines(), content="[0]")
  debug_inspect(
    cache.get_compute_pipeline_state(compute_id).is_err(),
    content="true",
  )

  try {
    cache.get_render_pipeline_descriptor(CachedRenderPipelineId::new(99UL))
    |> ignore
    fail("unprocessed pipeline should reject descriptor access")
  } catch {
    PipelineNotProcessed(id) => debug_inspect(id, content="99")
    _ => fail("expected PipelineNotProcessed")
  }
  try {
    cache.get_render_pipeline_descriptor(
      CachedRenderPipelineId::new(compute_id.id()),
    )
    |> ignore
    fail("compute pipeline should not be readable as render")
  } catch {
    WrongPipelineKind(id) => debug_inspect(id, content="1")
    _ => fail("expected WrongPipelineKind")
  }
}

///|
test "pipeline cache: descriptor access rejects unprocessed ids and wrong kinds" {
  let cache = PipelineCache::new()
  let render_id = cache.queue_render_pipeline(RenderPipelineDescriptor())
  try {
    cache.get_render_pipeline_descriptor(render_id) |> ignore
    fail("descriptor should not be accessible before processing")
  } catch {
    PipelineNotProcessed(id) => debug_inspect(id, content="0")
    _ => fail("expected PipelineNotProcessed")
  }
  cache.process_queue()
  try {
    cache.get_compute_pipeline_descriptor(CachedComputePipelineId::new(0UL))
    |> ignore
    fail("render pipeline should not be readable as compute")
  } catch {
    WrongPipelineKind(id) => debug_inspect(id, content="0")
    _ => fail("expected WrongPipelineKind")
  }
}
