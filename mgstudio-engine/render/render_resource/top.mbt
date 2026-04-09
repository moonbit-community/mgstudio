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
let buffer_id_seed : Ref[UInt64] = Ref::new(0)

///|
let texture_id_seed : Ref[UInt64] = Ref::new(0)

///|
let texture_view_id_seed : Ref[UInt64] = Ref::new(0)

///|
let sampler_id_seed : Ref[UInt64] = Ref::new(0)

///|
let bind_group_id_seed : Ref[UInt64] = Ref::new(0)

///|
let bind_group_layout_id_seed : Ref[UInt64] = Ref::new(0)

///|
let render_pipeline_id_seed : Ref[UInt64] = Ref::new(0)

///|
let compute_pipeline_id_seed : Ref[UInt64] = Ref::new(0)

///|
fn next_id(seed : Ref[UInt64]) -> UInt64 {
  let id = seed.val
  seed.val = id + 1
  id
}

///|
fn next_buffer_id() -> BufferId {
  next_id(buffer_id_seed)
}

///|
fn next_texture_id() -> TextureId {
  next_id(texture_id_seed)
}

///|
fn next_texture_view_id() -> TextureViewId {
  next_id(texture_view_id_seed)
}

///|
fn next_sampler_id() -> SamplerId {
  next_id(sampler_id_seed)
}

///|
fn next_bind_group_id() -> BindGroupId {
  next_id(bind_group_id_seed)
}

///|
fn next_bind_group_layout_id() -> BindGroupLayoutId {
  next_id(bind_group_layout_id_seed)
}

///|
fn next_render_pipeline_id() -> RenderPipelineId {
  next_id(render_pipeline_id_seed)
}

///|
fn next_compute_pipeline_id() -> ComputePipelineId {
  next_id(compute_pipeline_id_seed)
}
