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
// Bevy source: `bevy/crates/bevy_render/src/render_resource/pipeline_specializer.rs`.

///|
pub struct PipelineSpecializer[T] {
  entries : Array[Specializer[T]]
}

///|
pub fn[T] PipelineSpecializer::new() -> PipelineSpecializer[T] {
  PipelineSpecializer::{ entries: [] }
}

///|
pub fn[T] PipelineSpecializer::push(
  self : PipelineSpecializer[T],
  specializer : Specializer[T],
) -> Unit {
  self.entries.push(specializer)
}

///|
pub fn[T] PipelineSpecializer::len(self : PipelineSpecializer[T]) -> Int {
  self.entries.length()
}

///|
pub fn[T] PipelineSpecializer::entries(
  self : PipelineSpecializer[T],
) -> Array[Specializer[T]] {
  self.entries
}

///|
pub fn[T] PipelineSpecializer::find_label(
  self : PipelineSpecializer[T],
  label : String,
) -> Specializer[T]? {
  for specializer in self.entries {
    if specializer.label() == label {
      return Some(specializer)
    }
  }
  None
}
