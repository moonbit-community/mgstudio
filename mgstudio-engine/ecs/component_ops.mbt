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
pub(all) struct ComponentColumnOps {
  payload_at_row : (@any.Any, Int) -> ErasedValue?
  writer_from_payload : (ErasedValue) -> ErasedWriter?
  append_writer : (@any.Any, ErasedWriter) -> Bool
  replace_writer_at_row : (@any.Any, Int, ErasedWriter) -> Bool
  append_from_row : (@any.Any, Int, @any.Any) -> Bool
  swap_remove_row : (@any.Any, Int) -> Bool
}

///|
pub(all) struct ComponentOps {
  definition_id : Int
  debug_name : String
  new_values : () -> @any.Any
  column_ops : ComponentColumnOps
}

///|
let component_ops_registry : @hashmap.HashMap[Int, ComponentOps] = @hashmap.HashMap([],
)

///|
fn[T] component_ops_for_key(key : ComponentKey[T]) -> ComponentOps {
  let definition_id = key.id()
  let debug_name = key.debug_name()
  let column_ops : ComponentColumnOps = {
    payload_at_row: fn(values_any, row_index) {
      let values : Array[T] = values_any.unsafe_coerce()
      if row_index < 0 || row_index >= values.length() {
        return None
      }
      Some(erased_value(values[row_index]))
    },
    writer_from_payload: fn(payload) {
      let result : Result[T, @any.TypeMismatch] = try? payload.to_value()
      match result {
        Ok(value) => Some(erased_writer(key, value))
        Err(_) => None
      }
    },
    append_writer: fn(values_any, writer) {
      if writer.component_definition_id != definition_id {
        return false
      }
      (writer.append_to_values)(values_any)
    },
    replace_writer_at_row: fn(values_any, row_index, writer) {
      if writer.component_definition_id != definition_id {
        return false
      }
      (writer.replace_in_values)(values_any, row_index)
    },
    append_from_row: fn(source_any, row_index, values_any) {
      let source : Array[T] = source_any.unsafe_coerce()
      if row_index < 0 || row_index >= source.length() {
        return false
      }
      let values : Array[T] = values_any.unsafe_coerce()
      values.push(source[row_index])
      true
    },
    swap_remove_row: fn(values_any, row_index) {
      let values : Array[T] = values_any.unsafe_coerce()
      if row_index < 0 || row_index >= values.length() {
        return false
      }
      let last_index = values.length() - 1
      if row_index != last_index {
        values[row_index] = values[last_index]
      }
      ignore(values.pop())
      true
    },
  }
  {
    definition_id,
    debug_name,
    new_values: fn() {
      let values : Array[T] = []
      @any.of(values)
    },
    column_ops,
  }
}

///|
fn[T] register_component_ops(component_id : Int, key : ComponentKey[T]) -> Unit {
  if component_ops_registry.get(component_id) is Some(_) {
    return
  }
  component_ops_registry.set(component_id, component_ops_for_key(key))
}

///|
fn component_ops(component_id : Int) -> ComponentOps {
  match component_ops_registry.get(component_id) {
    Some(ops) => ops
    None =>
      abort(
        "Missing component ops for component definition \{component_id.to_string()}",
      )
  }
}
