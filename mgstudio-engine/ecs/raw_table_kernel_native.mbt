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
priv type RawTableMetadataKernel

///|
extern "c" fn raw_table_metadata_kernel_new_native() -> RawTableMetadataKernel = "mgstudio_ecs_raw_table_metadata_new"

///|
#borrow(kernel)
extern "c" fn raw_table_metadata_kernel_len_native(
  kernel : RawTableMetadataKernel,
) -> Int = "mgstudio_ecs_raw_table_metadata_len"

///|
#borrow(kernel)
extern "c" fn raw_table_metadata_kernel_push_native(
  kernel : RawTableMetadataKernel,
  added_sequence : Int,
  changed_sequence : Int,
  changed_caller_id : Int,
) -> Bool = "mgstudio_ecs_raw_table_metadata_push"

///|
#borrow(kernel)
extern "c" fn raw_table_metadata_kernel_set_native(
  kernel : RawTableMetadataKernel,
  row : Int,
  added_sequence : Int,
  changed_sequence : Int,
  changed_caller_id : Int,
) -> Bool = "mgstudio_ecs_raw_table_metadata_set"

///|
#borrow(kernel)
extern "c" fn raw_table_metadata_kernel_added_native(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Int = "mgstudio_ecs_raw_table_metadata_added"

///|
#borrow(kernel)
extern "c" fn raw_table_metadata_kernel_changed_native(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Int = "mgstudio_ecs_raw_table_metadata_changed"

///|
#borrow(kernel)
extern "c" fn raw_table_metadata_kernel_changed_caller_id_native(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Int = "mgstudio_ecs_raw_table_metadata_changed_caller_id"

///|
#borrow(kernel)
extern "c" fn raw_table_metadata_kernel_swap_remove_native(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Bool = "mgstudio_ecs_raw_table_metadata_swap_remove"

///|
fn raw_table_metadata_kernel_new() -> RawTableMetadataKernel {
  raw_table_metadata_kernel_new_native()
}

///|
fn raw_table_metadata_kernel_len(kernel : RawTableMetadataKernel) -> Int {
  raw_table_metadata_kernel_len_native(kernel)
}

///|
fn raw_table_metadata_kernel_push(
  kernel : RawTableMetadataKernel,
  added_sequence : @core.Sequence,
  changed_sequence : @core.Sequence,
  changed_caller_id : Int,
) -> Bool {
  raw_table_metadata_kernel_push_native(
    kernel,
    added_sequence,
    changed_sequence,
    changed_caller_id,
  )
}

///|
fn raw_table_metadata_kernel_set(
  kernel : RawTableMetadataKernel,
  row : Int,
  added_sequence : @core.Sequence,
  changed_sequence : @core.Sequence,
  changed_caller_id : Int,
) -> Bool {
  raw_table_metadata_kernel_set_native(
    kernel,
    row,
    added_sequence,
    changed_sequence,
    changed_caller_id,
  )
}

///|
fn raw_table_metadata_kernel_added(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> @core.Sequence {
  raw_table_metadata_kernel_added_native(kernel, row)
}

///|
fn raw_table_metadata_kernel_changed(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> @core.Sequence {
  raw_table_metadata_kernel_changed_native(kernel, row)
}

///|
fn raw_table_metadata_kernel_changed_caller_id(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Int {
  raw_table_metadata_kernel_changed_caller_id_native(kernel, row)
}

///|
fn raw_table_metadata_kernel_swap_remove(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Bool {
  raw_table_metadata_kernel_swap_remove_native(kernel, row)
}
