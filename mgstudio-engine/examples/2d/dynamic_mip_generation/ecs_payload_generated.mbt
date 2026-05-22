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
  EcsPayload_examples_2d_dynamic_mip_generation_AppSetting(AppSetting)
  EcsPayload_examples_2d_dynamic_mip_generation_AnimatedImage(AnimatedImage)
  EcsPayload_examples_2d_dynamic_mip_generation_ImageView(ImageView)
  EcsPayload_examples_2d_dynamic_mip_generation_RegenerateImage(RegenerateImage)
}

///|
impl @ecs.EcsPayloadCodec for AppSetting with to_ecs_payload(self) {
  EcsPayload_examples_2d_dynamic_mip_generation_AppSetting(self)
}

///|
impl @ecs.EcsPayloadCodec for AppSetting with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_dynamic_mip_generation_AppSetting(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AnimatedImage with to_ecs_payload(self) {
  EcsPayload_examples_2d_dynamic_mip_generation_AnimatedImage(self)
}

///|
impl @ecs.EcsPayloadCodec for AnimatedImage with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_dynamic_mip_generation_AnimatedImage(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ImageView with to_ecs_payload(self) {
  EcsPayload_examples_2d_dynamic_mip_generation_ImageView(self)
}

///|
impl @ecs.EcsPayloadCodec for ImageView with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_dynamic_mip_generation_ImageView(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for RegenerateImage with to_ecs_payload(self) {
  EcsPayload_examples_2d_dynamic_mip_generation_RegenerateImage(self)
}

///|
impl @ecs.EcsPayloadCodec for RegenerateImage with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_dynamic_mip_generation_RegenerateImage(value) =>
      Some(value)
    _ => None
  }
}
