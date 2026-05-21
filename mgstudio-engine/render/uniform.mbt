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
// Bevy source: `bevy/crates/bevy_render/src/uniform.rs`.
//
// `DynamicUniformIndex` and `ComponentUniforms` are still owned by
// `render/extract_component.mbt` in mgstudio until the Bevy owner split is
// fully collapsed into this file.

///|
pub struct UniformComponentPluginState {
  component_debug_name : String
  prepared_count : Int
} derive(Eq, Debug)

///|
pub fn UniformComponentPluginState::new(
  component_debug_name : String,
) -> UniformComponentPluginState {
  UniformComponentPluginState::{ component_debug_name, prepared_count: 0 }
}

///|
pub fn UniformComponentPluginState::component_debug_name(
  self : UniformComponentPluginState,
) -> String {
  self.component_debug_name
}

///|
pub fn UniformComponentPluginState::prepared_count(
  self : UniformComponentPluginState,
) -> Int {
  self.prepared_count
}

///|
pub fn uniform_component_prepare_indices(component_count : Int) -> Array[UInt] {
  if component_count < 0 {
    abort("uniform component count must be non-negative")
  }
  let indices : Array[UInt] = []
  for i in 0..<component_count {
    indices.push(i.reinterpret_as_uint())
  }
  indices
}
