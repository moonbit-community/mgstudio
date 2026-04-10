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

// Bevy source: `bevy/crates/bevy_tasks/src/iter/adapters.rs`.

///|
pub struct ParallelIteratorAdapter[T] {
  iter : ParallelIterator[T]
}

///|
pub fn[T] ParallelIteratorAdapter::new(
  iter : ParallelIterator[T],
) -> ParallelIteratorAdapter[T] {
  ParallelIteratorAdapter::{ iter, }
}

///|
pub fn[T] ParallelIteratorAdapter::next_batch(
  self : ParallelIteratorAdapter[T],
) -> Array[T]? {
  self.iter.next_batch()
}

///|
pub fn[T] parallel_chain(
  left : ParallelIterator[T],
  right : ParallelIterator[T],
) -> ParallelIterator[T] {
  let batches : Array[Array[T]] = []
  while left.next_batch() is Some(batch) {
    batches.push(batch)
  }
  while right.next_batch() is Some(batch) {
    batches.push(batch)
  }
  ParallelIterator::new(batches)
}
