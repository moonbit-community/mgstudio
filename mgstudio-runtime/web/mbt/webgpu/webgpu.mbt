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
/// Minimal WebGPU FFI bindings for browser runtime.

///|
#external
pub type GPU

///|
pub fn GPU::as_any(self : GPU) -> @js.Any = "%identity"

///|
#external
pub type GPUAdapter

///|
pub fn GPUAdapter::as_any(self : GPUAdapter) -> @js.Any = "%identity"

///|
#external
pub type GPUDevice

///|
pub fn GPUDevice::as_any(self : GPUDevice) -> @js.Any = "%identity"

///|
#external
pub type GPUQueue

///|
pub fn GPUQueue::as_any(self : GPUQueue) -> @js.Any = "%identity"

///|
#external
pub type GPUCanvasContext

///|
pub fn GPUCanvasContext::as_any(self : GPUCanvasContext) -> @js.Any = "%identity"

///|
#external
pub type GPUBuffer

///|
pub fn GPUBuffer::as_any(self : GPUBuffer) -> @js.Any = "%identity"

///|
#external
pub type GPUTexture

///|
pub fn GPUTexture::as_any(self : GPUTexture) -> @js.Any = "%identity"

///|
#external
pub type GPUTextureView

///|
pub fn GPUTextureView::as_any(self : GPUTextureView) -> @js.Any = "%identity"

///|
#external
pub type GPUCommandEncoder

///|
pub fn GPUCommandEncoder::as_any(self : GPUCommandEncoder) -> @js.Any = "%identity"

///|
#external
pub type GPURenderPassEncoder

///|
pub fn GPURenderPassEncoder::as_any(self : GPURenderPassEncoder) -> @js.Any = "%identity"

///|
#external
pub type GPURenderPipeline

///|
pub fn GPURenderPipeline::as_any(self : GPURenderPipeline) -> @js.Any = "%identity"

///|
pub fn GPURenderPipeline::get_bind_group_layout(
  self : GPURenderPipeline,
  index : Int,
) -> GPUBindGroupLayout {
  self.as_any()._call("getBindGroupLayout", [@js.any(index)]).cast()
}

///|
#external
pub type GPUShaderModule

///|
pub fn GPUShaderModule::as_any(self : GPUShaderModule) -> @js.Any = "%identity"

///|
#external
pub type GPUSampler

///|
pub fn GPUSampler::as_any(self : GPUSampler) -> @js.Any = "%identity"

///|
#external
pub type GPUBindGroup

///|
pub fn GPUBindGroup::as_any(self : GPUBindGroup) -> @js.Any = "%identity"

///|
#external
pub type GPUBindGroupLayout

///|
pub fn GPUBindGroupLayout::as_any(self : GPUBindGroupLayout) -> @js.Any = "%identity"

///|
#external
pub type GPUPipelineLayout

///|
pub fn GPUPipelineLayout::as_any(self : GPUPipelineLayout) -> @js.Any = "%identity"

///|
extern "js" fn gpu_raw() -> GPU =
  #| () => navigator.gpu

///|
pub fn gpu() -> GPU {
  gpu_raw()
}

///|
extern "js" fn preferred_canvas_format_raw() -> String =
  #| () => {
  #|   const gpu = navigator.gpu
  #|   if (!gpu || typeof gpu.getPreferredCanvasFormat !== "function") {
  #|     return ""
  #|   }
  #|   const format = gpu.getPreferredCanvasFormat()
  #|   return typeof format === "string" ? format : ""
  #| }

///|
pub fn preferred_canvas_format() -> String {
  preferred_canvas_format_raw()
}

///|
extern "js" fn texture_usage_raw() -> @js.Any =
  #| () => GPUTextureUsage

///|
extern "js" fn buffer_usage_raw() -> @js.Any =
  #| () => GPUBufferUsage

///|
extern "js" fn shader_stage_raw() -> @js.Any =
  #| () => GPUShaderStage

///|
pub fn texture_usage_render_attachment() -> Int {
  texture_usage_raw()._get("RENDER_ATTACHMENT").cast()
}

///|
pub fn texture_usage_texture_binding() -> Int {
  texture_usage_raw()._get("TEXTURE_BINDING").cast()
}

///|
pub fn texture_usage_copy_dst() -> Int {
  texture_usage_raw()._get("COPY_DST").cast()
}

///|
pub fn buffer_usage_vertex() -> Int {
  buffer_usage_raw()._get("VERTEX").cast()
}

///|
pub fn buffer_usage_uniform() -> Int {
  buffer_usage_raw()._get("UNIFORM").cast()
}

///|
pub fn buffer_usage_copy_dst() -> Int {
  buffer_usage_raw()._get("COPY_DST").cast()
}

///|
pub fn buffer_usage_storage() -> Int {
  buffer_usage_raw()._get("STORAGE").cast()
}

///|
pub fn shader_stage_vertex() -> Int {
  shader_stage_raw()._get("VERTEX").cast()
}

///|
pub fn shader_stage_fragment() -> Int {
  shader_stage_raw()._get("FRAGMENT").cast()
}

///|
extern "js" fn bit_or(a : Int, b : Int) -> Int =
  #| (a, b) => a | b

///|
pub fn combine_flags(a : Int, b : Int) -> Int {
  bit_or(a, b)
}

///|
extern "js" fn request_adapter_raw(
  gpu : GPU,
  options : @js.Any,
) -> @js.Promise[GPUAdapter] =
  #| (gpu, options) => gpu.requestAdapter(options)

///|
pub async fn request_adapter(
  power_preference? : String,
  force_fallback_adapter? : Bool,
) -> GPUAdapter {
  let options = @js.new_object()
  if power_preference is Some(value) {
    options._set("powerPreference", @js.any(value)) |> ignore
  }
  if force_fallback_adapter is Some(value) {
    options._set("forceFallbackAdapter", @js.any(value)) |> ignore
  }
  let options_value = if power_preference is None &&
    force_fallback_adapter is None {
    @js.undefined()
  } else {
    options
  }
  request_adapter_raw(gpu_raw(), options_value).wait()
}

///|
extern "js" fn request_device_raw(
  adapter : GPUAdapter,
  descriptor : @js.Any,
) -> @js.Promise[GPUDevice] =
  #| (adapter, descriptor) => adapter.requestDevice(descriptor)

///|
pub async fn request_device(
  adapter : GPUAdapter,
  descriptor? : @js.Any,
) -> GPUDevice {
  let descriptor_value = match descriptor {
    Some(value) => value
    None => @js.undefined()
  }
  request_device_raw(adapter, descriptor_value).wait()
}

///|
pub fn GPUDevice::queue(self : GPUDevice) -> GPUQueue {
  self.as_any()._get("queue").cast()
}

///|
pub fn GPUDevice::create_buffer(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPUBuffer {
  self.as_any()._call("createBuffer", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_texture(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPUTexture {
  self.as_any()._call("createTexture", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_sampler(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPUSampler {
  self.as_any()._call("createSampler", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_bind_group_layout(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPUBindGroupLayout {
  self.as_any()._call("createBindGroupLayout", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_bind_group(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPUBindGroup {
  self.as_any()._call("createBindGroup", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_pipeline_layout(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPUPipelineLayout {
  self.as_any()._call("createPipelineLayout", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_shader_module(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPUShaderModule {
  self.as_any()._call("createShaderModule", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_render_pipeline(
  self : GPUDevice,
  descriptor : @js.Any,
) -> GPURenderPipeline {
  self.as_any()._call("createRenderPipeline", [descriptor]).cast()
}

///|
pub fn GPUDevice::create_command_encoder(
  self : GPUDevice,
  descriptor? : @js.Any,
) -> GPUCommandEncoder {
  let value = match descriptor {
    Some(desc) => desc
    None => @js.undefined()
  }
  self.as_any()._call("createCommandEncoder", [value]).cast()
}

///|
pub fn GPUCommandEncoder::begin_render_pass(
  self : GPUCommandEncoder,
  descriptor : @js.Any,
) -> GPURenderPassEncoder {
  self.as_any()._call("beginRenderPass", [descriptor]).cast()
}

///|
pub fn GPUCommandEncoder::finish(self : GPUCommandEncoder) -> @js.Any {
  self.as_any()._call("finish", [])
}

///|
pub fn GPUQueue::submit(
  self : GPUQueue,
  command_buffers : Array[@js.Any],
) -> Unit {
  self.as_any()._call("submit", [@js.any(command_buffers)]) |> ignore
}

///|
pub fn GPUQueue::write_buffer(
  self : GPUQueue,
  buffer : GPUBuffer,
  offset : Int,
  data : @js.Any,
) -> Unit {
  self.as_any()._call("writeBuffer", [buffer.as_any(), @js.any(offset), data])
  |> ignore
}

///|
pub fn GPUTexture::create_view(
  self : GPUTexture,
  descriptor? : @js.Any,
) -> GPUTextureView {
  let value = match descriptor {
    Some(desc) => desc
    None => @js.undefined()
  }
  self.as_any()._call("createView", [value]).cast()
}

///|
extern "js" fn canvas_get_context(canvas : @js.Any) -> GPUCanvasContext =
  #| (canvas) => canvas.getContext("webgpu")

///|
pub fn get_canvas_context(canvas : @js.Any) -> GPUCanvasContext {
  canvas_get_context(canvas)
}

///|
pub fn GPUCanvasContext::configure(
  self : GPUCanvasContext,
  descriptor : @js.Any,
) -> Unit {
  self.as_any()._call("configure", [descriptor]) |> ignore
}

///|
pub fn GPUCanvasContext::get_current_texture(
  self : GPUCanvasContext,
) -> GPUTexture {
  self.as_any()._call("getCurrentTexture", []).cast()
}

///|
pub fn GPURenderPassEncoder::set_pipeline(
  self : GPURenderPassEncoder,
  pipeline : GPURenderPipeline,
) -> Unit {
  self.as_any()._call("setPipeline", [pipeline.as_any()]) |> ignore
}

///|
pub fn GPURenderPassEncoder::set_bind_group(
  self : GPURenderPassEncoder,
  index : Int,
  bind_group : GPUBindGroup,
) -> Unit {
  self.as_any()._call("setBindGroup", [@js.any(index), bind_group.as_any()])
  |> ignore
}

///|
pub fn GPURenderPassEncoder::set_vertex_buffer(
  self : GPURenderPassEncoder,
  slot : Int,
  buffer : GPUBuffer,
) -> Unit {
  self.as_any()._call("setVertexBuffer", [@js.any(slot), buffer.as_any()])
  |> ignore
}

///|
pub fn GPURenderPassEncoder::set_viewport(
  self : GPURenderPassEncoder,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
  min_depth : Double,
  max_depth : Double,
) -> Unit {
  self
  .as_any()
  ._call("setViewport", [
    @js.any(x),
    @js.any(y),
    @js.any(width),
    @js.any(height),
    @js.any(min_depth),
    @js.any(max_depth),
  ])
  |> ignore
}

///|
pub fn GPURenderPassEncoder::set_scissor_rect(
  self : GPURenderPassEncoder,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit {
  self
  .as_any()
  ._call("setScissorRect", [
    @js.any(x),
    @js.any(y),
    @js.any(width),
    @js.any(height),
  ])
  |> ignore
}

///|
pub fn GPURenderPassEncoder::draw(
  self : GPURenderPassEncoder,
  vertex_count : Int,
  instance_count : Int,
  first_vertex : Int,
  first_instance : Int,
) -> Unit {
  self
  .as_any()
  ._call("draw", [
    @js.any(vertex_count),
    @js.any(instance_count),
    @js.any(first_vertex),
    @js.any(first_instance),
  ])
  |> ignore
}

///|
pub fn GPURenderPassEncoder::end(self : GPURenderPassEncoder) -> Unit {
  self.as_any()._call("end", []) |> ignore
}
