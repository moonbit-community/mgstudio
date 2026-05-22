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
pub extenum EcsPayload {}

///|
extenum EcsPayload += {
  EcsPayload_Unit(Unit)
  EcsPayload_Bool(Bool)
  EcsPayload_Int(Int)
  EcsPayload_UInt64(UInt64)
  EcsPayload_Float(Float)
  EcsPayload_Double(Double)
  EcsPayload_String(String)
}

///|
pub(open) trait EcsPayloadCodec {
  fn to_ecs_payload(Self) -> EcsPayload
  fn from_ecs_payload(EcsPayload) -> Self?
}

///|
pub impl EcsPayloadCodec for Unit with to_ecs_payload(self) {
  EcsPayload_Unit(self)
}

///|
pub impl EcsPayloadCodec for Unit with from_ecs_payload(payload) {
  match payload {
    EcsPayload_Unit(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Bool with to_ecs_payload(self) {
  EcsPayload_Bool(self)
}

///|
pub impl EcsPayloadCodec for Bool with from_ecs_payload(payload) {
  match payload {
    EcsPayload_Bool(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Int with to_ecs_payload(self) {
  EcsPayload_Int(self)
}

///|
pub impl EcsPayloadCodec for Int with from_ecs_payload(payload) {
  match payload {
    EcsPayload_Int(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for UInt64 with to_ecs_payload(self) {
  EcsPayload_UInt64(self)
}

///|
pub impl EcsPayloadCodec for UInt64 with from_ecs_payload(payload) {
  match payload {
    EcsPayload_UInt64(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Float with to_ecs_payload(self) {
  EcsPayload_Float(self)
}

///|
pub impl EcsPayloadCodec for Float with from_ecs_payload(payload) {
  match payload {
    EcsPayload_Float(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for Double with to_ecs_payload(self) {
  EcsPayload_Double(self)
}

///|
pub impl EcsPayloadCodec for Double with from_ecs_payload(payload) {
  match payload {
    EcsPayload_Double(value) => Some(value)
    _ => None
  }
}

///|
pub impl EcsPayloadCodec for String with to_ecs_payload(self) {
  EcsPayload_String(self)
}

///|
pub impl EcsPayloadCodec for String with from_ecs_payload(payload) {
  match payload {
    EcsPayload_String(value) => Some(value)
    _ => None
  }
}

///|
pub struct EcsPayloadWriter {
  priv component_definition_id : Int
  priv component_debug_name : String
  priv value_type_name : String
  priv payload : EcsPayload
}

///|
fn[T : EcsPayloadCodec] ecs_payload_writer(
  key : ComponentKey[T],
  value : T,
) -> EcsPayloadWriter {
  ensure_component_ops_for_key(key)
  ecs_payload_writer_from_payload(
    key.id(),
    key.debug_name(),
    T::to_ecs_payload(value),
  )
}

///|
fn ecs_payload_writer_from_payload(
  component_definition_id : Int,
  component_debug_name : String,
  payload : EcsPayload,
) -> EcsPayloadWriter {
  {
    component_definition_id,
    component_debug_name,
    value_type_name: if component_debug_name != "" {
      component_debug_name
    } else {
      "component#\{component_definition_id.to_string()}"
    },
    payload,
  }
}

///|
pub fn[T : EcsPayloadCodec] component_writer(
  key : ComponentKey[T],
  value : T,
) -> EcsPayloadWriter {
  ecs_payload_writer(key, value)
}

///|
fn EcsPayloadWriter::to_ecs_payload(self : EcsPayloadWriter) -> EcsPayload {
  self.payload
}

///|
pub fn EcsPayloadWriter::component_definition_id(
  self : EcsPayloadWriter,
) -> Int {
  self.component_definition_id
}

///|
pub fn EcsPayloadWriter::component_debug_name(
  self : EcsPayloadWriter,
) -> String {
  self.component_debug_name
}

///|
pub fn EcsPayloadWriter::value_type_name(self : EcsPayloadWriter) -> String {
  self.value_type_name
}
