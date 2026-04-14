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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/material_pipeline_prepare.rs`.

///|
pub struct MeshletViewMaterialsMainOpaquePass {
  mut entries : Array[(Int, Int, Int)]
}

///|
pub let ecs_key_meshlet_view_materials_main_opaque_pass : @ecs.ComponentKey[
  MeshletViewMaterialsMainOpaquePass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_main_opaque_pass",
)

///|
pub fn MeshletViewMaterialsMainOpaquePass::default() -> MeshletViewMaterialsMainOpaquePass {
  MeshletViewMaterialsMainOpaquePass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsMainOpaquePass::push(
  self : MeshletViewMaterialsMainOpaquePass,
  material_bin : (Int, Int, Int),
) -> Unit {
  self.entries.push(material_bin)
}

///|
pub fn MeshletViewMaterialsMainOpaquePass::len(
  self : MeshletViewMaterialsMainOpaquePass,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshletViewMaterialsMainOpaquePass::clear(
  self : MeshletViewMaterialsMainOpaquePass,
) -> Unit {
  self.entries = []
}

///|
pub struct MeshletViewMaterialsPrepass {
  mut entries : Array[(Int, Int, Int)]
}

///|
pub let ecs_key_meshlet_view_materials_prepass : @ecs.ComponentKey[
  MeshletViewMaterialsPrepass,
] = @ecs.register_component(debug_name="render3d.meshlet_view_materials_prepass")

///|
pub fn MeshletViewMaterialsPrepass::default() -> MeshletViewMaterialsPrepass {
  MeshletViewMaterialsPrepass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsPrepass::push(
  self : MeshletViewMaterialsPrepass,
  material_bin : (Int, Int, Int),
) -> Unit {
  self.entries.push(material_bin)
}

///|
pub fn MeshletViewMaterialsPrepass::len(
  self : MeshletViewMaterialsPrepass,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshletViewMaterialsPrepass::clear(
  self : MeshletViewMaterialsPrepass,
) -> Unit {
  self.entries = []
}

///|
pub struct MeshletViewMaterialsDeferredGBufferPrepass {
  mut entries : Array[(Int, Int, Int)]
}

///|
pub let ecs_key_meshlet_view_materials_deferred_gbuffer_prepass : @ecs.ComponentKey[
  MeshletViewMaterialsDeferredGBufferPrepass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_deferred_gbuffer_prepass",
)

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::default() -> MeshletViewMaterialsDeferredGBufferPrepass {
  MeshletViewMaterialsDeferredGBufferPrepass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::push(
  self : MeshletViewMaterialsDeferredGBufferPrepass,
  material_bin : (Int, Int, Int),
) -> Unit {
  self.entries.push(material_bin)
}

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::len(
  self : MeshletViewMaterialsDeferredGBufferPrepass,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::clear(
  self : MeshletViewMaterialsDeferredGBufferPrepass,
) -> Unit {
  self.entries = []
}

///|
pub fn meshlet_material_prepare_entry_count(
  main_opaque : MeshletViewMaterialsMainOpaquePass,
  prepass : MeshletViewMaterialsPrepass,
  deferred_prepass : MeshletViewMaterialsDeferredGBufferPrepass,
) -> Int {
  main_opaque.entries.length() +
  prepass.entries.length() +
  deferred_prepass.entries.length()
}

///|
fn meshlet_build_material_bins(
  material_ids : Array[Int],
  pipeline_base : Int,
  bind_group_base : Int,
) -> Array[(Int, Int, Int)] {
  let bins = []
  for index in 0..<material_ids.length() {
    let material_id = material_ids[index]
    bins.push((
      material_id,
      pipeline_base + material_id,
      bind_group_base + index,
    ))
  }
  bins
}

///|
pub fn prepare_material_meshlet_meshes_main_opaque_pass(
  view_materials : MeshletViewMaterialsMainOpaquePass,
  material_ids : Array[Int],
) -> Unit {
  view_materials.clear()
  let bins = meshlet_build_material_bins(material_ids, 1000, 0)
  for material_bin in bins {
    view_materials.push(material_bin)
  }
}

///|
pub fn prepare_material_meshlet_meshes_prepass(
  prepass_materials : MeshletViewMaterialsPrepass,
  deferred_prepass_materials : MeshletViewMaterialsDeferredGBufferPrepass,
  material_ids : Array[Int],
  deferred_enabled~ : Bool = true,
) -> Unit {
  prepass_materials.clear()
  deferred_prepass_materials.clear()
  let prepass_bins = meshlet_build_material_bins(
    material_ids,
    2000,
    100,
  )
  for material_bin in prepass_bins {
    prepass_materials.push(material_bin)
  }
  if deferred_enabled {
    let deferred_bins = meshlet_build_material_bins(
      material_ids,
      3000,
      200,
    )
    for material_bin in deferred_bins {
      deferred_prepass_materials.push(material_bin)
    }
  }
}

///|
pub impl @ecs.Component for MeshletViewMaterialsMainOpaquePass with component() {
  ecs_key_meshlet_view_materials_main_opaque_pass
}

///|
pub impl @ecs.Component for MeshletViewMaterialsPrepass with component() {
  ecs_key_meshlet_view_materials_prepass
}

///|
pub impl @ecs.Component for MeshletViewMaterialsDeferredGBufferPrepass with component() {
  ecs_key_meshlet_view_materials_deferred_gbuffer_prepass
}
