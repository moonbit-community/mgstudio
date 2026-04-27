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
test "app log: target filter specificity follows Bevy EnvFilter shape" {
  let records : Array[String] = []
  let layer : LogLayer = fn(record : LogRecord) {
    records.push(record.message())
  }
  let _app = App::new(@ecs.World::new()).add_plugins(
    LogPlugin::default()
    .with_level(LogLevel::Trace)
    .with_filter("warn,target_a=trace,target_a::child=error")
    .with_fmt_layer(layer),
  )
  log_record(LogLevel::Info, message="global-info", target="other")
  log_record(LogLevel::Debug, message="target-debug", target="target_a")
  log_record(LogLevel::Warn, message="child-warn", target="target_a::child")
  log_record(LogLevel::Error, message="child-error", target="target_a::child")
  debug_inspect(records, content="[\"target-debug\", \"child-error\"]")
}
