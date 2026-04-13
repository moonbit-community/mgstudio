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
// Bevy source: `bevy/crates/bevy_utils/src/parallel_queue.rs`.
// MoonBit adaptation of Bevy's parallel queue utility.

///|
pub type ParallelQueueValues[T] = Array[T]

///|
pub fn[T] parallel_queue_values_empty() -> ParallelQueueValues[T] {
  []
}

///|
pub struct ParallelQueue[T] {
  mut values : Array[T]
}

///|
pub fn[T] ParallelQueue::new() -> ParallelQueue[T] {
  ParallelQueue::{ values: [] }
}

///|
pub fn[T] ParallelQueue::default() -> ParallelQueue[T] {
  ParallelQueue::new()
}

///|
pub fn[T] ParallelQueue::push(self : ParallelQueue[T], value : T) -> Unit {
  self.values.push(value)
}

///|
pub fn[T] ParallelQueue::extend(
  self : ParallelQueue[T],
  items : Array[T],
) -> Unit {
  for item in items {
    self.values.push(item)
  }
}

///|
pub fn[T] ParallelQueue::len(self : ParallelQueue[T]) -> Int {
  self.values.length()
}

///|
pub fn[T] ParallelQueue::is_empty(self : ParallelQueue[T]) -> Bool {
  self.values.is_empty()
}

///|
pub fn[T] ParallelQueue::clear(self : ParallelQueue[T]) -> Unit {
  self.values.clear()
}

///|
pub fn[T] ParallelQueue::drain(self : ParallelQueue[T]) -> Array[T] {
  let drained = self.values
  self.values = []
  drained
}

///|
pub fn[T] ParallelQueue::drain_into(
  self : ParallelQueue[T],
  out : Array[T],
) -> Unit {
  for item in self.values {
    out.push(item)
  }
  self.values.clear()
}
