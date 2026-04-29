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
fn test_skinning_mesh_with_influences() -> Mesh {
  let positions = [
    @math.Vec3::new(0.0F, 0.0F, 0.0F),
    @math.Vec3::new(2.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 4.0F, 0.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  Mesh3dGeometry::new(positions, uvs, None)
  .with_joint_data(
    Some([
      MeshJointIndices::new(1, 0, 0, 0),
      MeshJointIndices::new(0, 2, 0, 0),
      MeshJointIndices::new(3, 4, 0, 0),
    ]),
    Some([
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.5F, 0.0F, 0.0F),
      @math.Vec4::new(0.25F, 0.75F, 0.0F, 0.0F),
    ]),
  )
  .to_mesh()
}

///|
test "mesh/skinning: influence iterator mirrors Bevy non-zero weights" {
  let empty = Mesh3dGeometry::new([], [], None).to_mesh()
  guard InfluenceIterator::new(empty)
    is Err(MeshAttributeError::MissingAttribute("Vertex_JointIndex")) else {
    fail("expected missing joint index attribute")
  }
  let influences = match
    InfluenceIterator::new(test_skinning_mesh_with_influences()) {
    Ok(iterator) => iterator.collect()
    Err(_) => fail("unexpected influence iterator error")
  }
  debug_inspect(influences.length(), content="4")
  debug_inspect(influences[0].vertex_index(), content="0")
  debug_inspect(influences[0].joint_index().value(), content="1")
  debug_inspect(influences[1].vertex_index(), content="1")
  debug_inspect(influences[1].joint_index().value(), content="2")
  debug_inspect(influences[2].vertex_index(), content="2")
  debug_inspect(influences[2].joint_index().value(), content="3")
  debug_inspect(influences[3].vertex_index(), content="2")
  debug_inspect(influences[3].joint_index().value(), content="4")
}

///|
test "mesh/skinning: skinned mesh bounds group vertices by joint" {
  let bounds = match
    SkinnedMeshBounds::from_mesh(test_skinning_mesh_with_influences()) {
    Ok(bounds) => bounds
    Err(_) => fail("unexpected skinned mesh bounds error")
  }
  let entries = bounds.iter()
  debug_inspect(entries.length(), content="4")
  debug_inspect(entries[0].0.value(), content="1")
  debug_inspect(entries[0].1.center().x.to_double(), content="0")
  debug_inspect(entries[0].1.center().y.to_double(), content="0")
  debug_inspect(entries[1].0.value(), content="2")
  debug_inspect(entries[1].1.center().x.to_double(), content="2")
  debug_inspect(entries[1].1.center().y.to_double(), content="0")
  debug_inspect(entries[2].0.value(), content="3")
  debug_inspect(entries[2].1.center().x.to_double(), content="0")
  debug_inspect(entries[2].1.center().y.to_double(), content="4")
  debug_inspect(entries[3].0.value(), content="4")
  debug_inspect(entries[3].1.center().x.to_double(), content="0")
  debug_inspect(entries[3].1.center().y.to_double(), content="4")
}

///|
test "mesh/skinning: mesh stores and generates skinned mesh bounds" {
  let mesh = test_skinning_mesh_with_influences()
  debug_inspect(mesh.skinned_mesh_bounds() is None, content="true")
  match mesh.generate_skinned_mesh_bounds() {
    Ok(_) => ()
    Err(_) => fail("generate_skinned_mesh_bounds should succeed")
  }
  let generated = mesh.skinned_mesh_bounds().unwrap()
  debug_inspect(generated.iter().length(), content="4")
  let explicit = SkinnedMeshBounds::new(
    [JointAabb::new(@math.Vec3::zero(), @math.Vec3::zero())],
    [JointIndex::new(7)],
  )
  mesh.set_skinned_mesh_bounds(Some(explicit))
  let stored = mesh.skinned_mesh_bounds().unwrap()
  debug_inspect(stored.iter()[0].0.value(), content="7")
  let generated_mesh = match
    test_skinning_mesh_with_influences().with_generated_skinned_mesh_bounds() {
    Ok(mesh) => mesh
    Err(_) => fail("with_generated_skinned_mesh_bounds should succeed")
  }
  debug_inspect(
    generated_mesh.skinned_mesh_bounds().unwrap().iter().length(),
    content="4",
  )
}
