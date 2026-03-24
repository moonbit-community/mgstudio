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
test "task pool assignment policy rounds and clamps like Bevy" {
  let policy = TaskPoolThreadAssignmentPolicy::{
    min_threads: 1,
    max_threads: 4,
    percent: 0.25F,
    on_thread_spawn: None,
    on_thread_destroy: None,
  }

  inspect(task_pool_assignment_thread_count(policy, 8, 8), content="2")
  inspect(task_pool_assignment_thread_count(policy, 1, 8), content="1")
  inspect(task_pool_assignment_thread_count(policy, 16, 32), content="4")
}

///|
test "task pool options with_num_threads pins total thread budget" {
  let options = TaskPoolOptions::with_num_threads(4)
  inspect(options.min_total_threads, content="4")
  inspect(options.max_total_threads, content="4")
}

///|
test "task pool options create Bevy-style global pools" {
  TaskPoolOptions::with_num_threads(3).create_default_pools()

  inspect(@tasks.IoTaskPool::get().thread_num(), content="1")
  inspect(@tasks.AsyncComputeTaskPool::get().thread_num(), content="1")
  inspect(@tasks.ComputeTaskPool::get().thread_num(), content="1")
}
