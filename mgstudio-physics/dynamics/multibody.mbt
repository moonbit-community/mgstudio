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
const SPATIAL_DIM : Int = 3

///|
struct RevoluteJointBuilder {
  mut local_anchor1 : @core.Vec2
  mut local_anchor2 : @core.Vec2
}

///|
pub fn RevoluteJointBuilder::new() -> RevoluteJointBuilder {
  { local_anchor1: @core.Vec2::zero(), local_anchor2: @core.Vec2::zero() }
}

///|
pub fn RevoluteJointBuilder::local_anchor1(
  self : RevoluteJointBuilder,
  anchor : @core.Vec2,
) -> RevoluteJointBuilder {
  self.local_anchor1 = anchor
  self
}

///|
pub fn RevoluteJointBuilder::local_anchor2(
  self : RevoluteJointBuilder,
  anchor : @core.Vec2,
) -> RevoluteJointBuilder {
  self.local_anchor2 = anchor
  self
}

///|
pub fn RevoluteJointBuilder::build(
  self : RevoluteJointBuilder,
) -> RevoluteJoint {
  { local_anchor1: self.local_anchor1, local_anchor2: self.local_anchor2 }
}

///|
struct RevoluteJoint {
  local_anchor1 : @core.Vec2
  local_anchor2 : @core.Vec2
}

///|
pub fn RevoluteJoint::angle(
  self : RevoluteJoint,
  rot1 : @core.Rot2,
  rot2 : @core.Rot2,
) -> @core.Real {
  self.local_anchor1 |> ignore
  self.local_anchor2 |> ignore
  let delta = rot2.angle() - rot1.angle()
  let pi_value = @core.pi()
  let two_pi = @core.two_pi()
  let eps = 1.0e-4F
  if delta > pi_value {
    if delta - pi_value < eps {
      pi_value
    } else {
      delta - two_pi
    }
  } else if delta < -pi_value {
    if -pi_value - delta < eps {
      -pi_value
    } else {
      delta + two_pi
    }
  } else {
    delta
  }
}

///|
fn revolute_body_to_parent(
  joint : RevoluteJoint,
  angle : @core.Real,
) -> @core.Isometry2 {
  let t1 = @core.Isometry2::from_translation(joint.local_anchor1)
  let rot = @core.Isometry2::new(
    @core.Vec2::zero(),
    @core.Rot2::from_angle(angle),
  )
  let neg_anchor2 = @core.Vec2::new(
    -joint.local_anchor2.x,
    -joint.local_anchor2.y,
  )
  let t2 = @core.Isometry2::from_translation(neg_anchor2)
  t1.mul(rot).mul(t2)
}

///|
pub struct LinkId {
  value : Int
}

///|
fn LinkId::new(value : Int) -> LinkId {
  LinkId::{ value, }
}

///|
struct MultibodyLink {
  mut internal_id : Int
  mut parent_internal_id : Int
  mut assembly_id : Int
  rigid_body : RigidBodyHandle
  mut joint : RevoluteJoint
  mut joint_angle : @core.Real
  mut local_to_parent : @core.Isometry2
  mut local_to_world : @core.Isometry2
}

///|
pub fn MultibodyLink::local_to_world(self : MultibodyLink) -> @core.Isometry2 {
  self.local_to_world
}

///|
struct Multibody {
  links : Array[MultibodyLink]
  mut ndofs : Int
  mut root_is_dynamic : Bool
  mut root_translation : @core.Vec2
  mut root_angle : @core.Real
}

///|
fn Multibody::new_with_root(handle : RigidBodyHandle) -> Multibody {
  let joint = RevoluteJointBuilder::new().build()
  let link = MultibodyLink::{
    internal_id: 0,
    parent_internal_id: 0,
    assembly_id: 0,
    rigid_body: handle,
    joint,
    joint_angle: 0.0F,
    local_to_parent: @core.Isometry2::identity(),
    local_to_world: @core.Isometry2::identity(),
  }
  let links : Array[MultibodyLink] = [link]
  {
    links,
    ndofs: SPATIAL_DIM,
    root_is_dynamic: true,
    root_translation: @core.Vec2::zero(),
    root_angle: 0.0F,
  }
}

///|
fn Multibody::root_pose(
  self : Multibody,
  displacements : Array[@core.Real]?,
) -> @core.Isometry2 {
  let mut tx = self.root_translation.x
  let mut ty = self.root_translation.y
  let mut angle = self.root_angle
  if self.root_is_dynamic && displacements is Some(disp) {
    if disp.length() > 0 {
      tx = tx + disp[0]
    }
    if disp.length() > 1 {
      ty = ty + disp[1]
    }
    if disp.length() > 2 {
      angle = angle + disp[2]
    }
  }
  @core.Isometry2::new(@core.Vec2::new(tx, ty), @core.Rot2::from_angle(angle))
}

///|
fn Multibody::update_root_from_body(self : Multibody, body : RigidBody) -> Unit {
  let position = body.position()
  self.root_translation = position.translation
  self.root_angle = position.rotation.angle()
}

///|
fn Multibody::rebuild_indices(self : Multibody, root_dofs : Int) -> Unit {
  let mut assembly = root_dofs
  for i in 0..<self.links.length() {
    let link = self.links[i]
    link.internal_id = i
    if i == 0 {
      link.assembly_id = 0
    } else {
      link.assembly_id = assembly
      assembly = assembly + 1
    }
    self.links[i] = link
  }
}

///|
fn Multibody::recompute_ndofs(self : Multibody) -> Unit {
  let count = self.links.length()
  if count <= 0 {
    self.ndofs = 0
  } else {
    self.root_is_dynamic = true
    self.ndofs = SPATIAL_DIM + (count - 1)
    self.rebuild_indices(SPATIAL_DIM)
  }
}

///|
fn Multibody::update_ndofs_with_root(
  self : Multibody,
  bodies : RigidBodySet,
) -> Unit {
  if self.links.length() <= 0 {
    self.ndofs = 0
    return
  }
  let root = self.links[0]
  let is_dynamic = if bodies.get(root.rigid_body) is Some(body) {
    !(body.body_type is RigidBodyType::Fixed)
  } else {
    true
  }
  let root_dofs = if is_dynamic { SPATIAL_DIM } else { 0 }
  self.root_is_dynamic = is_dynamic
  self.ndofs = root_dofs + (self.links.length() - 1)
  self.rebuild_indices(root_dofs)
}

///|
pub fn Multibody::forward_kinematics(
  self : Multibody,
  bodies : RigidBodySet,
  update_positions : Bool,
) -> Unit {
  self.update_ndofs_with_root(bodies)
  if self.links.length() <= 0 {
    update_positions |> ignore
    return
  }
  if update_positions && bodies.get(self.links[0].rigid_body) is Some(body) {
    self.update_root_from_body(body)
  }
  let root_pose = self.root_pose(None)
  let root_link = self.links[0]
  root_link.local_to_parent = root_pose
  root_link.local_to_world = root_link.local_to_parent
  self.links[0] = root_link
  for i in 1..<self.links.length() {
    let link = self.links[i]
    let parent = self.links[link.parent_internal_id]
    let local_to_parent = revolute_body_to_parent(link.joint, link.joint_angle)
    link.local_to_parent = local_to_parent
    link.local_to_world = parent.local_to_world.mul(link.local_to_parent)
    self.links[i] = link
  }
}

///|
pub fn Multibody::ndofs(self : Multibody) -> Int {
  self.ndofs
}

///|
pub fn Multibody::link(self : Multibody, id : LinkId) -> MultibodyLink? {
  let idx = id.value
  if idx < 0 || idx >= self.links.length() {
    return None
  }
  let link = self.links[idx]
  if link.internal_id != idx {
    return None
  }
  Some(link)
}

///|
fn Multibody::branch_ids(self : Multibody, id : LinkId) -> Array[Int] {
  let branch : Array[Int] = []
  let mut current = id.value
  if current < 0 || current >= self.links.length() {
    return branch
  }
  while true {
    branch.push(current)
    if current == 0 {
      break
    }
    current = self.links[current].parent_internal_id
  }
  let reversed : Array[Int] = []
  let len = branch.length()
  for i in 0..<len {
    reversed.push(branch[len - 1 - i])
  }
  reversed
}

///|
fn Multibody::compute_link_pose(
  self : Multibody,
  id : LinkId,
  displacements : Array[@core.Real]?,
  out_jacobian : Jacobian?,
) -> @core.Isometry2 {
  let branch = self.branch_ids(id)
  if branch.length() == 0 {
    return @core.Isometry2::identity()
  }
  let root_pose = self.root_pose(displacements)
  let mut current_pose = root_pose
  let joint_positions : Array[@core.Vec2] = []
  let joint_cols : Array[Int] = []
  for i in 1..<branch.length() {
    let link_id = branch[i]
    let link = self.links[link_id]
    let joint_pos = current_pose.transform_point(link.joint.local_anchor1)
    joint_positions.push(joint_pos)
    joint_cols.push(link.assembly_id)
    let mut angle = link.joint_angle
    if displacements is Some(disp) && link.assembly_id < disp.length() {
      angle = angle + disp[link.assembly_id]
    }
    let local_to_parent = revolute_body_to_parent(link.joint, angle)
    current_pose = current_pose.mul(local_to_parent)
  }
  if out_jacobian is Some(jacobian) {
    jacobian.ensure_cols(self.ndofs)
    let link_pos = current_pose.translation
    let root_pos = root_pose.translation
    if self.root_is_dynamic && self.ndofs >= SPATIAL_DIM {
      jacobian.set_value(0, 0, 1.0F)
      jacobian.set_value(1, 0, 0.0F)
      jacobian.set_value(2, 0, 0.0F)
      jacobian.set_value(0, 1, 0.0F)
      jacobian.set_value(1, 1, 1.0F)
      jacobian.set_value(2, 1, 0.0F)
      let dx = link_pos.x - root_pos.x
      let dy = link_pos.y - root_pos.y
      jacobian.set_value(0, 2, -dy)
      jacobian.set_value(1, 2, dx)
      jacobian.set_value(2, 2, 1.0F)
    }
    for i in 0..<joint_positions.length() {
      let col = joint_cols[i]
      if col >= 0 && col < self.ndofs {
        let joint_pos = joint_positions[i]
        let dx = link_pos.x - joint_pos.x
        let dy = link_pos.y - joint_pos.y
        jacobian.set_value(0, col, -dy)
        jacobian.set_value(1, col, dx)
        jacobian.set_value(2, col, 1.0F)
      }
    }
  }
  current_pose
}

///|
pub fn Multibody::body_jacobian(self : Multibody, id : LinkId) -> Jacobian {
  let jacobian = Jacobian::zeros(self.ndofs)
  self.compute_link_pose(id, None, Some(jacobian)) |> ignore
  jacobian
}

///|
pub fn Multibody::forward_kinematics_single_link(
  self : Multibody,
  bodies : RigidBodySet,
  id : LinkId,
  displacements : Array[@core.Real]?,
  jacobian : Jacobian?,
) -> @core.Isometry2 {
  self.update_ndofs_with_root(bodies)
  self.compute_link_pose(id, displacements, jacobian)
}

///|
pub fn Multibody::apply_displacements(
  self : Multibody,
  displacements : Array[@core.Real],
) -> Unit {
  if self.root_is_dynamic {
    if displacements.length() > 0 {
      let tx = self.root_translation.x + displacements[0]
      self.root_translation = @core.Vec2::new(tx, self.root_translation.y)
    }
    if displacements.length() > 1 {
      let ty = self.root_translation.y + displacements[1]
      self.root_translation = @core.Vec2::new(self.root_translation.x, ty)
    }
    if displacements.length() > 2 {
      self.root_angle = self.root_angle + displacements[2]
    }
  }
  for i in 1..<self.links.length() {
    let link = self.links[i]
    let col = link.assembly_id
    if col >= 0 && col < displacements.length() {
      link.joint_angle = link.joint_angle + displacements[col]
      self.links[i] = link
    }
  }
}

///|
struct MultibodyJointHandle {
  id : Int
}

///|
fn MultibodyJointHandle::new(id : Int) -> MultibodyJointHandle {
  MultibodyJointHandle::{ id, }
}

///|
pub fn MultibodyJointHandle::from_raw_parts(
  id : Int,
  generation : Int,
) -> MultibodyJointHandle {
  generation |> ignore
  MultibodyJointHandle::new(id)
}

///|
pub fn MultibodyJointHandle::into_raw_parts(
  self : MultibodyJointHandle,
) -> (Int, Int) {
  (self.id, 0)
}

///|
pub fn MultibodyJointHandle::invalid() -> MultibodyJointHandle {
  MultibodyJointHandle::new(-1)
}

///|
pub struct MultibodyIndex {
  value : Int
}

///|
fn MultibodyIndex::new(value : Int) -> MultibodyIndex {
  { value, }
}

///|
pub fn MultibodyIndex::invalid() -> MultibodyIndex {
  MultibodyIndex::new(-1)
}

///|
pub struct MultibodyLinkId {
  multibody : MultibodyIndex
  id : Int
}

///|
priv struct LinkInfo {
  mb_index : Int
  link_id : LinkId
}

///|
struct MultibodyJointSet {
  multibodies : Array[Multibody]
  body_links : Array[LinkInfo?]
  to_wake_up : Array[RigidBodyHandle]
  to_join : Array[(RigidBodyHandle, RigidBodyHandle)]
}

///|
fn multibody_root_pose(
  multibody : Multibody,
  root_id : Int,
) -> (@core.Vec2, @core.Real) {
  if root_id < 0 || root_id >= multibody.links.length() {
    return (@core.Vec2::zero(), 0.0F)
  }
  let root_link = multibody.links[root_id]
  let pose = root_link.local_to_world
  (pose.translation, pose.rotation.angle())
}

///|
fn collect_subtree_indices(multibody : Multibody, root_id : Int) -> Array[Int] {
  if root_id < 0 || root_id >= multibody.links.length() {
    return []
  }
  let count = multibody.links.length()
  let children : Array[Array[Int]] = []
  for _ in 0..<count {
    children.push([])
  }
  for i in 0..<count {
    let link = multibody.links[i]
    let parent_id = link.parent_internal_id
    if parent_id >= 0 && parent_id < count && parent_id != i {
      children[parent_id].push(i)
    }
  }
  let visited : Array[Bool] = []
  for _ in 0..<count {
    visited.push(false)
  }
  let stack : Array[Int] = [root_id]
  let result : Array[Int] = []
  while stack.pop() is Some(id) {
    if id < 0 || id >= count {
      continue
    }
    if visited[id] {
      continue
    }
    visited[id] = true
    result.push(id)
    let child_list = children[id]
    for i in 0..<child_list.length() {
      stack.push(child_list[i])
    }
  }
  result
}

///|
fn build_multibody_from_indices(
  multibody : Multibody,
  indices : Array[Int],
  root_id : Int,
) -> Multibody {
  let total = multibody.links.length()
  let mut_order : Array[Int] = [root_id]
  for i in 0..<indices.length() {
    let id = indices[i]
    if id != root_id {
      mut_order.push(id)
    }
  }
  let map : Array[Int] = []
  for _ in 0..<total {
    map.push(-1)
  }
  let new_links : Array[MultibodyLink] = []
  for i in 0..<mut_order.length() {
    let old_id = mut_order[i]
    if old_id < 0 || old_id >= total {
      continue
    }
    let link = multibody.links[old_id]
    let new_id = new_links.length()
    map[old_id] = new_id
    link.internal_id = new_id
    let old_parent = link.parent_internal_id
    if old_id == root_id ||
      old_parent == old_id ||
      old_parent < 0 ||
      old_parent >= total ||
      map[old_parent] < 0 {
      link.parent_internal_id = new_id
    } else {
      link.parent_internal_id = map[old_parent]
    }
    new_links.push(link)
  }
  let (root_translation, root_angle) = multibody_root_pose(multibody, root_id)
  let new_multibody = Multibody::{
    links: new_links,
    ndofs: 0,
    root_is_dynamic: multibody.root_is_dynamic,
    root_translation,
    root_angle,
  }
  new_multibody.recompute_ndofs()
  new_multibody
}

///|
pub fn MultibodyJointSet::new() -> MultibodyJointSet {
  { multibodies: [], body_links: [], to_wake_up: [], to_join: [] }
}

///|
pub fn MultibodyJointSet::take_wake_up(
  self : MultibodyJointSet,
) -> Array[RigidBodyHandle] {
  let result : Array[RigidBodyHandle] = []
  for i in 0..<self.to_wake_up.length() {
    result.push(self.to_wake_up[i])
  }
  self.to_wake_up.clear()
  result
}

///|
pub fn MultibodyJointSet::take_to_join(
  self : MultibodyJointSet,
) -> Array[(RigidBodyHandle, RigidBodyHandle)] {
  let result : Array[(RigidBodyHandle, RigidBodyHandle)] = []
  for i in 0..<self.to_join.length() {
    result.push(self.to_join[i])
  }
  self.to_join.clear()
  result
}

///|
pub fn MultibodyJointSet::iter(
  self : MultibodyJointSet,
) -> Array[(MultibodyJointHandle, MultibodyLinkId, Multibody, MultibodyLink)] {
  let result : Array[
    (MultibodyJointHandle, MultibodyLinkId, Multibody, MultibodyLink),
  ] = []
  for i in 0..<self.body_links.length() {
    if self.body_links[i] is Some(info) {
      if info.link_id.value > 0 &&
        info.mb_index >= 0 &&
        info.mb_index < self.multibodies.length() {
        let multibody = self.multibodies[info.mb_index]
        if info.link_id.value >= 0 &&
          info.link_id.value < multibody.links.length() {
          let link = multibody.links[info.link_id.value]
          let link_id = MultibodyLinkId::{
            multibody: MultibodyIndex::new(info.mb_index),
            id: info.link_id.value,
          }
          result.push((MultibodyJointHandle::new(i), link_id, multibody, link))
        }
      }
    }
  }
  result
}

///|
fn MultibodyJointSet::update_body_links_for_multibody(
  self : MultibodyJointSet,
  mb_index : Int,
  multibody : Multibody,
) -> Unit {
  for i in 0..<multibody.links.length() {
    let link = multibody.links[i]
    if link.rigid_body.id >= 0 {
      self.ensure_body_capacity(link.rigid_body.id)
      self.body_links[link.rigid_body.id] = Some(LinkInfo::{
        mb_index,
        link_id: LinkId::new(link.internal_id),
      })
    }
  }
}

///|
fn MultibodyJointSet::ensure_body_capacity(
  self : MultibodyJointSet,
  id : Int,
) -> Unit {
  while self.body_links.length() <= id {
    self.body_links.push(None)
  }
}

///|
fn MultibodyJointSet::remove_multibody_at(
  self : MultibodyJointSet,
  index : Int,
) -> Unit {
  if index < 0 || index >= self.multibodies.length() {
    return
  }
  let last_index = self.multibodies.length() - 1
  if index != last_index {
    let moved_multibody = self.multibodies[last_index]
    self.multibodies[index] = moved_multibody
    for i in 0..<moved_multibody.links.length() {
      let link = moved_multibody.links[i]
      if link.rigid_body.id >= 0 {
        self.ensure_body_capacity(link.rigid_body.id)
        self.body_links[link.rigid_body.id] = Some(LinkInfo::{
          mb_index: index,
          link_id: LinkId::new(i),
        })
      }
    }
  }
  self.multibodies.pop() |> ignore
}

///|
fn MultibodyJointSet::register_body(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> LinkInfo {
  let mb = Multibody::new_with_root(handle)
  let index = self.multibodies.length()
  self.multibodies.push(mb)
  let info = LinkInfo::{ mb_index: index, link_id: LinkId::new(0) }
  self.ensure_body_capacity(handle.id)
  self.body_links[handle.id] = Some(info)
  info
}

///|
fn MultibodyJointSet::lookup_body(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> LinkInfo {
  self.ensure_body_capacity(handle.id)
  if self.body_links[handle.id] is Some(info) {
    info
  } else {
    self.register_body(handle)
  }
}

///|
pub fn MultibodyJointSet::insert(
  self : MultibodyJointSet,
  parent : RigidBodyHandle,
  child : RigidBodyHandle,
  joint : RevoluteJoint,
  wake_up : Bool,
) -> MultibodyJointHandle? {
  let parent_info = self.lookup_body(parent)
  let child_info = self.lookup_body(child)
  if parent_info.mb_index == child_info.mb_index {
    return None
  }
  if child_info.link_id.value != 0 {
    return None
  }
  let parent_mb = self.multibodies[parent_info.mb_index]
  let child_mb = self.multibodies[child_info.mb_index]
  let offset = parent_mb.links.length()
  for i in 0..<child_mb.links.length() {
    let link = child_mb.links[i]
    if i == 0 {
      link.parent_internal_id = parent_info.link_id.value
      link.joint = joint
    } else {
      link.parent_internal_id = link.parent_internal_id + offset
    }
    link.internal_id = offset + i
    parent_mb.links.push(link)
  }
  parent_mb.recompute_ndofs()
  self.multibodies[parent_info.mb_index] = parent_mb
  for i in 0..<child_mb.links.length() {
    let link = child_mb.links[i]
    self.ensure_body_capacity(link.rigid_body.id)
    self.body_links[link.rigid_body.id] = Some(LinkInfo::{
      mb_index: parent_info.mb_index,
      link_id: LinkId::new(offset + i),
    })
  }
  self.remove_multibody_at(child_info.mb_index)
  if wake_up {
    push_unique_handle(self.to_wake_up, parent)
    push_unique_handle(self.to_wake_up, child)
  }
  push_unique_pair(self.to_join, (parent, child))
  Some(MultibodyJointHandle::new(child.id))
}

///|
pub fn MultibodyJointSet::insert_kinematic(
  self : MultibodyJointSet,
  parent : RigidBodyHandle,
  child : RigidBodyHandle,
  joint : RevoluteJoint,
  wake_up : Bool,
) -> MultibodyJointHandle? {
  self.insert(parent, child, joint, wake_up)
}

///|
pub fn MultibodyJointSet::remove(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
  wake_up : Bool,
) -> Unit {
  if handle.id < 0 || handle.id >= self.body_links.length() {
    return
  }
  if self.body_links[handle.id] is Some(info) {
    if info.mb_index < 0 || info.mb_index >= self.multibodies.length() {
      self.body_links[handle.id] = None
      return
    }
    let link_id = info.link_id.value
    if link_id <= 0 {
      return
    }
    let multibody = self.multibodies[info.mb_index]
    let subtree = collect_subtree_indices(multibody, link_id)
    if subtree.length() == 0 || subtree.length() == multibody.links.length() {
      return
    }
    let remaining : Array[Int] = []
    for i in 0..<multibody.links.length() {
      let mut in_subtree = false
      for j in 0..<subtree.length() {
        if subtree[j] == i {
          in_subtree = true
          break
        }
      }
      if !in_subtree {
        remaining.push(i)
      }
    }
    if wake_up {
      let removed_link = multibody.links[link_id]
      push_unique_handle(self.to_wake_up, removed_link.rigid_body)
      let parent_id = removed_link.parent_internal_id
      if parent_id >= 0 && parent_id < multibody.links.length() {
        let parent_link = multibody.links[parent_id]
        push_unique_handle(self.to_wake_up, parent_link.rigid_body)
      }
    }
    let remaining_mb = build_multibody_from_indices(multibody, remaining, 0)
    let subtree_mb = build_multibody_from_indices(multibody, subtree, link_id)
    if remaining_mb.links.length() <= 1 {
      let link = remaining_mb.links[0]
      if link.rigid_body.id >= 0 {
        self.ensure_body_capacity(link.rigid_body.id)
        self.body_links[link.rigid_body.id] = None
      }
      self.remove_multibody_at(info.mb_index)
    } else {
      self.multibodies[info.mb_index] = remaining_mb
      self.update_body_links_for_multibody(info.mb_index, remaining_mb)
    }
    if subtree_mb.links.length() <= 1 {
      let link = subtree_mb.links[0]
      if link.rigid_body.id >= 0 {
        self.ensure_body_capacity(link.rigid_body.id)
        self.body_links[link.rigid_body.id] = None
      }
    } else {
      let new_index = self.multibodies.length()
      self.multibodies.push(subtree_mb)
      self.update_body_links_for_multibody(new_index, subtree_mb)
    }
  } else {
    self.body_links[handle.id] = None
  }
}

///|
pub fn MultibodyJointSet::remove_multibody_articulations(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
  wake_up : Bool,
) -> Unit {
  if handle.id < 0 || handle.id >= self.body_links.length() {
    return
  }
  if self.body_links[handle.id] is Some(info) {
    if info.mb_index < 0 || info.mb_index >= self.multibodies.length() {
      self.body_links[handle.id] = None
      return
    }
    let removed_multibody = self.multibodies[info.mb_index]
    for i in 0..<removed_multibody.links.length() {
      let link = removed_multibody.links[i]
      if link.rigid_body.id >= 0 {
        self.ensure_body_capacity(link.rigid_body.id)
        self.body_links[link.rigid_body.id] = None
      }
      if wake_up {
        push_unique_handle(self.to_wake_up, link.rigid_body)
      }
    }
    self.remove_multibody_at(info.mb_index)
  } else {
    self.body_links[handle.id] = None
  }
}

///|
pub fn MultibodyJointSet::rigid_body_link(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> MultibodyLinkId? {
  if handle.id < 0 || handle.id >= self.body_links.length() {
    return None
  }
  if self.body_links[handle.id] is Some(info) {
    Some(MultibodyLinkId::{
      multibody: MultibodyIndex::new(info.mb_index),
      id: info.link_id.value,
    })
  } else {
    None
  }
}

///|
pub fn MultibodyJointSet::get_multibody(
  self : MultibodyJointSet,
  index : MultibodyIndex,
) -> Multibody? {
  if index.value < 0 || index.value >= self.multibodies.length() {
    None
  } else {
    Some(self.multibodies[index.value])
  }
}

///|
pub fn MultibodyJointSet::get_multibody_mut(
  self : MultibodyJointSet,
  index : MultibodyIndex,
) -> Multibody? {
  self.get_multibody(index)
}

///|
pub fn MultibodyJointSet::get_multibody_mut_internal(
  self : MultibodyJointSet,
  index : MultibodyIndex,
) -> Multibody? {
  self.get_multibody(index)
}

///|
pub fn MultibodyJointSet::multibodies(
  self : MultibodyJointSet,
) -> Array[Multibody] {
  let result : Array[Multibody] = []
  for i in 0..<self.multibodies.length() {
    result.push(self.multibodies[i])
  }
  result
}

///|
pub fn MultibodyJointSet::get(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
) -> (Multibody, LinkId)? {
  if handle.id < 0 {
    return None
  }
  if handle.id >= self.body_links.length() {
    return None
  }
  if self.body_links[handle.id] is Some(info) {
    if info.mb_index < 0 || info.mb_index >= self.multibodies.length() {
      return None
    }
    Some((self.multibodies[info.mb_index], info.link_id))
  } else {
    None
  }
}

///|
pub fn MultibodyJointSet::get_mut(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
) -> (Multibody, LinkId)? {
  self.get(handle)
}

///|
pub fn MultibodyJointSet::get_mut_internal(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
) -> (Multibody, LinkId)? {
  self.get(handle)
}

///|
pub fn MultibodyJointSet::get_unknown_gen(
  self : MultibodyJointSet,
  id : Int,
) -> (Multibody, LinkId, MultibodyJointHandle)? {
  if id < 0 || id >= self.body_links.length() {
    return None
  }
  if self.body_links[id] is Some(info) {
    if info.mb_index < 0 || info.mb_index >= self.multibodies.length() {
      return None
    }
    Some(
      (
        self.multibodies[info.mb_index],
        info.link_id,
        MultibodyJointHandle::new(id),
      ),
    )
  } else {
    None
  }
}

///|
pub fn MultibodyJointSet::joint_between(
  self : MultibodyJointSet,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> (MultibodyJointHandle, Multibody, MultibodyLink)? {
  if body1.id < 0 || body2.id < 0 {
    return None
  }
  if body1.id >= self.body_links.length() ||
    body2.id >= self.body_links.length() {
    return None
  }
  if self.body_links[body1.id] is Some(info1) &&
    self.body_links[body2.id] is Some(info2) {
    if info1.mb_index != info2.mb_index {
      return None
    }
    if info1.mb_index < 0 || info1.mb_index >= self.multibodies.length() {
      return None
    }
    let multibody = self.multibodies[info1.mb_index]
    if info1.link_id.value < 0 ||
      info1.link_id.value >= multibody.links.length() ||
      info2.link_id.value < 0 ||
      info2.link_id.value >= multibody.links.length() {
      return None
    }
    let link1 = multibody.links[info1.link_id.value]
    let link2 = multibody.links[info2.link_id.value]
    if link1.parent_internal_id == info2.link_id.value {
      Some((MultibodyJointHandle::new(body1.id), multibody, link1))
    } else if link2.parent_internal_id == info1.link_id.value {
      Some((MultibodyJointHandle::new(body2.id), multibody, link2))
    } else {
      None
    }
  } else {
    None
  }
}

///|
pub fn MultibodyJointSet::attached_joints(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Array[(RigidBodyHandle, RigidBodyHandle, MultibodyJointHandle)] {
  if handle.id < 0 || handle.id >= self.body_links.length() {
    return []
  }
  if self.body_links[handle.id] is Some(info) {
    if info.mb_index < 0 || info.mb_index >= self.multibodies.length() {
      return []
    }
    let multibody = self.multibodies[info.mb_index]
    if info.link_id.value < 0 || info.link_id.value >= multibody.links.length() {
      return []
    }
    let result : Array[(RigidBodyHandle, RigidBodyHandle, MultibodyJointHandle)] = []
    let current_link = multibody.links[info.link_id.value]
    if current_link.parent_internal_id != current_link.internal_id {
      let parent_id = current_link.parent_internal_id
      if parent_id >= 0 && parent_id < multibody.links.length() {
        let parent = multibody.links[parent_id].rigid_body
        result.push((parent, handle, MultibodyJointHandle::new(handle.id)))
      }
    }
    for i in 0..<multibody.links.length() {
      let link = multibody.links[i]
      if link.parent_internal_id == info.link_id.value &&
        !RigidBodyHandle::equals(link.rigid_body, handle) {
        result.push(
          (
            handle,
            link.rigid_body,
            MultibodyJointHandle::new(link.rigid_body.id),
          ),
        )
      }
    }
    result
  } else {
    []
  }
}

///|
pub fn MultibodyJointSet::attached_bodies(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Array[RigidBodyHandle] {
  if handle.id < 0 || handle.id >= self.body_links.length() {
    return []
  }
  if self.body_links[handle.id] is Some(info) {
    if info.mb_index < 0 || info.mb_index >= self.multibodies.length() {
      return []
    }
    let multibody = self.multibodies[info.mb_index]
    let result : Array[RigidBodyHandle] = []
    for i in 0..<multibody.links.length() {
      let link = multibody.links[i]
      if !RigidBodyHandle::equals(link.rigid_body, handle) {
        result.push(link.rigid_body)
      }
    }
    result
  } else {
    []
  }
}

///|
pub fn MultibodyJointSet::bodies_attached_with_enabled_joint(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Array[RigidBodyHandle] {
  self.attached_bodies(handle)
}

///|
fn MultibodyJointSet::remove_joints_attached_to_rigid_body(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Unit {
  let attached = self.attached_joints(handle)
  if attached.length() == 0 {
    return
  }
  let to_remove : Array[MultibodyJointHandle] = []
  for i in 0..<attached.length() {
    let joint = attached[i]
    to_remove.push(joint.2)
  }
  for i in 0..<to_remove.length() {
    self.remove(to_remove[i], true)
  }
}
