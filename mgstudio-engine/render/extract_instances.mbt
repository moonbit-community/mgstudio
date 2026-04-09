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
// Bevy source: `bevy/crates/bevy_render/src/extract_instances.rs`.

///|
pub struct ExtractedInstances[EI] {
  mut items : Array[EI]
}

///|
pub fn[EI] ExtractedInstances::new() -> ExtractedInstances[EI] {
  ExtractedInstances::{ items: [] }
}

///|
pub fn[EI] ExtractedInstances::len(self : ExtractedInstances[EI]) -> Int {
  self.items.length()
}

///|
pub fn[EI] ExtractedInstances::clear(self : ExtractedInstances[EI]) -> Unit {
  self.items = []
}

///|
pub fn[EI] ExtractedInstances::push(
  self : ExtractedInstances[EI],
  instance : EI,
) -> Unit {
  self.items.push(instance)
}

///|
pub fn[EI] ExtractedInstances::items(
  self : ExtractedInstances[EI],
) -> Array[EI] {
  self.items
}

///|
pub fn[EI] extract_all(instances : Array[EI]) -> ExtractedInstances[EI] {
  let extracted = ExtractedInstances::new()
  for instance in instances {
    extracted.push(instance)
  }
  extracted
}

///|
pub fn[EI] extract_visible(
  instances : Array[EI],
  visible : Array[Bool],
) -> ExtractedInstances[EI] {
  let extracted = ExtractedInstances::new()
  let limit = if instances.length() < visible.length() {
    instances.length()
  } else {
    visible.length()
  }
  for index in 0..<limit {
    if visible[index] {
      extracted.push(instances[index])
    }
  }
  extracted
}

///|
pub fn extract_instances_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_plugin(app)
}
