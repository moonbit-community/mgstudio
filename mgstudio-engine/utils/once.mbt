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

///|
pub struct OnceFlag {
  mut should_fire : Bool
}

///|
pub fn OnceFlag::new() -> OnceFlag {
  OnceFlag::{ should_fire: true }
}

///|
pub fn OnceFlag::default() -> OnceFlag {
  OnceFlag::new()
}

///|
pub fn OnceFlag::set(self : OnceFlag) -> Bool {
  let should_fire = self.should_fire
  self.should_fire = false
  should_fire
}

///|
pub struct OnceCell[T] {
  mut value : T?
}

///|
pub fn[T] OnceCell::new() -> OnceCell[T] {
  OnceCell::{ value: None }
}

///|
pub fn[T] OnceCell::set(self : OnceCell[T], value : T) -> Unit {
  if self.value is None {
    self.value = Some(value)
  }
}

///|
pub fn[T] OnceCell::set_once(self : OnceCell[T], value : T) -> Bool {
  if self.value is None {
    self.value = Some(value)
    true
  } else {
    false
  }
}

///|
pub fn[T] OnceCell::get(self : OnceCell[T]) -> T? {
  self.value
}

///|
pub fn[T] OnceCell::get_or_init(self : OnceCell[T], init : () -> T) -> T {
  guard self.value is Some(value) else {
    let value = init()
    self.value = Some(value)
    return value
  }
  value
}
