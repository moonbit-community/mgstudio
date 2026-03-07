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
/// Port of `bevy/examples/app/log_layers_ecs.rs`.

///|
struct LogMessage {
  message : String
  level : @app.LogLevel
}

///|
let log_message_key : @ecs.MessageKey[LogMessage] = @ecs.register_message(
  debug_name="examples.app.log_layers_ecs.LogMessage",
)

///|
let captured_log_queue_ref : Ref[Array[LogMessage]] = Ref::new([])

///|
pub impl @ecs.Message for LogMessage with message() {
  log_message_key
}

///|
fn custom_layer(record : @app.LogRecord) -> Unit {
  captured_log_queue_ref.val.push(LogMessage::{
    message: record.message(),
    level: record.level(),
  })
}

///|
fn transfer_log_messages(writer : @ecs.MessageWriter[LogMessage]) -> Unit {
  let tick_messages = captured_log_queue_ref.val
  captured_log_queue_ref.val = []
  for message in tick_messages {
    ignore(writer.write(message))
  }
}

///|
fn log_system(_world : @ecs.World) -> Unit {
  @app.log_error("Something failed")
  @app.log_warn(
    "Something bad happened that isn't a failure, but thats worth calling out",
  )
  @app.log_info("Helpful information that is worth printing by default")
  @app.log_debug("Helpful for debugging")
  @app.log_trace("Very noisy")
}

///|
fn print_logs(reader : @ecs.MessageReader[LogMessage]) -> Unit {
  for log_message in (try! reader.read()) {
    println(log_message.level.to_string() + " " + log_message.message)
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  let log_plugin = @app.LogPlugin::default().with_custom_layer(custom_layer)
  @app.App::new(@ecs.World::new())
  .add_message(log_message_key)
  .add_plugins(plugins)
  .add_plugins([@app.log_plugin(log_plugin)])
  .add_systems(@app.Update, @app.system(log_system))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(transfer_log_messages)),
  )
  .add_systems(@app.Update, @app.system(@app.system_param(print_logs)))
  .run()
}
