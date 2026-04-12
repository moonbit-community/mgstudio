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
// Bevy source: `bevy/crates/bevy_window/src/cursor/system_cursor.rs`.

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
pub fn SystemCursorIcon::to_native(self : SystemCursorIcon) -> @window_core.CursorIcon {
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
pub fn SystemCursorIcon::from_native(icon : @window_core.CursorIcon) -> SystemCursorIcon {
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
pub fn cursor_icon_from_system(icon : SystemCursorIcon) -> CursorIcon {
  CursorIcon::from(icon)
}
