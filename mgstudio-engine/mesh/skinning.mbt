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
pub struct MeshJointIndices {
  x : Int
  y : Int
  z : Int
  w : Int
}

///|
pub fn MeshJointIndices::new(
  x : Int,
  y : Int,
  z : Int,
  w : Int,
) -> MeshJointIndices {
  { x, y, z, w }
}

///|
pub struct MeshCustomAttributeVec3 {
  name : String
  values : Array[@math.Vec3]
}

///|
pub fn MeshCustomAttributeVec3::new(
  name : String,
  values : Array[@math.Vec3],
) -> MeshCustomAttributeVec3 {
  { name, values }
}

///|
pub fn MeshCustomAttributeVec3::name(self : MeshCustomAttributeVec3) -> String {
  self.name
}

///|
pub fn MeshCustomAttributeVec3::values(
  self : MeshCustomAttributeVec3,
) -> Array[@math.Vec3] {
  self.values
}

///|
pub struct SkinningMat4 {
  m00 : Float
  m01 : Float
  m02 : Float
  m03 : Float
  m10 : Float
  m11 : Float
  m12 : Float
  m13 : Float
  m20 : Float
  m21 : Float
  m22 : Float
  m23 : Float
  m30 : Float
  m31 : Float
  m32 : Float
  m33 : Float
}

///|
pub fn SkinningMat4::identity() -> SkinningMat4 {
  SkinningMat4::{
    m00: 1.0F,
    m01: 0.0F,
    m02: 0.0F,
    m03: 0.0F,
    m10: 0.0F,
    m11: 1.0F,
    m12: 0.0F,
    m13: 0.0F,
    m20: 0.0F,
    m21: 0.0F,
    m22: 1.0F,
    m23: 0.0F,
    m30: 0.0F,
    m31: 0.0F,
    m32: 0.0F,
    m33: 1.0F,
  }
}

///|
pub fn SkinningMat4::from_values(
  m00 : Float,
  m01 : Float,
  m02 : Float,
  m03 : Float,
  m10 : Float,
  m11 : Float,
  m12 : Float,
  m13 : Float,
  m20 : Float,
  m21 : Float,
  m22 : Float,
  m23 : Float,
  m30 : Float,
  m31 : Float,
  m32 : Float,
  m33 : Float,
) -> SkinningMat4 {
  {
    m00,
    m01,
    m02,
    m03,
    m10,
    m11,
    m12,
    m13,
    m20,
    m21,
    m22,
    m23,
    m30,
    m31,
    m32,
    m33,
  }
}

///|
fn skinning_rotate_vec3(
  rotation : @math.Quat,
  value : @math.Vec3,
) -> @math.Vec3 {
  let qx = rotation.x
  let qy = rotation.y
  let qz = rotation.z
  let qw = rotation.w
  let uv = @math.Vec3::new(
    qy * value.z - qz * value.y,
    qz * value.x - qx * value.z,
    qx * value.y - qy * value.x,
  )
  let uuv = @math.Vec3::new(
    qy * uv.z - qz * uv.y,
    qz * uv.x - qx * uv.z,
    qx * uv.y - qy * uv.x,
  )
  @math.Vec3::add(
    @math.Vec3::add(value, @math.Vec3::mul_scalar(uv, 2.0F * qw)),
    @math.Vec3::mul_scalar(uuv, 2.0F),
  )
}

///|
pub fn SkinningMat4::from_transform(
  transform : @transform.Transform,
) -> SkinningMat4 {
  let qx = transform.rotation.x
  let qy = transform.rotation.y
  let qz = transform.rotation.z
  let qw = transform.rotation.w
  let sx = transform.scale.x
  let sy = transform.scale.y
  let sz = transform.scale.z
  let xx = qx * qx
  let yy = qy * qy
  let zz = qz * qz
  let xy = qx * qy
  let xz = qx * qz
  let yz = qy * qz
  let wx = qw * qx
  let wy = qw * qy
  let wz = qw * qz
  SkinningMat4::{
    m00: (1.0F - 2.0F * (yy + zz)) * sx,
    m01: 2.0F * (xy - wz) * sy,
    m02: 2.0F * (xz + wy) * sz,
    m03: transform.translation.x,
    m10: 2.0F * (xy + wz) * sx,
    m11: (1.0F - 2.0F * (xx + zz)) * sy,
    m12: 2.0F * (yz - wx) * sz,
    m13: transform.translation.y,
    m20: 2.0F * (xz - wy) * sx,
    m21: 2.0F * (yz + wx) * sy,
    m22: (1.0F - 2.0F * (xx + yy)) * sz,
    m23: transform.translation.z,
    m30: 0.0F,
    m31: 0.0F,
    m32: 0.0F,
    m33: 1.0F,
  }
}

///|
pub fn SkinningMat4::inverse_transform(
  transform : @transform.Transform,
) -> SkinningMat4 {
  let sx = if transform.scale.x == 0.0F {
    0.0F
  } else {
    1.0F / transform.scale.x
  }
  let sy = if transform.scale.y == 0.0F {
    0.0F
  } else {
    1.0F / transform.scale.y
  }
  let sz = if transform.scale.z == 0.0F {
    0.0F
  } else {
    1.0F / transform.scale.z
  }
  let inverse_rotation = @math.Quat::new(
    -transform.rotation.x,
    -transform.rotation.y,
    -transform.rotation.z,
    transform.rotation.w,
  )
  let translated = skinning_rotate_vec3(
    inverse_rotation,
    @math.Vec3::new(
      -transform.translation.x * sx,
      -transform.translation.y * sy,
      -transform.translation.z * sz,
    ),
  )
  let qx = inverse_rotation.x
  let qy = inverse_rotation.y
  let qz = inverse_rotation.z
  let qw = inverse_rotation.w
  let xx = qx * qx
  let yy = qy * qy
  let zz = qz * qz
  let xy = qx * qy
  let xz = qx * qz
  let yz = qy * qz
  let wx = qw * qx
  let wy = qw * qy
  let wz = qw * qz
  SkinningMat4::{
    m00: (1.0F - 2.0F * (yy + zz)) * sx,
    m01: 2.0F * (xy - wz) * sy,
    m02: 2.0F * (xz + wy) * sz,
    m03: translated.x,
    m10: 2.0F * (xy + wz) * sx,
    m11: (1.0F - 2.0F * (xx + zz)) * sy,
    m12: 2.0F * (yz - wx) * sz,
    m13: translated.y,
    m20: 2.0F * (xz - wy) * sx,
    m21: 2.0F * (yz + wx) * sy,
    m22: (1.0F - 2.0F * (xx + yy)) * sz,
    m23: translated.z,
    m30: 0.0F,
    m31: 0.0F,
    m32: 0.0F,
    m33: 1.0F,
  }
}

///|
pub fn SkinningMat4::mul(
  self : SkinningMat4,
  other : SkinningMat4,
) -> SkinningMat4 {
  SkinningMat4::{
    m00: self.m00 * other.m00 +
    self.m01 * other.m10 +
    self.m02 * other.m20 +
    self.m03 * other.m30,
    m01: self.m00 * other.m01 +
    self.m01 * other.m11 +
    self.m02 * other.m21 +
    self.m03 * other.m31,
    m02: self.m00 * other.m02 +
    self.m01 * other.m12 +
    self.m02 * other.m22 +
    self.m03 * other.m32,
    m03: self.m00 * other.m03 +
    self.m01 * other.m13 +
    self.m02 * other.m23 +
    self.m03 * other.m33,
    m10: self.m10 * other.m00 +
    self.m11 * other.m10 +
    self.m12 * other.m20 +
    self.m13 * other.m30,
    m11: self.m10 * other.m01 +
    self.m11 * other.m11 +
    self.m12 * other.m21 +
    self.m13 * other.m31,
    m12: self.m10 * other.m02 +
    self.m11 * other.m12 +
    self.m12 * other.m22 +
    self.m13 * other.m32,
    m13: self.m10 * other.m03 +
    self.m11 * other.m13 +
    self.m12 * other.m23 +
    self.m13 * other.m33,
    m20: self.m20 * other.m00 +
    self.m21 * other.m10 +
    self.m22 * other.m20 +
    self.m23 * other.m30,
    m21: self.m20 * other.m01 +
    self.m21 * other.m11 +
    self.m22 * other.m21 +
    self.m23 * other.m31,
    m22: self.m20 * other.m02 +
    self.m21 * other.m12 +
    self.m22 * other.m22 +
    self.m23 * other.m32,
    m23: self.m20 * other.m03 +
    self.m21 * other.m13 +
    self.m22 * other.m23 +
    self.m23 * other.m33,
    m30: self.m30 * other.m00 +
    self.m31 * other.m10 +
    self.m32 * other.m20 +
    self.m33 * other.m30,
    m31: self.m30 * other.m01 +
    self.m31 * other.m11 +
    self.m32 * other.m21 +
    self.m33 * other.m31,
    m32: self.m30 * other.m02 +
    self.m31 * other.m12 +
    self.m32 * other.m22 +
    self.m33 * other.m32,
    m33: self.m30 * other.m03 +
    self.m31 * other.m13 +
    self.m32 * other.m23 +
    self.m33 * other.m33,
  }
}

///|
pub fn SkinningMat4::transform_point3(
  self : SkinningMat4,
  point : @math.Vec3,
) -> @math.Vec3 {
  @math.Vec3::new(
    self.m00 * point.x + self.m01 * point.y + self.m02 * point.z + self.m03,
    self.m10 * point.x + self.m11 * point.y + self.m12 * point.z + self.m13,
    self.m20 * point.x + self.m21 * point.y + self.m22 * point.z + self.m23,
  )
}

///|
pub struct SkinnedMesh {
  source_mesh : @asset.Handle[Mesh]
  joints : Array[@core.Entity]
  inverse_bindposes : Array[SkinningMat4]
  mesh_root : @core.Entity?
}

///|
pub fn SkinnedMesh::new(
  source_mesh : @asset.Handle[Mesh],
  joints : Array[@core.Entity],
  inverse_bindposes : Array[SkinningMat4],
  mesh_root? : @core.Entity? = None,
) -> SkinnedMesh {
  { source_mesh, joints, inverse_bindposes, mesh_root }
}

///|
pub fn SkinnedMesh::source_mesh(self : SkinnedMesh) -> @asset.Handle[Mesh] {
  self.source_mesh
}

///|
pub fn SkinnedMesh::joints(self : SkinnedMesh) -> Array[@core.Entity] {
  self.joints
}

///|
pub fn SkinnedMesh::inverse_bindposes(
  self : SkinnedMesh,
) -> Array[SkinningMat4] {
  self.inverse_bindposes
}

///|
pub fn SkinnedMesh::mesh_root(self : SkinnedMesh) -> @core.Entity? {
  self.mesh_root
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
  debug_name="bevy_render::mesh::skinning::SkinnedMesh",
)

///|
pub let ecs_key_morph_target_mesh : @ecs.ComponentKey[MorphTargetMesh] = @ecs.register_component(
  debug_name="bevy_render::mesh::morph::MorphTargetMesh",
)

///|
pub let ecs_key_morph_weights : @ecs.ComponentKey[MorphWeights] = @ecs.register_component(
  debug_name="bevy_render::mesh::morph::MorphWeights",
)

///|
pub let ecs_key_dynamic_skinned_mesh_bounds : @ecs.ComponentKey[
  DynamicSkinnedMeshBounds,
] = @ecs.register_component(
  debug_name="bevy_render::mesh::skinning::DynamicSkinnedMeshBounds",
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
