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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/specializer.rs`.

///|
pub struct Specializer[T] {
  key : T
  label : String
}

///|
pub fn[T] Specializer::new(key : T, label : String) -> Specializer[T] {
  Specializer::{ key, label }
}

///|
pub fn[T] Specializer::key(self : Specializer[T]) -> T {
  self.key
}

///|
pub fn[T] Specializer::label(self : Specializer[T]) -> String {
  self.label
}
