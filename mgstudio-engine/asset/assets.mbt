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
pub struct Assets[T] {
  items : Array[T]
}

///|
pub fn[T] Assets::new() -> Assets[T] {
  Assets::{ items: [] }
}

///|
pub fn[T] Assets::len(self : Assets[T]) -> Int {
  self.items.length()
}

///|
pub fn[T] Assets::add(self : Assets[T], value : T) -> Handle[T] {
  let id = self.items.length()
  self.items.push(value)
  Handle::new(id)
}

///|
pub fn[T] Assets::get(self : Assets[T], handle : Handle[T]) -> T? {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    None
  } else {
    Some(self.items[id])
  }
}

///|
pub fn[T] Assets::set(self : Assets[T], handle : Handle[T], value : T) -> Bool {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    false
  } else {
    self.items[id] = value
    true
  }
}
