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
extenum EcsPayload += {
  EcsPayload_ecs_CoreEntity(@core.Entity)
  EcsPayload_ecs_MessageRegistryState(MessageRegistryState)
  EcsPayload_ecs_Messages(MessageQueueState)
  EcsPayload_ecs_Name(Name)
  EcsPayload_ecs_Disabled(Disabled)
  EcsPayload_ecs_DefaultQueryFilters(DefaultQueryFilters)
  EcsPayload_ecs_Insert(Insert)
  EcsPayload_ecs_Add(Add)
  EcsPayload_ecs_Replace(Replace)
  EcsPayload_ecs_Remove(Remove)
  EcsPayload_ecs_Despawn(Despawn)
}

///|
pub impl EcsPayloadCodec for @core.Entity with to_ecs_payload(self) {
  EcsPayload_ecs_CoreEntity(self)
}

///|
pub impl EcsPayloadCodec for @core.Entity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_CoreEntity(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for MessageRegistryState with to_ecs_payload(self) {
  EcsPayload_ecs_MessageRegistryState(self)
}

///|
pub impl EcsPayloadCodec for MessageRegistryState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_MessageRegistryState(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Name with to_ecs_payload(self) {
  EcsPayload_ecs_Name(self)
}

///|
pub impl EcsPayloadCodec for Name with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Name(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Disabled with to_ecs_payload(self) {
  EcsPayload_ecs_Disabled(self)
}

///|
pub impl EcsPayloadCodec for Disabled with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Disabled(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for DefaultQueryFilters with to_ecs_payload(self) {
  EcsPayload_ecs_DefaultQueryFilters(self)
}

///|
pub impl EcsPayloadCodec for DefaultQueryFilters with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_DefaultQueryFilters(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Insert with to_ecs_payload(self) {
  EcsPayload_ecs_Insert(self)
}

///|
pub impl EcsPayloadCodec for Insert with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Insert(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Add with to_ecs_payload(self) {
  EcsPayload_ecs_Add(self)
}

///|
pub impl EcsPayloadCodec for Add with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Add(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Replace with to_ecs_payload(self) {
  EcsPayload_ecs_Replace(self)
}

///|
pub impl EcsPayloadCodec for Replace with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Replace(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Remove with to_ecs_payload(self) {
  EcsPayload_ecs_Remove(self)
}

///|
pub impl EcsPayloadCodec for Remove with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Remove(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Despawn with to_ecs_payload(self) {
  EcsPayload_ecs_Despawn(self)
}

///|
pub impl EcsPayloadCodec for Despawn with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Despawn(value) => Some(value)
    _ => None
  }
}

///|
pub impl[T] EcsPayloadCodec for Messages[T] with to_ecs_payload(self) {
  EcsPayload_ecs_Messages(self.slot.state)
}

///|
pub impl[T] EcsPayloadCodec for Messages[T] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ecs_Messages(state) =>
      Some(Messages::{ slot: MessageQueueSlot::{ state, } })
    _ => None
  }
}
