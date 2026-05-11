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
  EcsPayload_examples_picking_dragdrop_picking_DropArea(DropArea)
  EcsPayload_examples_picking_dragdrop_picking_DraggableButton(DraggableButton)
  EcsPayload_examples_picking_dragdrop_picking_GhostPreview(GhostPreview)
  EcsPayload_examples_picking_dragdrop_picking_DragState(DragState)
}

///|
impl @ecs.EcsPayloadCodec for DropArea with to_ecs_payload(self) {
  EcsPayload_examples_picking_dragdrop_picking_DropArea(self)
}

///|
impl @ecs.EcsPayloadCodec for DropArea with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_picking_dragdrop_picking_DropArea(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DraggableButton with to_ecs_payload(self) {
  EcsPayload_examples_picking_dragdrop_picking_DraggableButton(self)
}

///|
impl @ecs.EcsPayloadCodec for DraggableButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_picking_dragdrop_picking_DraggableButton(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for GhostPreview with to_ecs_payload(self) {
  EcsPayload_examples_picking_dragdrop_picking_GhostPreview(self)
}

///|
impl @ecs.EcsPayloadCodec for GhostPreview with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_picking_dragdrop_picking_GhostPreview(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DragState with to_ecs_payload(self) {
  EcsPayload_examples_picking_dragdrop_picking_DragState(self)
}

///|
impl @ecs.EcsPayloadCodec for DragState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_picking_dragdrop_picking_DragState(value) => Some(value)
    _ => None
  }
}
