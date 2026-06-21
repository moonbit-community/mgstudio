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
pub fn WgpuSettings::WgpuSettings() -> WgpuSettings {
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
pub let render_device_resource_key : @ecs.ResourceKey[@renderer.RenderDevice] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderDevice",
)

///|
pub let render_queue_resource_key : @ecs.ResourceKey[@renderer.RenderQueue] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderQueue",
)

///|
pub let render_adapter_info_resource_key : @ecs.ResourceKey[
  @renderer.RenderAdapterInfo,
] = @ecs.register_resource(debug_name="mgstudio_render::RenderAdapterInfo")

///|
pub let render_adapter_resource_key : @ecs.ResourceKey[@renderer.RenderAdapter] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderAdapter",
)

///|
pub let render_instance_resource_key : @ecs.ResourceKey[
  @renderer.RenderInstance,
] = @ecs.register_resource(debug_name="mgstudio_render::RenderInstance")

///|
pub let pipeline_cache_resource_key : @ecs.ResourceKey[
  @render_resource.PipelineCache,
] = @ecs.register_resource(debug_name="mgstudio_render::PipelineCache")

///|
pub let pending_command_buffers_resource_key : @ecs.ResourceKey[
  @renderer.PendingCommandBuffers,
] = @ecs.register_resource(debug_name="mgstudio_render::PendingCommandBuffers")

///|
pub struct CurrentView {
  entity : @core.Entity
} derive(Eq, Debug)

///|
pub fn CurrentView::new(entity : @core.Entity) -> CurrentView {
  CurrentView::{ entity, }
}

///|
pub fn CurrentView::entity(self : CurrentView) -> @core.Entity {
  self.entity
}

///|
pub let current_view_resource_key : @ecs.ResourceKey[CurrentView] = @ecs.register_resource(
  debug_name="mgstudio_render::CurrentView",
)

///|
fn[T] render_world_resource_present(
  world : @ecs.World,
  key : @ecs.ResourceKey[T],
) -> Bool {
  match world.get_resource(key) {
    Some(_) => true
    None => false
  }
}

///|
pub fn init_pending_command_buffers_resource(world : @ecs.World) -> Unit {
  world.insert_resource(
    pending_command_buffers_resource_key,
    @renderer.PendingCommandBuffers::PendingCommandBuffers(),
  )
}

///|
pub fn flush_pending_command_buffers(world : @ecs.World) -> Unit {
  let pending = match world.get_resource(pending_command_buffers_resource_key) {
    Some(value) => value
    None => return
  }
  let queue = match world.get_resource(render_queue_resource_key) {
    Some(value) => value
    None => return
  }
  let buffers = pending.take()
  if buffers.length() > 0 {
    queue.submit(buffers)
    for buffer in buffers {
      buffer.release()
    }
  }
  @renderer.release_frame_retired_resources()
  world.insert_resource(pending_command_buffers_resource_key, pending)
}

///|
pub fn prepare_active_frame_submissions(world : @ecs.World) -> Unit {
  let pending = match world.get_resource(pending_command_buffers_resource_key) {
    Some(value) => value
    None => return
  }
  @renderer.prepare_active_frame_submissions(pending)
  world.insert_resource(pending_command_buffers_resource_key, pending)
}

///|
pub fn present_active_frames(_world : @ecs.World) -> Unit {
  @renderer.present_active_frames()
}

///|
pub fn prepare_window_surfaces(_world : @ecs.World) -> Unit {
  @renderer.prepare_initial_surface_frames()
}

///|
fn process_pipeline_queue_system(world : @ecs.World) -> Unit {
  guard world.get_resource(pipeline_cache_resource_key) is Some(cache) else {
    return
  }
  cache.process_queue()
}

///|
fn register_pipeline_cache_render_pipeline_descriptors(
  world : @ecs.World,
) -> Unit {
  guard world.get_resource(pipeline_cache_resource_key) is Some(cache) else {
    return
  }
  let pipelines = cache.pipelines()
  for pipeline_id in cache.waiting_pipelines() {
    let index = pipeline_id.to_int()
    if index < 0 || index >= pipelines.length() {
      continue
    }
    let cached_pipeline = pipelines[index]
    if !cached_pipeline.state().is_creating() {
      continue
    }
    match cached_pipeline.descriptor() {
      @render_resource.PipelineDescriptor::RenderPipelineDescriptor(descriptor) => {
        @renderer.register_mesh3d_material_pipeline_descriptor(
          material_pipeline_id=pipeline_id,
          descriptor~,
        )
        try {
          let cached_id = @render_resource.CachedRenderPipelineId::new(
            pipeline_id,
          )
          match
            @renderer.materialize_pipeline_cache_render_pipeline_descriptor(
              descriptor,
            ) {
            Some(pipeline) =>
              cache.mark_render_pipeline_ready(cached_id, pipeline) catch {
                _ => ()
              }
            None => ()
          }
        } catch {
          @renderer.ShaderNotReady(message) =>
            cache.mark_pipeline_retryable_error(pipeline_id, message) catch {
              _ => ()
            }
          err =>
            cache.mark_pipeline_error(pipeline_id, to_repr(err).to_string()) catch {
              _ => ()
            }
        }
      }
      @render_resource.PipelineDescriptor::ComputePipelineDescriptor(descriptor) =>
        try {
          let cached_id = @render_resource.CachedComputePipelineId::new(
            pipeline_id,
          )
          match
            @renderer.materialize_pipeline_cache_compute_pipeline_descriptor(
              descriptor,
            ) {
            Some(pipeline) =>
              cache.mark_compute_pipeline_ready(cached_id, pipeline) catch {
                _ => ()
              }
            None => ()
          }
        } catch {
          @renderer.ShaderNotReady(message) =>
            cache.mark_pipeline_retryable_error(pipeline_id, message) catch {
              _ => ()
            }
          err =>
            cache.mark_pipeline_error(pipeline_id, to_repr(err).to_string()) catch {
              _ => ()
            }
        }
    }
  }
}

///|
pub fn RenderResources::unpack_into(
  self : RenderResources,
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  main_world.insert_resource(render_device_resource_key, self.device)
  main_world.insert_resource(render_queue_resource_key, self.queue)
  main_world.insert_resource(
    render_adapter_info_resource_key,
    self.adapter_info,
  )
  main_world.insert_resource(render_adapter_resource_key, self.render_adapter)

  render_world.insert_resource(render_instance_resource_key, self.instance)
  render_world.insert_resource(
    pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )
  render_world.insert_resource(render_device_resource_key, self.device)
  render_world.insert_resource(render_queue_resource_key, self.queue)
  render_world.insert_resource(render_adapter_resource_key, self.render_adapter)
  render_world.insert_resource(
    render_adapter_info_resource_key,
    self.adapter_info,
  )
}

///|
pub fn ensure_primary_render_resources(
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  let device = match @renderer.primary_render_device() {
    Some(value) => value
    None => return
  }
  let queue = match @renderer.primary_render_queue() {
    Some(value) => value
    None => return
  }
  let adapter_info = match @renderer.primary_render_adapter_info() {
    Some(value) => value
    None => return
  }
  let render_adapter = match @renderer.primary_render_adapter() {
    Some(value) => value
    None => return
  }
  let instance = match @renderer.primary_render_instance() {
    Some(value) => value
    None => return
  }

  if !render_world_resource_present(main_world, render_device_resource_key) {
    main_world.insert_resource(render_device_resource_key, device)
  }
  if !render_world_resource_present(main_world, render_queue_resource_key) {
    main_world.insert_resource(render_queue_resource_key, queue)
  }
  if !render_world_resource_present(
      main_world, render_adapter_info_resource_key,
    ) {
    main_world.insert_resource(render_adapter_info_resource_key, adapter_info)
  }
  if !render_world_resource_present(main_world, render_adapter_resource_key) {
    main_world.insert_resource(render_adapter_resource_key, render_adapter)
  }

  if !render_world_resource_present(render_world, render_instance_resource_key) {
    render_world.insert_resource(render_instance_resource_key, instance)
  }
  if !render_world_resource_present(render_world, pipeline_cache_resource_key) {
    render_world.insert_resource(
      pipeline_cache_resource_key,
      @render_resource.PipelineCache::new(),
    )
  }
  if !render_world_resource_present(render_world, render_device_resource_key) {
    render_world.insert_resource(render_device_resource_key, device)
  }
  if !render_world_resource_present(render_world, render_queue_resource_key) {
    render_world.insert_resource(render_queue_resource_key, queue)
  }
  if !render_world_resource_present(render_world, render_adapter_resource_key) {
    render_world.insert_resource(render_adapter_resource_key, render_adapter)
  }
  if !render_world_resource_present(
      render_world, render_adapter_info_resource_key,
    ) {
    render_world.insert_resource(render_adapter_info_resource_key, adapter_info)
  }
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
  Automatic(WgpuSettings::WgpuSettings())
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
