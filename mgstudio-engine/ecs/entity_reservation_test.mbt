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
test "ecs: entity reservations are scoped to an active World lifecycle" {
  let first_world = World::new()
  let second_world = World::new()
  let reservation = try! first_world.reserve_entity()
  debug_inspect(first_world.pending_entity_reservation_count(), content="1")

  let foreign_error : Ref[EcsError?] = Ref(None)
  ignore(second_world.spawn_reserved(reservation)) catch {
    error => foreign_error.val = Some(error)
  }
  debug_inspect(
    foreign_error.val is Some(ForeignEntityReservation(_, _, _)),
    content="true",
  )

  first_world.close()
  debug_inspect(first_world.pending_entity_reservation_count(), content="0")
  let closed_error : Ref[EcsError?] = Ref(None)
  ignore(first_world.reserve_entity()) catch {
    error => closed_error.val = Some(error)
  }
  debug_inspect(closed_error.val is Some(WorldClosed(_)), content="true")
}
