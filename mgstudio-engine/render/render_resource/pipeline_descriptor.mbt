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
  VertexState::{ shader: None, shader_defs: [], entry_point: None, buffers: [] }
}

///|
pub fn VertexState::new(
  shader : String?,
  shader_defs : Array[ShaderDefVal],
  entry_point : String?,
  buffers : Array[VertexBufferLayout],
) -> VertexState {
  VertexState::{ shader, shader_defs, entry_point, buffers }
}

///|
pub impl Default for VertexState with fn default() {
  VertexState::VertexState()
}

///|
pub struct ColorTargetState {
  format : UInt
  write_mask : UInt64
}

///|
pub fn ColorTargetState::new(
  format : UInt,
  write_mask : UInt64,
) -> ColorTargetState {
  ColorTargetState::{ format, write_mask }
}

///|
pub fn ColorTargetState::format(self : ColorTargetState) -> UInt {
  self.format
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
  FragmentState::{
    shader: None,
    shader_defs: [],
    entry_point: None,
    targets: [],
  }
}

///|
pub fn FragmentState::new(
  shader : String?,
  shader_defs : Array[ShaderDefVal],
  entry_point : String?,
  targets : Array[ColorTargetState?],
) -> FragmentState {
  FragmentState::{ shader, shader_defs, entry_point, targets }
}

///|
pub impl Default for FragmentState with fn default() {
  FragmentState::FragmentState()
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
  FragmentState::{ ..self, shader, }
}

///|
pub fn FragmentState::with_shader_defs(
  self : FragmentState,
  shader_defs : Array[ShaderDefVal],
) -> FragmentState {
  FragmentState::{ ..self, shader_defs, }
}

///|
pub fn FragmentState::with_entry_point(
  self : FragmentState,
  entry_point : String?,
) -> FragmentState {
  FragmentState::{ ..self, entry_point, }
}

///|
pub struct PrimitiveState {
  topology : UInt
  strip_index_format : UInt?
  front_face : UInt
  cull_mode : UInt?
  polygon_mode : UInt?
}

///|
pub fn PrimitiveState::PrimitiveState() -> PrimitiveState {
  PrimitiveState::{
    topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    strip_index_format: None,
    front_face: @wgpu.FRONT_FACE_CCW,
    cull_mode: Some(@wgpu.CULL_MODE_BACK),
    polygon_mode: None,
  }
}

///|
pub impl Default for PrimitiveState with fn default() {
  PrimitiveState::PrimitiveState()
}

///|
pub fn PrimitiveState::with_polygon_mode(
  self : PrimitiveState,
  polygon_mode : UInt?,
) -> PrimitiveState {
  PrimitiveState::{ ..self, polygon_mode, }
}

///|
pub fn PrimitiveState::with_topology(
  self : PrimitiveState,
  topology : UInt,
) -> PrimitiveState {
  PrimitiveState::{ ..self, topology, }
}

///|
pub fn PrimitiveState::with_strip_index_format(
  self : PrimitiveState,
  strip_index_format : UInt?,
) -> PrimitiveState {
  PrimitiveState::{ ..self, strip_index_format, }
}

///|
pub fn PrimitiveState::with_front_face(
  self : PrimitiveState,
  front_face : UInt,
) -> PrimitiveState {
  PrimitiveState::{ ..self, front_face, }
}

///|
pub fn PrimitiveState::with_cull_mode(
  self : PrimitiveState,
  cull_mode : UInt?,
) -> PrimitiveState {
  PrimitiveState::{ ..self, cull_mode, }
}

///|
pub struct DepthStencilState {
  format : UInt
  depth_write_enabled : Bool
  depth_compare : UInt
  bias_slope_scale : Float
}

///|
pub fn DepthStencilState::DepthStencilState() -> DepthStencilState {
  DepthStencilState::{
    format: @wgpu.TEXTURE_FORMAT_DEPTH24_PLUS,
    depth_write_enabled: true,
    depth_compare: @wgpu.COMPARE_FUNCTION_LESS_EQUAL,
    bias_slope_scale: 0.0F,
  }
}

///|
pub fn DepthStencilState::new(
  format : UInt,
  depth_write_enabled : Bool,
  depth_compare : UInt,
) -> DepthStencilState {
  DepthStencilState::{
    format,
    depth_write_enabled,
    depth_compare,
    bias_slope_scale: 0.0F,
  }
}

///|
pub fn DepthStencilState::with_bias_slope_scale(
  self : DepthStencilState,
  bias_slope_scale : Float,
) -> DepthStencilState {
  DepthStencilState::{ ..self, bias_slope_scale, }
}

///|
pub impl Default for DepthStencilState with fn default() {
  DepthStencilState::DepthStencilState()
}

///|
pub struct MultisampleState {
  count : UInt
  mask : UInt64
  alpha_to_coverage_enabled : Bool
}

///|
pub fn MultisampleState::MultisampleState() -> MultisampleState {
  MultisampleState::{
    count: 1U,
    mask: 0xffffffffffffffffUL,
    alpha_to_coverage_enabled: false,
  }
}

///|
pub impl Default for MultisampleState with fn default() {
  MultisampleState::MultisampleState()
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
  RenderPipelineDescriptor::{
    label: None,
    layout: [],
    immediate_size: 0U,
    vertex: VertexState::VertexState(),
    primitive: PrimitiveState::PrimitiveState(),
    depth_stencil: None,
    multisample: MultisampleState::MultisampleState(),
    fragment: None,
    zero_initialize_workgroup_memory: true,
  }
}

///|
pub impl Default for RenderPipelineDescriptor with fn default() {
  RenderPipelineDescriptor::RenderPipelineDescriptor()
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
  RenderPipelineDescriptor::{ ..self, label, }
}

///|
pub fn RenderPipelineDescriptor::with_layout(
  self : RenderPipelineDescriptor,
  layout : Array[BindGroupLayoutDescriptor],
) -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{ ..self, layout, }
}

///|
pub fn RenderPipelineDescriptor::with_vertex(
  self : RenderPipelineDescriptor,
  vertex : VertexState,
) -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{ ..self, vertex, }
}

///|
pub fn RenderPipelineDescriptor::with_fragment(
  self : RenderPipelineDescriptor,
  fragment : FragmentState?,
) -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{ ..self, fragment, }
}

///|
pub fn RenderPipelineDescriptor::with_depth_stencil(
  self : RenderPipelineDescriptor,
  depth_stencil : DepthStencilState?,
) -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{ ..self, depth_stencil, }
}

///|
pub fn RenderPipelineDescriptor::with_immediate_size(
  self : RenderPipelineDescriptor,
  immediate_size : UInt,
) -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{ ..self, immediate_size, }
}

///|
pub fn RenderPipelineDescriptor::with_primitive(
  self : RenderPipelineDescriptor,
  primitive : PrimitiveState,
) -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{ ..self, primitive, }
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
  ComputePipelineDescriptor::{
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
  ComputePipelineDescriptor::ComputePipelineDescriptor()
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
pub fn ComputePipelineDescriptor::with_label(
  self : ComputePipelineDescriptor,
  label : String?,
) -> ComputePipelineDescriptor {
  ComputePipelineDescriptor::{ ..self, label, }
}

///|
pub fn ComputePipelineDescriptor::with_layout(
  self : ComputePipelineDescriptor,
  layout : Array[BindGroupLayoutDescriptor],
) -> ComputePipelineDescriptor {
  ComputePipelineDescriptor::{ ..self, layout, }
}

///|
pub fn ComputePipelineDescriptor::with_shader(
  self : ComputePipelineDescriptor,
  shader : String?,
) -> ComputePipelineDescriptor {
  ComputePipelineDescriptor::{ ..self, shader, }
}

///|
pub fn ComputePipelineDescriptor::with_shader_defs(
  self : ComputePipelineDescriptor,
  shader_defs : Array[ShaderDefVal],
) -> ComputePipelineDescriptor {
  ComputePipelineDescriptor::{ ..self, shader_defs, }
}

///|
pub fn ComputePipelineDescriptor::with_entry_point(
  self : ComputePipelineDescriptor,
  entry_point : String?,
) -> ComputePipelineDescriptor {
  ComputePipelineDescriptor::{ ..self, entry_point, }
}

///|
pub fn ComputePipelineDescriptor::with_immediate_size(
  self : ComputePipelineDescriptor,
  immediate_size : UInt,
) -> ComputePipelineDescriptor {
  ComputePipelineDescriptor::{ ..self, immediate_size, }
}

///|
pub fn ComputePipelineDescriptor::with_zero_initialize_workgroup_memory(
  self : ComputePipelineDescriptor,
  zero_initialize_workgroup_memory : Bool,
) -> ComputePipelineDescriptor {
  ComputePipelineDescriptor::{ ..self, zero_initialize_workgroup_memory, }
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
  filling_set_at(
    next_layout,
    index,
    BindGroupLayoutDescriptor::BindGroupLayoutDescriptor(),
    layout,
  )
  RenderPipelineDescriptor::{ ..self, layout: next_layout }
}

///|
pub fn FragmentState::set_target(
  self : FragmentState,
  index : Int,
  target : ColorTargetState,
) -> FragmentState {
  let next_targets = self.targets
  filling_set_at(next_targets, index, None, Some(target))
  FragmentState::{ ..self, targets: next_targets }
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
  CachedRenderPipelineId::{ id: 0xffffffffffffffffUL }
}

///|
pub fn CachedRenderPipelineId::new(id : UInt64) -> CachedRenderPipelineId {
  CachedRenderPipelineId::{ id, }
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
  CachedComputePipelineId::{ id: 0xffffffffffffffffUL }
}

///|
pub fn CachedComputePipelineId::new(id : UInt64) -> CachedComputePipelineId {
  CachedComputePipelineId::{ id, }
}

///|
pub fn CachedComputePipelineId::id(self : CachedComputePipelineId) -> UInt64 {
  self.id
}
