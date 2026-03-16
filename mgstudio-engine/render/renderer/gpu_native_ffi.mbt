// Copyright 2025 International Digital Economy Academy
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
pub extern "C" fn pipeline_layout_descriptor_3_new(
  bind_group_layout0 : @wgpu_c.WGPUBindGroupLayout,
  bind_group_layout1 : @wgpu_c.WGPUBindGroupLayout,
  bind_group_layout2 : @wgpu_c.WGPUBindGroupLayout,
) -> @wgpu_c.WGPUPipelineLayoutDescriptorPtr = "mgstudio_pipeline_layout_descriptor_3_new"

///|
fn create_pipeline_layout_3(
  device : @wgpu.Device,
  bind_group_layout0 : @wgpu.BindGroupLayout,
  bind_group_layout1 : @wgpu.BindGroupLayout,
  bind_group_layout2 : @wgpu.BindGroupLayout,
) -> @wgpu.PipelineLayout {
  let descriptor = pipeline_layout_descriptor_3_new(
    bind_group_layout0.raw_handle(),
    bind_group_layout1.raw_handle(),
    bind_group_layout2.raw_handle(),
  )
  let layout = device.create_pipeline_layout_ptr(descriptor)
  @wgpu_c.pipeline_layout_descriptor_free(descriptor)
  layout
}
