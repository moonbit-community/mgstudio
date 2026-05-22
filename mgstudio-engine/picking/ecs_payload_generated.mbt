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
  EcsPayload_picking_PointerId(PointerId)
  EcsPayload_picking_PointerLocation(PointerLocation)
  EcsPayload_picking_PointerPress(PointerPress)
  EcsPayload_picking_PointerInteraction(PointerInteraction)
  EcsPayload_picking_PointerMap(PointerMap)
  EcsPayload_picking_PointerInput(PointerInput)
  EcsPayload_picking_PointerHits(PointerHits)
  EcsPayload_picking_Pickable(Pickable)
  EcsPayload_picking_SpritePickingCamera(SpritePickingCamera)
  EcsPayload_picking_HoverMap(HoverMap)
  EcsPayload_picking_PreviousHoverMap(PreviousHoverMap)
  EcsPayload_picking_PickingSettings(PickingSettings)
  EcsPayload_picking_PickingState(PickingState)
  EcsPayload_picking_PointerInputSettings(PointerInputSettings)
  EcsPayload_picking_SpritePickingSettings(SpritePickingSettings)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerId with to_ecs_payload(self) {
  EcsPayload_picking_PointerId(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerId with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PointerId(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointerLocation with to_ecs_payload(self) {
  EcsPayload_picking_PointerLocation(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerLocation with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PointerLocation(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointerPress with to_ecs_payload(self) {
  EcsPayload_picking_PointerPress(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerPress with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PointerPress(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointerInteraction with to_ecs_payload(self) {
  EcsPayload_picking_PointerInteraction(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerInteraction with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_picking_PointerInteraction(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointerMap with to_ecs_payload(self) {
  EcsPayload_picking_PointerMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerMap with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PointerMap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointerInput with to_ecs_payload(self) {
  EcsPayload_picking_PointerInput(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerInput with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PointerInput(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointerHits with to_ecs_payload(self) {
  EcsPayload_picking_PointerHits(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerHits with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PointerHits(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Pickable with to_ecs_payload(self) {
  EcsPayload_picking_Pickable(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Pickable with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_Pickable(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpritePickingCamera with to_ecs_payload(self) {
  EcsPayload_picking_SpritePickingCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpritePickingCamera with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_picking_SpritePickingCamera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for HoverMap with to_ecs_payload(self) {
  EcsPayload_picking_HoverMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for HoverMap with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_HoverMap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PreviousHoverMap with to_ecs_payload(self) {
  EcsPayload_picking_PreviousHoverMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PreviousHoverMap with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_picking_PreviousHoverMap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PickingSettings with to_ecs_payload(self) {
  EcsPayload_picking_PickingSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PickingSettings with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PickingSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PickingState with to_ecs_payload(self) {
  EcsPayload_picking_PickingState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PickingState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_picking_PickingState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointerInputSettings with to_ecs_payload(self) {
  EcsPayload_picking_PointerInputSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointerInputSettings with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_picking_PointerInputSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpritePickingSettings with to_ecs_payload(
  self,
) {
  EcsPayload_picking_SpritePickingSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpritePickingSettings with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_picking_SpritePickingSettings(value) => Some(value)
    _ => None
  }
}
