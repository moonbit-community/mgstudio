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
/// Physics2D event types (engine-facing).

///|
pub enum CollisionEvent2d {
  Started(@core.Entity, @core.Entity, Bool)
  Stopped(@core.Entity, @core.Entity, Bool)
}

///|
pub struct ContactForceEvent2d {
  entity1 : @core.Entity
  entity2 : @core.Entity
  total_force : @math.Vec2
  total_force_magnitude : Float
  max_force_direction : @math.Vec2
  max_force_magnitude : Float
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct Physics2dEvents {
  mut collisions : Array[CollisionEvent2d]
  mut contact_forces : Array[ContactForceEvent2d]
}

///|
pub fn Physics2dEvents::new() -> Physics2dEvents {
  { collisions: [], contact_forces: [] }
}

///|
pub fn Physics2dEvents::clear(self : Physics2dEvents) -> Unit {
  self.collisions.clear()
  self.contact_forces.clear()
}
