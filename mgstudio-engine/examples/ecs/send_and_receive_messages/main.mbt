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

///|
struct A {}

///|
struct B {}

///|
struct DebugMessage {
  resend_from_param_set : Bool
  resend_from_local_message_reader : Bool
  times_sent : Int
} derive(Show)

///|
let a_key : @ecs.MessageKey[A] = @ecs.register_message(
  debug_name="examples.ecs.send_and_receive_messages.A",
)

///|
let b_key : @ecs.MessageKey[B] = @ecs.register_message(
  debug_name="examples.ecs.send_and_receive_messages.B",
)

///|
let debug_message_key : @ecs.MessageKey[DebugMessage] = @ecs.register_message(
  debug_name="examples.ecs.send_and_receive_messages.DebugMessage",
)

///|
pub impl @ecs.Message for A with message() {
  a_key
}

///|
pub impl @ecs.Message for B with message() {
  b_key
}

///|
pub impl @ecs.Message for DebugMessage with message() {
  debug_message_key
}

///|
let send_messages_set : @app.SystemSet = @app.system_set(
  "examples.ecs.send_and_receive_messages.send_messages",
)

///|
let debug_messages_before_param_set : @app.SystemSet = @app.system_set(
  "examples.ecs.send_and_receive_messages.debug_messages_before_param_set",
)

///|
let send_and_receive_param_set_set : @app.SystemSet = @app.system_set(
  "examples.ecs.send_and_receive_messages.param_set",
)

///|
let debug_messages_before_local_cursor_set : @app.SystemSet = @app.system_set(
  "examples.ecs.send_and_receive_messages.debug_messages_before_local_cursor",
)

///|
let send_and_receive_manual_reader_set : @app.SystemSet = @app.system_set(
  "examples.ecs.send_and_receive_messages.local_cursor",
)

///|
let debug_messages_after_local_cursor_set : @app.SystemSet = @app.system_set(
  "examples.ecs.send_and_receive_messages.debug_messages_after_local_cursor",
)

///|
fn read_and_write_different_message_types(
  a : @ecs.MessageWriter[A],
  b : @ecs.MessageReader[B],
) -> Unit {
  for _ in (try! b.read()) {

  }
  ignore(a.write(A::{  }))
}

///|
fn send_messages(
  debug_messages : @ecs.MessageWriter[DebugMessage],
  frame_count : @app.Res[@diagnostic.FrameCount],
) -> Unit {
  println("Sending messages for frame \{frame_count.get().value}")

  ignore(
    debug_messages.write(DebugMessage::{
      resend_from_param_set: false,
      resend_from_local_message_reader: false,
      times_sent: 1,
    }),
  )
  ignore(
    debug_messages.write(DebugMessage::{
      resend_from_param_set: true,
      resend_from_local_message_reader: false,
      times_sent: 1,
    }),
  )
  ignore(
    debug_messages.write(DebugMessage::{
      resend_from_param_set: false,
      resend_from_local_message_reader: true,
      times_sent: 1,
    }),
  )
  ignore(
    debug_messages.write(DebugMessage::{
      resend_from_param_set: true,
      resend_from_local_message_reader: true,
      times_sent: 1,
    }),
  )
}

///|
fn debug_messages(messages : @ecs.MessageReader[DebugMessage]) -> Unit {
  for message in (try! messages.read()) {
    println(message.to_string())
  }
}

///|
fn send_and_receive_param_set(
  param_set : @app.ParamSet2[
    @ecs.MessageReader[DebugMessage],
    @ecs.MessageWriter[DebugMessage],
  ],
  frame_count : @app.Res[@diagnostic.FrameCount],
) -> Unit {
  println(
    "Sending and receiving messages for frame \{frame_count.get().value} with a `ParamSet`",
  )

  let messages_to_resend : Array[DebugMessage] = []
  for message in (try! param_set.p0().read()) {
    if message.resend_from_param_set {
      messages_to_resend.push(message)
    }
  }

  for message in messages_to_resend {
    ignore(
      param_set
      .p1()
      .write(DebugMessage::{
        resend_from_param_set: message.resend_from_param_set,
        resend_from_local_message_reader: message.resend_from_local_message_reader,
        times_sent: message.times_sent + 1,
      }),
    )
  }
}

///|
fn send_and_receive_manual_message_reader(
  local_message_reader : @app.Local[@ecs.MessageCursor[DebugMessage]],
  messages : @app.ResMut[@ecs.Messages[DebugMessage]],
  frame_count : @app.Res[@diagnostic.FrameCount],
) -> Unit {
  println(
    "Sending and receiving messages for frame \{frame_count.get().value} with a `Local<MessageCursor>`",
  )

  let messages_to_resend : Array[DebugMessage] = []
  for message in (try! local_message_reader.read(messages)) {
    if message.resend_from_local_message_reader {
      messages_to_resend.push(message)
    }
  }

  for message in messages_to_resend {
    ignore(
      messages.write(DebugMessage::{
        resend_from_param_set: message.resend_from_param_set,
        resend_from_local_message_reader: message.resend_from_local_message_reader,
        times_sent: message.times_sent + 1,
      }),
    )
  }
}

///|
fn main {
  B::{  } |> ignore
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.minimal_plugins())
    .add_message(debug_message_key)
    .add_message(a_key)
    .add_message(b_key)
    .add_systems(
      @app.Update,
      @app.system(@app.system_param2(read_and_write_different_message_types)),
    )
    .add_systems(
      @app.Update,
      @app.system(@app.system_param2(send_messages)).in_set(send_messages_set),
    )
    .add_systems(
      @app.Update,
      @app.system(@app.system_param(debug_messages)).in_set(
        debug_messages_before_param_set,
      ),
    )
    .add_systems(
      @app.Update,
      @app.system(@app.system_param2(send_and_receive_param_set)).in_set(
        send_and_receive_param_set_set,
      ),
    )
    .add_systems(
      @app.Update,
      @app.system(@app.system_param(debug_messages)).in_set(
        debug_messages_before_local_cursor_set,
      ),
    )
    .add_systems(
      @app.Update,
      @app.system(@app.system_param3(send_and_receive_manual_message_reader)).in_set(
        send_and_receive_manual_reader_set,
      ),
    )
    .add_systems(
      @app.Update,
      @app.system(@app.system_param(debug_messages)).in_set(
        debug_messages_after_local_cursor_set,
      ),
    )
    .configure_set(@app.Update, send_messages_set, before=[
      debug_messages_before_param_set,
    ])
    .configure_set(@app.Update, debug_messages_before_param_set, before=[
      send_and_receive_param_set_set,
    ])
    .configure_set(@app.Update, send_and_receive_param_set_set, before=[
      debug_messages_before_local_cursor_set,
    ])
    .configure_set(@app.Update, debug_messages_before_local_cursor_set, before=[
      send_and_receive_manual_reader_set,
    ])
    .configure_set(@app.Update, send_and_receive_manual_reader_set, before=[
      debug_messages_after_local_cursor_set,
    ])

  app = app.update()
  app = app.update()
  ignore(app)
}
