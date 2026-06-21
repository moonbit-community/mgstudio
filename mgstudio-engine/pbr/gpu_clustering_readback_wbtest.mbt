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
test "render3d: gpu clustering schedules metadata staging copy" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let readback = ViewClusteringReadbackData::new(
    @light_cluster.GlobalClusterGpuSettings::new(8, 16),
  )
  let staging_buffer = readback.get_or_create_staging_buffer(render_device)
  let uploaded_buffers = ViewGpuClusteringBuffers::ViewGpuClusteringBuffers()
  uploaded_buffers.write_buffers(render_device, render_queue)
  let encoder = render_device.create_command_encoder()

  debug_inspect(
    gpu_clustering_schedule_readback_staging(
      encoder, uploaded_buffers, staging_buffer,
    ),
    content="true",
  )
  let command_buffer = encoder.finish()
  render_queue.submit([command_buffer])
  command_buffer.release()
  encoder.release()
  staging_buffer.release()
  device.release()
  adapter.release()
  instance.release()
}
