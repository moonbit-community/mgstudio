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
pub fn[W] log_plugin(plugin : LogPlugin) -> @app.Plugin[W] {
  @app.log_plugin(plugin)
}
