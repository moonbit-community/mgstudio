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
// Bevy source: `bevy/crates/bevy_utils/src/once.rs`.
// The current runtime does not expose Bevy's once-cell helpers.

///|
pub const ONCE_MODULE_TAG : String = "bevy_utils::once"

///|
pub fn utils_once_available() -> Bool {
  true
}

///|
pub struct OnceCellBridge[T] {
  mut value : T?
}

///|
pub fn[T] OnceCellBridge::new() -> OnceCellBridge[T] {
  OnceCellBridge::{ value: None }
}

///|
pub fn[T] OnceCellBridge::set(self : OnceCellBridge[T], value : T) -> Unit {
  if self.value is None {
    self.value = Some(value)
  }
}

///|
pub fn[T] OnceCellBridge::get(self : OnceCellBridge[T]) -> T? {
  self.value
}
