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
/// Tasks API boundary aligned with Bevy's `bevy_tasks` crate responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/app`.

///|
pub type TaskPoolOptions = @app.TaskPoolOptions

///|
pub type TaskPoolPlugin = @app.TaskPoolPlugin

///|
pub fn[W] task_pool_plugin(plugin : TaskPoolPlugin) -> @app.Plugin[W] {
  @app.task_pool_plugin(plugin)
}

///|
pub fn task_pool_num_threads() -> Int? {
  @app.task_pool_num_threads()
}

///|
pub struct Task[T] {
  result : T
}

///|
pub struct IoTaskPool {}

///|
pub struct AsyncComputeTaskPool {}

///|
pub fn IoTaskPool::get() -> IoTaskPool {
  IoTaskPool::{  }
}

///|
pub fn AsyncComputeTaskPool::get() -> AsyncComputeTaskPool {
  AsyncComputeTaskPool::{  }
}

///|
pub fn[T] IoTaskPool::spawn(self : IoTaskPool, task : () -> T) -> Task[T] {
  self |> ignore
  Task::{ result: task() }
}

///|
pub fn[T] AsyncComputeTaskPool::spawn(
  self : AsyncComputeTaskPool,
  task : () -> T,
) -> Task[T] {
  self |> ignore
  Task::{ result: task() }
}

///|
pub fn[T] Task::get(self : Task[T]) -> T {
  self.result
}

///|
pub fn[T] Task::detach(self : Task[T]) -> Unit {
  self |> ignore
}
