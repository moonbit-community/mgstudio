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
/// Bevy-aligned tasks API for native mgstudio.

///|
pub(all) suberror TaskError {
  TaskCancelled
  TaskFailed(String)
}

///|
pub fn TaskError::message(self : TaskError) -> String {
  match self {
    TaskCancelled => "task was cancelled"
    TaskFailed(message) => message
  }
}

///|
pub impl Show for TaskError with output(self, logger) {
  logger.write_string(
    match self {
      TaskCancelled => "TaskCancelled"
      TaskFailed(message) => "TaskFailed(" + message + ")"
    },
  )
}

///|
pub fn available_parallelism() -> Int {
  let count = background_native_available_parallelism()
  if count <= 0 {
    1
  } else {
    count
  }
}

///|
struct Task[T] {
  shared : TaskShared[T]
}

///|
pub fn[T] Task::detach(self : Task[T]) -> Unit {
  task_shared_mark_detached(self.shared)
}

///|
pub fn[T] Task::cancel(self : Task[T]) -> Unit {
  task_shared_request_cancel(self.shared)
}

///|
pub fn[T] Task::is_finished(self : Task[T]) -> Bool {
  task_shared_is_finished(self.shared)
}

///|
pub fn[T] Task::try_wait(self : Task[T]) -> T? raise TaskError {
  match task_shared_snapshot(self.shared) {
    Pending => None
    Success(value) => Some(value)
    Failed(message) => raise TaskFailed(message)
    Cancelled => raise TaskCancelled
  }
}

///|
pub async fn[T] Task::wait(self : Task[T]) -> T raise TaskError {
  while true {
    try self.try_wait() catch {
      err => raise err
    } noraise {
      result =>
        match result {
          Some(value) => return value
          None => @async.sleep(1) catch { _ => raise TaskCancelled }
        }
    }
  }
  abort("unreachable")
}

///|
pub struct TaskPoolBuilder {
  num_threads : Int?
  thread_name : String?
  on_thread_spawn : (() -> Unit)?
  on_thread_destroy : (() -> Unit)?
}

///|
impl Default for TaskPoolBuilder with default() {
  TaskPoolBuilder::{
    num_threads: None,
    thread_name: None,
    on_thread_spawn: None,
    on_thread_destroy: None,
  }
}

///|
pub fn TaskPoolBuilder::new() -> TaskPoolBuilder {
  TaskPoolBuilder::default()
}

///|
pub fn TaskPoolBuilder::num_threads(
  self : TaskPoolBuilder,
  num_threads : Int,
) -> TaskPoolBuilder {
  let clamped = if num_threads <= 0 { 1 } else { num_threads }
  { ..self, num_threads: Some(clamped) }
}

///|
pub fn TaskPoolBuilder::thread_name(
  self : TaskPoolBuilder,
  thread_name : String,
) -> TaskPoolBuilder {
  { ..self, thread_name: Some(thread_name) }
}

///|
pub fn TaskPoolBuilder::on_thread_spawn(
  self : TaskPoolBuilder,
  callback : () -> Unit,
) -> TaskPoolBuilder {
  { ..self, on_thread_spawn: Some(callback) }
}

///|
pub fn TaskPoolBuilder::on_thread_destroy(
  self : TaskPoolBuilder,
  callback : () -> Unit,
) -> TaskPoolBuilder {
  { ..self, on_thread_destroy: Some(callback) }
}

///|
struct TaskPool {
  runtime : TaskPoolRuntime
}

///|
pub fn TaskPool::new() -> TaskPool {
  TaskPoolBuilder::new().build()
}

///|
pub fn TaskPoolBuilder::build(self : TaskPoolBuilder) -> TaskPool {
  let thread_count = match self.num_threads {
    Some(value) => value
    None => available_parallelism()
  }
  TaskPool::{
    runtime: task_pool_runtime_new(
      thread_count,
      self.on_thread_spawn,
      self.on_thread_destroy,
    ),
  }
}

///|
pub fn TaskPool::thread_num(self : TaskPool) -> Int {
  self.runtime.thread_count
}

///|
pub fn[T] TaskPool::spawn(self : TaskPool, task : () -> T raise) -> Task[T] {
  let shared = task_shared_new()
  worker_queue_push(self.runtime.queue, task_spawn_command(shared, task))
  Task::{ shared, }
}

///|
pub struct ComputeTaskPool {
  pool : TaskPool
}

///|
pub struct AsyncComputeTaskPool {
  pool : TaskPool
}

///|
pub struct IoTaskPool {
  pool : TaskPool
}

///|
let compute_task_pool_ref : Ref[ComputeTaskPool?] = Ref::new(None)

///|
let async_compute_task_pool_ref : Ref[AsyncComputeTaskPool?] = Ref::new(None)

///|
let io_task_pool_ref : Ref[IoTaskPool?] = Ref::new(None)

///|
pub fn ComputeTaskPool::get_or_init(init : () -> TaskPool) -> ComputeTaskPool {
  match compute_task_pool_ref.val {
    Some(pool) => pool
    None => {
      let pool = ComputeTaskPool::{ pool: init() }
      compute_task_pool_ref.val = Some(pool)
      pool
    }
  }
}

///|
pub fn ComputeTaskPool::try_get() -> ComputeTaskPool? {
  compute_task_pool_ref.val
}

///|
pub fn ComputeTaskPool::get() -> ComputeTaskPool {
  match compute_task_pool_ref.val {
    Some(pool) => pool
    None =>
      abort(
        "The ComputeTaskPool has not been initialized yet. Please call ComputeTaskPool::get_or_init beforehand.",
      )
  }
}

///|
pub fn[T] ComputeTaskPool::spawn(
  self : ComputeTaskPool,
  task : () -> T raise,
) -> Task[T] {
  self.pool.spawn(task)
}

///|
pub fn ComputeTaskPool::thread_num(self : ComputeTaskPool) -> Int {
  self.pool.thread_num()
}

///|
pub fn AsyncComputeTaskPool::get_or_init(
  init : () -> TaskPool,
) -> AsyncComputeTaskPool {
  match async_compute_task_pool_ref.val {
    Some(pool) => pool
    None => {
      let pool = AsyncComputeTaskPool::{ pool: init() }
      async_compute_task_pool_ref.val = Some(pool)
      pool
    }
  }
}

///|
pub fn AsyncComputeTaskPool::try_get() -> AsyncComputeTaskPool? {
  async_compute_task_pool_ref.val
}

///|
pub fn AsyncComputeTaskPool::get() -> AsyncComputeTaskPool {
  match async_compute_task_pool_ref.val {
    Some(pool) => pool
    None =>
      abort(
        "The AsyncComputeTaskPool has not been initialized yet. Please call AsyncComputeTaskPool::get_or_init beforehand.",
      )
  }
}

///|
pub fn[T] AsyncComputeTaskPool::spawn(
  self : AsyncComputeTaskPool,
  task : () -> T raise,
) -> Task[T] {
  self.pool.spawn(task)
}

///|
pub fn AsyncComputeTaskPool::thread_num(self : AsyncComputeTaskPool) -> Int {
  self.pool.thread_num()
}

///|
pub fn IoTaskPool::get_or_init(init : () -> TaskPool) -> IoTaskPool {
  match io_task_pool_ref.val {
    Some(pool) => pool
    None => {
      let pool = IoTaskPool::{ pool: init() }
      io_task_pool_ref.val = Some(pool)
      pool
    }
  }
}

///|
pub fn IoTaskPool::try_get() -> IoTaskPool? {
  io_task_pool_ref.val
}

///|
pub fn IoTaskPool::get() -> IoTaskPool {
  match io_task_pool_ref.val {
    Some(pool) => pool
    None =>
      abort(
        "The IoTaskPool has not been initialized yet. Please call IoTaskPool::get_or_init beforehand.",
      )
  }
}

///|
pub fn[T] IoTaskPool::spawn(self : IoTaskPool, task : () -> T raise) -> Task[T] {
  self.pool.spawn(task)
}

///|
pub fn IoTaskPool::thread_num(self : IoTaskPool) -> Int {
  self.pool.thread_num()
}
