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
const MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING : UInt = 1U

///|
const MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING : UInt = 1U << 1

///|
const MESH3D_PREPROCESS_KEY_EARLY_PHASE : UInt = 1U << 2

///|
priv struct Mesh3dPreprocessPipelineKey {
  bits : UInt
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
fn Mesh3dPreprocessPipelineKey::shader_defines(
  self : Mesh3dPreprocessPipelineKey,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  if self.contains(MESH3D_PREPROCESS_KEY_FRUSTUM_CULLING) {
    defines.set("INDIRECT", true)
    defines.set("FRUSTUM_CULLING", true)
  }
  if self.contains(MESH3D_PREPROCESS_KEY_OCCLUSION_CULLING) {
    defines.set("OCCLUSION_CULLING", true)
    if self.contains(MESH3D_PREPROCESS_KEY_EARLY_PHASE) {
      defines.set("EARLY_PHASE", true)
    } else {
      defines.set("LATE_PHASE", true)
    }
  }
  defines
}

///|
fn load_wgsl_required_mesh3d_preprocess(
  assets_base : String,
  key : Mesh3dPreprocessPipelineKey,
) -> String raise GpuBackendError {
  load_wgsl_preprocessed(
    assets_base,
    "pbr/render/mesh_preprocess.wgsl",
    key.shader_defines(),
    default_wgsl_value_defines(),
  )
}

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
priv struct Mesh3dBuildIndirectParametersPipelineKey {
  bits : UInt
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
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, false, false, false, false, false,
  )
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::early_occlusion_culling(
  indexed : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, false, true, true, false, false,
  )
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::late_occlusion_culling(
  indexed : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, false, true, false, true, false,
  )
}

///|
fn Mesh3dBuildIndirectParametersPipelineKey::main_occlusion_culling(
  indexed : Bool,
) -> Mesh3dBuildIndirectParametersPipelineKey {
  mesh3d_build_indirect_parameters_pipeline_key(
    indexed, false, true, false, false, true,
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
fn Mesh3dBuildIndirectParametersPipelineKey::shader_defines(
  self : Mesh3dBuildIndirectParametersPipelineKey,
) -> @hashmap.HashMap[String, Bool] {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_INDEXED) {
    defines.set("INDEXED", true)
  }
  if self.contains(
      MESH3D_BUILD_INDIRECT_KEY_MULTI_DRAW_INDIRECT_COUNT_SUPPORTED,
    ) {
    defines.set("MULTI_DRAW_INDIRECT_COUNT_SUPPORTED", true)
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_OCCLUSION_CULLING) {
    defines.set("OCCLUSION_CULLING", true)
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_EARLY_PHASE) {
    defines.set("EARLY_PHASE", true)
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_LATE_PHASE) {
    defines.set("LATE_PHASE", true)
  }
  if self.contains(MESH3D_BUILD_INDIRECT_KEY_MAIN_PHASE) {
    defines.set("MAIN_PHASE", true)
  }
  defines
}

///|
fn load_wgsl_required_mesh3d_build_indirect_params(
  assets_base : String,
  key : Mesh3dBuildIndirectParametersPipelineKey,
) -> String raise GpuBackendError {
  load_wgsl_preprocessed(
    assets_base,
    "pbr/render/build_indirect_params.wgsl",
    key.shader_defines(),
    default_wgsl_value_defines(),
  )
}

///|
fn load_wgsl_required_mesh3d_downsample_depth(
  assets_base : String,
) -> String raise GpuBackendError {
  load_wgsl_from_assets_base_required(
    assets_base, "core_pipeline/mip_generation/experimental/downsample_depth.wgsl",
  )
}
