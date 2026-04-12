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
// Bevy source: `bevy/crates/bevy_app/src/task_pool_plugin.rs`.

///|
pub(all) struct TaskPoolThreadAssignmentPolicy {
  min_threads : Int
  max_threads : Int
  percent : Float
} derive(Debug)

///|
pub fn TaskPoolThreadAssignmentPolicy::default_io() -> TaskPoolThreadAssignmentPolicy {
  TaskPoolThreadAssignmentPolicy::{
    min_threads: 1,
    max_threads: 4,
    percent: 0.25F,
  }
}

///|
pub fn TaskPoolThreadAssignmentPolicy::default_async_compute() -> TaskPoolThreadAssignmentPolicy {
  TaskPoolThreadAssignmentPolicy::{
    min_threads: 1,
    max_threads: 4,
    percent: 0.25F,
  }
}

///|
pub fn TaskPoolThreadAssignmentPolicy::default_compute() -> TaskPoolThreadAssignmentPolicy {
  TaskPoolThreadAssignmentPolicy::{
    min_threads: 1,
    max_threads: 2147483647,
    percent: 1.0F,
  }
}

///|
pub(all) struct TaskPoolOptions {
  min_total_threads : Int
  max_total_threads : Int
  io : TaskPoolThreadAssignmentPolicy
  async_compute : TaskPoolThreadAssignmentPolicy
  compute : TaskPoolThreadAssignmentPolicy
} derive(Debug)

///|
pub fn TaskPoolOptions::default() -> TaskPoolOptions {
  TaskPoolOptions::{
    min_total_threads: 1,
    max_total_threads: 2147483647,
    io: TaskPoolThreadAssignmentPolicy::default_io(),
    async_compute: TaskPoolThreadAssignmentPolicy::default_async_compute(),
    compute: TaskPoolThreadAssignmentPolicy::default_compute(),
  }
}

///|
pub fn TaskPoolOptions::with_num_threads(thread_count : Int) -> TaskPoolOptions {
  TaskPoolOptions::{
    ..TaskPoolOptions::default(),
    min_total_threads: thread_count,
    max_total_threads: thread_count,
  }
}

///|
pub fn TaskPoolOptions::create_default_pools(self : TaskPoolOptions) -> Unit {
  ignore(self)
}

///|
pub(all) struct TaskPoolPlugin {
  task_pool_options : TaskPoolOptions
} derive(Debug)

///|
pub fn TaskPoolPlugin::default() -> TaskPoolPlugin {
  TaskPoolPlugin::{ task_pool_options: TaskPoolOptions::default() }
}

///|
pub fn TaskPoolPlugin::build(
  self : TaskPoolPlugin,
  app : App[@ecs.World],
) -> App[@ecs.World] {
  self.task_pool_options.create_default_pools()
  app.add_last_system(fn(_world : @ecs.World) { () })
}

///|
pub fn task_pool_plugin(app : App[@ecs.World]) -> App[@ecs.World] {
  TaskPoolPlugin::default().build(app)
}
