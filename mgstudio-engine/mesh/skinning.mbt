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
pub fn MeshJointIndices::get(self : MeshJointIndices, index : Int) -> Int? {
  match index {
    0 => Some(self.x)
    1 => Some(self.y)
    2 => Some(self.z)
    3 => Some(self.w)
    _ => None
  }
}

///|
pub fn MeshJointIndices::values(self : MeshJointIndices) -> Array[Int] {
  [self.x, self.y, self.z, self.w]
}

///|
pub struct JointIndex {
  value : Int
} derive(Eq, Debug)

///|
pub fn JointIndex::new(value : Int) -> JointIndex {
  JointIndex::{ value, }
}

///|
pub fn JointIndex::value(self : JointIndex) -> Int {
  self.value
}

///|
pub struct Influence {
  vertex_index : Int
  joint_index : JointIndex
  joint_weight : Float
} derive(Eq, Debug)

///|
pub fn Influence::new(
  vertex_index : Int,
  joint_index : JointIndex,
  joint_weight : Float,
) -> Influence {
  Influence::{ vertex_index, joint_index, joint_weight }
}

///|
pub fn Influence::vertex_index(self : Influence) -> Int {
  self.vertex_index
}

///|
pub fn Influence::joint_index(self : Influence) -> JointIndex {
  self.joint_index
}

///|
pub fn Influence::joint_weight(self : Influence) -> Float {
  self.joint_weight
}

///|
pub(all) enum MeshAttributeError {
  MissingAttribute(String)
  UnexpectedFormat(String, String)
} derive(Eq, Debug)

///|
pub struct InfluenceIterator {
  influences : Array[Influence]
  mut cursor : Int
} derive(Debug)

///|
fn mesh_joint_weight_at(weights : @math.Vec4, index : Int) -> Float? {
  match index {
    0 => Some(weights.x)
    1 => Some(weights.y)
    2 => Some(weights.z)
    3 => Some(weights.w)
    _ => None
  }
}

///|
pub fn InfluenceIterator::new(
  mesh : Mesh,
) -> Result[InfluenceIterator, MeshAttributeError] {
  let geometry = match mesh.as_3d_geometry() {
    Some(geometry) => geometry
    None => return Err(MeshAttributeError::MissingAttribute("Vertex_Position"))
  }
  let joint_indices = match geometry.joint_indices {
    Some(joint_indices) => joint_indices
    None =>
      return Err(MeshAttributeError::MissingAttribute("Vertex_JointIndex"))
  }
  let joint_weights = match geometry.joint_weights {
    Some(joint_weights) => joint_weights
    None =>
      return Err(MeshAttributeError::MissingAttribute("Vertex_JointWeight"))
  }
  let vertex_count = if joint_indices.length() < joint_weights.length() {
    joint_indices.length()
  } else {
    joint_weights.length()
  }
  let influences : Array[Influence] = []
  for vertex_index in 0..<vertex_count {
    for influence_index in 0..<4 {
      let joint_weight = mesh_joint_weight_at(
        joint_weights[vertex_index],
        influence_index,
      ).unwrap()
      if joint_weight > 0.0F {
        let joint_index = joint_indices[vertex_index]
          .get(influence_index)
          .unwrap()
        influences.push(
          Influence::new(
            vertex_index,
            JointIndex::new(joint_index),
            joint_weight,
          ),
        )
      }
    }
  }
  Ok(InfluenceIterator::{ influences, cursor: 0 })
}

///|
pub fn InfluenceIterator::next(self : InfluenceIterator) -> Influence? {
  if self.cursor >= self.influences.length() {
    None
  } else {
    let influence = self.influences[self.cursor]
    self.cursor = self.cursor + 1
    Some(influence)
  }
}

///|
pub fn InfluenceIterator::collect(self : InfluenceIterator) -> Array[Influence] {
  self.influences
}

///|
pub struct JointAabb {
  center : @math.Vec3
  half_size : @math.Vec3
} derive(ToJson)

///|
pub fn JointAabb::new(center : @math.Vec3, half_size : @math.Vec3) -> JointAabb {
  JointAabb::{ center, half_size }
}

///|
pub fn JointAabb::center(self : JointAabb) -> @math.Vec3 {
  self.center
}

///|
pub fn JointAabb::half_size(self : JointAabb) -> @math.Vec3 {
  self.half_size
}

///|
pub fn JointAabb::min(self : JointAabb) -> @math.Vec3 {
  self.center.sub(self.half_size)
}

///|
pub fn JointAabb::max(self : JointAabb) -> @math.Vec3 {
  self.center.add(self.half_size)
}

///|
pub fn JointAabb::to_aabb3d(self : JointAabb) -> @math.Aabb3d {
  @math.Aabb3d::from_min_max(self.min(), self.max())
}

///|
pub fn JointAabb::from_aabb3d(aabb : @math.Aabb3d) -> JointAabb {
  JointAabb::new(aabb.center(), aabb.half_size())
}

///|
priv struct AabbAccumulator {
  mut has_value : Bool
  mut min : @math.Vec3
  mut max : @math.Vec3
}

///|
fn AabbAccumulator::new() -> AabbAccumulator {
  AabbAccumulator::{
    has_value: false,
    min: @math.Vec3::zero(),
    max: @math.Vec3::zero(),
  }
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn vec3_min(a : @math.Vec3, b : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(min_float(a.x, b.x), min_float(a.y, b.y), min_float(a.z, b.z))
}

///|
fn vec3_max(a : @math.Vec3, b : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(max_float(a.x, b.x), max_float(a.y, b.y), max_float(a.z, b.z))
}

///|
fn AabbAccumulator::add_point(
  self : AabbAccumulator,
  position : @math.Vec3,
) -> Unit {
  if self.has_value {
    self.min = vec3_min(self.min, position)
    self.max = vec3_max(self.max, position)
  } else {
    self.has_value = true
    self.min = position
    self.max = position
  }
}

///|
fn AabbAccumulator::add_aabb(
  self : AabbAccumulator,
  aabb : @math.Aabb3d,
) -> Unit {
  self.add_point(aabb.min)
  self.add_point(aabb.max)
}

///|
fn AabbAccumulator::finish(self : AabbAccumulator) -> JointAabb? {
  if self.has_value {
    Some(JointAabb::from_aabb3d(@math.Aabb3d::from_min_max(self.min, self.max)))
  } else {
    None
  }
}

///|
pub struct SkinnedMeshBounds {
  aabbs : Array[JointAabb]
  aabb_index_to_joint_index : Array[JointIndex]
}

///|
pub fn SkinnedMeshBounds::default() -> SkinnedMeshBounds {
  SkinnedMeshBounds::{ aabbs: [], aabb_index_to_joint_index: [] }
}

///|
pub fn SkinnedMeshBounds::new(
  aabbs : Array[JointAabb],
  aabb_index_to_joint_index : Array[JointIndex],
) -> SkinnedMeshBounds {
  SkinnedMeshBounds::{ aabbs, aabb_index_to_joint_index }
}

///|
pub fn SkinnedMeshBounds::aabbs(self : SkinnedMeshBounds) -> Array[JointAabb] {
  self.aabbs
}

///|
pub fn SkinnedMeshBounds::aabb_index_to_joint_index(
  self : SkinnedMeshBounds,
) -> Array[JointIndex] {
  self.aabb_index_to_joint_index
}

///|
pub fn SkinnedMeshBounds::iter(
  self : SkinnedMeshBounds,
) -> Array[(JointIndex, JointAabb)] {
  let len = if self.aabbs.length() < self.aabb_index_to_joint_index.length() {
    self.aabbs.length()
  } else {
    self.aabb_index_to_joint_index.length()
  }
  let out : Array[(JointIndex, JointAabb)] = []
  for i in 0..<len {
    out.push((self.aabb_index_to_joint_index[i], self.aabbs[i]))
  }
  out
}

///|
pub(all) enum SkinnedMeshBoundsError {
  NoSkinnedJoints
  MeshAttributeError(MeshAttributeError)
} derive(Eq, Debug)

///|
pub(all) enum EntityAabbFromSkinnedMeshBoundsError {
  OutOfRangeJointIndex(JointIndex)
  MissingJointEntity
  MissingSkinnedMeshBounds
} derive(Eq, Debug)

///|
fn abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn vec3_abs(value : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(abs_float(value.x), abs_float(value.y), abs_float(value.z))
}

///|
fn skinning_mat4_to_affine3(matrix : SkinningMat4) -> @math.Affine3 {
  @math.Affine3::from_mat3_translation(
    @math.Mat3::from_cols(
      @math.Vec3::new(matrix.m00, matrix.m10, matrix.m20),
      @math.Vec3::new(matrix.m01, matrix.m11, matrix.m21),
      @math.Vec3::new(matrix.m02, matrix.m12, matrix.m22),
    ),
    @math.Vec3::new(matrix.m03, matrix.m13, matrix.m23),
  )
}

///|
fn transform_joint_aabb(
  input : JointAabb,
  transform : @math.Affine3,
) -> @math.Aabb3d {
  let mx = transform.matrix3.x_axis
  let my = transform.matrix3.y_axis
  let mz = transform.matrix3.z_axis
  let mt = transform.translation
  let center = input.center()
  let half_size = input.half_size()

  let tc = mx
    .mul_scalar(center.x)
    .add(my.mul_scalar(center.y))
    .add(mz.mul_scalar(center.z))
    .add(mt)
  let ts = vec3_abs(mx)
    .mul_scalar(half_size.x)
    .add(vec3_abs(my).mul_scalar(half_size.y))
    .add(vec3_abs(mz).mul_scalar(half_size.z))
  @math.Aabb3d::from_min_max(tc.sub(ts), tc.add(ts))
}

///|
pub fn entity_aabb_from_skinned_mesh_bounds(
  world : @ecs.World,
  mesh : Mesh,
  skinned_mesh : SkinnedMesh,
  skinned_mesh_inverse_bindposes : SkinnedMeshInverseBindposes,
  world_from_entity : @transform.GlobalTransform?,
) -> Result[@math.Aabb3d, EntityAabbFromSkinnedMeshBoundsError] {
  let skinned_mesh_bounds = match mesh.skinned_mesh_bounds() {
    Some(bounds) => bounds
    None =>
      return Err(EntityAabbFromSkinnedMeshBoundsError::MissingSkinnedMeshBounds)
  }
  let accumulator = AabbAccumulator::new()
  let joints = skinned_mesh.joints()
  for entry in skinned_mesh_bounds.iter() {
    let (joint_index, modelspace_joint_aabb) = entry
    let joint_index_value = joint_index.value()
    let joint_from_model = match
      skinned_mesh_inverse_bindposes.get(joint_index_value) {
      Some(inverse_bindpose) => skinning_mat4_to_affine3(inverse_bindpose)
      None =>
        return Err(
          EntityAabbFromSkinnedMeshBoundsError::OutOfRangeJointIndex(
            joint_index,
          ),
        )
    }
    if joint_index_value < 0 || joint_index_value >= joints.length() {
      return Err(
        EntityAabbFromSkinnedMeshBoundsError::OutOfRangeJointIndex(joint_index),
      )
    }
    let joint_entity = joints[joint_index_value]
    let world_from_joint = match
      (try! world.get_by_key(joint_entity, @transform.ecs_key_global_transform)) {
      Some(global_transform) => global_transform
      None =>
        return Err(EntityAabbFromSkinnedMeshBoundsError::MissingJointEntity)
    }
    let world_from_model = world_from_joint.affine().mul(joint_from_model)
    accumulator.add_aabb(
      transform_joint_aabb(modelspace_joint_aabb, world_from_model),
    )
  }
  let worldspace_entity_aabb = match accumulator.finish() {
    Some(aabb) => aabb.to_aabb3d()
    None => return Err(EntityAabbFromSkinnedMeshBoundsError::MissingJointEntity)
  }
  match world_from_entity {
    Some(global_transform) =>
      Ok(
        transform_joint_aabb(
          JointAabb::from_aabb3d(worldspace_entity_aabb),
          global_transform.affine().inverse(),
        ),
      )
    None => Ok(worldspace_entity_aabb)
  }
}

///|
pub fn SkinnedMeshBounds::from_mesh(
  mesh : Mesh,
) -> Result[SkinnedMeshBounds, SkinnedMeshBoundsError] {
  let geometry = match mesh.as_3d_geometry() {
    Some(geometry) => geometry
    None =>
      return Err(
        SkinnedMeshBoundsError::MeshAttributeError(
          MeshAttributeError::MissingAttribute("Vertex_Position"),
        ),
      )
  }
  let influences = match InfluenceIterator::new(mesh) {
    Ok(iterator) => iterator.collect()
    Err(error) => return Err(SkinnedMeshBoundsError::MeshAttributeError(error))
  }
  if influences.is_empty() {
    return Ok(SkinnedMeshBounds::default())
  }
  let mut max_joint_index = -1
  for influence in influences {
    let joint_index = influence.joint_index().value()
    if joint_index > max_joint_index {
      max_joint_index = joint_index
    }
  }
  let accumulators : Array[AabbAccumulator] = []
  for _ in 0..<(max_joint_index + 1) {
    accumulators.push(AabbAccumulator::new())
  }
  for influence in influences {
    let vertex_index = influence.vertex_index()
    let joint_index = influence.joint_index().value()
    if vertex_index >= 0 &&
      vertex_index < geometry.positions.length() &&
      joint_index >= 0 &&
      joint_index < accumulators.length() {
      accumulators[joint_index].add_point(geometry.positions[vertex_index])
    }
  }
  let aabbs : Array[JointAabb] = []
  let aabb_index_to_joint_index : Array[JointIndex] = []
  for joint_index, accumulator in accumulators {
    match accumulator.finish() {
      Some(aabb) => {
        aabbs.push(aabb)
        aabb_index_to_joint_index.push(JointIndex::new(joint_index))
      }
      None => ()
    }
  }
  if aabbs.is_empty() {
    Err(SkinnedMeshBoundsError::NoSkinnedJoints)
  } else {
    Ok(SkinnedMeshBounds::new(aabbs, aabb_index_to_joint_index))
  }
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
pub fn SkinningMat4::from_global_transform(
  transform : @transform.GlobalTransform,
) -> SkinningMat4 {
  let affine = transform.affine()
  let x_axis = affine.matrix3.x_axis
  let y_axis = affine.matrix3.y_axis
  let z_axis = affine.matrix3.z_axis
  SkinningMat4::{
    m00: x_axis.x,
    m01: y_axis.x,
    m02: z_axis.x,
    m03: affine.translation.x,
    m10: x_axis.y,
    m11: y_axis.y,
    m12: z_axis.y,
    m13: affine.translation.y,
    m20: x_axis.z,
    m21: y_axis.z,
    m22: z_axis.z,
    m23: affine.translation.z,
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
pub fn SkinningMat4::mul_write_row_major_f32(
  self : SkinningMat4,
  other : SkinningMat4,
  out : Array[Float],
  base_index : Int,
) -> Unit {
  out[base_index] = self.m00 * other.m00 +
    self.m01 * other.m10 +
    self.m02 * other.m20 +
    self.m03 * other.m30
  out[base_index + 1] = self.m00 * other.m01 +
    self.m01 * other.m11 +
    self.m02 * other.m21 +
    self.m03 * other.m31
  out[base_index + 2] = self.m00 * other.m02 +
    self.m01 * other.m12 +
    self.m02 * other.m22 +
    self.m03 * other.m32
  out[base_index + 3] = self.m00 * other.m03 +
    self.m01 * other.m13 +
    self.m02 * other.m23 +
    self.m03 * other.m33
  out[base_index + 4] = self.m10 * other.m00 +
    self.m11 * other.m10 +
    self.m12 * other.m20 +
    self.m13 * other.m30
  out[base_index + 5] = self.m10 * other.m01 +
    self.m11 * other.m11 +
    self.m12 * other.m21 +
    self.m13 * other.m31
  out[base_index + 6] = self.m10 * other.m02 +
    self.m11 * other.m12 +
    self.m12 * other.m22 +
    self.m13 * other.m32
  out[base_index + 7] = self.m10 * other.m03 +
    self.m11 * other.m13 +
    self.m12 * other.m23 +
    self.m13 * other.m33
  out[base_index + 8] = self.m20 * other.m00 +
    self.m21 * other.m10 +
    self.m22 * other.m20 +
    self.m23 * other.m30
  out[base_index + 9] = self.m20 * other.m01 +
    self.m21 * other.m11 +
    self.m22 * other.m21 +
    self.m23 * other.m31
  out[base_index + 10] = self.m20 * other.m02 +
    self.m21 * other.m12 +
    self.m22 * other.m22 +
    self.m23 * other.m32
  out[base_index + 11] = self.m20 * other.m03 +
    self.m21 * other.m13 +
    self.m22 * other.m23 +
    self.m23 * other.m33
  out[base_index + 12] = self.m30 * other.m00 +
    self.m31 * other.m10 +
    self.m32 * other.m20 +
    self.m33 * other.m30
  out[base_index + 13] = self.m30 * other.m01 +
    self.m31 * other.m11 +
    self.m32 * other.m21 +
    self.m33 * other.m31
  out[base_index + 14] = self.m30 * other.m02 +
    self.m31 * other.m12 +
    self.m32 * other.m22 +
    self.m33 * other.m32
  out[base_index + 15] = self.m30 * other.m03 +
    self.m31 * other.m13 +
    self.m32 * other.m23 +
    self.m33 * other.m33
}

///|
pub fn SkinningMat4::write_affine3_mul_row_major_f32(
  self : SkinningMat4,
  affine : @math.Affine3,
  out : Array[Float],
  base_index : Int,
) -> Unit {
  let x_axis = affine.matrix3.x_axis
  let y_axis = affine.matrix3.y_axis
  let z_axis = affine.matrix3.z_axis
  let translation = affine.translation
  out[base_index] = x_axis.x * self.m00 +
    y_axis.x * self.m10 +
    z_axis.x * self.m20 +
    translation.x * self.m30
  out[base_index + 1] = x_axis.x * self.m01 +
    y_axis.x * self.m11 +
    z_axis.x * self.m21 +
    translation.x * self.m31
  out[base_index + 2] = x_axis.x * self.m02 +
    y_axis.x * self.m12 +
    z_axis.x * self.m22 +
    translation.x * self.m32
  out[base_index + 3] = x_axis.x * self.m03 +
    y_axis.x * self.m13 +
    z_axis.x * self.m23 +
    translation.x * self.m33
  out[base_index + 4] = x_axis.y * self.m00 +
    y_axis.y * self.m10 +
    z_axis.y * self.m20 +
    translation.y * self.m30
  out[base_index + 5] = x_axis.y * self.m01 +
    y_axis.y * self.m11 +
    z_axis.y * self.m21 +
    translation.y * self.m31
  out[base_index + 6] = x_axis.y * self.m02 +
    y_axis.y * self.m12 +
    z_axis.y * self.m22 +
    translation.y * self.m32
  out[base_index + 7] = x_axis.y * self.m03 +
    y_axis.y * self.m13 +
    z_axis.y * self.m23 +
    translation.y * self.m33
  out[base_index + 8] = x_axis.z * self.m00 +
    y_axis.z * self.m10 +
    z_axis.z * self.m20 +
    translation.z * self.m30
  out[base_index + 9] = x_axis.z * self.m01 +
    y_axis.z * self.m11 +
    z_axis.z * self.m21 +
    translation.z * self.m31
  out[base_index + 10] = x_axis.z * self.m02 +
    y_axis.z * self.m12 +
    z_axis.z * self.m22 +
    translation.z * self.m32
  out[base_index + 11] = x_axis.z * self.m03 +
    y_axis.z * self.m13 +
    z_axis.z * self.m23 +
    translation.z * self.m33
  out[base_index + 12] = self.m30
  out[base_index + 13] = self.m31
  out[base_index + 14] = self.m32
  out[base_index + 15] = self.m33
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
pub fn SkinningMat4::to_row_major_f32(self : SkinningMat4) -> Array[Float] {
  [
    self.m00,
    self.m01,
    self.m02,
    self.m03,
    self.m10,
    self.m11,
    self.m12,
    self.m13,
    self.m20,
    self.m21,
    self.m22,
    self.m23,
    self.m30,
    self.m31,
    self.m32,
    self.m33,
  ]
}

///|
pub fn SkinningMat4::append_row_major_f32(
  self : SkinningMat4,
  out : Array[Float],
) -> Unit {
  out.push(self.m00)
  out.push(self.m01)
  out.push(self.m02)
  out.push(self.m03)
  out.push(self.m10)
  out.push(self.m11)
  out.push(self.m12)
  out.push(self.m13)
  out.push(self.m20)
  out.push(self.m21)
  out.push(self.m22)
  out.push(self.m23)
  out.push(self.m30)
  out.push(self.m31)
  out.push(self.m32)
  out.push(self.m33)
}

///|
pub fn SkinningMat4::write_row_major_f32(
  self : SkinningMat4,
  out : Array[Float],
  base_index : Int,
) -> Unit {
  out[base_index] = self.m00
  out[base_index + 1] = self.m01
  out[base_index + 2] = self.m02
  out[base_index + 3] = self.m03
  out[base_index + 4] = self.m10
  out[base_index + 5] = self.m11
  out[base_index + 6] = self.m12
  out[base_index + 7] = self.m13
  out[base_index + 8] = self.m20
  out[base_index + 9] = self.m21
  out[base_index + 10] = self.m22
  out[base_index + 11] = self.m23
  out[base_index + 12] = self.m30
  out[base_index + 13] = self.m31
  out[base_index + 14] = self.m32
  out[base_index + 15] = self.m33
}
