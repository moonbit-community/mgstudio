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
struct ErasedValue {
  value : @any.Any
}

///|
pub struct ErasedWriter {
  component_definition_id : Int
  component_debug_name : String
  value_type_name : String
  to_value : () -> ErasedValue
  append_to_values : (@any.Any) -> Bool
  replace_in_values : (@any.Any, Int) -> Bool
}

///|
fn[T] erased_value(value : T) -> ErasedValue {
  { value: @any.of(value) }
}

///|
fn[T] erased_writer(key : ComponentKey[T], value : T) -> ErasedWriter {
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
    to_value: fn() { erased_value(value) },
    append_to_values: fn(values_any) {
      let values : Array[T] = values_any.unsafe_coerce()
      values.push(value)
      true
    },
    replace_in_values: fn(values_any, row_index) {
      let values : Array[T] = values_any.unsafe_coerce()
      if row_index < 0 || row_index >= values.length() {
        return false
      }
      values[row_index] = value
      true
    },
  }
}

///|
pub fn[T] component_writer(
  key : ComponentKey[T],
  value : T,
) -> ErasedWriter {
  erased_writer(key, value)
}

///|
fn[T] ErasedValue::to_value(self : ErasedValue) -> T raise @any.TypeMismatch {
  self.value.to()
}

///|
fn ErasedValue::type_name(self : ErasedValue) -> String {
  self.value.type_name()
}

///|
fn ErasedWriter::to_erased_value(self : ErasedWriter) -> ErasedValue {
  (self.to_value)()
}
