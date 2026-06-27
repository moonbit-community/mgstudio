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
// Bevy source: `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs`.

///|
const GPU_PREPROCESSING_PLUGIN_NAME : String = "mgstudio.render.batching.GpuPreprocessingPlugin"

///|
pub(all) enum GpuPreprocessingMode {
  None
  PreprocessingOnly
  Culling
} derive(Eq, Debug)

///|
pub struct GpuPreprocessingSupport {
  max_supported_mode : GpuPreprocessingMode
}

///|
// Bevy source: `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs`
// (`IndirectParametersBuffersSettings`).
pub struct IndirectParametersBuffersSettings {
  allow_copies_from_indirect_parameter_buffers : Bool
}

///|
pub struct IndirectBatchSet {
  indirect_parameters_base : Int
  indirect_parameters_count : Int
} derive(Eq, Debug)

///|
pub fn IndirectBatchSet::new(
  indirect_parameters_base : Int,
  indirect_parameters_count? : Int = 0,
) -> IndirectBatchSet {
  IndirectBatchSet::{ indirect_parameters_base, indirect_parameters_count }
}

///|
pub fn IndirectBatchSet::indirect_parameters_base(
  self : IndirectBatchSet,
) -> Int {
  self.indirect_parameters_base
}

///|
pub fn IndirectBatchSet::indirect_parameters_count(
  self : IndirectBatchSet,
) -> Int {
  self.indirect_parameters_count
}

///|
pub struct MeshClassIndirectParametersBuffers {
  mut indirect_draw_parameter_count : Int
  mut cpu_metadata_count : Int
  mut gpu_metadata_count : Int
  batch_sets : Array[IndirectBatchSet]
  allow_copies_from_indirect_parameter_buffers : Bool
}

///|
pub fn MeshClassIndirectParametersBuffers::new(
  allow_copies_from_indirect_parameter_buffers : Bool,
) -> MeshClassIndirectParametersBuffers {
  MeshClassIndirectParametersBuffers::{
    indirect_draw_parameter_count: 0,
    cpu_metadata_count: 0,
    gpu_metadata_count: 0,
    batch_sets: [],
    allow_copies_from_indirect_parameter_buffers,
  }
}

///|
pub fn MeshClassIndirectParametersBuffers::allocate(
  self : MeshClassIndirectParametersBuffers,
  count : Int,
) -> Int {
  let offset = self.indirect_draw_parameter_count
  if count > 0 {
    self.indirect_draw_parameter_count += count
    self.cpu_metadata_count += count
    self.gpu_metadata_count += count
  }
  offset
}

///|
pub fn MeshClassIndirectParametersBuffers::batch_count(
  self : MeshClassIndirectParametersBuffers,
) -> Int {
  self.indirect_draw_parameter_count
}

///|
pub fn MeshClassIndirectParametersBuffers::batch_set_count(
  self : MeshClassIndirectParametersBuffers,
) -> Int {
  self.batch_sets.length()
}

///|
pub fn MeshClassIndirectParametersBuffers::add_batch_set(
  self : MeshClassIndirectParametersBuffers,
  indirect_parameters_base : Int,
) -> Unit {
  self.batch_sets.push(IndirectBatchSet::new(indirect_parameters_base))
}

///|
pub fn MeshClassIndirectParametersBuffers::clear(
  self : MeshClassIndirectParametersBuffers,
) -> Unit {
  self.indirect_draw_parameter_count = 0
  self.cpu_metadata_count = 0
  self.gpu_metadata_count = 0
  self.batch_sets.clear()
}

///|
pub fn MeshClassIndirectParametersBuffers::allow_copies_from_indirect_parameter_buffers(
  self : MeshClassIndirectParametersBuffers,
) -> Bool {
  self.allow_copies_from_indirect_parameter_buffers
}

///|
pub struct UntypedPhaseIndirectParametersBuffers {
  indexed : MeshClassIndirectParametersBuffers
  non_indexed : MeshClassIndirectParametersBuffers
}

///|
pub fn UntypedPhaseIndirectParametersBuffers::new(
  allow_copies_from_indirect_parameter_buffers : Bool,
) -> UntypedPhaseIndirectParametersBuffers {
  UntypedPhaseIndirectParametersBuffers::{
    indexed: MeshClassIndirectParametersBuffers::new(
      allow_copies_from_indirect_parameter_buffers,
    ),
    non_indexed: MeshClassIndirectParametersBuffers::new(
      allow_copies_from_indirect_parameter_buffers,
    ),
  }
}

///|
pub fn UntypedPhaseIndirectParametersBuffers::allocate(
  self : UntypedPhaseIndirectParametersBuffers,
  indexed : Bool,
  count : Int,
) -> Int {
  if indexed {
    self.indexed.allocate(count)
  } else {
    self.non_indexed.allocate(count)
  }
}

///|
pub fn UntypedPhaseIndirectParametersBuffers::batch_count(
  self : UntypedPhaseIndirectParametersBuffers,
  indexed : Bool,
) -> Int {
  if indexed {
    self.indexed.batch_count()
  } else {
    self.non_indexed.batch_count()
  }
}

///|
pub fn UntypedPhaseIndirectParametersBuffers::batch_set_count(
  self : UntypedPhaseIndirectParametersBuffers,
  indexed : Bool,
) -> Int {
  if indexed {
    self.indexed.batch_set_count()
  } else {
    self.non_indexed.batch_set_count()
  }
}

///|
pub fn UntypedPhaseIndirectParametersBuffers::add_batch_set(
  self : UntypedPhaseIndirectParametersBuffers,
  indexed : Bool,
  indirect_parameters_base : Int,
) -> Unit {
  if indexed {
    self.indexed.add_batch_set(indirect_parameters_base)
  } else {
    self.non_indexed.add_batch_set(indirect_parameters_base)
  }
}

///|
pub fn UntypedPhaseIndirectParametersBuffers::get_next_batch_set_index(
  self : UntypedPhaseIndirectParametersBuffers,
  indexed : Bool,
) -> Int? {
  Some(self.batch_set_count(indexed))
}

///|
pub fn UntypedPhaseIndirectParametersBuffers::clear(
  self : UntypedPhaseIndirectParametersBuffers,
) -> Unit {
  self.indexed.clear()
  self.non_indexed.clear()
}

///|
pub struct PhaseIndirectParametersBuffers {
  mut buffers : UntypedPhaseIndirectParametersBuffers
}

///|
pub fn PhaseIndirectParametersBuffers::new(
  allow_copies_from_indirect_parameter_buffers : Bool,
) -> PhaseIndirectParametersBuffers {
  PhaseIndirectParametersBuffers::{
    buffers: UntypedPhaseIndirectParametersBuffers::new(
      allow_copies_from_indirect_parameter_buffers,
    ),
  }
}

///|
pub fn PhaseIndirectParametersBuffers::allocate(
  self : PhaseIndirectParametersBuffers,
  no_indirect_drawing : Bool,
  item_is_indexed : Bool,
) -> Int? {
  if no_indirect_drawing {
    None
  } else {
    Some(self.buffers.allocate(item_is_indexed, 1))
  }
}

///|
pub struct IndirectParametersBuffers {
  buffers : @hashmap.HashMap[String, UntypedPhaseIndirectParametersBuffers]
}

///|
pub fn IndirectParametersBuffers::IndirectParametersBuffers() -> IndirectParametersBuffers {
  IndirectParametersBuffers::{ buffers: @hashmap.HashMap([]) }
}

///|
pub fn IndirectParametersBuffers::phase_count(
  self : IndirectParametersBuffers,
) -> Int {
  self.buffers.length()
}

///|
pub fn IndirectParametersBuffers::get(
  self : IndirectParametersBuffers,
  phase_id : String,
) -> UntypedPhaseIndirectParametersBuffers? {
  self.buffers.get(phase_id)
}

///|
pub fn GpuPreprocessingSupport::GpuPreprocessingSupport() -> GpuPreprocessingSupport {
  GpuPreprocessingSupport::{ max_supported_mode: GpuPreprocessingMode::None }
}

///|
pub fn GpuPreprocessingSupport::with_max_supported_mode(
  max_supported_mode : GpuPreprocessingMode,
) -> GpuPreprocessingSupport {
  GpuPreprocessingSupport::{ max_supported_mode, }
}

///|
pub fn IndirectParametersBuffersSettings::IndirectParametersBuffersSettings() -> IndirectParametersBuffersSettings {
  IndirectParametersBuffersSettings::{
    allow_copies_from_indirect_parameter_buffers: false,
  }
}

///|
pub fn IndirectParametersBuffersSettings::with_allow_copies_from_indirect_parameter_buffers(
  _self : IndirectParametersBuffersSettings,
  allow : Bool,
) -> IndirectParametersBuffersSettings {
  IndirectParametersBuffersSettings::{
    allow_copies_from_indirect_parameter_buffers: allow,
  }
}

///|
pub fn IndirectParametersBuffersSettings::allow_copies_from_indirect_parameter_buffers(
  self : IndirectParametersBuffersSettings,
) -> Bool {
  self.allow_copies_from_indirect_parameter_buffers
}

///|
pub fn GpuPreprocessingSupport::is_available(
  self : GpuPreprocessingSupport,
) -> Bool {
  self.max_supported_mode != GpuPreprocessingMode::None
}

///|
pub fn GpuPreprocessingSupport::min(
  self : GpuPreprocessingSupport,
  mode : GpuPreprocessingMode,
) -> GpuPreprocessingMode {
  match (self.max_supported_mode, mode) {
    (GpuPreprocessingMode::None, _) | (_, GpuPreprocessingMode::None) =>
      GpuPreprocessingMode::None
    (GpuPreprocessingMode::Culling, other) => other
    (other, GpuPreprocessingMode::Culling) => other
    _ => GpuPreprocessingMode::PreprocessingOnly
  }
}

///|
pub fn GpuPreprocessingSupport::is_culling_supported(
  self : GpuPreprocessingSupport,
) -> Bool {
  self.max_supported_mode == GpuPreprocessingMode::Culling
}

///|
pub struct InstanceInputUniformBuffer[BDI] {
  buffer : Array[BDI]
  free_uniform_indices : Array[Int]
}

///|
pub fn[BDI] InstanceInputUniformBuffer::new() -> InstanceInputUniformBuffer[BDI] {
  InstanceInputUniformBuffer::{ buffer: [], free_uniform_indices: [] }
}

///|
pub fn[BDI] InstanceInputUniformBuffer::clear(
  self : InstanceInputUniformBuffer[BDI],
) -> Unit {
  self.buffer.clear()
  self.free_uniform_indices.clear()
}

///|
pub fn[BDI] InstanceInputUniformBuffer::add(
  self : InstanceInputUniformBuffer[BDI],
  element : BDI,
) -> Int {
  match self.free_uniform_indices.pop() {
    Some(uniform_index) => {
      self.buffer[uniform_index] = element
      uniform_index
    }
    None => {
      let uniform_index = self.buffer.length()
      self.buffer.push(element)
      uniform_index
    }
  }
}

///|
pub fn[BDI] InstanceInputUniformBuffer::remove(
  self : InstanceInputUniformBuffer[BDI],
  uniform_index : Int,
) -> Unit {
  if uniform_index >= 0 &&
    uniform_index < self.buffer.length() &&
    !self.free_uniform_indices.contains(uniform_index) {
    self.free_uniform_indices.push(uniform_index)
  }
}

///|
pub fn[BDI] InstanceInputUniformBuffer::get(
  self : InstanceInputUniformBuffer[BDI],
  uniform_index : Int,
) -> BDI? {
  if uniform_index < 0 ||
    uniform_index >= self.buffer.length() ||
    self.free_uniform_indices.contains(uniform_index) {
    None
  } else {
    Some(self.buffer[uniform_index])
  }
}

///|
pub fn[BDI] InstanceInputUniformBuffer::get_unchecked(
  self : InstanceInputUniformBuffer[BDI],
  uniform_index : Int,
) -> BDI {
  self.buffer[uniform_index]
}

///|
pub fn[BDI] InstanceInputUniformBuffer::set(
  self : InstanceInputUniformBuffer[BDI],
  uniform_index : Int,
  element : BDI,
) -> Unit {
  self.buffer[uniform_index] = element
}

///|
pub fn[BDI] InstanceInputUniformBuffer::ensure_nonempty(
  self : InstanceInputUniformBuffer[BDI],
  default_value : BDI,
) -> Unit {
  if self.buffer.is_empty() {
    self.buffer.push(default_value)
  }
}

///|
pub fn[BDI] InstanceInputUniformBuffer::len(
  self : InstanceInputUniformBuffer[BDI],
) -> Int {
  self.buffer.length()
}

///|
pub fn[BDI] InstanceInputUniformBuffer::is_empty(
  self : InstanceInputUniformBuffer[BDI],
) -> Bool {
  self.buffer.is_empty()
}

///|
pub fn[BDI] InstanceInputUniformBuffer::values(
  self : InstanceInputUniformBuffer[BDI],
) -> Array[BDI] {
  self.buffer
}

///|
pub struct BatchedInstanceBuffers[BD, BDI] {
  current_input_buffer : InstanceInputUniformBuffer[BDI]
  previous_input_buffer : InstanceInputUniformBuffer[BDI]
  phase_instance_buffers : @hashmap.HashMap[
    String,
    PhaseBatchedInstanceBuffers[BD],
  ]
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::new() -> BatchedInstanceBuffers[BD, BDI] {
  BatchedInstanceBuffers::{
    current_input_buffer: InstanceInputUniformBuffer::new(),
    previous_input_buffer: InstanceInputUniformBuffer::new(),
    phase_instance_buffers: @hashmap.HashMap([]),
  }
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::clear(
  self : BatchedInstanceBuffers[BD, BDI],
) -> Unit {
  self.current_input_buffer.clear()
  self.previous_input_buffer.clear()
  for _, phase_instance_buffers in self.phase_instance_buffers {
    phase_instance_buffers.clear()
  }
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::phase_instance_buffer_count(
  self : BatchedInstanceBuffers[BD, BDI],
) -> Int {
  self.phase_instance_buffers.length()
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::insert_phase_instance_buffers(
  self : BatchedInstanceBuffers[BD, BDI],
  phase_id : String,
  buffers : PhaseBatchedInstanceBuffers[BD],
) -> Unit {
  self.phase_instance_buffers.set(phase_id, buffers)
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::swap_input_buffers(
  self : BatchedInstanceBuffers[BD, BDI],
) -> Unit {
  self.previous_input_buffer.clear()
  for value in self.current_input_buffer.values() {
    ignore(self.previous_input_buffer.add(value))
  }
  self.current_input_buffer.clear()
}

///|
pub struct UntypedPhaseBatchedInstanceBuffers[BD] {
  data_buffer : @render_resource.GpuArrayBuffer[BD]
  work_item_buffers : @hashmap.HashMap[String, PreprocessWorkItemBuffers]
  late_indexed_indirect_parameters_buffer : Array[
    LatePreprocessWorkItemIndirectParameters,
  ]
  late_non_indexed_indirect_parameters_buffer : Array[
    LatePreprocessWorkItemIndirectParameters,
  ]
}

///|
pub fn[BD] UntypedPhaseBatchedInstanceBuffers::new() -> UntypedPhaseBatchedInstanceBuffers[
  BD,
] {
  UntypedPhaseBatchedInstanceBuffers::{
    data_buffer: @render_resource.GpuArrayBuffer::new(),
    work_item_buffers: @hashmap.HashMap([]),
    late_indexed_indirect_parameters_buffer: [],
    late_non_indexed_indirect_parameters_buffer: [],
  }
}

///|
pub fn[BD] UntypedPhaseBatchedInstanceBuffers::clear(
  self : UntypedPhaseBatchedInstanceBuffers[BD],
) -> Unit {
  self.data_buffer.clear()
  self.work_item_buffers.clear()
  self.late_indexed_indirect_parameters_buffer.clear()
  self.late_non_indexed_indirect_parameters_buffer.clear()
}

///|
pub struct PhaseBatchedInstanceBuffers[BD] {
  mut buffers : UntypedPhaseBatchedInstanceBuffers[BD]
  mut marker : Int
}

///|
pub fn[BD] PhaseBatchedInstanceBuffers::new() -> PhaseBatchedInstanceBuffers[BD] {
  PhaseBatchedInstanceBuffers::{
    buffers: UntypedPhaseBatchedInstanceBuffers::new(),
    marker: 0,
  }
}

///|
pub fn[BD] PhaseBatchedInstanceBuffers::clear(
  self : PhaseBatchedInstanceBuffers[BD],
) -> Unit {
  self.buffers.clear()
  self.marker = 0
}

///|
pub fn[BD, BDI] collect_phase_batched_instance_buffers(
  batched_instance_buffers : BatchedInstanceBuffers[BD, BDI],
  phase_id : String,
  phase_batched_instance_buffers : PhaseBatchedInstanceBuffers[BD],
) -> Unit {
  let untyped_phase_batched_instance_buffers = phase_batched_instance_buffers.buffers
  let outgoing_phase_batched_instance_buffers = PhaseBatchedInstanceBuffers::{
    buffers: untyped_phase_batched_instance_buffers,
    marker: phase_batched_instance_buffers.marker,
  }
  match batched_instance_buffers.phase_instance_buffers.get(phase_id) {
    Some(old_untyped_phase_batched_instance_buffers) => {
      old_untyped_phase_batched_instance_buffers.clear()
      phase_batched_instance_buffers.buffers = old_untyped_phase_batched_instance_buffers.buffers
      phase_batched_instance_buffers.marker = old_untyped_phase_batched_instance_buffers.marker
    }
    None => {
      phase_batched_instance_buffers.buffers = UntypedPhaseBatchedInstanceBuffers::new()
      phase_batched_instance_buffers.marker = 0
    }
  }
  batched_instance_buffers.phase_instance_buffers.set(
    phase_id, outgoing_phase_batched_instance_buffers,
  )
}

///|
pub fn collect_phase_indirect_parameters_buffers(
  indirect_parameters_buffers : IndirectParametersBuffers,
  phase_id : String,
  phase_indirect_parameters_buffers : PhaseIndirectParametersBuffers,
  indirect_parameters_buffers_settings : IndirectParametersBuffersSettings,
) -> Unit {
  let untyped_phase_indirect_parameters_buffers = phase_indirect_parameters_buffers.buffers
  let outgoing_phase_indirect_parameters_buffers = untyped_phase_indirect_parameters_buffers
  let replacement = match indirect_parameters_buffers.get(phase_id) {
    Some(old_untyped_phase_indirect_parameters_buffers) => {
      old_untyped_phase_indirect_parameters_buffers.clear()
      old_untyped_phase_indirect_parameters_buffers
    }
    None =>
      UntypedPhaseIndirectParametersBuffers::new(
        indirect_parameters_buffers_settings.allow_copies_from_indirect_parameter_buffers(),
      )
  }
  phase_indirect_parameters_buffers.buffers = replacement
  indirect_parameters_buffers.buffers.set(
    phase_id, outgoing_phase_indirect_parameters_buffers,
  )
}

///|
pub fn[BD, BDI] collect_buffers_for_phase(
  phase_id : String,
  phase_batched_instance_buffers : PhaseBatchedInstanceBuffers[BD],
  phase_indirect_parameters_buffers : PhaseIndirectParametersBuffers,
  batched_instance_buffers : BatchedInstanceBuffers[BD, BDI],
  indirect_parameters_buffers : IndirectParametersBuffers,
  indirect_parameters_buffers_settings : IndirectParametersBuffersSettings,
) -> Unit {
  collect_phase_batched_instance_buffers(
    batched_instance_buffers, phase_id, phase_batched_instance_buffers,
  )
  collect_phase_indirect_parameters_buffers(
    indirect_parameters_buffers, phase_id, phase_indirect_parameters_buffers, indirect_parameters_buffers_settings,
  )
}

///|
pub struct PreprocessWorkItem {
  input_index : Int
  output_or_indirect_parameters_index : Int
} derive(Eq, Debug)

///|
pub fn PreprocessWorkItem::new(
  input_index : Int,
  output_or_indirect_parameters_index : Int,
) -> PreprocessWorkItem {
  PreprocessWorkItem::{ input_index, output_or_indirect_parameters_index }
}

///|
pub struct LatePreprocessWorkItemIndirectParameters {
  dispatch_x : Int
  dispatch_y : Int
  dispatch_z : Int
  work_item_count : Int
} derive(Eq, Debug)

///|
pub fn LatePreprocessWorkItemIndirectParameters::LatePreprocessWorkItemIndirectParameters() -> LatePreprocessWorkItemIndirectParameters {
  LatePreprocessWorkItemIndirectParameters::{
    dispatch_x: 0,
    dispatch_y: 1,
    dispatch_z: 1,
    work_item_count: 0,
  }
}

///|
pub struct GpuOcclusionCullingWorkItemBuffers {
  late_indexed : Array[PreprocessWorkItem]
  late_non_indexed : Array[PreprocessWorkItem]
  mut late_indirect_parameters_indexed_offset : Int
  mut late_indirect_parameters_non_indexed_offset : Int
}

///|
pub fn GpuOcclusionCullingWorkItemBuffers::new() -> GpuOcclusionCullingWorkItemBuffers {
  GpuOcclusionCullingWorkItemBuffers::{
    late_indexed: [],
    late_non_indexed: [],
    late_indirect_parameters_indexed_offset: 0,
    late_indirect_parameters_non_indexed_offset: 0,
  }
}

///|
pub(all) enum PreprocessWorkItemBuffers {
  Direct(Array[PreprocessWorkItem])
  Indirect(
    Array[PreprocessWorkItem],
    Array[PreprocessWorkItem],
    GpuOcclusionCullingWorkItemBuffers?
  )
}

///|
pub fn preprocess_work_item_buffers_direct() -> PreprocessWorkItemBuffers {
  PreprocessWorkItemBuffers::Direct([])
}

///|
pub fn preprocess_work_item_buffers_indirect(
  enable_gpu_occlusion_culling : Bool,
) -> PreprocessWorkItemBuffers {
  PreprocessWorkItemBuffers::Indirect(
    [],
    [],
    if enable_gpu_occlusion_culling {
      Some(GpuOcclusionCullingWorkItemBuffers::new())
    } else {
      None
    },
  )
}

///|
pub fn get_or_create_work_item_buffer(
  work_item_buffers : @hashmap.HashMap[String, PreprocessWorkItemBuffers],
  view : String,
  no_indirect_drawing : Bool,
  enable_gpu_occlusion_culling : Bool,
) -> PreprocessWorkItemBuffers {
  let current = match work_item_buffers.get(view) {
    Some(buffer) => buffer
    None => {
      let buffer = if no_indirect_drawing {
        preprocess_work_item_buffers_direct()
      } else {
        preprocess_work_item_buffers_indirect(enable_gpu_occlusion_culling)
      }
      work_item_buffers.set(view, buffer)
      buffer
    }
  }
  match current {
    Indirect(indexed, non_indexed, gpu_occlusion_culling) => {
      let next_gpu_occlusion_culling = match
        (enable_gpu_occlusion_culling, gpu_occlusion_culling) {
        (true, Some(existing)) => Some(existing)
        (true, None) => Some(GpuOcclusionCullingWorkItemBuffers::new())
        (false, _) => None
      }
      let next = PreprocessWorkItemBuffers::Indirect(
        indexed, non_indexed, next_gpu_occlusion_culling,
      )
      work_item_buffers.set(view, next)
      next
    }
    Direct(_) => current
  }
}

///|
pub fn init_work_item_buffers(
  work_item_buffers : PreprocessWorkItemBuffers,
  late_indexed_indirect_parameters_buffer : Array[
    LatePreprocessWorkItemIndirectParameters,
  ],
  late_non_indexed_indirect_parameters_buffer : Array[
    LatePreprocessWorkItemIndirectParameters,
  ],
) -> Unit {
  match work_item_buffers {
    Indirect(_, _, Some(gpu_occlusion_culling)) => {
      gpu_occlusion_culling.late_indirect_parameters_indexed_offset = late_indexed_indirect_parameters_buffer.length()
      late_indexed_indirect_parameters_buffer.push(
        LatePreprocessWorkItemIndirectParameters::LatePreprocessWorkItemIndirectParameters(),
      )
      gpu_occlusion_culling.late_indirect_parameters_non_indexed_offset = late_non_indexed_indirect_parameters_buffer.length()
      late_non_indexed_indirect_parameters_buffer.push(
        LatePreprocessWorkItemIndirectParameters::LatePreprocessWorkItemIndirectParameters(),
      )
    }
    _ => ()
  }
}

///|
pub fn PreprocessWorkItemBuffers::push(
  self : PreprocessWorkItemBuffers,
  indexed : Bool,
  preprocess_work_item : PreprocessWorkItem,
) -> Unit {
  match self {
    Direct(buffer) => buffer.push(preprocess_work_item)
    Indirect(indexed_buffer, non_indexed_buffer, gpu_occlusion_culling) => {
      if indexed {
        indexed_buffer.push(preprocess_work_item)
      } else {
        non_indexed_buffer.push(preprocess_work_item)
      }
      match gpu_occlusion_culling {
        Some(buffers) =>
          if indexed {
            buffers.late_indexed.push(preprocess_work_item)
          } else {
            buffers.late_non_indexed.push(preprocess_work_item)
          }
        None => ()
      }
    }
  }
}

///|
pub fn PreprocessWorkItemBuffers::clear(
  self : PreprocessWorkItemBuffers,
) -> Unit {
  match self {
    Direct(buffer) => buffer.clear()
    Indirect(indexed_buffer, non_indexed_buffer, gpu_occlusion_culling) => {
      indexed_buffer.clear()
      non_indexed_buffer.clear()
      match gpu_occlusion_culling {
        Some(buffers) => {
          buffers.late_indexed.clear()
          buffers.late_non_indexed.clear()
          buffers.late_indirect_parameters_indexed_offset = 0
          buffers.late_indirect_parameters_non_indexed_offset = 0
        }
        None => ()
      }
    }
  }
}

///|
pub fn PreprocessWorkItemBuffers::direct_len(
  self : PreprocessWorkItemBuffers,
) -> Int {
  match self {
    Direct(buffer) => buffer.length()
    Indirect(_, _, _) => 0
  }
}

///|
pub fn PreprocessWorkItemBuffers::indexed_len(
  self : PreprocessWorkItemBuffers,
) -> Int {
  match self {
    Direct(_) => 0
    Indirect(indexed_buffer, _, _) => indexed_buffer.length()
  }
}

///|
pub fn PreprocessWorkItemBuffers::non_indexed_len(
  self : PreprocessWorkItemBuffers,
) -> Int {
  match self {
    Direct(_) => 0
    Indirect(_, non_indexed_buffer, _) => non_indexed_buffer.length()
  }
}

///|
pub fn PreprocessWorkItemBuffers::late_indexed_len(
  self : PreprocessWorkItemBuffers,
) -> Int {
  match self {
    Indirect(_, _, Some(buffers)) => buffers.late_indexed.length()
    _ => 0
  }
}

///|
pub fn PreprocessWorkItemBuffers::late_non_indexed_len(
  self : PreprocessWorkItemBuffers,
) -> Int {
  match self {
    Indirect(_, _, Some(buffers)) => buffers.late_non_indexed.length()
    _ => 0
  }
}

///|
pub fn PreprocessWorkItemBuffers::late_indirect_offsets(
  self : PreprocessWorkItemBuffers,
) -> (Int, Int)? {
  match self {
    Indirect(_, _, Some(buffers)) =>
      Some(
        (
          buffers.late_indirect_parameters_indexed_offset,
          buffers.late_indirect_parameters_non_indexed_offset,
        ),
      )
    _ => None
  }
}

///|
pub struct GpuPreprocessingPlugin {
  mode : GpuPreprocessingMode
  allow_copies_from_indirect_parameter_buffers : Bool
}

///|
pub fn GpuPreprocessingPlugin::GpuPreprocessingPlugin() -> GpuPreprocessingPlugin {
  GpuPreprocessingPlugin::{
    mode: GpuPreprocessingMode::Culling,
    allow_copies_from_indirect_parameter_buffers: false,
  }
}

///|
pub fn GpuPreprocessingPlugin::with_mode(
  mode : GpuPreprocessingMode,
) -> GpuPreprocessingPlugin {
  GpuPreprocessingPlugin::{
    mode,
    allow_copies_from_indirect_parameter_buffers: false,
  }
}

///|
pub fn GpuPreprocessingPlugin::with_allow_copies_from_indirect_parameter_buffers(
  self : GpuPreprocessingPlugin,
  allow : Bool,
) -> GpuPreprocessingPlugin {
  GpuPreprocessingPlugin::{
    ..self,
    allow_copies_from_indirect_parameter_buffers: allow,
  }
}

///|
pub impl @app.Plugin for GpuPreprocessingPlugin with fn name(_self) {
  GPU_PREPROCESSING_PLUGIN_NAME
}

///|
pub impl @app.Plugin for GpuPreprocessingPlugin with fn build(self, app) {
  gpu_preprocessing_plugin_with(app, self)
}

///|
let gpu_preprocessing_support_resource_key : @ecs.ResourceKey[
  GpuPreprocessingSupport,
] = @ecs.register_resource(
  debug_name="mgstudio_render::GpuPreprocessingSupport",
)

///|
let indirect_parameters_buffers_settings_resource_key : @ecs.ResourceKey[
  IndirectParametersBuffersSettings,
] = @ecs.register_resource(
  debug_name="mgstudio_render::IndirectParametersBuffersSettings",
)

///|
let indirect_parameters_buffers_resource_key : @ecs.ResourceKey[
  IndirectParametersBuffers,
] = @ecs.register_resource(
  debug_name="mgstudio_render::IndirectParametersBuffers",
)

///|
pub impl @app.Resource for GpuPreprocessingSupport with fn resource() {
  gpu_preprocessing_support_resource_key
}

///|
pub impl @app.Resource for IndirectParametersBuffersSettings with fn resource() {
  indirect_parameters_buffers_settings_resource_key
}

///|
pub impl @app.Resource for IndirectParametersBuffers with fn resource() {
  indirect_parameters_buffers_resource_key
}

///|
pub fn gpu_preprocessing_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  gpu_preprocessing_plugin_with(
    app,
    GpuPreprocessingPlugin::GpuPreprocessingPlugin(),
  )
}

///|
pub fn gpu_preprocessing_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GpuPreprocessingPlugin,
) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(gpu_preprocessing_support_resource_key) {
    next = next.insert_world_resource(gpu_preprocessing_support_resource_key, GpuPreprocessingSupport::{
      max_supported_mode: plugin.mode,
    })
  }
  ignore(
    next.modify_sub_app(@app.RenderApp, fn(render_sub_app) {
      render_sub_app
      .world()
      .insert_resource(
        indirect_parameters_buffers_settings_resource_key,
        IndirectParametersBuffersSettings::IndirectParametersBuffersSettings().with_allow_copies_from_indirect_parameter_buffers(
          plugin.allow_copies_from_indirect_parameter_buffers,
        ),
      )
      if render_sub_app
        .world()
        .get_resource(indirect_parameters_buffers_resource_key)
        is None {
        render_sub_app
        .world()
        .insert_resource(
          indirect_parameters_buffers_resource_key,
          IndirectParametersBuffers::IndirectParametersBuffers(),
        )
      }
      render_sub_app
    }),
  )
  next
}
