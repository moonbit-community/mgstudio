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
  EcsPayload_gltf_loader_GltfLoaderRuntimeState(GltfLoaderRuntimeState)
  EcsPayload_gltf_loader_GltfLoaderPluginRuntimeState(
    GltfLoaderPluginRuntimeState
  )
}

///|
pub impl @ecs.EcsPayloadCodec for GltfLoaderRuntimeState with to_ecs_payload(
  self,
) {
  EcsPayload_gltf_loader_GltfLoaderRuntimeState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfLoaderRuntimeState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_gltf_loader_GltfLoaderRuntimeState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for GltfLoaderPluginRuntimeState with to_ecs_payload(
  self,
) {
  EcsPayload_gltf_loader_GltfLoaderPluginRuntimeState(self)
}

///|
impl @ecs.EcsPayloadCodec for GltfLoaderPluginRuntimeState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_gltf_loader_GltfLoaderPluginRuntimeState(value) => Some(value)
    _ => None
  }
}
