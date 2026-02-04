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
/// Physics3D event types (engine-facing).

///|
pub enum CollisionEvent3d {
  Started(@core.Entity, @core.Entity, Bool)
  Stopped(@core.Entity, @core.Entity, Bool)
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct Physics3dEvents {
  mut collisions : Array[CollisionEvent3d]
}

///|
pub fn Physics3dEvents::new() -> Physics3dEvents {
  { collisions: [] }
}

///|
pub fn Physics3dEvents::clear(self : Physics3dEvents) -> Unit {
  self.collisions.clear()
}
