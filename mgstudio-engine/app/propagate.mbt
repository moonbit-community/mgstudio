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
// Bevy source: `bevy/crates/bevy_app/src/propagate.rs`.

///|
pub struct FixedSchedulePropagationConfig {
  run_fixed_update : Bool
  run_fixed_main : Bool
}

///|
pub fn FixedSchedulePropagationConfig::default() -> FixedSchedulePropagationConfig {
  FixedSchedulePropagationConfig::{ run_fixed_update: true, run_fixed_main: true }
}

///|
pub fn run_fixed_update_schedule(world : @ecs.World) -> Unit {
  run_current_fixed_update_schedule(world)
}

///|
pub fn run_fixed_main_stage(world : @ecs.World) -> Unit {
  run_current_fixed_main_schedule(world)
}

///|
pub fn run_fixed_schedules_with_config(
  world : @ecs.World,
  config : FixedSchedulePropagationConfig,
) -> Unit {
  if config.run_fixed_update {
    run_fixed_update_schedule(world)
  }
  if config.run_fixed_main {
    run_fixed_main_stage(world)
  }
}

///|
pub fn run_all_fixed_schedules(world : @ecs.World) -> Unit {
  run_fixed_schedules_with_config(world, FixedSchedulePropagationConfig::default())
}
