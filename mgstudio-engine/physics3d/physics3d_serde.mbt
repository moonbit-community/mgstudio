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
const ACTIVE_COLLISION_TYPES_ALL_BITS : Int = 0xEE2F

///|
fn rigid_body_type_to_json(body_type : @dynamics.RigidBodyType) -> Json {
  match body_type {
    @dynamics.RigidBodyType::Dynamic => "dynamic".to_json()
    @dynamics.RigidBodyType::Fixed => "fixed".to_json()
    @dynamics.RigidBodyType::KinematicPositionBased =>
      "kinematic_position_based".to_json()
    @dynamics.RigidBodyType::KinematicVelocityBased =>
      "kinematic_velocity_based".to_json()
  }
}

///|
fn rigid_body_type_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.RigidBodyType raise @json.JsonDecodeError {
  let tag : String = @json.from_json(json, path~)
  if tag == "fixed" {
    @dynamics.RigidBodyType::Fixed
  } else if tag == "kinematic_position_based" {
    @dynamics.RigidBodyType::KinematicPositionBased
  } else if tag == "kinematic_velocity_based" {
    @dynamics.RigidBodyType::KinematicVelocityBased
  } else {
    @dynamics.RigidBodyType::Dynamic
  }
}

///|
fn active_collision_types_to_json(
  types : @collision.ActiveCollisionTypes,
) -> Json {
  types.value.to_json()
}

///|
fn active_collision_types_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ActiveCollisionTypes raise @json.JsonDecodeError {
  let bits : Int = @json.from_json(json, path~)
  if bits == ACTIVE_COLLISION_TYPES_ALL_BITS {
    @collision.ActiveCollisionTypes::all()
  } else {
    @collision.ActiveCollisionTypes::default()
  }
}

///|
fn active_events_to_json(events : @collision.ActiveEvents) -> Json {
  let mut bits = 0
  if events.contains(@collision.ActiveEvents::collision_events()) {
    bits = bits | (1 << 0)
  }
  if events.contains(@collision.ActiveEvents::contact_force_events()) {
    bits = bits | (1 << 1)
  }
  if events.contains(@collision.ActiveEvents::intersection_events()) {
    bits = bits | (1 << 2)
  }
  bits.to_json()
}

///|
fn active_events_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ActiveEvents raise @json.JsonDecodeError {
  let bits : Int = @json.from_json(json, path~)
  @collision.ActiveEvents::from_bits_retain(bits)
}

///|
fn active_hooks_to_json(hooks : @collision.ActiveHooks) -> Json {
  let mut bits = 0
  if hooks.contains(@collision.ActiveHooks::filter_contact_pairs()) {
    bits = bits | (1 << 0)
  }
  if hooks.contains(@collision.ActiveHooks::filter_intersection_pair()) {
    bits = bits | (1 << 1)
  }
  if hooks.contains(@collision.ActiveHooks::modify_solver_contacts()) {
    bits = bits | (1 << 2)
  }
  bits.to_json()
}

///|
fn active_hooks_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ActiveHooks raise @json.JsonDecodeError {
  let bits : Int = @json.from_json(json, path~)
  @collision.ActiveHooks::from_bits_retain(bits)
}

///|
fn rigid_body_handle_to_json(handle : @dynamics.RigidBodyHandle) -> Json {
  handle.into_raw_parts().to_json()
}

///|
fn rigid_body_handle_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.RigidBodyHandle raise @json.JsonDecodeError {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  @dynamics.RigidBodyHandle::from_raw_parts(id, generation)
}

///|
fn collider_handle3d_to_json(handle : @collision.ColliderHandle3D) -> Json {
  handle.into_raw_parts().to_json()
}

///|
fn collider_handle3d_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ColliderHandle3D raise @json.JsonDecodeError {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  @collision.ColliderHandle3D::from_raw_parts(id, generation)
}

///|
pub impl ToJson for RigidBody3d with to_json(self) {
  rigid_body_type_to_json(self.body_type)
}

///|
pub impl @json.FromJson for RigidBody3d with from_json(json, path) {
  RigidBody3d::{ body_type: rigid_body_type_from_json(json, path) }
}

///|
pub impl ToJson for ColliderShape3d with to_json(self) {
  match self {
    Ball(radius) => ("Ball", radius).to_json()
    Cuboid(hx, hy, hz) => ("Cuboid", (hx, hy, hz)).to_json()
    CapsuleX(half_height, radius) =>
      ("CapsuleX", (half_height, radius)).to_json()
    CapsuleY(half_height, radius) =>
      ("CapsuleY", (half_height, radius)).to_json()
    CapsuleZ(half_height, radius) =>
      ("CapsuleZ", (half_height, radius)).to_json()
    Cylinder(half_height, radius) =>
      ("Cylinder", (half_height, radius)).to_json()
    Cone(half_height, radius) => ("Cone", (half_height, radius)).to_json()
    HalfSpace(normal) => ("HalfSpace", normal).to_json()
    Triangle(a, b, c) => ("Triangle", (a, b, c)).to_json()
    TriMesh(vertices, indices) => ("TriMesh", (vertices, indices)).to_json()
    ConvexHull(vertices) => ("ConvexHull", vertices).to_json()
    Compound(parts) => ("Compound", parts).to_json()
    Heightfield(heights, nrows, ncols, scale) =>
      ("Heightfield", (heights, nrows, ncols, scale)).to_json()
    Raw(_shape) => ("RawUnsupported", ().to_json()).to_json()
  }
}

///|
pub impl @json.FromJson for ColliderShape3d with from_json(json, path) {
  let (tag, payload) : (String, Json) = @json.from_json(json, path~)
  match tag {
    "Ball" => {
      let radius : Float = @json.from_json(payload, path~)
      ColliderShape3d::ball(radius)
    }
    "Cuboid" => {
      let (hx, hy, hz) : (Float, Float, Float) = @json.from_json(payload, path~)
      ColliderShape3d::cuboid(hx, hy, hz)
    }
    "CapsuleX" => {
      let (half_height, radius) : (Float, Float) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::capsule_x(half_height, radius)
    }
    "CapsuleY" => {
      let (half_height, radius) : (Float, Float) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::capsule_y(half_height, radius)
    }
    "CapsuleZ" => {
      let (half_height, radius) : (Float, Float) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::capsule_z(half_height, radius)
    }
    "Cylinder" => {
      let (half_height, radius) : (Float, Float) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::cylinder(half_height, radius)
    }
    "Cone" => {
      let (half_height, radius) : (Float, Float) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::cone(half_height, radius)
    }
    "HalfSpace" => {
      let normal : @math.Vec3 = @json.from_json(payload, path~)
      ColliderShape3d::halfspace(normal)
    }
    "Triangle" => {
      let (a, b, c) : (@math.Vec3, @math.Vec3, @math.Vec3) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::triangle(a, b, c)
    }
    "TriMesh" => {
      let (vertices, indices) : (Array[@math.Vec3], Array[(Int, Int, Int)]) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::trimesh(vertices, indices)
    }
    "ConvexHull" => {
      let vertices : Array[@math.Vec3] = @json.from_json(payload, path~)
      ColliderShape3d::convex_hull(vertices)
    }
    "Compound" => {
      let parts : Array[(@transform.Transform, ColliderShape3d)] = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::compound(parts)
    }
    "Heightfield" => {
      let (heights, nrows, ncols, scale) : (Array[Float], Int, Int, @math.Vec3) = @json.from_json(
        payload,
        path~,
      )
      ColliderShape3d::heightfield(heights, nrows, ncols, scale)
    }
    _ => ColliderShape3d::ball(0.5F)
  }
}

///|
pub impl ToJson for Collider3d with to_json(self) {
  (self.shape, self.sensor).to_json()
}

///|
pub impl @json.FromJson for Collider3d with from_json(json, path) {
  let (shape, sensor) : (ColliderShape3d, Bool) = @json.from_json(json, path~)
  Collider3d::{ shape, sensor }
}

///|
pub impl ToJson for ActiveEvents3d with to_json(self) {
  active_events_to_json(self.events)
}

///|
pub impl @json.FromJson for ActiveEvents3d with from_json(json, path) {
  ActiveEvents3d::{ events: active_events_from_json(json, path) }
}

///|
pub impl ToJson for ContactForceEventThreshold3d with to_json(self) {
  self.threshold.to_json()
}

///|
pub impl @json.FromJson for ContactForceEventThreshold3d with from_json(
  json,
  path,
) {
  ContactForceEventThreshold3d::{ threshold: @json.from_json(json, path~) }
}

///|
pub impl ToJson for ActiveCollisionTypes3d with to_json(self) {
  active_collision_types_to_json(self.types)
}

///|
pub impl @json.FromJson for ActiveCollisionTypes3d with from_json(json, path) {
  ActiveCollisionTypes3d::{
    types: active_collision_types_from_json(json, path),
  }
}

///|
pub impl ToJson for ActiveHooks3d with to_json(self) {
  active_hooks_to_json(self.hooks)
}

///|
pub impl @json.FromJson for ActiveHooks3d with from_json(json, path) {
  ActiveHooks3d::{ hooks: active_hooks_from_json(json, path) }
}

///|
pub impl ToJson for Velocity3d with to_json(self) {
  (self.linvel, self.angvel).to_json()
}

///|
pub impl @json.FromJson for Velocity3d with from_json(json, path) {
  let (linvel, angvel) : (@math.Vec3, @math.Vec3) = @json.from_json(json, path~)
  Velocity3d::{ linvel, angvel }
}

///|
pub impl ToJson for RapierBodyHandle3d with to_json(self) {
  rigid_body_handle_to_json(self.handle)
}

///|
pub impl @json.FromJson for RapierBodyHandle3d with from_json(json, path) {
  RapierBodyHandle3d::{ handle: rigid_body_handle_from_json(json, path) }
}

///|
pub impl ToJson for RapierColliderHandle3d with to_json(self) {
  collider_handle3d_to_json(self.handle)
}

///|
pub impl @json.FromJson for RapierColliderHandle3d with from_json(json, path) {
  RapierColliderHandle3d::{ handle: collider_handle3d_from_json(json, path) }
}

///|
let physics3d_config_serde_next_id : Ref[Int] = Ref::new(1)

///|
let physics3d_config_serde_values : Map[Int, Physics3dConfig] = {}

///|
pub impl ToJson for Physics3dConfig with to_json(self) {
  let id = physics3d_config_serde_next_id.val
  physics3d_config_serde_next_id.val = id + 1
  physics3d_config_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for Physics3dConfig with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  physics3d_config_serde_values.get(id).unwrap_or(Physics3dConfig::default())
}

///|
let physics3d_events_serde_next_id : Ref[Int] = Ref::new(1)

///|
let physics3d_events_serde_values : Map[Int, Physics3dEvents] = {}

///|
pub impl ToJson for Physics3dEvents with to_json(self) {
  let id = physics3d_events_serde_next_id.val
  physics3d_events_serde_next_id.val = id + 1
  physics3d_events_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for Physics3dEvents with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  physics3d_events_serde_values.get(id).unwrap_or(Physics3dEvents::new())
}

///|
let physics3d_context_serde_next_id : Ref[Int] = Ref::new(1)

///|
let physics3d_context_serde_values : Map[Int, Physics3dContext] = {}

///|
pub impl ToJson for Physics3dContext with to_json(self) {
  let id = physics3d_context_serde_next_id.val
  physics3d_context_serde_next_id.val = id + 1
  physics3d_context_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for Physics3dContext with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  physics3d_context_serde_values.get(id).unwrap_or(Physics3dContext::new())
}
