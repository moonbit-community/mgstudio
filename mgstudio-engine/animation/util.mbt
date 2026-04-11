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
// Bevy source: `bevy/crates/bevy_animation/src/util.rs`.
// Bevy-aligned animation target id utilities and hashing.

///|
const ANIMATION_TARGET_NAMESPACE : String = "bevy_animation_target"

///|
const HASH_A_OFFSET : UInt = 0x811C9DC5U

///|
const HASH_A_PRIME : UInt = 0x01000193U

///|
const HASH_B_OFFSET : UInt = 0x9E3779B9U

///|
const HASH_B_PRIME : UInt = 0x85EBCA6BU

///|
pub type AnimationMask = UInt

///|
fn animation_hash_update(hash : UInt, byte : Int, prime : UInt) -> UInt {
  (hash ^ (byte & 0xFF).reinterpret_as_uint()) * prime
}

///|
fn animation_hash_update_len(hash : UInt, len : Int, prime : UInt) -> UInt {
  let value = len.reinterpret_as_uint()
  let b0 = (value & 0xFFU).reinterpret_as_int()
  let b1 = ((value >> 8) & 0xFFU).reinterpret_as_int()
  let b2 = ((value >> 16) & 0xFFU).reinterpret_as_int()
  let b3 = ((value >> 24) & 0xFFU).reinterpret_as_int()
  let h0 = animation_hash_update(hash, b0, prime)
  let h1 = animation_hash_update(h0, b1, prime)
  let h2 = animation_hash_update(h1, b2, prime)
  animation_hash_update(h2, b3, prime)
}

///|
fn animation_hash_namespace() -> (UInt, UInt) {
  let mut a = HASH_A_OFFSET
  let mut b = HASH_B_OFFSET
  let n = ANIMATION_TARGET_NAMESPACE.length()
  for i in 0..<n {
    let code = ANIMATION_TARGET_NAMESPACE.code_unit_at(i).to_int()
    a = animation_hash_update(a, code, HASH_A_PRIME)
    b = animation_hash_update(b, code, HASH_B_PRIME)
  }
  (a, b)
}

///|
fn animation_hash_names(names : Array[String]) -> (UInt, UInt) {
  let mut state = animation_hash_namespace()
  for name in names {
    let len = name.length()
    let a0 = animation_hash_update_len(state.0, len, HASH_A_PRIME)
    let b0 = animation_hash_update_len(state.1, len, HASH_B_PRIME)
    let mut a = a0
    let mut b = b0
    for i in 0..<len {
      let code = name.code_unit_at(i).to_int()
      a = animation_hash_update(a, code, HASH_A_PRIME)
      b = animation_hash_update(b, code, HASH_B_PRIME)
    }
    state = (a, b)
  }
  state
}

///|
pub struct AnimationTargetId {
  high : Int
  low : Int
} derive(Eq, Debug)

///|
pub fn AnimationTargetId::new(high : Int, low : Int) -> AnimationTargetId {
  AnimationTargetId::{ high, low }
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
  let (high, low) = animation_hash_names(names)
  AnimationTargetId::new(high.reinterpret_as_int(), low.reinterpret_as_int())
}

///|
pub fn AnimationTargetId::from_iter(
  names : Array[String],
) -> AnimationTargetId {
  AnimationTargetId::from_names(names)
}

///|
pub fn AnimationTargetId::from_name(name : String) -> AnimationTargetId {
  AnimationTargetId::from_names([name])
}

///|
fn animation_target_id_lookup_key(target_id : AnimationTargetId) -> UInt64 {
  let high = target_id.high.reinterpret_as_uint().to_uint64()
  let low = target_id.low.reinterpret_as_uint().to_uint64()
  (high << 32) | low
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
pub fn animation_target_id_for_iter(
  names : Array[String],
) -> AnimationTargetId {
  AnimationTargetId::from_iter(names)
}
