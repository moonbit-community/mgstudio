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
// Bevy source: `bevy/crates/bevy_ptr/src/lib.rs`.
// Crate-root pointer surface.
pub const PTR_CRATE_ID : String = "bevy_ptr"

///|
pub fn[T] bevy_ptr_default(value : T) -> Ptr[T] {
  ptr(value)
}

///|
pub fn[T] bevy_ptr_lib(value : T) -> Ptr[T] {
  ptr(value)
}
