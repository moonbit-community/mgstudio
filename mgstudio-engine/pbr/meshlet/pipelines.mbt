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
pub(all) enum MeshletPipelineKind {
  Compute
  Render
}

///|
pub struct MeshletPipelineSlotDescriptor {
  label : String
  kind : MeshletPipelineKind
  optional : Bool
  enabled : Bool
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
pub fn meshlet_pipeline_slot_descriptors(
  remap_dispatch_enabled? : Bool = false,
) -> Array[MeshletPipelineSlotDescriptor] {
  [
    MeshletPipelineSlotDescriptor::{
      label: "clear_visibility_buffer",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "clear_visibility_buffer_shadow_view",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "first_instance_cull",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "second_instance_cull",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "first_bvh_cull",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "second_bvh_cull",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "first_meshlet_cull",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "second_meshlet_cull",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "downsample_depth_first",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "downsample_depth_second",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "downsample_depth_first_shadow_view",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "downsample_depth_second_shadow_view",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "visibility_buffer_software_raster",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "visibility_buffer_software_raster_shadow_view",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "visibility_buffer_hardware_raster",
      kind: MeshletPipelineKind::Render,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "visibility_buffer_hardware_raster_shadow_view",
      kind: MeshletPipelineKind::Render,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "visibility_buffer_hardware_raster_shadow_view_unclipped",
      kind: MeshletPipelineKind::Render,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "resolve_depth",
      kind: MeshletPipelineKind::Render,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "resolve_depth_shadow_view",
      kind: MeshletPipelineKind::Render,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "resolve_material_depth",
      kind: MeshletPipelineKind::Render,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "fill_counts",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "meshlet_mesh_material_shader",
      kind: MeshletPipelineKind::Compute,
      optional: false,
      enabled: true,
    },
    MeshletPipelineSlotDescriptor::{
      label: "remap_1d_to_2d_dispatch",
      kind: MeshletPipelineKind::Compute,
      optional: true,
      enabled: remap_dispatch_enabled,
    },
  ]
}

///|
fn meshlet_pipeline_slot_id(
  pipelines : MeshletPipelines,
  label : String,
) -> Int? {
  match label {
    "clear_visibility_buffer" => Some(pipelines.clear_visibility_buffer)
    "clear_visibility_buffer_shadow_view" =>
      Some(pipelines.clear_visibility_buffer_shadow_view)
    "first_instance_cull" => Some(pipelines.first_instance_cull)
    "second_instance_cull" => Some(pipelines.second_instance_cull)
    "first_bvh_cull" => Some(pipelines.first_bvh_cull)
    "second_bvh_cull" => Some(pipelines.second_bvh_cull)
    "first_meshlet_cull" => Some(pipelines.first_meshlet_cull)
    "second_meshlet_cull" => Some(pipelines.second_meshlet_cull)
    "downsample_depth_first" => Some(pipelines.downsample_depth_first)
    "downsample_depth_second" => Some(pipelines.downsample_depth_second)
    "downsample_depth_first_shadow_view" =>
      Some(pipelines.downsample_depth_first_shadow_view)
    "downsample_depth_second_shadow_view" =>
      Some(pipelines.downsample_depth_second_shadow_view)
    "visibility_buffer_software_raster" =>
      Some(pipelines.visibility_buffer_software_raster)
    "visibility_buffer_software_raster_shadow_view" =>
      Some(pipelines.visibility_buffer_software_raster_shadow_view)
    "visibility_buffer_hardware_raster" =>
      Some(pipelines.visibility_buffer_hardware_raster)
    "visibility_buffer_hardware_raster_shadow_view" =>
      Some(pipelines.visibility_buffer_hardware_raster_shadow_view)
    "visibility_buffer_hardware_raster_shadow_view_unclipped" =>
      Some(pipelines.visibility_buffer_hardware_raster_shadow_view_unclipped)
    "resolve_depth" => Some(pipelines.resolve_depth)
    "resolve_depth_shadow_view" => Some(pipelines.resolve_depth_shadow_view)
    "resolve_material_depth" => Some(pipelines.resolve_material_depth)
    "fill_counts" => Some(pipelines.fill_counts)
    "meshlet_mesh_material_shader" =>
      Some(pipelines.meshlet_mesh_material_shader_id)
    "remap_1d_to_2d_dispatch" => pipelines.remap_1d_to_2d_dispatch
    _ => None
  }
}

///|
pub fn meshlet_missing_required_pipeline_slots(
  pipelines : MeshletPipelines,
  remap_dispatch_enabled? : Bool = false,
) -> Array[String] {
  let missing : Array[String] = []
  for descriptor in meshlet_pipeline_slot_descriptors(remap_dispatch_enabled~) {
    if !descriptor.enabled {
      continue
    }
    match meshlet_pipeline_slot_id(pipelines, descriptor.label) {
      Some(id) =>
        if !meshlet_pipeline_is_valid(id) {
          missing.push(descriptor.label)
        }
      None => if !descriptor.optional { missing.push(descriptor.label) }
    }
  }
  missing
}

///|
pub fn meshlet_pipelines_ready(
  pipelines : MeshletPipelines,
  remap_dispatch_enabled? : Bool = false,
) -> Bool {
  meshlet_missing_required_pipeline_slots(pipelines, remap_dispatch_enabled~).is_empty()
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
