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
priv struct RawTableRowKernel {
  mut entities : Array[@core.Entity]
}

///|
fn raw_table_row_kernel_new() -> RawTableRowKernel {
  { entities: [] }
}

///|
fn raw_table_row_kernel_len(kernel : RawTableRowKernel) -> Int {
  kernel.entities.length()
}

///|
fn raw_table_row_kernel_push(
  kernel : RawTableRowKernel,
  entity : @core.Entity,
) -> Int {
  let row = kernel.entities.length()
  kernel.entities.push(entity)
  row
}

///|
fn raw_table_row_kernel_entity_at(
  kernel : RawTableRowKernel,
  row : Int,
) -> @core.Entity? {
  if row < 0 || row >= kernel.entities.length() {
    return None
  }
  Some(kernel.entities[row])
}

///|
fn raw_table_row_kernel_swap_remove(
  kernel : RawTableRowKernel,
  row : Int,
) -> Bool {
  if row < 0 || row >= kernel.entities.length() {
    return false
  }
  let last_index = kernel.entities.length() - 1
  if row != last_index {
    kernel.entities[row] = kernel.entities[last_index]
  }
  ignore(kernel.entities.pop())
  true
}

///|
priv struct RawTableMetadataKernel {
  mut added_sequences : Array[@core.Sequence]
  mut changed_sequences : Array[@core.Sequence]
  mut changed_caller_ids : Array[Int]
}

///|
fn raw_table_metadata_kernel_new() -> RawTableMetadataKernel {
  { added_sequences: [], changed_sequences: [], changed_caller_ids: [] }
}

///|
fn raw_table_metadata_kernel_len(kernel : RawTableMetadataKernel) -> Int {
  kernel.added_sequences.length()
}

///|
fn raw_table_metadata_kernel_push(
  kernel : RawTableMetadataKernel,
  added_sequence : @core.Sequence,
  changed_sequence : @core.Sequence,
  changed_caller_id : Int,
) -> Bool {
  kernel.added_sequences.push(added_sequence)
  kernel.changed_sequences.push(changed_sequence)
  kernel.changed_caller_ids.push(changed_caller_id)
  true
}

///|
fn raw_table_metadata_kernel_set(
  kernel : RawTableMetadataKernel,
  row : Int,
  added_sequence : @core.Sequence,
  changed_sequence : @core.Sequence,
  changed_caller_id : Int,
) -> Bool {
  if row < 0 || row >= kernel.added_sequences.length() {
    return false
  }
  kernel.added_sequences[row] = added_sequence
  kernel.changed_sequences[row] = changed_sequence
  kernel.changed_caller_ids[row] = changed_caller_id
  true
}

///|
fn raw_table_metadata_kernel_added(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> @core.Sequence {
  if row < 0 || row >= kernel.added_sequences.length() {
    return -1
  }
  kernel.added_sequences[row]
}

///|
fn raw_table_metadata_kernel_changed(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> @core.Sequence {
  if row < 0 || row >= kernel.changed_sequences.length() {
    return -1
  }
  kernel.changed_sequences[row]
}

///|
fn raw_table_metadata_kernel_changed_caller_id(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Int {
  if row < 0 || row >= kernel.changed_caller_ids.length() {
    return 0
  }
  kernel.changed_caller_ids[row]
}

///|
fn raw_table_metadata_kernel_swap_remove(
  kernel : RawTableMetadataKernel,
  row : Int,
) -> Bool {
  if row < 0 || row >= kernel.added_sequences.length() {
    return false
  }
  let last_index = kernel.added_sequences.length() - 1
  if row != last_index {
    kernel.added_sequences[row] = kernel.added_sequences[last_index]
    kernel.changed_sequences[row] = kernel.changed_sequences[last_index]
    kernel.changed_caller_ids[row] = kernel.changed_caller_ids[last_index]
  }
  ignore(kernel.added_sequences.pop())
  ignore(kernel.changed_sequences.pop())
  ignore(kernel.changed_caller_ids.pop())
  true
}
