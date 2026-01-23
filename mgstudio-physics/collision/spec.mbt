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
pub type ColliderHandle

///|
#declaration_only
pub fn ColliderHandle::equals(
  self : ColliderHandle,
  other : ColliderHandle,
) -> Bool {
  ...
}

///|
#declaration_only
pub type ActiveCollisionTypes

///|
#declaration_only
pub fn ActiveCollisionTypes::all() -> ActiveCollisionTypes {
  ...
}

///|
#declaration_only
pub fn ActiveCollisionTypes::equals(
  self : ActiveCollisionTypes,
  other : ActiveCollisionTypes,
) -> Bool {
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
pub(all) enum ActiveEvents {
  CollisionEvents
  ContactForceEvents
}

///|
#declaration_only
pub type ActiveHooks

///|
#declaration_only
pub fn ActiveHooks::empty() -> ActiveHooks {
  ...
}

///|
#declaration_only
pub fn ActiveHooks::all() -> ActiveHooks {
  ...
}

///|
#declaration_only
pub fn ActiveHooks::filter_contact_pairs() -> ActiveHooks {
  ...
}

///|
#declaration_only
pub fn ActiveHooks::filter_intersection_pair() -> ActiveHooks {
  ...
}

///|
#declaration_only
pub fn ActiveHooks::modify_solver_contacts() -> ActiveHooks {
  ...
}

///|
#declaration_only
pub fn ActiveHooks::contains(self : ActiveHooks, other : ActiveHooks) -> Bool {
  ...
}

///|
#declaration_only
pub fn ActiveHooks::insert(
  self : ActiveHooks,
  other : ActiveHooks,
) -> ActiveHooks {
  ...
}

///|
pub(all) enum ColliderEnabled {
  Enabled
  DisabledByParent
  Disabled
}

///|
#declaration_only
pub type Collider

///|
#declaration_only
pub type Shape

///|
#declaration_only
pub type ColliderBuilder

///|
#declaration_only
pub fn ColliderBuilder::ball(radius : @core.Real) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::cuboid(
  half_width : @core.Real,
  half_height : @core.Real,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::translation(
  self : ColliderBuilder,
  translation : @core.Vec2,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::rotation(
  self : ColliderBuilder,
  rotation : @core.Real,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::active_collision_types(
  self : ColliderBuilder,
  types : ActiveCollisionTypes,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::sensor(
  self : ColliderBuilder,
  enabled : Bool,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::active_events(
  self : ColliderBuilder,
  events : ActiveEvents,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::active_hooks(
  self : ColliderBuilder,
  hooks : ActiveHooks,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::collision_groups(
  self : ColliderBuilder,
  groups : InteractionGroups,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::solver_groups(
  self : ColliderBuilder,
  groups : InteractionGroups,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::friction(
  self : ColliderBuilder,
  friction : @core.Real,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::friction_combine_rule(
  self : ColliderBuilder,
  rule : @dynamics.CoefficientCombineRule,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::restitution(
  self : ColliderBuilder,
  value : @core.Real,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::restitution_combine_rule(
  self : ColliderBuilder,
  rule : @dynamics.CoefficientCombineRule,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::contact_skin(
  self : ColliderBuilder,
  skin : @core.Real,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::contact_force_event_threshold(
  self : ColliderBuilder,
  threshold : @core.Real,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::user_data(
  self : ColliderBuilder,
  data : Int,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::enabled(
  self : ColliderBuilder,
  enabled : Bool,
) -> ColliderBuilder {
  ...
}

///|
#declaration_only
pub fn ColliderBuilder::build(self : ColliderBuilder) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::shape(self : Collider) -> Shape {
  ...
}

///|
#declaration_only
pub fn Collider::set_shape(self : Collider, shape : Shape) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::translation(self : Collider) -> @core.Vec2 {
  ...
}

///|
#declaration_only
pub fn Collider::position(self : Collider) -> @core.Isometry2 {
  ...
}

///|
#declaration_only
pub fn Collider::rotation(self : Collider) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn Collider::position_wrt_parent(self : Collider) -> @core.Isometry2? {
  ...
}

///|
#declaration_only
pub fn Collider::parent(self : Collider) -> @dynamics.RigidBodyHandle? {
  ...
}

///|
#declaration_only
pub fn Collider::is_sensor(self : Collider) -> Bool {
  ...
}

///|
#declaration_only
pub fn Collider::active_collision_types(
  self : Collider,
) -> ActiveCollisionTypes {
  ...
}

///|
#declaration_only
pub fn Collider::active_events(self : Collider) -> ActiveEvents? {
  ...
}

///|
#declaration_only
pub fn Collider::active_hooks(self : Collider) -> ActiveHooks {
  ...
}

///|
#declaration_only
pub fn Collider::collision_groups(self : Collider) -> InteractionGroups {
  ...
}

///|
#declaration_only
pub fn Collider::solver_groups(self : Collider) -> InteractionGroups {
  ...
}

///|
#declaration_only
pub fn Collider::friction(self : Collider) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn Collider::friction_combine_rule(
  self : Collider,
) -> @dynamics.CoefficientCombineRule {
  ...
}

///|
#declaration_only
pub fn Collider::restitution(self : Collider) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn Collider::restitution_combine_rule(
  self : Collider,
) -> @dynamics.CoefficientCombineRule {
  ...
}

///|
#declaration_only
pub fn Collider::contact_skin(self : Collider) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn Collider::contact_force_event_threshold(self : Collider) -> @core.Real {
  ...
}

///|
#declaration_only
pub fn Collider::user_data(self : Collider) -> Int {
  ...
}

///|
#declaration_only
pub fn Collider::is_enabled(self : Collider) -> Bool {
  ...
}

///|
#declaration_only
pub fn Collider::set_sensor(self : Collider, enabled : Bool) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_active_collision_types(
  self : Collider,
  types : ActiveCollisionTypes,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_active_events(
  self : Collider,
  events : ActiveEvents?,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_active_hooks(
  self : Collider,
  hooks : ActiveHooks,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_collision_groups(
  self : Collider,
  groups : InteractionGroups,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_solver_groups(
  self : Collider,
  groups : InteractionGroups,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_friction(
  self : Collider,
  friction : @core.Real,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_friction_combine_rule(
  self : Collider,
  rule : @dynamics.CoefficientCombineRule,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_restitution(
  self : Collider,
  restitution : @core.Real,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_restitution_combine_rule(
  self : Collider,
  rule : @dynamics.CoefficientCombineRule,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_contact_skin(
  self : Collider,
  skin : @core.Real,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_contact_force_event_threshold(
  self : Collider,
  threshold : @core.Real,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_user_data(self : Collider, data : Int) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_translation(
  self : Collider,
  translation : @core.Vec2,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_rotation(
  self : Collider,
  rotation : @core.Real,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_position(
  self : Collider,
  position : @core.Isometry2,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_translation_wrt_parent(
  self : Collider,
  translation : @core.Vec2,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_rotation_wrt_parent(
  self : Collider,
  rotation : @core.Real,
) -> Collider {
  ...
}

///|
#declaration_only
pub fn Collider::set_enabled(self : Collider, enabled : Bool) -> Collider {
  ...
}

///|
#declaration_only
pub type ColliderSet

///|
#declaration_only
pub fn ColliderSet::new() -> ColliderSet {
  ...
}

///|
#declaration_only
pub fn ColliderSet::insert(
  self : ColliderSet,
  collider : Collider,
) -> ColliderHandle {
  ...
}

///|
#declaration_only
pub fn ColliderSet::colliders_with_parent(
  self : ColliderSet,
  parent : @dynamics.RigidBodyHandle,
) -> Array[ColliderHandle] {
  ...
}

///|
#declaration_only
pub fn ColliderSet::insert_with_parent(
  self : ColliderSet,
  collider : Collider,
  parent : @dynamics.RigidBodyHandle,
  bodies : @dynamics.RigidBodySet,
) -> ColliderHandle {
  ...
}

///|
#declaration_only
pub fn ColliderSet::get(
  self : ColliderSet,
  handle : ColliderHandle,
) -> Collider? {
  ...
}

///|
#declaration_only
pub fn ColliderSet::get_mut(
  self : ColliderSet,
  handle : ColliderHandle,
) -> Collider? {
  ...
}

///|
#declaration_only
pub fn ColliderSet::remove(
  self : ColliderSet,
  handle : ColliderHandle,
  islands : @dynamics.IslandManager,
  bodies : @dynamics.RigidBodySet,
  wake_up : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn ColliderSet::set_parent(
  self : ColliderSet,
  handle : ColliderHandle,
  parent : @dynamics.RigidBodyHandle?,
  bodies : @dynamics.RigidBodySet,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn ColliderSet::set_parent_enabled(
  self : ColliderSet,
  parent : @dynamics.RigidBodyHandle,
  enabled : Bool,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn ColliderSet::take_modified(self : ColliderSet) -> Array[ColliderHandle] {
  ...
}

///|
#declaration_only
pub fn ColliderSet::clear_changes_for(
  self : ColliderSet,
  handles : Array[ColliderHandle],
) -> Unit {
  ...
}

///|
#declaration_only
pub fn handle_user_changes_to_colliders(
  bodies : @dynamics.RigidBodySet,
  colliders : ColliderSet,
  modified_colliders : Array[ColliderHandle],
) -> Unit {
  ...
}

///|
pub struct IntersectionPair {
  collider1 : ColliderHandle
  collider2 : ColliderHandle
  intersecting : Bool
}

///|
#declaration_only
pub type ContactPair

///|
#declaration_only
pub fn ContactPair::manifold_count(self : ContactPair) -> Int {
  ...
}

///|
#declaration_only
pub type NarrowPhase

///|
#declaration_only
pub fn NarrowPhase::new() -> NarrowPhase {
  ...
}

///|
#declaration_only
pub fn NarrowPhase::intersection_pairs_with(
  self : NarrowPhase,
  handle : ColliderHandle,
) -> Array[IntersectionPair] {
  ...
}

///|
#declaration_only
pub fn NarrowPhase::contact_pairs_with(
  self : NarrowPhase,
  handle : ColliderHandle,
) -> Array[(ColliderHandle, ColliderHandle, ContactPair)] {
  ...
}

///|
#declaration_only
pub fn NarrowPhase::contact_pair(
  self : NarrowPhase,
  first : ColliderHandle,
  second : ColliderHandle,
) -> ContactPair? {
  ...
}

///|
#declaration_only
pub fn NarrowPhase::intersection_pair(
  self : NarrowPhase,
  first : ColliderHandle,
  second : ColliderHandle,
) -> IntersectionPair? {
  ...
}

///|
#declaration_only
pub fn NarrowPhase::update(
  self : NarrowPhase,
  bodies : @dynamics.RigidBodySet,
  colliders : ColliderSet,
) -> Unit {
  ...
}

///|
#declaration_only
pub fn NarrowPhase::query_dispatcher(
  self : NarrowPhase,
) -> @query.QueryDispatcher {
  ...
}

///|
#declaration_only
pub type BroadPhaseBvh

///|
#declaration_only
pub fn BroadPhaseBvh::new() -> BroadPhaseBvh {
  ...
}

///|
#declaration_only
pub fn BroadPhaseBvh::as_query_pipeline(
  self : BroadPhaseBvh,
  dispatcher : @query.QueryDispatcher,
  bodies : @dynamics.RigidBodySet,
  colliders : ColliderSet,
  filter : @query.QueryFilter,
) -> @query.QueryPipeline {
  ...
}
