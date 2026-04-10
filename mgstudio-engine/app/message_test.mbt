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
} derive(Eq, Debug)

///|
struct TestCursorAppMessage {
  resend : Bool
  times_sent : Int
} derive(Eq, Debug)

///|
impl @ecs.Message for TestAppMessage with message() {
  @ecs.register_message(debug_name="tests.app.message_support.test_app_message")
}

///|
impl @ecs.Message for TestCursorAppMessage with message() {
  @ecs.register_message(
    debug_name="tests.app.message_support.test_cursor_app_message",
  )
}

///|
struct TestDefaultAppMessage {
  mut value : Int
} derive(Eq, Debug)

///|
impl @ecs.Message for TestDefaultAppMessage with message() {
  @ecs.register_message(
    debug_name="tests.app.message_support.test_default_app_message",
  )
}

///|
pub impl Default for TestDefaultAppMessage with default() {
  { value: 5 }
}

///|
let test_message_writer_set : SystemSet = system_set(
  "tests.app.message_support.writer",
)

///|
let test_message_mutator_set : SystemSet = system_set(
  "tests.app.message_support.mutator",
)

///|
let test_message_reader_set : SystemSet = system_set(
  "tests.app.message_support.reader",
)

///|
let test_message_cursor_set : SystemSet = system_set(
  "tests.app.message_support.cursor",
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

  debug_inspect(seen, content="[7]")
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

  debug_inspect(triggered.val, content="1")
}

///|
test "app: MessageMutator mutates unread messages and MessageWriter write_default works" {
  let sent = Ref::new(false)
  let seen : Array[Int] = []
  let key : @ecs.MessageKey[TestDefaultAppMessage] = @ecs.Message::message()

  let mut app = App::new(@ecs.World::new())
    .add_message(key)
    .add_systems(
      Update,
      system(
        system_param(fn(writer : @ecs.MessageWriter[TestDefaultAppMessage]) {
          if !sent.val {
            ignore(writer.write_default())
            sent.val = true
          }
        }),
      ).in_set(test_message_writer_set),
    )
    .add_systems(
      Update,
      system(
        system_param(fn(mutator : @ecs.MessageMutator[TestDefaultAppMessage]) {
          for message in (try! mutator.read()) {
            message.val.value = message.val.value + 4
          }
        }),
      ).in_set(test_message_mutator_set),
    )
    .add_systems(
      Update,
      system(
        system_param(fn(reader : @ecs.MessageReader[TestDefaultAppMessage]) {
          for message in (try! reader.read()) {
            seen.push(message.value)
          }
        }),
      ).in_set(test_message_reader_set),
    )
    .configure_set(Update, test_message_writer_set, before=[
      test_message_mutator_set,
    ])
    .configure_set(Update, test_message_mutator_set, before=[
      test_message_reader_set,
    ])

  app = app.run_once()
  app = app.run_once()

  debug_inspect(seen, content="[9]")
}

///|
test "app: Messages resource and Local MessageCursor resend unread messages in Bevy order" {
  let frame = Ref::new(0)
  let seen : Array[Int] = []
  let key : @ecs.MessageKey[TestCursorAppMessage] = @ecs.Message::message()

  let mut app = App::new(@ecs.World::new())
    .add_message(key)
    .add_systems(
      Update,
      system(
        system_param(fn(writer : @ecs.MessageWriter[TestCursorAppMessage]) {
          frame.val = frame.val + 1
          ignore(
            writer.write(TestCursorAppMessage::{
              resend: frame.val == 1,
              times_sent: frame.val,
            }),
          )
        }),
      ).in_set(test_message_writer_set),
    )
    .add_systems(
      Update,
      system(
        system_param2(fn(
          cursor : Local[@ecs.MessageCursor[TestCursorAppMessage]],
          messages : ResMut[@ecs.Messages[TestCursorAppMessage]],
        ) {
          for message in (try! cursor.read(messages)) {
            if message.resend {
              ignore(
                messages.write(TestCursorAppMessage::{
                  resend: message.resend,
                  times_sent: message.times_sent + 10,
                }),
              )
            }
          }
        }),
      ).in_set(test_message_cursor_set),
    )
    .add_systems(
      Update,
      system(
        system_param(fn(reader : @ecs.MessageReader[TestCursorAppMessage]) {
          for message in (try! reader.read()) {
            seen.push(message.times_sent)
          }
        }),
      ).in_set(test_message_reader_set),
    )
    .configure_set(Update, test_message_writer_set, before=[
      test_message_cursor_set,
    ])
    .configure_set(Update, test_message_cursor_set, before=[
      test_message_reader_set,
    ])

  app = app.run_once()
  app = app.run_once()

  debug_inspect(seen, content="[1, 11, 2, 21]")
}
