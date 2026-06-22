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
// Bevy source: `bevy/crates/bevy_render/src/view/window/mod.rs`.

///|
pub struct WindowRenderPlugin {}

///|
pub fn WindowRenderPlugin::WindowRenderPlugin() -> WindowRenderPlugin {
  WindowRenderPlugin::{  }
}

///|
pub impl @app.Plugin for WindowRenderPlugin with fn name(_self) {
  "mgstudio.render.view.window.WindowRenderPlugin"
}

///|
pub impl @app.Plugin for WindowRenderPlugin with fn build(_self, app) {
  window_render_plugin_install(app)
}

///|
pub type ManualTextureViewHandle = @camera_render_target.ManualTextureViewHandle

///|
pub struct ExtractedWindow {
  entity : @core.Entity
  handle : @window_pkg.RawHandleWrapper
  physical_width : Int
  physical_height : Int
  present_mode : @window_pkg.PresentMode
  desired_maximum_frame_latency : Int?
  swap_chain_texture_view : @render_resource.TextureView?
  mut swap_chain_texture : @render_resource.SurfaceTexture?
  swap_chain_texture_format : @wgpu.TextureFormat?
  swap_chain_texture_view_format : @wgpu.TextureFormat?
  size_changed : Bool
  present_mode_changed : Bool
  alpha_mode : @window_pkg.CompositeAlphaMode
  needs_initial_present : Bool
}

///|
pub fn ExtractedWindow::new(
  entity : @core.Entity,
  handle : @window_pkg.RawHandleWrapper,
  physical_width : Int,
  physical_height : Int,
  present_mode : @window_pkg.PresentMode,
  desired_maximum_frame_latency : Int?,
  alpha_mode : @window_pkg.CompositeAlphaMode,
) -> ExtractedWindow {
  ExtractedWindow::{
    entity,
    handle,
    physical_width: physical_width.max(1),
    physical_height: physical_height.max(1),
    present_mode,
    desired_maximum_frame_latency,
    swap_chain_texture_view: None,
    swap_chain_texture: None,
    swap_chain_texture_format: None,
    swap_chain_texture_view_format: None,
    size_changed: false,
    present_mode_changed: false,
    alpha_mode,
    needs_initial_present: true,
  }
}

///|
pub fn ExtractedWindow::has_swapchain_texture(self : ExtractedWindow) -> Bool {
  self.swap_chain_texture_view is Some(_) && self.swap_chain_texture is Some(_)
}

///|
pub fn ExtractedWindow::present(self : ExtractedWindow) -> Unit {
  match self.swap_chain_texture {
    Some(surface_texture) => {
      self.swap_chain_texture = None
      surface_texture.present()
    }
    None => ()
  }
}

///|
pub struct ExtractedWindows {
  mut primary : @core.Entity?
  windows : @hashmap.HashMap[@core.Entity, ExtractedWindow]
}

///|
pub fn ExtractedWindows::ExtractedWindows() -> ExtractedWindows {
  ExtractedWindows::{ primary: None, windows: @hashmap.HashMap([]) }
}

///|
pub fn ExtractedWindows::len(self : ExtractedWindows) -> Int {
  self.windows.length()
}

///|
pub fn ExtractedWindows::is_empty(self : ExtractedWindows) -> Bool {
  self.len() == 0
}

///|
pub fn ExtractedWindows::get(
  self : ExtractedWindows,
  entity : @core.Entity,
) -> ExtractedWindow? {
  self.windows.get(entity)
}

///|
pub fn ExtractedWindows::insert(
  self : ExtractedWindows,
  entity : @core.Entity,
  window : ExtractedWindow,
) -> Unit {
  self.windows.set(entity, window)
}

///|
pub fn ExtractedWindows::remove(
  self : ExtractedWindows,
  entity : @core.Entity,
) -> Unit {
  self.windows.remove(entity)
  if self.primary == Some(entity) {
    self.primary = None
  }
}

///|
pub fn ExtractedWindows::clear(self : ExtractedWindows) -> Unit {
  self.primary = None
  self.windows.clear()
}

///|
pub(all) struct SurfaceData {
  surface : @wgpu.Surface
  configuration : @wgpu.SurfaceConfiguration
  texture_view_format : @wgpu.TextureFormat?
}

///|
pub struct WindowSurfaces {
  surfaces : @hashmap.HashMap[@core.Entity, SurfaceData]
  configured_windows : @hashset.HashSet[@core.Entity]
}

///|
pub fn WindowSurfaces::WindowSurfaces() -> WindowSurfaces {
  WindowSurfaces::{
    surfaces: @hashmap.HashMap([]),
    configured_windows: @hashset.HashSet([]),
  }
}

///|
pub fn WindowSurfaces::len(self : WindowSurfaces) -> Int {
  self.surfaces.length()
}

///|
pub fn WindowSurfaces::is_empty(self : WindowSurfaces) -> Bool {
  self.len() == 0
}

///|
pub fn WindowSurfaces::is_configured(
  self : WindowSurfaces,
  entity : @core.Entity,
) -> Bool {
  self.configured_windows.contains(entity)
}

///|
pub fn WindowSurfaces::remove(
  self : WindowSurfaces,
  entity : @core.Entity,
) -> Unit {
  self.surfaces.remove(entity)
  self.configured_windows.remove(entity)
}

///|
pub let extracted_windows_resource_key : @ecs.ResourceKey[ExtractedWindows] = @ecs.register_resource(
  debug_name="mgstudio_render::ExtractedWindows",
)

///|
pub let window_surfaces_resource_key : @ecs.ResourceKey[WindowSurfaces] = @ecs.register_resource(
  debug_name="mgstudio_render::WindowSurfaces",
)

///|
pub fn init_extracted_windows(world : @ecs.World) -> Unit {
  if world.resource(extracted_windows_resource_key).is_present() {
    return
  }
  world.insert_resource(
    extracted_windows_resource_key,
    ExtractedWindows::ExtractedWindows(),
  )
}

///|
pub fn init_window_surfaces(world : @ecs.World) -> Unit {
  if world.resource(window_surfaces_resource_key).is_present() {
    return
  }
  world.insert_resource(
    window_surfaces_resource_key,
    WindowSurfaces::WindowSurfaces(),
  )
}

///|
pub impl @app.Resource for ExtractedWindows with fn resource() {
  extracted_windows_resource_key
}

///|
pub impl @app.Resource for WindowSurfaces with fn resource() {
  window_surfaces_resource_key
}

///|
fn window_render_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let next = app
  ignore(
    next.modify_sub_app(@app.RenderApp, fn(render_sub_app) {
      init_extracted_windows(render_sub_app.world())
      init_window_surfaces(render_sub_app.world())
      render_sub_app
    }),
  )
  next
}

///|
pub fn window_screenshot_capture_surface_request() -> Int {
  screenshot_capture_surface_request()
}

///|
pub fn window_screenshot_capture_surface_target_request(
  target_id~ : Int,
) -> Int {
  screenshot_capture_surface_target_request(target_id~)
}

///|
pub fn window_screenshot_capture_texture_request(texture_id~ : Int) -> Int {
  screenshot_capture_texture_request(texture_id~)
}

///|
pub fn window_screenshot_take_capture_result(
  capture_id : Int,
) -> @renderer.ScreenshotCaptureResult? {
  screenshot_take_capture_result(capture_id)
}

///|
pub fn window_screenshot_capture_texture_sync(
  texture_id~ : Int,
) -> @renderer.ScreenshotCaptureResult? {
  screenshot_capture_texture_sync(texture_id~)
}

///|
pub fn window_screenshot_parity_capture_completed() -> Bool {
  screenshot_parity_capture_completed()
}

///|
pub fn window_manual_texture_view_handle(
  texture_id~ : Int,
  mip_level~ : Int,
) -> ManualTextureViewHandle {
  ManualTextureViewHandle::new(texture_id * 10_000 + mip_level)
}
