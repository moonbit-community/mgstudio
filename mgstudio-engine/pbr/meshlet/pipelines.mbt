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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/pipelines.rs`.

///|
pub struct MeshletPipelines {
  clear_visibility_buffer : Int
  clear_visibility_buffer_shadow_view : Int
  first_instance_cull : Int
  second_instance_cull : Int
  first_bvh_cull : Int
  second_bvh_cull : Int
  first_meshlet_cull : Int
  second_meshlet_cull : Int
  downsample_depth_first : Int
  downsample_depth_second : Int
  downsample_depth_first_shadow_view : Int
  downsample_depth_second_shadow_view : Int
  visibility_buffer_software_raster : Int
  visibility_buffer_software_raster_shadow_view : Int
  visibility_buffer_hardware_raster : Int
  visibility_buffer_hardware_raster_shadow_view : Int
  visibility_buffer_hardware_raster_shadow_view_unclipped : Int
  resolve_depth : Int
  resolve_depth_shadow_view : Int
  resolve_material_depth : Int
  remap_1d_to_2d_dispatch : Int?
  fill_counts : Int
  meshlet_mesh_material_shader_id : Int
}

///|
pub fn MeshletPipelines::default() -> MeshletPipelines {
  MeshletPipelines::{
    clear_visibility_buffer: -1,
    clear_visibility_buffer_shadow_view: -1,
    first_instance_cull: -1,
    second_instance_cull: -1,
    first_bvh_cull: -1,
    second_bvh_cull: -1,
    first_meshlet_cull: -1,
    second_meshlet_cull: -1,
    downsample_depth_first: -1,
    downsample_depth_second: -1,
    downsample_depth_first_shadow_view: -1,
    downsample_depth_second_shadow_view: -1,
    visibility_buffer_software_raster: -1,
    visibility_buffer_software_raster_shadow_view: -1,
    visibility_buffer_hardware_raster: -1,
    visibility_buffer_hardware_raster_shadow_view: -1,
    visibility_buffer_hardware_raster_shadow_view_unclipped: -1,
    resolve_depth: -1,
    resolve_depth_shadow_view: -1,
    resolve_material_depth: -1,
    remap_1d_to_2d_dispatch: None,
    fill_counts: -1,
    meshlet_mesh_material_shader_id: -1,
  }
}

///|
fn meshlet_pipeline_sanitize_id(value : Int) -> Int {
  if value < 0 {
    -1
  } else {
    value
  }
}

///|
fn meshlet_pipeline_is_valid(value : Int) -> Bool {
  value >= 0
}

///|
pub fn init_meshlet_pipelines_with_core(
  visibility_buffer_hardware_raster : Int,
  resolve_depth : Int,
  resolve_material_depth : Int,
  fill_counts : Int,
) -> MeshletPipelines {
  let pipelines = MeshletPipelines::default()
  MeshletPipelines::{
    ..pipelines,
    visibility_buffer_hardware_raster: meshlet_pipeline_sanitize_id(
      visibility_buffer_hardware_raster,
    ),
    resolve_depth: meshlet_pipeline_sanitize_id(resolve_depth),
    resolve_material_depth: meshlet_pipeline_sanitize_id(resolve_material_depth),
    fill_counts: meshlet_pipeline_sanitize_id(fill_counts),
  }
}

///|
pub fn init_meshlet_pipelines(
  main_opaque_pipeline_id : Int,
  prepass_pipeline_id : Int,
  deferred_prepass_pipeline_id : Int,
) -> MeshletPipelines {
  let pipelines = init_meshlet_pipelines_with_core(
    main_opaque_pipeline_id, prepass_pipeline_id, deferred_prepass_pipeline_id, -1,
  )
  MeshletPipelines::{
    ..pipelines,
    visibility_buffer_software_raster: meshlet_pipeline_sanitize_id(
      main_opaque_pipeline_id,
    ),
  }
}

///|
pub fn meshlet_pipeline_count(pipelines : MeshletPipelines) -> Int {
  let base_count = [
    pipelines.clear_visibility_buffer,
    pipelines.clear_visibility_buffer_shadow_view,
    pipelines.first_instance_cull,
    pipelines.second_instance_cull,
    pipelines.first_bvh_cull,
    pipelines.second_bvh_cull,
    pipelines.first_meshlet_cull,
    pipelines.second_meshlet_cull,
    pipelines.downsample_depth_first,
    pipelines.downsample_depth_second,
    pipelines.downsample_depth_first_shadow_view,
    pipelines.downsample_depth_second_shadow_view,
    pipelines.visibility_buffer_software_raster,
    pipelines.visibility_buffer_software_raster_shadow_view,
    pipelines.visibility_buffer_hardware_raster,
    pipelines.visibility_buffer_hardware_raster_shadow_view,
    pipelines.visibility_buffer_hardware_raster_shadow_view_unclipped,
    pipelines.resolve_depth,
    pipelines.resolve_depth_shadow_view,
    pipelines.resolve_material_depth,
    pipelines.fill_counts,
    pipelines.meshlet_mesh_material_shader_id,
  ].fold(init=0, fn(acc, id) {
    if meshlet_pipeline_is_valid(id) {
      acc + 1
    } else {
      acc
    }
  })
  let optional_count = if pipelines.remap_1d_to_2d_dispatch is Some(_) {
    1
  } else {
    0
  }
  base_count + optional_count
}

///|
pub fn meshlet_render_pipeline_count(pipelines : MeshletPipelines) -> Int {
  let render_ids = [
    pipelines.visibility_buffer_hardware_raster,
    pipelines.visibility_buffer_hardware_raster_shadow_view,
    pipelines.visibility_buffer_hardware_raster_shadow_view_unclipped,
    pipelines.resolve_depth,
    pipelines.resolve_depth_shadow_view,
    pipelines.resolve_material_depth,
  ]
  render_ids.fold(init=0, fn(acc, id) {
    if meshlet_pipeline_is_valid(id) {
      acc + 1
    } else {
      acc
    }
  })
}

///|
pub fn meshlet_compute_pipeline_count(pipelines : MeshletPipelines) -> Int {
  meshlet_pipeline_count(pipelines) - meshlet_render_pipeline_count(pipelines)
}
