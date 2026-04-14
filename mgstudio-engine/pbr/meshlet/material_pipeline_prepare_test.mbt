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
test "pbr meshlet: material prepare entry count aggregates all passes" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::default()
  let prepass = MeshletViewMaterialsPrepass::default()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
  main_opaque.push((1, 2, 3))
  prepass.push((4, 5, 6))
  inspect(
    meshlet_material_prepare_entry_count(main_opaque, prepass, deferred),
    content="2",
  )
}

///|
test "pbr meshlet: prepare main opaque pass fills bins from material ids" {
  let main_opaque = MeshletViewMaterialsMainOpaquePass::default()
  prepare_material_meshlet_meshes_main_opaque_pass(main_opaque, [10, 20, 30])
  inspect(main_opaque.len(), content="3")
}

///|
test "pbr meshlet: prepare prepass respects deferred toggle" {
  let prepass = MeshletViewMaterialsPrepass::default()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
  prepare_material_meshlet_meshes_prepass(
    prepass,
    deferred,
    [7, 8],
    deferred_enabled=false,
  )
  inspect(prepass.len(), content="2")
  inspect(deferred.len(), content="0")
}
