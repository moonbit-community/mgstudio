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
/// Internal native worker runtime for Bevy-aligned task pools.

///|
#external
priv type BackgroundNativeMutex

///|
extern "C" fn BackgroundNativeMutex::new() -> BackgroundNativeMutex = "mgstudio_tasks_mutex_new"

///|
#borrow(self)
extern "C" fn BackgroundNativeMutex::lock(self : BackgroundNativeMutex) = "mgstudio_tasks_mutex_lock"

///|
#borrow(self)
extern "C" fn BackgroundNativeMutex::unlock(self : BackgroundNativeMutex) = "mgstudio_tasks_mutex_unlock"

///|
#external
priv type BackgroundNativeSignal

///|
extern "C" fn BackgroundNativeSignal::new() -> BackgroundNativeSignal = "mgstudio_tasks_signal_new"

///|
#borrow(self)
extern "C" fn BackgroundNativeSignal::wake(self : BackgroundNativeSignal) = "mgstudio_tasks_signal_wake"

///|
#borrow(self)
extern "C" fn BackgroundNativeSignal::wait(
  self : BackgroundNativeSignal,
  timeout_ms : Int,
) -> Int = "mgstudio_tasks_signal_wait"

///|
#external
priv type BackgroundNativeThread

///|
#owned(call_entry, entry)
extern "C" fn background_native_thread_spawn(
  call_entry : FuncRef[(() -> Unit) -> Unit],
  entry : () -> Unit,
) -> BackgroundNativeThread = "mgstudio_tasks_thread_spawn"

///|
#borrow(self)
extern "C" fn BackgroundNativeThread::detach(self : BackgroundNativeThread) = "mgstudio_tasks_thread_detach"

///|
extern "C" fn background_native_available_parallelism() -> Int = "mgstudio_tasks_available_parallelism"

///|
type WorkerCommand = () -> Unit

///|
priv enum TaskOutcome[T] {
  Pending
  Success(T)
  Failed(String)
  Cancelled
}

///|
priv struct WorkerQueue {
  mutex : BackgroundNativeMutex
  signal : BackgroundNativeSignal
  queue : Array[WorkerCommand]
}

///|
priv struct TaskPoolRuntime {
  queue : WorkerQueue
  thread_count : Int
}

///|
priv struct TaskShared[T] {
  mutex : BackgroundNativeMutex
  mut outcome : TaskOutcome[T]
  mut cancel_requested : Bool
}

///|
fn[T] pop_front(queue : Array[T]) -> T? {
  if queue.length() == 0 {
    return None
  }
  let value = queue[0]
  let retained : Array[T] = []
  for i in 1..<queue.length() {
    retained.push(queue[i])
  }
  queue.clear()
  for item in retained {
    queue.push(item)
  }
  Some(value)
}

///|
fn worker_queue_new() -> WorkerQueue {
  WorkerQueue::{
    mutex: BackgroundNativeMutex::new(),
    signal: BackgroundNativeSignal::new(),
    queue: [],
  }
}

///|
fn worker_queue_push(queue : WorkerQueue, command : WorkerCommand) -> Unit {
  queue.mutex.lock()
  defer queue.mutex.unlock()
  queue.queue.push(command)
  queue.signal.wake()
}

///|
fn worker_queue_pop(queue : WorkerQueue) -> WorkerCommand? {
  queue.mutex.lock()
  defer queue.mutex.unlock()
  pop_front(queue.queue)
}

///|
fn[T] task_shared_new() -> TaskShared[T] {
  TaskShared::{
    mutex: BackgroundNativeMutex::new(),
    outcome: Pending,
    cancel_requested: false,
  }
}

///|
fn[T] task_shared_snapshot(shared : TaskShared[T]) -> TaskOutcome[T] {
  shared.mutex.lock()
  defer shared.mutex.unlock()
  shared.outcome
}

///|
fn[T] task_shared_is_finished(shared : TaskShared[T]) -> Bool {
  match task_shared_snapshot(shared) {
    Pending => false
    _ => true
  }
}

///|
fn[T] task_shared_mark_detached(shared : TaskShared[T]) -> Unit {
  ignore(shared)
}

///|
fn[T] task_shared_request_cancel(shared : TaskShared[T]) -> Unit {
  shared.mutex.lock()
  defer shared.mutex.unlock()
  if shared.outcome is Pending {
    shared.cancel_requested = true
  }
}

///|
fn[T] task_shared_is_cancel_requested(shared : TaskShared[T]) -> Bool {
  shared.mutex.lock()
  defer shared.mutex.unlock()
  shared.cancel_requested
}

///|
fn[T] task_shared_begin_run(shared : TaskShared[T]) -> Bool {
  shared.mutex.lock()
  defer shared.mutex.unlock()
  guard shared.outcome is Pending else { return false }
  if shared.cancel_requested {
    shared.outcome = Cancelled
    return false
  }
  true
}

///|
fn[T] task_shared_finish_success(shared : TaskShared[T], value : T) -> Unit {
  shared.mutex.lock()
  defer shared.mutex.unlock()
  guard shared.outcome is Pending else { return }
  if shared.cancel_requested {
    shared.outcome = Cancelled
  } else {
    shared.outcome = Success(value)
  }
}

///|
fn[T] task_shared_finish_failed(
  shared : TaskShared[T],
  message : String,
) -> Unit {
  shared.mutex.lock()
  defer shared.mutex.unlock()
  guard shared.outcome is Pending else { return }
  if shared.cancel_requested {
    shared.outcome = Cancelled
  } else {
    shared.outcome = Failed(message)
  }
}

///|
fn[T] task_shared_finish_cancelled(shared : TaskShared[T]) -> Unit {
  shared.mutex.lock()
  defer shared.mutex.unlock()
  guard shared.outcome is Pending else { return }
  shared.outcome = Cancelled
}

///|
fn[T] task_spawn_command(
  shared : TaskShared[T],
  task : () -> T raise,
) -> WorkerCommand {
  fn() {
    if !task_shared_begin_run(shared) {
      return
    }
    try task() catch {
      err =>
        if task_shared_is_cancel_requested(shared) {
          task_shared_finish_cancelled(shared)
        } else {
          task_shared_finish_failed(shared, err.to_string())
        }
    } noraise {
      value =>
        if task_shared_is_cancel_requested(shared) {
          task_shared_finish_cancelled(shared)
        } else {
          task_shared_finish_success(shared, value)
        }
    }
  }
}

///|
fn worker_thread_loop(runtime : TaskPoolRuntime) -> Unit {
  while true {
    match worker_queue_pop(runtime.queue) {
      Some(command) => command()
      None => ignore(runtime.queue.signal.wait(-1))
    }
  }
}

///|
fn worker_thread_entry(
  runtime : TaskPoolRuntime,
  on_thread_spawn : (() -> Unit)?,
  on_thread_destroy : (() -> Unit)?,
) -> Unit {
  if on_thread_spawn is Some(callback) {
    callback()
  }
  worker_thread_loop(runtime)
  if on_thread_destroy is Some(callback) {
    callback()
  }
}

///|
fn background_thread_entry(entry : () -> Unit) -> Unit {
  entry()
}

///|
let background_thread_entry_fr : FuncRef[(() -> Unit) -> Unit] = fn(entry) {
  background_thread_entry(entry)
}

///|
fn task_pool_runtime_new(
  thread_count : Int,
  on_thread_spawn : (() -> Unit)?,
  on_thread_destroy : (() -> Unit)?,
) -> TaskPoolRuntime {
  let safe_thread_count = if thread_count <= 0 { 1 } else { thread_count }
  let runtime = TaskPoolRuntime::{
    queue: worker_queue_new(),
    thread_count: safe_thread_count,
  }
  for _ in 0..<safe_thread_count {
    let thread = background_native_thread_spawn(background_thread_entry_fr, fn() {
      worker_thread_entry(runtime, on_thread_spawn, on_thread_destroy)
    })
    thread.detach()
  }
  runtime
}
