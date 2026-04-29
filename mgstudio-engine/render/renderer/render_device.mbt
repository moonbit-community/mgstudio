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
// Bevy source: `bevy/crates/bevy_render/src/renderer/render_device.rs`.

///|
/// This GPU device is responsible for the creation of most rendering and
/// compute resources.
///
/// Bevy stores a `WgpuWrapper<wgpu::Device>` here. mgstudio uses the same
/// logical shape over `wgpu_mbt.Device`; the legacy integer device handle API
/// below is retained only as the host-runtime compatibility boundary.
pub struct RenderDevice {
  device : WgpuWrapper[@wgpu.Device]
}

///|
pub fn RenderDevice::new(device : WgpuWrapper[@wgpu.Device]) -> RenderDevice {
  { device, }
}

///|
pub fn RenderDevice::from_wgpu(device : @wgpu.Device) -> RenderDevice {
  RenderDevice::new(WgpuWrapper::new(device))
}

///|
pub fn RenderDevice::from_backend(backend : GpuBackend) -> RenderDevice {
  RenderDevice::from_wgpu(backend.device)
}

///|
pub fn RenderDevice::wgpu_device(self : RenderDevice) -> @wgpu.Device {
  self.device.get()
}

///|
pub fn RenderDevice::create_command_encoder(
  self : RenderDevice,
) -> @wgpu.CommandEncoder {
  self.wgpu_device().create_command_encoder()
}

///|
pub fn RenderDevice::create_shader_module_wgsl(
  self : RenderDevice,
  source : String,
) -> @wgpu.ShaderModule {
  self.wgpu_device().create_shader_module_wgsl(source)
}

///|
pub fn RenderDevice::poll(self : RenderDevice, wait? : Bool = false) -> Bool {
  self.wgpu_device().poll(wait~)
}

///|
pub fn RenderDevice::supported_features_count_u64(
  self : RenderDevice,
) -> UInt64 {
  self.wgpu_device().supported_features_count_u64()
}

///|
pub fn RenderDevice::supported_feature_u32_at(
  self : RenderDevice,
  index : UInt64,
) -> UInt {
  self.wgpu_device().supported_feature_u32_at(index)
}

///|
pub fn RenderDevice::supports_rust_features_u64(
  self : RenderDevice,
  features : UInt64,
) -> Bool {
  self.wgpu_device().supports_rust_features_u64(features)
}

///|
pub fn RenderDevice::supported_rust_features_u64(self : RenderDevice) -> UInt64 {
  self.wgpu_device().supported_rust_features_u64()
}

///|
pub fn RenderDevice::limits_max_bind_groups_u32(self : RenderDevice) -> UInt {
  self.wgpu_device().limits_max_bind_groups_u32()
}

///|
pub fn RenderDevice::limits_max_push_constant_size_u32(
  self : RenderDevice,
) -> UInt {
  self.wgpu_device().limits_max_push_constant_size_u32()
}

///|
pub fn RenderDevice::queue(self : RenderDevice) -> RenderQueue {
  RenderQueue::from_wgpu(self.wgpu_device().queue())
}

///|
/// This queue is used to enqueue tasks for the GPU to execute asynchronously.
/// Mirrors Bevy's `RenderQueue(pub Arc<WgpuWrapper<Queue>>)` at the package
/// boundary; MoonBit native does not need the extra `Arc` layer.
pub struct RenderQueue {
  queue : WgpuWrapper[@wgpu.Queue]
}

///|
pub fn RenderQueue::new(queue : WgpuWrapper[@wgpu.Queue]) -> RenderQueue {
  { queue, }
}

///|
pub fn RenderQueue::from_wgpu(queue : @wgpu.Queue) -> RenderQueue {
  RenderQueue::new(WgpuWrapper::new(queue))
}

///|
pub fn RenderQueue::from_backend(backend : GpuBackend) -> RenderQueue {
  RenderQueue::from_wgpu(backend.queue)
}

///|
pub fn RenderQueue::wgpu_queue(self : RenderQueue) -> @wgpu.Queue {
  self.queue.get()
}

///|
pub fn RenderQueue::submit(
  self : RenderQueue,
  buffers : Array[@wgpu.CommandBuffer],
) -> Unit {
  self.wgpu_queue().submit(buffers)
}

///|
pub fn RenderQueue::submit_for_index(
  self : RenderQueue,
  buffers : Array[@wgpu.CommandBuffer],
) -> UInt64 {
  self.wgpu_queue().submit_for_index(buffers)
}

///|
pub fn RenderQueue::get_timestamp_period(self : RenderQueue) -> Float {
  self.wgpu_queue().get_timestamp_period()
}

///|
/// The handle to the physical device being used for rendering.
pub struct RenderAdapter {
  adapter : WgpuWrapper[@wgpu.Adapter]
}

///|
pub fn RenderAdapter::new(
  adapter : WgpuWrapper[@wgpu.Adapter],
) -> RenderAdapter {
  { adapter, }
}

///|
pub fn RenderAdapter::from_wgpu(adapter : @wgpu.Adapter) -> RenderAdapter {
  RenderAdapter::new(WgpuWrapper::new(adapter))
}

///|
pub fn RenderAdapter::from_backend(backend : GpuBackend) -> RenderAdapter {
  RenderAdapter::from_wgpu(backend.adapter)
}

///|
pub fn RenderAdapter::wgpu_adapter(self : RenderAdapter) -> @wgpu.Adapter {
  self.adapter.get()
}

///|
pub fn RenderAdapter::supported_rust_features_u64(
  self : RenderAdapter,
) -> UInt64 {
  self.wgpu_adapter().supported_rust_features_u64()
}

///|
pub fn RenderAdapter::supports_rust_features_u64(
  self : RenderAdapter,
  features : UInt64,
) -> Bool {
  self.wgpu_adapter().supports_rust_features_u64(features)
}

///|
/// The GPU instance used to initialize renderer resources and window surfaces.
pub struct RenderInstance {
  instance : WgpuWrapper[@wgpu.Instance]
}

///|
pub fn RenderInstance::new(
  instance : WgpuWrapper[@wgpu.Instance],
) -> RenderInstance {
  { instance, }
}

///|
pub fn RenderInstance::from_wgpu(instance : @wgpu.Instance) -> RenderInstance {
  RenderInstance::new(WgpuWrapper::new(instance))
}

///|
pub fn RenderInstance::from_backend(backend : GpuBackend) -> RenderInstance {
  RenderInstance::from_wgpu(backend.instance)
}

///|
pub fn RenderInstance::wgpu_instance(self : RenderInstance) -> @wgpu.Instance {
  self.instance.get()
}

///|
pub struct RenderAdapterInfo {
  name : String
  vendor : String
  device : String
  device_id : UInt
  vendor_id : UInt
  device_type : UInt
  backend : UInt
}

///|
pub fn RenderAdapterInfo::from_adapter(
  adapter : RenderAdapter,
) -> RenderAdapterInfo {
  let raw = adapter.wgpu_adapter()
  {
    name: raw.info_description(),
    vendor: raw.info_vendor(),
    device: raw.info_device(),
    device_id: raw.info_device_id_u32(),
    vendor_id: raw.info_vendor_id_u32(),
    device_type: raw.info_adapter_type_u32(),
    backend: raw.info_backend_type_u32(),
  }
}

///|
pub fn RenderAdapterInfo::from_backend(
  backend : GpuBackend,
) -> RenderAdapterInfo {
  RenderAdapterInfo::from_adapter(RenderAdapter::from_backend(backend))
}

///|
pub fn RenderAdapterInfo::name(self : RenderAdapterInfo) -> String {
  self.name
}

///|
pub fn RenderAdapterInfo::vendor(self : RenderAdapterInfo) -> String {
  self.vendor
}

///|
pub fn RenderAdapterInfo::device(self : RenderAdapterInfo) -> String {
  self.device
}

///|
pub fn RenderAdapterInfo::device_id(self : RenderAdapterInfo) -> UInt {
  self.device_id
}

///|
pub fn RenderAdapterInfo::vendor_id(self : RenderAdapterInfo) -> UInt {
  self.vendor_id
}

///|
pub fn RenderAdapterInfo::device_type(self : RenderAdapterInfo) -> UInt {
  self.device_type
}

///|
pub fn RenderAdapterInfo::backend(self : RenderAdapterInfo) -> UInt {
  self.backend
}

///|
const PRIMARY_DEVICE_ID : NativeGpuDevice = 1

///|
const PRIMARY_QUEUE_ID : NativeGpuQueue = 2

///|
pub fn request_device() -> NativeGpuDevice {
  if ensure_backend() is Some(_) {
    PRIMARY_DEVICE_ID
  } else {
    0
  }
}

///|
pub fn get_queue(device : NativeGpuDevice) -> NativeGpuQueue {
  if device == PRIMARY_DEVICE_ID && ensure_backend() is Some(_) {
    PRIMARY_QUEUE_ID
  } else {
    0
  }
}
