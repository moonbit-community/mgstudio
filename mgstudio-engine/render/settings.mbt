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
// Bevy source: `bevy/crates/bevy_render/src/settings.rs`.

///|
pub(all) enum WgpuSettingsPriority {
  Compatibility
  Functionality
  WebGL2
} derive(Eq, Debug)

///|
pub fn WgpuSettingsPriority::default() -> WgpuSettingsPriority {
  Functionality
}

///|
pub struct WgpuSettings {
  device_label : String?
  backends : String?
  power_preference : String
  priority : WgpuSettingsPriority
  features_mask : UInt64
  disabled_features_mask : UInt64
  limits_profile : String
  constrained_limits_profile : String?
  force_fallback_adapter : Bool
  adapter_name : String?
} derive(Eq, Debug)

///|
pub fn WgpuSettings::default() -> WgpuSettings {
  WgpuSettings::{
    device_label: None,
    backends: Some("all"),
    power_preference: "high_performance",
    priority: Functionality,
    features_mask: 0UL,
    disabled_features_mask: 0UL,
    limits_profile: "default",
    constrained_limits_profile: None,
    force_fallback_adapter: false,
    adapter_name: None,
  }
}

///|
pub fn WgpuSettings::with_priority(
  self : WgpuSettings,
  priority : WgpuSettingsPriority,
) -> WgpuSettings {
  WgpuSettings::{ ..self, priority, }
}

///|
pub fn WgpuSettings::with_backends(
  self : WgpuSettings,
  backends : String?,
) -> WgpuSettings {
  WgpuSettings::{ ..self, backends, }
}

///|
pub fn WgpuSettings::with_power_preference(
  self : WgpuSettings,
  power_preference : String,
) -> WgpuSettings {
  WgpuSettings::{ ..self, power_preference, }
}

///|
pub fn WgpuSettings::with_adapter_name(
  self : WgpuSettings,
  adapter_name : String?,
) -> WgpuSettings {
  WgpuSettings::{ ..self, adapter_name, }
}

///|
pub fn WgpuSettings::with_force_fallback_adapter(
  self : WgpuSettings,
  force_fallback_adapter : Bool,
) -> WgpuSettings {
  WgpuSettings::{ ..self, force_fallback_adapter, }
}

///|
pub struct RenderResources {
  device : @renderer.RenderDevice
  queue : @renderer.RenderQueue
  adapter_info : @renderer.RenderAdapterInfo
  render_adapter : @renderer.RenderAdapter
  instance : @renderer.RenderInstance
}

///|
pub fn RenderResources::new(
  device : @renderer.RenderDevice,
  queue : @renderer.RenderQueue,
  adapter_info : @renderer.RenderAdapterInfo,
  render_adapter : @renderer.RenderAdapter,
  instance : @renderer.RenderInstance,
) -> RenderResources {
  RenderResources::{ device, queue, adapter_info, render_adapter, instance }
}

///|
pub fn RenderResources::from_backend(
  backend : @renderer.GpuBackend,
) -> RenderResources {
  RenderResources::new(
    @renderer.RenderDevice::from_backend(backend),
    @renderer.RenderQueue::from_backend(backend),
    @renderer.RenderAdapterInfo::from_backend(backend),
    @renderer.RenderAdapter::from_backend(backend),
    @renderer.RenderInstance::from_backend(backend),
  )
}

///|
pub fn RenderResources::device(
  self : RenderResources,
) -> @renderer.RenderDevice {
  self.device
}

///|
pub fn RenderResources::queue(self : RenderResources) -> @renderer.RenderQueue {
  self.queue
}

///|
pub fn RenderResources::adapter_info(
  self : RenderResources,
) -> @renderer.RenderAdapterInfo {
  self.adapter_info
}

///|
pub fn RenderResources::render_adapter(
  self : RenderResources,
) -> @renderer.RenderAdapter {
  self.render_adapter
}

///|
pub fn RenderResources::instance(
  self : RenderResources,
) -> @renderer.RenderInstance {
  self.instance
}

///|
let ecs_key_render_device_resource : @ecs.ResourceKey[@renderer.RenderDevice] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderDevice",
)

///|
let ecs_key_render_queue_resource : @ecs.ResourceKey[@renderer.RenderQueue] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderQueue",
)

///|
let ecs_key_render_adapter_info_resource : @ecs.ResourceKey[
  @renderer.RenderAdapterInfo,
] = @ecs.register_resource(debug_name="mgstudio_render::RenderAdapterInfo")

///|
let ecs_key_render_adapter_resource : @ecs.ResourceKey[@renderer.RenderAdapter] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderAdapter",
)

///|
let ecs_key_render_instance_resource : @ecs.ResourceKey[
  @renderer.RenderInstance,
] = @ecs.register_resource(debug_name="mgstudio_render::RenderInstance")

///|
let ecs_key_pipeline_cache_resource : @ecs.ResourceKey[
  @render_resource.PipelineCache,
] = @ecs.register_resource(debug_name="mgstudio_render::PipelineCache")

///|
let ecs_key_pending_command_buffers_resource : @ecs.ResourceKey[
  @renderer.PendingCommandBuffers,
] = @ecs.register_resource(debug_name="mgstudio_render::PendingCommandBuffers")

///|
pub fn render_device_resource_key() -> @ecs.ResourceKey[@renderer.RenderDevice] {
  ecs_key_render_device_resource
}

///|
pub fn render_queue_resource_key() -> @ecs.ResourceKey[@renderer.RenderQueue] {
  ecs_key_render_queue_resource
}

///|
pub fn render_adapter_info_resource_key() -> @ecs.ResourceKey[
  @renderer.RenderAdapterInfo,
] {
  ecs_key_render_adapter_info_resource
}

///|
pub fn render_adapter_resource_key() -> @ecs.ResourceKey[
  @renderer.RenderAdapter,
] {
  ecs_key_render_adapter_resource
}

///|
pub fn render_instance_resource_key() -> @ecs.ResourceKey[
  @renderer.RenderInstance,
] {
  ecs_key_render_instance_resource
}

///|
pub fn pipeline_cache_resource_key() -> @ecs.ResourceKey[
  @render_resource.PipelineCache,
] {
  ecs_key_pipeline_cache_resource
}

///|
pub fn pending_command_buffers_resource_key() -> @ecs.ResourceKey[
  @renderer.PendingCommandBuffers,
] {
  ecs_key_pending_command_buffers_resource
}

///|
fn[T] render_world_resource_present(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
) -> Bool {
  match
    (try world.get_resource(key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(_) => true
    None => false
  }
}

///|
pub fn init_renderer_context_resources(world : @ecs.World) -> Unit {
  if !render_world_resource_present(
      world,
      pending_command_buffers_resource_key(),
    ) {
    world.insert_resource(
      pending_command_buffers_resource_key(),
      @renderer.PendingCommandBuffers::default(),
    )
  }
}

///|
pub fn flush_pending_command_buffers(world : @ecs.World) -> Unit {
  let pending = match
    (try world.get_resource(pending_command_buffers_resource_key()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => value
    None => return
  }
  let queue = match
    (try world.get_resource(render_queue_resource_key()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => value
    None => return
  }
  let buffers = pending.take()
  if buffers.length() > 0 {
    queue.submit(buffers)
  }
  world.insert_resource(pending_command_buffers_resource_key(), pending)
}

///|
pub fn RenderResources::unpack_into(
  self : RenderResources,
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  main_world.insert_resource(render_device_resource_key(), self.device)
  main_world.insert_resource(render_queue_resource_key(), self.queue)
  main_world.insert_resource(
    render_adapter_info_resource_key(),
    self.adapter_info,
  )
  main_world.insert_resource(render_adapter_resource_key(), self.render_adapter)

  render_world.insert_resource(render_instance_resource_key(), self.instance)
  render_world.insert_resource(
    pipeline_cache_resource_key(),
    @render_resource.PipelineCache::new(),
  )
  init_renderer_context_resources(render_world)
  render_world.insert_resource(render_device_resource_key(), self.device)
  render_world.insert_resource(render_queue_resource_key(), self.queue)
  render_world.insert_resource(
    render_adapter_resource_key(),
    self.render_adapter,
  )
  render_world.insert_resource(
    render_adapter_info_resource_key(),
    self.adapter_info,
  )
}

///|
pub(all) enum RenderCreation {
  Manual(RenderResources)
  Automatic(WgpuSettings)
}

///|
pub fn RenderCreation::manual(
  device : @renderer.RenderDevice,
  queue : @renderer.RenderQueue,
  adapter_info : @renderer.RenderAdapterInfo,
  render_adapter : @renderer.RenderAdapter,
  instance : @renderer.RenderInstance,
) -> RenderCreation {
  Manual(
    RenderResources::new(device, queue, adapter_info, render_adapter, instance),
  )
}

///|
pub fn RenderCreation::manual_resources(
  resources : RenderResources,
) -> RenderCreation {
  Manual(resources)
}

///|
pub fn RenderCreation::automatic(settings : WgpuSettings) -> RenderCreation {
  Automatic(settings)
}

///|
pub fn RenderCreation::default() -> RenderCreation {
  Automatic(WgpuSettings::default())
}

///|
pub fn host_gpu_set_mesh3d_gpu_instance_builder_enabled(enabled : Bool) -> Unit {
  @renderer.set_mesh3d_gpu_instance_builder_enabled(enabled)
}

///|
pub fn host_gpu_mesh3d_indirect_first_instance_supported() -> Bool {
  @renderer.mesh3d_indirect_first_instance_supported()
}

///|
pub fn host_gpu_mesh3d_gpu_culling_supported() -> Bool {
  @renderer.mesh3d_gpu_culling_supported()
}

///|
pub fn host_gpu_mesh3d_preprocess_disabled() -> Bool {
  @renderer.mesh3d_preprocess_disabled()
}

///|
pub fn host_gpu_read_only_binding_type_uniform(
  required_storage_buffers : Int,
) -> Bool {
  @renderer.read_only_binding_type_uniform(required_storage_buffers)
}
