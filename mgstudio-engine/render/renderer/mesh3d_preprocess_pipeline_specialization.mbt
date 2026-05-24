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
// Bevy source: `bevy/crates/bevy_pbr/src/render/gpu_preprocess.rs`.

///|
const MESH3D_PREPROCESS_SHADER_PATH : String = "pbr/render/mesh_preprocess.wgsl"

///|
const MESH3D_BUILD_INDIRECT_PARAMS_SHADER_PATH : String = "pbr/render/build_indirect_params.wgsl"

///|
const MESH3D_RESET_INDIRECT_BATCH_SETS_SHADER_PATH : String = "pbr/render/reset_indirect_batch_sets.wgsl"

///|
const MESH3D_DOWNSAMPLE_DEPTH_SHADER_PATH : String = "core_pipeline/mip_generation/experimental/downsample_depth.wgsl"

///|
const MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING : UInt = 1U

///|
const MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING : UInt = 1U << 1

///|
const MESH3D_PREPROCESS_KEY_EARLY_PHASE : UInt = 1U << 2

///|
const MESH3D_BUILD_INDIRECT_KEY_INDEXED : UInt = 1U

///|
const MESH3D_BUILD_INDIRECT_KEY_MULTI_DRAW_INDIRECT_COUNT_SUPPORTED : UInt = 1U <<
  1

///|
const MESH3D_BUILD_INDIRECT_KEY_OCCLUSION_CULLING : UInt = 1U << 2

///|
const MESH3D_BUILD_INDIRECT_KEY_EARLY_PHASE : UInt = 1U << 3

///|
const MESH3D_BUILD_INDIRECT_KEY_LATE_PHASE : UInt = 1U << 4

///|
const MESH3D_BUILD_INDIRECT_KEY_MAIN_PHASE : UInt = 1U << 5

///|
priv struct Mesh3dComputePipelineDescriptor {
  label : String
  layout : @wgpu.PipelineLayout
  shader_path : String
  shader_defs : Array[String]
  entry_point : String
}

///|
priv struct Mesh3dPreprocessPipeline {
  layout : @wgpu.PipelineLayout
}

///|
priv struct Mesh3dResetIndirectBatchSetsPipeline {
  layout : @wgpu.PipelineLayout
}

///|
priv struct Mesh3dBuildIndirectParametersPipeline {
  layout : @wgpu.PipelineLayout
}

///|
priv struct Mesh3dDownsampleDepthPipeline {
  layout : @wgpu.PipelineLayout
}

///|
priv struct Mesh3dPreprocessPipelineKey {
  bits : UInt
}

///|
priv struct Mesh3dBuildIndirectParametersPipelineKey {
  bits : UInt
}

///|
fn Mesh3dPreprocessPipeline::new(
  layout : @wgpu.PipelineLayout,
) -> Mesh3dPreprocessPipeline {
  { layout, }
}

///|
fn Mesh3dResetIndirectBatchSetsPipeline::new(
  layout : @wgpu.PipelineLayout,
) -> Mesh3dResetIndirectBatchSetsPipeline {
  { layout, }
}

///|
fn Mesh3dBuildIndirectParametersPipeline::new(
  layout : @wgpu.PipelineLayout,
) -> Mesh3dBuildIndirectParametersPipeline {
  { layout, }
}

///|
fn Mesh3dDownsampleDepthPipeline::new(
  layout : @wgpu.PipelineLayout,
) -> Mesh3dDownsampleDepthPipeline {
  { layout, }
}

///|
fn Mesh3dPreprocessPipelineKey::direct() -> Mesh3dPreprocessPipelineKey {
  Mesh3dPreprocessPipelineKey::{ bits: 0U }
}

///|
fn Mesh3dPreprocessPipelineKey::frustum_culling() -> Mesh3dPreprocessPipelineKey {
  Mesh3dPreprocessPipelineKey::{ bits: MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING }
}

///|
fn Mesh3dPreprocessPipelineKey::early_occlusion_culling() -> Mesh3dPreprocessPipelineKey {
  Mesh3dPreprocessPipelineKey::{
    bits: MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING |
    MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING |
    MESH3D_PREPROCESS_KEY_EARLY_PHASE,
  }
}

///|
fn Mesh3dPreprocessPipelineKey::late_occlusion_culling() -> Mesh3dPreprocessPipelineKey {
  Mesh3dPreprocessPipelineKey::{
    bits: MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING |
    MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING,
  }
}

///|
fn Mesh3dPreprocessPipelineKey::contains(
  self : Mesh3dPreprocessPipelineKey,
  flag : UInt,
) -> Bool {
  (self.bits & flag) != 0U
}

///|
fn Mesh3dPreprocessPipelineKey::shader_defs(
  self : Mesh3dPreprocessPipelineKey,
) -> Array[String] {
  let defs : Array[String] = ["WRITE_INDIRECT_PARAMETERS_METADATA"]
  if self.contains(MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING) {
    defs.push("INDIRECT")
    defs.push("FRUSTUM_CULLING")
  }
  if self.contains(MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING) {
    defs.push("OCCLUSION_CULLING")
    if self.contains(MESH3D_PREPROCESS_KEY_EARLY_PHASE) {
      defs.push("EARLY_PHASE")
    } else {
      defs.push("LATE_PHASE")
    }
  }
  defs
}

///|
fn Mesh3dPreprocessPipelineKey::label(
  self : Mesh3dPreprocessPipelineKey,
) -> String {
  if self.contains(
      MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING |
      MESH3D_PREPROCESS_KEY_EARLY_PHASE,
    ) {
    "mgstudio mesh preprocessing (early GPU occlusion culling)"
  } else if self.contains(MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING) {
    "mgstudio mesh preprocessing (late GPU occlusion culling)"
  } else if self.contains(MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING) {
    "mgstudio mesh preprocessing (GPU frustum culling)"
  } else {
    "mgstudio mesh preprocessing (direct)"
  }
}

///|
fn mesh3d_build_indirect_parameters_pipeline_key(
  indexed : Bool,
  multi_draw_indirect_count_supported : Bool,
  occlusion_culling : Bool,
  early_phase : Bool,
  late_phase : Bool,
  main_phase : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  Mesh3dBuildIndirectParametersPipelineKey::{
    bits: (if indexed { MESH3D_BUILD_INDIRECT_KEY_INDEXED } else { 0U }) |
    (if multi_draw_indirect_count_supported {
      MESH3D_BUILD_INDIRECT_KEY_MULTI_DRAW_INDIRECT_COUNT_SUPPORTED
    } else {
      0U
    }) |
    (if occlusion_culling {
      MESH3D_BUILD_INDIRECT_KEY_OCCLUSION_CULLING
    } else {
      0U
    }) |
    (if early_phase { MESH3D_BUILD_INDIRECT_KEY_EARLY_PHASE } else { 0U }) |
    (if late_phase { MESH3D_BUILD_INDIRECT_KEY_LATE_PHASE } else { 0U }) |
    (if main_phase { MESH3D_BUILD_INDIRECT_KEY_MAIN_PHASE } else { 0U }),
  }
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::frustum_culling(
  indexed : Bool,
  multi_draw_indirect_count_supported : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, multi_draw_indirect_count_supported, false, false, false, false,
  )
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::early_occlusion_culling(
  indexed : Bool,
  multi_draw_indirect_count_supported : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, multi_draw_indirect_count_supported, true, true, false, false,
  )
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::late_occlusion_culling(
  indexed : Bool,
  multi_draw_indirect_count_supported : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, multi_draw_indirect_count_supported, true, false, true, false,
  )
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::main_occlusion_culling(
  indexed : Bool,
  multi_draw_indirect_count_supported : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, multi_draw_indirect_count_supported, true, false, false, true,
  )
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::contains(
  self : Mesh3dBuildIndirectParametersPipelineKey,
  flag : UInt,
) -> Bool {
  (self.bits & flag) != 0U
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::shader_defs(
  self : Mesh3dBuildIndirectParametersPipelineKey,
) -> Array[String] {
  let defs : Array[String] = []
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_INDEXED) {
    defs.push("INDEXED")
  }
  if self.contains(
      MESH3D_BUILD_INDIRECT_KEY_MULTI_DRAW_INDIRECT_COUNT_SUPPORTED,
    ) {
    defs.push("MULTI_DRAW_INDIRECT_COUNT_SUPPORTED")
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_OCCLUSION_CULLING) {
    defs.push("OCCLUSION_CULLING")
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_EARLY_PHASE) {
    defs.push("EARLY_PHASE")
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_LATE_PHASE) {
    defs.push("LATE_PHASE")
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_MAIN_PHASE) {
    defs.push("MAIN_PHASE")
  }
  defs
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::label(
  self : Mesh3dBuildIndirectParametersPipelineKey,
) -> String {
  let phase = if !self.contains(MESH3D_BUILD_INDIRECT_KEY_OCCLUSION_CULLING) {
    "frustum culling"
  } else if self.contains(MESH3D_BUILD_INDIRECT_KEY_EARLY_PHASE) {
    "early occlusion culling"
  } else if self.contains(MESH3D_BUILD_INDIRECT_KEY_LATE_PHASE) {
    "late occlusion culling"
  } else {
    "main occlusion culling"
  }
  let index_kind = if self.contains(MESH3D_BUILD_INDIRECT_KEY_INDEXED) {
    "indexed"
  } else {
    "non-indexed"
  }
  "mgstudio \{phase} build \{index_kind} indirect parameters"
}

///|
fn Mesh3dPreprocessPipeline::specialize(
  self : Mesh3dPreprocessPipeline,
  key : Mesh3dPreprocessPipelineKey,
) -> Mesh3dComputePipelineDescriptor {
  Mesh3dComputePipelineDescriptor::{
    label: key.label(),
    layout: self.layout,
    shader_path: MESH3D_PREPROCESS_SHADER_PATH,
    shader_defs: key.shader_defs(),
    entry_point: "main",
  }
}

///|
fn Mesh3dResetIndirectBatchSetsPipeline::specialize(
  self : Mesh3dResetIndirectBatchSetsPipeline,
) -> Mesh3dComputePipelineDescriptor {
  Mesh3dComputePipelineDescriptor::{
    label: "mgstudio reset indirect batch sets",
    layout: self.layout,
    shader_path: MESH3D_RESET_INDIRECT_BATCH_SETS_SHADER_PATH,
    shader_defs: [],
    entry_point: "main",
  }
}

///|
fn Mesh3dBuildIndirectParametersPipeline::specialize(
  self : Mesh3dBuildIndirectParametersPipeline,
  key : Mesh3dBuildIndirectParametersPipelineKey,
) -> Mesh3dComputePipelineDescriptor {
  Mesh3dComputePipelineDescriptor::{
    label: key.label(),
    layout: self.layout,
    shader_path: MESH3D_BUILD_INDIRECT_PARAMS_SHADER_PATH,
    shader_defs: key.shader_defs(),
    entry_point: "main",
  }
}

///|
fn Mesh3dDownsampleDepthPipeline::specialize(
  self : Mesh3dDownsampleDepthPipeline,
  entry_point : String,
  label : String,
) -> Mesh3dComputePipelineDescriptor {
  Mesh3dComputePipelineDescriptor::{
    label,
    layout: self.layout,
    shader_path: MESH3D_DOWNSAMPLE_DEPTH_SHADER_PATH,
    shader_defs: [],
    entry_point,
  }
}

///|
fn mesh3d_shader_defs_to_bool_map(
  shader_defs : Array[String],
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  for shader_def in shader_defs {
    defines.set(shader_def, true)
  }
  defines
}

///|
fn Mesh3dComputePipelineDescriptor::compile(
  self : Mesh3dComputePipelineDescriptor,
  backend : GpuBackend,
) -> @wgpu.ComputePipeline raise GpuBackendError {
  let source = load_wgsl_preprocessed(
    backend.assets_base,
    self.shader_path,
    mesh3d_shader_defs_to_bool_map(self.shader_defs),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(source)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    self.layout,
    shader,
    self.entry_point,
  ) catch {
    err =>
      fatal("wgpu: failed to create \{self.label} pipeline: \{err.message()}")
  }
  pipeline.set_label(self.label)
  shader.release()
  pipeline
}

///|
fn mesh3d_build_indirect_multi_draw_indirect_count_supported(
  backend : GpuBackend,
) -> Bool {
  backend.device.has_feature_native_multi_draw_indirect_count()
}
