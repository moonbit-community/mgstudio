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
fn skin_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xffffffffUL
  (hi << 32) | lo
}

///|
fn skin_test_inverse_assets_key() -> @ecs.ResourceKey[
  @asset.Assets[@mesh.SkinnedMeshInverseBindposes],
] {
  @asset.assets_resource_key()
}

///|
fn skin_test_insert_inverse_bindposes_assets(
  world : @ecs.World,
  values : Array[@mesh.SkinningMat4],
) -> @asset.Handle[@mesh.SkinnedMeshInverseBindposes] {
  let assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes] = @asset.Assets::new()
  let handle = assets.add(@mesh.SkinnedMeshInverseBindposes::new(values))
  world.insert_resource(skin_test_inverse_assets_key(), assets)
  handle
}

///|
fn skin_test_inverse_assets_or_abort(
  world : @ecs.World,
) -> @asset.Assets[@mesh.SkinnedMeshInverseBindposes] {
  match (try! world.get_resource(skin_test_inverse_assets_key())) {
    Some(assets) => assets
    None => abort("missing test inverse bindposes assets")
  }
}

///|
fn skin_test_set_global_x(
  world : @ecs.World,
  entity : @core.Entity,
  x : Float,
) -> Unit {
  try! world.set(
    entity,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(x, 0.0F, 0.0F),
    ),
  )
}

///|
fn skin_test_set_local_x(world : @ecs.World, entity : @core.Entity, x : Float) -> Unit {
  try! world.set(
    entity,
    @transform.Transform::from_xyz(x, 0.0F, 0.0F),
  )
}

///|
fn skin_test_set_sequence(
  world : @ecs.World,
  last_run : Int,
  this_run : Int,
) -> Unit {
  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(last_run, this_run))
  world.set_sequence_context(ctx)
}

///|
fn skin_test_set_global_x_sequence_only(
  world : @ecs.World,
  entity : @core.Entity,
  x : Float,
) -> Unit {
  let column = match world.component_column(@transform.ecs_key_global_transform) {
    Some(column) => column
    None => abort("missing GlobalTransform column")
  }
  ignore(
    column.set_sequence_only_hot(
      entity,
      @transform.GlobalTransform::from_transform(
        @transform.Transform::from_xyz(x, 0.0F, 0.0F),
      ),
    ),
  )
}

///|
fn skin_test_add_skin_direct(
  world : @ecs.World,
  skin_uniforms_ref : Ref[SkinUniforms],
  skin_entity : @core.Entity,
  handle : @asset.Handle[@mesh.SkinnedMeshInverseBindposes],
  joints : Array[@core.Entity],
) -> Unit {
  render3d_add_skin(
    world,
    skin_uniforms_ref,
    render3d_world_transform_cache_ref(world),
    skin_entity,
    @mesh.SkinnedMesh::new(handle, joints),
    skin_test_inverse_assets_or_abort(world),
    render3d_transform_columns(world),
  )
}

///|
test "pbr render skin: add_skin falls back to cached local transform when GlobalTransform is absent" {
  let world = @ecs.World::new()
  let handle = skin_test_insert_inverse_bindposes_assets(world, [
    @mesh.SkinningMat4::identity(),
  ])
  let joint = world.spawn()
  skin_test_set_local_x(world, joint, 7.0F)
  let skin_entity = world.spawn()
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)

  skin_test_add_skin_direct(world, skin_uniforms_ref, skin_entity, handle, [
    joint,
  ])

  let rows = skin_uniforms_ref.val.current_staging_buffer
  debug_inspect(rows[3] == 7.0F, content="true")
}

///|
test "pbr render skin: allocator reuses freed allocation units" {
  let allocator = SkinOffsetAllocator::new()
  let first = match allocator.allocate(1) {
    Some(allocation) => allocation
    None => abort("expected first allocation")
  }
  let second = match allocator.allocate(1) {
    Some(allocation) => allocation
    None => abort("expected second allocation")
  }
  allocator.free(first)
  let third = match allocator.allocate(1) {
    Some(allocation) => allocation
    None => abort("expected reused allocation")
  }

  debug_inspect(first.matrix_offset(), content="0")
  debug_inspect(second.matrix_offset(), content="4")
  debug_inspect(third.matrix_offset(), content="0")
}

///|
test "pbr render skin: add_skin writes staging rows and identity fallback" {
  let world = @ecs.World::new()
  let handle = skin_test_insert_inverse_bindposes_assets(world, [
    @mesh.SkinningMat4::identity(),
  ])
  let joint_with_bindpose = world.spawn()
  let joint_missing_bindpose = world.spawn()
  skin_test_set_global_x(world, joint_with_bindpose, 2.0F)
  skin_test_set_global_x(world, joint_missing_bindpose, 3.0F)
  let skin_entity = world.spawn()
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)

  skin_test_add_skin_direct(world, skin_uniforms_ref, skin_entity, handle, [
    joint_with_bindpose, joint_missing_bindpose,
  ])

  let rows = skin_uniforms_ref.val.current_staging_buffer
  debug_inspect(rows[3] == 2.0F, content="true")
  debug_inspect(rows[16] == 1.0F, content="true")
  debug_inspect(rows[19] == 0.0F, content="true")
  debug_inspect(rows[21] == 1.0F, content="true")
  debug_inspect(rows.length(), content="64")
}

///|
test "pbr render skin: missing inverse bindpose asset initializes identity rows" {
  let world = @ecs.World::new()
  let assets : @asset.Assets[@mesh.SkinnedMeshInverseBindposes] = @asset.Assets::new()
  world.insert_resource(skin_test_inverse_assets_key(), assets)
  let missing_handle : @asset.Handle[@mesh.SkinnedMeshInverseBindposes] = @asset.Handle::new(
    999,
  )
  let joint = world.spawn()
  skin_test_set_global_x(world, joint, 5.0F)
  let skin_entity = world.spawn()
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)

  skin_test_add_skin_direct(
    world,
    skin_uniforms_ref,
    skin_entity,
    missing_handle,
    [joint],
  )

  let rows = skin_uniforms_ref.val.current_staging_buffer
  debug_inspect(rows[0] == 1.0F, content="true")
  debug_inspect(rows[3] == 0.0F, content="true")
}

///|
test "pbr render skin: remove and re-add reuses the same offset" {
  let world = @ecs.World::new()
  let handle = skin_test_insert_inverse_bindposes_assets(world, [
    @mesh.SkinningMat4::identity(),
  ])
  let joint = world.spawn()
  skin_test_set_global_x(world, joint, 1.0F)
  let first_skin = world.spawn()
  let second_skin = world.spawn()
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)

  skin_test_add_skin_direct(world, skin_uniforms_ref, first_skin, handle, [
    joint,
  ])
  skin_test_add_skin_direct(world, skin_uniforms_ref, second_skin, handle, [
    joint,
  ])
  let (first_offset, _) = render3d_prepared_skin_binding_keys(
    skin_uniforms_ref, first_skin,
  )
  let (second_offset, _) = render3d_prepared_skin_binding_keys(
    skin_uniforms_ref, second_skin,
  )
  render3d_phase_remove_skin(skin_uniforms_ref, first_skin)
  skin_test_add_skin_direct(world, skin_uniforms_ref, first_skin, handle, [
    joint,
  ])
  let (reused_offset, _) = render3d_prepared_skin_binding_keys(
    skin_uniforms_ref, first_skin,
  )

  debug_inspect(first_offset, content="0")
  debug_inspect(second_offset, content="4")
  debug_inspect(reused_offset, content="0")
}

///|
test "pbr render skin: invisible changed skin frees allocation" {
  let world = @ecs.World::new()
  let handle = skin_test_insert_inverse_bindposes_assets(world, [
    @mesh.SkinningMat4::identity(),
  ])
  let joint = world.spawn()
  skin_test_set_global_x(world, joint, 1.0F)
  let skin_entity = world.spawn()
  try! world.set(skin_entity, @visibility.ViewVisibility::new(true))
  try! world.set(skin_entity, @mesh.SkinnedMesh::new(handle, [joint]))
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)
  let world_transform_cache_ref = render3d_world_transform_cache_ref(world)
  skin_test_set_sequence(world, 0, 1)
  render3d_extract_skin_bindings(
    world, skin_uniforms_ref, world_transform_cache_ref,
  )
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore

  try! world.set(skin_entity, @visibility.ViewVisibility::new(false))
  skin_test_set_sequence(world, 1, 2)
  render3d_extract_skin_bindings(
    world, skin_uniforms_ref, world_transform_cache_ref,
  )

  let (skin_offset, _) = render3d_prepared_skin_binding_keys(
    skin_uniforms_ref, skin_entity,
  )
  debug_inspect(skin_offset, content="-1")
  debug_inspect(
    skin_uniforms_ref.val.current_skins.contains(skin_entity_key(skin_entity)),
    content="false",
  )
}

///|
test "pbr render skin: dirty joint extraction updates only mapped skins" {
  let world = @ecs.World::new()
  let handle = skin_test_insert_inverse_bindposes_assets(world, [
    @mesh.SkinningMat4::identity(),
    @mesh.SkinningMat4::identity(),
  ])
  let skin_a_joint_0 = world.spawn()
  let skin_a_joint_1 = world.spawn()
  let skin_b_joint_0 = world.spawn()
  let skin_b_joint_1 = world.spawn()
  skin_test_set_global_x(world, skin_a_joint_0, 1.0F)
  skin_test_set_global_x(world, skin_a_joint_1, 1.0F)
  skin_test_set_global_x(world, skin_b_joint_0, 2.0F)
  skin_test_set_global_x(world, skin_b_joint_1, 2.0F)
  let skin_a = world.spawn()
  let skin_b = world.spawn()
  try! world.set(skin_a, @visibility.ViewVisibility::new(true))
  try! world.set(skin_b, @visibility.ViewVisibility::new(true))
  try! world.set(
    skin_a,
    @mesh.SkinnedMesh::new(handle, [skin_a_joint_0, skin_a_joint_1]),
  )
  try! world.set(
    skin_b,
    @mesh.SkinnedMesh::new(handle, [skin_b_joint_0, skin_b_joint_1]),
  )
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)
  let world_transform_cache_ref = render3d_world_transform_cache_ref(world)
  skin_test_set_sequence(world, 0, 1)
  render3d_extract_skin_bindings(
    world, skin_uniforms_ref, world_transform_cache_ref,
  )
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore

  skin_test_set_global_x(world, skin_a_joint_0, 4.0F)
  skin_test_set_sequence(world, 1, 2)
  render3d_extract_skin_bindings(
    world, skin_uniforms_ref, world_transform_cache_ref,
  )

  let rows = skin_uniforms_ref.val.current_staging_buffer
  debug_inspect(rows[3] == 4.0F, content="true")
  debug_inspect(rows[67] == 2.0F, content="true")
}

///|
test "pbr render skin: dirty joint extraction uses tick metadata without changed messages" {
  let world = @ecs.World::new()
  let handle = skin_test_insert_inverse_bindposes_assets(world, [
    @mesh.SkinningMat4::identity(),
  ])
  let joint = world.spawn()
  skin_test_set_global_x(world, joint, 1.0F)
  let skin_entity = world.spawn()
  try! world.set(skin_entity, @visibility.ViewVisibility::new(true))
  try! world.set(skin_entity, @mesh.SkinnedMesh::new(handle, [joint]))
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)
  let world_transform_cache_ref = render3d_world_transform_cache_ref(world)
  skin_test_set_sequence(world, 0, 1)
  render3d_extract_skin_bindings(
    world, skin_uniforms_ref, world_transform_cache_ref,
  )
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore

  skin_test_set_global_x_sequence_only(world, joint, 6.0F)
  skin_test_set_sequence(world, 1, 2)
  render3d_extract_skin_bindings(
    world, skin_uniforms_ref, world_transform_cache_ref,
  )

  let changed_messages = world
    .changed_components(
      @transform.ecs_key_global_transform,
      @core.SystemSequence::new(1, 2),
    )
    .read()
  let rows = skin_uniforms_ref.val.current_staging_buffer
  debug_inspect(changed_messages.contains(joint), content="false")
  debug_inspect(rows[3] == 6.0F, content="true")
}

///|
test "pbr render skin: prepare publishes current skins as previous-skin flags" {
  let world = @ecs.World::new()
  let handle = skin_test_insert_inverse_bindposes_assets(world, [
    @mesh.SkinningMat4::identity(),
  ])
  let joint = world.spawn()
  skin_test_set_global_x(world, joint, 1.0F)
  let skin_entity = world.spawn()
  let skin_uniforms_ref = skin_uniforms_ref_or_abort(world)
  let world_transform_cache_ref = render3d_world_transform_cache_ref(world)
  skin_test_add_skin_direct(world, skin_uniforms_ref, skin_entity, handle, [
    joint,
  ])

  render3d_prepare_skin_bindings_upload(
    world, skin_uniforms_ref, world_transform_cache_ref,
  )

  debug_inspect(
    skin_uniforms_ref.val.previous_skins.contains(skin_entity_key(skin_entity)),
    content="true",
  )
}
