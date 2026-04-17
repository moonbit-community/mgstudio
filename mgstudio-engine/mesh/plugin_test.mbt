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
fn inverse_bindposes_assets_mut_or_abort(
  world : @ecs.World,
) -> Ref[@asset.Assets[SkinnedMeshInverseBindposes]] {
  let key : @ecs.ResourceKey[@asset.Assets[SkinnedMeshInverseBindposes]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets_ref) => assets_ref
    None => abort("missing Assets<SkinnedMeshInverseBindposes> resource")
  }
}

///|
fn mesh_assets_mut_or_abort(world : @ecs.World) -> Ref[@asset.Assets[Mesh]] {
  let key : @ecs.ResourceKey[@asset.Assets[Mesh]] = @asset.assets_resource_key()
  match (try! world.get_resource_ref_mut(key)) {
    Some(assets_ref) => assets_ref
    None => abort("missing Assets<Mesh> resource")
  }
}

///|
fn test_mesh2d_asset(width : Float, height : Float) -> Mesh {
  let hw = width * 0.5F
  let hh = height * 0.5F
  Mesh::from_2d_geometry(
    Mesh2dGeometry::new(
      [
        @math.Vec2::new(-hw, -hh),
        @math.Vec2::new(hw, -hh),
        @math.Vec2::new(hw, hh),
        @math.Vec2::new(-hw, hh),
      ],
      [
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(1.0F, 0.0F),
        @math.Vec2::new(1.0F, 1.0F),
        @math.Vec2::new(0.0F, 1.0F),
      ],
      Some([0, 1, 2, 0, 2, 3]),
    ),
  )
}

///|
test "mesh plugin: initializes mesh and skinned-inverse-bindposes asset resources" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(MeshPlugin::default())
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[Mesh]] = @asset.assets_resource_key()
  let inverse_bindposes_assets_key : @ecs.ResourceKey[
    @asset.Assets[SkinnedMeshInverseBindposes],
  ] = @asset.assets_resource_key()
  debug_inspect(app.contains_resource(mesh_assets_key), content="true")
  debug_inspect(
    app.contains_resource(inverse_bindposes_assets_key),
    content="true",
  )
}

///|
test "mesh plugin: modified SkinnedMeshInverseBindposes marks SkinnedMesh changed" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(MeshPlugin::default())
  let world = app.world()

  let inverse_bindposes_handle = inverse_bindposes_assets_mut_or_abort(world).val.add(
    SkinnedMeshInverseBindposes::new([SkinningMat4::identity()]),
  )
  let entity = world.spawn()
  try! world.set(entity, SkinnedMesh::new(inverse_bindposes_handle, []))
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore

  let before = world.read_sequence()
  debug_inspect(
    inverse_bindposes_assets_mut_or_abort(world).val.set(
      inverse_bindposes_handle,
      SkinnedMeshInverseBindposes::new([
        SkinningMat4::identity(),
        SkinningMat4::inverse_transform(
          @transform.Transform::from_xyz(0.0F, 1.0F, 0.0F),
        ),
      ]),
    ),
    content="true",
  )
  app = app.update()

  let after = app.world().read_sequence()
  let changed = app
    .world()
    .changed_components(
      ecs_key_skinned_mesh,
      @core.SystemSequence::new(before, after),
    )
    .read()
  debug_inspect(changed.contains(entity), content="true")
}

///|
test "mesh plugin: non-modified SkinnedMeshInverseBindposes does not mark SkinnedMesh changed" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(MeshPlugin::default())
  let world = app.world()

  let inverse_bindposes_handle = inverse_bindposes_assets_mut_or_abort(world).val.add(
    SkinnedMeshInverseBindposes::new([SkinningMat4::identity()]),
  )
  let entity = world.spawn()
  try! world.set(entity, SkinnedMesh::new(inverse_bindposes_handle, []))
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore

  let before = world.read_sequence()
  app = app.update()
  let after = app.world().read_sequence()
  let changed = app
    .world()
    .changed_components(
      ecs_key_skinned_mesh,
      @core.SystemSequence::new(before, after),
    )
    .read()
  debug_inspect(changed.contains(entity), content="false")
}

///|
test "mesh plugin: modified Mesh marks Mesh2d changed" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(MeshPlugin::default())
  let world = app.world()
  let mesh_handle = mesh_assets_mut_or_abort(world).val.add(
    test_mesh2d_asset(10.0F, 8.0F),
  )
  let entity = world.spawn()
  try! world.set(entity, Mesh2d::new(mesh_handle))
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore

  let before = world.read_sequence()
  debug_inspect(
    mesh_assets_mut_or_abort(world).val.set(
      mesh_handle,
      test_mesh2d_asset(12.0F, 8.0F),
    ),
    content="true",
  )
  app = app.update()

  let after = app.world().read_sequence()
  let changed = app
    .world()
    .changed_components(
      ecs_key_mesh2d,
      @core.SystemSequence::new(before, after),
    )
    .read()
  debug_inspect(changed.contains(entity), content="true")
}

///|
test "mesh plugin: non-modified Mesh does not mark Mesh2d changed" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::default())
    .add_plugins(MeshPlugin::default())
  let world = app.world()
  let mesh_handle = mesh_assets_mut_or_abort(world).val.add(
    test_mesh2d_asset(10.0F, 8.0F),
  )
  let entity = world.spawn()
  try! world.set(entity, Mesh2d::new(mesh_handle))
  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore

  let before = world.read_sequence()
  app = app.update()
  let after = app.world().read_sequence()
  let changed = app
    .world()
    .changed_components(
      ecs_key_mesh2d,
      @core.SystemSequence::new(before, after),
    )
    .read()
  debug_inspect(changed.contains(entity), content="false")
}

///|
test "mesh: base mesh pipeline key primitive topology roundtrip" {
  let triangle = BaseMeshPipelineKey::from_primitive_topology(
    Mesh3dPrimitiveTopology::TriangleList,
  )
  let line_list = BaseMeshPipelineKey::from_primitive_topology(
    Mesh3dPrimitiveTopology::LineList,
  )
  let line_strip = BaseMeshPipelineKey::from_primitive_topology(
    Mesh3dPrimitiveTopology::LineStrip,
  )
  debug_inspect(
    triangle.primitive_topology() == Mesh3dPrimitiveTopology::TriangleList,
    content="true",
  )
  debug_inspect(
    line_list.primitive_topology() == Mesh3dPrimitiveTopology::LineList,
    content="true",
  )
  debug_inspect(
    line_strip.primitive_topology() == Mesh3dPrimitiveTopology::LineStrip,
    content="true",
  )
}

///|
test "mesh: base mesh pipeline key morph targets bit detection" {
  let morph = BaseMeshPipelineKey::morph_targets()
  let line_list = BaseMeshPipelineKey::from_primitive_topology(
    Mesh3dPrimitiveTopology::LineList,
  )
  debug_inspect(morph.contains_morph_targets(), content="true")
  debug_inspect(line_list.contains_morph_targets(), content="false")
}
