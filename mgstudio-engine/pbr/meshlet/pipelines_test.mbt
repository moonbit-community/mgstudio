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
test "pbr/meshlet: pipeline counters split compute and render paths" {
  let pipelines = init_meshlet_pipelines_with_core(10, 11, 12, 13)
  debug_inspect(meshlet_pipeline_count(pipelines), content="4")
  debug_inspect(meshlet_render_pipeline_count(pipelines), content="3")
  debug_inspect(meshlet_compute_pipeline_count(pipelines), content="1")
}

///|
test "pbr/meshlet: compatibility init keeps pipeline ids active" {
  let pipelines = init_meshlet_pipelines(21, 22, 23)
  debug_inspect(meshlet_pipeline_count(pipelines), content="4")
}

///|
test "pbr/meshlet: pipeline slot descriptors expose bevy-shaped surface" {
  let descriptors = meshlet_pipeline_slot_descriptors()
  debug_inspect(descriptors.length(), content="22")
}

///|
test "pbr/meshlet: readiness reports missing required slots" {
  let pipelines = MeshletPipelines::default()
  debug_inspect(meshlet_pipelines_ready(pipelines), content="false")
  let missing = meshlet_missing_required_pipeline_slots(pipelines)
  debug_inspect(missing.length() > 0, content="true")
}
