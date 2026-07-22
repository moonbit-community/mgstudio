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
struct LogMessage {
  message : String
  level : @app.LogLevel
}

///|
struct LogViewerRoot {}

///|
let log_message_key : @ecs.MessageKey[LogMessage] = @ecs.register_message(
  debug_name="examples.app.log_layers_ecs.LogMessage",
)

///|
let log_viewer_root_key : @ecs.ComponentKey[LogViewerRoot] = @ecs.register_component(
  debug_name="examples.app.log_layers_ecs.LogViewerRoot",
)

///|
let captured_log_queue_ref : Ref[Array[LogMessage]] = Ref([])

///|
pub impl @ecs.Message for LogMessage with fn message() {
  log_message_key
}

///|
pub impl @ecs.Component for LogViewerRoot with fn component() {
  log_viewer_root_key
}

///|
fn custom_layer(record : @app.LogRecord) -> Unit {
  captured_log_queue_ref.val.push({
    message: record.message(),
    level: record.level(),
  })
}

///|
fn transfer_log_messages(writer : @ecs.MessageWriter[LogMessage]) -> Unit {
  let tick_messages = captured_log_queue_ref.val
  ignore(tick_messages)
  captured_log_queue_ref.val = []
  for message in tick_messages {
    ignore(writer.write(message))
  }
}

///|
fn log_system() -> Unit {
  @app.log_record(Error, message="Something failed", target="log_layers_ecs")
  @app.log_record(
    Warn,
    message="Something bad happened that isn't a failure, but thats worth calling out",
    target="log_layers_ecs",
  )
  @app.log_record(
    Info,
    message="Helpful information that is worth printing by default",
    target="log_layers_ecs",
  )
  @app.log_record(
    Debug,
    message="Helpful for debugging",
    target="log_layers_ecs",
  )
  @app.log_record(Trace, message="Very noisy", target="log_layers_ecs")
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))
  ignore(
    commands.spawn(
      (
        @ui.Node::Node()
        .with_width(Vw(100.0F))
        .with_height(Vh(100.0F))
        .with_flex_direction(Column)
        .with_padding(@ui.UiRect::all(Px(12.0F))),
        LogViewerRoot::{  },
      ),
    ),
  )
}

///|
fn level_color(level : @app.LogLevel) -> @color.Color {
  match level {
    Error => @color.Color::srgba(0.972549F, 0.443137F, 0.443137F, 1.0F)
    Warn => @color.Color::srgba(0.984314F, 0.572549F, 0.235294F, 1.0F)
    Info => @color.Color::srgba(0.290196F, 0.870588F, 0.501961F, 1.0F)
    Trace => @color.Color::srgba(0.752941F, 0.517647F, 0.988235F, 1.0F)
    Debug => @color.Color::srgba(0.376471F, 0.647059F, 0.980392F, 1.0F)
  }
}

///|
fn log_level_text(level : @app.LogLevel) -> String {
  let text = match level {
    Error => "ERROR"
    Warn => "WARN"
    Info => "INFO"
    Debug => "DEBUG"
    Trace => "TRACE"
  }
  if text.length() >= 5 {
    text[:5].to_owned()
  } else {
    let mut padded = text
    while padded.length() < 5 {
      padded = "\{padded} "
    }
    padded
  }
}

///|
fn spawn_log_text(
  commands : @app.Commands,
  parent : @core.Entity,
  log_message : LogMessage,
) -> Unit {
  let text_entity = commands.spawn(
    (@hierarchy.Parent::new(parent), @text.Text::Text()),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(text_entity),
        @text.TextSpan::new("\{log_level_text(log_message.level)} "),
        @text.TextColor::new(level_color(log_message.level)),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(text_entity),
        @text.TextSpan::new(log_message.message),
      ),
    ),
  )
}

///|
fn print_logs(
  reader : @ecs.MessageReader[LogMessage],
  commands : @app.Commands,
  roots : @ecs.Query[(@core.Entity, @ecs.Read[LogViewerRoot]), @ecs.All],
) -> Unit {
  let root_entity : Ref[@core.Entity?] = Ref(None)
  try! roots.view(fn(_query_entity, pair) {
    if root_entity.val is None {
      root_entity.val = Some(pair.0)
    }
  })
  guard root_entity.val is Some(root) else { return }
  for log_message in reader.read() {
    spawn_log_text(commands, root, log_message)
  }
}

///|
fn main {
  let log_plugin = @app.LogPlugin::LogPlugin()
    .with_level(Trace)
    .with_filter("warn,log_layers_ecs=trace")
    .with_custom_layer(custom_layer)
  let transfer_log_messages_system : @app.SystemConfig[@ecs.World] = @app.system_config_param(
    transfer_log_messages,
  )
  let print_logs_system : @app.SystemConfig[@ecs.World] = @app.system_config_param3(
    print_logs,
  )
  @app.App::new(@ecs.World::new())
  .add_message(log_message_key)
  .add_plugins(@mgstudio.DefaultPlugins::set(log_plugin))
  .add_systems_param(Startup, setup)
  .add_systems_fn(Startup, log_system)
  .add_systems(
    Update,
    (transfer_log_messages_system, print_logs_system) |> @app.chain(),
  )
  .run()
}
