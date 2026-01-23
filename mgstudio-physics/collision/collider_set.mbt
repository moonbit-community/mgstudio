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
pub struct ColliderHandle {
  id : Int
  generation : Int
}

///|
fn ColliderHandle::new(id : Int, generation : Int) -> ColliderHandle {
  ColliderHandle::{ id, generation }
}

///|
pub fn ColliderHandle::equals(
  self : ColliderHandle,
  other : ColliderHandle,
) -> Bool {
  self.id == other.id && self.generation == other.generation
}

///|
const COLLIDER_CHANGES_IN_MODIFIED_SET : Int = 1 << 0

///|
const COLLIDER_CHANGES_POSITION : Int = 1 << 1

///|
const COLLIDER_CHANGES_SHAPE : Int = 1 << 2

///|
const COLLIDER_CHANGES_LOCAL_MASS_PROPERTIES : Int = 1 << 3

///|
const COLLIDER_CHANGES_PARENT : Int = 1 << 4

///|
const COLLIDER_CHANGES_ENABLED_OR_DISABLED : Int = 1 << 5

///|
const COLLIDER_CHANGES_PARENT_EFFECTIVE_DOMINANCE : Int = 1 << 6

///|
const COLLIDER_CHANGES_ALL : Int = COLLIDER_CHANGES_IN_MODIFIED_SET |
  COLLIDER_CHANGES_POSITION |
  COLLIDER_CHANGES_SHAPE |
  COLLIDER_CHANGES_LOCAL_MASS_PROPERTIES |
  COLLIDER_CHANGES_PARENT |
  COLLIDER_CHANGES_ENABLED_OR_DISABLED |
  COLLIDER_CHANGES_PARENT_EFFECTIVE_DOMINANCE

///|
struct ColliderChanges {
  mut bits : Int
}

///|
fn ColliderChanges::all() -> ColliderChanges {
  { bits: COLLIDER_CHANGES_ALL }
}

///|
fn ColliderChanges::contains(self : ColliderChanges, flag : Int) -> Bool {
  (self.bits & flag) != 0
}

///|
fn ColliderChanges::insert(
  self : ColliderChanges,
  flag : Int,
) -> ColliderChanges {
  self.bits = self.bits | flag
  self
}

///|
fn ColliderChanges::remove(
  self : ColliderChanges,
  flag : Int,
) -> ColliderChanges {
  let clear_bits = self.bits & flag
  self.bits = self.bits - clear_bits
  self
}

///|
pub struct ActiveCollisionTypes {
  value : Int
}

///|
const ACTIVE_COLLISION_DYNAMIC_DYNAMIC : Int = 0x0001

///|
const ACTIVE_COLLISION_DYNAMIC_KINEMATIC : Int = 0x000C

///|
const ACTIVE_COLLISION_DYNAMIC_FIXED : Int = 0x0002

///|
const ACTIVE_COLLISION_KINEMATIC_KINEMATIC : Int = 0xCC00

///|
const ACTIVE_COLLISION_KINEMATIC_FIXED : Int = 0x2200

///|
const ACTIVE_COLLISION_FIXED_FIXED : Int = 0x0020

///|
const ACTIVE_COLLISION_DEFAULT : Int = ACTIVE_COLLISION_DYNAMIC_DYNAMIC |
  ACTIVE_COLLISION_DYNAMIC_KINEMATIC |
  ACTIVE_COLLISION_DYNAMIC_FIXED

///|
const ACTIVE_COLLISION_ALL : Int = ACTIVE_COLLISION_DEFAULT |
  ACTIVE_COLLISION_KINEMATIC_KINEMATIC |
  ACTIVE_COLLISION_KINEMATIC_FIXED |
  ACTIVE_COLLISION_FIXED_FIXED

///|
pub fn ActiveCollisionTypes::all() -> ActiveCollisionTypes {
  { value: ACTIVE_COLLISION_ALL }
}

///|
pub fn ActiveCollisionTypes::default() -> ActiveCollisionTypes {
  { value: ACTIVE_COLLISION_DEFAULT }
}

///|
pub fn ActiveCollisionTypes::equals(
  self : ActiveCollisionTypes,
  other : ActiveCollisionTypes,
) -> Bool {
  self.value == other.value
}

///|
fn rigid_body_type_index(body_type : @dynamics.RigidBodyType) -> Int {
  match body_type {
    @dynamics.RigidBodyType::Dynamic => 0
    @dynamics.RigidBodyType::Fixed => 1
    @dynamics.RigidBodyType::KinematicPositionBased => 2
    @dynamics.RigidBodyType::KinematicVelocityBased => 3
  }
}

///|
pub fn ActiveCollisionTypes::test_body_types(
  self : ActiveCollisionTypes,
  body_type1 : @dynamics.RigidBodyType,
  body_type2 : @dynamics.RigidBodyType,
) -> Bool {
  let index1 = rigid_body_type_index(body_type1)
  let index2 = rigid_body_type_index(body_type2)
  let mask1 = (self.value >> (index1 * 4)) & 0xF
  let mask2 = (self.value >> (index2 * 4)) & 0xF
  (mask1 & (1 << index2)) != 0 || (mask2 & (1 << index1)) != 0
}

///|
const ACTIVE_HOOKS_FILTER_CONTACT_PAIRS : Int = 1 << 0

///|
const ACTIVE_HOOKS_FILTER_INTERSECTION_PAIR : Int = 1 << 1

///|
const ACTIVE_HOOKS_MODIFY_SOLVER_CONTACTS : Int = 1 << 2

///|
pub struct ActiveHooks {
  mut value : Int
}

///|
pub fn ActiveHooks::empty() -> ActiveHooks {
  { value: 0 }
}

///|
pub fn ActiveHooks::all() -> ActiveHooks {
  {
    value: ACTIVE_HOOKS_FILTER_CONTACT_PAIRS |
    ACTIVE_HOOKS_FILTER_INTERSECTION_PAIR |
    ACTIVE_HOOKS_MODIFY_SOLVER_CONTACTS,
  }
}

///|
pub fn ActiveHooks::filter_contact_pairs() -> ActiveHooks {
  { value: ACTIVE_HOOKS_FILTER_CONTACT_PAIRS }
}

///|
pub fn ActiveHooks::filter_intersection_pair() -> ActiveHooks {
  { value: ACTIVE_HOOKS_FILTER_INTERSECTION_PAIR }
}

///|
pub fn ActiveHooks::modify_solver_contacts() -> ActiveHooks {
  { value: ACTIVE_HOOKS_MODIFY_SOLVER_CONTACTS }
}

///|
pub fn ActiveHooks::contains(self : ActiveHooks, other : ActiveHooks) -> Bool {
  (self.value & other.value) == other.value
}

///|
pub fn ActiveHooks::insert(
  self : ActiveHooks,
  other : ActiveHooks,
) -> ActiveHooks {
  self.value = self.value | other.value
  self
}

///|
pub(all) enum Shape {
  Ball(@core.Real)
  Cuboid(@core.Real, @core.Real)
}

///|
pub struct Collider {
  mut shape : Shape
  mut local_translation : @core.Vec2
  mut local_rotation : @core.Real
  mut world_translation : @core.Vec2
  mut world_rotation : @core.Real
  mut active_collision_types : ActiveCollisionTypes
  mut sensor : Bool
  mut active_events : ActiveEvents?
  mut active_hooks : ActiveHooks
  mut collision_groups : @dynamics.InteractionGroups
  mut solver_groups : @dynamics.InteractionGroups
  mut friction : @core.Real
  mut friction_combine_rule : @dynamics.CoefficientCombineRule
  mut restitution : @core.Real
  mut restitution_combine_rule : @dynamics.CoefficientCombineRule
  mut contact_skin : @core.Real
  mut contact_force_event_threshold : @core.Real
  mut user_data : Int
  mut parent : @dynamics.RigidBodyHandle?
  mut enabled : ColliderEnabled
  mut changes : ColliderChanges
}

///|
pub struct ColliderBuilder {
  shape : Shape
  mut translation : @core.Vec2
  mut rotation : @core.Real
  mut active_collision_types : ActiveCollisionTypes
  mut sensor : Bool
  mut active_events : ActiveEvents?
  mut active_hooks : ActiveHooks
  mut collision_groups : @dynamics.InteractionGroups
  mut solver_groups : @dynamics.InteractionGroups
  mut friction : @core.Real
  mut friction_combine_rule : @dynamics.CoefficientCombineRule
  mut restitution : @core.Real
  mut restitution_combine_rule : @dynamics.CoefficientCombineRule
  mut contact_skin : @core.Real
  mut contact_force_event_threshold : @core.Real
  mut user_data : Int
  mut enabled : Bool
}

///|
pub fn ColliderBuilder::ball(radius : @core.Real) -> ColliderBuilder {
  {
    shape: Shape::Ball(radius),
    translation: @core.Vec2::zero(),
    rotation: 0.0F,
    active_collision_types: ActiveCollisionTypes::default(),
    sensor: false,
    active_events: None,
    active_hooks: ActiveHooks::empty(),
    collision_groups: @dynamics.InteractionGroups::all(),
    solver_groups: @dynamics.InteractionGroups::all(),
    friction: 0.5F,
    friction_combine_rule: @dynamics.CoefficientCombineRule::Average,
    restitution: 0.0F,
    restitution_combine_rule: @dynamics.CoefficientCombineRule::Average,
    contact_skin: 0.0F,
    contact_force_event_threshold: 0.0F,
    user_data: 0,
    enabled: true,
  }
}

///|
pub fn ColliderBuilder::cuboid(
  half_width : @core.Real,
  half_height : @core.Real,
) -> ColliderBuilder {
  {
    shape: Shape::Cuboid(half_width, half_height),
    translation: @core.Vec2::zero(),
    rotation: 0.0F,
    active_collision_types: ActiveCollisionTypes::default(),
    sensor: false,
    active_events: None,
    active_hooks: ActiveHooks::empty(),
    collision_groups: @dynamics.InteractionGroups::all(),
    solver_groups: @dynamics.InteractionGroups::all(),
    friction: 0.5F,
    friction_combine_rule: @dynamics.CoefficientCombineRule::Average,
    restitution: 0.0F,
    restitution_combine_rule: @dynamics.CoefficientCombineRule::Average,
    contact_skin: 0.0F,
    contact_force_event_threshold: 0.0F,
    user_data: 0,
    enabled: true,
  }
}

///|
pub fn ColliderBuilder::translation(
  self : ColliderBuilder,
  translation : @core.Vec2,
) -> ColliderBuilder {
  self.translation = translation
  self
}

///|
pub fn ColliderBuilder::rotation(
  self : ColliderBuilder,
  rotation : @core.Real,
) -> ColliderBuilder {
  self.rotation = rotation
  self
}

///|
pub fn ColliderBuilder::active_collision_types(
  self : ColliderBuilder,
  types : ActiveCollisionTypes,
) -> ColliderBuilder {
  self.active_collision_types = types
  self
}

///|
pub fn ColliderBuilder::sensor(
  self : ColliderBuilder,
  enabled : Bool,
) -> ColliderBuilder {
  self.sensor = enabled
  self
}

///|
pub fn ColliderBuilder::active_events(
  self : ColliderBuilder,
  events : ActiveEvents,
) -> ColliderBuilder {
  self.active_events = Some(events)
  self
}

///|
pub fn ColliderBuilder::active_hooks(
  self : ColliderBuilder,
  hooks : ActiveHooks,
) -> ColliderBuilder {
  self.active_hooks = hooks
  self
}

///|
pub fn ColliderBuilder::collision_groups(
  self : ColliderBuilder,
  groups : @dynamics.InteractionGroups,
) -> ColliderBuilder {
  self.collision_groups = groups
  self
}

///|
pub fn ColliderBuilder::solver_groups(
  self : ColliderBuilder,
  groups : @dynamics.InteractionGroups,
) -> ColliderBuilder {
  self.solver_groups = groups
  self
}

///|
pub fn ColliderBuilder::friction(
  self : ColliderBuilder,
  friction : @core.Real,
) -> ColliderBuilder {
  self.friction = friction
  self
}

///|
pub fn ColliderBuilder::friction_combine_rule(
  self : ColliderBuilder,
  rule : @dynamics.CoefficientCombineRule,
) -> ColliderBuilder {
  self.friction_combine_rule = rule
  self
}

///|
pub fn ColliderBuilder::restitution(
  self : ColliderBuilder,
  value : @core.Real,
) -> ColliderBuilder {
  self.restitution = value
  self
}

///|
pub fn ColliderBuilder::restitution_combine_rule(
  self : ColliderBuilder,
  rule : @dynamics.CoefficientCombineRule,
) -> ColliderBuilder {
  self.restitution_combine_rule = rule
  self
}

///|
pub fn ColliderBuilder::contact_skin(
  self : ColliderBuilder,
  skin : @core.Real,
) -> ColliderBuilder {
  self.contact_skin = skin
  self
}

///|
pub fn ColliderBuilder::contact_force_event_threshold(
  self : ColliderBuilder,
  threshold : @core.Real,
) -> ColliderBuilder {
  self.contact_force_event_threshold = threshold
  self
}

///|
pub fn ColliderBuilder::user_data(
  self : ColliderBuilder,
  data : Int,
) -> ColliderBuilder {
  self.user_data = data
  self
}

///|
pub fn ColliderBuilder::enabled(
  self : ColliderBuilder,
  enabled : Bool,
) -> ColliderBuilder {
  self.enabled = enabled
  self
}

///|
pub fn ColliderBuilder::build(self : ColliderBuilder) -> Collider {
  {
    shape: self.shape,
    local_translation: self.translation,
    local_rotation: self.rotation,
    world_translation: self.translation,
    world_rotation: self.rotation,
    active_collision_types: self.active_collision_types,
    sensor: self.sensor,
    active_events: self.active_events,
    active_hooks: self.active_hooks,
    collision_groups: self.collision_groups,
    solver_groups: self.solver_groups,
    friction: self.friction,
    friction_combine_rule: self.friction_combine_rule,
    restitution: self.restitution,
    restitution_combine_rule: self.restitution_combine_rule,
    contact_skin: self.contact_skin,
    contact_force_event_threshold: self.contact_force_event_threshold,
    user_data: self.user_data,
    parent: None,
    enabled: if self.enabled {
      ColliderEnabled::Enabled
    } else {
      ColliderEnabled::Disabled
    },
    changes: ColliderChanges::all(),
  }
}

///|
pub fn Collider::shape(self : Collider) -> Shape {
  self.shape
}

///|
pub fn Collider::set_shape(self : Collider, shape : Shape) -> Collider {
  self.shape = shape
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::translation(self : Collider) -> @core.Vec2 {
  self.world_translation
}

///|
pub fn Collider::position(self : Collider) -> @core.Isometry2 {
  @core.Isometry2::new(
    self.world_translation,
    @core.Rot2::from_angle(self.world_rotation),
  )
}

///|
pub fn Collider::rotation(self : Collider) -> @core.Real {
  self.world_rotation
}

///|
pub fn Collider::position_wrt_parent(self : Collider) -> @core.Isometry2? {
  if self.parent is Some(_) {
    Some(
      @core.Isometry2::new(
        self.local_translation,
        @core.Rot2::from_angle(self.local_rotation),
      ),
    )
  } else {
    None
  }
}

///|
pub fn Collider::parent(self : Collider) -> @dynamics.RigidBodyHandle? {
  self.parent
}

///|
pub fn Collider::is_sensor(self : Collider) -> Bool {
  self.sensor
}

///|
pub fn Collider::active_collision_types(
  self : Collider,
) -> ActiveCollisionTypes {
  self.active_collision_types
}

///|
pub fn Collider::active_events(self : Collider) -> ActiveEvents? {
  self.active_events
}

///|
pub fn Collider::active_hooks(self : Collider) -> ActiveHooks {
  self.active_hooks
}

///|
pub fn Collider::collision_groups(
  self : Collider,
) -> @dynamics.InteractionGroups {
  self.collision_groups
}

///|
pub fn Collider::solver_groups(self : Collider) -> @dynamics.InteractionGroups {
  self.solver_groups
}

///|
pub fn Collider::friction(self : Collider) -> @core.Real {
  self.friction
}

///|
pub fn Collider::friction_combine_rule(
  self : Collider,
) -> @dynamics.CoefficientCombineRule {
  self.friction_combine_rule
}

///|
pub fn Collider::restitution(self : Collider) -> @core.Real {
  self.restitution
}

///|
pub fn Collider::restitution_combine_rule(
  self : Collider,
) -> @dynamics.CoefficientCombineRule {
  self.restitution_combine_rule
}

///|
pub fn Collider::contact_skin(self : Collider) -> @core.Real {
  self.contact_skin
}

///|
pub fn Collider::contact_force_event_threshold(self : Collider) -> @core.Real {
  self.contact_force_event_threshold
}

///|
pub fn Collider::user_data(self : Collider) -> Int {
  self.user_data
}

///|
pub fn Collider::is_enabled(self : Collider) -> Bool {
  self.enabled is ColliderEnabled::Enabled
}

///|
pub fn Collider::set_sensor(self : Collider, enabled : Bool) -> Collider {
  if self.sensor != enabled {
    self.sensor = enabled
    self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  }
  self
}

///|
pub fn Collider::set_active_collision_types(
  self : Collider,
  types : ActiveCollisionTypes,
) -> Collider {
  self.active_collision_types = types
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_active_events(
  self : Collider,
  events : ActiveEvents?,
) -> Collider {
  self.active_events = events
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_active_hooks(
  self : Collider,
  hooks : ActiveHooks,
) -> Collider {
  self.active_hooks = hooks
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_collision_groups(
  self : Collider,
  groups : @dynamics.InteractionGroups,
) -> Collider {
  self.collision_groups = groups
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_solver_groups(
  self : Collider,
  groups : @dynamics.InteractionGroups,
) -> Collider {
  self.solver_groups = groups
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_friction(
  self : Collider,
  friction : @core.Real,
) -> Collider {
  self.friction = friction
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_friction_combine_rule(
  self : Collider,
  rule : @dynamics.CoefficientCombineRule,
) -> Collider {
  self.friction_combine_rule = rule
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_restitution(
  self : Collider,
  restitution : @core.Real,
) -> Collider {
  self.restitution = restitution
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_restitution_combine_rule(
  self : Collider,
  rule : @dynamics.CoefficientCombineRule,
) -> Collider {
  self.restitution_combine_rule = rule
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_contact_skin(
  self : Collider,
  skin : @core.Real,
) -> Collider {
  self.contact_skin = skin
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_contact_force_event_threshold(
  self : Collider,
  threshold : @core.Real,
) -> Collider {
  self.contact_force_event_threshold = threshold
  self.changes = self.changes.insert(COLLIDER_CHANGES_SHAPE)
  self
}

///|
pub fn Collider::set_user_data(self : Collider, data : Int) -> Collider {
  self.user_data = data
  self
}

///|
pub fn Collider::set_translation(
  self : Collider,
  translation : @core.Vec2,
) -> Collider {
  if self.parent is None {
    self.local_translation = translation
    self.world_translation = translation
    self.changes = self.changes.insert(COLLIDER_CHANGES_POSITION)
  }
  self
}

///|
pub fn Collider::set_rotation(
  self : Collider,
  rotation : @core.Real,
) -> Collider {
  if self.parent is None {
    self.local_rotation = rotation
    self.world_rotation = rotation
    self.changes = self.changes.insert(COLLIDER_CHANGES_POSITION)
  }
  self
}

///|
pub fn Collider::set_position(
  self : Collider,
  position : @core.Isometry2,
) -> Collider {
  if self.parent is None {
    self.local_translation = position.translation
    self.local_rotation = position.rotation.angle()
    self.world_translation = position.translation
    self.world_rotation = position.rotation.angle()
    self.changes = self.changes.insert(COLLIDER_CHANGES_POSITION)
  }
  self
}

///|
pub fn Collider::set_translation_wrt_parent(
  self : Collider,
  translation : @core.Vec2,
) -> Collider {
  if self.parent is Some(_) {
    self.local_translation = translation
    self.changes = self.changes.insert(COLLIDER_CHANGES_PARENT)
  }
  self
}

///|
pub fn Collider::set_rotation_wrt_parent(
  self : Collider,
  rotation : @core.Real,
) -> Collider {
  if self.parent is Some(_) {
    self.local_rotation = rotation
    self.changes = self.changes.insert(COLLIDER_CHANGES_PARENT)
  }
  self
}

///|
pub fn Collider::set_enabled(self : Collider, enabled : Bool) -> Collider {
  match self.enabled {
    ColliderEnabled::Enabled | ColliderEnabled::DisabledByParent =>
      if !enabled {
        self.changes = self.changes.insert(COLLIDER_CHANGES_ENABLED_OR_DISABLED)
        self.enabled = ColliderEnabled::Disabled
      }
    ColliderEnabled::Disabled =>
      if enabled {
        self.changes = self.changes.insert(COLLIDER_CHANGES_ENABLED_OR_DISABLED)
        self.enabled = ColliderEnabled::Enabled
      }
  }
  self
}

///|
fn Collider::clear_changes(self : Collider) -> Collider {
  self.changes = self.changes.remove(COLLIDER_CHANGES_ALL)
  self
}

///|
pub struct ColliderSet {
  colliders : Array[Collider?]
  generations : Array[Int]
  free_list : Array[Int]
  modified_colliders : Array[ColliderHandle]
}

///|
pub fn ColliderSet::new() -> ColliderSet {
  { colliders: [], generations: [], free_list: [], modified_colliders: [] }
}

///|
fn ColliderSet::allocate_handle(self : ColliderSet) -> ColliderHandle {
  if self.free_list.pop() is Some(index) {
    let generation = self.generations[index]
    ColliderHandle::new(index, generation)
  } else {
    let index = self.colliders.length()
    self.colliders.push(None)
    self.generations.push(0)
    ColliderHandle::new(index, 0)
  }
}

///|
fn collider_handle_equals(
  left : ColliderHandle,
  right : ColliderHandle,
) -> Bool {
  left.id == right.id && left.generation == right.generation
}

///|
fn is_same_parent(left : Collider, right : Collider) -> Bool {
  if left.parent is Some(parent1) && right.parent is Some(parent2) {
    @dynamics.RigidBodyHandle::equals(parent1, parent2)
  } else {
    false
  }
}

///|
fn update_collider_world_pose(
  collider : Collider,
  bodies : @dynamics.RigidBodySet,
) -> Collider {
  if collider.parent is Some(parent) {
    if bodies.get(parent) is Some(body) {
      let body_translation = body.translation()
      collider.world_translation = body_translation.add(
        collider.local_translation,
      )
      collider.world_rotation = body.rotation().angle() +
        collider.local_rotation
      return collider
    }
  }
  collider.world_translation = collider.local_translation
  collider.world_rotation = collider.local_rotation
  collider
}

///|
fn ColliderSet::push_modified_unchecked(
  self : ColliderSet,
  handle : ColliderHandle,
  collider : Collider,
) -> Unit {
  collider.changes = collider.changes.insert(COLLIDER_CHANGES_IN_MODIFIED_SET)
  self.modified_colliders.push(handle)
}

///|
fn ColliderSet::push_modified(
  self : ColliderSet,
  handle : ColliderHandle,
  collider : Collider,
) -> Unit {
  if !collider.changes.contains(COLLIDER_CHANGES_IN_MODIFIED_SET) {
    self.push_modified_unchecked(handle, collider)
  }
}

///|
fn ColliderSet::sync_with_bodies(
  self : ColliderSet,
  bodies : @dynamics.RigidBodySet,
) -> Unit {
  for i in 0..<self.colliders.length() {
    if self.colliders[i] is Some(collider) {
      self.colliders[i] = Some(update_collider_world_pose(collider, bodies))
    }
  }
}

///|
pub fn ColliderSet::insert(
  self : ColliderSet,
  collider : Collider,
) -> ColliderHandle {
  let handle = self.allocate_handle()
  let updated = collider
  updated.changes = ColliderChanges::all()
  self.colliders[handle.id] = Some(updated)
  if self.colliders[handle.id] is Some(collider_ref) {
    self.push_modified_unchecked(handle, collider_ref)
  }
  handle
}

///|
pub fn ColliderSet::colliders_with_parent(
  self : ColliderSet,
  parent : @dynamics.RigidBodyHandle,
) -> Array[ColliderHandle] {
  let result : Array[ColliderHandle] = []
  for i in 0..<self.colliders.length() {
    if self.colliders[i] is Some(collider) {
      if collider.parent is Some(current_parent) &&
        @dynamics.RigidBodyHandle::equals(current_parent, parent) {
        result.push(ColliderHandle::new(i, self.generations[i]))
      }
    }
  }
  result
}

///|
pub fn ColliderSet::insert_with_parent(
  self : ColliderSet,
  collider : Collider,
  parent : @dynamics.RigidBodyHandle,
  bodies : @dynamics.RigidBodySet,
) -> ColliderHandle {
  let handle = self.allocate_handle()
  let updated = collider
  updated.changes = ColliderChanges::all()
  updated.parent = Some(parent)
  let updated_world = update_collider_world_pose(updated, bodies)
  self.colliders[handle.id] = Some(updated_world)
  if self.colliders[handle.id] is Some(collider_ref) {
    self.push_modified_unchecked(handle, collider_ref)
  }
  handle
}

///|
pub fn ColliderSet::get(
  self : ColliderSet,
  handle : ColliderHandle,
) -> Collider? {
  if handle.id < 0 || handle.id >= self.colliders.length() {
    return None
  }
  if self.generations[handle.id] != handle.generation {
    return None
  }
  self.colliders[handle.id]
}

///|
pub fn ColliderSet::get_mut(
  self : ColliderSet,
  handle : ColliderHandle,
) -> Collider? {
  self.get_mut_internal_with_modification_tracking(handle)
}

///|
pub fn ColliderSet::get_mut_internal(
  self : ColliderSet,
  handle : ColliderHandle,
) -> Collider? {
  if handle.id < 0 || handle.id >= self.colliders.length() {
    return None
  }
  if self.generations[handle.id] != handle.generation {
    return None
  }
  self.colliders[handle.id]
}

///|
pub fn ColliderSet::get_mut_internal_with_modification_tracking(
  self : ColliderSet,
  handle : ColliderHandle,
) -> Collider? {
  if self.get_mut_internal(handle) is Some(collider) {
    self.push_modified(handle, collider)
    Some(collider)
  } else {
    None
  }
}

///|
pub fn ColliderSet::remove(
  self : ColliderSet,
  handle : ColliderHandle,
  islands : @dynamics.IslandManager,
  bodies : @dynamics.RigidBodySet,
  wake_up : Bool,
) -> Unit {
  if handle.id < 0 || handle.id >= self.colliders.length() {
    islands |> ignore
    bodies |> ignore
    wake_up |> ignore
    return
  }
  if self.generations[handle.id] != handle.generation {
    islands |> ignore
    bodies |> ignore
    wake_up |> ignore
    return
  }
  if self.colliders[handle.id] is Some(_) {
    self.colliders[handle.id] = None
    self.generations[handle.id] = self.generations[handle.id] + 1
    self.free_list.push(handle.id)
  }
  islands |> ignore
  bodies |> ignore
  wake_up |> ignore
}

///|
pub fn ColliderSet::take_modified(self : ColliderSet) -> Array[ColliderHandle] {
  let result : Array[ColliderHandle] = []
  for i in 0..<self.modified_colliders.length() {
    let handle = self.modified_colliders[i]
    result.push(handle)
    if handle.id >= 0 && handle.id < self.colliders.length() {
      if self.generations[handle.id] == handle.generation {
        if self.colliders[handle.id] is Some(collider) {
          collider.changes = collider.changes.remove(
            COLLIDER_CHANGES_IN_MODIFIED_SET,
          )
        }
      }
    }
  }
  self.modified_colliders.clear()
  result
}

///|
pub fn ColliderSet::clear_changes_for(
  self : ColliderSet,
  handles : Array[ColliderHandle],
) -> Unit {
  for i in 0..<handles.length() {
    let handle = handles[i]
    if self.get_mut_internal(handle) is Some(collider) {
      collider.clear_changes() |> ignore
    }
  }
}

///|
pub fn ColliderSet::set_parent(
  self : ColliderSet,
  handle : ColliderHandle,
  parent : @dynamics.RigidBodyHandle?,
  bodies : @dynamics.RigidBodySet,
) -> Unit {
  if handle.id < 0 || handle.id >= self.colliders.length() {
    return
  }
  if self.generations[handle.id] != handle.generation {
    return
  }
  if self.colliders[handle.id] is Some(collider) {
    collider.parent = parent
    collider.changes = collider.changes.insert(COLLIDER_CHANGES_PARENT)
    self.colliders[handle.id] = Some(
      update_collider_world_pose(collider, bodies),
    )
    if self.colliders[handle.id] is Some(updated) {
      self.push_modified(handle, updated)
    }
  }
}

///|
pub fn ColliderSet::set_parent_enabled(
  self : ColliderSet,
  parent : @dynamics.RigidBodyHandle,
  enabled : Bool,
) -> Unit {
  for i in 0..<self.colliders.length() {
    if self.colliders[i] is Some(collider) {
      if collider.parent is Some(current_parent) &&
        @dynamics.RigidBodyHandle::equals(current_parent, parent) {
        if enabled {
          if collider.enabled is ColliderEnabled::DisabledByParent {
            collider.enabled = ColliderEnabled::Enabled
            collider.changes = collider.changes.insert(
              COLLIDER_CHANGES_ENABLED_OR_DISABLED,
            )
          }
        } else if collider.enabled is ColliderEnabled::Enabled {
          collider.enabled = ColliderEnabled::DisabledByParent
          collider.changes = collider.changes.insert(
            COLLIDER_CHANGES_ENABLED_OR_DISABLED,
          )
        }
        let handle = ColliderHandle::new(i, self.generations[i])
        self.push_modified(handle, collider)
      }
    }
  }
}

///|
pub fn handle_user_changes_to_colliders(
  bodies : @dynamics.RigidBodySet,
  colliders : ColliderSet,
  modified_colliders : Array[ColliderHandle],
) -> Unit {
  for i in 0..<modified_colliders.length() {
    let handle = modified_colliders[i]
    if colliders.get_mut_internal(handle) is Some(collider) {
      let changes = collider.changes
      let parent = collider.parent
      if changes.contains(COLLIDER_CHANGES_PARENT) {
        let updated = update_collider_world_pose(collider, bodies)
        updated.changes = updated.changes.insert(COLLIDER_CHANGES_POSITION)
        if handle.id >= 0 && handle.id < colliders.colliders.length() {
          colliders.colliders[handle.id] = Some(updated)
        }
      }
      if changes.contains(COLLIDER_CHANGES_PARENT) ||
        changes.contains(COLLIDER_CHANGES_SHAPE) ||
        changes.contains(COLLIDER_CHANGES_LOCAL_MASS_PROPERTIES) ||
        changes.contains(COLLIDER_CHANGES_ENABLED_OR_DISABLED) {
        if parent is Some(rb_handle) {
          if bodies.get_mut_internal_with_modification_tracking(rb_handle)
            is Some(body) {
            body.mark_local_mass_properties_changed() |> ignore
          }
        }
      }
    }
  }
}

///|
pub struct ContactPair {
  manifold_count : Int
}

///|
pub fn ContactPair::manifold_count(self : ContactPair) -> Int {
  self.manifold_count
}

///|
pub struct NarrowPhase {
  mut intersections : Array[IntersectionPair]
  mut contacts : Array[(ColliderHandle, ColliderHandle, ContactPair)]
  dispatcher : @query.QueryDispatcher
}

///|
pub fn NarrowPhase::new() -> NarrowPhase {
  { intersections: [], contacts: [], dispatcher: @query.QueryDispatcher::new() }
}

///|
fn find_intersection_pair(
  pairs : Array[IntersectionPair],
  first : ColliderHandle,
  second : ColliderHandle,
) -> IntersectionPair? {
  for i in 0..<pairs.length() {
    let pair = pairs[i]
    let matches = collider_handle_equals(pair.collider1, first) &&
      collider_handle_equals(pair.collider2, second)
    let matches_swapped = collider_handle_equals(pair.collider1, second) &&
      collider_handle_equals(pair.collider2, first)
    if matches || matches_swapped {
      return Some(pair)
    }
  }
  None
}

///|
fn find_contact_pair(
  pairs : Array[(ColliderHandle, ColliderHandle, ContactPair)],
  first : ColliderHandle,
  second : ColliderHandle,
) -> ContactPair? {
  for i in 0..<pairs.length() {
    let pair = pairs[i]
    let matches = collider_handle_equals(pair.0, first) &&
      collider_handle_equals(pair.1, second)
    let matches_swapped = collider_handle_equals(pair.0, second) &&
      collider_handle_equals(pair.1, first)
    if matches || matches_swapped {
      return Some(pair.2)
    }
  }
  None
}

///|
fn min_value(a : @core.Real, b : @core.Real) -> @core.Real {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_value(a : @core.Real, b : @core.Real) -> @core.Real {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn clamp_value(
  value : @core.Real,
  min_val : @core.Real,
  max_val : @core.Real,
) -> @core.Real {
  max_value(min_val, min_value(max_val, value))
}

///|
fn shapes_intersect(
  shape1 : Shape,
  pos1 : @core.Vec2,
  shape2 : Shape,
  pos2 : @core.Vec2,
) -> Bool {
  match (shape1, shape2) {
    (Shape::Ball(r1), Shape::Ball(r2)) => {
      let delta = pos2.sub(pos1)
      let dist2 = delta.length_squared()
      let radius = r1 + r2
      dist2 <= radius * radius
    }
    (Shape::Cuboid(hw1, hh1), Shape::Cuboid(hw2, hh2)) => {
      let dx = @core.abs(pos2.x - pos1.x)
      let dy = @core.abs(pos2.y - pos1.y)
      dx <= hw1 + hw2 && dy <= hh1 + hh2
    }
    (Shape::Ball(r), Shape::Cuboid(hw, hh)) =>
      ball_cuboid_intersect(pos1, r, pos2, hw, hh)
    (Shape::Cuboid(hw, hh), Shape::Ball(r)) =>
      ball_cuboid_intersect(pos2, r, pos1, hw, hh)
  }
}

///|
fn ball_cuboid_intersect(
  ball_pos : @core.Vec2,
  radius : @core.Real,
  cuboid_pos : @core.Vec2,
  half_width : @core.Real,
  half_height : @core.Real,
) -> Bool {
  let dx = clamp_value(ball_pos.x - cuboid_pos.x, -half_width, half_width)
  let dy = clamp_value(ball_pos.y - cuboid_pos.y, -half_height, half_height)
  let closest = @core.Vec2::new(cuboid_pos.x + dx, cuboid_pos.y + dy)
  let delta = ball_pos.sub(closest)
  delta.length_squared() <= radius * radius
}

///|
pub fn NarrowPhase::update(
  self : NarrowPhase,
  bodies : @dynamics.RigidBodySet,
  colliders : ColliderSet,
) -> Unit {
  colliders.sync_with_bodies(bodies)
  let intersections : Array[IntersectionPair] = []
  let contacts : Array[(ColliderHandle, ColliderHandle, ContactPair)] = []
  for i in 0..<colliders.colliders.length() {
    if colliders.colliders[i] is Some(collider1) {
      if !collider1.is_enabled() {
        continue
      }
      let handle1 = ColliderHandle::new(i, colliders.generations[i])
      for j in (i + 1)..<colliders.colliders.length() {
        if colliders.colliders[j] is Some(collider2) {
          if !collider2.is_enabled() {
            continue
          }
          let handle2 = ColliderHandle::new(j, colliders.generations[j])
          if is_same_parent(collider1, collider2) {
            continue
          }
          let pos1 = collider1.world_translation
          let pos2 = collider2.world_translation
          let intersecting = shapes_intersect(
            collider1.shape,
            pos1,
            collider2.shape,
            pos2,
          )
          if intersecting {
            if collider1.sensor || collider2.sensor {
              intersections.push(IntersectionPair::{
                collider1: handle1,
                collider2: handle2,
                intersecting,
              })
            } else {
              let contact = ContactPair::{ manifold_count: 1 }
              contacts.push((handle1, handle2, contact))
            }
          }
        }
      }
    }
  }
  self.intersections = intersections
  self.contacts = contacts
}

///|
pub fn NarrowPhase::intersection_pairs_with(
  self : NarrowPhase,
  handle : ColliderHandle,
) -> Array[IntersectionPair] {
  let result : Array[IntersectionPair] = []
  for i in 0..<self.intersections.length() {
    let pair = self.intersections[i]
    let matches = collider_handle_equals(pair.collider1, handle) ||
      collider_handle_equals(pair.collider2, handle)
    if matches {
      result.push(pair)
    }
  }
  result
}

///|
pub fn NarrowPhase::contact_pairs_with(
  self : NarrowPhase,
  handle : ColliderHandle,
) -> Array[(ColliderHandle, ColliderHandle, ContactPair)] {
  let result : Array[(ColliderHandle, ColliderHandle, ContactPair)] = []
  for i in 0..<self.contacts.length() {
    let pair = self.contacts[i]
    if ColliderHandle::equals(pair.0, handle) ||
      ColliderHandle::equals(pair.1, handle) {
      result.push(pair)
    }
  }
  result
}

///|
pub fn NarrowPhase::contact_pair(
  self : NarrowPhase,
  first : ColliderHandle,
  second : ColliderHandle,
) -> ContactPair? {
  find_contact_pair(self.contacts, first, second)
}

///|
pub fn NarrowPhase::intersection_pair(
  self : NarrowPhase,
  first : ColliderHandle,
  second : ColliderHandle,
) -> IntersectionPair? {
  find_intersection_pair(self.intersections, first, second)
}

///|
pub fn NarrowPhase::query_dispatcher(
  self : NarrowPhase,
) -> @query.QueryDispatcher {
  self.dispatcher
}

///|
pub struct BroadPhaseBvh {}

///|
pub fn BroadPhaseBvh::new() -> BroadPhaseBvh {
  BroadPhaseBvh::{  }
}

///|
pub fn BroadPhaseBvh::as_query_pipeline(
  self : BroadPhaseBvh,
  dispatcher : @query.QueryDispatcher,
  bodies : @dynamics.RigidBodySet,
  colliders : ColliderSet,
  filter : @query.QueryFilter,
) -> @query.QueryPipeline {
  self |> ignore
  bodies |> ignore
  colliders |> ignore
  @query.QueryPipeline::new(filter, dispatcher)
}
