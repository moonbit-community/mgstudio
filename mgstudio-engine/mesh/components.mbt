// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_mesh/src/components.rs`.
// Runtime owner split out of `mesh/skinning.mbt`.

///|
pub struct SkinnedMeshInverseBindposes {
  values : Array[SkinningMat4]
}

///|
pub fn SkinnedMeshInverseBindposes::new(
  values : Array[SkinningMat4],
) -> SkinnedMeshInverseBindposes {
  { values, }
}

///|
pub fn SkinnedMeshInverseBindposes::values(
  self : SkinnedMeshInverseBindposes,
) -> Array[SkinningMat4] {
  self.values
}

///|
pub fn SkinnedMeshInverseBindposes::get(
  self : SkinnedMeshInverseBindposes,
  index : Int,
) -> SkinningMat4? {
  if index < 0 || index >= self.values.length() {
    None
  } else {
    Some(self.values[index])
  }
}

///|
pub fn SkinnedMeshInverseBindposes::len(
  self : SkinnedMeshInverseBindposes,
) -> Int {
  self.values.length()
}

///|
pub struct SkinnedMesh {
  inverse_bindposes : @asset.Handle[SkinnedMeshInverseBindposes]
  joints : Array[@core.Entity]
}

///|
pub fn SkinnedMesh::new(
  inverse_bindposes : @asset.Handle[SkinnedMeshInverseBindposes],
  joints : Array[@core.Entity],
) -> SkinnedMesh {
  { inverse_bindposes, joints }
}

///|
pub fn SkinnedMesh::joints(self : SkinnedMesh) -> Array[@core.Entity] {
  self.joints
}

///|
pub fn SkinnedMesh::inverse_bindposes(
  self : SkinnedMesh,
) -> @asset.Handle[SkinnedMeshInverseBindposes] {
  self.inverse_bindposes
}

///|
pub struct MorphTargetMesh {
  source_mesh : @asset.Handle[Mesh]
}

///|
pub fn MorphTargetMesh::new(
  source_mesh : @asset.Handle[Mesh],
) -> MorphTargetMesh {
  { source_mesh, }
}

///|
pub fn MorphTargetMesh::source_mesh(
  self : MorphTargetMesh,
) -> @asset.Handle[Mesh] {
  self.source_mesh
}

///|
pub struct MorphWeights {
  values : Array[Float]
}

///|
pub fn MorphWeights::new(values : Array[Float]) -> MorphWeights {
  { values, }
}

///|
pub fn MorphWeights::values(self : MorphWeights) -> Array[Float] {
  self.values
}

///|
pub struct DynamicSkinnedMeshBounds {}

///|
pub fn DynamicSkinnedMeshBounds::new() -> DynamicSkinnedMeshBounds {
  DynamicSkinnedMeshBounds::{  }
}

///|
pub let ecs_key_skinned_mesh : @ecs.ComponentKey[SkinnedMesh] = @ecs.register_component(
  debug_name="mgstudio_render::mesh::skinning::SkinnedMesh",
)

///|
pub let ecs_key_morph_target_mesh : @ecs.ComponentKey[MorphTargetMesh] = @ecs.register_component(
  debug_name="mgstudio_render::mesh::morph::MorphTargetMesh",
)

///|
pub let ecs_key_morph_weights : @ecs.ComponentKey[MorphWeights] = @ecs.register_component(
  debug_name="mgstudio_render::mesh::morph::MorphWeights",
)

///|
pub let ecs_key_dynamic_skinned_mesh_bounds : @ecs.ComponentKey[
  DynamicSkinnedMeshBounds,
] = @ecs.register_component(
  debug_name="mgstudio_render::mesh::skinning::DynamicSkinnedMeshBounds",
)

///|
pub impl @ecs.Component for SkinnedMesh with component() {
  ecs_key_skinned_mesh
}

///|
pub impl @ecs.Component for MorphTargetMesh with component() {
  ecs_key_morph_target_mesh
}

///|
pub impl @ecs.Component for MorphWeights with component() {
  ecs_key_morph_weights
}

///|
pub impl @ecs.Component for DynamicSkinnedMeshBounds with component() {
  ecs_key_dynamic_skinned_mesh_bounds
}
