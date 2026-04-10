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

// Bevy source: `bevy/crates/bevy_tasks/src/iter/mod.rs`.

///|
pub struct ParallelIterator[T] {
  batches : Array[Array[T]]
  mut cursor : Int
}

///|
pub fn[T] ParallelIterator::new(
  batches : Array[Array[T]],
) -> ParallelIterator[T] {
  ParallelIterator::{ batches, cursor: 0 }
}

///|
pub fn[T] ParallelIterator::from_items(
  items : Array[T],
  batch_size : Int,
) -> ParallelIterator[T] {
  let size = if batch_size <= 0 { 1 } else { batch_size }
  let batches : Array[Array[T]] = []
  let mut start = 0
  while start < items.length() {
    let mut end = start + size
    if end > items.length() {
      end = items.length()
    }
    let batch : Array[T] = []
    for index in start..<end {
      batch.push(items[index])
    }
    batches.push(batch)
    start = end
  }
  ParallelIterator::{ batches, cursor: 0 }
}

///|
pub fn[T] ParallelIterator::next_batch(self : ParallelIterator[T]) -> Array[T]? {
  if self.cursor >= self.batches.length() {
    return None
  }
  let batch = self.batches[self.cursor]
  self.cursor = self.cursor + 1
  Some(batch)
}

///|
pub fn[T] ParallelIterator::size_hint(
  self : ParallelIterator[T],
) -> (Int, Int?) {
  let mut total = 0
  let mut index = self.cursor
  while index < self.batches.length() {
    total = total + self.batches[index].length()
    index = index + 1
  }
  (total, Some(total))
}

///|
pub fn[T] ParallelIterator::count(self : ParallelIterator[T]) -> Int {
  let mut total = 0
  while self.next_batch() is Some(batch) {
    total = total + batch.length()
  }
  total
}

///|
pub fn[T] ParallelIterator::collect(self : ParallelIterator[T]) -> Array[T] {
  let out : Array[T] = []
  while self.next_batch() is Some(batch) {
    for item in batch {
      out.push(item)
    }
  }
  out
}

///|
pub fn[T] ParallelIterator::last(self : ParallelIterator[T]) -> T? {
  let mut last_item : T? = None
  while self.next_batch() is Some(batch) {
    for item in batch {
      last_item = Some(item)
    }
  }
  last_item
}
