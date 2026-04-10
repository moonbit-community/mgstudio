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
pub(all) enum CursorGrabMode {
  GrabNone
  GrabConfined
  GrabLocked
} derive(Eq, Debug)

///|
pub(all) enum CursorIcon {
  System(SystemCursorIcon)
  Custom(CustomCursor)
}

///|
pub fn CursorIcon::from(icon : SystemCursorIcon) -> CursorIcon {
  System(icon)
}

///|
pub fn CursorIcon::from_custom(cursor : CustomCursor) -> CursorIcon {
  Custom(cursor)
}

///|
pub fn CursorIcon::as_system(self : CursorIcon) -> SystemCursorIcon? {
  match self {
    System(icon) => Some(icon)
    _ => None
  }
}

///|
pub impl Default for CursorIcon with default() {
  System(@window_core.CursorIcon::Default)
}

///|
pub struct CustomCursorImage {
  handle : @asset.Handle[@asset.Image]
  texture_atlas : @asset.TextureAtlas?
  flip_x : Bool
  flip_y : Bool
  rect : @math.URect?
  hotspot : (Int, Int)
}

///|
pub fn CustomCursorImage::new(
  handle : @asset.Handle[@asset.Image],
  hotspot : (Int, Int),
  texture_atlas? : @asset.TextureAtlas? = None,
  flip_x? : Bool = false,
  flip_y? : Bool = false,
  rect? : @math.URect? = None,
) -> CustomCursorImage {
  CustomCursorImage::{ handle, texture_atlas, flip_x, flip_y, rect, hotspot }
}

///|
pub struct CustomCursorUrl {
  url : String
  hotspot : (Int, Int)
}

///|
pub fn CustomCursorUrl::new(
  url : String,
  hotspot : (Int, Int),
) -> CustomCursorUrl {
  CustomCursorUrl::{ url, hotspot }
}

///|
pub(all) enum CustomCursor {
  Image(CustomCursorImage)
  Url(CustomCursorUrl)
}

///|
pub(all) struct CursorOptions {
  mut visible : Bool
  mut grab_mode : CursorGrabMode
  hit_test : Bool
} derive(Eq, Debug)

///|
pub fn CursorOptions::default() -> CursorOptions {
  CursorOptions::{ visible: true, grab_mode: GrabNone, hit_test: true }
}

///|
pub let ecs_key_cursor_options : @ecs.ComponentKey[CursorOptions] = @ecs.register_component(
  debug_name="mgstudio_window::CursorOptions",
)

///|
pub let ecs_key_cursor_icon : @ecs.ComponentKey[CursorIcon] = @ecs.register_component(
  debug_name="mgstudio_window::CursorIcon",
)

///|
pub impl @ecs.Component for CursorOptions with component() {
  ecs_key_cursor_options
}

///|
pub impl @ecs.Component for CursorIcon with component() {
  ecs_key_cursor_icon
}
