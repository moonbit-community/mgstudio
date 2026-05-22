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
  EcsPayload_dev_tools_DebugPickingMode(DebugPickingMode)
  EcsPayload_dev_tools_FpsOverlayConfig(FpsOverlayConfig)
  EcsPayload_dev_tools_FpsText(FpsText)
  EcsPayload_dev_tools_FrameTimeGraph(FrameTimeGraph)
  EcsPayload_dev_tools_EasyScreenshotConfig(EasyScreenshotConfig)
  EcsPayload_dev_tools_EasyScreenshotState(EasyScreenshotState)
  EcsPayload_dev_tools_DiagnosticsOverlay(DiagnosticsOverlay)
  EcsPayload_dev_tools_DiagnosticsOverlayPlane(DiagnosticsOverlayPlane)
  EcsPayload_dev_tools_DiagnosticsOverlayWindow(DiagnosticsOverlayWindow)
  EcsPayload_dev_tools_DiagnosticsOverlayHeader(DiagnosticsOverlayHeader)
  EcsPayload_dev_tools_FrametimeGraphMaterial(FrametimeGraphMaterial)
}

///|
pub impl @ecs.EcsPayloadCodec for DebugPickingMode with to_ecs_payload(self) {
  EcsPayload_dev_tools_DebugPickingMode(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DebugPickingMode with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_DebugPickingMode(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FpsOverlayConfig with to_ecs_payload(self) {
  EcsPayload_dev_tools_FpsOverlayConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FpsOverlayConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_FpsOverlayConfig(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for FpsText with to_ecs_payload(self) {
  EcsPayload_dev_tools_FpsText(self)
}

///|
impl @ecs.EcsPayloadCodec for FpsText with from_ecs_payload(payload) {
  match payload {
    EcsPayload_dev_tools_FpsText(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for FrameTimeGraph with to_ecs_payload(self) {
  EcsPayload_dev_tools_FrameTimeGraph(self)
}

///|
impl @ecs.EcsPayloadCodec for FrameTimeGraph with from_ecs_payload(payload) {
  match payload {
    EcsPayload_dev_tools_FrameTimeGraph(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for EasyScreenshotConfig with to_ecs_payload(self) {
  EcsPayload_dev_tools_EasyScreenshotConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for EasyScreenshotConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_EasyScreenshotConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for EasyScreenshotState with to_ecs_payload(self) {
  EcsPayload_dev_tools_EasyScreenshotState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for EasyScreenshotState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_EasyScreenshotState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DiagnosticsOverlay with to_ecs_payload(self) {
  EcsPayload_dev_tools_DiagnosticsOverlay(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DiagnosticsOverlay with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_DiagnosticsOverlay(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DiagnosticsOverlayPlane with to_ecs_payload(
  self,
) {
  EcsPayload_dev_tools_DiagnosticsOverlayPlane(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DiagnosticsOverlayPlane with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_DiagnosticsOverlayPlane(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DiagnosticsOverlayWindow with to_ecs_payload(self) {
  EcsPayload_dev_tools_DiagnosticsOverlayWindow(self)
}

///|
impl @ecs.EcsPayloadCodec for DiagnosticsOverlayWindow with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_DiagnosticsOverlayWindow(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DiagnosticsOverlayHeader with to_ecs_payload(self) {
  EcsPayload_dev_tools_DiagnosticsOverlayHeader(self)
}

///|
impl @ecs.EcsPayloadCodec for DiagnosticsOverlayHeader with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_DiagnosticsOverlayHeader(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FrametimeGraphMaterial with to_ecs_payload(
  self,
) {
  EcsPayload_dev_tools_FrametimeGraphMaterial(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FrametimeGraphMaterial with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_FrametimeGraphMaterial(value) => Some(value)
    _ => None
  }
}
