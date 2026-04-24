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
#external
priv type RawTableRowKernel

///|
extern "c" fn raw_table_row_kernel_new_native() -> RawTableRowKernel = "mgstudio_ecs_raw_table_rows_new"

///|
#borrow(kernel)
extern "c" fn raw_table_row_kernel_len_native(
  kernel : RawTableRowKernel,
) -> Int = "mgstudio_ecs_raw_table_rows_len"

///|
#borrow(kernel)
extern "c" fn raw_table_row_kernel_push_native(
  kernel : RawTableRowKernel,
  entity_bits : UInt64,
) -> Int = "mgstudio_ecs_raw_table_rows_push"

///|
#borrow(kernel)
extern "c" fn raw_table_row_kernel_get_bits_native(
  kernel : RawTableRowKernel,
  row : Int,
) -> UInt64 = "mgstudio_ecs_raw_table_rows_get"

///|
#borrow(kernel)
extern "c" fn raw_table_row_kernel_swap_remove_native(
  kernel : RawTableRowKernel,
  row : Int,
) -> Unit = "mgstudio_ecs_raw_table_rows_swap_remove"

///|
fn raw_table_row_kernel_new() -> RawTableRowKernel {
  raw_table_row_kernel_new_native()
}

///|
fn raw_table_row_kernel_len(kernel : RawTableRowKernel) -> Int {
  raw_table_row_kernel_len_native(kernel)
}

///|
fn raw_table_row_kernel_push(
  kernel : RawTableRowKernel,
  entity : @core.Entity,
) -> Int {
  raw_table_row_kernel_push_native(kernel, entity.to_bits())
}

///|
fn raw_table_row_kernel_entity_at(
  kernel : RawTableRowKernel,
  row : Int,
) -> @core.Entity? {
  if row < 0 || row >= raw_table_row_kernel_len(kernel) {
    return None
  }
  Some(
    @core.Entity::from_bits(raw_table_row_kernel_get_bits_native(kernel, row)),
  )
}

///|
fn raw_table_row_kernel_swap_remove(
  kernel : RawTableRowKernel,
  row : Int,
) -> Bool {
  if row < 0 || row >= raw_table_row_kernel_len(kernel) {
    return false
  }
  raw_table_row_kernel_swap_remove_native(kernel, row)
  true
}

///|
#external
priv type RawTableValueColumnKernel

///|
extern "c" fn raw_table_value_column_kernel_new_native(
) -> RawTableValueColumnKernel = "mgstudio_ecs_raw_table_value_column_new"

///|
#borrow(kernel)
extern "c" fn raw_table_value_column_kernel_len_native(
  kernel : RawTableValueColumnKernel,
) -> Int = "mgstudio_ecs_raw_table_value_column_len"

///|
#borrow(kernel, value)
extern "c" fn raw_table_value_column_kernel_push_native(
  kernel : RawTableValueColumnKernel,
  value : @any.Any,
  added_sequence : Int,
  changed_sequence : Int,
  changed_caller_id : Int,
) -> Bool = "mgstudio_ecs_raw_table_value_column_push"

///|
#borrow(kernel, value)
extern "c" fn raw_table_value_column_kernel_replace_native(
  kernel : RawTableValueColumnKernel,
  row : Int,
  value : @any.Any,
) -> Bool = "mgstudio_ecs_raw_table_value_column_replace"

///|
#borrow(kernel)
extern "c" fn raw_table_value_column_kernel_value_native(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> @any.Any = "mgstudio_ecs_raw_table_value_column_value"

///|
#borrow(kernel)
extern "c" fn raw_table_value_column_kernel_set_metadata_native(
  kernel : RawTableValueColumnKernel,
  row : Int,
  added_sequence : Int,
  changed_sequence : Int,
  changed_caller_id : Int,
) -> Bool = "mgstudio_ecs_raw_table_value_column_set_metadata"

///|
#borrow(kernel)
extern "c" fn raw_table_value_column_kernel_added_native(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> Int = "mgstudio_ecs_raw_table_value_column_added"

///|
#borrow(kernel)
extern "c" fn raw_table_value_column_kernel_changed_native(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> Int = "mgstudio_ecs_raw_table_value_column_changed"

///|
#borrow(kernel)
extern "c" fn raw_table_value_column_kernel_changed_caller_id_native(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> Int = "mgstudio_ecs_raw_table_value_column_changed_caller_id"

///|
#borrow(kernel)
extern "c" fn raw_table_value_column_kernel_swap_remove_native(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> Bool = "mgstudio_ecs_raw_table_value_column_swap_remove"

///|
fn raw_table_value_column_kernel_new() -> RawTableValueColumnKernel {
  raw_table_value_column_kernel_new_native()
}

///|
fn raw_table_value_column_kernel_len(
  kernel : RawTableValueColumnKernel,
) -> Int {
  raw_table_value_column_kernel_len_native(kernel)
}

///|
fn raw_table_value_column_kernel_push(
  kernel : RawTableValueColumnKernel,
  value : @any.Any,
  added_sequence : @core.Sequence,
  changed_sequence : @core.Sequence,
  changed_caller_id : Int,
) -> Bool {
  raw_table_value_column_kernel_push_native(
    kernel,
    value,
    added_sequence,
    changed_sequence,
    changed_caller_id,
  )
}

///|
fn raw_table_value_column_kernel_replace(
  kernel : RawTableValueColumnKernel,
  row : Int,
  value : @any.Any,
) -> Bool {
  if row < 0 || row >= raw_table_value_column_kernel_len(kernel) {
    return false
  }
  raw_table_value_column_kernel_replace_native(kernel, row, value)
}

///|
fn raw_table_value_column_kernel_value(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> @any.Any? {
  if row < 0 || row >= raw_table_value_column_kernel_len(kernel) {
    return None
  }
  Some(raw_table_value_column_kernel_value_native(kernel, row))
}

///|
fn raw_table_value_column_kernel_set_metadata(
  kernel : RawTableValueColumnKernel,
  row : Int,
  added_sequence : @core.Sequence,
  changed_sequence : @core.Sequence,
  changed_caller_id : Int,
) -> Bool {
  raw_table_value_column_kernel_set_metadata_native(
    kernel,
    row,
    added_sequence,
    changed_sequence,
    changed_caller_id,
  )
}

///|
fn raw_table_value_column_kernel_added(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> @core.Sequence {
  raw_table_value_column_kernel_added_native(kernel, row)
}

///|
fn raw_table_value_column_kernel_changed(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> @core.Sequence {
  raw_table_value_column_kernel_changed_native(kernel, row)
}

///|
fn raw_table_value_column_kernel_changed_caller_id(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> Int {
  raw_table_value_column_kernel_changed_caller_id_native(kernel, row)
}

///|
fn raw_table_value_column_kernel_swap_remove(
  kernel : RawTableValueColumnKernel,
  row : Int,
) -> Bool {
  raw_table_value_column_kernel_swap_remove_native(kernel, row)
}
