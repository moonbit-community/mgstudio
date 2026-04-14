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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/material_shade_nodes.rs`.

///|
pub const MESHLET_MAIN_OPAQUE_PASS_NODE : String = "mgstudio.pbr.meshlet.main_opaque_pass"

///|
pub const MESHLET_PREPASS_NODE : String = "mgstudio.pbr.meshlet.prepass"

///|
pub const MESHLET_DEFERRED_GBUFFER_PREPASS_NODE : String = "mgstudio.pbr.meshlet.deferred_gbuffer_prepass"

///|
pub fn meshlet_material_shade_nodes() -> Array[String] {
  [
    MESHLET_MAIN_OPAQUE_PASS_NODE,
    MESHLET_PREPASS_NODE,
    MESHLET_DEFERRED_GBUFFER_PREPASS_NODE,
  ]
}

///|
pub fn meshlet_material_shade_node_count() -> Int {
  meshlet_material_shade_nodes().length()
}

///|
pub fn meshlet_material_shade_node_index(node : String) -> Int? {
  let nodes = meshlet_material_shade_nodes()
  for index in 0..<nodes.length() {
    if nodes[index] == node {
      return Some(index)
    }
  }
  None
}

///|
fn meshlet_clamp_draw_count(draw_count : Int) -> Int {
  if draw_count < 0 {
    0
  } else {
    draw_count
  }
}

///|
fn meshlet_pipeline_id_valid(pipeline_id : Int) -> Bool {
  pipeline_id >= 0
}

///|
pub struct MeshletMaterialDrawCall {
  material_id : Int
  material_pipeline_id : Int
  material_bind_group : Int
  vertex_start : Int
  vertex_end : Int
} derive(Eq, Debug)

///|
fn meshlet_material_bin_draw_calls(
  material_bins : Array[(Int, Int, Int)],
  instance_manager : InstanceManager,
  has_material_depth : Bool,
  has_material_shade_bind_group : Bool,
) -> Array[MeshletMaterialDrawCall] {
  if material_bins.is_empty() {
    return []
  }
  if !has_material_depth || !has_material_shade_bind_group {
    return []
  }
  let draw_calls : Array[MeshletMaterialDrawCall] = []
  for material_bin in material_bins {
    let (material_id, material_pipeline_id, material_bind_group) = material_bin
    if meshlet_pipeline_id_valid(material_pipeline_id) &&
      instance_manager.material_present_in_scene(material_id) {
      let vertex_start = material_id * 3
      draw_calls.push(MeshletMaterialDrawCall::{
        material_id,
        material_pipeline_id,
        material_bind_group,
        vertex_start,
        vertex_end: vertex_start + 3,
      })
    }
  }
  draw_calls
}

///|
fn meshlet_material_bin_draw_count(
  material_bins : Array[(Int, Int, Int)],
  instance_manager : InstanceManager,
  has_material_depth : Bool,
  has_material_shade_bind_group : Bool,
) -> Int {
  meshlet_material_bin_draw_calls(
    material_bins, instance_manager, has_material_depth, has_material_shade_bind_group,
  ).length()
}

///|
pub fn meshlet_main_opaque_pass_draw_calls(
  materials : MeshletViewMaterialsMainOpaquePass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Array[MeshletMaterialDrawCall] {
  meshlet_material_bin_draw_calls(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_prepass_draw_calls(
  materials : MeshletViewMaterialsPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Array[MeshletMaterialDrawCall] {
  meshlet_material_bin_draw_calls(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_deferred_gbuffer_prepass_draw_calls(
  materials : MeshletViewMaterialsDeferredGBufferPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Array[MeshletMaterialDrawCall] {
  meshlet_material_bin_draw_calls(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_main_opaque_pass_materials(
  materials : MeshletViewMaterialsMainOpaquePass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Int {
  meshlet_material_bin_draw_count(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_prepass_materials(
  materials : MeshletViewMaterialsPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Int {
  meshlet_material_bin_draw_count(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_deferred_gbuffer_prepass_materials(
  materials : MeshletViewMaterialsDeferredGBufferPrepass,
  instance_manager : InstanceManager,
  has_material_depth? : Bool = true,
  has_material_shade_bind_group? : Bool = true,
) -> Int {
  meshlet_material_bin_draw_count(
    materials.entries,
    instance_manager,
    has_material_depth,
    has_material_shade_bind_group,
  )
}

///|
pub fn meshlet_prepass(draw_count : Int) -> Int {
  meshlet_clamp_draw_count(draw_count)
}

///|
pub fn meshlet_deferred_gbuffer_prepass(draw_count : Int) -> Int {
  meshlet_clamp_draw_count(draw_count)
}

///|
pub fn meshlet_main_opaque_pass(draw_count : Int) -> Int {
  meshlet_clamp_draw_count(draw_count)
}
