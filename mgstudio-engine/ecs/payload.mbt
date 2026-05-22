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
pub struct ComponentWriter {
  priv component_definition_id : Int
  priv component_debug_name : String
  priv value_type_name : String
  priv apply_fn : (World, @core.Entity) -> Unit
}

///|
fn[T] component_writer_for_key(
  key : ComponentKey[T],
  value : T,
) -> ComponentWriter {
  ensure_component_ops_for_key(key)
  let component_definition_id = key.id()
  let component_debug_name = key.debug_name()
  {
    component_definition_id,
    component_debug_name,
    value_type_name: if component_debug_name != "" {
      component_debug_name
    } else {
      "component#\{component_definition_id.to_string()}"
    },
    apply_fn: fn(world, entity) { (key.access.set)(world, entity, value) },
  }
}

///|
pub fn[T] component_writer(key : ComponentKey[T], value : T) -> ComponentWriter {
  component_writer_for_key(key, value)
}

///|
fn ComponentWriter::apply(
  self : ComponentWriter,
  world : World,
  entity : @core.Entity,
) -> Unit {
  (self.apply_fn)(world, entity)
}

///|
pub fn ComponentWriter::component_definition_id(self : ComponentWriter) -> Int {
  self.component_definition_id
}

///|
pub fn ComponentWriter::component_debug_name(self : ComponentWriter) -> String {
  self.component_debug_name
}

///|
pub fn ComponentWriter::value_type_name(self : ComponentWriter) -> String {
  self.value_type_name
}
