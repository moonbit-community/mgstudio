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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/pipelines.rs`.

///|
pub struct MeshletPipelines {
  main_opaque_pipeline_id : Int
  prepass_pipeline_id : Int
  deferred_prepass_pipeline_id : Int
}

///|
pub fn MeshletPipelines::default() -> MeshletPipelines {
  MeshletPipelines::{
    main_opaque_pipeline_id: -1,
    prepass_pipeline_id: -1,
    deferred_prepass_pipeline_id: -1,
  }
}

///|
pub fn init_meshlet_pipelines(
  main_opaque_pipeline_id : Int,
  prepass_pipeline_id : Int,
  deferred_prepass_pipeline_id : Int,
) -> MeshletPipelines {
  MeshletPipelines::{
    main_opaque_pipeline_id,
    prepass_pipeline_id,
    deferred_prepass_pipeline_id,
  }
}

///|
pub fn meshlet_pipeline_count(pipelines : MeshletPipelines) -> Int {
  let mut count = 0
  if pipelines.main_opaque_pipeline_id >= 0 {
    count = count + 1
  }
  if pipelines.prepass_pipeline_id >= 0 {
    count = count + 1
  }
  if pipelines.deferred_prepass_pipeline_id >= 0 {
    count = count + 1
  }
  count
}

///|
pub fn meshlet_pipelines_runtime_available() -> Bool {
  meshlet_runtime_available()
}
