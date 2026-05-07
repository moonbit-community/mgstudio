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
struct TestCursorMessage {
  resend : Bool
  times_sent : Int
} derive(Eq, Debug)

///|
struct TestParamSetMessage {
  resend : Bool
  times_sent : Int
} derive(Eq, Debug)

///|
impl @ecs.Message for TestCursorMessage with message() {
  @ecs.register_message(debug_name="tests.app.send_and_receive_messages.cursor")
}

///|
impl @ecs.Message for TestParamSetMessage with message() {
  @ecs.register_message(
    debug_name="tests.app.send_and_receive_messages.param_set",
  )
}

///|
let cursor_send_set : SystemSet = system_set(
  "tests.app.send_and_receive_messages.cursor.send",
)

///|
let cursor_receive_set : SystemSet = system_set(
  "tests.app.send_and_receive_messages.cursor.receive",
)

///|
let cursor_observe_set : SystemSet = system_set(
  "tests.app.send_and_receive_messages.cursor.observe",
)

///|
let param_send_set : SystemSet = system_set(
  "tests.app.send_and_receive_messages.param.send",
)

///|
let param_receive_set : SystemSet = system_set(
  "tests.app.send_and_receive_messages.param.receive",
)

///|
let param_observe_set : SystemSet = system_set(
  "tests.app.send_and_receive_messages.param.observe",
)

///|
test "app: Local MessageCursor with ResMut Messages reads unread messages and can resend" {
  let frame = Ref(0)
  let observed : Array[(Bool, Int)] = []
  let key : @ecs.MessageKey[TestCursorMessage] = @ecs.Message::message()

  let mut app = App::new(@ecs.World::new())
    .add_message(key)
    .add_systems(
      Update,
      system(
        system_param(fn(writer : @ecs.MessageWriter[TestCursorMessage]) {
          frame.val = frame.val + 1
          ignore(
            writer.write(TestCursorMessage::{
              resend: frame.val == 1,
              times_sent: frame.val,
            }),
          )
        }),
      ).in_set(cursor_send_set),
    )
    .add_systems(
      Update,
      system(
        system_param2(fn(
          cursor : Local[@ecs.MessageCursor[TestCursorMessage]],
          messages : ResMut[@ecs.Messages[TestCursorMessage]],
        ) {
          for message in (try! cursor.read(messages)) {
            if message.resend {
              ignore(
                messages.write(TestCursorMessage::{
                  resend: message.resend,
                  times_sent: message.times_sent + 10,
                }),
              )
            }
          }
        }),
      ).in_set(cursor_receive_set),
    )
    .add_systems(
      Update,
      system(
        system_param(fn(reader : @ecs.MessageReader[TestCursorMessage]) {
          for message in (try! reader.read()) {
            observed.push((message.resend, message.times_sent))
          }
        }),
      ).in_set(cursor_observe_set),
    )
    .configure_set(Update, cursor_send_set, before=[cursor_receive_set])
    .configure_set(Update, cursor_receive_set, before=[cursor_observe_set])

  app = app.run_once()
  app = app.run_once()

  debug_inspect(
    observed,
    content="[(true, 1), (true, 11), (false, 2), (true, 21)]",
  )
}

///|
test "app: ParamSet2 can read and write the same message type in one system" {
  let sent = Ref(false)
  let observed : Array[Int] = []
  let key : @ecs.MessageKey[TestParamSetMessage] = @ecs.Message::message()

  let mut app = App::new(@ecs.World::new())
    .add_message(key)
    .add_systems(
      Update,
      system(
        system_param(fn(writer : @ecs.MessageWriter[TestParamSetMessage]) {
          if !sent.val {
            ignore(
              writer.write(TestParamSetMessage::{ resend: false, times_sent: 1 }),
            )
            ignore(
              writer.write(TestParamSetMessage::{ resend: true, times_sent: 1 }),
            )
            sent.val = true
          }
        }),
      ).in_set(param_send_set),
    )
    .add_systems(
      Update,
      system(
        system_param(fn(
          param_set : ParamSet2[
            @ecs.MessageReader[TestParamSetMessage],
            @ecs.MessageWriter[TestParamSetMessage],
          ],
        ) {
          let resend : Array[TestParamSetMessage] = []
          for message in (try! param_set.p0().read()) {
            if message.resend {
              resend.push(message)
            }
          }
          for message in resend {
            ignore(
              param_set
              .p1()
              .write(TestParamSetMessage::{
                resend: message.resend,
                times_sent: message.times_sent + 1,
              }),
            )
          }
        }),
      ).in_set(param_receive_set),
    )
    .add_systems(
      Update,
      system(
        system_param(fn(reader : @ecs.MessageReader[TestParamSetMessage]) {
          for message in (try! reader.read()) {
            observed.push(message.times_sent)
          }
        }),
      ).in_set(param_observe_set),
    )
    .configure_set(Update, param_send_set, before=[param_receive_set])
    .configure_set(Update, param_receive_set, before=[param_observe_set])

  app = app.run_once()
  app = app.run_once()

  debug_inspect(observed, content="[1, 1, 2, 3]")
}
