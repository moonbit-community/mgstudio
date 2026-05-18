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
fn meshlet_wbtest_bytes_prefix(bytes : Bytes, count : Int) -> Array[Int] {
  let values : Array[Int] = []
  for index in 0..<count {
    match bytes.get(index) {
      Some(byte) => values.push(byte.to_int() & 0xFF)
      None => values.push(-1)
    }
  }
  values
}

///|
test "pbr/meshlet: mesh manager produces Bevy-shaped GPU buffer payloads" {
  let manager = MeshletMeshManager::default()
  let meshlet_mesh = MeshletMesh::from_parts(
    vertex_positions=[31, 32, 33],
    vertex_normals=[41, 42],
    vertex_uvs=[MeshletVertexUv::new(0.5, 0.25)],
    indices=[0, 2, 1],
    bvh=[BvhNode::default().with_child_count(0, 2)],
    meshlets=[Meshlet::new(0, 0, 0, 3, 1)],
    meshlet_cull_data=[MeshletCullData::default()],
  )
  ignore(manager.queue_upload_if_needed(11, meshlet_mesh))
  ignore(manager.perform_pending_mesh_writes())
  let instance_manager = InstanceManager::default()
  instance_manager.add_instance(
    @core.Entity::new(1, 0),
    7,
    0,
    MeshletAabb::default(),
    0,
  )
  ignore(
    queue_material_meshlet_meshes_with_present_material_assets(instance_manager),
  )
  ignore(queue_material_meshlet_meshes(instance_manager))
  let payload = manager.gpu_buffer_payload(instance_manager)
  debug_inspect(
    meshlet_wbtest_bytes_prefix(payload.vertex_positions, 12),
    content="[31, 0, 0, 0, 32, 0, 0, 0, 33, 0, 0, 0]",
  )
  debug_inspect(
    meshlet_wbtest_bytes_prefix(payload.vertex_normals, 8),
    content="[41, 0, 0, 0, 42, 0, 0, 0]",
  )
  debug_inspect(payload.vertex_uvs.length(), content="8")
  debug_inspect(
    meshlet_wbtest_bytes_prefix(payload.indices, 3),
    content="[0, 2, 1]",
  )
  debug_inspect(payload.bvh_nodes.length(), content="400")
  debug_inspect(payload.meshlets.length(), content="32")
  debug_inspect(payload.cull_data.length(), content="48")
  debug_inspect(payload.instance_uniforms.length(), content="176")
  debug_inspect(payload.instance_aabbs.length(), content="32")
  debug_inspect(
    meshlet_wbtest_bytes_prefix(payload.instance_material_ids, 4),
    content="[1, 0, 0, 0]",
  )
  debug_inspect(
    meshlet_wbtest_bytes_prefix(payload.instance_bvh_root_nodes, 4),
    content="[0, 0, 0, 0]",
  )
  debug_inspect(payload.byte_count(), content="727")
}
