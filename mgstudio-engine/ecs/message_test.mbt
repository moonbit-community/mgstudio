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
struct TestRuntimeMessage {
  mut value : Int
} derive(Eq, Debug)

///|
impl Message for TestRuntimeMessage with message() {
  register_message(debug_name="tests.ecs.message.runtime")
}

///|
struct TestDefaultRuntimeMessage {
  value : Int
} derive(Eq, Debug)

///|
impl Message for TestDefaultRuntimeMessage with message() {
  register_message(debug_name="tests.ecs.message.default")
}

///|
pub impl Default for TestDefaultRuntimeMessage with default() {
  { value: 42 }
}

///|
test "ecs message: mutator reads unread messages as in-place refs" {
  let world = World::new()
  let key : MessageKey[TestRuntimeMessage] = Message::message()
  world.init_message(key)

  let writer = world.message_writer(key)
  ignore(writer.write({ value: 1 }))
  ignore(writer.write({ value: 2 }))

  let cursor = Ref(0)
  let mutator = world.message_mutator(key, cursor)
  let unread = try! mutator.read()
  debug_inspect(unread.length(), content="2")
  unread[0].value = unread[0].value + 9
  unread[1].value = unread[1].value + 18
  debug_inspect(mutator.is_empty(), content="true")

  let reader = world.message_reader(key, Ref(0))
  let messages = try! reader.read()
  debug_inspect(messages[0].value, content="10")
  debug_inspect(messages[1].value, content="20")
}

///|
test "ecs message: writer write_default sends default message" {
  let world = World::new()
  let key : MessageKey[TestDefaultRuntimeMessage] = Message::message()
  world.init_message(key)

  let writer = world.message_writer(key)
  ignore(writer.write_default())

  let reader = world.message_reader(key, Ref(0))
  let messages = try! reader.read()
  debug_inspect(messages.length(), content="1")
  debug_inspect(messages[0].value, content="42")
}
