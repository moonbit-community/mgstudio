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
// Bevy source: `bevy/crates/bevy_utils/src/bloom_filter.rs`.
// MoonBit adaptation of Bevy's bloom-filter utility.

///|
pub type BloomFilterHashes = Array[Int]

///|
pub fn bloom_filter_hashes_empty() -> BloomFilterHashes {
  []
}

///|
pub struct BloomFilter {
  bits : Array[UInt]
  hash_count : Int
}

///|
pub fn BloomFilter::new(
  segment_count? : Int = 1,
  hash_count? : Int = 2,
) -> BloomFilter {
  let segments = if segment_count <= 0 { 1 } else { segment_count }
  BloomFilter::{
    bits: Array::make(segments, 0U),
    hash_count: if hash_count <= 0 { 1 } else { hash_count },
  }
}

///|
pub fn BloomFilter::default() -> BloomFilter {
  BloomFilter::new()
}

///|
pub fn BloomFilter::clear(self : BloomFilter) -> Unit {
  for i in 0..<self.bits.length() {
    self.bits[i] = 0U
  }
}

///|
pub fn BloomFilter::segment_count(self : BloomFilter) -> Int {
  self.bits.length()
}

///|
pub fn BloomFilter::hash_count(self : BloomFilter) -> Int {
  self.hash_count
}

///|
fn bloom_filter_probe_hash(base_hash : Int, i : Int) -> UInt {
  let h1 = base_hash.reinterpret_as_uint()
  let h2 = ((base_hash >> 16) ^ base_hash).reinterpret_as_uint() | 1U
  h1 + i.reinterpret_as_uint() * h2
}

///|
fn bloom_filter_insert_hash_impl(filter : BloomFilter, hash : Int) -> Unit {
  let total_bits = filter.bits.length() * 64
  if total_bits <= 0 {
    return
  }
  let total_bits_u = total_bits.reinterpret_as_uint()
  for i in 0..<filter.hash_count {
    let idx_u = bloom_filter_probe_hash(hash, i) % total_bits_u
    let segment = idx_u / 64U
    let offset = idx_u % 64U
    let segment_i = segment.reinterpret_as_int()
    let offset_i = offset.reinterpret_as_int()
    filter.bits[segment_i] = filter.bits[segment_i] | (1U << offset_i)
  }
}

///|
fn bloom_filter_contains_hash_impl(filter : BloomFilter, hash : Int) -> Bool {
  let total_bits = filter.bits.length() * 64
  if total_bits <= 0 {
    return false
  }
  let total_bits_u = total_bits.reinterpret_as_uint()
  for i in 0..<filter.hash_count {
    let idx_u = bloom_filter_probe_hash(hash, i) % total_bits_u
    let segment = idx_u / 64U
    let offset = idx_u % 64U
    let segment_i = segment.reinterpret_as_int()
    let offset_i = offset.reinterpret_as_int()
    if (filter.bits[segment_i] & (1U << offset_i)) == 0U {
      return false
    }
  }
  true
}

///|
pub fn BloomFilter::insert_hash(self : BloomFilter, hash : Int) -> Unit {
  bloom_filter_insert_hash_impl(self, hash)
}

///|
pub fn BloomFilter::contains_hash(self : BloomFilter, hash : Int) -> Bool {
  bloom_filter_contains_hash_impl(self, hash)
}

///|
pub fn BloomFilter::check_insert_hash(self : BloomFilter, hash : Int) -> Bool {
  let existed = bloom_filter_contains_hash_impl(self, hash)
  if !existed {
    bloom_filter_insert_hash_impl(self, hash)
  }
  existed
}
