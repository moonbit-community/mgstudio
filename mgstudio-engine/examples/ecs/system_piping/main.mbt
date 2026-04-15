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
struct Message {
  value : String
}

///|
struct OptionalWarning {
  value : String?
}

///|
enum ParseOutcome {
  Parsed(Int)
  ParseError(String)
} derive(Debug)

///|
let message_resource_key : @ecs.ResourceKey[Message] = @ecs.register_resource(
  debug_name="examples.ecs.system_piping.message",
)

///|
let optional_warning_resource_key : @ecs.ResourceKey[OptionalWarning] = @ecs.register_resource(
  debug_name="examples.ecs.system_piping.optional_warning",
)

///|
impl @app.Resource for Message with resource() {
  message_resource_key
}

///|
impl @app.Resource for OptionalWarning with resource() {
  optional_warning_resource_key
}

///|
fn parse_message(text : String) -> ParseOutcome {
  try @string.parse_int(text[:], base=10) catch {
    _ => ParseError("failed to parse message: \{text}")
  } noraise {
    value => Parsed(value)
  }
}

///|
fn parse_message_system(message : @app.Res[Message]) -> ParseOutcome {
  parse_message(message.get().value)
}

///|
fn parse_error_message_system(message : @app.Res[Message]) -> String? {
  match parse_message(message.get().value) {
    Parsed(_) => None
    ParseError(err) => Some(err)
  }
}

///|
fn handler_system(result : @app.In[ParseOutcome]) -> Unit {
  match result.get() {
    Parsed(value) => println("parsed message: \{value.to_string()}")
    ParseError(err) => println("encountered an error: \{err}")
  }
}

///|
fn data_pipe_system(message : @app.Res[Message]) -> String {
  message.get().value
}

///|
fn warning_pipe_system(warning : @app.Res[OptionalWarning]) -> String? {
  warning.get().value
}

///|
fn print_info(output : String) -> Unit {
  @app.log_info(output)
}

///|
fn print_debug(result : ParseOutcome) -> Unit {
  @app.log_debug(to_repr(result).to_string())
}

///|
fn print_warning(warning : String?) -> Unit {
  if warning is Some(err) {
    @app.log_error(err)
  }
}

///|
fn print_parse_error(result : String?) -> Unit {
  if result is Some(err) {
    @app.log_error(err)
  }
}

///|
fn drop_parsed_message(_result : ParseOutcome) -> Unit {

}

///|
fn main {
  let parse_pipe_config : @app.SystemConfig[@ecs.World] = @app.system_param_output(
    parse_message_system,
  ).pipe(handler_system)
  let data_map_config : @app.SystemConfig[@ecs.World] = @app.system_param_output(
    data_pipe_system,
  ).map(print_info)
  let debug_map_config : @app.SystemConfig[@ecs.World] = @app.system_param_output(
    parse_message_system,
  ).map(print_debug)
  let warning_map_config : @app.SystemConfig[@ecs.World] = @app.system_param_output(
    warning_pipe_system,
  ).map(print_warning)
  let parse_error_map_config : @app.SystemConfig[@ecs.World] = @app.system_param_output(
    parse_error_message_system,
  ).map(print_parse_error)
  let drop_map_config : @app.SystemConfig[@ecs.World] = @app.system_param_output(
    parse_message_system,
  ).map(drop_parsed_message)
  let update_chain : @app.SystemConfig[@ecs.World] = (
      parse_pipe_config, data_map_config, debug_map_config, warning_map_config, parse_error_map_config,
      drop_map_config,
    )
    |> @app.chain()

  @app.App::new(@ecs.World::new())
  .add_plugins(@app.ScheduleRunnerPlugin::run_once())
  .insert_resource(Message::{ value: "42" })
  .insert_resource(OptionalWarning::{ value: Some("Got to rusty?") })
  .add_systems(@app.Update, update_chain)
  .run()
}
