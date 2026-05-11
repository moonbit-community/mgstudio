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
extenum @ecs.EcsPayload += {
  EcsPayload_window_Screenshot(Screenshot)
  EcsPayload_window_Capturing(Capturing)
  EcsPayload_window_Captured(Captured)
  EcsPayload_window_ScreenshotCaptured(ScreenshotCaptured)
  EcsPayload_window_WindowCreated(WindowCreated)
  EcsPayload_window_WindowResized(WindowResized)
  EcsPayload_window_RequestRedraw(RequestRedraw)
  EcsPayload_window_WindowCloseRequested(WindowCloseRequested)
  EcsPayload_window_WindowClosing(WindowClosing)
  EcsPayload_window_WindowClosed(WindowClosed)
  EcsPayload_window_WindowDestroyed(WindowDestroyed)
  EcsPayload_window_CursorMoved(CursorMoved)
  EcsPayload_window_CursorEntered(CursorEntered)
  EcsPayload_window_CursorLeft(CursorLeft)
  EcsPayload_window_FileDragAndDrop(FileDragAndDrop)
  EcsPayload_window_WindowEvent(WindowEvent)
  EcsPayload_window_WindowMoved(WindowMoved)
  EcsPayload_window_WindowScaleFactorChanged(WindowScaleFactorChanged)
  EcsPayload_window_WindowBackendScaleFactorChanged(
    WindowBackendScaleFactorChanged
  )
  EcsPayload_window_WindowFocused(WindowFocused)
  EcsPayload_window_WindowOccluded(WindowOccluded)
  EcsPayload_window_WindowThemeChanged(WindowThemeChanged)
  EcsPayload_window_AppLifecycle(AppLifecycle)
  EcsPayload_window_Ime(Ime)
  EcsPayload_window_CursorOptions(CursorOptions)
  EcsPayload_window_CursorIcon(CursorIcon)
  EcsPayload_window_RawHandleWrapper(RawHandleWrapper)
  EcsPayload_window_RawHandleWrapperHolder(RawHandleWrapperHolder)
  EcsPayload_window_WindowRuntime(WindowRuntime)
  EcsPayload_window_Window(Window)
  EcsPayload_window_PrimaryWindow(PrimaryWindow)
  EcsPayload_window_ClosingWindow(ClosingWindow)
  EcsPayload_window_Monitor(Monitor)
  EcsPayload_window_PrimaryMonitor(PrimaryMonitor)
}

///|
pub impl @ecs.EcsPayloadCodec for Screenshot with to_ecs_payload(self) {
  EcsPayload_window_Screenshot(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Screenshot with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_Screenshot(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Capturing with to_ecs_payload(self) {
  EcsPayload_window_Capturing(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Capturing with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_Capturing(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Captured with to_ecs_payload(self) {
  EcsPayload_window_Captured(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Captured with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_Captured(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenshotCaptured with to_ecs_payload(self) {
  EcsPayload_window_ScreenshotCaptured(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenshotCaptured with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_window_ScreenshotCaptured(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowCreated with to_ecs_payload(self) {
  EcsPayload_window_WindowCreated(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowCreated with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowCreated(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowResized with to_ecs_payload(self) {
  EcsPayload_window_WindowResized(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowResized with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowResized(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RequestRedraw with to_ecs_payload(self) {
  EcsPayload_window_RequestRedraw(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RequestRedraw with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_RequestRedraw(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowCloseRequested with to_ecs_payload(self) {
  EcsPayload_window_WindowCloseRequested(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowCloseRequested with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_window_WindowCloseRequested(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowClosing with to_ecs_payload(self) {
  EcsPayload_window_WindowClosing(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowClosing with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowClosing(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowClosed with to_ecs_payload(self) {
  EcsPayload_window_WindowClosed(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowClosed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowClosed(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowDestroyed with to_ecs_payload(self) {
  EcsPayload_window_WindowDestroyed(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowDestroyed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowDestroyed(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CursorMoved with to_ecs_payload(self) {
  EcsPayload_window_CursorMoved(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CursorMoved with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_CursorMoved(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CursorEntered with to_ecs_payload(self) {
  EcsPayload_window_CursorEntered(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CursorEntered with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_CursorEntered(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CursorLeft with to_ecs_payload(self) {
  EcsPayload_window_CursorLeft(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CursorLeft with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_CursorLeft(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FileDragAndDrop with to_ecs_payload(self) {
  EcsPayload_window_FileDragAndDrop(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FileDragAndDrop with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_FileDragAndDrop(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowEvent with to_ecs_payload(self) {
  EcsPayload_window_WindowEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowMoved with to_ecs_payload(self) {
  EcsPayload_window_WindowMoved(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowMoved with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowMoved(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowScaleFactorChanged with to_ecs_payload(
  self,
) {
  EcsPayload_window_WindowScaleFactorChanged(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowScaleFactorChanged with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_window_WindowScaleFactorChanged(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowBackendScaleFactorChanged with to_ecs_payload(
  self,
) {
  EcsPayload_window_WindowBackendScaleFactorChanged(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowBackendScaleFactorChanged with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_window_WindowBackendScaleFactorChanged(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowFocused with to_ecs_payload(self) {
  EcsPayload_window_WindowFocused(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowFocused with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowFocused(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowOccluded with to_ecs_payload(self) {
  EcsPayload_window_WindowOccluded(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowOccluded with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowOccluded(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WindowThemeChanged with to_ecs_payload(self) {
  EcsPayload_window_WindowThemeChanged(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WindowThemeChanged with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_window_WindowThemeChanged(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AppLifecycle with to_ecs_payload(self) {
  EcsPayload_window_AppLifecycle(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AppLifecycle with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_AppLifecycle(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Ime with to_ecs_payload(self) {
  EcsPayload_window_Ime(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Ime with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_Ime(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CursorOptions with to_ecs_payload(self) {
  EcsPayload_window_CursorOptions(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CursorOptions with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_CursorOptions(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CursorIcon with to_ecs_payload(self) {
  EcsPayload_window_CursorIcon(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CursorIcon with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_CursorIcon(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RawHandleWrapper with to_ecs_payload(self) {
  EcsPayload_window_RawHandleWrapper(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RawHandleWrapper with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_window_RawHandleWrapper(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RawHandleWrapperHolder with to_ecs_payload(
  self,
) {
  EcsPayload_window_RawHandleWrapperHolder(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RawHandleWrapperHolder with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_window_RawHandleWrapperHolder(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for WindowRuntime with to_ecs_payload(self) {
  EcsPayload_window_WindowRuntime(self)
}

///|
impl @ecs.EcsPayloadCodec for WindowRuntime with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_WindowRuntime(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Window with to_ecs_payload(self) {
  EcsPayload_window_Window(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Window with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_Window(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PrimaryWindow with to_ecs_payload(self) {
  EcsPayload_window_PrimaryWindow(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PrimaryWindow with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_PrimaryWindow(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ClosingWindow with to_ecs_payload(self) {
  EcsPayload_window_ClosingWindow(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ClosingWindow with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_ClosingWindow(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Monitor with to_ecs_payload(self) {
  EcsPayload_window_Monitor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Monitor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_Monitor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PrimaryMonitor with to_ecs_payload(self) {
  EcsPayload_window_PrimaryMonitor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PrimaryMonitor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_window_PrimaryMonitor(value) => Some(value)
    _ => None
  }
}
