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
// Bevy source: `bevy/crates/bevy_animation/src/lib.rs`.
// Bevy-aligned animation target id utilities and hashing.

///|
let animation_target_namespace_bytes : Array[Byte] = [
  0x31U.to_byte(),
  0x79U.to_byte(),
  0xF5U.to_byte(),
  0x19U.to_byte(),
  0xD9U.to_byte(),
  0x27U.to_byte(),
  0x4FU.to_byte(),
  0xF2U.to_byte(),
  0xB5U.to_byte(),
  0x96U.to_byte(),
  0x6FU.to_byte(),
  0xD0U.to_byte(),
  0x77U.to_byte(),
  0x02U.to_byte(),
  0x39U.to_byte(),
  0x11U.to_byte(),
]

///|
const BLAKE3_BLOCK_LEN : Int = 64

///|
const BLAKE3_CHUNK_LEN : Int = 1024

///|
const BLAKE3_CHUNK_START : UInt = 1U

///|
const BLAKE3_CHUNK_END : UInt = 2U

///|
const BLAKE3_PARENT : UInt = 4U

///|
const BLAKE3_ROOT : UInt = 8U

///|
pub type AnimationMask = UInt

///|
priv struct Blake3Output {
  input_chaining_value : Array[UInt]
  block_words : Array[UInt]
  counter : UInt64
  block_len : UInt
  flags : UInt
}

///|
fn blake3_iv() -> Array[UInt] {
  [
    0x6A09E667U, 0xBB67AE85U, 0x3C6EF372U, 0xA54FF53AU, 0x510E527FU, 0x9B05688CU,
    0x1F83D9ABU, 0x5BE0CD19U,
  ]
}

///|
fn blake3_msg_permutation() -> Array[Int] {
  [2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8]
}

///|
fn blake3_rotr(value : UInt, bits : Int) -> UInt {
  (value >> bits) | (value << (32 - bits))
}

///|
fn blake3_g(
  state : Array[UInt],
  a : Int,
  b : Int,
  c : Int,
  d : Int,
  x : UInt,
  y : UInt,
) -> Unit {
  state[a] = state[a] + state[b] + x
  state[d] = blake3_rotr(state[d] ^ state[a], 16)
  state[c] = state[c] + state[d]
  state[b] = blake3_rotr(state[b] ^ state[c], 12)
  state[a] = state[a] + state[b] + y
  state[d] = blake3_rotr(state[d] ^ state[a], 8)
  state[c] = state[c] + state[d]
  state[b] = blake3_rotr(state[b] ^ state[c], 7)
}

///|
fn blake3_round(state : Array[UInt], message : Array[UInt]) -> Unit {
  blake3_g(state, 0, 4, 8, 12, message[0], message[1])
  blake3_g(state, 1, 5, 9, 13, message[2], message[3])
  blake3_g(state, 2, 6, 10, 14, message[4], message[5])
  blake3_g(state, 3, 7, 11, 15, message[6], message[7])
  blake3_g(state, 0, 5, 10, 15, message[8], message[9])
  blake3_g(state, 1, 6, 11, 12, message[10], message[11])
  blake3_g(state, 2, 7, 8, 13, message[12], message[13])
  blake3_g(state, 3, 4, 9, 14, message[14], message[15])
}

///|
fn blake3_permute(message : Array[UInt]) -> Array[UInt] {
  let permutation = blake3_msg_permutation()
  let out : Array[UInt] = []
  for index in permutation {
    out.push(message[index])
  }
  out
}

///|
fn blake3_compress(
  chaining_value : Array[UInt],
  block_words : Array[UInt],
  counter : UInt64,
  block_len : UInt,
  flags : UInt,
) -> Array[UInt] {
  let iv = blake3_iv()
  let counter_low = counter.to_uint()
  let counter_high = (counter >> 32).to_uint()
  let state : Array[UInt] = [
    chaining_value[0],
    chaining_value[1],
    chaining_value[2],
    chaining_value[3],
    chaining_value[4],
    chaining_value[5],
    chaining_value[6],
    chaining_value[7],
    iv[0],
    iv[1],
    iv[2],
    iv[3],
    counter_low,
    counter_high,
    block_len,
    flags,
  ]
  let mut message = block_words
  for round in 0..<7 {
    ignore(round)
    blake3_round(state, message)
    message = blake3_permute(message)
  }
  for i in 0..<8 {
    state[i] = state[i] ^ state[i + 8]
    state[i + 8] = state[i + 8] ^ chaining_value[i]
  }
  state
}

///|
fn blake3_block_words(input : Bytes, offset : Int, len : Int) -> Array[UInt] {
  let words : Array[UInt] = []
  for word_index in 0..<16 {
    let base = offset + word_index * 4
    let mut word = 0U
    for byte_index in 0..<4 {
      let source_index = base + byte_index
      let byte = if source_index < offset + len && source_index < input.length() {
        input[source_index].to_uint()
      } else {
        0U
      }
      word = word | (byte << (byte_index * 8))
    }
    words.push(word)
  }
  words
}

///|
fn blake3_output_chaining_value(output : Blake3Output) -> Array[UInt] {
  let compressed = blake3_compress(
    output.input_chaining_value,
    output.block_words,
    output.counter,
    output.block_len,
    output.flags,
  )
  [
    compressed[0],
    compressed[1],
    compressed[2],
    compressed[3],
    compressed[4],
    compressed[5],
    compressed[6],
    compressed[7],
  ]
}

///|
fn blake3_output_root_bytes(output : Blake3Output) -> Bytes {
  let compressed = blake3_compress(
    output.input_chaining_value,
    output.block_words,
    output.counter,
    output.block_len,
    output.flags | BLAKE3_ROOT,
  )
  Bytes::makei(32, i => {
    let word = compressed[i / 4]
    ((word >> (i % 4 * 8)) & 0xFFU).to_byte()
  })
}

///|
fn blake3_chunk_output(
  input : Bytes,
  chunk_offset : Int,
  chunk_len : Int,
  chunk_counter : UInt64,
) -> Blake3Output {
  let chunk_end = chunk_offset + chunk_len
  let mut chaining_value = blake3_iv()
  let mut offset = chunk_offset
  while offset + BLAKE3_BLOCK_LEN < chunk_end {
    let block_words = blake3_block_words(input, offset, BLAKE3_BLOCK_LEN)
    let flags = if offset == chunk_offset { BLAKE3_CHUNK_START } else { 0U }
    chaining_value = blake3_output_chaining_value({
      input_chaining_value: chaining_value,
      block_words,
      counter: chunk_counter,
      block_len: BLAKE3_BLOCK_LEN.reinterpret_as_uint(),
      flags,
    })
    offset = offset + BLAKE3_BLOCK_LEN
  }
  let block_len = chunk_end - offset
  let block_words = blake3_block_words(input, offset, block_len)
  let mut flags = BLAKE3_CHUNK_END
  if offset == chunk_offset {
    flags = flags | BLAKE3_CHUNK_START
  }
  {
    input_chaining_value: chaining_value,
    block_words,
    counter: chunk_counter,
    block_len: block_len.reinterpret_as_uint(),
    flags,
  }
}

///|
fn blake3_parent_block_words(
  left_child : Array[UInt],
  right_child : Array[UInt],
) -> Array[UInt] {
  [
    left_child[0],
    left_child[1],
    left_child[2],
    left_child[3],
    left_child[4],
    left_child[5],
    left_child[6],
    left_child[7],
    right_child[0],
    right_child[1],
    right_child[2],
    right_child[3],
    right_child[4],
    right_child[5],
    right_child[6],
    right_child[7],
  ]
}

///|
fn blake3_parent_output(
  left_child : Array[UInt],
  right_child : Array[UInt],
) -> Blake3Output {
  {
    input_chaining_value: blake3_iv(),
    block_words: blake3_parent_block_words(left_child, right_child),
    counter: 0UL,
    block_len: BLAKE3_BLOCK_LEN.reinterpret_as_uint(),
    flags: BLAKE3_PARENT,
  }
}

///|
fn blake3_parent_chaining_value(
  left_child : Array[UInt],
  right_child : Array[UInt],
) -> Array[UInt] {
  blake3_output_chaining_value(blake3_parent_output(left_child, right_child))
}

///|
fn blake3_add_chunk_chaining_value(
  stack : Array[Array[UInt]],
  chunk_chaining_value : Array[UInt],
  total_chunks : Int,
) -> Unit {
  let mut cv = chunk_chaining_value
  let mut chunk_count = total_chunks
  while (chunk_count & 1) == 0 {
    let left = stack[stack.length() - 1]
    ignore(stack.pop())
    cv = blake3_parent_chaining_value(left, cv)
    chunk_count = chunk_count / 2
  }
  stack.push(cv)
}

///|
fn blake3_root_hash(input : Bytes) -> Bytes {
  let len = input.length()
  if len <= BLAKE3_CHUNK_LEN {
    return blake3_output_root_bytes(blake3_chunk_output(input, 0, len, 0UL))
  }

  let stack : Array[Array[UInt]] = []
  let mut offset = 0
  let mut chunk_counter = 0
  while offset < len {
    let remaining = len - offset
    let chunk_len = if remaining > BLAKE3_CHUNK_LEN {
      BLAKE3_CHUNK_LEN
    } else {
      remaining
    }
    let chunk_output = blake3_chunk_output(
      input,
      offset,
      chunk_len,
      chunk_counter.to_uint64(),
    )
    blake3_add_chunk_chaining_value(
      stack,
      blake3_output_chaining_value(chunk_output),
      chunk_counter + 1,
    )
    chunk_counter = chunk_counter + 1
    offset = offset + chunk_len
  }

  let mut right_child = stack[stack.length() - 1]
  ignore(stack.pop())
  while stack.length() > 0 {
    let left_child = stack[stack.length() - 1]
    ignore(stack.pop())
    let output = blake3_parent_output(left_child, right_child)
    if stack.length() == 0 {
      return blake3_output_root_bytes(output)
    }
    right_child = blake3_output_chaining_value(output)
  }

  Bytes::new(0)
}

///|
fn animation_target_uuid_pair_from_sha1_bytes(
  digest : Bytes,
) -> (UInt64, UInt64) {
  let uuid_bytes : Array[Byte] = []
  for i in 0..<16 {
    uuid_bytes.push(digest[i])
  }
  uuid_bytes[6] = ((uuid_bytes[6].to_uint() & 0x0FU) | 0x50U).to_byte()
  uuid_bytes[8] = ((uuid_bytes[8].to_uint() & 0x3FU) | 0x80U).to_byte()
  let mut high = 0UL
  let mut low = 0UL
  for i in 0..<8 {
    high = (high << 8) | uuid_bytes[i].to_uint64()
  }
  for i in 8..<16 {
    low = (low << 8) | uuid_bytes[i].to_uint64()
  }
  (high, low)
}

///|
fn animation_target_id_input(names : Array[String]) -> Bytes {
  let out : Array[Byte] = []
  for byte in animation_target_namespace_bytes {
    out.push(byte)
  }
  for name in names {
    let encoded = @utf8.encode(name[:])
    let len_bytes = encoded.length().to_uint64().to_le_bytes()
    for byte in len_bytes {
      out.push(byte)
    }
    for byte in encoded {
      out.push(byte)
    }
  }
  Bytes::from_array(out)
}

///|
fn animation_target_id_from_u64_pair(
  high : UInt64,
  low : UInt64,
) -> AnimationTargetId {
  AnimationTargetId::{ high, low }
}

///|
pub struct AnimationTargetId {
  high : UInt64
  low : UInt64
} derive(Eq, Debug)

///|
pub fn AnimationTargetId::new(high : Int, low : Int) -> AnimationTargetId {
  animation_target_id_from_u64_pair(high.to_uint64(), low.to_uint64())
}

///|
pub impl ToJson for AnimationTargetId with to_json(self) {
  (self.high, self.low).to_json()
}

///|
pub impl @json.FromJson for AnimationTargetId with from_json(json, path) {
  let (high, low) : (Int, Int) = @json.from_json(json, path~)
  AnimationTargetId::new(high, low)
}

///|
pub fn AnimationTargetId::from_names(
  names : Array[String],
) -> AnimationTargetId {
  let digest = blake3_root_hash(animation_target_id_input(names))
  let (high, low) = animation_target_uuid_pair_from_sha1_bytes(digest)
  animation_target_id_from_u64_pair(high, low)
}

///|
pub fn AnimationTargetId::from_iter(names : Array[String]) -> AnimationTargetId {
  AnimationTargetId::from_names(names)
}

///|
pub fn AnimationTargetId::from_name(name : String) -> AnimationTargetId {
  AnimationTargetId::from_names([name])
}

///|
fn animation_target_id_lookup_key(target_id : AnimationTargetId) -> UInt64 {
  target_id.high ^ target_id.low
}

///|
pub fn animation_target_id_for_name(name : String) -> AnimationTargetId {
  AnimationTargetId::from_name(name)
}

///|
pub fn animation_target_id_for_names(
  names : Array[String],
) -> AnimationTargetId {
  AnimationTargetId::from_names(names)
}

///|
pub fn animation_target_id_for_iter(names : Array[String]) -> AnimationTargetId {
  AnimationTargetId::from_iter(names)
}
