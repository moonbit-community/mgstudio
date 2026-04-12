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
  entries : Array[(Int, Int, Int)]
}

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
pub struct MeshletViewMaterialsPrepass {
  entries : Array[(Int, Int, Int)]
}

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
pub struct MeshletViewMaterialsDeferredGBufferPrepass {
  entries : Array[(Int, Int, Int)]
}

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
pub fn meshlet_material_pipeline_prepare_runtime_available() -> Bool {
  meshlet_runtime_available()
}
