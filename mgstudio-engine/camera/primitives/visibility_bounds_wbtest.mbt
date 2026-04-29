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
fn visibility_bounds_test_mesh() -> @mesh.Mesh {
  @mesh.Mesh::from_3d_geometry(
    @mesh.Mesh3dGeometry::new(
      [@math.Vec3::new(-1.0F, -2.0F, 0.0F), @math.Vec3::new(3.0F, 2.0F, 0.0F)],
      [@math.Vec2::zero(), @math.Vec2::zero()],
      None,
    ),
  )
}

///|
fn visibility_bounds_test_skinned_mesh() -> @mesh.Mesh {
  let mesh = @mesh.Mesh::from_3d_geometry(
    @mesh.Mesh3dGeometry::new([@math.Vec3::zero()], [@math.Vec2::zero()], None).with_joint_data(
      Some([@mesh.MeshJointIndices::new(0, 0, 0, 0)]),
      Some([@math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F)]),
    ),
  )
  match mesh.generate_skinned_mesh_bounds() {
    Ok(_) => mesh
    Err(_) => abort("expected generated skinned mesh bounds")
  }
}

///|
test "camera/primitives: calculate_bounds inserts Mesh3d Aabb" {
  let world = @ecs.World::new()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let meshes : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
  let mesh_handle = meshes.add(visibility_bounds_test_mesh())
  world.insert_resource(mesh_assets_key, meshes)
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(mesh_handle),
  )

  calculate_bounds_system(world)

  let aabb = (try! world.get_by_key(entity, ecs_key_aabb)).unwrap()
  debug_inspect(aabb.center().x.to_double(), content="1")
  debug_inspect(aabb.center().y.to_double(), content="0")
  debug_inspect(aabb.half_size().x.to_double(), content="2")
  debug_inspect(aabb.half_size().y.to_double(), content="2")
}

///|
test "camera/primitives: update_skinned_mesh_bounds follows joint transforms" {
  let world = @ecs.World::new()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let inverse_bindposes_assets_key : @ecs.ResourceKey[
    @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
  ] = @asset.assets_resource_key()
  let meshes : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
  let inverse_bindposes_assets : @asset.Assets[
    @mesh.SkinnedMeshInverseBindposes,
  ] = @asset.Assets::new()
  let mesh_handle = meshes.add(visibility_bounds_test_skinned_mesh())
  let inverse_bindposes_handle = inverse_bindposes_assets.add(
    @mesh.SkinnedMeshInverseBindposes::new([@mesh.SkinningMat4::identity()]),
  )
  world.insert_resource(mesh_assets_key, meshes)
  world.insert_resource(inverse_bindposes_assets_key, inverse_bindposes_assets)

  let joint = world.spawn()
  try! world.set_by_key(
    joint,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(5.0F, 0.0F, 0.0F),
    ),
  )
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(mesh_handle),
  )
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_skinned_mesh,
    @mesh.SkinnedMesh::new(inverse_bindposes_handle, [joint]),
  )
  try! world.set_by_key(
    entity,
    @mesh.ecs_key_dynamic_skinned_mesh_bounds,
    @mesh.DynamicSkinnedMeshBounds::new(),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
  try! world.set_by_key(
    entity,
    ecs_key_aabb,
    Aabb::from_min_max(@math.Vec3::zero(), @math.Vec3::zero()),
  )

  update_skinned_mesh_bounds_system(world)

  let aabb = (try! world.get_by_key(entity, ecs_key_aabb)).unwrap()
  debug_inspect(aabb.center().x.to_double(), content="5")
  debug_inspect(aabb.center().y.to_double(), content="0")
}
