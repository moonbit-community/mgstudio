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
pub(all) enum ShaderDefVal {
  Flag(String)
  Bool(String, Bool)
  Int(String, Int)
  UInt(String, UInt)
  String(String, String)
}

///|
pub type VertexBufferLayout = @mesh.VertexBufferLayout

///|
pub struct VertexState {
  shader : String?
  shader_defs : Array[ShaderDefVal]
  entry_point : String?
  buffers : Array[VertexBufferLayout]
}

///|
pub fn VertexState::VertexState() -> VertexState {
  { shader: None, shader_defs: [], entry_point: None, buffers: [] }
}

///|
pub fn VertexState::new(
  shader : String?,
  shader_defs : Array[ShaderDefVal],
  entry_point : String?,
  buffers : Array[VertexBufferLayout],
) -> VertexState {
  { shader, shader_defs, entry_point, buffers }
}

///|
pub fn VertexState::shader(self : VertexState) -> String? {
  self.shader
}

///|
pub fn VertexState::shader_defs(self : VertexState) -> Array[ShaderDefVal] {
  self.shader_defs.copy()
}

///|
pub fn VertexState::entry_point(self : VertexState) -> String? {
  self.entry_point
}

///|
pub fn VertexState::buffers(self : VertexState) -> Array[VertexBufferLayout] {
  self.buffers.copy()
}

///|
pub impl Default for VertexState with fn default() {
  VertexState()
}

///|
pub type BlendFactor = UInt

///|
pub type BlendOperation = UInt

///|
pub struct BlendComponent {
  src_factor : BlendFactor
  dst_factor : BlendFactor
  operation : BlendOperation
}

///|
pub fn BlendComponent::BlendComponent(
  src_factor? : BlendFactor = @wgpu.BLEND_FACTOR_ONE,
  dst_factor? : BlendFactor = @wgpu.BLEND_FACTOR_ZERO,
  operation? : BlendOperation = @wgpu.BLEND_OPERATION_ADD,
) -> BlendComponent {
  { src_factor, dst_factor, operation }
}

///|
pub fn BlendComponent::over() -> BlendComponent {
  {
    src_factor: @wgpu.BLEND_FACTOR_ONE,
    dst_factor: @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
    operation: @wgpu.BLEND_OPERATION_ADD,
  }
}

///|
pub fn BlendComponent::src_factor(self : BlendComponent) -> BlendFactor {
  self.src_factor
}

///|
pub fn BlendComponent::dst_factor(self : BlendComponent) -> BlendFactor {
  self.dst_factor
}

///|
pub fn BlendComponent::operation(self : BlendComponent) -> BlendOperation {
  self.operation
}

///|
pub struct BlendState {
  color : BlendComponent
  alpha : BlendComponent
}

///|
pub fn BlendState::BlendState(
  color? : BlendComponent = BlendComponent(),
  alpha? : BlendComponent = BlendComponent(),
) -> BlendState {
  { color, alpha }
}

///|
pub fn BlendState::alpha_blending() -> BlendState {
  { color: BlendComponent::over(), alpha: BlendComponent::over() }
}

///|
pub fn BlendState::premultiplied_alpha_blending() -> BlendState {
  { color: BlendComponent::over(), alpha: BlendComponent::over() }
}

///|
pub fn BlendState::color(self : BlendState) -> BlendComponent {
  self.color
}

///|
pub fn BlendState::alpha(self : BlendState) -> BlendComponent {
  self.alpha
}

///|
pub struct ColorTargetState {
  format : UInt
  blend : BlendState?
  write_mask : UInt64
}

///|
pub fn ColorTargetState::new(
  format : UInt,
  write_mask : UInt64,
  blend? : BlendState? = None,
) -> ColorTargetState {
  { format, blend, write_mask }
}

///|
pub fn ColorTargetState::format(self : ColorTargetState) -> UInt {
  self.format
}

///|
pub fn ColorTargetState::blend(self : ColorTargetState) -> BlendState? {
  self.blend
}

///|
pub fn ColorTargetState::with_blend(
  self : ColorTargetState,
  blend : BlendState?,
) -> ColorTargetState {
  { ..self, blend, }
}

///|
pub fn ColorTargetState::write_mask(self : ColorTargetState) -> UInt64 {
  self.write_mask
}

///|
pub struct FragmentState {
  shader : String?
  shader_defs : Array[ShaderDefVal]
  entry_point : String?
  targets : Array[ColorTargetState?]
}

///|
pub fn FragmentState::FragmentState() -> FragmentState {
  { shader: None, shader_defs: [], entry_point: None, targets: [] }
}

///|
pub fn FragmentState::new(
  shader : String?,
  shader_defs : Array[ShaderDefVal],
  entry_point : String?,
  targets : Array[ColorTargetState?],
) -> FragmentState {
  { shader, shader_defs, entry_point, targets }
}

///|
pub impl Default for FragmentState with fn default() {
  FragmentState()
}

///|
pub fn FragmentState::shader(self : FragmentState) -> String? {
  self.shader
}

///|
pub fn FragmentState::shader_defs(self : FragmentState) -> Array[ShaderDefVal] {
  self.shader_defs.copy()
}

///|
pub fn FragmentState::entry_point(self : FragmentState) -> String? {
  self.entry_point
}

///|
pub fn FragmentState::targets(self : FragmentState) -> Array[ColorTargetState?] {
  self.targets.copy()
}

///|
pub fn FragmentState::with_shader(
  self : FragmentState,
  shader : String?,
) -> FragmentState {
  { ..self, shader, }
}

///|
pub fn FragmentState::with_shader_defs(
  self : FragmentState,
  shader_defs : Array[ShaderDefVal],
) -> FragmentState {
  { ..self, shader_defs, }
}

///|
pub fn FragmentState::with_entry_point(
  self : FragmentState,
  entry_point : String?,
) -> FragmentState {
  { ..self, entry_point, }
}

///|
pub struct PrimitiveState {
  topology : UInt
  strip_index_format : UInt?
  front_face : UInt
  cull_mode : UInt?
  polygon_mode : UInt?
  unclipped_depth : Bool
}

///|
pub fn PrimitiveState::PrimitiveState() -> PrimitiveState {
  {
    topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    strip_index_format: None,
    front_face: @wgpu.FRONT_FACE_CCW,
    cull_mode: None,
    polygon_mode: None,
    unclipped_depth: false,
  }
}

///|
pub impl Default for PrimitiveState with fn default() {
  PrimitiveState()
}

///|
pub fn PrimitiveState::with_polygon_mode(
  self : PrimitiveState,
  polygon_mode : UInt?,
) -> PrimitiveState {
  { ..self, polygon_mode, }
}

///|
pub fn PrimitiveState::with_topology(
  self : PrimitiveState,
  topology : UInt,
) -> PrimitiveState {
  { ..self, topology, }
}

///|
pub fn PrimitiveState::with_strip_index_format(
  self : PrimitiveState,
  strip_index_format : UInt?,
) -> PrimitiveState {
  { ..self, strip_index_format, }
}

///|
pub fn PrimitiveState::with_front_face(
  self : PrimitiveState,
  front_face : UInt,
) -> PrimitiveState {
  { ..self, front_face, }
}

///|
pub fn PrimitiveState::with_cull_mode(
  self : PrimitiveState,
  cull_mode : UInt?,
) -> PrimitiveState {
  { ..self, cull_mode, }
}

///|
pub fn PrimitiveState::with_unclipped_depth(
  self : PrimitiveState,
  unclipped_depth : Bool,
) -> PrimitiveState {
  { ..self, unclipped_depth, }
}

///|
pub struct DepthStencilState {
  format : UInt
  depth_write_enabled : Bool
  depth_compare : UInt
  bias_constant : Int
  bias_slope_scale : Float
  bias_clamp : Float
}

///|
pub fn DepthStencilState::DepthStencilState() -> DepthStencilState {
  {
    format: @wgpu.TEXTURE_FORMAT_DEPTH24_PLUS,
    depth_write_enabled: true,
    depth_compare: @wgpu.COMPARE_FUNCTION_LESS_EQUAL,
    bias_constant: 0,
    bias_slope_scale: 0.0F,
    bias_clamp: 0.0F,
  }
}

///|
pub fn DepthStencilState::new(
  format : UInt,
  depth_write_enabled : Bool,
  depth_compare : UInt,
) -> DepthStencilState {
  {
    format,
    depth_write_enabled,
    depth_compare,
    bias_constant: 0,
    bias_slope_scale: 0.0F,
    bias_clamp: 0.0F,
  }
}

///|
pub fn DepthStencilState::with_bias_constant(
  self : DepthStencilState,
  bias_constant : Int,
) -> DepthStencilState {
  { ..self, bias_constant, }
}

///|
pub fn DepthStencilState::with_bias_slope_scale(
  self : DepthStencilState,
  bias_slope_scale : Float,
) -> DepthStencilState {
  { ..self, bias_slope_scale, }
}

///|
pub fn DepthStencilState::with_bias_clamp(
  self : DepthStencilState,
  bias_clamp : Float,
) -> DepthStencilState {
  { ..self, bias_clamp, }
}

///|
pub impl Default for DepthStencilState with fn default() {
  DepthStencilState()
}

///|
pub struct MultisampleState {
  count : UInt
  mask : UInt64
  alpha_to_coverage_enabled : Bool
}

///|
pub fn MultisampleState::MultisampleState() -> MultisampleState {
  { count: 1U, mask: 0xffffffffffffffffUL, alpha_to_coverage_enabled: false }
}

///|
pub impl Default for MultisampleState with fn default() {
  MultisampleState()
}

///|
pub fn MultisampleState::new(
  count : UInt,
  mask? : UInt64 = 0xffffffffffffffffUL,
  alpha_to_coverage_enabled? : Bool = false,
) -> MultisampleState {
  { count, mask, alpha_to_coverage_enabled }
}

///|
pub fn MultisampleState::count(self : MultisampleState) -> UInt {
  self.count
}

///|
pub struct RenderPipelineDescriptor {
  label : String?
  layout : Array[BindGroupLayoutDescriptor]
  immediate_size : UInt
  vertex : VertexState
  primitive : PrimitiveState
  depth_stencil : DepthStencilState?
  multisample : MultisampleState
  fragment : FragmentState?
  zero_initialize_workgroup_memory : Bool
}

///|
pub fn RenderPipelineDescriptor::RenderPipelineDescriptor() -> RenderPipelineDescriptor {
  {
    label: None,
    layout: [],
    immediate_size: 0U,
    vertex: VertexState(),
    primitive: PrimitiveState(),
    depth_stencil: None,
    multisample: MultisampleState(),
    fragment: None,
    zero_initialize_workgroup_memory: true,
  }
}

///|
pub impl Default for RenderPipelineDescriptor with fn default() {
  RenderPipelineDescriptor()
}

///|
pub fn RenderPipelineDescriptor::label(
  self : RenderPipelineDescriptor,
) -> String? {
  self.label
}

///|
pub fn RenderPipelineDescriptor::layout(
  self : RenderPipelineDescriptor,
) -> Array[BindGroupLayoutDescriptor] {
  self.layout.copy()
}

///|
pub fn RenderPipelineDescriptor::vertex(
  self : RenderPipelineDescriptor,
) -> VertexState {
  self.vertex
}

///|
pub fn RenderPipelineDescriptor::fragment(
  self : RenderPipelineDescriptor,
) -> FragmentState? {
  self.fragment
}

///|
pub fn RenderPipelineDescriptor::with_label(
  self : RenderPipelineDescriptor,
  label : String?,
) -> RenderPipelineDescriptor {
  { ..self, label, }
}

///|
pub fn RenderPipelineDescriptor::with_layout(
  self : RenderPipelineDescriptor,
  layout : Array[BindGroupLayoutDescriptor],
) -> RenderPipelineDescriptor {
  { ..self, layout, }
}

///|
pub fn RenderPipelineDescriptor::with_vertex(
  self : RenderPipelineDescriptor,
  vertex : VertexState,
) -> RenderPipelineDescriptor {
  { ..self, vertex, }
}

///|
pub fn RenderPipelineDescriptor::with_fragment(
  self : RenderPipelineDescriptor,
  fragment : FragmentState?,
) -> RenderPipelineDescriptor {
  { ..self, fragment, }
}

///|
pub fn RenderPipelineDescriptor::with_depth_stencil(
  self : RenderPipelineDescriptor,
  depth_stencil : DepthStencilState?,
) -> RenderPipelineDescriptor {
  { ..self, depth_stencil, }
}

///|
pub fn RenderPipelineDescriptor::with_immediate_size(
  self : RenderPipelineDescriptor,
  immediate_size : UInt,
) -> RenderPipelineDescriptor {
  { ..self, immediate_size, }
}

///|
pub fn RenderPipelineDescriptor::with_primitive(
  self : RenderPipelineDescriptor,
  primitive : PrimitiveState,
) -> RenderPipelineDescriptor {
  { ..self, primitive, }
}

///|
pub fn RenderPipelineDescriptor::with_multisample(
  self : RenderPipelineDescriptor,
  multisample : MultisampleState,
) -> RenderPipelineDescriptor {
  { ..self, multisample, }
}

///|
pub suberror NoFragmentStateError {
  NoFragmentStateConfigured
}

///|
pub fn RenderPipelineDescriptor::fragment_or_error(
  self : RenderPipelineDescriptor,
) -> FragmentState raise NoFragmentStateError {
  match self.fragment {
    Some(fragment) => fragment
    None => raise NoFragmentStateConfigured
  }
}

///|
pub struct ComputePipelineDescriptor {
  label : String?
  layout : Array[BindGroupLayoutDescriptor]
  immediate_size : UInt
  shader : String?
  shader_defs : Array[ShaderDefVal]
  entry_point : String?
  zero_initialize_workgroup_memory : Bool
}

///|
pub fn ComputePipelineDescriptor::ComputePipelineDescriptor() -> ComputePipelineDescriptor {
  {
    label: None,
    layout: [],
    immediate_size: 0U,
    shader: None,
    shader_defs: [],
    entry_point: None,
    zero_initialize_workgroup_memory: true,
  }
}

///|
pub impl Default for ComputePipelineDescriptor with fn default() {
  ComputePipelineDescriptor()
}

///|
pub fn ComputePipelineDescriptor::label(
  self : ComputePipelineDescriptor,
) -> String? {
  self.label
}

///|
pub fn ComputePipelineDescriptor::layout(
  self : ComputePipelineDescriptor,
) -> Array[BindGroupLayoutDescriptor] {
  self.layout.copy()
}

///|
pub fn ComputePipelineDescriptor::shader(
  self : ComputePipelineDescriptor,
) -> String? {
  self.shader
}

///|
pub fn ComputePipelineDescriptor::entry_point(
  self : ComputePipelineDescriptor,
) -> String? {
  self.entry_point
}

///|
pub fn ComputePipelineDescriptor::shader_defs(
  self : ComputePipelineDescriptor,
) -> Array[ShaderDefVal] {
  self.shader_defs.copy()
}

///|
pub fn ComputePipelineDescriptor::with_label(
  self : ComputePipelineDescriptor,
  label : String?,
) -> ComputePipelineDescriptor {
  { ..self, label, }
}

///|
pub fn ComputePipelineDescriptor::with_layout(
  self : ComputePipelineDescriptor,
  layout : Array[BindGroupLayoutDescriptor],
) -> ComputePipelineDescriptor {
  { ..self, layout, }
}

///|
pub fn ComputePipelineDescriptor::with_shader(
  self : ComputePipelineDescriptor,
  shader : String?,
) -> ComputePipelineDescriptor {
  { ..self, shader, }
}

///|
pub fn ComputePipelineDescriptor::with_shader_defs(
  self : ComputePipelineDescriptor,
  shader_defs : Array[ShaderDefVal],
) -> ComputePipelineDescriptor {
  { ..self, shader_defs, }
}

///|
pub fn ComputePipelineDescriptor::with_entry_point(
  self : ComputePipelineDescriptor,
  entry_point : String?,
) -> ComputePipelineDescriptor {
  { ..self, entry_point, }
}

///|
pub fn ComputePipelineDescriptor::with_immediate_size(
  self : ComputePipelineDescriptor,
  immediate_size : UInt,
) -> ComputePipelineDescriptor {
  { ..self, immediate_size, }
}

///|
pub fn ComputePipelineDescriptor::with_zero_initialize_workgroup_memory(
  self : ComputePipelineDescriptor,
  zero_initialize_workgroup_memory : Bool,
) -> ComputePipelineDescriptor {
  { ..self, zero_initialize_workgroup_memory, }
}

///|
fn[T] filling_set_at(
  vec : Array[T],
  index : Int,
  filler : T,
  value : T,
) -> Unit {
  if index < 0 {
    abort("index must be non-negative")
  }
  let fill_count = index + 1 - vec.length()
  if fill_count > 0 {
    for _ in 0..<fill_count {
      vec.push(filler)
    }
  }
  vec[index] = value
}

///|
pub fn RenderPipelineDescriptor::set_layout(
  self : RenderPipelineDescriptor,
  index : Int,
  layout : BindGroupLayoutDescriptor,
) -> RenderPipelineDescriptor {
  let next_layout = self.layout
  filling_set_at(next_layout, index, BindGroupLayoutDescriptor(), layout)
  { ..self, layout: next_layout }
}

///|
pub fn FragmentState::set_target(
  self : FragmentState,
  index : Int,
  target : ColorTargetState,
) -> FragmentState {
  let next_targets = self.targets
  filling_set_at(next_targets, index, None, Some(target))
  { ..self, targets: next_targets }
}

///|
pub(all) enum PipelineDescriptor {
  RenderPipelineDescriptor(RenderPipelineDescriptor)
  ComputePipelineDescriptor(ComputePipelineDescriptor)
}

///|
pub struct CachedRenderPipelineId {
  id : UInt64
}

///|
pub fn CachedRenderPipelineId::invalid() -> CachedRenderPipelineId {
  { id: 0xffffffffffffffffUL }
}

///|
pub fn CachedRenderPipelineId::new(id : UInt64) -> CachedRenderPipelineId {
  { id, }
}

///|
pub fn CachedRenderPipelineId::id(self : CachedRenderPipelineId) -> UInt64 {
  self.id
}

///|
pub struct CachedComputePipelineId {
  id : UInt64
}

///|
pub fn CachedComputePipelineId::invalid() -> CachedComputePipelineId {
  { id: 0xffffffffffffffffUL }
}

///|
pub fn CachedComputePipelineId::new(id : UInt64) -> CachedComputePipelineId {
  { id, }
}

///|
pub fn CachedComputePipelineId::id(self : CachedComputePipelineId) -> UInt64 {
  self.id
}
