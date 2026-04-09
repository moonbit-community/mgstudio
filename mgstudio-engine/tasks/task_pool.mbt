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

// Bevy source-shape anchor: bevy_tasks/src/task_pool.rs

pub struct Scope {}

pub struct TaskPool {}

pub struct TaskPoolBuilder {
  thread_num : Int?
}

pub fn TaskPoolBuilder::new() -> TaskPoolBuilder {
  TaskPoolBuilder::{ thread_num: None }
}

pub fn TaskPoolBuilder::with_thread_num(self : TaskPoolBuilder, n : Int) -> TaskPoolBuilder {
  ignore(self)
  TaskPoolBuilder::{ thread_num: Some(n) }
}

pub fn TaskPoolBuilder::build(self : TaskPoolBuilder) -> TaskPool {
  ignore(self)
  TaskPool::{  }
}
