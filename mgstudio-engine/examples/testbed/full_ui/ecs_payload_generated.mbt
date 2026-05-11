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
  EcsPayload_examples_testbed_full_ui_IdleColor(IdleColor)
}

///|
impl @ecs.EcsPayloadCodec for IdleColor with to_ecs_payload(self) {
  EcsPayload_examples_testbed_full_ui_IdleColor(self)
}

///|
impl @ecs.EcsPayloadCodec for IdleColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_testbed_full_ui_IdleColor(value) => Some(value)
    _ => None
  }
}
