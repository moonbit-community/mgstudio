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
  EcsPayload_examples_animation_color_animation_CurveLinearRgba(CurveLinearRgba)
  EcsPayload_examples_animation_color_animation_CurveXyza(CurveXyza)
  EcsPayload_examples_animation_color_animation_CurveOklaba(CurveOklaba)
  EcsPayload_examples_animation_color_animation_MixedHsla(MixedHsla)
  EcsPayload_examples_animation_color_animation_MixedSrgba(MixedSrgba)
  EcsPayload_examples_animation_color_animation_MixedOklcha(MixedOklcha)
}

///|
impl @ecs.EcsPayloadCodec for CurveLinearRgba with to_ecs_payload(self) {
  EcsPayload_examples_animation_color_animation_CurveLinearRgba(self)
}

///|
impl @ecs.EcsPayloadCodec for CurveLinearRgba with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_color_animation_CurveLinearRgba(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CurveXyza with to_ecs_payload(self) {
  EcsPayload_examples_animation_color_animation_CurveXyza(self)
}

///|
impl @ecs.EcsPayloadCodec for CurveXyza with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_color_animation_CurveXyza(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CurveOklaba with to_ecs_payload(self) {
  EcsPayload_examples_animation_color_animation_CurveOklaba(self)
}

///|
impl @ecs.EcsPayloadCodec for CurveOklaba with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_color_animation_CurveOklaba(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MixedHsla with to_ecs_payload(self) {
  EcsPayload_examples_animation_color_animation_MixedHsla(self)
}

///|
impl @ecs.EcsPayloadCodec for MixedHsla with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_color_animation_MixedHsla(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MixedSrgba with to_ecs_payload(self) {
  EcsPayload_examples_animation_color_animation_MixedSrgba(self)
}

///|
impl @ecs.EcsPayloadCodec for MixedSrgba with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_color_animation_MixedSrgba(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MixedOklcha with to_ecs_payload(self) {
  EcsPayload_examples_animation_color_animation_MixedOklcha(self)
}

///|
impl @ecs.EcsPayloadCodec for MixedOklcha with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_color_animation_MixedOklcha(value) =>
      Some(value)
    _ => None
  }
}
