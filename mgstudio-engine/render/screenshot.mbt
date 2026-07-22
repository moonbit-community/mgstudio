// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_render/src/view/window/screenshot.rs`.

///|
pub type ManualTextureViewHandle = @render_view_window.ManualTextureViewHandle

///|
pub(all) enum ScreenshotTarget {
  Window(@window.WindowRef)
  Image(@asset.Handle[@asset.Image])
  TextureView(ManualTextureViewHandle)
}

///|
pub struct Screenshot {
  target : ScreenshotTarget
}

///|
pub struct Capturing {}

///|
pub struct Captured {}

///|
pub(all) struct ScreenshotCaptured {
  entity : @core.Entity
  image : @asset.Image
}

///|
let screenshot_captured_event_key : @ecs.EventKey[ScreenshotCaptured] = @ecs.register_event(
  debug_name="mgstudio_render::view::window::ScreenshotCaptured",
)

///|
priv struct PendingScreenshotEntityCapture {
  capture_id : Int
  entity : @core.Entity
}

///|
priv struct PendingScreenshotEntityCaptures {
  captures : Array[PendingScreenshotEntityCapture]
}

///|
priv struct CapturedScreenshot {
  entity : @core.Entity
  image : @asset.Image
}

///|
priv struct CapturedScreenshots {
  captures : Array[CapturedScreenshot]
}

///|
priv struct RenderScreenshotTargets {
  targets : Map[@core.Entity, String]
}

///|
priv struct RenderScreenshotsPrepared {
  prepared : Map[@core.Entity, Int]
}

///|
let pending_screenshot_entity_captures_resource_key : @ecs.ResourceKey[
  PendingScreenshotEntityCaptures,
] = @ecs.register_resource(
  debug_name="mgstudio_render::view::window::PendingScreenshotEntityCaptures",
)

///|
let captured_screenshots_resource_key : @ecs.ResourceKey[CapturedScreenshots] = @ecs.register_resource(
  debug_name="mgstudio_render::view::window::CapturedScreenshots",
)

///|
let render_screenshot_targets_resource_key : @ecs.ResourceKey[
  RenderScreenshotTargets,
] = @ecs.register_resource(
  debug_name="mgstudio_render::view::window::RenderScreenshotTargets",
)

///|
let render_screenshots_prepared_resource_key : @ecs.ResourceKey[
  RenderScreenshotsPrepared,
] = @ecs.register_resource(
  debug_name="mgstudio_render::view::window::RenderScreenshotsPrepared",
)

///|
fn PendingScreenshotEntityCaptures::PendingScreenshotEntityCaptures() -> PendingScreenshotEntityCaptures {
  { captures: [] }
}

///|
fn CapturedScreenshots::CapturedScreenshots() -> CapturedScreenshots {
  { captures: [] }
}

///|
fn RenderScreenshotTargets::RenderScreenshotTargets() -> RenderScreenshotTargets {
  let targets = RenderScreenshotTargets::{ targets: Map([]) }
  if targets.targets.length() != 0 {
    abort("RenderScreenshotTargets must initialize empty")
  }
  targets
}

///|
fn RenderScreenshotsPrepared::RenderScreenshotsPrepared() -> RenderScreenshotsPrepared {
  let prepared = RenderScreenshotsPrepared::{ prepared: Map([]) }
  if prepared.prepared.length() != 0 {
    abort("RenderScreenshotsPrepared must initialize empty")
  }
  prepared
}

///|
pub let screenshot_trigger_system_set : @app.SystemSet = @app.system_set(
  "mgstudio.render.trigger_screenshots",
)

///|
pub struct ScreenshotPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn ScreenshotPlugin::ScreenshotPlugin() -> ScreenshotPlugin {
  ScreenshotPlugin::{  }
}

///|
pub impl @app.Plugin for ScreenshotPlugin with fn name(_self) {
  "mgstudio.render.ScreenshotPlugin"
}

///|
pub impl @app.Plugin for ScreenshotPlugin with fn build(_self, app) {
  screenshot_plugin_install(app)
}

///|
pub fn Screenshot::window(window : @core.Entity) -> Screenshot {
  { target: Window(Entity(window)) }
}

///|
pub fn Screenshot::primary_window() -> Screenshot {
  { target: Window(Primary) }
}

///|
pub fn Screenshot::image(image : @asset.Handle[@asset.Image]) -> Screenshot {
  { target: Image(image) }
}

///|
pub fn Screenshot::texture_view(
  texture_view : ManualTextureViewHandle,
) -> Screenshot {
  { target: TextureView(texture_view) }
}

///|
pub let ecs_key_screenshot : @ecs.ComponentKey[Screenshot] = @ecs.register_component(
  debug_name="mgstudio_render::view::window::Screenshot",
)

///|
pub let ecs_key_capturing : @ecs.ComponentKey[Capturing] = @ecs.register_component(
  debug_name="mgstudio_render::view::window::Capturing",
)

///|
pub let ecs_key_captured : @ecs.ComponentKey[Captured] = @ecs.register_component(
  debug_name="mgstudio_render::view::window::Captured",
)

///|
pub impl @ecs.Component for Screenshot with fn component() {
  ecs_key_screenshot
}

///|
pub impl @ecs.Component for Capturing with fn component() {
  ecs_key_capturing
}

///|
pub impl @ecs.Component for Captured with fn component() {
  ecs_key_captured
}

///|
pub impl @ecs.TriggerEvent for ScreenshotCaptured with fn observer_event() {
  screenshot_captured_event_key
}

///|
pub impl @ecs.TriggerEvent for ScreenshotCaptured with fn observer_entity(self) {
  Some(self.entity)
}

///|
pub impl @ecs.TriggerEvent for ScreenshotCaptured with fn set_observer_entity(
  self,
  entity,
) {
  { ..self, entity, }
}

///|
pub impl @ecs.TriggerEvent for ScreenshotCaptured with fn auto_propagate(_self) {
  false
}

///|
pub impl @ecs.TriggerEvent for ScreenshotCaptured with fn debug_name() {
  "ScreenshotCaptured"
}

///|
fn screenshot_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> Screenshot? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn ensure_pending_screenshot_entity_captures(
  world : @ecs.World,
) -> @ecs.ResourceMut[PendingScreenshotEntityCaptures] {
  match
    world.get_resource_mut(pending_screenshot_entity_captures_resource_key) {
    Some(resource) => resource
    None => {
      world.insert_resource(
        pending_screenshot_entity_captures_resource_key,
        PendingScreenshotEntityCaptures(),
      )
      world
      .get_resource_mut(pending_screenshot_entity_captures_resource_key)
      .unwrap()
    }
  }
}

///|
fn ensure_captured_screenshots(
  world : @ecs.World,
) -> @ecs.ResourceMut[CapturedScreenshots] {
  match world.get_resource_mut(captured_screenshots_resource_key) {
    Some(resource) => resource
    None => {
      world.insert_resource(
        captured_screenshots_resource_key,
        CapturedScreenshots(),
      )
      world.get_resource_mut(captured_screenshots_resource_key).unwrap()
    }
  }
}

///|
fn ensure_render_screenshot_targets(
  world : @ecs.World,
) -> @ecs.ResourceMut[RenderScreenshotTargets] {
  match world.get_resource_mut(render_screenshot_targets_resource_key) {
    Some(resource) => resource
    None => {
      world.insert_resource(
        render_screenshot_targets_resource_key,
        RenderScreenshotTargets(),
      )
      world.get_resource_mut(render_screenshot_targets_resource_key).unwrap()
    }
  }
}

///|
fn init_pending_screenshot_entity_captures_resource(world : @ecs.World) -> Unit {
  if world
    .resource(pending_screenshot_entity_captures_resource_key)
    .is_present() {
    return
  }
  world.insert_resource(
    pending_screenshot_entity_captures_resource_key,
    PendingScreenshotEntityCaptures(),
  )
}

///|
fn init_captured_screenshots_resource(world : @ecs.World) -> Unit {
  if world.resource(captured_screenshots_resource_key).is_present() {
    return
  }
  world.insert_resource(
    captured_screenshots_resource_key,
    CapturedScreenshots(),
  )
}

///|
fn init_render_screenshot_targets_resource(world : @ecs.World) -> Unit {
  if world.resource(render_screenshot_targets_resource_key).is_present() {
    return
  }
  world.insert_resource(
    render_screenshot_targets_resource_key,
    RenderScreenshotTargets(),
  )
}

///|
fn init_render_screenshots_prepared_resource(world : @ecs.World) -> Unit {
  if world.resource(render_screenshots_prepared_resource_key).is_present() {
    return
  }
  world.insert_resource(
    render_screenshots_prepared_resource_key,
    RenderScreenshotsPrepared(),
  )
}

///|
fn screenshot_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let mut next = app
  init_pending_screenshot_entity_captures_resource(next.world())
  init_captured_screenshots_resource(next.world())
  init_render_screenshot_targets_resource(next.world())
  next = try_with_render_app(next, fn(render_sub_app) {
    init_render_screenshot_targets_resource(render_sub_app.world())
    init_render_screenshots_prepared_resource(render_sub_app.world())
    render_sub_app
  })
  next = next
    .add_systems(
      First,
      @app.system(screenshot_clear_system).named(
        "mgstudio_render::screenshot_clear_system",
      ),
    )
    .add_systems(
      Update,
      (
        @app.system(extract_screenshots)
        .named("mgstudio_render::extract_screenshots")
        .in_set(screenshot_trigger_system_set),
        @app.system(screenshot_queue_capture_requests)
        .named("mgstudio_render::screenshot_queue_capture_requests")
        .in_set(screenshot_trigger_system_set),
        @app.system(screenshot_collect_capture_requests)
        .named("mgstudio_render::screenshot_collect_capture_requests")
        .in_set(screenshot_trigger_system_set),
        @app.system(trigger_screenshots)
        .named("mgstudio_render::trigger_screenshots")
        .in_set(screenshot_trigger_system_set),
      )
      |> @app.chain(),
    )
  next
}

///|
fn screenshot_warn(message : String) -> Unit {
  host_debug_string(value="[screenshot] \{message}")
}

///|
fn array_contains(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}

///|
fn screenshot_target_key(
  world : @ecs.World,
  screenshot : Screenshot,
) -> String? {
  match screenshot.target {
    Window(window_ref) => {
      guard @window.window_entity_for_ref(world, window_ref)
        is Some(window_entity) else {
        return None
      }
      Some("window:\{window_entity.id.to_string()}")
    }
    Image(image) => Some("image:\{image.id().to_string()}")
    TextureView(texture_view) =>
      Some("texture_view:\{texture_view.value().to_string()}")
  }
}

///|
fn screenshot_request_capture(
  world : @ecs.World,
  screenshot : Screenshot,
) -> Int {
  match screenshot.target {
    Window(window_ref) => {
      guard @window.window_host_window_for_ref(world, window_ref)
        is Some(host_window) else {
        return 0
      }
      let target_id = host_gpu_surface_target_id_for_window(host_window)
      if target_id <= 0 {
        match window_ref {
          Primary => return screenshot_capture_surface_request()
          Entity(_) => return 0
        }
      }
      screenshot_capture_surface_target_request(target_id~)
    }
    Image(image) => screenshot_capture_texture_request(texture_id=image.id())
    TextureView(texture_view) =>
      screenshot_capture_texture_request(texture_id=texture_view.value())
  }
}

///|
fn extract_screenshots(world : @ecs.World) -> Unit {
  let entities : Array[@core.Entity] = []
  let seen_targets : Array[String] = []
  try! world
  .query_entities_filtered(
    (@ecs.With::new(ecs_key_screenshot), @ecs.Without::new(ecs_key_capturing)),
  )
  .view(fn(_query_entity, entity) { entities.push(entity) })
  let targets = ensure_render_screenshot_targets(world)
  targets.modify(fn(state) { state.targets.clear() })
  for entity in entities {
    guard screenshot_component(world, entity) is Some(screenshot) else {
      continue
    }
    guard screenshot_target_key(world, screenshot) is Some(target_key) else {
      continue
    }
    if array_contains(seen_targets, target_key) {
      screenshot_warn(
        "duplicate screenshot target skipped for entity \{entity.id.to_string()}",
      )
      world.despawn(entity) catch {
        _ => ()
      }
      continue
    }
    seen_targets.push(target_key)
    try! (world.entity_mut(entity).insert_component(Capturing::{  }) |> ignore)
    targets.modify(fn(state) { state.targets.set(entity, target_key) })
  }
}

///|
pub fn screenshot_queue_capture_requests(world : @ecs.World) -> Unit {
  let entities : Array[@core.Entity] = []
  let targets = ensure_render_screenshot_targets(world)
  for entry in targets.peek().targets.iter() {
    let (entity, _) = entry
    entities.push(entity)
  }
  for entity in entities {
    guard world.is_alive(entity) else { continue }
    guard screenshot_component(world, entity) is Some(screenshot) else {
      continue
    }
    let capture_id = screenshot_request_capture(world, screenshot)
    if capture_id <= 0 {
      continue
    }
    ensure_pending_screenshot_entity_captures(world).modify(fn(state) {
      state.captures.push({ capture_id, entity })
    })
  }
}

///|
fn screenshot_collect_capture_requests(world : @ecs.World) -> Unit {
  let remaining : Array[PendingScreenshotEntityCapture] = []
  let pending = ensure_pending_screenshot_entity_captures(world)
  let completed : Array[CapturedScreenshot] = []
  for pending_capture in pending.peek().captures {
    let capture_id = pending_capture.capture_id
    let entity = pending_capture.entity
    guard world.is_alive(entity) else { continue }
    guard screenshot_take_capture_result(capture_id) is Some(capture) else {
      remaining.push(pending_capture)
      continue
    }
    completed.push({
      entity,
      image: @asset.Image::new(capture.width, capture.height, capture.pixels),
    })
  }
  pending.set({ captures: remaining })
  if completed.length() > 0 {
    ensure_captured_screenshots(world).modify(fn(state) {
      for capture in completed {
        state.captures.push(capture)
      }
    })
  }
}

///|
pub fn trigger_screenshots(world : @ecs.World) -> Unit {
  let captured_screenshots = ensure_captured_screenshots(world)
  let captures = captured_screenshots.peek().captures.copy()
  captured_screenshots.set(CapturedScreenshots())
  for capture in captures {
    let entity = capture.entity
    guard world.is_alive(entity) else { continue }
    try! (world.entity_mut(entity).insert_component(Captured::{  }) |> ignore)
    world.trigger(
      ScreenshotCaptured::{ entity, image: capture.image },
      caller=Some("mgstudio_render::view::window::trigger_screenshots"),
    )
  }
}

///|
fn screenshot_write_capture_to_disk(
  capture : ScreenshotCaptured,
  path : String,
) -> Unit {
  let pixels = capture.image.pixels
  let opaque_pixels = if pixels.length() % 4 != 0 {
    pixels
  } else {
    let out : Array[Byte] = []
    for i in 0..<(pixels.length() / 4) {
      let base = i * 4
      out.push(pixels[base])
      out.push(pixels[base + 1])
      out.push(pixels[base + 2])
      out.push((255).to_byte())
    }
    Bytes::from_array(out)
  }
  @asset.host_asset_save_rgba8_png(
    width=capture.image.width,
    height=capture.image.height,
    pixels=opaque_pixels,
    path~,
  )
}

///|
pub fn save_to_disk(path : String) -> (@ecs.On[ScreenshotCaptured]) -> Unit {
  fn(event : @ecs.On[ScreenshotCaptured]) {
    let capture = event.event()
    screenshot_write_capture_to_disk(capture, path)
  }
}

///|
pub fn screenshot_clear_system(world : @ecs.World) -> Unit {
  let entities : Array[@core.Entity] = []
  try! world
  .query_entities_filtered(@ecs.With::new(ecs_key_captured))
  .view(fn(_query_entity, entity) { entities.push(entity) })
  for entity in entities {
    world.despawn(entity) catch {
      _ => ()
    }
  }
}
