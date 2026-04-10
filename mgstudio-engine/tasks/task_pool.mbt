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

// Bevy source: `bevy/crates/bevy_tasks/src/task_pool.rs`.

///|
pub struct Scope[T] {
  results : Array[T]
}

///|
pub fn[T] Scope::new() -> Scope[T] {
  Scope::{ results: [] }
}

///|
pub fn[T] Scope::spawn(self : Scope[T], task : () -> T) -> Unit {
  self.results.push(task())
}

///|
pub fn[T] Scope::spawn_on_scope(self : Scope[T], task : () -> T) -> Unit {
  self.spawn(task)
}

///|
pub fn[T] Scope::results(self : Scope[T]) -> Array[T] {
  self.results
}

///|
pub struct TaskPool {
  thread_num : Int
}

///|
pub fn TaskPool::new() -> TaskPool {
  TaskPoolBuilder::new().build()
}

///|
pub fn TaskPool::thread_num(self : TaskPool) -> Int {
  self.thread_num
}

///|
pub fn[T] TaskPool::scope(
  self : TaskPool,
  run : (Scope[T]) -> Unit,
) -> Array[T] {
  ignore(self)
  let scope = Scope::new()
  run(scope)
  scope.results()
}

///|
pub fn[T] TaskPool::scope_with_executor(
  self : TaskPool,
  tick_task_pool_executor : Bool,
  external_executor : ThreadExecutor?,
  run : (Scope[T]) -> Unit,
) -> Array[T] {
  ignore(tick_task_pool_executor)
  ignore(external_executor)
  self.scope(run)
}

///|
pub struct TaskPoolBuilder {
  num_threads : Int?
  stack_size : Int?
  thread_name : String?
  on_thread_spawn : (() -> Unit)?
  on_thread_destroy : (() -> Unit)?
}

///|
pub fn TaskPoolBuilder::new() -> TaskPoolBuilder {
  TaskPoolBuilder::{
    num_threads: None,
    stack_size: None,
    thread_name: None,
    on_thread_spawn: None,
    on_thread_destroy: None,
  }
}

///|
pub fn TaskPoolBuilder::num_threads(
  self : TaskPoolBuilder,
  num_threads : Int,
) -> TaskPoolBuilder {
  TaskPoolBuilder::{ ..self, num_threads: Some(num_threads) }
}

///|
pub fn TaskPoolBuilder::stack_size(
  self : TaskPoolBuilder,
  stack_size : Int,
) -> TaskPoolBuilder {
  TaskPoolBuilder::{ ..self, stack_size: Some(stack_size) }
}

///|
pub fn TaskPoolBuilder::thread_name(
  self : TaskPoolBuilder,
  thread_name : String,
) -> TaskPoolBuilder {
  TaskPoolBuilder::{ ..self, thread_name: Some(thread_name) }
}

///|
pub fn TaskPoolBuilder::on_thread_spawn(
  self : TaskPoolBuilder,
  callback : () -> Unit,
) -> TaskPoolBuilder {
  TaskPoolBuilder::{ ..self, on_thread_spawn: Some(callback) }
}

///|
pub fn TaskPoolBuilder::on_thread_destroy(
  self : TaskPoolBuilder,
  callback : () -> Unit,
) -> TaskPoolBuilder {
  TaskPoolBuilder::{ ..self, on_thread_destroy: Some(callback) }
}

///|
pub fn TaskPoolBuilder::with_thread_num(
  self : TaskPoolBuilder,
  n : Int,
) -> TaskPoolBuilder {
  self.num_threads(n)
}

///|
pub fn TaskPoolBuilder::build(self : TaskPoolBuilder) -> TaskPool {
  if self.on_thread_spawn is Some(callback) {
    callback()
  }
  if self.on_thread_destroy is Some(callback) {
    callback()
  }
  TaskPool::{ thread_num: self.num_threads.unwrap_or(available_parallelism()) }
}
