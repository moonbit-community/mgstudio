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
struct TestAppMessage {
  value : Int
} derive(Eq, Show)

///|
impl @ecs.Message for TestAppMessage with message() {
  @ecs.register_message(debug_name="tests.app.message_support.test_app_message")
}

///|
let test_message_writer_set : SystemSet = system_set(
  "tests.app.message_support.writer",
)

///|
let test_message_reader_set : SystemSet = system_set(
  "tests.app.message_support.reader",
)

///|
test "app: add_message wires MessageWriter and MessageReader through world queues" {
  let sent = Ref::new(false)
  let seen : Array[Int] = []
  let key : @ecs.MessageKey[TestAppMessage] = @ecs.Message::message()

  let mut app = App::new(@ecs.World::new())
    .add_message(key)
    .add_systems(
      Update,
      system(
        system_param(fn(writer : @ecs.MessageWriter[TestAppMessage]) {
          if !sent.val {
            ignore(writer.write(TestAppMessage::{ value: 7 }))
            sent.val = true
          }
        }),
      ).in_set(test_message_writer_set),
    )
    .add_systems(
      Update,
      system(
        system_param(fn(reader : @ecs.MessageReader[TestAppMessage]) {
          for message in (try! reader.read()) {
            seen.push(message.value)
          }
        }),
      ).in_set(test_message_reader_set),
    )
    .configure_set(Update, test_message_writer_set, before=[
      test_message_reader_set,
    ])

  app = app.run_once()
  app = app.run_once()

  inspect(seen, content="[7]")
}

///|
test "app: on_message consumes unread messages once per condition state" {
  let sent = Ref::new(false)
  let triggered = Ref::new(0)
  let key : @ecs.MessageKey[TestAppMessage] = @ecs.Message::message()

  let mut app = App::new(@ecs.World::new())
    .add_message(key)
    .add_systems(
      Update,
      system(
        system_param(fn(writer : @ecs.MessageWriter[TestAppMessage]) {
          if !sent.val {
            ignore(writer.write(TestAppMessage::{ value: 1 }))
            sent.val = true
          }
        }),
      ).in_set(test_message_writer_set),
    )
    .add_systems(
      Update,
      system(fn(_world : @ecs.World) { triggered.val = triggered.val + 1 })
      .run_if_on_message(key)
      .in_set(test_message_reader_set),
    )
    .configure_set(Update, test_message_writer_set, before=[
      test_message_reader_set,
    ])

  app = app.run_once()
  app = app.run_once()
  app = app.run_once()

  inspect(triggered.val, content="1")
}
