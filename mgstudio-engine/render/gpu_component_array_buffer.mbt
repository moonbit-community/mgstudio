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
// Bevy source: `bevy/crates/bevy_render/src/gpu_component_array_buffer.rs`.

///|
const GPU_COMPONENT_ARRAY_BUFFER_PLUGIN_NAME : String = "mgstudio.render.GpuComponentArrayBufferPlugin"

///|
pub struct GpuComponentArrayBufferPlugin[_] {}

///|
pub fn[C] GpuComponentArrayBufferPlugin::default() -> GpuComponentArrayBufferPlugin[
  C,
] {
  GpuComponentArrayBufferPlugin::{  }
}

///|
pub impl[C] @app.Plugin for GpuComponentArrayBufferPlugin[C] with name(_self) {
  GPU_COMPONENT_ARRAY_BUFFER_PLUGIN_NAME
}

///|
pub impl[C] @app.Plugin for GpuComponentArrayBufferPlugin[C] with build(
  self,
  app,
) {
  gpu_component_array_buffer_plugin(app, _plugin=self)
}

///|
pub struct GpuComponentArrayBufferState[C] {
  buffer : @render_resource.GpuArrayBuffer[C]
  indices : Map[UInt64, UInt]
}

///|
pub fn[C] GpuComponentArrayBufferState::new() -> GpuComponentArrayBufferState[C] {
  GpuComponentArrayBufferState::{
    buffer: @render_resource.GpuArrayBuffer::new(),
    indices: {},
  }
}

///|
pub fn[C] GpuComponentArrayBufferState::clear(
  self : GpuComponentArrayBufferState[C],
) -> Unit {
  self.buffer.clear()
  self.indices.clear()
}

///|
pub fn[C] GpuComponentArrayBufferState::buffer(
  self : GpuComponentArrayBufferState[C],
) -> @render_resource.GpuArrayBuffer[C] {
  self.buffer
}

///|
pub fn[C] GpuComponentArrayBufferState::index(
  self : GpuComponentArrayBufferState[C],
  entity : @core.Entity,
) -> UInt? {
  self.indices.get(gpu_component_array_buffer_entity_key(entity))
}

///|
pub fn[C] gpu_component_array_buffer_state_key(
  debug_name? : String = "mgstudio_render::GpuComponentArrayBufferState",
) -> @ecs.ResourceKey[GpuComponentArrayBufferState[C]] {
  @ecs.register_resource(debug_name~)
}

///|
fn[C] gpu_component_array_buffer_state_ref(
  world : @ecs.World,
  state_key : @ecs.ResourceKey[GpuComponentArrayBufferState[C]],
) -> @ecs.ResourceMut[GpuComponentArrayBufferState[C]] {
  if (try! world.get_resource(state_key)) is None {
    world.insert_resource(state_key, GpuComponentArrayBufferState::new())
  }
  match (try! world.get_resource_mut(state_key)) {
    Some(state_ref) => state_ref
    None => abort("Missing GpuComponentArrayBufferState resource")
  }
}

///|
fn gpu_component_array_buffer_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
pub fn[C : @ecs.Component] prepare_gpu_component_array_buffers(
  world : @ecs.World,
  state_key : @ecs.ResourceKey[GpuComponentArrayBufferState[C]],
  component_key? : @ecs.ComponentKey[C] = C::component(),
) -> Unit {
  let state_ref = gpu_component_array_buffer_state_ref(world, state_key)
  ignore(
    state_ref.modify(fn(state) {
      state.clear()
      world.for_each_component(component_key, fn(entity, component) {
        let index = state.buffer.len().reinterpret_as_uint()
        state.buffer.push(component)
        state.indices.set(gpu_component_array_buffer_entity_key(entity), index)
      })
    }),
  )
}

///|
pub fn[C] gpu_component_array_buffer_plugin(
  app : @app.App[@ecs.World],
  _plugin? : GpuComponentArrayBufferPlugin[C] = GpuComponentArrayBufferPlugin::default(),
) -> @app.App[@ecs.World] {
  app
}
