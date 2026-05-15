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
  let message = meshlet_mesh_save_or_load_error_debug_message(WrongVersion(2UL))
  debug_inspect(message, content="\"wrong version: 2\"")
}

///|
fn test_meshlet_asset_fixture() -> MeshletMesh {
  let meshlet = Meshlet::new(32, 4, 7, 9, 3)
    .with_quantization(10, 11, 12, 2)
    .with_min_vertex_position_channels(-1.5, 2.25, 4.5)
  let bvh = BvhNode::default().with_child_count(0, 255)
  let aabb = MeshletAabb::new(
    center_x=1.0,
    center_y=2.0,
    center_z=3.0,
    half_extent_x=4.0,
    half_extent_y=5.0,
    half_extent_z=6.0,
  )
  MeshletMesh::from_parts(
    vertex_positions=[0x11223344, 0x01020304],
    vertex_normals=[0x55667788],
    vertex_uvs=[MeshletVertexUv::new(0.125, 0.875)],
    indices=[0, 1, 2, 255],
    bvh=[bvh],
    meshlets=[meshlet],
    meshlet_cull_data=[MeshletCullData::default()],
    aabb~,
    bvh_depth=5,
  )
}

///|
test "pbr/meshlet: bevy bytes round trip all raw slices" {
  let meshlet_mesh = test_meshlet_asset_fixture()
  let bytes = meshlet_mesh_encode_bevy_bytes(meshlet_mesh)
  debug_inspect(bytes.length() > 44, content="true")
  match meshlet_mesh_decode_bevy_bytes(bytes) {
    MeshletMeshLoadOk(round_trip) => {
      debug_inspect(
        round_trip.vertex_positions,
        content="[287454020, 16909060]",
      )
      debug_inspect(round_trip.vertex_normals, content="[1432778632]")
      debug_inspect(round_trip.indices, content="[0, 1, 2, 255]")
      debug_inspect(round_trip.vertex_uvs[0].y, content="0.875")
      debug_inspect(round_trip.bvh[0].child_counts[0], content="255")
      debug_inspect(round_trip.meshlets[0].triangle_count, content="3")
      debug_inspect(
        round_trip.meshlets[0].min_vertex_position_channel_x,
        content="-1.5",
      )
      debug_inspect(round_trip.aabb.half_extent_z, content="6")
      debug_inspect(round_trip.bvh_depth, content="5")
    }
    MeshletMeshLoadErr(error) =>
      debug_inspect(
        meshlet_mesh_save_or_load_error_debug_message(error),
        content="\"unexpected error\"",
      )
  }
}

///|
test "pbr/meshlet: loader rejects wrong file type before decompression" {
  let bytes = Bytes::from_array(Array::make(44, (0).to_byte()))
  match meshlet_mesh_decode_bevy_bytes(bytes) {
    MeshletMeshLoadErr(WrongFileType) => debug_inspect(true, content="true")
    _ => debug_inspect(false, content="true")
  }
}

///|
test "pbr/meshlet: loader rejects wrong version before decompression" {
  let raw = meshlet_mesh_encode_bevy_bytes(test_meshlet_asset_fixture()).to_array()
  raw[8] = (2).to_byte()
  match meshlet_mesh_decode_bevy_bytes(Bytes::from_array(raw)) {
    MeshletMeshLoadErr(WrongVersion(2UL)) => debug_inspect(true, content="true")
    other =>
      debug_inspect(
        match other {
          MeshletMeshLoadOk(_) => "ok"
          MeshletMeshLoadErr(error) =>
            meshlet_mesh_save_or_load_error_debug_message(error)
        },
        content="\"wrong version: 2\"",
      )
  }
}

///|
test "pbr/meshlet: bevy lz4-frame bytes round trip through loader" {
  let raw = meshlet_mesh_saver().save_bytes(test_meshlet_asset_fixture())
  debug_inspect(
    meshlet_mesh_loader().extensions(),
    content="[\"meshlet_mesh\"]",
  )
  match meshlet_mesh_loader().load_bytes(raw) {
    MeshletMeshLoadOk(meshlet_mesh) => {
      debug_inspect(
        meshlet_mesh.vertex_positions,
        content="[287454020, 16909060]",
      )
      debug_inspect(meshlet_mesh.indices, content="[0, 1, 2, 255]")
      debug_inspect(meshlet_mesh.bvh[0].child_counts[0], content="255")
      debug_inspect(meshlet_mesh.meshlets[0].vertex_count(), content="9")
      debug_inspect(meshlet_mesh.bvh_depth, content="5")
    }
    MeshletMeshLoadErr(error) =>
      debug_inspect(
        meshlet_mesh_save_or_load_error_debug_message(error),
        content="\"unexpected error\"",
      )
  }
}

///|
test "pbr/meshlet: loader decodes compressed lz4 block payloads" {
  let raw : Array[Byte] = [
    36, 93, 15, 230, 143, 1, 0, 0, // meshlet magic
     3, 0, 0, 0, 0, 0, 0, 0, // asset version
     0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // AABB
     0, 0, 0, 0, // BVH depth
     4, 34, 77, 24, 96, 64, 130, // LZ4 frame header
     5, 0, 0, 0, // compressed block length
     31, 0, 1, 0, 36, // 56 zero bytes: 1 literal + offset-1 match
     0, 0, 0, 0, // end mark
  ]
  match meshlet_mesh_decode_bevy_bytes(Bytes::from_array(raw)) {
    MeshletMeshLoadOk(meshlet_mesh) => {
      debug_inspect(meshlet_mesh.meshlet_count(), content="0")
      debug_inspect(meshlet_mesh.bvh_node_count(), content="0")
      debug_inspect(meshlet_mesh.index_count(), content="0")
      debug_inspect(meshlet_mesh.bvh_depth, content="0")
    }
    MeshletMeshLoadErr(error) =>
      debug_inspect(
        meshlet_mesh_save_or_load_error_debug_message(error),
        content="\"unexpected error\"",
      )
  }
}
