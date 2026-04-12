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
// Bevy source: `bevy/crates/bevy_utils/src/atomic_id.rs`.

///|
let atomic_id_counter : Ref[UInt] = Ref::new(1U)

///|
pub fn atomic_id_next() -> Int {
  let next = atomic_id_counter.val
  let advanced = next + 1U
  if advanced == 0U {
    abort("The system ran out of unique atomic ids.")
  }
  atomic_id_counter.val = advanced
  next.reinterpret_as_int()
}

///|
pub fn atomic_id_next_non_zero_u32() -> UInt {
  atomic_id_next().reinterpret_as_uint()
}
