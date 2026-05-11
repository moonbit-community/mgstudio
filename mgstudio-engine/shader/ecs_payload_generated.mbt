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
  EcsPayload_shader_Shader(Shader)
  EcsPayload_shader_ShaderAssetPaths(ShaderAssetPaths)
  EcsPayload_shader_ShaderRuntimeCache(ShaderRuntimeCache)
}

///|
pub impl @ecs.EcsPayloadCodec for Shader with to_ecs_payload(self) {
  EcsPayload_shader_Shader(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Shader with from_ecs_payload(payload) {
  match payload {
    EcsPayload_shader_Shader(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ShaderAssetPaths with to_ecs_payload(self) {
  EcsPayload_shader_ShaderAssetPaths(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ShaderAssetPaths with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_shader_ShaderAssetPaths(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ShaderRuntimeCache with to_ecs_payload(self) {
  EcsPayload_shader_ShaderRuntimeCache(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ShaderRuntimeCache with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_shader_ShaderRuntimeCache(value) => Some(value)
    _ => None
  }
}
