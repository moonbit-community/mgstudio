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
test "pbr meshlet: main opaque pass draw count filters scene presence and pipeline validity" {
  let instance_manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 1), 7),
  ])
  ignore(
    queue_material_meshlet_meshes_with_material_assets(instance_manager, [7]),
  )
  ignore(queue_material_meshlet_meshes(instance_manager))
  let materials = MeshletViewMaterialsMainOpaquePass::default()
  materials.push((1, 100, 10))
  materials.push((2, 100, 11))
  materials.push((1, -1, 12))
  debug_inspect(
    meshlet_main_opaque_pass_materials(materials, instance_manager),
    content="1",
  )
}

///|
test "pbr meshlet: prepass draw count follows same filtering" {
  let instance_manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 1), 3),
  ])
  ignore(
    queue_material_meshlet_meshes_with_material_assets(instance_manager, [3]),
  )
  ignore(queue_material_meshlet_meshes(instance_manager))
  let prepass = MeshletViewMaterialsPrepass::default()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::default()
  prepass.push((1, 20, 1))
  prepass.push((99, 21, 2))
  deferred.push((1, 22, 3))
  debug_inspect(
    meshlet_prepass_materials(prepass, instance_manager),
    content="1",
  )
  debug_inspect(
    meshlet_deferred_gbuffer_prepass_materials(deferred, instance_manager),
    content="1",
  )
}
