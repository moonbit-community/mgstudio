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
  EcsPayload_examples_ui_images_image_node_resizing_ImageGroup(ImageGroup)
  EcsPayload_examples_ui_images_image_node_resizing_ResizeLabel(ResizeLabel)
  EcsPayload_examples_ui_images_image_node_resizing_TextData(TextData)
  EcsPayload_examples_ui_images_image_node_resizing_ImageGroupResize(
    ImageGroupResize
  )
  EcsPayload_examples_ui_images_image_node_resizing_TextUpdate(TextUpdate)
}

///|
impl @ecs.EcsPayloadCodec for ImageGroup with to_ecs_payload(self) {
  EcsPayload_examples_ui_images_image_node_resizing_ImageGroup(self)
}

///|
impl @ecs.EcsPayloadCodec for ImageGroup with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_images_image_node_resizing_ImageGroup(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ResizeLabel with to_ecs_payload(self) {
  EcsPayload_examples_ui_images_image_node_resizing_ResizeLabel(self)
}

///|
impl @ecs.EcsPayloadCodec for ResizeLabel with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_images_image_node_resizing_ResizeLabel(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TextData with to_ecs_payload(self) {
  EcsPayload_examples_ui_images_image_node_resizing_TextData(self)
}

///|
impl @ecs.EcsPayloadCodec for TextData with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_images_image_node_resizing_TextData(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ImageGroupResize with to_ecs_payload(self) {
  EcsPayload_examples_ui_images_image_node_resizing_ImageGroupResize(self)
}

///|
impl @ecs.EcsPayloadCodec for ImageGroupResize with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_images_image_node_resizing_ImageGroupResize(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TextUpdate with to_ecs_payload(self) {
  EcsPayload_examples_ui_images_image_node_resizing_TextUpdate(self)
}

///|
impl @ecs.EcsPayloadCodec for TextUpdate with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_images_image_node_resizing_TextUpdate(value) =>
      Some(value)
    _ => None
  }
}
