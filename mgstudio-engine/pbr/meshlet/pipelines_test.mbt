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
test "pbr/meshlet: pipeline counters split compute and render paths" {
  let pipelines = init_meshlet_pipelines_with_core(10, 11, 12, 13)
  debug_inspect(meshlet_pipeline_count(pipelines), content="4")
  debug_inspect(meshlet_render_pipeline_count(pipelines), content="3")
  debug_inspect(meshlet_compute_pipeline_count(pipelines), content="1")
}

///|
test "pbr/meshlet: compatibility init keeps pipeline ids active" {
  let pipelines = init_meshlet_pipelines(21, 22, 23)
  debug_inspect(meshlet_pipeline_count(pipelines), content="4")
}

///|
test "pbr/meshlet: pipeline slot descriptors expose bevy-shaped surface" {
  let descriptors = meshlet_pipeline_slot_descriptors()
  debug_inspect(descriptors.length(), content="22")
}

///|
test "pbr/meshlet: queued pipeline descriptors mirror bevy init order and labels" {
  let descriptors = meshlet_pipeline_descriptors()
  debug_inspect(descriptors.length(), content="22")
  inspect(descriptors[0].slot_label, content="clear_visibility_buffer")
  inspect(
    descriptors[0].pipeline_label,
    content="meshlet_clear_visibility_buffer_pipeline",
  )
  inspect(descriptors[21].slot_label, content="remap_1d_to_2d_dispatch")
  debug_inspect(descriptors[21].enabled, content="false")
}

///|
test "pbr/meshlet: cull descriptors carry bevy shader defs and immediates" {
  let descriptors = meshlet_pipeline_descriptors()
  let first_instance_cull = descriptors[2]
  debug_inspect(first_instance_cull.immediate_size, content="4")
  inspect(first_instance_cull.shader_label, content="cull_instances.wgsl")
  debug_inspect(
    first_instance_cull.has_shader_def("MESHLET_INSTANCE_CULLING_PASS"),
    content="true",
  )
  debug_inspect(
    first_instance_cull.has_shader_def("MESHLET_FIRST_CULLING_PASS"),
    content="true",
  )
  let first_bvh_cull = descriptors[4]
  debug_inspect(first_bvh_cull.immediate_size, content="8")
  debug_inspect(
    first_bvh_cull.has_shader_def("MESHLET_BVH_CULLING_PASS"),
    content="true",
  )
}

///|
test "pbr/meshlet: raster and resolve descriptors expose render target depth state" {
  let descriptors = meshlet_pipeline_descriptors()
  let hardware_raster = descriptors[14]
  debug_inspect(hardware_raster.kind is Render, content="true")
  debug_inspect(hardware_raster.immediate_size, content="4")
  debug_inspect(hardware_raster.color_target_r8uint, content="true")
  debug_inspect(hardware_raster.color_write_mask_empty, content="true")
  debug_inspect(
    hardware_raster.has_shader_def(
      "MESHLET_VISIBILITY_BUFFER_RASTER_PASS_OUTPUT",
    ),
    content="true",
  )
  let resolve_material_depth = descriptors[19]
  debug_inspect(
    resolve_material_depth.depth_format is Depth16Unorm,
    content="true",
  )
  debug_inspect(resolve_material_depth.depth_write_enabled, content="true")
  debug_inspect(resolve_material_depth.depth_compare_always, content="true")
  debug_inspect(
    resolve_material_depth.entry_point,
    content="Some(\"resolve_material_depth\")",
  )
}

///|
test "pbr/meshlet: remap dispatch flag follows bevy empty shader-def shape" {
  let descriptors_without_remap = meshlet_pipeline_descriptors()
  let software_without_remap = descriptors_without_remap[12]
  debug_inspect(software_without_remap.compute_shader_defs[2], content="\"\"")
  let remap_without = descriptors_without_remap[21]
  debug_inspect(remap_without.optional, content="true")
  debug_inspect(remap_without.enabled, content="false")
  let descriptors_with_remap = meshlet_pipeline_descriptors(
    remap_dispatch_enabled=true,
  )
  let software_with_remap = descriptors_with_remap[12]
  debug_inspect(
    software_with_remap.compute_shader_defs[2],
    content="\"MESHLET_2D_DISPATCH\"",
  )
  let remap_with = descriptors_with_remap[21]
  debug_inspect(remap_with.enabled, content="true")
  debug_inspect(remap_with.immediate_size, content="4")
}

///|
test "pbr/meshlet: readiness reports missing required slots" {
  let pipelines = MeshletPipelines::MeshletPipelines()
  debug_inspect(meshlet_pipelines_ready(pipelines), content="false")
  let missing = meshlet_missing_required_pipeline_slots(pipelines)
  debug_inspect(missing.length() > 0, content="true")
  debug_inspect(pipelines.get() is None, content="true")
}
