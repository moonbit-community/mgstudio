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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/mod.rs`.
//
// The package now owns lightweight Bevy-shaped wrappers around the GPU
// resource primitives used by the render stack.

///|
pub type BufferId = UInt64

///|
pub type TextureId = UInt64

///|
pub type TextureViewId = UInt64

///|
pub type SamplerId = UInt64

///|
pub type BindGroupId = UInt64

///|
pub type BindGroupLayoutId = UInt64

///|
pub type RenderPipelineId = UInt64

///|
pub type ComputePipelineId = UInt64

///|
pub type BufferAddress = UInt64

///|
priv struct RenderResourceIdState {
  mut buffer_id_seed : UInt64
  mut texture_id_seed : UInt64
  mut texture_view_id_seed : UInt64
  mut sampler_id_seed : UInt64
  mut bind_group_id_seed : UInt64
  mut bind_group_layout_id_seed : UInt64
  mut render_pipeline_id_seed : UInt64
  mut compute_pipeline_id_seed : UInt64
}

///|
fn render_resource_id_state_default() -> RenderResourceIdState {
  RenderResourceIdState::{
    buffer_id_seed: 0,
    texture_id_seed: 0,
    texture_view_id_seed: 0,
    sampler_id_seed: 0,
    bind_group_id_seed: 0,
    bind_group_layout_id_seed: 0,
    render_pipeline_id_seed: 0,
    compute_pipeline_id_seed: 0,
  }
}

///|
let render_resource_id_state_ref : Ref[RenderResourceIdState] = Ref(
  render_resource_id_state_default(),
)

///|
const RENDER_RESOURCE_ID_KIND_BUFFER : Int = 0

///|
const RENDER_RESOURCE_ID_KIND_TEXTURE : Int = 1

///|
const RENDER_RESOURCE_ID_KIND_TEXTURE_VIEW : Int = 2

///|
const RENDER_RESOURCE_ID_KIND_SAMPLER : Int = 3

///|
const RENDER_RESOURCE_ID_KIND_BIND_GROUP : Int = 4

///|
const RENDER_RESOURCE_ID_KIND_BIND_GROUP_LAYOUT : Int = 5

///|
const RENDER_RESOURCE_ID_KIND_RENDER_PIPELINE : Int = 6

///|
const RENDER_RESOURCE_ID_KIND_COMPUTE_PIPELINE : Int = 7

///|
fn next_id(kind : Int) -> UInt64 {
  let state = render_resource_id_state_ref.val
  match kind {
    RENDER_RESOURCE_ID_KIND_BUFFER => {
      let id = state.buffer_id_seed
      state.buffer_id_seed = id + 1
      id
    }
    RENDER_RESOURCE_ID_KIND_TEXTURE => {
      let id = state.texture_id_seed
      state.texture_id_seed = id + 1
      id
    }
    RENDER_RESOURCE_ID_KIND_TEXTURE_VIEW => {
      let id = state.texture_view_id_seed
      state.texture_view_id_seed = id + 1
      id
    }
    RENDER_RESOURCE_ID_KIND_SAMPLER => {
      let id = state.sampler_id_seed
      state.sampler_id_seed = id + 1
      id
    }
    RENDER_RESOURCE_ID_KIND_BIND_GROUP => {
      let id = state.bind_group_id_seed
      state.bind_group_id_seed = id + 1
      id
    }
    RENDER_RESOURCE_ID_KIND_BIND_GROUP_LAYOUT => {
      let id = state.bind_group_layout_id_seed
      state.bind_group_layout_id_seed = id + 1
      id
    }
    RENDER_RESOURCE_ID_KIND_RENDER_PIPELINE => {
      let id = state.render_pipeline_id_seed
      state.render_pipeline_id_seed = id + 1
      id
    }
    _ => {
      let id = state.compute_pipeline_id_seed
      state.compute_pipeline_id_seed = id + 1
      id
    }
  }
}

///|
fn next_buffer_id() -> BufferId {
  next_id(RENDER_RESOURCE_ID_KIND_BUFFER)
}

///|
fn next_texture_id() -> TextureId {
  next_id(RENDER_RESOURCE_ID_KIND_TEXTURE)
}

///|
fn next_texture_view_id() -> TextureViewId {
  next_id(RENDER_RESOURCE_ID_KIND_TEXTURE_VIEW)
}

///|
fn next_sampler_id() -> SamplerId {
  next_id(RENDER_RESOURCE_ID_KIND_SAMPLER)
}

///|
fn next_bind_group_id() -> BindGroupId {
  next_id(RENDER_RESOURCE_ID_KIND_BIND_GROUP)
}

///|
fn next_bind_group_layout_id() -> BindGroupLayoutId {
  next_id(RENDER_RESOURCE_ID_KIND_BIND_GROUP_LAYOUT)
}

///|
fn next_render_pipeline_id() -> RenderPipelineId {
  next_id(RENDER_RESOURCE_ID_KIND_RENDER_PIPELINE)
}

///|
fn next_compute_pipeline_id() -> ComputePipelineId {
  next_id(RENDER_RESOURCE_ID_KIND_COMPUTE_PIPELINE)
}
