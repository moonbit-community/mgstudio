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
  EcsPayload_transform_Transform(Transform)
  EcsPayload_transform_GlobalTransform(GlobalTransform)
  EcsPayload_transform_TransformTreeChanged(TransformTreeChanged)
  EcsPayload_transform_StaticTransformOptimizations(
    StaticTransformOptimizations
  )
  EcsPayload_transform_TransformPropagationScratch(TransformPropagationScratch)
}

///|
pub impl @ecs.EcsPayloadCodec for Transform with to_ecs_payload(self) {
  EcsPayload_transform_Transform(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Transform with from_ecs_payload(payload) {
  match payload {
    EcsPayload_transform_Transform(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalTransform with to_ecs_payload(self) {
  EcsPayload_transform_GlobalTransform(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalTransform with from_ecs_payload(payload) {
  match payload {
    EcsPayload_transform_GlobalTransform(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TransformTreeChanged with to_ecs_payload(self) {
  EcsPayload_transform_TransformTreeChanged(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TransformTreeChanged with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_transform_TransformTreeChanged(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for StaticTransformOptimizations with to_ecs_payload(
  self,
) {
  EcsPayload_transform_StaticTransformOptimizations(self)
}

///|
pub impl @ecs.EcsPayloadCodec for StaticTransformOptimizations with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_transform_StaticTransformOptimizations(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TransformPropagationScratch with to_ecs_payload(
  self,
) {
  EcsPayload_transform_TransformPropagationScratch(self)
}

///|
impl @ecs.EcsPayloadCodec for TransformPropagationScratch with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_transform_TransformPropagationScratch(value) => Some(value)
    _ => None
  }
}
