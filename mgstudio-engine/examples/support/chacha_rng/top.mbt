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
#valtype
priv struct U32Product {
  lo : UInt
  hi : UInt
}

///|
pub struct ChaCha8Rng {
  priv state : Array[UInt]
  priv buffer : Array[UInt]
  priv mut index : Int
}

///|
fn u32_rotate_left(value : UInt, shift : Int) -> UInt {
  let s = shift & 31
  if s == 0 {
    value
  } else {
    (value << s) | (value >> (32 - s))
  }
}

///|
fn u32_rotate_right(value : UInt, shift : Int) -> UInt {
  let s = shift & 31
  if s == 0 {
    value
  } else {
    (value >> s) | (value << (32 - s))
  }
}

///|
fn pcg32_next(state : Ref[UInt64]) -> UInt {
  let mul : UInt64 = 0x5851F42D4C957F2DUL
  let inc : UInt64 = 0xA17654E46FBE17F3UL
  state.val = state.val * mul + inc
  let current = state.val
  let xorshifted = (((current >> 18) ^ current) >> 27).to_uint()
  let rotation = (current >> 59).to_int()
  u32_rotate_right(xorshifted, rotation)
}

///|
fn u32_widening_multiply(a : UInt, b : UInt) -> U32Product {
  let product = a.to_uint64() * b.to_uint64()
  U32Product::{ lo: product.to_uint(), hi: (product >> 32).to_uint() }
}

///|
fn chacha_quarter_round(
  state : Array[UInt],
  a : Int,
  b : Int,
  c : Int,
  d : Int,
) -> Unit {
  state[a] = state[a] + state[b]
  state[d] = u32_rotate_left(state[d] ^ state[a], 16)
  state[c] = state[c] + state[d]
  state[b] = u32_rotate_left(state[b] ^ state[c], 12)
  state[a] = state[a] + state[b]
  state[d] = u32_rotate_left(state[d] ^ state[a], 8)
  state[c] = state[c] + state[d]
  state[b] = u32_rotate_left(state[b] ^ state[c], 7)
}

///|
fn chacha8_block(input : Array[UInt]) -> Array[UInt] {
  let output = input.copy()
  for _ in 0..<4 {
    chacha_quarter_round(output, 0, 4, 8, 12)
    chacha_quarter_round(output, 1, 5, 9, 13)
    chacha_quarter_round(output, 2, 6, 10, 14)
    chacha_quarter_round(output, 3, 7, 11, 15)
    chacha_quarter_round(output, 0, 5, 10, 15)
    chacha_quarter_round(output, 1, 6, 11, 12)
    chacha_quarter_round(output, 2, 7, 8, 13)
    chacha_quarter_round(output, 3, 4, 9, 14)
  }
  for i in 0..<16 {
    output[i] = output[i] + input[i]
  }
  output
}

///|
fn ChaCha8Rng::refill(self : ChaCha8Rng) -> Unit {
  for block in 0..<4 {
    let words = chacha8_block(self.state)
    for i in 0..<16 {
      self.buffer[block * 16 + i] = words[i]
    }
    let counter = self.state[12].to_uint64() |
      (self.state[13].to_uint64() << 32)
    let next_counter = counter + 1UL
    self.state[12] = next_counter.to_uint()
    self.state[13] = (next_counter >> 32).to_uint()
  }
  self.index = 0
}

///|
pub fn ChaCha8Rng::seed_from_u64(seed : UInt64) -> ChaCha8Rng {
  let pcg_state = Ref(seed)
  let state = [
    0x61707865U,
    0x3320646EU,
    0x79622D32U,
    0x6B206574U,
    pcg32_next(pcg_state),
    pcg32_next(pcg_state),
    pcg32_next(pcg_state),
    pcg32_next(pcg_state),
    pcg32_next(pcg_state),
    pcg32_next(pcg_state),
    pcg32_next(pcg_state),
    pcg32_next(pcg_state),
    0U,
    0U,
    0U,
    0U,
  ]
  ChaCha8Rng::{ state, buffer: Array::make(64, 0U), index: 64 }
}

///|
fn ChaCha8Rng::next_u32(self : ChaCha8Rng) -> UInt {
  if self.index >= 64 {
    self.refill()
  }
  let value = self.buffer[self.index]
  self.index = self.index + 1
  value
}

///|
pub fn ChaCha8Rng::next_u64(self : ChaCha8Rng) -> UInt64 {
  let lo = self.next_u32().to_uint64()
  let hi = self.next_u32().to_uint64()
  (hi << 32) | lo
}

///|
pub fn ChaCha8Rng::random_range(self : ChaCha8Rng, upper : Int) -> Int {
  if upper <= 0 {
    abort("random range must be non-empty")
  }
  let range = upper.reinterpret_as_uint()
  let product = u32_widening_multiply(self.next_u32(), range)
  let mut result = product.hi
  if product.lo > 0U - range {
    let adjust = u32_widening_multiply(self.next_u32(), range).hi
    let adjusted = product.lo + adjust
    if adjusted < product.lo {
      result = result + 1U
    }
  }
  result.reinterpret_as_int()
}
