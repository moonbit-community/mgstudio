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
pub struct RigidBodyHandle {
  id : Int
  generation : Int
}

///|
fn RigidBodyHandle::new(id : Int, generation : Int) -> RigidBodyHandle {
  RigidBodyHandle::{ id, generation }
}

///|
pub fn RigidBodyHandle::equals(self : RigidBodyHandle, other : RigidBodyHandle) -> Bool {
  self.id == other.id && self.generation == other.generation
}

///|
pub struct RigidBodyPosition {
  mut position : @core.Isometry2
  mut next_position : @core.Isometry2
}

///|
pub fn RigidBodyPosition::new(
  position : @core.Isometry2,
  next_position : @core.Isometry2,
) -> RigidBodyPosition {
  { position, next_position }
}

///|
pub fn RigidBodyPosition::interpolate_velocity(
  self : RigidBodyPosition,
  inv_dt : @core.Real,
  local_com : @core.Vec2,
) -> RigidBodyVelocity {
  let com = self.position.transform_point(local_com)
  let shift = @core.Isometry2::from_translation(com)
  let dpos = shift.inverse().mul(self.next_position).mul(self.position.inverse()).mul(shift)
  let angular = dpos.rotation.angle()
  let linear = dpos.translation
  RigidBodyVelocity::{
    linvel: @core.Vec2::new(linear.x * inv_dt, linear.y * inv_dt),
    angvel: angular * inv_dt,
  }
}

///|
pub struct RigidBodyVelocity {
  linvel : @core.Vec2
  angvel : @core.Real
}

///|
pub fn RigidBodyVelocity::integrate(
  self : RigidBodyVelocity,
  dt : @core.Real,
  curr_pos : @core.Isometry2,
  local_com : @core.Vec2,
) -> @core.Isometry2 {
  let com = curr_pos.transform_point(local_com)
  let shift = @core.Isometry2::from_translation(
    @core.Vec2::new(-com.x, -com.y),
  )
  let rot = @core.Isometry2::new(
    @core.Vec2::zero(),
    @core.Rot2::from_angle(self.angvel * dt),
  )
  let translation = @core.Vec2::new(self.linvel.x * dt, self.linvel.y * dt)
  let unshift = @core.Isometry2::from_translation(com.add(translation))
  unshift.mul(rot).mul(shift).mul(curr_pos)
}

///|
pub struct RigidBody {
  position : RigidBodyPosition
  mut body_type : RigidBodyType
  mut enabled : Bool
  can_sleep : Bool
  mut sleeping : Bool
  additional_mass : @core.Real
}

///|
fn RigidBody::is_dynamic_or_kinematic(self : RigidBody) -> Bool {
  match self.body_type {
    RigidBodyType::Fixed => false
    _ => true
  }
}

///|
pub fn RigidBody::set_body_type(
  self : RigidBody,
  body_type : RigidBodyType,
  wake_up : Bool,
) -> RigidBody {
  self.body_type = body_type
  if wake_up && self.is_dynamic_or_kinematic() {
    self.sleeping = false
  }
  self
}

///|
pub fn RigidBody::is_sleeping(self : RigidBody) -> Bool {
  self.sleeping
}

///|
pub fn RigidBody::translation(self : RigidBody) -> @core.Vec2 {
  self.position.position.translation
}

///|
pub fn RigidBody::rotation(self : RigidBody) -> @core.Rot2 {
  self.position.position.rotation
}

///|
pub fn RigidBody::set_translation(
  self : RigidBody,
  translation : @core.Vec2,
  wake_up : Bool,
) -> RigidBody {
  let curr_rot = self.position.position.rotation
  let next_rot = self.position.next_position.rotation
  self.position.position = @core.Isometry2::new(translation, curr_rot)
  self.position.next_position = @core.Isometry2::new(translation, next_rot)
  if wake_up && self.is_dynamic_or_kinematic() {
    self.sleeping = false
  }
  self
}

///|
pub fn RigidBody::set_rotation(
  self : RigidBody,
  rotation : @core.Rot2,
  wake_up : Bool,
) -> RigidBody {
  let curr_translation = self.position.position.translation
  let next_translation = self.position.next_position.translation
  self.position.position = @core.Isometry2::new(curr_translation, rotation)
  self.position.next_position = @core.Isometry2::new(next_translation, rotation)
  if wake_up && self.is_dynamic_or_kinematic() {
    self.sleeping = false
  }
  self
}

///|
pub fn RigidBody::set_enabled(self : RigidBody, enabled : Bool) -> RigidBody {
  self.enabled = enabled
  self
}

///|
pub fn RigidBody::position(self : RigidBody) -> @core.Isometry2 {
  self.position.position
}

///|
pub fn RigidBody::set_next_kinematic_translation(
  self : RigidBody,
  translation : @core.Vec2,
) -> RigidBody {
  if self.body_type is RigidBodyType::KinematicPositionBased {
    let next_rot = self.position.next_position.rotation
    self.position.next_position = @core.Isometry2::new(translation, next_rot)
    if !vec2_equal(self.position.position.translation, translation) {
      self.sleeping = false
    }
  }
  self
}

///|
pub struct RigidBodyBuilder {
  mut position : @core.Isometry2
  body_type : RigidBodyType
  mut additional_mass : @core.Real
  mut can_sleep : Bool
}

///|
fn RigidBodyBuilder::new(body_type : RigidBodyType) -> RigidBodyBuilder {
  {
    position: @core.Isometry2::identity(),
    body_type,
    additional_mass: 0.0F,
    can_sleep: true,
  }
}

///|
pub fn RigidBodyBuilder::dynamic() -> RigidBodyBuilder {
  RigidBodyBuilder::new(RigidBodyType::Dynamic)
}

///|
pub fn RigidBodyBuilder::fixed() -> RigidBodyBuilder {
  RigidBodyBuilder::new(RigidBodyType::Fixed)
}

///|
pub fn RigidBodyBuilder::kinematic_position_based() -> RigidBodyBuilder {
  RigidBodyBuilder::new(RigidBodyType::KinematicPositionBased)
}

///|
pub fn RigidBodyBuilder::translation(
  self : RigidBodyBuilder,
  translation : @core.Vec2,
) -> RigidBodyBuilder {
  let rot = self.position.rotation
  self.position = @core.Isometry2::new(translation, rot)
  self
}

///|
pub fn RigidBodyBuilder::additional_mass(
  self : RigidBodyBuilder,
  mass : @core.Real,
) -> RigidBodyBuilder {
  self.additional_mass = mass
  self
}

///|
pub fn RigidBodyBuilder::can_sleep(
  self : RigidBodyBuilder,
  can_sleep : Bool,
) -> RigidBodyBuilder {
  self.can_sleep = can_sleep
  self
}

///|
pub fn RigidBodyBuilder::build(self : RigidBodyBuilder) -> RigidBody {
  let pos = RigidBodyPosition::new(self.position, self.position)
  {
    position: pos,
    body_type: self.body_type,
    enabled: true,
    can_sleep: self.can_sleep,
    sleeping: false,
    additional_mass: self.additional_mass,
  }
}

///|
pub struct RigidBodySet {
  bodies : Array[RigidBody?]
  generations : Array[Int]
  free_list : Array[Int]
}

///|
pub fn RigidBodySet::new() -> RigidBodySet {
  { bodies: [], generations: [], free_list: [] }
}

///|
pub fn RigidBodySet::insert(self : RigidBodySet, body : RigidBody) -> RigidBodyHandle {
  if self.free_list.pop() is Some(index) {
    self.bodies[index] = Some(body)
    let generation = self.generations[index]
    RigidBodyHandle::new(index, generation)
  } else {
    let index = self.bodies.length()
    self.bodies.push(Some(body))
    self.generations.push(0)
    RigidBodyHandle::new(index, 0)
  }
}

///|
pub fn RigidBodySet::get(self : RigidBodySet, handle : RigidBodyHandle) -> RigidBody? {
  if handle.id < 0 || handle.id >= self.bodies.length() {
    return None
  }
  if self.generations[handle.id] != handle.generation {
    return None
  }
  self.bodies[handle.id]
}

///|
pub fn RigidBodySet::get_mut(self : RigidBodySet, handle : RigidBodyHandle) -> RigidBody? {
  self.get(handle)
}

///|
pub fn RigidBodySet::remove(
  self : RigidBodySet,
  handle : RigidBodyHandle,
  islands : IslandManager,
  colliders : Unit,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
  wake_up : Bool,
) -> Unit {
  if handle.id < 0 || handle.id >= self.bodies.length() {
    islands |> ignore
    colliders |> ignore
    impulse_joints |> ignore
    multibody_joints |> ignore
    wake_up |> ignore
    return
  }
  if self.generations[handle.id] != handle.generation {
    islands |> ignore
    colliders |> ignore
    impulse_joints |> ignore
    multibody_joints |> ignore
    wake_up |> ignore
    return
  }
  if self.bodies[handle.id] is Some(_) {
    self.bodies[handle.id] = None
    self.generations[handle.id] = self.generations[handle.id] + 1
    self.free_list.push(handle.id)
  }
  islands |> ignore
  colliders |> ignore
  impulse_joints |> ignore
  multibody_joints |> ignore
  wake_up |> ignore
}

///|
fn body_type_to_int(body_type : RigidBodyType) -> Int {
  match body_type {
    RigidBodyType::Dynamic => 0
    RigidBodyType::Fixed => 1
    RigidBodyType::KinematicPositionBased => 2
  }
}

///|
fn body_type_from_int(value : Int) -> RigidBodyType {
  if value == 1 {
    RigidBodyType::Fixed
  } else if value == 2 {
    RigidBodyType::KinematicPositionBased
  } else {
    RigidBodyType::Dynamic
  }
}

///|
fn split_values(text : String, sep : String) -> Array[String] {
  let values : Array[String] = []
  for part in text.split(sep[:]) {
    let value = part.to_string()
    if value.length() > 0 {
      values.push(value)
    }
  }
  values
}

///|
fn parse_int_value(text : String) -> Int {
  let result : Result[Int, @strconv.StrConvError] = try? @strconv.parse_int(text[:], base=10)
  if result is Ok(value) {
    value
  } else {
    0
  }
}

///|
fn parse_real_value(text : String) -> @core.Real {
  let result : Result[Double, @strconv.StrConvError] = try? @strconv.parse_double(text[:])
  if result is Ok(value) {
    Float::from_double(value)
  } else {
    0.0F
  }
}

///|
fn parse_bool_value(text : String) -> Bool {
  text == "1"
}

///|
fn vec2_equal(left : @core.Vec2, right : @core.Vec2) -> Bool {
  left.x == right.x && left.y == right.y
}

///|
pub fn RigidBodySet::serialize(self : RigidBodySet) -> String {
  let sb = StringBuilder::new()
  sb.write_string("len=")
  sb.write_object(self.bodies.length())
  sb.write_char(';')
  sb.write_string("gens=")
  for i in 0..<self.generations.length() {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_object(self.generations[i])
  }
  sb.write_char(';')
  sb.write_string("free=")
  for i in 0..<self.free_list.length() {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_object(self.free_list[i])
  }
  sb.write_char(';')
  sb.write_string("bodies=")
  for i in 0..<self.bodies.length() {
    if i > 0 {
      sb.write_char('|')
    }
    if self.bodies[i] is Some(body) {
      let pos = body.position.position
      let next_pos = body.position.next_position
      sb.write_string("B,")
      sb.write_object(body_type_to_int(body.body_type))
      sb.write_char(',')
      sb.write_object(pos.translation.x)
      sb.write_char(',')
      sb.write_object(pos.translation.y)
      sb.write_char(',')
      sb.write_object(pos.rotation.angle())
      sb.write_char(',')
      sb.write_object(next_pos.translation.x)
      sb.write_char(',')
      sb.write_object(next_pos.translation.y)
      sb.write_char(',')
      sb.write_object(next_pos.rotation.angle())
      sb.write_char(',')
      sb.write_object(if body.enabled { 1 } else { 0 })
      sb.write_char(',')
      sb.write_object(if body.can_sleep { 1 } else { 0 })
      sb.write_char(',')
      sb.write_object(if body.sleeping { 1 } else { 0 })
      sb.write_char(',')
      sb.write_object(body.additional_mass)
    } else {
      sb.write_char('N')
    }
  }
  sb.to_string()
}

///|
pub fn RigidBodySet::deserialize(data : String) -> RigidBodySet {
  let mut len = 0
  let generations : Array[Int] = []
  let free_list : Array[Int] = []
  let bodies : Array[RigidBody?] = []

  for part in data.split(";"[:]) {
    let value = part.to_string()
    if value.starts_with("len="[:]) {
      let raw = value.substring(start=4)
      len = parse_int_value(raw)
    } else if value.starts_with("gens="[:]) {
      let raw = value.substring(start=5)
      let items = split_values(raw, ",")
      for item in items {
        generations.push(parse_int_value(item))
      }
    } else if value.starts_with("free="[:]) {
      let raw = value.substring(start=5)
      let items = split_values(raw, ",")
      for item in items {
        free_list.push(parse_int_value(item))
      }
    } else if value.starts_with("bodies="[:]) {
      let raw = value.substring(start=7)
      let entries = split_values(raw, "|")
      for entry in entries {
        if entry == "N" {
          bodies.push(None)
        } else if entry.starts_with("B,"[:]) {
          let fields = split_values(entry.substring(start=2), ",")
          let body_type = body_type_from_int(
            if fields.length() > 0 { parse_int_value(fields[0]) } else { 0 },
          )
          let tx = if fields.length() > 1 { parse_real_value(fields[1]) } else { 0.0F }
          let ty = if fields.length() > 2 { parse_real_value(fields[2]) } else { 0.0F }
          let rot = if fields.length() > 3 { parse_real_value(fields[3]) } else { 0.0F }
          let ntx = if fields.length() > 4 { parse_real_value(fields[4]) } else { tx }
          let nty = if fields.length() > 5 { parse_real_value(fields[5]) } else { ty }
          let nrot = if fields.length() > 6 { parse_real_value(fields[6]) } else { rot }
          let enabled = if fields.length() > 7 { parse_bool_value(fields[7]) } else { true }
          let can_sleep = if fields.length() > 8 { parse_bool_value(fields[8]) } else { true }
          let sleeping = if fields.length() > 9 { parse_bool_value(fields[9]) } else { false }
          let additional_mass = if fields.length() > 10 {
            parse_real_value(fields[10])
          } else {
            0.0F
          }
          let position = @core.Isometry2::new(
            @core.Vec2::new(tx, ty),
            @core.Rot2::from_angle(rot),
          )
          let next_position = @core.Isometry2::new(
            @core.Vec2::new(ntx, nty),
            @core.Rot2::from_angle(nrot),
          )
          let rb_pos = RigidBodyPosition::new(position, next_position)
          let body : RigidBody = {
            position: rb_pos,
            body_type,
            enabled,
            can_sleep,
            sleeping,
            additional_mass,
          }
          bodies.push(Some(body))
        } else {
          bodies.push(None)
        }
      }
    }
  }

  while generations.length() < len {
    generations.push(0)
  }
  while bodies.length() < len {
    bodies.push(None)
  }

  { bodies, generations, free_list }
}
