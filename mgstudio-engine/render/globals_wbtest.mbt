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
test "globals: uniform bytes match Bevy std140 layout" {
  let bytes = GlobalsUniform::new(1.0F, 0.5F, 513U).bytes()
  inspect(bytes.length(), content="16")
  inspect(bytes[0].to_int() & 0xFF, content="0")
  inspect(bytes[1].to_int() & 0xFF, content="0")
  inspect(bytes[2].to_int() & 0xFF, content="128")
  inspect(bytes[3].to_int() & 0xFF, content="63")
  inspect(bytes[4].to_int() & 0xFF, content="0")
  inspect(bytes[5].to_int() & 0xFF, content="0")
  inspect(bytes[6].to_int() & 0xFF, content="0")
  inspect(bytes[7].to_int() & 0xFF, content="63")
  inspect(bytes[8].to_int() & 0xFF, content="1")
  inspect(bytes[9].to_int() & 0xFF, content="2")
  inspect(bytes[10].to_int() & 0xFF, content="0")
  inspect(bytes[11].to_int() & 0xFF, content="0")
  inspect(bytes[12].to_int() & 0xFF, content="0")
  inspect(bytes[13].to_int() & 0xFF, content="0")
  inspect(bytes[14].to_int() & 0xFF, content="0")
  inspect(bytes[15].to_int() & 0xFF, content="0")
}

///|
test "globals: init system inserts render-world resource once" {
  let world = @ecs.World::new()
  defer world.close()
  init_globals_buffer(world)
  inspect(
    world.resource(GlobalsBuffer::resource()).is_present(),
    content="true",
  )
  let before = world.get_resource(GlobalsBuffer::resource()).unwrap()
  before.set(GlobalsUniform::new(2.0F, 0.25F, 7U))
  init_globals_buffer(world)
  let after = world.get_resource(GlobalsBuffer::resource()).unwrap()
  inspect(after.value().frame_count(), content="7")
}

///|
test "globals: prepare tolerates missing GPU resources" {
  let world = @ecs.World::new()
  defer world.close()
  prepare_globals_buffer(world)
  inspect(
    world.resource(GlobalsBuffer::resource()).is_present(),
    content="false",
  )
}
