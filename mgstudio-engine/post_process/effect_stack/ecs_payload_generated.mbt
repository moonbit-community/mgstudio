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
  EcsPayload_post_process_effect_stack_Vignette(Vignette)
  EcsPayload_post_process_effect_stack_ChromaticAberration(ChromaticAberration)
}

///|
pub impl @ecs.EcsPayloadCodec for Vignette with to_ecs_payload(self) {
  EcsPayload_post_process_effect_stack_Vignette(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Vignette with from_ecs_payload(payload) {
  match payload {
    EcsPayload_post_process_effect_stack_Vignette(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ChromaticAberration with to_ecs_payload(self) {
  EcsPayload_post_process_effect_stack_ChromaticAberration(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ChromaticAberration with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_post_process_effect_stack_ChromaticAberration(value) =>
      Some(value)
    _ => None
  }
}
