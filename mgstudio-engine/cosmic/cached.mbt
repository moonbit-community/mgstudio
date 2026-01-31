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
/// Ported from `cosmic-text/src/cached.rs` (cosmic-text is dual-licensed MIT OR Apache-2.0).
///
/// MoonBit version is implemented in a functional style (returns updated Cached),
/// but keeps the same state machine semantics as the upstream `&mut self` API.
pub(all) enum Cached[T] {
  Empty
  Unused(T)
  Used(T)
}

///|
pub fn[T] Cached::get(self : Cached[T]) -> T? {
  match self {
    Used(v) => Some(v)
    _ => None
  }
}

///|
pub fn[T] Cached::is_unused(self : Cached[T]) -> Bool {
  match self {
    Empty | Unused(_) => true
    Used(_) => false
  }
}

///|
pub fn[T] Cached::is_used(self : Cached[T]) -> Bool {
  match self {
    Used(_) => true
    _ => false
  }
}

///|
pub fn[T] Cached::take_unused(self : Cached[T]) -> (Cached[T], T?) {
  match self {
    Unused(v) => (Empty, Some(v))
    _ => (self, None)
  }
}

///|
pub fn[T] Cached::take_used(self : Cached[T]) -> (Cached[T], T?) {
  match self {
    Used(v) => (Empty, Some(v))
    _ => (self, None)
  }
}

///|
pub fn[T] Cached::set_unused(self : Cached[T]) -> Cached[T] {
  match self {
    Used(v) => Unused(v)
    _ => self
  }
}

///|
pub fn[T] Cached::set_used(_self : Cached[T], val : T) -> Cached[T] {
  Used(val)
}
