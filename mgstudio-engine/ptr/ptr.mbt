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
/// Pointer boundary aligned with Bevy's `bevy_ptr` crate.
/// MoonBit pointer-like semantics are mapped to `Ref[T]`.

///|
pub type Ptr[T] = Ref[T]

///|
pub type PtrMut[T] = Ref[T]

///|
pub fn[T] ptr(value : T) -> Ptr[T] {
  Ref::new(value)
}

///|
pub fn[T] read(ptr : Ptr[T]) -> T {
  ptr.val
}

///|
pub fn[T] write(ptr : PtrMut[T], value : T) -> Unit {
  ptr.val = value
}
