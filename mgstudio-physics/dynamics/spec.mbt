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
#declaration_only
pub fn RigidBodyHandle::from_raw_parts(
  id : Int,
  generation : Int,
) -> RigidBodyHandle {
  ...
}

///|
#declaration_only
pub fn RigidBodyHandle::into_raw_parts(self : RigidBodyHandle) -> (Int, Int) {
  ...
}

///|
#declaration_only
pub fn RigidBodyHandle::invalid() -> RigidBodyHandle {
  ...
}

///|
pub(all) enum RigidBodyType {
  Dynamic
  Fixed
  KinematicPositionBased
  KinematicVelocityBased
}

///|
#declaration_only
pub fn RigidBodyType::is_fixed(self : RigidBodyType) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBodyType::is_dynamic(self : RigidBodyType) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBodyType::is_kinematic(self : RigidBodyType) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBodyType::is_dynamic_or_kinematic(self : RigidBodyType) -> Bool {
  ...
}

///|
#declaration_only
pub type RigidBodyDominance

///|
#declaration_only
pub fn RigidBodyDominance::new(group : Int) -> RigidBodyDominance {
  ...
}

///|
#declaration_only
pub fn RigidBodyDominance::default() -> RigidBodyDominance {
  ...
}

///|
#declaration_only
pub fn RigidBodyDominance::effective_group(
  self : RigidBodyDominance,
  body_type : RigidBodyType,
) -> Int {
  ...
}

///|
pub(all) enum CoefficientCombineRule {
  Average
  Min
  Multiply
  Max
  ClampedSum
}

///|
#declaration_only
pub fn CoefficientCombineRule::combine(
  coeff1 : @core.Real,
  coeff2 : @core.Real,
  rule_value1 : CoefficientCombineRule,
  rule_value2 : CoefficientCombineRule,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub type Group

///|
#declaration_only
pub fn Group::new(bits : Int) -> Group {
  ...
}

///|
#declaration_only
pub fn Group::bits(self : Group) -> Int {
  ...
}

///|
#declaration_only
pub fn Group::equals(self : Group, other : Group) -> Bool {
  ...
}

///|
#declaration_only
pub fn Group::none() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::all() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_1() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_2() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_3() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_4() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_5() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_6() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_7() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_8() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_9() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_10() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_11() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_12() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_13() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_14() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_15() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::group_16() -> Group {
  ...
}

///|
#declaration_only
pub fn Group::or(self : Group, other : Group) -> Group {
  ...
}

///|
#declaration_only
pub fn Group::intersection(self : Group, other : Group) -> Group {
  ...
}

///|
pub(all) enum InteractionTestMode {
  And
  Or
}

///|
#declaration_only
pub type InteractionGroups

///|
#declaration_only
pub fn InteractionGroups::new(
  memberships : Group,
  filter : Group,
  test_mode : InteractionTestMode,
) -> InteractionGroups {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::all() -> InteractionGroups {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::none() -> InteractionGroups {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::with_memberships(
  self : InteractionGroups,
  memberships : Group,
) -> InteractionGroups {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::with_filter(
  self : InteractionGroups,
  filter : Group,
) -> InteractionGroups {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::test_and(
  self : InteractionGroups,
  other : InteractionGroups,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::test_or(
  self : InteractionGroups,
  other : InteractionGroups,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::test_groups(
  self : InteractionGroups,
  other : InteractionGroups,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::memberships(self : InteractionGroups) -> Group {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::filter(self : InteractionGroups) -> Group {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::test_mode(
  self : InteractionGroups,
) -> InteractionTestMode {
  ...
}

///|
#declaration_only
pub fn InteractionGroups::default() -> InteractionGroups {
  ...
}

///|
#declaration_only
pub type SpringCoefficients

///|
#declaration_only
pub fn SpringCoefficients::new(
  natural_frequency : @core.Real,
  damping_ratio : @core.Real,
) -> SpringCoefficients {
  ...
}

///|
#declaration_only
pub fn SpringCoefficients::contact_defaults() -> SpringCoefficients {
  ...
}

///|
#declaration_only
pub fn SpringCoefficients::joint_defaults() -> SpringCoefficients {
  ...
}

///|
#declaration_only
pub fn SpringCoefficients::angular_frequency(
  self : SpringCoefficients,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn SpringCoefficients::erp_inv_dt(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn SpringCoefficients::erp(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn SpringCoefficients::cfm_coeff(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn SpringCoefficients::cfm_factor(
  self : SpringCoefficients,
  dt : @core.Real,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub type IntegrationParameters

///|
#declaration_only
pub fn IntegrationParameters::default() -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::new() -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::inv_dt(
  self : IntegrationParameters,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_dt(
  self : IntegrationParameters,
  dt : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_inv_dt(
  self : IntegrationParameters,
  inv_dt : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_min_ccd_dt(
  self : IntegrationParameters,
  min_ccd_dt : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_contact_softness(
  self : IntegrationParameters,
  contact_softness : SpringCoefficients,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_warmstart_coefficient(
  self : IntegrationParameters,
  warmstart_coefficient : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_length_unit(
  self : IntegrationParameters,
  length_unit : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_normalized_allowed_linear_error(
  self : IntegrationParameters,
  normalized_allowed_linear_error : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_normalized_max_corrective_velocity(
  self : IntegrationParameters,
  normalized_max_corrective_velocity : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_normalized_prediction_distance(
  self : IntegrationParameters,
  normalized_prediction_distance : @core.Real,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_num_solver_iterations(
  self : IntegrationParameters,
  num_solver_iterations : Int,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_num_internal_pgs_iterations(
  self : IntegrationParameters,
  num_internal_pgs_iterations : Int,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_num_internal_stabilization_iterations(
  self : IntegrationParameters,
  num_internal_stabilization_iterations : Int,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_min_island_size(
  self : IntegrationParameters,
  min_island_size : Int,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::set_max_ccd_substeps(
  self : IntegrationParameters,
  max_ccd_substeps : Int,
) -> IntegrationParameters {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::allowed_linear_error(
  self : IntegrationParameters,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::max_corrective_velocity(
  self : IntegrationParameters,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn IntegrationParameters::prediction_distance(
  self : IntegrationParameters,
) -> @core.Real {
  ...
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
pub fn RigidBodyBuilder::kinematic_velocity_based() -> RigidBodyBuilder {
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
pub fn RigidBodyBuilder::position(
  self : RigidBodyBuilder,
  position : @core.Isometry2,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::rotation(
  self : RigidBodyBuilder,
  rotation : @core.Rot2,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::linvel(
  self : RigidBodyBuilder,
  linvel : @core.Vec2,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::angvel(
  self : RigidBodyBuilder,
  angvel : @core.Real,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::gravity_scale(
  self : RigidBodyBuilder,
  scale : @core.Real,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::linear_damping(
  self : RigidBodyBuilder,
  damping : @core.Real,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::angular_damping(
  self : RigidBodyBuilder,
  damping : @core.Real,
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
pub fn RigidBodyBuilder::dominance_group(
  self : RigidBodyBuilder,
  group : Int,
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
pub fn RigidBodySet::with_capacity(capacity : Int) -> RigidBodySet {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::len(self : RigidBodySet) -> Int {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::is_empty(self : RigidBodySet) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::contains(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::take_modified(
  self : RigidBodySet,
) -> Array[RigidBodyHandle] {
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
pub fn RigidBodySet::get_mut_internal(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::get_mut_internal_with_modification_tracking(
  self : RigidBodySet,
  handle : RigidBodyHandle,
) -> RigidBody? {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::get_unknown_gen(
  self : RigidBodySet,
  id : Int,
) -> (RigidBody, RigidBodyHandle)? {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::get_unknown_gen_mut(
  self : RigidBodySet,
  id : Int,
) -> (RigidBody, RigidBodyHandle)? {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::get_pair_mut(
  self : RigidBodySet,
  handle1 : RigidBodyHandle,
  handle2 : RigidBodyHandle,
) -> (RigidBody?, RigidBody?) {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::iter(
  self : RigidBodySet,
) -> Array[(RigidBodyHandle, RigidBody)] {
  ...
}

///|
#declaration_only
pub fn RigidBodySet::iter_mut(
  self : RigidBodySet,
) -> Array[(RigidBodyHandle, RigidBody)] {
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
  remove_attached_colliders : Bool,
) -> RigidBody? {
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
pub fn RigidBody::body_type(self : RigidBody) -> RigidBodyType {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_enabled(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_fixed(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_dynamic(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_kinematic(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_dynamic_or_kinematic(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::dominance_group(self : RigidBody) -> Int {
  ...
}

///|
#declaration_only
pub fn RigidBody::effective_dominance_group(self : RigidBody) -> Int {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_dominance_group(
  self : RigidBody,
  group : Int,
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
pub fn RigidBody::additional_mass(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_additional_mass(
  self : RigidBody,
  mass : @core.Real,
  wake_up : Bool,
) -> RigidBody {
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
pub fn RigidBody::activation(self : RigidBody) -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub fn RigidBody::damping(self : RigidBody) -> RigidBodyDamping {
  ...
}

///|
#declaration_only
pub fn RigidBody::linear_damping(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_linear_damping(
  self : RigidBody,
  damping : @core.Real,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::angular_damping(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_angular_damping(
  self : RigidBody,
  damping : @core.Real,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::vels(self : RigidBody) -> RigidBodyVelocity {
  ...
}

///|
#declaration_only
pub fn RigidBody::linvel(self : RigidBody) -> @core.Vec2 {
  ...
}

///|
#declaration_only
pub fn RigidBody::angvel(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_vels(
  self : RigidBody,
  vels : RigidBodyVelocity,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_linvel(
  self : RigidBody,
  linvel : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_angvel(
  self : RigidBody,
  angvel : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::apply_impulse(
  self : RigidBody,
  impulse : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::apply_torque_impulse(
  self : RigidBody,
  torque_impulse : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::apply_impulse_at_point(
  self : RigidBody,
  impulse : @core.Vec2,
  point : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::forces(self : RigidBody) -> RigidBodyForces {
  ...
}

///|
#declaration_only
pub fn RigidBody::gravity_scale(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_gravity_scale(
  self : RigidBody,
  scale : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::reset_forces(self : RigidBody, wake_up : Bool) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::reset_torques(self : RigidBody, wake_up : Bool) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::add_force(
  self : RigidBody,
  force : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::add_torque(
  self : RigidBody,
  torque : @core.Real,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::add_force_at_point(
  self : RigidBody,
  force : @core.Vec2,
  point : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::ccd(self : RigidBody) -> RigidBodyCcd {
  ...
}

///|
#declaration_only
pub fn RigidBody::enable_ccd(self : RigidBody, enabled : Bool) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_ccd_enabled(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_soft_ccd_prediction(
  self : RigidBody,
  prediction_distance : @core.Real,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::soft_ccd_prediction(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::is_ccd_active(self : RigidBody) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBody::mass_props(self : RigidBody) -> RigidBodyMassProps {
  ...
}

///|
#declaration_only
pub fn RigidBody::mass(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::inv_mass(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::inertia(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::inv_inertia(self : RigidBody) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBody::center_of_mass(self : RigidBody) -> @core.Vec2 {
  ...
}

///|
#declaration_only
pub fn RigidBody::world_com(self : RigidBody) -> @core.Vec2 {
  ...
}

///|
#declaration_only
pub fn RigidBody::wake_up(self : RigidBody, strong : Bool) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::sleep(self : RigidBody) -> RigidBody {
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
pub fn RigidBody::set_position(
  self : RigidBody,
  position : @core.Isometry2,
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
pub fn RigidBody::clear_changes(self : RigidBody) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::mark_local_mass_properties_changed(
  self : RigidBody,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub type RigidBodyActivation

///|
#declaration_only
pub fn RigidBodyActivation::default() -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::default_normalized_linear_threshold() -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::default_angular_threshold() -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::default_time_until_sleep() -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::active() -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::inactive() -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::cannot_sleep() -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::is_active(self : RigidBodyActivation) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::wake_up(
  self : RigidBodyActivation,
  strong : Bool,
) -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::sleep(
  self : RigidBodyActivation,
) -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::is_eligible_for_sleep(
  self : RigidBodyActivation,
) -> Bool {
  ...
}

///|
#declaration_only
pub fn RigidBodyActivation::update_energy(
  self : RigidBodyActivation,
  body_type : RigidBodyType,
  length_unit : @core.Real,
  sq_linvel : @core.Real,
  sq_angvel : @core.Real,
  dt : @core.Real,
) -> RigidBodyActivation {
  ...
}

///|
#declaration_only
pub type RigidBodyDamping

///|
#declaration_only
pub fn RigidBodyDamping::default() -> RigidBodyDamping {
  ...
}

///|
#declaration_only
pub type RigidBodyForces

///|
#declaration_only
pub fn RigidBodyForces::default() -> RigidBodyForces {
  ...
}

///|
#declaration_only
pub fn RigidBodyForces::integrate(
  self : RigidBodyForces,
  dt : @core.Real,
  init_vels : RigidBodyVelocity,
  mprops : RigidBodyMassProps,
) -> RigidBodyVelocity {
  ...
}

///|
#declaration_only
pub fn RigidBodyForces::compute_effective_force_and_torque(
  self : RigidBodyForces,
  gravity : @core.Vec2,
  mass : @core.Vec2,
) -> RigidBodyForces {
  ...
}

///|
#declaration_only
pub fn RigidBodyForces::apply_force_at_point(
  self : RigidBodyForces,
  rb_mprops : RigidBodyMassProps,
  force : @core.Vec2,
  point : @core.Vec2,
) -> RigidBodyForces {
  ...
}

///|
#declaration_only
pub type RigidBodyCcd

///|
#declaration_only
pub fn RigidBodyCcd::default() -> RigidBodyCcd {
  ...
}

///|
#declaration_only
pub fn RigidBodyCcd::max_point_velocity(
  self : RigidBodyCcd,
  vels : RigidBodyVelocity,
) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn RigidBodyCcd::is_moving_fast(
  self : RigidBodyCcd,
  dt : @core.Real,
  vels : RigidBodyVelocity,
  forces : RigidBodyForces?,
) -> Bool {
  ...
}

///|
#declaration_only
pub type RigidBodyMassProps

///|
#declaration_only
pub fn RigidBodyMassProps::default() -> RigidBodyMassProps {
  ...
}

///|
#declaration_only
pub fn RigidBodyMassProps::set_effective_inv_mass(
  self : RigidBodyMassProps,
  inv_mass : @core.Vec2,
) -> RigidBodyMassProps {
  ...
}

///|
#declaration_only
pub fn RigidBodyMassProps::set_effective_world_inv_inertia(
  self : RigidBodyMassProps,
  inv_inertia : @core.Real,
) -> RigidBodyMassProps {
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
pub fn RigidBodyPosition::integrate_forces_and_velocities(
  self : RigidBodyPosition,
  dt : @core.Real,
  forces : RigidBodyForces,
  vels : RigidBodyVelocity,
  mprops : RigidBodyMassProps,
) -> @core.Isometry2 {
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
pub fn RigidBodyVelocity::zero() -> RigidBodyVelocity {
  ...
}

///|
#declaration_only
pub fn RigidBodyVelocity::apply_damping(
  self : RigidBodyVelocity,
  dt : @core.Real,
  damping : RigidBodyDamping,
) -> RigidBodyVelocity {
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
pub fn IslandManager::rigid_body_removed_or_disabled(
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
pub(all) enum PredictedImpacts {
  Impacts(Array[(RigidBodyHandle, @core.Real)])
  ImpactsAfterEndTime(@core.Real)
  NoImpacts
}

///|
#declaration_only
pub fn CCDSolver::clamp_motions(
  self : CCDSolver,
  dt : @core.Real,
  bodies : RigidBodySet,
  impacts : PredictedImpacts,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn CCDSolver::update_ccd_active_flags(
  self : CCDSolver,
  islands : IslandManager,
  bodies : RigidBodySet,
  dt : @core.Real,
  include_forces : Bool,
) -> Bool {
  ...
}

///|
pub(all) enum JointEnabled {
  Enabled
  DisabledByAttachedBody
  Disabled
}

///|
#declaration_only
pub type GenericJoint

///|
#declaration_only
pub fn GenericJoint::from_revolute(joint : RevoluteJoint) -> GenericJoint {
  ...
}

///|
#declaration_only
pub fn GenericJoint::is_enabled(self : GenericJoint) -> Bool {
  ...
}

///|
#declaration_only
pub fn GenericJoint::set_enabled(
  self : GenericJoint,
  enabled : Bool,
) -> GenericJoint {
  ...
}

///|
#declaration_only
pub fn GenericJoint::set_enabled_by_attached_body(
  self : GenericJoint,
  attached_enabled : Bool,
) -> GenericJoint {
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
pub type ImpulseJointGraph

///|
#declaration_only
pub type ImpulseJointHandle

///|
#declaration_only
pub fn ImpulseJoint::is_enabled(self : ImpulseJoint) -> Bool {
  ...
}

///|
#declaration_only
pub fn ImpulseJoint::set_enabled(
  self : ImpulseJoint,
  enabled : Bool,
) -> ImpulseJoint {
  ...
}

///|
#declaration_only
pub fn ImpulseJoint::set_enabled_by_attached_body(
  self : ImpulseJoint,
  attached_enabled : Bool,
) -> ImpulseJoint {
  ...
}

///|
#declaration_only
pub fn ImpulseJointGraph::nodes(
  self : ImpulseJointGraph,
) -> Array[RigidBodyHandle] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointGraph::edges(
  self : ImpulseJointGraph,
) -> Array[(RigidBodyHandle, RigidBodyHandle, ImpulseJoint)] {
  ...
}

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
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
  joint : GenericJoint,
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
pub fn ImpulseJointSet::joint_graph(
  self : ImpulseJointSet,
) -> ImpulseJointGraph {
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
pub fn ImpulseJointSet::get_mut(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
  wake_up : Bool,
) -> ImpulseJoint? {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::get_unknown_gen(
  self : ImpulseJointSet,
  id : Int,
) -> (ImpulseJoint, ImpulseJointHandle)? {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::get_unknown_gen_mut(
  self : ImpulseJointSet,
  id : Int,
) -> (ImpulseJoint, ImpulseJointHandle)? {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::iter(
  self : ImpulseJointSet,
) -> Array[(ImpulseJointHandle, ImpulseJoint)] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::iter_mut(
  self : ImpulseJointSet,
) -> Array[(ImpulseJointHandle, ImpulseJoint)] {
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
pub fn ImpulseJointSet::map_attached_joints_mut(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
  f : (RigidBodyHandle, RigidBodyHandle, ImpulseJointHandle, ImpulseJoint) -> Unit,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::attached_joints(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Array[(RigidBodyHandle, RigidBodyHandle, ImpulseJointHandle, ImpulseJoint)] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::attached_enabled_joints(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Array[(RigidBodyHandle, RigidBodyHandle, ImpulseJointHandle, ImpulseJoint)] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::joints_between(
  self : ImpulseJointSet,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> Array[(ImpulseJointHandle, ImpulseJoint)] {
  ...
}

///|
#declaration_only
pub fn ImpulseJointSet::select_active_interactions(
  self : ImpulseJointSet,
  islands : IslandManager,
  bodies : RigidBodySet,
  out : Array[Array[Int]],
) -> Unit {
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
pub fn MultibodyJointSet::iter(
  self : MultibodyJointSet,
) -> Array[(MultibodyJointHandle, MultibodyLinkId, Multibody, MultibodyLink)] {
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
pub fn RigidBodyBuilder::sleeping(
  self : RigidBodyBuilder,
  sleeping : Bool,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::enabled(
  self : RigidBodyBuilder,
  enabled : Bool,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::ccd_enabled(
  self : RigidBodyBuilder,
  enabled : Bool,
) -> RigidBodyBuilder {
  ...
}

///|
#declaration_only
pub fn RigidBodyBuilder::soft_ccd_prediction(
  self : RigidBodyBuilder,
  prediction_distance : @core.Real,
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
pub fn RigidBody::set_next_kinematic_rotation(
  self : RigidBody,
  rotation : @core.Rot2,
) -> RigidBody {
  ...
}

///|
#declaration_only
pub fn RigidBody::set_next_kinematic_position(
  self : RigidBody,
  position : @core.Isometry2,
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
pub type MultibodyIndex

///|
#declaration_only
pub fn MultibodyIndex::invalid() -> MultibodyIndex {
  ...
}

///|
#declaration_only
pub type MultibodyLinkId

///|
#declaration_only
pub fn MultibodyJointHandle::from_raw_parts(
  id : Int,
  generation : Int,
) -> MultibodyJointHandle {
  ...
}

///|
#declaration_only
pub fn MultibodyJointHandle::into_raw_parts(
  self : MultibodyJointHandle,
) -> (Int, Int) {
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
pub fn MultibodyJointSet::insert_kinematic(
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
pub fn MultibodyJointSet::remove(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
  wake_up : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::remove_multibody_articulations(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
  wake_up : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::rigid_body_link(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> MultibodyLinkId? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::get_multibody(
  self : MultibodyJointSet,
  index : MultibodyIndex,
) -> Multibody? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::get_multibody_mut(
  self : MultibodyJointSet,
  index : MultibodyIndex,
) -> Multibody? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::get_multibody_mut_internal(
  self : MultibodyJointSet,
  index : MultibodyIndex,
) -> Multibody? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::multibodies(
  self : MultibodyJointSet,
) -> Array[Multibody] {
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
pub fn MultibodyJointSet::get_mut_internal(
  self : MultibodyJointSet,
  handle : MultibodyJointHandle,
) -> (Multibody, LinkId)? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::get_unknown_gen(
  self : MultibodyJointSet,
  id : Int,
) -> (Multibody, LinkId, MultibodyJointHandle)? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::joint_between(
  self : MultibodyJointSet,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> (MultibodyJointHandle, Multibody, MultibodyLink)? {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::attached_joints(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Array[(RigidBodyHandle, RigidBodyHandle, MultibodyJointHandle)] {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::attached_bodies(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Array[RigidBodyHandle] {
  ...
}

///|
#declaration_only
pub fn MultibodyJointSet::bodies_attached_with_enabled_joint(
  self : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Array[RigidBodyHandle] {
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
