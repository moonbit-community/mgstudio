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
pub(all) enum SystemCursorIcon {
  Default
  ContextMenu
  Help
  Pointer
  Progress
  Wait
  Cell
  Crosshair
  Text
  VerticalText
  Alias
  Copy
  Move
  NoDrop
  NotAllowed
  Grab
  Grabbing
  EResize
  NResize
  NeResize
  NwResize
  SResize
  SeResize
  SwResize
  WResize
  EwResize
  NsResize
  NeswResize
  NwseResize
  ColResize
  RowResize
  AllScroll
  ZoomIn
  ZoomOut
} derive(Eq, Debug)

///|
pub fn SystemCursorIcon::to_native(
  self : SystemCursorIcon,
) -> @window_core.CursorIcon {
  match self {
    Default => @window_core.CursorIcon::Default
    ContextMenu => @window_core.CursorIcon::ContextMenu
    Help => @window_core.CursorIcon::Help
    Pointer => @window_core.CursorIcon::Pointer
    Progress => @window_core.CursorIcon::Progress
    Wait => @window_core.CursorIcon::Wait
    Cell => @window_core.CursorIcon::Cell
    Crosshair => @window_core.CursorIcon::Crosshair
    Text => @window_core.CursorIcon::Text
    VerticalText => @window_core.CursorIcon::VerticalText
    Alias => @window_core.CursorIcon::Alias
    Copy => @window_core.CursorIcon::Copy
    Move => @window_core.CursorIcon::Move
    NoDrop => @window_core.CursorIcon::NoDrop
    NotAllowed => @window_core.CursorIcon::NotAllowed
    Grab => @window_core.CursorIcon::Grab
    Grabbing => @window_core.CursorIcon::Grabbing
    EResize => @window_core.CursorIcon::EResize
    NResize => @window_core.CursorIcon::NResize
    NeResize => @window_core.CursorIcon::NeResize
    NwResize => @window_core.CursorIcon::NwResize
    SResize => @window_core.CursorIcon::SResize
    SeResize => @window_core.CursorIcon::SeResize
    SwResize => @window_core.CursorIcon::SwResize
    WResize => @window_core.CursorIcon::WResize
    EwResize => @window_core.CursorIcon::EwResize
    NsResize => @window_core.CursorIcon::NsResize
    NeswResize => @window_core.CursorIcon::NeswResize
    NwseResize => @window_core.CursorIcon::NwseResize
    ColResize => @window_core.CursorIcon::ColResize
    RowResize => @window_core.CursorIcon::RowResize
    AllScroll => @window_core.CursorIcon::AllScroll
    ZoomIn => @window_core.CursorIcon::ZoomIn
    ZoomOut => @window_core.CursorIcon::ZoomOut
  }
}

///|
pub fn SystemCursorIcon::from_native(
  icon : @window_core.CursorIcon,
) -> SystemCursorIcon {
  match icon {
    @window_core.CursorIcon::Default => Default
    @window_core.CursorIcon::ContextMenu => ContextMenu
    @window_core.CursorIcon::Help => Help
    @window_core.CursorIcon::Pointer => Pointer
    @window_core.CursorIcon::Progress => Progress
    @window_core.CursorIcon::Wait => Wait
    @window_core.CursorIcon::Cell => Cell
    @window_core.CursorIcon::Crosshair => Crosshair
    @window_core.CursorIcon::Text => Text
    @window_core.CursorIcon::VerticalText => VerticalText
    @window_core.CursorIcon::Alias => Alias
    @window_core.CursorIcon::Copy => Copy
    @window_core.CursorIcon::Move => Move
    @window_core.CursorIcon::NoDrop => NoDrop
    @window_core.CursorIcon::NotAllowed => NotAllowed
    @window_core.CursorIcon::Grab => Grab
    @window_core.CursorIcon::Grabbing => Grabbing
    @window_core.CursorIcon::EResize => EResize
    @window_core.CursorIcon::NResize => NResize
    @window_core.CursorIcon::NeResize => NeResize
    @window_core.CursorIcon::NwResize => NwResize
    @window_core.CursorIcon::SResize => SResize
    @window_core.CursorIcon::SeResize => SeResize
    @window_core.CursorIcon::SwResize => SwResize
    @window_core.CursorIcon::WResize => WResize
    @window_core.CursorIcon::EwResize => EwResize
    @window_core.CursorIcon::NsResize => NsResize
    @window_core.CursorIcon::NeswResize => NeswResize
    @window_core.CursorIcon::NwseResize => NwseResize
    @window_core.CursorIcon::ColResize => ColResize
    @window_core.CursorIcon::RowResize => RowResize
    @window_core.CursorIcon::AllScroll => AllScroll
    @window_core.CursorIcon::ZoomIn => ZoomIn
    @window_core.CursorIcon::ZoomOut => ZoomOut
  }
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
  System(SystemCursorIcon::Default)
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

///|
pub fn cursor_icon_from_custom(cursor : CustomCursor) -> CursorIcon {
  CursorIcon::from_custom(cursor)
}

///|
pub fn cursor_icon_from_system(icon : SystemCursorIcon) -> CursorIcon {
  CursorIcon::from(icon)
}
