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
/// Typed helpers for WebGPU descriptor objects.

///|
pub(all) enum LoadOp {
  Clear
}

///|
pub fn LoadOp::to_js_string(self : LoadOp) -> String {
  match self {
    Clear => "clear"
  }
}

///|
pub(all) enum StoreOp {
  Store
}

///|
pub fn StoreOp::to_js_string(self : StoreOp) -> String {
  match self {
    Store => "store"
  }
}

///|
pub(all) enum TextureFormat {
  Rgba8Unorm
  Bgra8Unorm
  Other(String)
}

///|
pub fn texture_format_from_string(value : String) -> TextureFormat {
  if value == "rgba8unorm" {
    Rgba8Unorm
  } else if value == "bgra8unorm" {
    Bgra8Unorm
  } else {
    Other(value)
  }
}

///|
pub fn TextureFormat::to_js_string(self : TextureFormat) -> String {
  match self {
    Rgba8Unorm => "rgba8unorm"
    Bgra8Unorm => "bgra8unorm"
    Other(value) => value
  }
}

///|
pub(all) enum AlphaMode {
  Premultiplied
}

///|
pub fn AlphaMode::to_js_string(self : AlphaMode) -> String {
  match self {
    Premultiplied => "premultiplied"
  }
}

///|
pub(all) enum FilterMode {
  Linear
  Nearest
}

///|
pub fn FilterMode::to_js_string(self : FilterMode) -> String {
  match self {
    Linear => "linear"
    Nearest => "nearest"
  }
}

///|
pub(all) enum BlendFactor {
  SrcAlpha
  OneMinusSrcAlpha
}

///|
pub fn BlendFactor::to_js_string(self : BlendFactor) -> String {
  match self {
    SrcAlpha => "src-alpha"
    OneMinusSrcAlpha => "one-minus-src-alpha"
  }
}

///|
pub(all) enum BlendOperation {
  Add
}

///|
pub fn BlendOperation::to_js_string(self : BlendOperation) -> String {
  match self {
    Add => "add"
  }
}

///|
pub(all) enum PrimitiveTopology {
  TriangleList
}

///|
pub fn PrimitiveTopology::to_js_string(self : PrimitiveTopology) -> String {
  match self {
    TriangleList => "triangle-list"
  }
}

///|
pub(all) enum VertexFormat {
  Float32x2
}

///|
pub fn VertexFormat::to_js_string(self : VertexFormat) -> String {
  match self {
    Float32x2 => "float32x2"
  }
}

///|
pub(all) enum PipelineLayout {
  Auto
}

///|
pub fn PipelineLayout::to_js(self : PipelineLayout) -> @js.Any {
  match self {
    Auto => @js.any("auto")
  }
}

///|
pub struct Color {
  r : Double
  g : Double
  b : Double
  a : Double
}

///|
pub fn color(r : Double, g : Double, b : Double, a : Double) -> Color {
  Color::{ r, g, b, a }
}

///|
pub fn Color::to_js(self : Color) -> @js.Any {
  @js.from_entries([
    ("r", @js.any(self.r)),
    ("g", @js.any(self.g)),
    ("b", @js.any(self.b)),
    ("a", @js.any(self.a)),
  ])
}

///|
pub struct ColorAttachment {
  view : GPUTextureView
  clear : Color
  load_op : LoadOp
  store_op : StoreOp
}

///|
pub fn color_attachment_clear(
  view : GPUTextureView,
  clear : Color,
) -> ColorAttachment {
  ColorAttachment::{ view, clear, load_op: Clear, store_op: Store }
}

///|
pub fn ColorAttachment::to_js(self : ColorAttachment) -> @js.Any {
  @js.from_entries([
    ("view", self.view.as_any()),
    ("clearValue", self.clear.to_js()),
    ("loadOp", @js.any(self.load_op.to_js_string())),
    ("storeOp", @js.any(self.store_op.to_js_string())),
  ])
}

///|
pub struct RenderPassDescriptor {
  color_attachments : Array[ColorAttachment]
}

///|
pub fn render_pass_descriptor(
  color_attachments : Array[ColorAttachment],
) -> RenderPassDescriptor {
  RenderPassDescriptor::{ color_attachments, }
}

///|
pub fn RenderPassDescriptor::to_js(self : RenderPassDescriptor) -> @js.Any {
  let attachments : Array[@js.Any] = []
  for attachment in self.color_attachments {
    attachments.push(attachment.to_js())
  }
  @js.from_entries([("colorAttachments", @js.any(attachments))])
}

///|
pub struct SurfaceSize {
  width : Int
  height : Int
}

///|
pub fn surface_size(width : Int, height : Int) -> SurfaceSize {
  SurfaceSize::{ width, height }
}

///|
pub fn SurfaceSize::to_js(self : SurfaceSize) -> @js.Any {
  @js.any([self.width, self.height])
}

///|
pub struct SurfaceConfiguration {
  device : GPUDevice
  format : TextureFormat
  alpha_mode : AlphaMode
  usage : Int
  size : SurfaceSize
}

///|
pub fn surface_configuration(
  device : GPUDevice,
  format : TextureFormat,
  alpha_mode : AlphaMode,
  usage : Int,
  size : SurfaceSize,
) -> SurfaceConfiguration {
  SurfaceConfiguration::{ device, format, alpha_mode, usage, size }
}

///|
pub fn SurfaceConfiguration::to_js(self : SurfaceConfiguration) -> @js.Any {
  @js.from_entries([
    ("device", self.device.as_any()),
    ("format", @js.any(self.format.to_js_string())),
    ("alphaMode", @js.any(self.alpha_mode.to_js_string())),
    ("usage", @js.any(self.usage)),
    ("size", self.size.to_js()),
  ])
}

///|
pub struct TextureSize {
  width : Int
  height : Int
  depth_or_array_layers : Int
}

///|
pub fn texture_size(width : Int, height : Int) -> TextureSize {
  TextureSize::{ width, height, depth_or_array_layers: 1 }
}

///|
pub fn TextureSize::to_js(self : TextureSize) -> @js.Any {
  @js.any([self.width, self.height, self.depth_or_array_layers])
}

///|
pub struct TextureDescriptor {
  size : TextureSize
  format : TextureFormat
  usage : Int
}

///|
pub fn texture_descriptor(
  size : TextureSize,
  format : TextureFormat,
  usage : Int,
) -> TextureDescriptor {
  TextureDescriptor::{ size, format, usage }
}

///|
pub fn TextureDescriptor::to_js(self : TextureDescriptor) -> @js.Any {
  @js.from_entries([
    ("size", self.size.to_js()),
    ("format", @js.any(self.format.to_js_string())),
    ("usage", @js.any(self.usage)),
  ])
}

///|
pub struct BufferDescriptor {
  size : Int
  usage : Int
}

///|
pub fn buffer_descriptor(size : Int, usage : Int) -> BufferDescriptor {
  BufferDescriptor::{ size, usage }
}

///|
pub fn BufferDescriptor::to_js(self : BufferDescriptor) -> @js.Any {
  @js.from_entries([
    ("size", @js.any(self.size)),
    ("usage", @js.any(self.usage)),
  ])
}

///|
pub struct SamplerDescriptor {
  mag_filter : FilterMode
  min_filter : FilterMode
}

///|
pub fn sampler_descriptor(
  mag_filter : FilterMode,
  min_filter : FilterMode,
) -> SamplerDescriptor {
  SamplerDescriptor::{ mag_filter, min_filter }
}

///|
pub fn SamplerDescriptor::to_js(self : SamplerDescriptor) -> @js.Any {
  @js.from_entries([
    ("magFilter", @js.any(self.mag_filter.to_js_string())),
    ("minFilter", @js.any(self.min_filter.to_js_string())),
  ])
}

///|
pub struct ShaderModuleDescriptor {
  code : String
}

///|
pub fn shader_module_descriptor(code : String) -> ShaderModuleDescriptor {
  ShaderModuleDescriptor::{ code, }
}

///|
pub fn ShaderModuleDescriptor::to_js(self : ShaderModuleDescriptor) -> @js.Any {
  @js.from_entries([("code", @js.any(self.code))])
}

///|
pub struct VertexAttribute {
  shader_location : Int
  offset : Int
  format : VertexFormat
}

///|
pub fn vertex_attribute(
  shader_location : Int,
  offset : Int,
  format : VertexFormat,
) -> VertexAttribute {
  VertexAttribute::{ shader_location, offset, format }
}

///|
pub fn VertexAttribute::to_js(self : VertexAttribute) -> @js.Any {
  @js.from_entries([
    ("shaderLocation", @js.any(self.shader_location)),
    ("offset", @js.any(self.offset)),
    ("format", @js.any(self.format.to_js_string())),
  ])
}

///|
pub struct VertexBufferLayout {
  array_stride : Int
  attributes : Array[VertexAttribute]
}

///|
pub fn vertex_buffer_layout(
  array_stride : Int,
  attributes : Array[VertexAttribute],
) -> VertexBufferLayout {
  VertexBufferLayout::{ array_stride, attributes }
}

///|
pub fn VertexBufferLayout::to_js(self : VertexBufferLayout) -> @js.Any {
  let attrs : Array[@js.Any] = []
  for attr in self.attributes {
    attrs.push(attr.to_js())
  }
  @js.from_entries([
    ("arrayStride", @js.any(self.array_stride)),
    ("attributes", @js.any(attrs)),
  ])
}

///|
pub struct VertexState {
  shader_module : GPUShaderModule
  entry_point : String
  buffers : Array[VertexBufferLayout]
}

///|
pub fn vertex_state(
  shader_module : GPUShaderModule,
  entry_point : String,
  buffers : Array[VertexBufferLayout],
) -> VertexState {
  VertexState::{ shader_module, entry_point, buffers }
}

///|
pub fn VertexState::to_js(self : VertexState) -> @js.Any {
  let buffer_defs : Array[@js.Any] = []
  for buffer_def in self.buffers {
    buffer_defs.push(buffer_def.to_js())
  }
  @js.from_entries([
    ("module", self.shader_module.as_any()),
    ("entryPoint", @js.any(self.entry_point)),
    ("buffers", @js.any(buffer_defs)),
  ])
}

///|
pub struct BlendComponent {
  src_factor : BlendFactor
  dst_factor : BlendFactor
  operation : BlendOperation
}

///|
pub fn blend_component(
  src_factor : BlendFactor,
  dst_factor : BlendFactor,
  operation : BlendOperation,
) -> BlendComponent {
  BlendComponent::{ src_factor, dst_factor, operation }
}

///|
pub fn BlendComponent::to_js(self : BlendComponent) -> @js.Any {
  @js.from_entries([
    ("srcFactor", @js.any(self.src_factor.to_js_string())),
    ("dstFactor", @js.any(self.dst_factor.to_js_string())),
    ("operation", @js.any(self.operation.to_js_string())),
  ])
}

///|
pub struct BlendState {
  color : BlendComponent
  alpha : BlendComponent
}

///|
pub fn blend_state(
  color : BlendComponent,
  alpha : BlendComponent,
) -> BlendState {
  BlendState::{ color, alpha }
}

///|
pub fn BlendState::to_js(self : BlendState) -> @js.Any {
  @js.from_entries([
    ("color", self.color.to_js()),
    ("alpha", self.alpha.to_js()),
  ])
}

///|
pub struct ColorTargetState {
  format : TextureFormat
  blend : BlendState
}

///|
pub fn color_target_state(
  format : TextureFormat,
  blend : BlendState,
) -> ColorTargetState {
  ColorTargetState::{ format, blend }
}

///|
pub fn ColorTargetState::to_js(self : ColorTargetState) -> @js.Any {
  @js.from_entries([
    ("format", @js.any(self.format.to_js_string())),
    ("blend", self.blend.to_js()),
  ])
}

///|
pub struct FragmentState {
  shader_module : GPUShaderModule
  entry_point : String
  targets : Array[ColorTargetState]
}

///|
pub fn fragment_state(
  shader_module : GPUShaderModule,
  entry_point : String,
  targets : Array[ColorTargetState],
) -> FragmentState {
  FragmentState::{ shader_module, entry_point, targets }
}

///|
pub fn FragmentState::to_js(self : FragmentState) -> @js.Any {
  let target_defs : Array[@js.Any] = []
  for target in self.targets {
    target_defs.push(target.to_js())
  }
  @js.from_entries([
    ("module", self.shader_module.as_any()),
    ("entryPoint", @js.any(self.entry_point)),
    ("targets", @js.any(target_defs)),
  ])
}

///|
pub struct PrimitiveState {
  topology : PrimitiveTopology
}

///|
pub fn primitive_state(topology : PrimitiveTopology) -> PrimitiveState {
  PrimitiveState::{ topology, }
}

///|
pub fn PrimitiveState::to_js(self : PrimitiveState) -> @js.Any {
  @js.from_entries([("topology", @js.any(self.topology.to_js_string()))])
}

///|
pub struct RenderPipelineDescriptor {
  layout : PipelineLayout
  vertex : VertexState
  fragment : FragmentState
  primitive : PrimitiveState
}

///|
pub fn render_pipeline_descriptor(
  layout : PipelineLayout,
  vertex : VertexState,
  fragment : FragmentState,
  primitive : PrimitiveState,
) -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{ layout, vertex, fragment, primitive }
}

///|
pub fn RenderPipelineDescriptor::to_js(
  self : RenderPipelineDescriptor,
) -> @js.Any {
  @js.from_entries([
    ("layout", self.layout.to_js()),
    ("vertex", self.vertex.to_js()),
    ("fragment", self.fragment.to_js()),
    ("primitive", self.primitive.to_js()),
  ])
}

///|
pub(all) enum BindGroupResource {
  Sampler(GPUSampler)
  TextureView(GPUTextureView)
  Buffer(GPUBuffer)
}

///|
pub fn BindGroupResource::to_js(self : BindGroupResource) -> @js.Any {
  match self {
    Sampler(value) => value.as_any()
    TextureView(value) => value.as_any()
    Buffer(value) => @js.from_entries([("buffer", value.as_any())])
  }
}

///|
pub struct BindGroupEntry {
  binding : Int
  resource : BindGroupResource
}

///|
pub fn bind_group_entry_sampler(
  binding : Int,
  sampler : GPUSampler,
) -> BindGroupEntry {
  BindGroupEntry::{ binding, resource: Sampler(sampler) }
}

///|
pub fn bind_group_entry_texture(
  binding : Int,
  view : GPUTextureView,
) -> BindGroupEntry {
  BindGroupEntry::{ binding, resource: TextureView(view) }
}

///|
pub fn bind_group_entry_buffer(
  binding : Int,
  buffer : GPUBuffer,
) -> BindGroupEntry {
  BindGroupEntry::{ binding, resource: Buffer(buffer) }
}

///|
pub fn BindGroupEntry::to_js(self : BindGroupEntry) -> @js.Any {
  @js.from_entries([
    ("binding", @js.any(self.binding)),
    ("resource", self.resource.to_js()),
  ])
}

///|
pub struct BindGroupDescriptor {
  layout : GPUBindGroupLayout
  entries : Array[BindGroupEntry]
}

///|
pub fn bind_group_descriptor(
  layout : GPUBindGroupLayout,
  entries : Array[BindGroupEntry],
) -> BindGroupDescriptor {
  BindGroupDescriptor::{ layout, entries }
}

///|
pub fn BindGroupDescriptor::to_js(self : BindGroupDescriptor) -> @js.Any {
  let entry_defs : Array[@js.Any] = []
  for entry in self.entries {
    entry_defs.push(entry.to_js())
  }
  @js.from_entries([
    ("layout", self.layout.as_any()),
    ("entries", @js.any(entry_defs)),
  ])
}
