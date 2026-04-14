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

// Bevy-aligned render module anchor.

///|
const GPU_MESH_PREPROCESS_PLUGIN_NAME : String = "mgstudio.pbr.render.GpuMeshPreprocessPlugin"

///|
pub struct Render3dGpuPreprocessState {
  enabled : Bool
  use_gpu_instance_buffer_builder : Bool
  indirect_enabled : Bool
  last_dispatch_count : Int
}

///|
pub fn Render3dGpuPreprocessState::default() -> Render3dGpuPreprocessState {
  Render3dGpuPreprocessState::{
    enabled: true,
    use_gpu_instance_buffer_builder: true,
    indirect_enabled: true,
    last_dispatch_count: 0,
  }
}

///|
pub fn render3d_gpu_preprocess_state(
  use_gpu_instance_buffer_builder : Bool,
  no_indirect_drawing : Bool,
) -> Render3dGpuPreprocessState {
  let enabled = render3d_gpu_preprocess_enabled()
  let builder_enabled = render3d_gpu_preprocess_builder_enabled(
    use_gpu_instance_buffer_builder,
  )
  let indirect_enabled = render3d_gpu_preprocess_camera_indirect_enabled(
    use_gpu_instance_buffer_builder, no_indirect_drawing,
  )
  Render3dGpuPreprocessState::{
    enabled,
    use_gpu_instance_buffer_builder: builder_enabled,
    indirect_enabled,
    last_dispatch_count: 0,
  }
}

///|
pub fn render3d_gpu_preprocess_state_with_dispatch_count(
  state : Render3dGpuPreprocessState,
  dispatch_count : Int,
) -> Render3dGpuPreprocessState {
  Render3dGpuPreprocessState::{
    ..state,
    last_dispatch_count: if dispatch_count < 0 {
      0
    } else {
      dispatch_count
    },
  }
}

///|
pub fn Render3dGpuPreprocessState::enabled(
  self : Render3dGpuPreprocessState,
) -> Bool {
  self.enabled
}

///|
pub fn Render3dGpuPreprocessState::indirect_enabled(
  self : Render3dGpuPreprocessState,
) -> Bool {
  self.indirect_enabled
}

///|
pub fn Render3dGpuPreprocessState::dispatch_count(
  self : Render3dGpuPreprocessState,
) -> Int {
  self.last_dispatch_count
}

///|
pub fn render3d_gpu_preprocess_enabled() -> Bool {
  !render3d_gpu_preprocess_forced_disabled()
}

///|
pub fn render3d_gpu_preprocess_builder_enabled(
  use_gpu_instance_buffer_builder : Bool,
) -> Bool {
  render3d_use_gpu_instance_buffer_builder(use_gpu_instance_buffer_builder)
}

///|
pub fn render3d_gpu_preprocess_camera_indirect_enabled(
  use_gpu_instance_buffer_builder : Bool,
  no_indirect_drawing : Bool,
) -> Bool {
  let gpu_culling_supported = render3d_gpu_culling_supported()
  render3d_camera_indirect_enabled(
    use_gpu_instance_buffer_builder, gpu_culling_supported, no_indirect_drawing,
  )
}

///|
const PREPROCESS_PIPELINE_KEY_FRUSTUM_CULLING : UInt = 1U

///|
const PREPROCESS_PIPELINE_KEY_OCCLUSION_CULLING : UInt = 1U << 1

///|
const PREPROCESS_PIPELINE_KEY_EARLY_PHASE : UInt = 1U << 2

///|
const BUILD_INDIRECT_KEY_INDEXED : UInt = 1U

///|
const BUILD_INDIRECT_KEY_MULTI_DRAW_INDIRECT_COUNT_SUPPORTED : UInt = 1U << 1

///|
const BUILD_INDIRECT_KEY_OCCLUSION_CULLING : UInt = 1U << 2

///|
const BUILD_INDIRECT_KEY_EARLY_PHASE : UInt = 1U << 3

///|
const BUILD_INDIRECT_KEY_LATE_PHASE : UInt = 1U << 4

///|
const BUILD_INDIRECT_KEY_MAIN_PHASE : UInt = 1U << 5

///|
pub struct GpuMeshPreprocessPlugin {
  use_gpu_instance_buffer_builder : Bool
}

///|
pub fn GpuMeshPreprocessPlugin::default() -> GpuMeshPreprocessPlugin {
  GpuMeshPreprocessPlugin::{ use_gpu_instance_buffer_builder: true }
}

///|
pub fn GpuMeshPreprocessPlugin::new(
  use_gpu_instance_buffer_builder : Bool,
) -> GpuMeshPreprocessPlugin {
  GpuMeshPreprocessPlugin::{ use_gpu_instance_buffer_builder, }
}

///|
pub impl @app.PluginReplacement for GpuMeshPreprocessPlugin with plugin_name(
  _self,
) {
  GPU_MESH_PREPROCESS_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for GpuMeshPreprocessPlugin with world_plugin(
  self,
) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    gpu_mesh_preprocess_plugin_install_with(app, self)
  }
}

///|
let ecs_key_gpu_mesh_preprocess_state : @ecs.ResourceKey[
  Render3dGpuPreprocessState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Render3dGpuPreprocessState",
)

///|
pub impl @app.Resource for Render3dGpuPreprocessState with resource() {
  ecs_key_gpu_mesh_preprocess_state
}

///|
pub fn gpu_mesh_preprocess_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  gpu_mesh_preprocess_plugin_install_with(app, GpuMeshPreprocessPlugin::default())
}

///|
pub fn gpu_mesh_preprocess_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : GpuMeshPreprocessPlugin,
) -> @app.App[@ecs.World] {
  let state = render3d_gpu_preprocess_state(
    plugin.use_gpu_instance_buffer_builder,
    false,
  )
  app.insert_world_resource(ecs_key_gpu_mesh_preprocess_state, state)
}

///|
pub struct PreprocessPipeline {
  bind_group_layout_label : String
  shader_path : String
  pipeline_id : Int?
}

///|
pub fn PreprocessPipeline::new(
  bind_group_layout_label : String,
  shader_path : String,
) -> PreprocessPipeline {
  PreprocessPipeline::{
    bind_group_layout_label,
    shader_path,
    pipeline_id: None,
  }
}

///|
pub struct ResetIndirectBatchSetsPipeline {
  bind_group_layout_label : String
  shader_path : String
  pipeline_id : Int?
}

///|
pub fn ResetIndirectBatchSetsPipeline::new(
  bind_group_layout_label : String,
  shader_path : String,
) -> ResetIndirectBatchSetsPipeline {
  ResetIndirectBatchSetsPipeline::{
    bind_group_layout_label,
    shader_path,
    pipeline_id: None,
  }
}

///|
pub struct BuildIndirectParametersPipeline {
  bind_group_layout_label : String
  shader_path : String
  pipeline_id : Int?
}

///|
pub fn BuildIndirectParametersPipeline::new(
  bind_group_layout_label : String,
  shader_path : String,
) -> BuildIndirectParametersPipeline {
  BuildIndirectParametersPipeline::{
    bind_group_layout_label,
    shader_path,
    pipeline_id: None,
  }
}

///|
pub struct PreprocessPhasePipelines {
  reset_indirect_batch_sets : ResetIndirectBatchSetsPipeline
  gpu_occlusion_culling_build_indexed_indirect_params : BuildIndirectParametersPipeline
  gpu_occlusion_culling_build_non_indexed_indirect_params : BuildIndirectParametersPipeline
}

///|
pub fn preprocess_phase_pipelines_default(
  label_prefix : String,
) -> PreprocessPhasePipelines {
  PreprocessPhasePipelines::{
    reset_indirect_batch_sets: ResetIndirectBatchSetsPipeline::new(
      "\{label_prefix}_reset_indirect_batch_sets_layout",
      "pbr/render/reset_indirect_batch_sets.wgsl",
    ),
    gpu_occlusion_culling_build_indexed_indirect_params: BuildIndirectParametersPipeline::new(
      "\{label_prefix}_build_indexed_indirect_layout",
      "pbr/render/build_indirect_params.wgsl",
    ),
    gpu_occlusion_culling_build_non_indexed_indirect_params: BuildIndirectParametersPipeline::new(
      "\{label_prefix}_build_non_indexed_indirect_layout",
      "pbr/render/build_indirect_params.wgsl",
    ),
  }
}

///|
pub struct PreprocessPipelines {
  direct_preprocess : PreprocessPipeline
  gpu_frustum_culling_preprocess : PreprocessPipeline
  early_gpu_occlusion_culling_preprocess : PreprocessPipeline
  late_gpu_occlusion_culling_preprocess : PreprocessPipeline
  gpu_frustum_culling_build_indexed_indirect_params : BuildIndirectParametersPipeline
  gpu_frustum_culling_build_non_indexed_indirect_params : BuildIndirectParametersPipeline
  early_phase : PreprocessPhasePipelines
  late_phase : PreprocessPhasePipelines
  main_phase : PreprocessPhasePipelines
}

///|
pub fn preprocess_pipelines_default() -> PreprocessPipelines {
  PreprocessPipelines::{
    direct_preprocess: PreprocessPipeline::new(
      "direct_preprocess_layout", "pbr/render/mesh_preprocess.wgsl",
    ),
    gpu_frustum_culling_preprocess: PreprocessPipeline::new(
      "gpu_frustum_culling_preprocess_layout", "pbr/render/mesh_preprocess.wgsl",
    ),
    early_gpu_occlusion_culling_preprocess: PreprocessPipeline::new(
      "early_gpu_occlusion_culling_preprocess_layout", "pbr/render/mesh_preprocess.wgsl",
    ),
    late_gpu_occlusion_culling_preprocess: PreprocessPipeline::new(
      "late_gpu_occlusion_culling_preprocess_layout", "pbr/render/mesh_preprocess.wgsl",
    ),
    gpu_frustum_culling_build_indexed_indirect_params: BuildIndirectParametersPipeline::new(
      "gpu_frustum_culling_build_indexed_indirect_layout", "pbr/render/build_indirect_params.wgsl",
    ),
    gpu_frustum_culling_build_non_indexed_indirect_params: BuildIndirectParametersPipeline::new(
      "gpu_frustum_culling_build_non_indexed_indirect_layout", "pbr/render/build_indirect_params.wgsl",
    ),
    early_phase: preprocess_phase_pipelines_default("early_phase"),
    late_phase: preprocess_phase_pipelines_default("late_phase"),
    main_phase: preprocess_phase_pipelines_default("main_phase"),
  }
}

///|
pub struct PreprocessPipelineKey {
  bits : UInt
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn PreprocessPipelineKey::default() -> PreprocessPipelineKey {
  PreprocessPipelineKey::{ bits: 0U }
}

///|
pub fn preprocess_pipeline_key(
  frustum_culling : Bool,
  occlusion_culling : Bool,
  early_phase : Bool,
) -> PreprocessPipelineKey {
  PreprocessPipelineKey::{
    bits: (if frustum_culling {
      PREPROCESS_PIPELINE_KEY_FRUSTUM_CULLING
    } else {
      0U
    }) |
    (if occlusion_culling {
      PREPROCESS_PIPELINE_KEY_OCCLUSION_CULLING
    } else {
      0U
    }) |
    (if early_phase { PREPROCESS_PIPELINE_KEY_EARLY_PHASE } else { 0U }),
  }
}

///|
pub fn PreprocessPipelineKey::contains(
  self : PreprocessPipelineKey,
  flag : UInt,
) -> Bool {
  (self.bits & flag) != 0U
}

///|
pub fn PreprocessPipelineKey::shader_defs(
  self : PreprocessPipelineKey,
) -> Array[String] {
  let defs : Array[String] = []
  if self.contains(PREPROCESS_PIPELINE_KEY_FRUSTUM_CULLING) {
    defs.push("FRUSTUM_CULLING")
  }
  if self.contains(PREPROCESS_PIPELINE_KEY_OCCLUSION_CULLING) {
    defs.push("OCCLUSION_CULLING")
  }
  if self.contains(PREPROCESS_PIPELINE_KEY_EARLY_PHASE) {
    defs.push("EARLY_PHASE")
  }
  defs
}

///|
pub struct BuildIndirectParametersPipelineKey {
  bits : UInt
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn BuildIndirectParametersPipelineKey::default() -> BuildIndirectParametersPipelineKey {
  BuildIndirectParametersPipelineKey::{ bits: 0U }
}

///|
pub fn build_indirect_parameters_pipeline_key(
  indexed : Bool,
  multi_draw_indirect_count_supported : Bool,
  occlusion_culling : Bool,
  early_phase : Bool,
  late_phase : Bool,
  main_phase : Bool,
) -> BuildIndirectParametersPipelineKey {
  BuildIndirectParametersPipelineKey::{
    bits: (if indexed { BUILD_INDIRECT_KEY_INDEXED } else { 0U }) |
    (if multi_draw_indirect_count_supported {
      BUILD_INDIRECT_KEY_MULTI_DRAW_INDIRECT_COUNT_SUPPORTED
    } else {
      0U
    }) |
    (if occlusion_culling { BUILD_INDIRECT_KEY_OCCLUSION_CULLING } else { 0U }) |
    (if early_phase { BUILD_INDIRECT_KEY_EARLY_PHASE } else { 0U }) |
    (if late_phase { BUILD_INDIRECT_KEY_LATE_PHASE } else { 0U }) |
    (if main_phase { BUILD_INDIRECT_KEY_MAIN_PHASE } else { 0U }),
  }
}

///|
pub fn BuildIndirectParametersPipelineKey::contains(
  self : BuildIndirectParametersPipelineKey,
  flag : UInt,
) -> Bool {
  (self.bits & flag) != 0U
}

///|
pub fn BuildIndirectParametersPipelineKey::shader_defs(
  self : BuildIndirectParametersPipelineKey,
) -> Array[String] {
  let defs : Array[String] = []
  if self.contains(BUILD_INDIRECT_KEY_INDEXED) {
    defs.push("INDEXED")
  }
  if self.contains(BUILD_INDIRECT_KEY_MULTI_DRAW_INDIRECT_COUNT_SUPPORTED) {
    defs.push("MULTI_DRAW_INDIRECT_COUNT_SUPPORTED")
  }
  if self.contains(BUILD_INDIRECT_KEY_OCCLUSION_CULLING) {
    defs.push("OCCLUSION_CULLING")
  }
  if self.contains(BUILD_INDIRECT_KEY_EARLY_PHASE) {
    defs.push("EARLY_PHASE")
  }
  if self.contains(BUILD_INDIRECT_KEY_LATE_PHASE) {
    defs.push("LATE_PHASE")
  }
  if self.contains(BUILD_INDIRECT_KEY_MAIN_PHASE) {
    defs.push("MAIN_PHASE")
  }
  defs
}

///|
pub(all) enum PhasePreprocessBindGroups {
  Direct(Int)
  IndirectFrustumCulling(Int, Int)
  IndirectOcclusionCulling(Int, Int, Int?, Int?)
}

///|
fn render3d_preprocess_pipeline_id(label : String, shader_path : String) -> Int {
  label.length() * 131 + shader_path.length()
}

///|
pub fn render3d_prepare_preprocess_pipeline(
  pipeline : PreprocessPipeline,
) -> PreprocessPipeline {
  let pipeline_id = render3d_preprocess_pipeline_id(
    pipeline.bind_group_layout_label,
    pipeline.shader_path,
  )
  PreprocessPipeline::{ ..pipeline, pipeline_id: Some(pipeline_id) }
}

///|
pub fn render3d_prepare_reset_indirect_batch_sets_pipeline(
  pipeline : ResetIndirectBatchSetsPipeline,
) -> ResetIndirectBatchSetsPipeline {
  let pipeline_id = render3d_preprocess_pipeline_id(
    pipeline.bind_group_layout_label,
    pipeline.shader_path,
  )
  ResetIndirectBatchSetsPipeline::{ ..pipeline, pipeline_id: Some(pipeline_id) }
}

///|
pub fn render3d_prepare_build_indirect_parameters_pipeline(
  pipeline : BuildIndirectParametersPipeline,
) -> BuildIndirectParametersPipeline {
  let pipeline_id = render3d_preprocess_pipeline_id(
    pipeline.bind_group_layout_label,
    pipeline.shader_path,
  )
  BuildIndirectParametersPipeline::{
    ..pipeline,
    pipeline_id: Some(pipeline_id),
  }
}

///|
pub fn render3d_prepare_preprocess_phase_pipelines(
  phase_pipelines : PreprocessPhasePipelines,
) -> PreprocessPhasePipelines {
  PreprocessPhasePipelines::{
    reset_indirect_batch_sets: render3d_prepare_reset_indirect_batch_sets_pipeline(
      phase_pipelines.reset_indirect_batch_sets,
    ),
    gpu_occlusion_culling_build_indexed_indirect_params: render3d_prepare_build_indirect_parameters_pipeline(
      phase_pipelines.gpu_occlusion_culling_build_indexed_indirect_params,
    ),
    gpu_occlusion_culling_build_non_indexed_indirect_params: render3d_prepare_build_indirect_parameters_pipeline(
      phase_pipelines.gpu_occlusion_culling_build_non_indexed_indirect_params,
    ),
  }
}

///|
pub fn render3d_prepare_preprocess_pipelines(
  pipelines : PreprocessPipelines,
) -> PreprocessPipelines {
  PreprocessPipelines::{
    direct_preprocess: render3d_prepare_preprocess_pipeline(
      pipelines.direct_preprocess,
    ),
    gpu_frustum_culling_preprocess: render3d_prepare_preprocess_pipeline(
      pipelines.gpu_frustum_culling_preprocess,
    ),
    early_gpu_occlusion_culling_preprocess: render3d_prepare_preprocess_pipeline(
      pipelines.early_gpu_occlusion_culling_preprocess,
    ),
    late_gpu_occlusion_culling_preprocess: render3d_prepare_preprocess_pipeline(
      pipelines.late_gpu_occlusion_culling_preprocess,
    ),
    gpu_frustum_culling_build_indexed_indirect_params: render3d_prepare_build_indirect_parameters_pipeline(
      pipelines.gpu_frustum_culling_build_indexed_indirect_params,
    ),
    gpu_frustum_culling_build_non_indexed_indirect_params: render3d_prepare_build_indirect_parameters_pipeline(
      pipelines.gpu_frustum_culling_build_non_indexed_indirect_params,
    ),
    early_phase: render3d_prepare_preprocess_phase_pipelines(
      pipelines.early_phase,
    ),
    late_phase: render3d_prepare_preprocess_phase_pipelines(
      pipelines.late_phase,
    ),
    main_phase: render3d_prepare_preprocess_phase_pipelines(
      pipelines.main_phase,
    ),
  }
}

///|
pub fn render3d_preprocess_dispatch_workgroup_count(
  work_item_count : Int,
) -> Int {
  if work_item_count <= 0 {
    0
  } else {
    (work_item_count + RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE - 1) /
    RENDER3D_GPU_PREPROCESS_WORKGROUP_SIZE
  }
}
