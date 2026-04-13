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
// Bevy source: `bevy/crates/bevy_app/src/schedule_runner.rs`.

///|
pub fn schedule_runner_plugin_once() -> Plugin[@ecs.World] {
  schedule_runner_plugin(ScheduleRunnerPlugin::run_once())
}

///|
pub fn schedule_runner_plugin_loop(
  interval_seconds : Float,
) -> Plugin[@ecs.World] {
  schedule_runner_plugin(ScheduleRunnerPlugin::run_loop(interval_seconds))
}

///|
pub fn schedule_runner_plugin_loop_hz(hz : Float) -> Plugin[@ecs.World] {
  let interval = if hz <= 0.0F { 0.0F } else { 1.0F / hz }
  schedule_runner_plugin(ScheduleRunnerPlugin::run_loop(interval))
}
