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
  EcsPayload_examples_ui_layout_size_constraints_Bar(Bar)
  EcsPayload_examples_ui_layout_size_constraints_ConstraintButton(
    ConstraintButton
  )
  EcsPayload_examples_ui_layout_size_constraints_ConstraintSettings(
    ConstraintSettings
  )
}

///|
impl @ecs.EcsPayloadCodec for Bar with to_ecs_payload(self) {
  EcsPayload_examples_ui_layout_size_constraints_Bar(self)
}

///|
impl @ecs.EcsPayloadCodec for Bar with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_layout_size_constraints_Bar(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ConstraintButton with to_ecs_payload(self) {
  EcsPayload_examples_ui_layout_size_constraints_ConstraintButton(self)
}

///|
impl @ecs.EcsPayloadCodec for ConstraintButton with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_layout_size_constraints_ConstraintButton(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ConstraintSettings with to_ecs_payload(self) {
  EcsPayload_examples_ui_layout_size_constraints_ConstraintSettings(self)
}

///|
impl @ecs.EcsPayloadCodec for ConstraintSettings with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_layout_size_constraints_ConstraintSettings(value) =>
      Some(value)
    _ => None
  }
}
