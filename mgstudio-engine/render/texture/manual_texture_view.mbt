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
// Bevy source: `bevy/crates/bevy_render/src/texture/manual_texture_view.rs`.

///|
pub type ManualTextureViewHandle = @camera_render_target.ManualTextureViewHandle

///|
pub struct ManualTextureView {
  texture_view : @render_resource.TextureView
  size : @math.UVec2
  view_format : @wgpu.TextureFormat
}

///|
pub fn ManualTextureView::new(
  texture_view : @render_resource.TextureView,
  size : @math.UVec2,
  view_format : @wgpu.TextureFormat,
) -> ManualTextureView {
  ManualTextureView::{ texture_view, size, view_format }
}

///|
pub fn ManualTextureView::with_default_format(
  texture_view : @render_resource.TextureView,
  size : @math.UVec2,
) -> ManualTextureView {
  ManualTextureView::new(
    texture_view,
    size,
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB),
  )
}

///|
pub fn ManualTextureView::texture_view(
  self : ManualTextureView,
) -> @render_resource.TextureView {
  self.texture_view
}

///|
pub fn ManualTextureView::size(self : ManualTextureView) -> @math.UVec2 {
  self.size
}

///|
pub fn ManualTextureView::view_format(
  self : ManualTextureView,
) -> @wgpu.TextureFormat {
  self.view_format
}

///|
pub struct ManualTextureViews {
  views : @hashmap.HashMap[ManualTextureViewHandle, ManualTextureView]
}

///|
pub fn ManualTextureViews::ManualTextureViews() -> ManualTextureViews {
  ManualTextureViews::{ views: @hashmap.HashMap([]) }
}

///|
pub fn ManualTextureViews::len(self : ManualTextureViews) -> Int {
  self.views.length()
}

///|
pub fn ManualTextureViews::is_empty(self : ManualTextureViews) -> Bool {
  self.len() == 0
}

///|
pub fn ManualTextureViews::insert(
  self : ManualTextureViews,
  handle : ManualTextureViewHandle,
  view : ManualTextureView,
) -> Unit {
  self.views.set(handle, view)
}

///|
pub fn ManualTextureViews::get(
  self : ManualTextureViews,
  handle : ManualTextureViewHandle,
) -> ManualTextureView? {
  self.views.get(handle)
}

///|
pub fn ManualTextureViews::remove(
  self : ManualTextureViews,
  handle : ManualTextureViewHandle,
) -> ManualTextureView? {
  let current = self.views.get(handle)
  self.views.remove(handle)
  current
}

///|
pub fn ManualTextureViews::clear(self : ManualTextureViews) -> Unit {
  self.views.clear()
}

///|
pub fn manual_texture_view_handle(
  texture_id~ : Int,
  mip_level~ : Int,
) -> ManualTextureViewHandle {
  ManualTextureViewHandle::new(texture_id * 10_000 + mip_level)
}

///|
pub let manual_texture_views_resource_key : @ecs.ResourceKey[ManualTextureViews] = @ecs.register_resource(
  debug_name="mgstudio_render::ManualTextureViews",
)

///|
pub impl @app.Resource for ManualTextureViews with fn resource() {
  manual_texture_views_resource_key
}
