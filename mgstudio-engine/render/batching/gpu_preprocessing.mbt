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
// Bevy source: `bevy/crates/bevy_render/src/batching/gpu_preprocessing.rs`.

///|
pub(all) enum GpuPreprocessingMode {
  None
  PreprocessingOnly
  Culling
} derive(Eq, Debug)

///|
pub struct GpuPreprocessingSupport {
  max_supported_mode : GpuPreprocessingMode
}

///|
pub fn GpuPreprocessingSupport::default() -> GpuPreprocessingSupport {
  GpuPreprocessingSupport::{ max_supported_mode: GpuPreprocessingMode::None }
}

///|
pub fn GpuPreprocessingSupport::is_available(
  self : GpuPreprocessingSupport,
) -> Bool {
  self.max_supported_mode != GpuPreprocessingMode::None
}

///|
pub fn GpuPreprocessingSupport::min(
  self : GpuPreprocessingSupport,
  mode : GpuPreprocessingMode,
) -> GpuPreprocessingMode {
  match (self.max_supported_mode, mode) {
    (GpuPreprocessingMode::None, _) | (_, GpuPreprocessingMode::None) =>
      GpuPreprocessingMode::None
    (GpuPreprocessingMode::Culling, other) => other
    (other, GpuPreprocessingMode::Culling) => other
    _ => GpuPreprocessingMode::PreprocessingOnly
  }
}

///|
pub fn GpuPreprocessingSupport::is_culling_supported(
  self : GpuPreprocessingSupport,
) -> Bool {
  self.max_supported_mode == GpuPreprocessingMode::Culling
}

///|
pub struct BatchedInstanceBuffers[BD, BDI] {
  current_input_buffer : @render_resource.GpuArrayBuffer[BDI]
  previous_input_buffer : @render_resource.GpuArrayBuffer[BDI]
  phase_instance_buffers : @hashmap.HashMap[
    String,
    PhaseBatchedInstanceBuffers[BD],
  ]
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::new() -> BatchedInstanceBuffers[BD, BDI] {
  BatchedInstanceBuffers::{
    current_input_buffer: @render_resource.GpuArrayBuffer::new(),
    previous_input_buffer: @render_resource.GpuArrayBuffer::new(),
    phase_instance_buffers: @hashmap.HashMap::new(),
  }
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::clear(
  self : BatchedInstanceBuffers[BD, BDI],
) -> Unit {
  self.current_input_buffer.clear()
  self.previous_input_buffer.clear()
  self.phase_instance_buffers.clear()
}

///|
pub fn[BD, BDI] BatchedInstanceBuffers::swap_input_buffers(
  self : BatchedInstanceBuffers[BD, BDI],
) -> Unit {
  self.previous_input_buffer.clear()
  for value in self.current_input_buffer.values() {
    self.previous_input_buffer.push(value)
  }
  self.current_input_buffer.clear()
}

///|
pub struct UntypedPhaseBatchedInstanceBuffers[BD] {
  values : @render_resource.GpuArrayBuffer[BD]
}

///|
pub fn[BD] UntypedPhaseBatchedInstanceBuffers::new() -> UntypedPhaseBatchedInstanceBuffers[
  BD,
] {
  UntypedPhaseBatchedInstanceBuffers::{
    values: @render_resource.GpuArrayBuffer::new(),
  }
}

///|
pub struct PhaseBatchedInstanceBuffers[BD] {
  buffers : UntypedPhaseBatchedInstanceBuffers[BD]
  mut marker : Int
}

///|
pub fn[BD] PhaseBatchedInstanceBuffers::new() -> PhaseBatchedInstanceBuffers[BD] {
  PhaseBatchedInstanceBuffers::{
    buffers: UntypedPhaseBatchedInstanceBuffers::new(),
    marker: 0,
  }
}

///|
pub fn[BD] PhaseBatchedInstanceBuffers::clear(
  self : PhaseBatchedInstanceBuffers[BD],
) -> Unit {
  self.buffers.values.clear()
  self.marker = 0
}

///|
pub struct GpuPreprocessingPlugin {
  mode : GpuPreprocessingMode
}

///|
pub fn GpuPreprocessingPlugin::default() -> GpuPreprocessingPlugin {
  GpuPreprocessingPlugin::{ mode: GpuPreprocessingMode::Culling }
}

///|
pub fn GpuPreprocessingPlugin::with_mode(
  mode : GpuPreprocessingMode,
) -> GpuPreprocessingPlugin {
  GpuPreprocessingPlugin::{ mode, }
}

///|
let gpu_preprocessing_support_resource_key : @ecs.ResourceKey[
  GpuPreprocessingSupport,
] = @ecs.register_resource(debug_name="bevy_render::GpuPreprocessingSupport")

///|
pub impl @app.Resource for GpuPreprocessingSupport with resource() {
  gpu_preprocessing_support_resource_key
}

///|
pub fn gpu_preprocessing_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  gpu_preprocessing_plugin_with(app, GpuPreprocessingPlugin::default())
}

///|
pub fn gpu_preprocessing_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GpuPreprocessingPlugin,
) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(gpu_preprocessing_support_resource_key) {
    next = next.insert_world_resource(gpu_preprocessing_support_resource_key, GpuPreprocessingSupport::{
      max_supported_mode: plugin.mode,
    })
  }
  next
}
