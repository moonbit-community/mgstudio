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
  EcsPayload_examples_ui_relative_cursor_position_CursorArea(CursorArea)
  EcsPayload_examples_ui_relative_cursor_position_CursorReadout(CursorReadout)
}

///|
impl @ecs.EcsPayloadCodec for CursorArea with to_ecs_payload(self) {
  EcsPayload_examples_ui_relative_cursor_position_CursorArea(self)
}

///|
impl @ecs.EcsPayloadCodec for CursorArea with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_relative_cursor_position_CursorArea(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CursorReadout with to_ecs_payload(self) {
  EcsPayload_examples_ui_relative_cursor_position_CursorReadout(self)
}

///|
impl @ecs.EcsPayloadCodec for CursorReadout with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_ui_relative_cursor_position_CursorReadout(value) =>
      Some(value)
    _ => None
  }
}
