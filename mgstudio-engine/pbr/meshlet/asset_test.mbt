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
test "pbr/meshlet: meshlet asset metadata is bevy-shaped" {
  let meshlet_mesh = MeshletMesh::new(3, 2)
    .with_vertex_buffers(64, 64, 32, 96)
    .with_bvh_depth(4)
  debug_inspect(meshlet_mesh.meshlet_count(), content="3")
  debug_inspect(meshlet_mesh.bvh_node_count(), content="2")
  debug_inspect(meshlet_mesh.vertex_position_word_count(), content="64")
  debug_inspect(meshlet_mesh.vertex_normal_word_count(), content="64")
  debug_inspect(meshlet_mesh.index_count(), content="96")
  debug_inspect(meshlet_mesh.vertex_count_estimate(), content="32")
  debug_inspect(meshlet_mesh.is_empty(), content="false")
  debug_inspect(meshlet_mesh_asset_magic(), content="1717551717668")
  debug_inspect(meshlet_mesh_asset_version_matches(3), content="true")
}

///|
test "pbr/meshlet: meshlet asset stores real bevy slice data" {
  let meshlet = Meshlet::new(1, 2, 3, 4, 5)
    .with_quantization(6, 7, 8, 9)
    .with_min_vertex_position_channels(10.0, 11.0, 12.0)
  let bvh = BvhNode::default().with_child_count(0, 255)
  let cull = MeshletCullData::default()
  let aabb = MeshletAabb::new(
    center_x=1.0,
    center_y=2.0,
    center_z=3.0,
    half_extent_x=4.0,
    half_extent_y=5.0,
    half_extent_z=6.0,
  )
  let meshlet_mesh = MeshletMesh::from_parts(
    vertex_positions=[10, 11],
    vertex_normals=[20],
    vertex_uvs=[MeshletVertexUv::new(0.25, 0.75)],
    indices=[0, 1, 2],
    bvh=[bvh],
    meshlets=[meshlet],
    meshlet_cull_data=[cull],
    aabb~,
    bvh_depth=3,
  )
  debug_inspect(meshlet_mesh.vertex_positions, content="[10, 11]")
  debug_inspect(meshlet_mesh.vertex_normals, content="[20]")
  debug_inspect(meshlet_mesh.indices, content="[0, 1, 2]")
  debug_inspect(meshlet_mesh.bvh[0].child_counts[0], content="255")
  debug_inspect(meshlet_mesh.meshlets[0].triangle_count, content="5")
  debug_inspect(
    meshlet_mesh.meshlets[0].min_vertex_position_channel_z,
    content="12",
  )
  debug_inspect(meshlet_mesh.aabb.half_extent_z, content="6")
  debug_inspect(meshlet_mesh.bvh_depth, content="3")
}

///|
test "pbr/meshlet: save/load error debug helper keeps exact reason" {
  let message = meshlet_mesh_save_or_load_error_debug_message(WrongVersion(2))
  debug_inspect(message, content="\"wrong version: 2\"")
}
