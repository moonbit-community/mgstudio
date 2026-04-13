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
// Bevy source: `bevy/crates/bevy_render/src/extract_component.rs`.

///|
pub struct DynamicUniformIndex[_] {
  index : UInt
}

///|
pub fn[C] DynamicUniformIndex::new(index : UInt) -> DynamicUniformIndex[C] {
  DynamicUniformIndex::{ index, }
}

///|
pub fn[C] DynamicUniformIndex::index(self : DynamicUniformIndex[C]) -> UInt {
  self.index
}

///|
pub struct ComponentUniforms[C] {
  uniforms : Array[C]
}

///|
pub fn[C] ComponentUniforms::default() -> ComponentUniforms[C] {
  ComponentUniforms::{ uniforms: [] }
}

///|
pub fn[C] ComponentUniforms::push(
  self : ComponentUniforms[C],
  component : C,
) -> Unit {
  self.uniforms.push(component)
}

///|
pub fn[C] ComponentUniforms::len(self : ComponentUniforms[C]) -> Int {
  self.uniforms.length()
}

///|
pub struct ExtractComponentPlugin[_, _] {
  only_extract_visible : Bool
}

///|
pub fn[C, F] ExtractComponentPlugin::default() -> ExtractComponentPlugin[C, F] {
  ExtractComponentPlugin::{ only_extract_visible: false }
}

///|
pub fn[C, F] ExtractComponentPlugin::extract_visible() -> ExtractComponentPlugin[
  C,
  F,
] {
  ExtractComponentPlugin::{ only_extract_visible: true }
}

///|
pub fn[C, F] extract_component_only_extract_visible(
  plugin : ExtractComponentPlugin[C, F],
) -> Bool {
  plugin.only_extract_visible
}

///|
pub fn extract_component_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_plugin(app)
}

///|
pub fn extract_component_source_world(world : @ecs.World) -> @ecs.World {
  render_source_world(world)
}
