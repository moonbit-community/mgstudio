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
pub struct WorldLease {
  priv world_id : Int
  priv epoch : Int
  priv mut active : Bool
  priv mut world : World?
}

///|
pub fn WorldLease::new(world : World) -> WorldLease {
  {
    world_id: world.world_id(),
    epoch: world.lifecycle_epoch(),
    active: true,
    world: Some(world),
  }
}

///|
pub fn WorldLease::is_active(self : WorldLease) -> Bool {
  self.active && self.world is Some(_)
}

///|
pub fn WorldLease::world(self : WorldLease) -> World? {
  guard self.active && self.world is Some(world) else { return None }
  guard world.is_active() &&
    world.world_id() == self.world_id &&
    world.lifecycle_epoch() == self.epoch else {
    return None
  }
  Some(world)
}

///|
pub fn WorldLease::world_or_abort(self : WorldLease) -> World {
  match self.world() {
    Some(world) => world
    None => abort("system parameter used outside its active World scope")
  }
}

///|
pub fn WorldLease::invalidate(self : WorldLease) -> Unit {
  guard self.active else { return }
  self.active = false
  self.world = None
}
