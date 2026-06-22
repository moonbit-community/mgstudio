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
  mut physical_width : Int
  mut physical_height : Int
  mut present_mode : @window_pkg.PresentMode
  desired_maximum_frame_latency : Int?
  mut swap_chain_texture_view : @render_resource.TextureView?
  mut swap_chain_texture : @render_resource.SurfaceTexture?
  swap_chain_texture_format : @wgpu.TextureFormat?
  swap_chain_texture_view_format : @wgpu.TextureFormat?
  mut size_changed : Bool
  mut present_mode_changed : Bool
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
priv struct ExtractWindowsMessageCursors {
  mut window_closing : @ecs.MessageCursor[@window_pkg.WindowClosing]
}

///|
fn ExtractWindowsMessageCursors::ExtractWindowsMessageCursors() -> ExtractWindowsMessageCursors {
  ExtractWindowsMessageCursors::{
    window_closing: @ecs.MessageCursor::MessageCursor(),
  }
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
pub fn need_surface_configuration(
  windows : ExtractedWindows,
  window_surfaces : WindowSurfaces,
) -> Bool {
  for entry in windows.windows.iter() {
    let (_, window) = entry
    if !window_surfaces.configured_windows.contains(window.entity) ||
      window.size_changed ||
      window.present_mode_changed {
      return true
    }
  }
  false
}

///|
pub const DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY : UInt = 2U

///|
pub fn present_mode_fallbacks_raw(
  present_mode : @window_pkg.PresentMode,
) -> Array[UInt] {
  match present_mode {
    AutoVsync => [@wgpu.PRESENT_MODE_FIFO_RELAXED, @wgpu.PRESENT_MODE_FIFO]
    AutoNoVsync =>
      [
        @wgpu.PRESENT_MODE_IMMEDIATE,
        @wgpu.PRESENT_MODE_MAILBOX,
        @wgpu.PRESENT_MODE_FIFO,
      ]
    Mailbox =>
      [
        @wgpu.PRESENT_MODE_MAILBOX,
        @wgpu.PRESENT_MODE_IMMEDIATE,
        @wgpu.PRESENT_MODE_FIFO,
      ]
    Fifo => [@wgpu.PRESENT_MODE_FIFO, @wgpu.PRESENT_MODE_FIFO]
    FifoRelaxed => [@wgpu.PRESENT_MODE_FIFO_RELAXED, @wgpu.PRESENT_MODE_FIFO]
    Immediate => [@wgpu.PRESENT_MODE_IMMEDIATE, @wgpu.PRESENT_MODE_FIFO]
  }
}

///|
fn present_mode_supported(supported_modes : Array[UInt], mode : UInt) -> Bool {
  for supported in supported_modes {
    if supported == mode {
      return true
    }
  }
  false
}

///|
pub fn present_mode_raw(
  window : ExtractedWindow,
  supported_modes : Array[UInt],
) -> UInt {
  for fallback in present_mode_fallbacks_raw(window.present_mode) {
    if present_mode_supported(supported_modes, fallback) {
      return fallback
    }
  }
  abort("Fallback system failed to choose present mode")
}

///|
fn surface_texture_format_is_srgb_raw(format_raw : UInt) -> Bool {
  match format_raw {
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_BC1_RGBA_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_BC2_RGBA_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_BC3_RGBA_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ETC2_RGB8_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC5X4_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC5X5_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC6X5_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC6X6_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC8X5_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC8X6_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC8X8_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC10X5_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC10X6_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC10X8_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC10X10_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC12X10_UNORM_SRGB
    | @wgpu.TEXTURE_FORMAT_ASTC12X12_UNORM_SRGB => true
    _ => false
  }
}

///|
fn surface_texture_format_add_srgb_suffix_raw(format_raw : UInt) -> UInt {
  match format_raw {
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM => @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM => @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_BC1_RGBA_UNORM =>
      @wgpu.TEXTURE_FORMAT_BC1_RGBA_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_BC2_RGBA_UNORM =>
      @wgpu.TEXTURE_FORMAT_BC2_RGBA_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_BC3_RGBA_UNORM =>
      @wgpu.TEXTURE_FORMAT_BC3_RGBA_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM =>
      @wgpu.TEXTURE_FORMAT_BC7_RGBA_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ETC2_RGB8_UNORM =>
      @wgpu.TEXTURE_FORMAT_ETC2_RGB8_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM =>
      @wgpu.TEXTURE_FORMAT_ETC2_RGB8_A1_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM =>
      @wgpu.TEXTURE_FORMAT_ETC2_RGBA8_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC4X4_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC5X4_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC5X4_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC5X5_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC5X5_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC6X5_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC6X5_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC6X6_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC6X6_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC8X5_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC8X5_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC8X6_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC8X6_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC8X8_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC8X8_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC10X5_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC10X5_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC10X6_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC10X6_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC10X8_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC10X8_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC10X10_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC10X10_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC12X10_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC12X10_UNORM_SRGB
    @wgpu.TEXTURE_FORMAT_ASTC12X12_UNORM =>
      @wgpu.TEXTURE_FORMAT_ASTC12X12_UNORM_SRGB
    _ => format_raw
  }
}

///|
pub fn surface_texture_format_is_srgb(format : @wgpu.TextureFormat) -> Bool {
  surface_texture_format_is_srgb_raw(format.to_u32())
}

///|
pub fn surface_texture_format_add_srgb_suffix(
  format : @wgpu.TextureFormat,
) -> @wgpu.TextureFormat {
  @wgpu.TextureFormat::from_u32(
    surface_texture_format_add_srgb_suffix_raw(format.to_u32()),
  )
}

///|
pub fn preferred_surface_format(
  formats : Array[@wgpu.TextureFormat],
) -> @wgpu.TextureFormat {
  guard formats.length() > 0 else { abort("No supported formats for surface") }
  let mut format = formats[0]
  for available_format in formats {
    let raw = available_format.to_u32()
    if raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB ||
      raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
      format = available_format
      break
    }
  }
  format
}

///|
pub fn surface_texture_view_format(
  format : @wgpu.TextureFormat,
) -> @wgpu.TextureFormat? {
  if surface_texture_format_is_srgb(format) {
    None
  } else {
    Some(surface_texture_format_add_srgb_suffix(format))
  }
}

///|
pub fn composite_alpha_mode_raw(
  alpha_mode : @window_pkg.CompositeAlphaMode,
) -> UInt {
  match alpha_mode {
    Auto => @wgpu.COMPOSITE_ALPHA_MODE_AUTO
    Opaque => @wgpu.COMPOSITE_ALPHA_MODE_OPAQUE
    PreMultiplied => @wgpu.COMPOSITE_ALPHA_MODE_PREMULTIPLIED
    PostMultiplied => @wgpu.COMPOSITE_ALPHA_MODE_UNPREMULTIPLIED
    Inherit => @wgpu.COMPOSITE_ALPHA_MODE_INHERIT
  }
}

///|
fn desired_maximum_frame_latency_raw(
  desired_maximum_frame_latency : Int?,
) -> UInt {
  match desired_maximum_frame_latency {
    Some(value) if value >= 1 => value.reinterpret_as_uint()
    _ => DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  }
}

///|
pub fn surface_configuration_for_window(
  window : ExtractedWindow,
  supported_present_modes : Array[UInt],
  supported_formats : Array[@wgpu.TextureFormat],
) -> @wgpu.SurfaceConfiguration {
  let format = preferred_surface_format(supported_formats)
  let view_formats = match surface_texture_view_format(format) {
    Some(view_format) => [view_format]
    None => []
  }
  @wgpu.SurfaceConfiguration::new(
    window.physical_width.reinterpret_as_uint(),
    window.physical_height.reinterpret_as_uint(),
    @wgpu.TextureUsage::from_u64(@wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT),
    format,
    @wgpu.PresentMode::from_u32(
      present_mode_raw(window, supported_present_modes),
    ),
    @wgpu.CompositeAlphaMode::from_u32(
      composite_alpha_mode_raw(window.alpha_mode),
    ),
  )
  .with_desired_maximum_frame_latency(
    desired_maximum_frame_latency_raw(window.desired_maximum_frame_latency),
  )
  .with_view_formats(view_formats)
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
let extract_windows_message_cursors_resource_key : @ecs.ResourceKey[
  ExtractWindowsMessageCursors,
] = @ecs.register_resource(
  debug_name="mgstudio_render::ExtractWindowsMessageCursors",
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
fn init_extract_windows_message_cursors(world : @ecs.World) -> Unit {
  if world.resource(extract_windows_message_cursors_resource_key).is_present() {
    return
  }
  world.insert_resource(
    extract_windows_message_cursors_resource_key,
    ExtractWindowsMessageCursors::ExtractWindowsMessageCursors(),
  )
}

///|
fn ensure_extracted_windows(
  world : @ecs.World,
) -> @ecs.ResourceMut[ExtractedWindows] {
  init_extracted_windows(world)
  world.get_resource_mut(extracted_windows_resource_key).unwrap()
}

///|
fn ensure_window_surfaces(
  world : @ecs.World,
) -> @ecs.ResourceMut[WindowSurfaces] {
  init_window_surfaces(world)
  world.get_resource_mut(window_surfaces_resource_key).unwrap()
}

///|
fn ensure_extract_windows_message_cursors(
  world : @ecs.World,
) -> @ecs.ResourceMut[ExtractWindowsMessageCursors] {
  init_extract_windows_message_cursors(world)
  world.get_resource_mut(extract_windows_message_cursors_resource_key).unwrap()
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
      init_extract_windows_message_cursors(render_sub_app.world())
      render_sub_app
    }),
  )
  next
}

///|
fn extract_windows_closing_events(
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> Array[@window_pkg.WindowClosing] {
  let events : Array[@window_pkg.WindowClosing] = []
  if !main_world.contains_message(@window_pkg.ecs_key_window_closing) {
    return events
  }
  ensure_extract_windows_message_cursors(render_world).modify(fn(state) {
    let reader = main_world.message_reader(
      @window_pkg.ecs_key_window_closing,
      cursor=state.window_closing,
    )
    for event in reader.read() {
      events.push(event)
    }
    state.window_closing = reader.cursor()
  })
  events
}

///|
fn extracted_window_from_components(
  entity : @core.Entity,
  window : @window_pkg.Window,
  handle : @window_pkg.RawHandleWrapper,
) -> ExtractedWindow {
  ExtractedWindow::new(
    entity,
    handle,
    window.physical_width(),
    window.physical_height(),
    window.present_mode,
    window.desired_maximum_frame_latency,
    window.composite_alpha_mode,
  )
}

///|
fn update_extracted_window_from_components(
  previous : ExtractedWindow,
  window : @window_pkg.Window,
) -> ExtractedWindow {
  let next = previous
  if next.swap_chain_texture is None {
    next.swap_chain_texture_view = None
  }
  let new_width = window.physical_width().max(1)
  let new_height = window.physical_height().max(1)
  next.size_changed = new_width != next.physical_width ||
    new_height != next.physical_height
  next.present_mode_changed = window.present_mode != next.present_mode
  if next.size_changed {
    next.physical_width = new_width
    next.physical_height = new_height
  }
  if next.present_mode_changed {
    next.present_mode = window.present_mode
  }
  next
}

///|
pub fn extract_windows(
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  let extracted_windows = ensure_extracted_windows(render_world)
  let window_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Read[@window_pkg.Window],
      @ecs.Read[@window_pkg.RawHandleWrapper],
      @ecs.Read[@window_pkg.PrimaryWindow]?,
    ),
    @ecs.All,
  ] = @ecs.query(main_world)
  try! window_query.view(fn(_query_entity, data) {
    let (entity, window_ref, handle_ref, primary_ref) = data
    extracted_windows.modify(fn(windows) {
      if primary_ref is Some(_) {
        windows.primary = Some(entity)
      }
      let previous = windows.get(entity)
      let next = match previous {
        Some(existing) =>
          update_extracted_window_from_components(existing, window_ref.value())
        None =>
          extracted_window_from_components(
            entity,
            window_ref.value(),
            handle_ref.value(),
          )
      }
      windows.insert(entity, next)
    })
  })

  let closing_events = extract_windows_closing_events(main_world, render_world)
  if closing_events.length() == 0 {
    return
  }
  let window_surfaces = ensure_window_surfaces(render_world)
  for closing_window in closing_events {
    extracted_windows.modify(fn(windows) {
      windows.remove(closing_window.window)
    })
    window_surfaces.modify(fn(surfaces) {
      surfaces.remove(closing_window.window)
    })
  }
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
