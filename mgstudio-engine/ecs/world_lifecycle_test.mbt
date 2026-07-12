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
test "ecs: closing a World is idempotent" {
  let world = World::new()
  debug_inspect(world.is_closed(), content="false")
  debug_inspect(world.lifecycle_epoch(), content="0")

  world.close()
  debug_inspect(world.is_closed(), content="true")
  debug_inspect(world.lifecycle_epoch(), content="1")

  world.close()
  debug_inspect(world.is_closed(), content="true")
  debug_inspect(world.lifecycle_epoch(), content="1")
}

///|
test "ecs: World close rejects reentry while finalizers run" {
  let world_ref : Ref[World?] = Ref(None)
  let finalizer_count : Ref[Int] = Ref(0)
  let key = register_resource(debug_name="tests.ecs.close_reentry", finalizer=fn(
    _value : Unit,
  ) {
    finalizer_count.val = finalizer_count.val + 1
    match world_ref.val {
      Some(world) => world.close()
      None => ()
    }
  })
  let world = World::new()
  world_ref.val = Some(world)
  world.insert_resource(key, ())

  world.close()
  debug_inspect(finalizer_count.val, content="1")
  debug_inspect(world.is_closed(), content="true")
  debug_inspect(world.lifecycle_epoch(), content="1")
}

///|
test "ecs: a closed World rejects raw entity mutation" {
  let world = World::new()
  world.close()
  let mutation_error : Ref[EcsError?] = Ref(None)
  ignore(world.spawn_empty_at(@core.Entity::new(99, 1))) catch {
    error => mutation_error.val = Some(error)
  }
  debug_inspect(mutation_error.val is Some(WorldClosed(_)), content="true")
}
