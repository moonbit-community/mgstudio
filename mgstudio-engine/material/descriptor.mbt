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
// The `material` package keeps these aliases for existing call sites; the
// owning descriptor surface now lives in `render/render_resource`, matching
// Bevy's package boundary.

///|
pub type BindGroupLayoutDescriptor = @render_resource.BindGroupLayoutDescriptor

///|
pub type ShaderDefVal = @render_resource.ShaderDefVal

///|
pub type VertexBufferLayout = @render_resource.VertexBufferLayout

///|
pub type VertexState = @render_resource.VertexState

///|
pub type ColorTargetState = @render_resource.ColorTargetState

///|
pub type FragmentState = @render_resource.FragmentState

///|
pub type PrimitiveState = @render_resource.PrimitiveState

///|
pub type DepthStencilState = @render_resource.DepthStencilState

///|
pub type MultisampleState = @render_resource.MultisampleState

///|
pub type RenderPipelineDescriptor = @render_resource.RenderPipelineDescriptor

///|
pub type NoFragmentStateError = @render_resource.NoFragmentStateError

///|
pub type ComputePipelineDescriptor = @render_resource.ComputePipelineDescriptor

///|
pub type PipelineDescriptor = @render_resource.PipelineDescriptor

///|
pub type CachedRenderPipelineId = @render_resource.CachedRenderPipelineId

///|
pub type CachedComputePipelineId = @render_resource.CachedComputePipelineId
