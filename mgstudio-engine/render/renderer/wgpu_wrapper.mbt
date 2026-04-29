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
/// Bevy source: `bevy/crates/bevy_render/src/renderer/wgpu_wrapper.rs`.
///
/// Native MoonBit builds do not need the wasm atomics `SendWrapper` branch,
/// so this is a direct transparent wrapper. Keeping the wrapper in the public
/// renderer model lets `RenderDevice`, `RenderQueue`, and render-context state
/// follow the same ownership shape as Bevy.
pub struct WgpuWrapper[T] {
  mut value : T
}

///|
pub fn[T] WgpuWrapper::new(value : T) -> WgpuWrapper[T] {
  { value, }
}

///|
pub fn[T] WgpuWrapper::get(self : WgpuWrapper[T]) -> T {
  self.value
}

///|
pub fn[T] WgpuWrapper::set(self : WgpuWrapper[T], value : T) -> Unit {
  self.value = value
}

///|
pub fn[T] WgpuWrapper::into_inner(self : WgpuWrapper[T]) -> T {
  self.value
}

///|
pub extern "C" fn pipeline_layout_descriptor_3_new(
  bind_group_layout0 : @wgpu_c.WGPUBindGroupLayout,
  bind_group_layout1 : @wgpu_c.WGPUBindGroupLayout,
  bind_group_layout2 : @wgpu_c.WGPUBindGroupLayout,
) -> @wgpu_c.WGPUPipelineLayoutDescriptorPtr = "mgstudio_pipeline_layout_descriptor_3_new"

///|
pub extern "C" fn pipeline_layout_descriptor_4_new(
  bind_group_layout0 : @wgpu_c.WGPUBindGroupLayout,
  bind_group_layout1 : @wgpu_c.WGPUBindGroupLayout,
  bind_group_layout2 : @wgpu_c.WGPUBindGroupLayout,
  bind_group_layout3 : @wgpu_c.WGPUBindGroupLayout,
) -> @wgpu_c.WGPUPipelineLayoutDescriptorPtr = "mgstudio_pipeline_layout_descriptor_4_new"

///|
#borrow(descriptor)
extern "C" fn render_pipeline_descriptor_set_cull_mode_native(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
  cull_mode : UInt,
) -> UInt = "mgstudio_render_pipeline_descriptor_set_cull_mode"

///|
#borrow(descriptor, fragment_module)
extern "C" fn render_pipeline_descriptor_set_fragment_module_native(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
  fragment_module : @wgpu_c.WGPUShaderModule,
) -> UInt = "mgstudio_render_pipeline_descriptor_set_fragment_module"

///|
#borrow(descriptor, vertex_module)
extern "C" fn render_pipeline_descriptor_set_vertex_module_native(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
  vertex_module : @wgpu_c.WGPUShaderModule,
) -> UInt = "mgstudio_render_pipeline_descriptor_set_vertex_module"

///|
#borrow(descriptor)
extern "C" fn render_pipeline_descriptor_clear_fragment_native(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
) -> UInt = "mgstudio_render_pipeline_descriptor_clear_fragment"

///|
#borrow(descriptor)
extern "C" fn render_pipeline_descriptor_set_fragment_target_count_zero_native(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
) -> UInt = "mgstudio_render_pipeline_descriptor_set_fragment_target_count_zero"

///|
#borrow(depth_view)
extern "C" fn render_pass_descriptor_depth_new_native(
  depth_view : @wgpu_c.WGPUTextureView,
  depth_load_op_u32 : UInt,
  depth_store_op_u32 : UInt,
  depth_clear_value_f32 : Float,
  stencil_load_op_u32 : UInt,
  stencil_store_op_u32 : UInt,
  stencil_clear_value_u32 : UInt,
  depth_read_only : Bool,
  stencil_read_only : Bool,
) -> @wgpu_c.WGPURenderPassDescriptorPtr = "mgstudio_render_pass_descriptor_depth_new"

///|
fn render_pipeline_descriptor_set_cull_mode(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
  cull_mode : UInt,
) -> Unit {
  let err = render_pipeline_descriptor_set_cull_mode_native(
    descriptor, cull_mode,
  )
  if err != 0U {
    abort("wgpu: failed to configure mesh pipeline cull mode")
  }
}

///|
fn render_pipeline_descriptor_set_fragment_module(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
  fragment_module : @wgpu.ShaderModule,
) -> Unit {
  let err = render_pipeline_descriptor_set_fragment_module_native(
    descriptor,
    fragment_module.raw_handle(),
  )
  if err != 0U {
    abort("wgpu: failed to configure mesh pipeline fragment shader module")
  }
}

///|
fn render_pipeline_descriptor_set_vertex_module(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
  vertex_module : @wgpu.ShaderModule,
) -> Unit {
  let err = render_pipeline_descriptor_set_vertex_module_native(
    descriptor,
    vertex_module.raw_handle(),
  )
  if err != 0U {
    abort("wgpu: failed to configure mesh pipeline vertex shader module")
  }
}

///|
fn render_pipeline_descriptor_clear_fragment(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
) -> Unit {
  let err = render_pipeline_descriptor_clear_fragment_native(descriptor)
  if err != 0U {
    abort("wgpu: failed to clear mesh pipeline fragment state")
  }
}

///|
fn render_pipeline_descriptor_set_fragment_target_count_zero(
  descriptor : @wgpu_c.WGPURenderPipelineDescriptorPtr,
) -> Unit {
  let err = render_pipeline_descriptor_set_fragment_target_count_zero_native(
    descriptor,
  )
  if err != 0U {
    abort("wgpu: failed to configure zero color targets")
  }
}

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

///|
fn command_encoder_begin_render_pass_depth_u32(
  encoder : @wgpu.CommandEncoder,
  depth_view : @wgpu.TextureView,
  depth_load_op_u32~ : UInt,
  depth_store_op_u32~ : UInt,
  depth_clear_value_f32~ : Float,
  stencil_load_op_u32~ : UInt,
  stencil_store_op_u32~ : UInt,
  stencil_clear_value_u32~ : UInt,
  depth_read_only~ : Bool,
  stencil_read_only~ : Bool,
) -> @wgpu.RenderPass {
  let descriptor = render_pass_descriptor_depth_new_native(
    depth_view.raw_handle(),
    depth_load_op_u32,
    depth_store_op_u32,
    depth_clear_value_f32,
    stencil_load_op_u32,
    stencil_store_op_u32,
    stencil_clear_value_u32,
    depth_read_only,
    stencil_read_only,
  )
  let pass = encoder.begin_render_pass_ptr(descriptor)
  @wgpu_c.render_pass_descriptor_free(descriptor)
  pass
}

///|
fn create_pipeline_layout_4(
  device : @wgpu.Device,
  bind_group_layout0 : @wgpu.BindGroupLayout,
  bind_group_layout1 : @wgpu.BindGroupLayout,
  bind_group_layout2 : @wgpu.BindGroupLayout,
  bind_group_layout3 : @wgpu.BindGroupLayout,
) -> @wgpu.PipelineLayout {
  let descriptor = pipeline_layout_descriptor_4_new(
    bind_group_layout0.raw_handle(),
    bind_group_layout1.raw_handle(),
    bind_group_layout2.raw_handle(),
    bind_group_layout3.raw_handle(),
  )
  let layout = device.create_pipeline_layout_ptr(descriptor)
  @wgpu_c.pipeline_layout_descriptor_free(descriptor)
  layout
}
