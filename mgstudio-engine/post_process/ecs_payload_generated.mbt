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
  EcsPayload_post_process_MsaaWriteback(MsaaWriteback)
  EcsPayload_post_process_Fxaa(Fxaa)
  EcsPayload_post_process_Bloom(Bloom)
  EcsPayload_post_process_CustomPostProcess3d(CustomPostProcess3d)
  EcsPayload_post_process_Tonemapping(Tonemapping)
  EcsPayload_post_process_ColorGrading(ColorGrading)
  EcsPayload_post_process_DebandDither(DebandDither)
  EcsPayload_post_process_TemporalJitter(TemporalJitter)
  EcsPayload_post_process_MipBias(MipBias)
  EcsPayload_post_process_TemporalAntiAliasing(TemporalAntiAliasing)
  EcsPayload_post_process_ScreenSpaceReflections(ScreenSpaceReflections)
  EcsPayload_post_process_ScreenSpaceAmbientOcclusion(
    ScreenSpaceAmbientOcclusion
  )
}

///|
pub impl @ecs.EcsPayloadCodec for MsaaWriteback with to_ecs_payload(self) {
  EcsPayload_post_process_MsaaWriteback(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MsaaWriteback with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_MsaaWriteback(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Fxaa with to_ecs_payload(self) {
  EcsPayload_post_process_Fxaa(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Fxaa with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_Fxaa(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Bloom with to_ecs_payload(self) {
  EcsPayload_post_process_Bloom(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Bloom with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_Bloom(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CustomPostProcess3d with to_ecs_payload(self) {
  EcsPayload_post_process_CustomPostProcess3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CustomPostProcess3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_post_process_CustomPostProcess3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Tonemapping with to_ecs_payload(self) {
  EcsPayload_post_process_Tonemapping(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Tonemapping with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_Tonemapping(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColorGrading with to_ecs_payload(self) {
  EcsPayload_post_process_ColorGrading(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColorGrading with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_ColorGrading(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DebandDither with to_ecs_payload(self) {
  EcsPayload_post_process_DebandDither(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DebandDither with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_DebandDither(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TemporalJitter with to_ecs_payload(self) {
  EcsPayload_post_process_TemporalJitter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TemporalJitter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_TemporalJitter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MipBias with to_ecs_payload(self) {
  EcsPayload_post_process_MipBias(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MipBias with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_MipBias(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TemporalAntiAliasing with to_ecs_payload(self) {
  EcsPayload_post_process_TemporalAntiAliasing(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TemporalAntiAliasing with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_post_process_TemporalAntiAliasing(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenSpaceReflections with to_ecs_payload(
  self,
) {
  EcsPayload_post_process_ScreenSpaceReflections(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenSpaceReflections with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_post_process_ScreenSpaceReflections(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenSpaceAmbientOcclusion with to_ecs_payload(
  self,
) {
  EcsPayload_post_process_ScreenSpaceAmbientOcclusion(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenSpaceAmbientOcclusion with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_post_process_ScreenSpaceAmbientOcclusion(value) => Some(value)
    _ => None
  }
}
