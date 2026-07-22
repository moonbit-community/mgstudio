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

///|
const UNIFORM_COMPONENT_PLUGIN_NAME : String = "mgstudio.render.UniformComponentPlugin"

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
pub fn[C] ComponentUniforms::ComponentUniforms() -> ComponentUniforms[C] {
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
pub fn[C] ComponentUniforms::clear(self : ComponentUniforms[C]) -> Unit {
  self.uniforms.clear()
}

///|
pub fn[C] ComponentUniforms::get(
  self : ComponentUniforms[C],
  index : Int,
) -> C? {
  if index < 0 || index >= self.uniforms.length() {
    None
  } else {
    Some(self.uniforms[index])
  }
}

///|
pub fn[C] ComponentUniforms::len(self : ComponentUniforms[C]) -> Int {
  self.uniforms.length()
}

///|
pub struct UniformComponentKeys[C] {
  uniforms : @ecs.ResourceKey[ComponentUniforms[C]]
  dynamic_index : @ecs.ComponentKey[DynamicUniformIndex[C]]
}

///|
pub fn[C] register_uniform_component_keys(
  component_debug_name : String,
) -> UniformComponentKeys[C] {
  UniformComponentKeys::{
    uniforms: @ecs.register_resource(
      debug_name="mgstudio_render::ComponentUniforms<\{component_debug_name}>",
    ),
    dynamic_index: @ecs.register_component(
      debug_name="mgstudio_render::DynamicUniformIndex<\{component_debug_name}>",
    ),
  }
}

///|
pub(open) trait UniformComponent {
  fn uniform_component_debug_name() -> String
  fn uniform_component_keys() -> UniformComponentKeys[Self]
}

///|
pub fn[C : UniformComponent] ComponentUniforms::resource() -> @ecs.ResourceKey[
  ComponentUniforms[C],
] {
  C::uniform_component_keys().uniforms
}

///|
pub impl[C : UniformComponent] @app.Resource for ComponentUniforms[C] with fn resource() {
  ComponentUniforms::resource()
}

///|
pub fn[C : UniformComponent] DynamicUniformIndex::component() -> @ecs.ComponentKey[
  DynamicUniformIndex[C],
] {
  C::uniform_component_keys().dynamic_index
}

///|
pub impl[C : UniformComponent] @ecs.Component for DynamicUniformIndex[C] with fn component() {
  DynamicUniformIndex::component()
}

///|
fn[C] prepare_uniform_components(
  world : @ecs.World,
  component_key : @ecs.ComponentKey[C],
  index_key : @ecs.ComponentKey[DynamicUniformIndex[C]],
  uniform_key : @ecs.ResourceKey[ComponentUniforms[C]],
) -> Unit {
  if world.get_resource(uniform_key) is None {
    world.insert_resource(uniform_key, ComponentUniforms::ComponentUniforms())
  }
  let entries : Array[(@core.Entity, C)] = []
  world.for_each_component(component_key, fn(entity, component) {
    entries.push((entity, component))
  })
  match world.get_resource_mut(uniform_key) {
    Some(uniforms) =>
      uniforms.modify(fn(value) {
        value.clear()
        for entry in entries {
          value.push(entry.1)
        }
      })
    None => abort("uniform_component: missing ComponentUniforms resource")
  }
  for index = 0; index < entries.length(); index = index + 1 {
    try! world.set_by_key(
      entries[index].0,
      index_key,
      DynamicUniformIndex::new(index.reinterpret_as_uint()),
    )
  }
}

///|
pub struct UniformComponentPlugin[_] {}

///|
pub fn[C] UniformComponentPlugin::UniformComponentPlugin() -> UniformComponentPlugin[
  C,
] {
  UniformComponentPlugin::{  }
}

///|
pub impl[C : @ecs.Component + UniformComponent] @app.Plugin for UniformComponentPlugin[
  C,
] with fn name(_self) {
  UNIFORM_COMPONENT_PLUGIN_NAME
}

///|
pub impl[C : @ecs.Component + UniformComponent] @app.Plugin for UniformComponentPlugin[
  C,
] with fn build(self, app) {
  uniform_component_plugin_with(app, self)
}

///|
fn[C : UniformComponent] uniform_component_debug_name_for_key(
  _key : @ecs.ComponentKey[C],
) -> String {
  C::uniform_component_debug_name()
}

///|
pub fn[C : @ecs.Component + UniformComponent] uniform_component_plugin_with(
  app : @app.App[@ecs.World],
  plugin : UniformComponentPlugin[C],
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let uniform_key : @ecs.ResourceKey[ComponentUniforms[C]] = ComponentUniforms::resource()
  let component_key : @ecs.ComponentKey[C] = @ecs.Component::component()
  let index_key : @ecs.ComponentKey[DynamicUniformIndex[C]] = DynamicUniformIndex::component()
  try_with_render_app(app, fn(render_app : @app.SubApp[@ecs.World]) {
    if render_app.world().get_resource(uniform_key) is None {
      render_app
      .world()
      .insert_resource(uniform_key, ComponentUniforms::ComponentUniforms())
    }
    render_app.add_systems(
      render_schedule_stage(),
      @app.system(fn(world : @ecs.World) -> Unit {
        prepare_uniform_components(world, component_key, index_key, uniform_key)
      })
      .named(
        "mgstudio_render::uniform::prepare_uniform_components<\{uniform_component_debug_name_for_key(component_key)}>",
      )
      .in_set(render_system_set_prepare_resources),
    )
  })
}
