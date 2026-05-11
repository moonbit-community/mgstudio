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
  EcsPayload_examples_ui_render_ui_to_texture_Cube(Cube)
  EcsPayload_examples_ui_render_ui_to_texture_MainCamera(MainCamera)
  EcsPayload_examples_ui_render_ui_to_texture_DraggablePanel(DraggablePanel)
  EcsPayload_examples_ui_render_ui_to_texture_PanelDragState(PanelDragState)
}

///|
impl @ecs.EcsPayloadCodec for Cube with to_ecs_payload(self) {
  EcsPayload_examples_ui_render_ui_to_texture_Cube(self)
}

///|
impl @ecs.EcsPayloadCodec for Cube with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_render_ui_to_texture_Cube(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MainCamera with to_ecs_payload(self) {
  EcsPayload_examples_ui_render_ui_to_texture_MainCamera(self)
}

///|
impl @ecs.EcsPayloadCodec for MainCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_render_ui_to_texture_MainCamera(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DraggablePanel with to_ecs_payload(self) {
  EcsPayload_examples_ui_render_ui_to_texture_DraggablePanel(self)
}

///|
impl @ecs.EcsPayloadCodec for DraggablePanel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_render_ui_to_texture_DraggablePanel(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PanelDragState with to_ecs_payload(self) {
  EcsPayload_examples_ui_render_ui_to_texture_PanelDragState(self)
}

///|
impl @ecs.EcsPayloadCodec for PanelDragState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_render_ui_to_texture_PanelDragState(value) =>
      Some(value)
    _ => None
  }
}
