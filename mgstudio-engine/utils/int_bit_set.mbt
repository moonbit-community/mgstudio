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
// Bevy source: `fixedbitset::FixedBitSet` as used by `bevy_ecs::query::QueryState`
// and `bevy_ecs::query::Access`. This is a compact MoonBit adaptation for dense
// non-negative integer ids such as component, table and archetype ids.

///|
let int_bit_set_segment_bits : Int = 32

///|
pub struct IntBitSet {
  bits : Array[UInt]
  mut bit_len : Int
}

///|
pub fn IntBitSet::new() -> IntBitSet {
  IntBitSet::{ bits: [], bit_len: 0 }
}

///|
pub fn IntBitSet::with_capacity(capacity : Int) -> IntBitSet {
  let capacity = if capacity < 0 { 0 } else { capacity }
  IntBitSet::{
    bits: Array::make(
      (capacity + int_bit_set_segment_bits - 1) / int_bit_set_segment_bits,
      0U,
    ),
    bit_len: capacity,
  }
}

///|
pub fn IntBitSet::default() -> IntBitSet {
  IntBitSet::new()
}

///|
pub fn IntBitSet::capacity(self : IntBitSet) -> Int {
  self.bits.length() * int_bit_set_segment_bits
}

///|
pub fn IntBitSet::bit_len(self : IntBitSet) -> Int {
  self.bit_len
}

///|
fn IntBitSet::ensure_capacity_for(self : IntBitSet, index : Int) -> Unit {
  if index < 0 {
    abort("IntBitSet index must be non-negative")
  }
  let required_segments = (index + int_bit_set_segment_bits) /
    int_bit_set_segment_bits
  while self.bits.length() < required_segments {
    self.bits.push(0U)
  }
  if self.bit_len <= index {
    self.bit_len = index + 1
  }
}

///|
pub fn IntBitSet::clear(self : IntBitSet) -> Unit {
  for i in 0..<self.bits.length() {
    self.bits[i] = 0U
  }
}

///|
pub fn IntBitSet::insert(self : IntBitSet, index : Int) -> Unit {
  self.ensure_capacity_for(index)
  let segment = index / int_bit_set_segment_bits
  let offset = index % int_bit_set_segment_bits
  self.bits[segment] = self.bits[segment] | (1U << offset)
}

///|
pub fn IntBitSet::remove(self : IntBitSet, index : Int) -> Unit {
  if index < 0 || index >= self.capacity() {
    return
  }
  let segment = index / int_bit_set_segment_bits
  let offset = index % int_bit_set_segment_bits
  let mask = 1U << offset
  if (self.bits[segment] & mask) != 0U {
    self.bits[segment] = self.bits[segment] - mask
  }
}

///|
pub fn IntBitSet::contains(self : IntBitSet, index : Int) -> Bool {
  if index < 0 || index >= self.capacity() {
    return false
  }
  let segment = index / int_bit_set_segment_bits
  let offset = index % int_bit_set_segment_bits
  (self.bits[segment] & (1U << offset)) != 0U
}

///|
pub fn IntBitSet::contains_all_array(
  self : IntBitSet,
  indices : Array[Int],
) -> Bool {
  for index in indices {
    if !self.contains(index) {
      return false
    }
  }
  true
}

///|
pub fn IntBitSet::is_empty(self : IntBitSet) -> Bool {
  for segment in self.bits {
    if segment != 0U {
      return false
    }
  }
  true
}

///|
pub fn IntBitSet::length(self : IntBitSet) -> Int {
  self.to_array().length()
}

///|
pub fn IntBitSet::to_array(self : IntBitSet) -> Array[Int] {
  let values : Array[Int] = []
  for segment_index in 0..<self.bits.length() {
    let segment = self.bits[segment_index]
    if segment == 0U {
      continue
    }
    for offset in 0..<int_bit_set_segment_bits {
      let index = segment_index * int_bit_set_segment_bits + offset
      if index >= self.bit_len {
        break
      }
      if (segment & (1U << offset)) != 0U {
        values.push(index)
      }
    }
  }
  values
}

///|
pub fn IntBitSet::clone(self : IntBitSet) -> IntBitSet {
  let bits : Array[UInt] = []
  for segment in self.bits {
    bits.push(segment)
  }
  IntBitSet::{ bits, bit_len: self.bit_len }
}
