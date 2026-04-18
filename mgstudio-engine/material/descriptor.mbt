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
// Bevy source: `bevy/crates/bevy_material/src/descriptor.rs`.

///|
pub struct BindGroupLayoutDescriptor {
  label : String
  entries : Array[@render_resource.BindGroupLayoutEntry]
}

///|
pub fn BindGroupLayoutDescriptor::default() -> BindGroupLayoutDescriptor {
  BindGroupLayoutDescriptor::{ label: "", entries: [] }
}

///|
pub fn BindGroupLayoutDescriptor::new(
  label : String,
  entries : Array[@render_resource.BindGroupLayoutEntry],
) -> BindGroupLayoutDescriptor {
  BindGroupLayoutDescriptor::{ label, entries }
}

///|
pub(all) enum ShaderDefVal {
  Flag(String)
  Bool(String, Bool)
  Int(String, Int)
  UInt(String, UInt)
  String(String, String)
}

///|
pub type VertexBufferLayout = Int

///|
pub struct VertexState {
  shader : String?
  shader_defs : Array[ShaderDefVal]
  entry_point : String?
  buffers : Array[VertexBufferLayout]
}

///|
pub fn VertexState::default() -> VertexState {
  VertexState::{ shader: None, shader_defs: [], entry_point: None, buffers: [] }
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
pub struct FragmentState {
  shader : String?
  shader_defs : Array[ShaderDefVal]
  entry_point : String?
  targets : Array[ColorTargetState?]
}

///|
pub fn FragmentState::default() -> FragmentState {
  FragmentState::{
    shader: None,
    shader_defs: [],
    entry_point: None,
    targets: [],
  }
}

///|
pub struct PrimitiveState {
  topology : UInt
  front_face : UInt
  cull_mode : UInt?
}

///|
pub fn PrimitiveState::default() -> PrimitiveState {
  PrimitiveState::{
    topology: @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    front_face: @wgpu.FRONT_FACE_CCW,
    cull_mode: Some(@wgpu.CULL_MODE_BACK),
  }
}

///|
pub struct DepthStencilState {
  format : UInt
  depth_write_enabled : Bool
  depth_compare : UInt
}

///|
pub fn DepthStencilState::default() -> DepthStencilState {
  DepthStencilState::{
    format: @wgpu.TEXTURE_FORMAT_DEPTH24_PLUS,
    depth_write_enabled: true,
    depth_compare: @wgpu.COMPARE_FUNCTION_LESS_EQUAL,
  }
}

///|
pub struct MultisampleState {
  count : UInt
  mask : UInt64
  alpha_to_coverage_enabled : Bool
}

///|
pub fn MultisampleState::default() -> MultisampleState {
  MultisampleState::{
    count: 1U,
    mask: 0xffffffffffffffffUL,
    alpha_to_coverage_enabled: false,
  }
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
pub fn RenderPipelineDescriptor::default() -> RenderPipelineDescriptor {
  RenderPipelineDescriptor::{
    label: None,
    layout: [],
    immediate_size: 0U,
    vertex: VertexState::default(),
    primitive: PrimitiveState::default(),
    depth_stencil: None,
    multisample: MultisampleState::default(),
    fragment: None,
    zero_initialize_workgroup_memory: true,
  }
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
pub fn ComputePipelineDescriptor::default() -> ComputePipelineDescriptor {
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
    BindGroupLayoutDescriptor::default(),
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
