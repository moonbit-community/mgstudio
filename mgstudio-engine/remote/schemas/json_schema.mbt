// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_remote/src/schemas/json_schema.rs`.

///|
pub(all) enum RemoteJsonSchemaType {
  Null
  Bool
  Number
  String
  Array
  Object
} derive(Eq, Debug)

///|
pub struct RemoteJsonSchema {
  title : String
  schema_type : RemoteJsonSchemaType
  description : String?
}

///|
pub fn RemoteJsonSchema::new(
  title : String,
  schema_type : RemoteJsonSchemaType,
) -> RemoteJsonSchema {
  RemoteJsonSchema::{ title, schema_type, description: None }
}

///|
pub fn RemoteJsonSchema::with_description(
  self : RemoteJsonSchema,
  description : String,
) -> RemoteJsonSchema {
  RemoteJsonSchema::{ ..self, description: Some(description) }
}

///|
pub fn remote_json_schema_string(title : String) -> RemoteJsonSchema {
  RemoteJsonSchema::new(title, String)
}

///|
pub fn remote_json_schema_object(title : String) -> RemoteJsonSchema {
  RemoteJsonSchema::new(title, Object)
}
