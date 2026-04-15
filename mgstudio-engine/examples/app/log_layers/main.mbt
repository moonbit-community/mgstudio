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
fn custom_layer(record : @app.LogRecord) -> Unit {
  println("Got event!")
  println("  level=\{to_repr(record.level()).to_string()}")
  println("  target=\{record.target()}")
  println("  name=\{record.name()}")
}

///|
fn fmt_layer(record : @app.LogRecord) -> Unit {
  let prefix = if record.target() == "" { "" } else { "[\{record.target()}] " }
  println(
    "[\{to_repr(record.level()).to_string()}] \{prefix}\{record.message()}",
  )
}

///|
fn log_system(_world : @ecs.World) -> Unit {
  @app.log_error("something failed")
  @app.log_warn(
    "something bad happened that isn't a failure, but thats worth calling out",
  )
  @app.log_info("helpful information that is worth printing by default")
  let secret_message = "Bevy"
  @app.log_info("Here's a log that uses the debug sigil: \{secret_message}")
  @app.log_debug("helpful for debugging")
  @app.log_trace("very noisy")
}

///|
fn main {
  let log_plugin = @app.LogPlugin::default()
    .with_custom_layer(custom_layer)
    .with_fmt_layer(fmt_layer)
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(log_plugin)
  .add_systems(@app.Update, @app.system(log_system))
  .run()
}
