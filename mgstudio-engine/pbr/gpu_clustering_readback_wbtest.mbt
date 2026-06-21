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
test "render3d: gpu clustering command pass counts follow Bevy" {
  let metadata = ClusterMetadata::new(11U, 13U, 17U, 19U, 0U, 0U)
  debug_inspect(gpu_clustering_clusterable_object_count(metadata), content="60")
  debug_inspect(
    gpu_clustering_z_slice_dispatch_count(
      gpu_clustering_clusterable_object_count(metadata).reinterpret_as_int(),
    ),
    content="1",
  )
  let config = ExtractedClusterConfig::new(0.1F, 1000.0F, 17, 13, 5)
  debug_inspect(
    gpu_clustering_allocation_pass_workgroup_count(config, false),
    content="5",
  )
  debug_inspect(
    gpu_clustering_allocation_pass_workgroup_count(config, true),
    content="1",
  )
  let view_lights_offset = @pbr_render.ViewLightsUniformOffset::new(256U)
  debug_inspect(view_lights_offset.offset(), content="256")
}

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
  let farthest_z = 9.75F
  let encoded_farthest_z = farthest_z.reinterpret_as_uint() ^ 0x8000_0000U
  uploaded_buffers.set_metadata(
    ClusterMetadata::from_gpu_readback(
      ClusterRasterIndirectDrawParams::new(6U, 19U, 0U, 0U, 0U),
      1U,
      2U,
      3U,
      4U,
      8U,
      35U,
      encoded_farthest_z,
    ),
  )
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

  debug_inspect(
    gpu_clustering_process_readback_staging_buffer(
      instance, readback, staging_buffer,
    ),
    content="true",
  )
  debug_inspect(readback.z_slice_list_capacity(), content="32")
  debug_inspect(readback.max_index_list_capacity(), content="64")
  debug_inspect(readback.free_staging_buffer_count(), content="1")
  let statistics = match readback.last_frame_statistics() {
    Some(value) => value
    None => abort("missing GPU clustering staging readback statistics")
  }
  debug_inspect(statistics.index_list_size(), content="35")
  debug_inspect(statistics.farthest_z(), content="9.75")
  let recycled_buffer = readback.get_or_create_staging_buffer(render_device)
  recycled_buffer.release()

  device.release()
  adapter.release()
  instance.release()
}
