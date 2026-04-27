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
/// Log API boundary aligned with Bevy's `bevy_log` crate responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/app`.

///|
pub type LogLayer = @app.LogLayer

///|
pub type LogLevel = @app.LogLevel

///|
pub type LogRecord = @app.LogRecord

///|
pub type LogPlugin = @app.LogPlugin

///|
pub const DEFAULT_FILTER : String = @app.DEFAULT_LOG_FILTER

///|
pub fn log_plugin(plugin : LogPlugin) -> LogPlugin {
  plugin
}

///|
pub fn log_record(
  level : LogLevel,
  message~ : String,
  target? : String = "",
  name? : String = "",
) -> Unit {
  @app.log_record(level, message~, target~, name~)
}

///|
pub fn error(message : String) -> Unit {
  @app.log_error(message)
}

///|
pub fn warn(message : String) -> Unit {
  @app.log_warn(message)
}

///|
pub fn info(message : String) -> Unit {
  @app.log_info(message)
}

///|
pub fn debug(message : String) -> Unit {
  @app.log_debug(message)
}

///|
pub fn trace(message : String) -> Unit {
  @app.log_trace(message)
}
