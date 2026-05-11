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
  EcsPayload_examples_3d_bloom_3d_Bouncing(Bouncing)
  EcsPayload_examples_3d_bloom_3d_BloomCamera(BloomCamera)
  EcsPayload_examples_3d_bloom_3d_BloomInstructions(BloomInstructions)
}

///|
impl @ecs.EcsPayloadCodec for Bouncing with to_ecs_payload(self) {
  EcsPayload_examples_3d_bloom_3d_Bouncing(self)
}

///|
impl @ecs.EcsPayloadCodec for Bouncing with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_bloom_3d_Bouncing(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for BloomCamera with to_ecs_payload(self) {
  EcsPayload_examples_3d_bloom_3d_BloomCamera(self)
}

///|
impl @ecs.EcsPayloadCodec for BloomCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_bloom_3d_BloomCamera(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for BloomInstructions with to_ecs_payload(self) {
  EcsPayload_examples_3d_bloom_3d_BloomInstructions(self)
}

///|
impl @ecs.EcsPayloadCodec for BloomInstructions with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_bloom_3d_BloomInstructions(value) => Some(value)
    _ => None
  }
}
