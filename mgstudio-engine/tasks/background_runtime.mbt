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
/// Native bridge for background threads, wake signals, and nonblocking channels.

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
) -> Bool = "mgstudio_tasks_signal_wait"

///|
#borrow(self)
extern "C" fn BackgroundNativeSignal::try_wait(
  self : BackgroundNativeSignal,
) -> Bool = "mgstudio_tasks_signal_try_wait"

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
extern "C" fn BackgroundNativeThread::join(self : BackgroundNativeThread) = "mgstudio_tasks_thread_join"

///|
#borrow(self)
extern "C" fn BackgroundNativeThread::detach(self : BackgroundNativeThread) = "mgstudio_tasks_thread_detach"

///|
struct BackgroundSignal {
  native : BackgroundNativeSignal
}

///|
pub fn BackgroundSignal::new() -> BackgroundSignal {
  BackgroundSignal::{ native: BackgroundNativeSignal::new() }
}

///|
pub fn BackgroundSignal::wake(self : BackgroundSignal) -> Unit {
  self.native.wake()
}

///|
pub fn BackgroundSignal::wait(
  self : BackgroundSignal,
  timeout_ms? : Int = -1,
) -> Bool {
  self.native.wait(timeout_ms)
}

///|
pub fn BackgroundSignal::try_wait(self : BackgroundSignal) -> Bool {
  self.native.try_wait()
}

///|
priv struct BackgroundChannelState[T] {
  mutex : BackgroundNativeMutex
  available : BackgroundSignal
  queue : Array[T]
  capacity : Int
  drop_oldest : Bool
}

///|
struct BackgroundSender[T] {
  state : BackgroundChannelState[T]
}

///|
struct BackgroundReceiver[T] {
  state : BackgroundChannelState[T]
}

///|
fn[T] background_channel_pop_front(queue : Array[T]) -> T? {
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
pub fn[T] background_channel(
  capacity? : Int = 64,
  drop_oldest? : Bool = false,
) -> (BackgroundSender[T], BackgroundReceiver[T]) {
  let safe_capacity = if capacity <= 0 { 1 } else { capacity }
  let state = BackgroundChannelState::{
    mutex: BackgroundNativeMutex::new(),
    available: BackgroundSignal::new(),
    queue: [],
    capacity: safe_capacity,
    drop_oldest,
  }
  (BackgroundSender::{ state, }, BackgroundReceiver::{ state, })
}

///|
pub fn[T] BackgroundSender::try_send(
  self : BackgroundSender[T],
  value : T,
) -> Bool {
  self.state.mutex.lock()
  defer self.state.mutex.unlock()

  let mut should_wake = false
  let success = if self.state.queue.length() < self.state.capacity {
    self.state.queue.push(value)
    should_wake = true
    true
  } else if self.state.drop_oldest {
    background_channel_pop_front(self.state.queue) |> ignore
    self.state.queue.push(value)
    true
  } else {
    false
  }

  if should_wake {
    self.state.available.wake()
  }
  success
}

///|
pub fn[T] BackgroundReceiver::try_recv(self : BackgroundReceiver[T]) -> T? {
  self.state.mutex.lock()
  defer self.state.mutex.unlock()

  match background_channel_pop_front(self.state.queue) {
    Some(value) => {
      self.state.available.try_wait() |> ignore
      Some(value)
    }
    None => None
  }
}

///|
pub fn[T] BackgroundReceiver::recv(self : BackgroundReceiver[T]) -> T {
  if self.try_recv() is Some(value) {
    value
  } else {
    self.state.available.wait() |> ignore
    self.recv()
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
struct Task[T] {
  thread : BackgroundNativeThread
  receiver : BackgroundReceiver[T]
}

///|
fn[T] background_spawn_task(task : () -> T) -> Task[T] {
  let task_channel : (BackgroundSender[T], BackgroundReceiver[T]) = background_channel(
    capacity=1,
  )
  let (sender, receiver) = task_channel
  let thread = background_native_thread_spawn(background_thread_entry_fr, fn() {
    if !sender.try_send(task()) {
      println(
        "mgstudio background task dropped result because its channel was full",
      )
    }
  })
  Task::{ thread, receiver }
}

///|
pub fn[T] Task::get(self : Task[T]) -> T {
  self.thread.join()
  match self.receiver.try_recv() {
    Some(value) => value
    None => abort("background task exited without producing a result")
  }
}

///|
pub fn[T] Task::detach(self : Task[T]) -> Unit {
  self.thread.detach()
}
