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
test "render3d: cluster pack/unpack keeps offset + point/spot counts" {
  let counts = ClusterableObjectCounts3d::new(17U, 9U, 3U, 5U, 2U)
  let packed = pbr_pack_cluster_offset_and_counts(1234U, counts)
  let unpacked = pbr_unpack_cluster_offset_and_counts(packed)
  debug_inspect(
    unpacked.offset() == 1234U &&
    unpacked.point_lights() == 17U &&
    unpacked.spot_lights() == 9U,
    content="true",
  )
}

///|
test "render3d: view cluster bindings enforce index/offset bounds" {
  let bindings = ViewClusterBindings3d::with_limits(2, 1)
  let counts = ClusterableObjectCounts3d::default()
  debug_inspect(bindings.push_offset_and_counts(0U, counts), content="true")
  debug_inspect(bindings.push_offset_and_counts(1U, counts), content="false")

  debug_inspect(bindings.push_index(10U), content="true")
  debug_inspect(bindings.push_dummy_index(), content="true")
  debug_inspect(bindings.push_index(11U), content="false")

  debug_inspect(bindings.n_offsets(), content="1")
  debug_inspect(bindings.n_indices(), content="2")
  debug_inspect(bindings.index(1) == Some(0xFFFF_FFFFU), content="true")
}
