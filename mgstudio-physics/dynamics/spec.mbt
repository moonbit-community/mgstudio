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
#declaration_only
pub type RigidBodyHandle

///|
#declaration_only
pub fn RigidBodyHandle::equals(
  self : RigidBodyHandle,
  other : RigidBodyHandle,
) -> Bool {
  ...
}

///|
pub(all) enum RigidBodyType {
  Dynamic
  Fixed
  KinematicPositionBased
}

///|
#declaration_only
pub type RigidBody

///|
#declaration_only
pub type RigidBodyBuilder

///|
#declaration_only
pub fn RigidBodyBuilder::dynamic() -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::fixed() -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::kinematic_position_based() -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::translation(
  self : RigidBodyBuilder,
  translation : @core.Vec2,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::additional_mass(
  self : RigidBodyBuilder,
  mass : @core.Real,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::additional_solver_iterations(
  self : RigidBodyBuilder,
  additional_iterations : Int,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::build(self : RigidBodyBuilder) -> RigidBody {
  ...
}

///|
#declaration_only
pub type RigidBodySet

///|
#declaration_only
pub fn RigidBodySet::new() -> RigidBodySet {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::insert(
  self : RigidBodySet,
  body : RigidBody,
) -> RigidBodyHandle {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::get(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::get_mut(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::remove(
  self : RigidBodySet,
  handle : RigidBodyHandle,
  islands : IslandManager,
  colliders : Unit,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
  wake_up : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_body_type(
  self : RigidBody,
  body_type : RigidBodyType,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::additional_solver_iterations(self : RigidBody) -> Int {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_additional_solver_iterations(
  self : RigidBody,
  additional_iterations : Int,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_sleeping(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::translation(self : RigidBody) -> @core.Vec2 {
  ...
}

///|
#declaration_only
pub fn RigidBody::rotation(self : RigidBody) -> @core.Rot2 {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_translation(
  self : RigidBody,
  translation : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_rotation(
  self : RigidBody,
  rotation : @core.Rot2,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_enabled(self : RigidBody, enabled : Bool) -> RigidBody {
  ...
}

///|
#declaration_only
pub type RigidBodyPosition

///|
#declaration_only
pub fn RigidBodyPosition::new(
  position : @core.Isometry2,
  next_position : @core.Isometry2,
) -> RigidBodyPosition {
  ...
}

///|
#declaration_only
pub fn RigidBodyPosition::interpolate_velocity(
  self : RigidBodyPosition,
  inv_dt : @core.Real,
  local_com : @core.Vec2,
) -> RigidBodyVelocity {
  ...
}

///|
#declaration_only
pub type RigidBodyVelocity

///|
#declaration_only
pub fn RigidBodyVelocity::integrate(
  self : RigidBodyVelocity,
  dt : @core.Real,
  curr_pos : @core.Isometry2,
  local_com : @core.Vec2,
) -> @core.Isometry2 {
  ...
}

///|
#declaration_only
pub type IslandManager

///|
#declaration_only
pub type ContactGraph

///|
#declaration_only
pub fn ContactGraph::new() -> ContactGraph {
  ...
}

///|
#declaration_only
pub fn ContactGraph::clear(self : ContactGraph) -> Unit {
  ...
}

///|
#declaration_only
pub fn ContactGraph::add_pair(
  self : ContactGraph,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn IslandManager::new() -> IslandManager {
  ...
}

///|
#declaration_only
pub fn IslandManager::active_bodies(
  self : IslandManager,
) -> Array[RigidBodyHandle] {
  ...
}

///|
#declaration_only
pub fn IslandManager::wake_up(
  self : IslandManager,
  bodies : RigidBodySet,
  handle : RigidBodyHandle,
  strong : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn IslandManager::interaction_started_or_stopped(
  self : IslandManager,
  bodies : RigidBodySet,
  handle1 : RigidBodyHandle?,
  handle2 : RigidBodyHandle?,
  started : Bool,
  wake_up : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn IslandManager::rigid_body_updated(
  self : IslandManager,
  handle : RigidBodyHandle,
  bodies : RigidBodySet,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn IslandManager::update_islands(
  self : IslandManager,
  dt : @core.Real,
  length_unit : @core.Real,
  bodies : RigidBodySet,
  contacts : ContactGraph,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
) -> Unit {
  ...
}

///|
#declaration_only
pub type CCDSolver

///|
#declaration_only
pub fn CCDSolver::new() -> CCDSolver {
  ...
}

///|
#declaration_only
pub type ImpulseJointSet

///|
#declaration_only
pub type ImpulseJoint

///|
#declaration_only
pub type ImpulseJointHandle

///|
#declaration_only
pub fn ImpulseJointHandle::from_raw_parts(
  id : Int,
  generation : Int,
) -> ImpulseJointHandle {
  ...
}

///|
#declaration_only
pub fn ImpulseJointHandle::into_raw_parts(
  self : ImpulseJointHandle,
) -> (Int, Int) {
  ...
}

///|
#declaration_only
pub fn ImpulseJointHandle::invalid() -> ImpulseJointHandle {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::new() -> ImpulseJointSet {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::take_wake_up(
  self : ImpulseJointSet,
) -> Array[RigidBodyHandle] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::take_to_join(
  self : ImpulseJointSet,
) -> Array[(RigidBodyHandle, RigidBodyHandle)] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::insert(
  self : ImpulseJointSet,
  parent : RigidBodyHandle,
  child : RigidBodyHandle,
  joint : RevoluteJoint,
  wake_up : Bool,
) -> ImpulseJointHandle {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::len(self : ImpulseJointSet) -> Int {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::is_empty(self : ImpulseJointSet) -> Bool {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::contains(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::get(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
) -> ImpulseJoint? {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::remove(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
  wake_up : Bool,
) -> ImpulseJoint? {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::remove_joints_attached_to_rigid_body(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Array[ImpulseJointHandle] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::attached_joints(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Array[ImpulseJoint] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::joints_between(
  self : ImpulseJointSet,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> Array[ImpulseJoint] {
  ...
}

///|
#declaration_only
pub type MultibodyJointSet

///|
#declaration_only
pub fn MultibodyJointSet::new() -> MultibodyJointSet {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::take_wake_up(
  self : MultibodyJointSet,
) -> Array[RigidBodyHandle] {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::take_to_join(
  self : MultibodyJointSet,
) -> Array[(RigidBodyHandle, RigidBodyHandle)] {
  ...
}

///|
#declaration_only
pub type RevoluteJointBuilder

///|
#declaration_only
pub fn RevoluteJointBuilder::new() -> RevoluteJointBuilder {
  ...
}

///|
#declaration_only
pub fn RevoluteJointBuilder::local_anchor1(
  self : RevoluteJointBuilder,
  anchor : @core.Vec2,
) -> RevoluteJointBuilder {
  ...
}

///|
#declaration_only
pub fn RevoluteJointBuilder::local_anchor2(
  self : RevoluteJointBuilder,
  anchor : @core.Vec2,
) -> RevoluteJointBuilder {
  ...
}

///|
#declaration_only
pub fn RevoluteJointBuilder::build(
  self : RevoluteJointBuilder,
) -> RevoluteJoint {
  ...
}

///|
#declaration_only
pub type RevoluteJoint

///|
#declaration_only
pub fn RevoluteJoint::angle(
  self : RevoluteJoint,
  rot1 : @core.Rot2,
  rot2 : @core.Rot2,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::can_sleep(
  self : RigidBodyBuilder,
  can_sleep : Bool,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBody::position(self : RigidBody) -> @core.Isometry2 {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_next_kinematic_translation(
  self : RigidBody,
  translation : @core.Vec2,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::serialize(self : RigidBodySet) -> String {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::deserialize(data : String) -> RigidBodySet {
  ...
}

///|
#declaration_only
pub type MultibodyJointHandle

///|
#declaration_only
pub fn MultibodyJointHandle::invalid() -> MultibodyJointHandle {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::insert(
  self : MultibodyJointSet,
  parent : RigidBodyHandle,
  child : RigidBodyHandle,
  joint : RevoluteJoint,
  wake_up : Bool,
) -> MultibodyJointHandle? {
  ...
}

///|
#declaration_only
pub type LinkId

///|
#declaration_only
pub type Multibody

///|
#declaration_only
pub type MultibodyLink

///|
#declaration_only
pub fn MultibodyJointSet::get(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
) -> (Multibody, LinkId)? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::get_mut(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
) -> (Multibody, LinkId)? {
  ...
}

///|
#declaration_only
pub fn Multibody::forward_kinematics(
  self : Multibody,
  bodies : RigidBodySet,
  update_positions : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn Multibody::ndofs(self : Multibody) -> Int {
  ...
}

///|
#declaration_only
pub fn Multibody::link(self : Multibody, id : LinkId) -> MultibodyLink? {
  ...
}

///|
#declaration_only
pub fn MultibodyLink::local_to_world(self : MultibodyLink) -> @core.Isometry2 {
  ...
}

///|
#declaration_only
pub type Jacobian

///|
#declaration_only
pub fn Jacobian::zeros(size : Int) -> Jacobian {
  ...
}

///|
#declaration_only
pub fn Jacobian::equals(self : Jacobian, other : Jacobian) -> Bool {
  ...
}

///|
#declaration_only
pub fn Multibody::body_jacobian(self : Multibody, id : LinkId) -> Jacobian {
  ...
}

///|
#declaration_only
pub fn Multibody::forward_kinematics_single_link(
  self : Multibody,
  bodies : RigidBodySet,
  id : LinkId,
  displacements : Array[@core.Real]?,
  jacobian : Jacobian?,
) -> @core.Isometry2 {
  ...
}

///|
#declaration_only
pub fn Multibody::apply_displacements(
  self : Multibody,
  displacements : Array[@core.Real],
) -> Unit {
  ...
}

///|
#declaration_only
pub type IndexSequence

///|
#declaration_only
pub fn IndexSequence::new() -> IndexSequence {
  ...
}

///|
#declaration_only
pub fn IndexSequence::remove(self : IndexSequence, index : Int) -> Unit {
  ...
}

///|
#declaration_only
pub fn IndexSequence::keep(self : IndexSequence, index : Int) -> Unit {
  ...
}

///|
#declaration_only
pub type RowDVector

///|
#declaration_only
pub type DVector

///|
#declaration_only
pub fn RowDVector::from_fn(
  size : Int,
  init : (Int) -> @core.Real,
) -> RowDVector {
  ...
}

///|
#declaration_only
pub fn RowDVector::from_array(values : Array[@core.Real]) -> RowDVector {
  ...
}

///|
#declaration_only
pub fn DVector::from_fn(size : Int, init : (Int) -> @core.Real) -> DVector {
  ...
}

///|
#declaration_only
pub fn DVector::from_array(values : Array[@core.Real]) -> DVector {
  ...
}

///|
#declaration_only
pub fn RowDVector::equals(self : RowDVector, other : RowDVector) -> Bool {
  ...
}

///|
#declaration_only
pub fn DVector::equals(self : DVector, other : DVector) -> Bool {
  ...
}

///|
#declaration_only
pub fn RowDVector::len(self : RowDVector) -> Int {
  ...
}

///|
#declaration_only
pub fn DVector::len(self : DVector) -> Int {
  ...
}

///|
#declaration_only
pub fn RowDVector::scale(self : RowDVector, value : @core.Real) -> RowDVector {
  ...
}

///|
#declaration_only
pub fn DVector::scale_in_place(self : DVector, value : @core.Real) -> Unit {
  ...
}

///|
#declaration_only
pub fn IndexSequence::rearrange_columns(
  self : IndexSequence,
  vec : RowDVector,
  keep_columns : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn IndexSequence::rearrange_rows(
  self : IndexSequence,
  vec : DVector,
  keep_rows : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn IndexSequence::inv_rearrange_rows(
  self : IndexSequence,
  vec : DVector,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn IndexSequence::with_rearranged_rows_mut(
  self : IndexSequence,
  vec : DVector,
  action : (DVector) -> Unit,
) -> Unit {
  ...
}
