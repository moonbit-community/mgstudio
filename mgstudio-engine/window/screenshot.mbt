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
pub type ManualTextureViewHandle = Int

///|
pub(all) enum ScreenshotTarget {
  Window(WindowRef)
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
pub struct ScreenshotCaptured {
  entity : @core.Entity
  image : @asset.Image
}

///|
priv struct PendingScreenshotEntityCapture {
  capture_id : Int
  entity : @core.Entity
}

///|
let pending_screenshot_entity_captures : Ref[
  Array[PendingScreenshotEntityCapture],
] = Ref([])

///|
pub fn Screenshot::window(window : @core.Entity) -> Screenshot {
  { target: Window(WindowRef::Entity(window)) }
}

///|
pub fn Screenshot::primary_window() -> Screenshot {
  { target: Window(WindowRef::Primary) }
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
pub let ecs_key_screenshot_captured : @ecs.ComponentKey[ScreenshotCaptured] = @ecs.register_component(
  debug_name="mgstudio_render::view::window::ScreenshotCaptured",
)

///|
pub impl @ecs.Component for Screenshot with component() {
  ecs_key_screenshot
}

///|
pub impl @ecs.Component for Capturing with component() {
  ecs_key_capturing
}

///|
pub impl @ecs.Component for Captured with component() {
  ecs_key_captured
}

///|
pub impl @ecs.Component for ScreenshotCaptured with component() {
  ecs_key_screenshot_captured
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
fn screenshot_captured_component(
  world : @ecs.World,
  entity : @core.Entity,
) -> ScreenshotCaptured? {
  try world.entity(entity).get() catch {
    _ => None
  } noraise {
    value => value
  }
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
      guard window_entity_for_ref(world, window_ref) is Some(window_entity) else {
        return None
      }
      Some("window:\{window_entity.id.to_string()}")
    }
    Image(image) => Some("image:\{image.id().to_string()}")
    TextureView(texture_view) =>
      Some("texture_view:\{texture_view.to_string()}")
  }
}

///|
fn screenshot_request_capture(
  world : @ecs.World,
  screenshot : Screenshot,
) -> Int {
  match screenshot.target {
    Window(window_ref) => {
      guard window_host_window_for_ref(world, window_ref) is Some(host_window) else {
        return 0
      }
      let target_id = @render.host_gpu_surface_target_id_for_window(host_window)
      if target_id <= 0 {
        return 0
      }
      @render.screenshot_capture_surface_target_request(target_id~)
    }
    Image(image) =>
      @render.screenshot_capture_texture_request(texture_id=image.id())
    TextureView(texture_view) =>
      @render.screenshot_capture_texture_request(texture_id=texture_view)
  }
}

///|
pub fn screenshot_queue_capture_requests(world : @ecs.World) -> Unit {
  let entities : Array[@core.Entity] = []
  let seen_targets : Array[String] = []
  try! world
  .query_entities_filtered(
    (
      @ecs.With::new(ecs_key_screenshot),
      @ecs.Without::new(ecs_key_capturing),
      @ecs.Without::new(ecs_key_captured),
    ),
  )
  .view(fn(_query_entity, entity) { entities.push(entity) })
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
    let capture_id = screenshot_request_capture(world, screenshot)
    if capture_id <= 0 {
      continue
    }
    try! (world.entity_mut(entity).insert_component(Capturing::{  }) |> ignore)
    pending_screenshot_entity_captures.val.push(PendingScreenshotEntityCapture::{
      capture_id,
      entity,
    })
  }
}

///|
pub fn screenshot_finalize_capture_requests(world : @ecs.World) -> Unit {
  let remaining : Array[PendingScreenshotEntityCapture] = []
  for pending_capture in pending_screenshot_entity_captures.val {
    let capture_id = pending_capture.capture_id
    let entity = pending_capture.entity
    guard world.is_alive(entity) else { continue }
    guard @render.screenshot_take_capture_result(capture_id) is Some(capture) else {
      remaining.push(pending_capture)
      continue
    }
    ignore(
      try! world
      .entity_mut(entity)
      .insert_component(ScreenshotCaptured::{
        entity,
        image: @asset.Image::new(capture.width, capture.height, capture.pixels),
      }),
    )
    try! (world.entity_mut(entity).insert_component(Captured::{  }) |> ignore)
  }
  pending_screenshot_entity_captures.val = remaining
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
pub fn save_to_disk(
  path : String,
) -> (@ecs.ComponentOn[@ecs.Insert, ScreenshotCaptured]) -> Unit {
  fn(event : @ecs.ComponentOn[@ecs.Insert, ScreenshotCaptured]) {
    let world = @ecs.current_observer_world_abort_missing()
    guard screenshot_captured_component(world, event.entity) is Some(capture) else {
      return
    }
    screenshot_write_capture_to_disk(capture, path)
  }
}

///|
fn screenshot_clear_system(world : @ecs.World) -> Unit {
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
