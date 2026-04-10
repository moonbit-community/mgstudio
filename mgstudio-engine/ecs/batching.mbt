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
const BATCH_SIZE_MIN_DEFAULT : Int = 1

///|
const BATCH_SIZE_MAX_DEFAULT : Int = 2147483647

///|
pub struct BatchingStrategy {
  min_batch_size : Int
  max_batch_size : Int
  batches_per_thread : Int
} derive(Eq, Debug)

///|
pub impl Default for BatchingStrategy with default() {
  BatchingStrategy::new()
}

///|
pub fn BatchingStrategy::new() -> BatchingStrategy {
  BatchingStrategy::{
    min_batch_size: BATCH_SIZE_MIN_DEFAULT,
    max_batch_size: BATCH_SIZE_MAX_DEFAULT,
    batches_per_thread: 1,
  }
}

///|
pub fn BatchingStrategy::fixed(batch_size : Int) -> BatchingStrategy {
  let normalized = batching_strategy_non_negative(batch_size)
  BatchingStrategy::{
    min_batch_size: normalized,
    max_batch_size: normalized,
    batches_per_thread: 1,
  }
}

///|
pub fn BatchingStrategy::min_batch_size(
  self : BatchingStrategy,
  batch_size : Int,
) -> BatchingStrategy {
  BatchingStrategy::{
    min_batch_size: batching_strategy_non_negative(batch_size),
    max_batch_size: self.max_batch_size,
    batches_per_thread: self.batches_per_thread,
  }
}

///|
pub fn BatchingStrategy::max_batch_size(
  self : BatchingStrategy,
  batch_size : Int,
) -> BatchingStrategy {
  BatchingStrategy::{
    min_batch_size: self.min_batch_size,
    max_batch_size: batching_strategy_non_negative(batch_size),
    batches_per_thread: self.batches_per_thread,
  }
}

///|
pub fn BatchingStrategy::batches_per_thread(
  self : BatchingStrategy,
  batches_per_thread : Int,
) -> BatchingStrategy {
  BatchingStrategy::{
    min_batch_size: self.min_batch_size,
    max_batch_size: self.max_batch_size,
    batches_per_thread: if batches_per_thread <= 0 {
      1
    } else {
      batches_per_thread
    },
  }
}

///|
pub fn BatchingStrategy::calc_batch_size(
  self : BatchingStrategy,
  max_items : () -> Int,
  thread_count : Int,
) -> Int {
  if self.max_batch_size <= self.min_batch_size {
    return self.min_batch_size
  }

  let safe_thread_count = if thread_count <= 0 { 1 } else { thread_count }
  let batches = safe_thread_count * self.batches_per_thread
  let item_count = batching_strategy_non_negative(max_items())
  let batch_size = if batches <= 0 {
    item_count
  } else {
    (item_count + batches - 1) / batches
  }
  batching_strategy_clamp(batch_size, self.min_batch_size, self.max_batch_size)
}

///|
fn batching_strategy_non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
fn batching_strategy_clamp(
  value : Int,
  min_value : Int,
  max_value : Int,
) -> Int {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}
