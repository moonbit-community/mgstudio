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
  EcsPayload_examples_math_cubic_splines_SplineMode(SplineMode)
  EcsPayload_examples_math_cubic_splines_CyclingMode(CyclingMode)
  EcsPayload_examples_math_cubic_splines_Curve(Curve)
  EcsPayload_examples_math_cubic_splines_ControlPoints(ControlPoints)
  EcsPayload_examples_math_cubic_splines_MouseEditMove(MouseEditMove)
  EcsPayload_examples_math_cubic_splines_MousePosition(MousePosition)
  EcsPayload_examples_math_cubic_splines_SplineModeTextHandle(
    SplineModeTextHandle
  )
  EcsPayload_examples_math_cubic_splines_CyclingModeTextHandle(
    CyclingModeTextHandle
  )
}

///|
impl @ecs.EcsPayloadCodec for SplineMode with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_SplineMode(self)
}

///|
impl @ecs.EcsPayloadCodec for SplineMode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_cubic_splines_SplineMode(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CyclingMode with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_CyclingMode(self)
}

///|
impl @ecs.EcsPayloadCodec for CyclingMode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_cubic_splines_CyclingMode(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Curve with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_Curve(self)
}

///|
impl @ecs.EcsPayloadCodec for Curve with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_cubic_splines_Curve(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ControlPoints with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_ControlPoints(self)
}

///|
impl @ecs.EcsPayloadCodec for ControlPoints with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_cubic_splines_ControlPoints(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MouseEditMove with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_MouseEditMove(self)
}

///|
impl @ecs.EcsPayloadCodec for MouseEditMove with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_cubic_splines_MouseEditMove(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MousePosition with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_MousePosition(self)
}

///|
impl @ecs.EcsPayloadCodec for MousePosition with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_cubic_splines_MousePosition(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SplineModeTextHandle with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_SplineModeTextHandle(self)
}

///|
impl @ecs.EcsPayloadCodec for SplineModeTextHandle with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_math_cubic_splines_SplineModeTextHandle(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CyclingModeTextHandle with to_ecs_payload(self) {
  EcsPayload_examples_math_cubic_splines_CyclingModeTextHandle(self)
}

///|
impl @ecs.EcsPayloadCodec for CyclingModeTextHandle with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_math_cubic_splines_CyclingModeTextHandle(value) =>
      Some(value)
    _ => None
  }
}
