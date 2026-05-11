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
  EcsPayload_examples_2d_rotation_Player(Player)
  EcsPayload_examples_2d_rotation_SnapToPlayer(SnapToPlayer)
  EcsPayload_examples_2d_rotation_RotateToPlayer(RotateToPlayer)
}

///|
impl @ecs.EcsPayloadCodec for Player with to_ecs_payload(self) {
  EcsPayload_examples_2d_rotation_Player(self)
}

///|
impl @ecs.EcsPayloadCodec for Player with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_rotation_Player(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SnapToPlayer with to_ecs_payload(self) {
  EcsPayload_examples_2d_rotation_SnapToPlayer(self)
}

///|
impl @ecs.EcsPayloadCodec for SnapToPlayer with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_rotation_SnapToPlayer(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for RotateToPlayer with to_ecs_payload(self) {
  EcsPayload_examples_2d_rotation_RotateToPlayer(self)
}

///|
impl @ecs.EcsPayloadCodec for RotateToPlayer with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_2d_rotation_RotateToPlayer(value) => Some(value)
    _ => None
  }
}
