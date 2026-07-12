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
priv enum EntityReservationStatus {
  Reserved
  Spawned
  Released
}

///|
pub struct EntityReservation {
  priv entity : @core.Entity
  priv world_id : Int
  priv epoch : Int
  priv mut status : EntityReservationStatus
}

///|
pub fn EntityReservation::entity(self : EntityReservation) -> @core.Entity {
  self.entity
}

///|
pub struct AllocatorConnection {
  priv world_id : Int
  priv epoch : Int
  priv mut active : Bool
  priv allocator : @core.EntityAllocator
  priv outstanding : Map[Int, EntityReservation]
}

///|
fn AllocatorConnection::new(world_id : Int, epoch : Int) -> AllocatorConnection {
  {
    world_id,
    epoch,
    active: true,
    allocator: @core.EntityAllocator::new(),
    outstanding: Map([]),
  }
}

///|
pub fn AllocatorConnection::reserve_entity(
  self : AllocatorConnection,
) -> EntityReservation raise EcsError {
  guard self.active else { raise WorldClosed(self.world_id) }
  let entity = self.allocator.alloc()
  let reservation = EntityReservation::{
    entity,
    world_id: self.world_id,
    epoch: self.epoch,
    status: Reserved,
  }
  self.outstanding.set(entity.id, reservation)
  reservation
}

///|
fn AllocatorConnection::claim(
  self : AllocatorConnection,
  reservation : EntityReservation,
) -> @core.Entity raise EcsError {
  guard self.active else { raise WorldClosed(self.world_id) }
  guard reservation.world_id == self.world_id && reservation.epoch == self.epoch else {
    raise ForeignEntityReservation(
      reservation.entity,
      reservation.world_id,
      self.world_id,
    )
  }
  guard reservation.status is Reserved &&
    self.outstanding.contains(reservation.entity.id) else {
    raise StaleEntityReservation(reservation.entity)
  }
  self.outstanding.remove(reservation.entity.id)
  reservation.status = Spawned
  reservation.entity
}

///|
fn AllocatorConnection::free_spawned(
  self : AllocatorConnection,
  entity : @core.Entity,
) -> Unit {
  self.allocator.free(entity)
}

///|
fn AllocatorConnection::pending_count(self : AllocatorConnection) -> Int {
  self.outstanding.length()
}

///|
fn AllocatorConnection::close(self : AllocatorConnection) -> Unit {
  guard self.active else { return }
  self.active = false
  for entry in self.outstanding.iter() {
    let reservation = entry.1
    if reservation.status is Reserved {
      reservation.status = Released
      self.allocator.free(reservation.entity)
    }
  }
  self.outstanding.clear()
}
