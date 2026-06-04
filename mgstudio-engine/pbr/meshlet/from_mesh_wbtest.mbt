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
fn meshlet_wbtest_aabb(
  x : Float,
  y : Float,
  z : Float,
  half : Float,
) -> @math.Aabb3d {
  @math.Aabb3d::new(@math.Vec3::new(x, y, z), @math.Vec3::splat(half))
}

///|
fn meshlet_wbtest_sphere(
  x : Float,
  y : Float,
  z : Float,
  radius : Float,
) -> MeshletTempSphere {
  MeshletTempSphere::new(@math.Vec3::new(x, y, z), radius)
}

///|
fn meshlet_wbtest_cull(id : Int) -> MeshletTempCullData {
  let x = Float::from_int(id) * 2.0F
  MeshletTempCullData::{
    aabb: meshlet_wbtest_aabb(x, 0.0F, 0.0F, 0.5F),
    lod_group_sphere: meshlet_wbtest_sphere(x, 0.0F, 0.0F, 0.5F),
    error: Float::from_int(id) * 0.01F,
  }
}

///|
fn meshlet_wbtest_group(id : Int, meshlets : Array[Int]) -> MeshletTempGroup {
  let mut aabb = meshlet_bvh_default_aabb()
  let mut lod_bounds = meshlet_temp_sphere_zero()
  let mut parent_error = Float::from_int(id) * 0.01F
  for meshlet_id in meshlets {
    let cull_data = meshlet_wbtest_cull(meshlet_id)
    aabb = meshlet_bvh_merge_aabb(aabb, cull_data.aabb)
    lod_bounds = meshlet_merge_spheres(lod_bounds, cull_data.lod_group_sphere)
    parent_error = parent_error.max(cull_data.error)
  }
  MeshletTempGroup::new(aabb~, lod_bounds~, parent_error~, meshlets~)
}

///|
fn meshlet_wbtest_build_meshlets() -> MeshletBuildMeshlets {
  MeshletBuildMeshlets::new(
    meshlets=[
      MeshletBuildMeshlet::new(
        vertex_offset=0,
        triangle_offset=0,
        vertex_count=3,
        triangle_count=1,
      ),
      MeshletBuildMeshlet::new(
        vertex_offset=3,
        triangle_offset=3,
        vertex_count=3,
        triangle_count=1,
      ),
      MeshletBuildMeshlet::new(
        vertex_offset=6,
        triangle_offset=6,
        vertex_count=3,
        triangle_count=1,
      ),
    ],
    vertices=[0, 1, 2, 2, 1, 3, 4, 5, 6],
    triangles=[0, 1, 2, 0, 1, 2, 0, 1, 2],
  )
}

///|
fn meshlet_wbtest_build_meshlets_count(count : Int) -> MeshletBuildMeshlets {
  let meshlets : Array[MeshletBuildMeshlet] = []
  let vertices : Array[Int] = []
  let triangles : Array[Int] = []
  for id in 0..<count {
    meshlets.push(
      MeshletBuildMeshlet::new(
        vertex_offset=id * 3,
        triangle_offset=id * 3,
        vertex_count=3,
        triangle_count=1,
      ),
    )
    vertices.push(id * 3)
    vertices.push(id * 3 + 1)
    vertices.push(id * 3 + 2)
    triangles.push(0)
    triangles.push(1)
    triangles.push(2)
  }
  MeshletBuildMeshlets::new(meshlets~, vertices~, triangles~)
}

///|
fn meshlet_wbtest_source_vertices(count : Int) -> Array[MeshletSourceVertex] {
  let vertices : Array[MeshletSourceVertex] = []
  for index in 0..<count {
    let x = Float::from_int(index)
    vertices.push(
      MeshletSourceVertex::new(
        position=@math.Vec3::new(x, x * 0.25F, 0.0F),
        normal=@math.Vec3::new(0.0F, 1.0F, 0.0F),
        uv=@math.Vec2::new(x * 0.125F, 0.5F),
      ),
    )
  }
  vertices
}

///|
test "pbr meshlet wbtest: merge spheres preserves containing sphere" {
  let left = meshlet_wbtest_sphere(0.0F, 0.0F, 0.0F, 10.0F)
  let right = meshlet_wbtest_sphere(1.0F, 0.0F, 0.0F, 1.0F)
  let merged = meshlet_merge_spheres(left, right)
  debug_inspect(merged.center.x, content="0")
  debug_inspect(merged.radius, content="10")
}

///|
test "pbr meshlet wbtest: bvh builder remaps group meshlets contiguously" {
  let meshlets = meshlet_wbtest_build_meshlets()
  let cull = [meshlet_wbtest_cull(0), meshlet_wbtest_cull(1)]
  let groups = [meshlet_wbtest_group(0, [1, 0])]
  let builder = MeshletBvhBuilder::new()
  builder.add_lod(0, groups)
  let built = builder.build(meshlets, groups, cull)
  debug_inspect(built.bvh.length(), content="1")
  debug_inspect(built.bvh_depth, content="1")
  debug_inspect(built.bvh[0].aabbs[0].child_offset, content="0")
  debug_inspect(built.bvh[0].child_counts[0], content="2")
  debug_inspect(built.meshlets.meshlets[0].triangle_offset, content="3")
  debug_inspect(built.meshlets.meshlets[1].triangle_offset, content="0")
  debug_inspect(built.cull_data.length(), content="2")
}

///|
test "pbr meshlet wbtest: connected meshlets count shared remapped vertices" {
  let meshlets = meshlet_wbtest_build_meshlets()
  let connected = meshlet_find_connected_meshlets([0, 1, 2], meshlets, [
    0, 1, 2, 3, 4, 5, 6,
  ])
  debug_inspect(connected[0].length(), content="1")
  debug_inspect(connected[0][0].meshlet_id, content="1")
  debug_inspect(connected[0][0].shared_vertex_count, content="2")
  debug_inspect(connected[1].length(), content="1")
  debug_inspect(connected[1][0].meshlet_id, content="0")
  debug_inspect(connected[2].length(), content="0")
}

///|
test "pbr meshlet wbtest: position remap collapses equal positions" {
  let vertices = [
    MeshletSourceVertex::new(
      position=@math.Vec3::new(1.0F, 0.0F, 0.0F),
      normal=@math.Vec3::new(0.0F, 1.0F, 0.0F),
      uv=@math.Vec2::new(0.0F, 0.0F),
    ),
    MeshletSourceVertex::new(
      position=@math.Vec3::new(2.0F, 0.0F, 0.0F),
      normal=@math.Vec3::new(0.0F, 1.0F, 0.0F),
      uv=@math.Vec2::new(0.0F, 0.0F),
    ),
    MeshletSourceVertex::new(
      position=@math.Vec3::new(1.0F, 0.0F, 0.0F),
      normal=@math.Vec3::new(1.0F, 0.0F, 0.0F),
      uv=@math.Vec2::new(1.0F, 1.0F),
    ),
  ]
  debug_inspect(meshlet_generate_position_remap(vertices), content="[0, 1, 0]")
}

///|
test "pbr meshlet wbtest: triangle partition graph mirrors bevy metis inputs" {
  let graph = meshlet_build_triangle_partition_graph(
    [0, 1, 2, 2, 1, 3, 4, 5, 6],
    [0, 1, 2, 3, 4, 5, 6],
  )
  debug_inspect(graph.xadj, content="[0, 1, 2, 2]")
  debug_inspect(graph.adjncy, content="[1, 0]")
  debug_inspect(graph.adjwgt, content="[2, 2]")
  debug_inspect(graph.partition_count, content="1")
  debug_inspect(graph.seed, content="17")
  debug_inspect(graph.imbalance_factor, content="1")
}

///|
test "pbr meshlet wbtest: from mesh processor boundary calls metis and meshopt" {
  let input = MeshletMeshInputData::new(
    vertices=meshlet_wbtest_source_vertices(7),
    indices=[0, 1, 2, 2, 1, 3, 4, 5, 6],
  )
  let remap = meshlet_generate_position_remap(input.vertices)
  let generated = meshlet_compute_meshlets_with_processor(
    input,
    input.indices,
    remap,
    None,
  ) catch {
    _ => abort("expected native meshlet processor to compute meshlets")
  }
  debug_inspect(generated.meshlets.len() > 0, content="true")
  debug_inspect(generated.cull_data.length() > 0, content="true")
  let meshlet_mesh = meshlet_build_from_mesh_with_processor(input, 4) catch {
    _ => abort("expected native meshlet processor to build meshlet mesh")
  }
  debug_inspect(meshlet_mesh.meshlet_count() > 0, content="true")
  debug_inspect(meshlet_mesh.index_count() > 0, content="true")
}

///|
test "pbr meshlet wbtest: indices are collected by metis partition ids" {
  let indices = meshlet_collect_indices_per_partition(
    [0, 1, 2, 2, 1, 3, 4, 5, 6],
    [1, 0, 1],
    2,
  )
  debug_inspect(indices[0], content="[2, 1, 3]")
  debug_inspect(indices[1], content="[0, 1, 2, 4, 5, 6]")
}

///|
test "pbr meshlet wbtest: group partition graph mirrors bevy metis inputs" {
  let meshlets = meshlet_wbtest_build_meshlets()
  let queue = [0, 1, 2]
  let connected = meshlet_find_connected_meshlets(queue, meshlets, [
    0, 1, 2, 3, 4, 5, 6,
  ])
  let graph = meshlet_build_group_partition_graph(queue, connected)
  debug_inspect(graph.xadj, content="[0, 1, 2, 2]")
  debug_inspect(graph.adjncy, content="[1, 0]")
  debug_inspect(graph.adjwgt, content="[2, 2]")
  debug_inspect(graph.partition_count, content="1")
  debug_inspect(graph.imbalance_factor, content="200")
  debug_inspect(
    (MESHLET_SIMPLIFICATION_FAILURE_PERCENTAGE - 0.6F).abs() < 0.000001F,
    content="true",
  )
}

///|
test "pbr meshlet wbtest: groups are assembled from metis partition ids" {
  let groups = meshlet_groups_from_partitions(
    [0, 1, 2],
    [meshlet_wbtest_cull(0), meshlet_wbtest_cull(1), meshlet_wbtest_cull(2)],
    [1, 0, 1],
    2,
  )
  debug_inspect(groups.length(), content="2")
  debug_inspect(groups[0].meshlets, content="[1]")
  debug_inspect(groups[1].meshlets, content="[0, 2]")
  debug_inspect(groups[0].aabb.center().x, content="2")
  debug_inspect(groups[1].lod_bounds.radius >= 2.5F, content="true")
}

///|
test "pbr meshlet wbtest: simplification group indices mirror meshopt input order" {
  let meshlets = meshlet_wbtest_build_meshlets()
  let group = meshlet_wbtest_group(0, [1, 0])
  debug_inspect(
    meshlet_collect_group_indices(group, meshlets),
    content="[2, 1, 3, 0, 1, 2]",
  )
  debug_inspect(meshlet_simplified_group_accepted(30, 18), content="true")
  debug_inspect(meshlet_simplified_group_accepted(30, 19), content="false")
}

///|
test "pbr meshlet wbtest: lod iteration merges simplified meshlets and retries stuck groups" {
  let meshlets = meshlet_wbtest_build_meshlets()
  let cull_data = [
    meshlet_wbtest_cull(0),
    meshlet_wbtest_cull(1),
    meshlet_wbtest_cull(2),
  ]
  let all_groups : Array[MeshletTempGroup] = []
  let simplification_queue = [0, 1, 2]
  let stuck : Array[MeshletTempGroup] = []
  let bvh = MeshletBvhBuilder::new()
  let new_meshlets = MeshletBuildMeshlets::new(
    meshlets=[
      MeshletBuildMeshlet::new(
        vertex_offset=0,
        triangle_offset=0,
        vertex_count=3,
        triangle_count=4,
      ),
    ],
    vertices=[8, 9, 10],
    triangles=[0, 1, 2, 0, 1, 2, 0, 1, 2, 0, 1, 2],
  )
  let result = meshlet_lod_iteration_apply_results(
    meshlets,
    cull_data,
    all_groups,
    simplification_queue,
    stuck,
    bvh,
    [
      MeshletLodSimplified(meshlet_wbtest_group(0, [0, 1]), new_meshlets, [
        meshlet_wbtest_cull(3),
      ]),
      MeshletLodStuck(meshlet_wbtest_group(2, [2])),
    ],
  )
  debug_inspect(result.first_group, content="0")
  debug_inspect(result.passed_tris, content="4")
  debug_inspect(result.stuck_tris, content="1")
  debug_inspect(result.retried_stuck, content="true")
  debug_inspect(meshlets.len(), content="4")
  debug_inspect(cull_data.length(), content="4")
  debug_inspect(all_groups.length(), content="1")
  debug_inspect(stuck.length(), content="0")
  debug_inspect(simplification_queue, content="[3, 2]")
  debug_inspect(bvh.nodes.length(), content="1")
  debug_inspect(bvh.lods.length(), content="1")
  debug_inspect(meshlets.meshlets[3].vertex_offset, content="9")
  debug_inspect(meshlets.meshlets[3].triangle_offset, content="9")
}

///|
test "pbr meshlet wbtest: lod iteration leaves stuck groups queued for final lod when progress is low" {
  let meshlets = meshlet_wbtest_build_meshlets()
  let cull_data = [
    meshlet_wbtest_cull(0),
    meshlet_wbtest_cull(1),
    meshlet_wbtest_cull(2),
  ]
  let all_groups : Array[MeshletTempGroup] = []
  let simplification_queue = [0, 1, 2]
  let stuck : Array[MeshletTempGroup] = []
  let bvh = MeshletBvhBuilder::new()
  let result = meshlet_lod_iteration_apply_results(
    meshlets,
    cull_data,
    all_groups,
    simplification_queue,
    stuck,
    bvh,
    [MeshletLodStuck(meshlet_wbtest_group(0, [0, 1, 2]))],
  )
  debug_inspect(result.passed_tris, content="0")
  debug_inspect(result.stuck_tris, content="3")
  debug_inspect(result.retried_stuck, content="false")
  debug_inspect(simplification_queue, content="[]")
  debug_inspect(stuck.length(), content="1")
  debug_inspect(bvh.nodes.length(), content="0")
  debug_inspect(bvh.lods.length(), content="0")
}

///|
test "pbr meshlet wbtest: final lod consumes stuck meshlet groups" {
  let all_groups = [meshlet_wbtest_group(0, [0, 1])]
  let stuck = [meshlet_wbtest_group(1, [2]), meshlet_wbtest_group(2, [3, 4])]
  let bvh = MeshletBvhBuilder::new()
  let appended = meshlet_lod_append_final_stuck_lod(all_groups, stuck, bvh)
  debug_inspect(appended, content="true")
  debug_inspect(stuck.length(), content="0")
  debug_inspect(all_groups.length(), content="3")
  debug_inspect(bvh.nodes.length(), content="2")
  debug_inspect(bvh.lods.length(), content="1")
  debug_inspect(bvh.nodes[0].group, content="1")
  debug_inspect(bvh.nodes[1].group, content="2")
}

///|
test "pbr meshlet wbtest: final lod ignores empty stuck list" {
  let all_groups = [meshlet_wbtest_group(0, [0, 1])]
  let stuck : Array[MeshletTempGroup] = []
  let bvh = MeshletBvhBuilder::new()
  let appended = meshlet_lod_append_final_stuck_lod(all_groups, stuck, bvh)
  debug_inspect(appended, content="false")
  debug_inspect(all_groups.length(), content="1")
  debug_inspect(bvh.nodes.length(), content="0")
  debug_inspect(bvh.lods.length(), content="0")
}

///|
test "pbr meshlet wbtest: lock group borders marks shared position vertices" {
  let meshlets = MeshletBuildMeshlets::new(
    meshlets=[
      MeshletBuildMeshlet::new(
        vertex_offset=0,
        triangle_offset=0,
        vertex_count=3,
        triangle_count=1,
      ),
      MeshletBuildMeshlet::new(
        vertex_offset=3,
        triangle_offset=3,
        vertex_count=3,
        triangle_count=1,
      ),
    ],
    vertices=[0, 1, 2, 3, 4, 5],
    triangles=[0, 1, 2, 0, 1, 2],
  )
  let vertex_locks = [false, false, false, false, false, false]
  meshlet_lock_group_borders(
    vertex_locks,
    [meshlet_wbtest_group(0, [0]), meshlet_wbtest_group(1, [1])],
    meshlets,
    [0, 1, 2, 0, 4, 5],
  )
  debug_inspect(
    vertex_locks,
    content="[true, false, false, true, false, false]",
  )
}

///|
test "pbr meshlet wbtest: bvh builder emits inner nodes for more than eight groups" {
  let meshlets = meshlet_wbtest_build_meshlets_count(10)
  let cull : Array[MeshletTempCullData] = []
  let groups : Array[MeshletTempGroup] = []
  for id in 0..<10 {
    cull.push(meshlet_wbtest_cull(id))
    groups.push(meshlet_wbtest_group(id, [id]))
  }
  let builder = MeshletBvhBuilder::new()
  builder.add_lod(0, groups)
  let built = builder.build(meshlets, groups, cull)
  debug_inspect(built.bvh.length() > 1, content="true")
  debug_inspect(built.bvh_depth >= 2, content="true")
  debug_inspect(built.bvh[0].child_counts[0], content="255")
  debug_inspect(built.meshlets.len(), content="10")
  debug_inspect(built.cull_data.length(), content="10")
  debug_inspect(built.aabb.half_extent_x > 8.0F, content="true")
}

///|
test "pbr meshlet wbtest: finalize compresses bvh-remapped raw meshlets" {
  let raw_meshlets = meshlet_wbtest_build_meshlets()
  let cull = [meshlet_wbtest_cull(0), meshlet_wbtest_cull(1)]
  let groups = [meshlet_wbtest_group(0, [1, 0])]
  let builder = MeshletBvhBuilder::new()
  builder.add_lod(0, groups)
  let built = builder.build(raw_meshlets, groups, cull)
  let input = MeshletMeshInputData::new(
    vertices=meshlet_wbtest_source_vertices(7),
    indices=[0, 1, 2, 2, 1, 3, 4, 5, 6],
  )
  let mesh = meshlet_finalize_bvh_build(input, built)
  debug_inspect(mesh.meshlet_count(), content="2")
  debug_inspect(mesh.index_count(), content="9")
  debug_inspect(mesh.vertex_uv_count(), content="6")
  debug_inspect(mesh.vertex_normal_word_count(), content="6")
  debug_inspect(mesh.meshlets[0].start_index_id, content="3")
  debug_inspect(mesh.meshlets[1].start_index_id, content="0")
  debug_inspect(mesh.meshlets[0].start_vertex_attribute_id, content="0")
  debug_inspect(mesh.meshlets[1].start_vertex_attribute_id, content="3")
  debug_inspect(mesh.meshlet_cull_data.length(), content="2")
  debug_inspect(mesh.bvh_depth, content="1")
}
