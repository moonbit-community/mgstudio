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
  EcsPayload_examples_2d_pixel_grid_snap_Canvas(Canvas)
  EcsPayload_examples_2d_pixel_grid_snap_InGameCamera(InGameCamera)
  EcsPayload_examples_2d_pixel_grid_snap_OuterCamera(OuterCamera)
  EcsPayload_examples_2d_pixel_grid_snap_Rotate(Rotate)
}

///|
impl @ecs.EcsPayloadCodec for Canvas with to_ecs_payload(self) {
  EcsPayload_examples_2d_pixel_grid_snap_Canvas(self)
}

///|
impl @ecs.EcsPayloadCodec for Canvas with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_pixel_grid_snap_Canvas(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for InGameCamera with to_ecs_payload(self) {
  EcsPayload_examples_2d_pixel_grid_snap_InGameCamera(self)
}

///|
impl @ecs.EcsPayloadCodec for InGameCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_pixel_grid_snap_InGameCamera(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for OuterCamera with to_ecs_payload(self) {
  EcsPayload_examples_2d_pixel_grid_snap_OuterCamera(self)
}

///|
impl @ecs.EcsPayloadCodec for OuterCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_pixel_grid_snap_OuterCamera(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Rotate with to_ecs_payload(self) {
  EcsPayload_examples_2d_pixel_grid_snap_Rotate(self)
}

///|
impl @ecs.EcsPayloadCodec for Rotate with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_pixel_grid_snap_Rotate(value) => Some(value)
    _ => None
  }
}
