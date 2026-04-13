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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/pipeline.rs`.

///|
pub struct RenderPipeline {
  id : RenderPipelineId
  value : @wgpu.RenderPipeline
}

///|
pub struct ComputePipeline {
  id : ComputePipelineId
  value : @wgpu.ComputePipeline
}

///|
pub fn RenderPipeline::new(value : @wgpu.RenderPipeline) -> RenderPipeline {
  RenderPipeline::{ id: next_render_pipeline_id(), value }
}

///|
pub fn RenderPipeline::from_wgpu(
  value : @wgpu.RenderPipeline,
) -> RenderPipeline {
  RenderPipeline::new(value)
}

///|
pub fn RenderPipeline::id(self : RenderPipeline) -> RenderPipelineId {
  self.id
}

///|
pub fn RenderPipeline::get_bind_group_layout(
  self : RenderPipeline,
  index : UInt,
) -> BindGroupLayout {
  BindGroupLayout::from_wgpu(self.value.get_bind_group_layout(index))
}

///|
pub fn RenderPipeline::set_label(self : RenderPipeline, label : String) -> Unit {
  self.value.set_label(label)
}

///|
pub fn RenderPipeline::into_inner(
  self : RenderPipeline,
) -> @wgpu.RenderPipeline {
  self.value
}

///|
pub fn ComputePipeline::new(value : @wgpu.ComputePipeline) -> ComputePipeline {
  ComputePipeline::{ id: next_compute_pipeline_id(), value }
}

///|
pub fn ComputePipeline::from_wgpu(
  value : @wgpu.ComputePipeline,
) -> ComputePipeline {
  ComputePipeline::new(value)
}

///|
pub fn ComputePipeline::id(self : ComputePipeline) -> ComputePipelineId {
  self.id
}

///|
pub fn ComputePipeline::get_bind_group_layout(
  self : ComputePipeline,
  index : UInt,
) -> BindGroupLayout {
  BindGroupLayout::from_wgpu(self.value.get_bind_group_layout(index))
}

///|
pub fn ComputePipeline::set_label(
  self : ComputePipeline,
  label : String,
) -> Unit {
  self.value.set_label(label)
}

///|
pub fn ComputePipeline::into_inner(
  self : ComputePipeline,
) -> @wgpu.ComputePipeline {
  self.value
}
