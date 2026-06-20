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
test "render texture: cache reuses descriptor-matched textures after cleanup update" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = @renderer.RenderDevice::from_wgpu(device)
  let cache = TextureCache::new()
  let descriptor = TextureCacheDescriptor::new(
    label=Some("texture cache test"),
    width=31,
    height=17,
    format_raw=@wgpu.TEXTURE_FORMAT_R8_UNORM,
    usage_bits=@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT |
      @wgpu.TEXTURE_USAGE_COPY_DST,
  )

  let first = cache.get(render_device, descriptor)
  let second = cache.get(render_device, descriptor)
  debug_inspect(first.texture_id() == second.texture_id(), content="false")
  debug_inspect(cache.descriptor_count(), content="1")
  debug_inspect(cache.len(), content="2")
  debug_inspect(cache.taken_count(), content="2")

  cache.update()
  debug_inspect(cache.taken_count(), content="0")
  let reused = cache.get(render_device, descriptor)
  debug_inspect(reused.texture_id(), content=first.texture_id().to_string())
  debug_inspect(cache.len(), content="2")

  cache.update()
  cache.update()
  cache.update()
  debug_inspect(cache.is_empty(), content="true")

  device.release()
  adapter.release()
  instance.release()
}
