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
  EcsPayload_pbr_lightmap_Lightmap(Lightmap)
  EcsPayload_pbr_lightmap_LightmapPluginState(LightmapPluginState)
  EcsPayload_pbr_lightmap_RenderLightmaps(RenderLightmaps)
}

///|
pub impl @ecs.EcsPayloadCodec for Lightmap with to_ecs_payload(self) {
  EcsPayload_pbr_lightmap_Lightmap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Lightmap with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_lightmap_Lightmap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LightmapPluginState with to_ecs_payload(self) {
  EcsPayload_pbr_lightmap_LightmapPluginState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LightmapPluginState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_lightmap_LightmapPluginState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderLightmaps with to_ecs_payload(self) {
  EcsPayload_pbr_lightmap_RenderLightmaps(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderLightmaps with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_lightmap_RenderLightmaps(value) => Some(value)
    _ => None
  }
}
