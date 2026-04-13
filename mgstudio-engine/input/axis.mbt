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
// Bevy source: `bevy/crates/bevy_input/src/axis.rs`.

///|
pub fn[T] axis_new() -> Axis[T] {
  Axis::new()
}

///|
pub fn[T : Eq] axis_set(
  axis : Axis[T],
  input_device : T,
  value : Float,
) -> Float? {
  axis.set(input_device, value)
}

///|
pub fn[T : Eq] axis_get(axis : Axis[T], input_device : T) -> Float? {
  axis.get(input_device)
}

///|
pub fn[T : Eq] axis_get_unclamped(axis : Axis[T], input_device : T) -> Float? {
  axis.get_unclamped(input_device)
}

///|
pub fn[T : Eq] axis_remove(axis : Axis[T], input_device : T) -> Float? {
  axis.remove(input_device)
}

///|
pub fn[T] axis_all(axis : Axis[T]) -> Array[T] {
  axis.all_axes()
}
