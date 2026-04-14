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
  let manager = InstanceManager::default()
  manager.add_instance(
    @core.Entity::new(0, 1),
    100,
    4,
    MeshletAabb::default(),
    3,
  )
  manager.add_instance(
    @core.Entity::new(0, 2),
    100,
    9,
    MeshletAabb::default(),
    7,
  )
  debug_inspect(manager.instance_count(), content="2")
  debug_inspect(manager.max_bvh_depth(), content="7")

  let material_id0 = manager.get_material_id(100)
  let material_id1 = manager.get_material_id(100)
  debug_inspect(material_id0, content="1")
  debug_inspect(material_id1, content="1")

  manager.mark_material_present_in_scene(material_id0)
  debug_inspect(manager.material_present_in_scene(material_id0), content="true")
  debug_inspect(manager.present_material_count(), content="1")
  debug_inspect(manager.instance_bvh_root_nodes(), content="[4, 9]")
}

///|
test "pbr/meshlet: queue helper requires extracted instances to mark scene usage" {
  let manager = InstanceManager::default()
  ignore(queue_material_meshlet_meshes_with_material_assets(manager, [1, 2, 1]))
  debug_inspect(queue_material_meshlet_meshes(manager), content="0")
}

///|
test "pbr/meshlet: queue writes per-instance material ids" {
  let manager = extract_meshlet_mesh_entities_from_instances([
    ExtractedMeshletInstance::new(@core.Entity::new(0, 10), 9),
    ExtractedMeshletInstance::new(@core.Entity::new(0, 11), 7),
    ExtractedMeshletInstance::new(@core.Entity::new(0, 12), 9),
  ])
  ignore(queue_material_meshlet_meshes_with_material_assets(manager, [7, 9]))
  debug_inspect(queue_material_meshlet_meshes(manager), content="2")
  debug_inspect(manager.instance_material_ids(), content="[2, 1, 2]")
}
