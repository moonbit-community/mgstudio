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
fn test_meshlet_shade_entry(
  material_id : Int,
  pipeline_id : Int,
  bind_group : Int,
) -> MeshletViewMaterialEntry {
  MeshletViewMaterialEntry::new(
    material_id,
    pipeline_id,
    bind_group,
    MeshletMaterialPipelineDescriptor::new(),
  )
}

///|
fn test_prepare_meshlet_material_ids(
  instance_manager : InstanceManager,
  material_asset_ids : Array[Int],
) -> Unit {
  for material_asset_id in material_asset_ids {
    ignore(instance_manager.get_material_id(material_asset_id))
  }
  ignore(queue_material_meshlet_meshes(instance_manager))
}

///|
test "pbr meshlet: main opaque pass draw count filters scene presence and pipeline validity" {
  let instance_manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 1), 7),
  ])
  test_prepare_meshlet_material_ids(instance_manager, [7])
  let materials = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  materials.push(test_meshlet_shade_entry(1, 100, 10))
  materials.push(test_meshlet_shade_entry(2, 100, 11))
  materials.push(test_meshlet_shade_entry(1, -1, 12))
  debug_inspect(
    meshlet_main_opaque_pass_materials(materials, instance_manager),
    content="1",
  )
  let draw_calls = meshlet_main_opaque_pass_draw_calls(
    materials, instance_manager,
  )
  debug_inspect(draw_calls.length(), content="1")
  debug_inspect(draw_calls[0].vertex_start, content="3")
  debug_inspect(draw_calls[0].vertex_end, content="6")
}

///|
test "pbr meshlet: main opaque shade descriptor mirrors bevy fullscreen pass" {
  let descriptor = meshlet_main_opaque_pass_descriptor()
  inspect(descriptor.pass_variant is MainOpaque, content="true")
  inspect(descriptor.label, content="meshlet_material_opaque_3d_pass")
  debug_inspect(descriptor.color_attachment_slots, content="[\"view_target\"]")
  inspect(descriptor.depth_load, content="Load")
  inspect(descriptor.depth_store, content="Store")
  inspect(descriptor.view_bind_group_kind, content="mesh_view")
  inspect(descriptor.view_bind_group_dynamic_offset_count, content="7")
  inspect(descriptor.sets_binding_array_group, content="true")
  inspect(descriptor.material_shade_bind_group_index, content="2")
  inspect(descriptor.material_bind_group_index, content="3")
}

///|
test "pbr meshlet: prepass shade descriptors preserve attachment topology" {
  let prepass = meshlet_prepass_descriptor(
    uses_motion_vector_prepass_bind_group=true,
  )
  let deferred = meshlet_deferred_gbuffer_prepass_descriptor()
  debug_inspect(
    prepass.color_attachment_slots,
    content="[\"normal\", \"motion_vectors\", \"none\", \"none\"]",
  )
  inspect(prepass.view_bind_group_kind, content="prepass_motion_vectors")
  inspect(prepass.view_bind_group_dynamic_offset_count, content="2")
  inspect(prepass.material_bind_group_index, content="2")
  debug_inspect(
    deferred.color_attachment_slots,
    content="[\"normal\", \"motion_vectors\", \"deferred\", \"deferred_lighting_pass_id\"]",
  )
  inspect(deferred.view_bind_group_kind, content="prepass_no_motion_vectors")
  inspect(deferred.view_bind_group_dynamic_offset_count, content="1")
}

///|
test "pbr meshlet: shade pass plan carries descriptor and filtered draws" {
  let instance_manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 1), 4),
  ])
  test_prepare_meshlet_material_ids(instance_manager, [4])
  let materials = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  materials.push(test_meshlet_shade_entry(1, 100, 10))
  materials.push(test_meshlet_shade_entry(2, -1, 11))
  let plan = meshlet_main_opaque_pass_plan(materials, instance_manager)
  inspect(plan.render_pass_enabled, content="true")
  inspect(plan.draw_count(), content="1")
  inspect(plan.descriptor.label, content="meshlet_material_opaque_3d_pass")
  inspect(plan.draw_calls[0].vertex_start, content="3")
  inspect(plan.draw_calls[0].vertex_end, content="6")
}

///|
test "pbr meshlet: main opaque pass commands mirror bevy bind and draw order" {
  let instance_manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 1), 4),
  ])
  test_prepare_meshlet_material_ids(instance_manager, [4])
  let materials = MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass()
  materials.push(test_meshlet_shade_entry(1, 42, 9))
  let plan = meshlet_main_opaque_pass_plan(materials, instance_manager)
  let commands = meshlet_material_shade_pass_commands(
    plan,
    has_camera_viewport=true,
  )
  inspect(commands.length(), content="8")
  inspect(commands[0].kind is BeginRenderPass, content="true")
  inspect(commands[0].label, content="meshlet_material_opaque_3d_pass")
  inspect(commands[1].kind is SetCameraViewport, content="true")
  inspect(commands[2].bind_group_index, content="0")
  inspect(commands[2].bind_group_kind, content="mesh_view")
  inspect(commands[2].dynamic_offset_count, content="7")
  inspect(commands[3].bind_group_index, content="1")
  inspect(commands[3].bind_group_kind, content="binding_array")
  inspect(commands[4].bind_group_index, content="2")
  inspect(commands[4].bind_group_kind, content="material_shade")
  inspect(commands[5].kind is SetRenderPipeline, content="true")
  inspect(commands[5].material_pipeline_id, content="42")
  inspect(commands[6].bind_group_index, content="3")
  inspect(commands[6].bind_group_kind, content="material")
  inspect(commands[6].material_bind_group, content="9")
  inspect(commands[7].vertex_start, content="3")
  inspect(commands[7].vertex_end, content="6")
}

///|
test "pbr meshlet: prepass commands preserve bevy group two replacement order" {
  let instance_manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 1), 8),
  ])
  test_prepare_meshlet_material_ids(instance_manager, [8])
  let materials = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  materials.push(test_meshlet_shade_entry(1, 33, 6))
  let plan = meshlet_prepass_plan(
    materials,
    instance_manager,
    uses_motion_vector_prepass_bind_group=true,
  )
  let commands = meshlet_material_shade_pass_commands(plan)
  inspect(commands.length(), content="7")
  inspect(commands[1].bind_group_index, content="0")
  inspect(commands[1].bind_group_kind, content="prepass_motion_vectors")
  inspect(commands[1].dynamic_offset_count, content="2")
  inspect(commands[2].bind_group_index, content="1")
  inspect(commands[2].bind_group_kind, content="empty")
  inspect(commands[3].bind_group_index, content="2")
  inspect(commands[3].bind_group_kind, content="material_shade")
  inspect(commands[5].bind_group_index, content="2")
  inspect(commands[5].bind_group_kind, content="material")
  inspect(commands[5].material_bind_group, content="6")
  inspect(commands[6].vertex_start, content="3")
  inspect(commands[6].vertex_end, content="6")
}

///|
test "pbr meshlet: prepass draw count follows same filtering" {
  let instance_manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 1), 3),
  ])
  test_prepare_meshlet_material_ids(instance_manager, [3])
  let prepass = MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass()
  let deferred = MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass()
  prepass.push(test_meshlet_shade_entry(1, 20, 1))
  prepass.push(test_meshlet_shade_entry(99, 21, 2))
  deferred.push(test_meshlet_shade_entry(1, 22, 3))
  debug_inspect(
    meshlet_prepass_materials(prepass, instance_manager),
    content="1",
  )
  debug_inspect(
    meshlet_deferred_gbuffer_prepass_materials(deferred, instance_manager),
    content="1",
  )
}
