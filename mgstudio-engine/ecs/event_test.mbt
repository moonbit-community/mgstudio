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
struct RuntimeEvent {
  value : Int
} derive(Eq, Show, ToJson, FromJson)

///|
struct BrokenEvent {
  value : String
} derive(Eq, Show, ToJson, FromJson)

///|
test "ecs event: read includes previous and current frame" {
  let world = World::new()
  let event_runtime : EventKey[RuntimeEvent] = register_event(
    debug_name="runtime_event",
  )

  world.send_event(event_runtime, RuntimeEvent::{ value: 1 })
  inspect(try! world.read_events(event_runtime), content="[{value: 1}]")

  world.advance_event_frame()
  inspect(try! world.read_events(event_runtime), content="[{value: 1}]")

  world.send_event(event_runtime, RuntimeEvent::{ value: 2 })
  inspect(
    try! world.read_events(event_runtime),
    content="[{value: 1}, {value: 2}]",
  )

  world.advance_event_frame()
  inspect(try! world.read_events(event_runtime), content="[{value: 2}]")

  world.advance_event_frame()
  inspect(try! world.read_events(event_runtime), content="[]")
}

///|
test "ecs event: clear removes both previous and current queues" {
  let world = World::new()
  let event_runtime : EventKey[RuntimeEvent] = register_event(
    debug_name="runtime_event_clear",
  )

  world.send_event(event_runtime, RuntimeEvent::{ value: 1 })
  world.advance_event_frame()
  world.send_event(event_runtime, RuntimeEvent::{ value: 2 })
  world.clear_events(event_runtime)

  inspect(try! world.read_events(event_runtime), content="[]")
}

///|
test "ecs event: decode diagnostics fail fast" {
  let world = World::new()
  let event_runtime : EventKey[RuntimeEvent] = register_event(
    debug_name="runtime_event_decode",
  )
  let event_broken : EventKey[BrokenEvent] = event_runtime.cast()

  world.send_event(event_runtime, RuntimeEvent::{ value: 9 })

  let result : Result[Array[BrokenEvent], EcsError] = try? world.read_events(
    event_broken,
  )
  guard result is Err(EventDecodeFailed(key_id, _debug_name, index, _)) else {
    fail("expected event decode diagnostics")
  }
  inspect(key_id == event_runtime.id(), content="true")
  inspect(index == 0, content="true")
}
