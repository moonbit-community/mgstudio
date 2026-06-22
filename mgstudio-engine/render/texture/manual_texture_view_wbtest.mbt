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
test "render texture: manual texture view handles preserve Bevy handle identity" {
  let a = manual_texture_view_handle(texture_id=1, mip_level=23)
  let b = manual_texture_view_handle(texture_id=2, mip_level=13)
  inspect(a == b, content="false")
  inspect(a.value(), content="10023")
  inspect(b.value(), content="20013")
}

///|
test "render texture: ManualTextureViews stores views by handle" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let texture = device.create_texture_u32(
    2U,
    4U,
    1U,
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
    @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB),
  )
  let texture_view = @render_resource.TextureView::from_wgpu(
    texture.create_view(),
  )
  let manual_view = ManualTextureView::with_default_format(
    texture_view,
    @math.UVec2::new(2, 4),
  )
  let handle = ManualTextureViewHandle::new(42)
  let views = ManualTextureViews::ManualTextureViews()
  inspect(views.is_empty(), content="true")
  views.insert(handle, manual_view)
  inspect(views.len(), content="1")
  let stored = views.get(handle).unwrap()
  inspect(stored.size().x, content="2")
  inspect(stored.size().y, content="4")
  inspect(stored.view_format().to_u32(), content="23")
  inspect(views.remove(handle) is Some(_), content="true")
  inspect(views.is_empty(), content="true")
  device.release()
  adapter.release()
  instance.release()
}
