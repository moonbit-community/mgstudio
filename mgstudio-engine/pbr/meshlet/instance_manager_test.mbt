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
test "pbr/meshlet: instance manager tracks counts and material ids" {
  let manager = InstanceManager::InstanceManager()
  manager.add_instance(@core.Entity::new(0, 1), 100, 4, MeshletAabb(), 3)
  manager.add_instance(@core.Entity::new(0, 2), 100, 9, MeshletAabb(), 7)
  debug_inspect(manager.instance_count(), content="2")
  debug_inspect(manager.max_bvh_depth(), content="7")

  let material_id0 = manager.get_material_id(100)
  let material_id1 = manager.get_material_id(100)
  debug_inspect(material_id0, content="1")
  debug_inspect(material_id1, content="1")

  manager.mark_material_present_in_scene(material_id0)
  debug_inspect(manager.material_present_in_scene(material_id0), content="true")
  debug_inspect(manager.present_material_count(), content="1")
  debug_inspect(manager.scene_material_asset_ids(), content="[100]")
  debug_inspect(manager.instance_bvh_root_nodes(), content="[4, 9]")
}

///|
test "pbr/meshlet: instance manager stores Bevy mesh uniform transforms and render layers" {
  let manager = InstanceManager::InstanceManager()
  let world_from_local = @transform.GlobalTransform::from_transform(
    @transform.Transform::from_xyz(4.0F, 5.0F, 6.0F),
  ).affine()
  let previous_world_from_local = @transform.GlobalTransform::from_transform(
    @transform.Transform::from_xyz(1.0F, 2.0F, 3.0F),
  ).affine()
  manager.add_instance(
    @core.Entity::new(0, 1),
    100,
    4,
    MeshletAabb(),
    3,
    render_layer_mask=8,
    world_from_local~,
    previous_world_from_local~,
  )
  let (_, render_layer_mask, not_shadow_caster) = manager.instances[0]
  debug_inspect(render_layer_mask, content="8")
  debug_inspect(not_shadow_caster, content="false")
  let uniform = manager.instance_uniforms[0]
  inspect(uniform.world_from_local.translation.x, content="4")
  inspect(uniform.previous_world_from_local.translation.x, content="1")
}

///|
test "pbr/meshlet: per-view instance visibility follows layers and shadow caster flags" {
  let manager = InstanceManager::InstanceManager()
  let view = @core.Entity::new(0, 100)
  manager.add_instance(
    @core.Entity::new(0, 1),
    100,
    4,
    MeshletAabb(),
    3,
    render_layer_mask=0b0001,
  )
  manager.add_instance(
    @core.Entity::new(0, 2),
    101,
    5,
    MeshletAabb(),
    3,
    render_layer_mask=0b0010,
  )
  manager.add_instance(
    @core.Entity::new(0, 3),
    102,
    6,
    MeshletAabb(),
    3,
    render_layer_mask=0b0001,
    not_shadow_caster=true,
  )
  let camera_visibility = manager.prepare_view_instance_visibility(
    view,
    view_render_layer_mask=0b0001,
  )
  debug_inspect(camera_visibility, content="[2]")
  debug_inspect(manager.view_instance_hidden(view, 0), content="false")
  debug_inspect(manager.view_instance_hidden(view, 1), content="true")
  debug_inspect(manager.view_instance_hidden(view, 2), content="false")

  let shadow_visibility = manager.prepare_view_instance_visibility(
    view,
    view_render_layer_mask=0b0001,
    shadow_view=true,
  )
  debug_inspect(shadow_visibility, content="[6]")
  debug_inspect(manager.view_instance_hidden(view, 1), content="true")
  debug_inspect(manager.view_instance_hidden(view, 2), content="true")
}

///|
test "pbr/meshlet: queue requires material ids prepared before scene usage is marked" {
  let manager = InstanceManager::InstanceManager()
  debug_inspect(queue_material_meshlet_meshes(manager), content="0")
  ignore(manager.get_material_id(1))
  ignore(manager.get_material_id(2))
  debug_inspect(manager.present_material_count(), content="0")
}

///|
test "pbr/meshlet: queue writes per-instance material ids" {
  let manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 10), 9),
    ExtractedMeshletInstance::new(@core.Entity::new(0, 11), 7),
    ExtractedMeshletInstance::new(@core.Entity::new(0, 12), 9),
  ])
  debug_inspect(manager.scene_material_asset_ids(), content="[7, 9]")
  ignore(manager.get_material_id(7))
  ignore(manager.get_material_id(9))
  debug_inspect(queue_material_meshlet_meshes(manager), content="2")
  debug_inspect(manager.instance_material_ids(), content="[2, 1, 2]")
}

///|
test "pbr/meshlet: material ids include Bevy material family" {
  let manager = InstanceManager::InstanceManager()
  manager.add_instance(
    @core.Entity::new(0, 1),
    7,
    1,
    MeshletAabb(),
    1,
    material_family=Standard,
  )
  manager.add_instance(
    @core.Entity::new(0, 2),
    7,
    2,
    MeshletAabb(),
    1,
    material_family=MeshletDebug,
  )
  debug_inspect(queue_material_meshlet_meshes(manager), content="2")
  debug_inspect(manager.instance_material_ids(), content="[1, 2]")
  let materials = manager.scene_materials()
  inspect(materials.length(), content="2")
  inspect(materials[0].material_family is Standard, content="true")
  inspect(materials[1].material_family is MeshletDebug, content="true")
}
