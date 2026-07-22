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
pub fn SystemCursorIcon::to_native(
  self : SystemCursorIcon,
) -> @window_core.CursorIcon {
  match self {
    Default => Default
    ContextMenu => ContextMenu
    Help => Help
    Pointer => Pointer
    Progress => Progress
    Wait => Wait
    Cell => Cell
    Crosshair => Crosshair
    Text => Text
    VerticalText => VerticalText
    Alias => Alias
    Copy => Copy
    Move => Move
    NoDrop => NoDrop
    NotAllowed => NotAllowed
    Grab => Grab
    Grabbing => Grabbing
    EResize => EResize
    NResize => NResize
    NeResize => NeResize
    NwResize => NwResize
    SResize => SResize
    SeResize => SeResize
    SwResize => SwResize
    WResize => WResize
    EwResize => EwResize
    NsResize => NsResize
    NeswResize => NeswResize
    NwseResize => NwseResize
    ColResize => ColResize
    RowResize => RowResize
    AllScroll => AllScroll
    ZoomIn => ZoomIn
    ZoomOut => ZoomOut
  }
}

///|
pub fn SystemCursorIcon::from_native(
  icon : @window_core.CursorIcon,
) -> SystemCursorIcon {
  match icon {
    Default => Default
    ContextMenu => ContextMenu
    Help => Help
    Pointer => Pointer
    Progress => Progress
    Wait => Wait
    Cell => Cell
    Crosshair => Crosshair
    Text => Text
    VerticalText => VerticalText
    Alias => Alias
    Copy => Copy
    Move => Move
    NoDrop => NoDrop
    NotAllowed => NotAllowed
    Grab => Grab
    Grabbing => Grabbing
    EResize => EResize
    NResize => NResize
    NeResize => NeResize
    NwResize => NwResize
    SResize => SResize
    SeResize => SeResize
    SwResize => SwResize
    WResize => WResize
    EwResize => EwResize
    NsResize => NsResize
    NeswResize => NeswResize
    NwseResize => NwseResize
    ColResize => ColResize
    RowResize => RowResize
    AllScroll => AllScroll
    ZoomIn => ZoomIn
    ZoomOut => ZoomOut
  }
}

///|
pub fn cursor_icon_from_system(icon : SystemCursorIcon) -> CursorIcon {
  CursorIcon::from(icon)
}
