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
  EcsPayload_hierarchy_Parent(Parent)
  EcsPayload_hierarchy_Children(Children)
}

///|
pub impl @ecs.EcsPayloadCodec for Parent with to_ecs_payload(self) {
  EcsPayload_hierarchy_Parent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Parent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_hierarchy_Parent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Children with to_ecs_payload(self) {
  EcsPayload_hierarchy_Children(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Children with from_ecs_payload(payload) {
  match payload {
    EcsPayload_hierarchy_Children(value) => Some(value)
    _ => None
  }
}
