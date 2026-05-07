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
fn mesh3d_preprocess_replace_string(
  source : String,
  needle : String,
  replacement : String,
) -> String {
  source.replace_all(old=needle, new=replacement)
}

///|
fn mesh3d_preprocess_specialize_late_phase_immediate(source : String) -> String {
  mesh3d_preprocess_replace_string(
    source, "var<immediate> immediates: Immediates;", "const LATE_PREPROCESS_WORK_ITEM_INDIRECT_OFFSET: u32 = 0u;",
  ).replace_all(
    old="immediates.late_preprocess_work_item_indirect_offset",
    new="LATE_PREPROCESS_WORK_ITEM_INDIRECT_OFFSET",
  )
}

///|
fn mesh3d_preprocess_specialize_downsample_depth(
  source : String,
  max_mip_level : Int,
) -> String {
  mesh3d_preprocess_replace_string(
    source,
    "struct Constants { max_mip_level: u32 }\nvar<immediate> constants: Constants;",
    "const MAX_MIP_LEVEL: u32 = \{max_mip_level.to_string()}u;",
  ).replace_all(old="constants.max_mip_level", new="MAX_MIP_LEVEL")
}

///|
fn load_wgsl_required_mesh3d_preprocess_direct(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/mesh_preprocess.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_preprocess_indirect(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  defines.set("INDIRECT", true)
  defines.set("FRUSTUM_CULLING", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/mesh_preprocess.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_preprocess_indirect_early_occlusion(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  defines.set("INDIRECT", true)
  defines.set("FRUSTUM_CULLING", true)
  defines.set("OCCLUSION_CULLING", true)
  defines.set("EARLY_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  let source = load_wgsl_preprocessed(
    assets_base, "pbr/render/mesh_preprocess.wgsl", defines, value_defines,
  )
  mesh3d_preprocess_specialize_late_phase_immediate(source)
}

///|
fn load_wgsl_required_mesh3d_preprocess_indirect_late_occlusion(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("WRITE_INDIRECT_PARAMETERS_METADATA", true)
  defines.set("INDIRECT", true)
  defines.set("FRUSTUM_CULLING", true)
  defines.set("OCCLUSION_CULLING", true)
  defines.set("LATE_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  let source = load_wgsl_preprocessed(
    assets_base, "pbr/render/mesh_preprocess.wgsl", defines, value_defines,
  )
  mesh3d_preprocess_specialize_late_phase_immediate(source)
}

///|
fn load_wgsl_required_mesh3d_build_indexed_indirect_params(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("INDEXED", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_build_indexed_indirect_params_early(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("INDEXED", true)
  defines.set("OCCLUSION_CULLING", true)
  defines.set("EARLY_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_build_indexed_indirect_params_late(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("INDEXED", true)
  defines.set("OCCLUSION_CULLING", true)
  defines.set("LATE_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_build_indexed_indirect_params_main(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("INDEXED", true)
  defines.set("OCCLUSION_CULLING", true)
  defines.set("MAIN_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_build_non_indexed_indirect_params(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_build_non_indexed_indirect_params_early(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("OCCLUSION_CULLING", true)
  defines.set("EARLY_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_build_non_indexed_indirect_params_late(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("OCCLUSION_CULLING", true)
  defines.set("LATE_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_build_non_indexed_indirect_params_main(
  assets_base : String,
) -> String raise GpuBackendError {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  defines.set("OCCLUSION_CULLING", true)
  defines.set("MAIN_PHASE", true)
  let value_defines = default_wgsl_value_defines()
  load_wgsl_preprocessed(
    assets_base, "pbr/render/build_indirect_params.wgsl", defines, value_defines,
  )
}

///|
fn load_wgsl_required_mesh3d_downsample_depth(
  assets_base : String,
  max_mip_level : Int,
) -> String raise GpuBackendError {
  let source = load_wgsl_from_assets_base_required(
    assets_base, "core_pipeline/mip_generation/experimental/downsample_depth.wgsl",
  )
  mesh3d_preprocess_specialize_downsample_depth(source, max_mip_level)
}
