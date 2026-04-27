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
// Bevy source: `bevy/crates/bevy_log/src/once.rs`.

///|
pub fn log_once(
  level : @app.LogLevel,
  callsite : String,
  message : String,
  target? : String = "mgstudio.log.once",
  name? : String = "mgstudio_log_once",
) -> Unit {
  @app.log_once(level, callsite~, message~, target~, name~)
}

///|
pub fn warn_once(callsite : String, message : String) -> Unit {
  @app.log_warn_once(callsite, message)
}

///|
pub fn info_once(callsite : String, message : String) -> Unit {
  @app.log_info_once(callsite, message)
}

///|
pub fn error_once(callsite : String, message : String) -> Unit {
  @app.log_error_once(callsite, message)
}

///|
pub fn debug_once(callsite : String, message : String) -> Unit {
  @app.log_debug_once(callsite, message)
}

///|
pub fn trace_once(callsite : String, message : String) -> Unit {
  @app.log_trace_once(callsite, message)
}
