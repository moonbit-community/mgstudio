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
pub type ManualTextureViewHandle = Int

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
pub fn window_manual_texture_view_handle(
  texture_id~ : Int,
  mip_level~ : Int,
) -> ManualTextureViewHandle {
  texture_id * 10_000 + mip_level
}
