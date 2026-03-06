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
let start_ms_ref : Ref[UInt64?] = Ref::new(None)

///|
pub fn now() -> Float {
  let now_ms = @env.now()
  match start_ms_ref.val {
    Some(start_ms) =>
      if now_ms >= start_ms {
        Float::from_uint64(now_ms - start_ms) / 1000.0F
      } else {
        0.0F
      }
    None => {
      start_ms_ref.val = Some(now_ms)
      0.0F
    }
  }
}
