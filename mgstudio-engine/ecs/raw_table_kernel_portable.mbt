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
pub(all) struct RawTableColumnKernel {
  mut added_ticks : Array[@core.Tick]
  mut changed_ticks : Array[@core.Tick]
  mut changed_caller_ids : Array[Int]
}

///|
fn raw_table_column_kernel_new() -> RawTableColumnKernel {
  { added_ticks: [], changed_ticks: [], changed_caller_ids: [] }
}

///|
fn raw_table_column_kernel_len(kernel : RawTableColumnKernel) -> Int {
  kernel.added_ticks.length()
}

///|
fn raw_table_column_kernel_push(
  kernel : RawTableColumnKernel,
  added_tick : @core.Tick,
  changed_tick : @core.Tick,
  changed_caller_id : Int,
) -> Bool {
  kernel.added_ticks.push(added_tick)
  kernel.changed_ticks.push(changed_tick)
  kernel.changed_caller_ids.push(changed_caller_id)
  true
}

///|
fn raw_table_column_kernel_set_metadata(
  kernel : RawTableColumnKernel,
  row : Int,
  added_tick : @core.Tick,
  changed_tick : @core.Tick,
  changed_caller_id : Int,
) -> Bool {
  if row < 0 || row >= kernel.added_ticks.length() {
    return false
  }
  kernel.added_ticks[row] = added_tick
  kernel.changed_ticks[row] = changed_tick
  kernel.changed_caller_ids[row] = changed_caller_id
  true
}

///|
fn raw_table_column_kernel_set_changed(
  kernel : RawTableColumnKernel,
  row : Int,
  changed_tick : @core.Tick,
  changed_caller_id : Int,
) -> Bool {
  if row < 0 || row >= kernel.added_ticks.length() {
    return false
  }
  kernel.changed_ticks[row] = changed_tick
  kernel.changed_caller_ids[row] = changed_caller_id
  true
}

///|
fn raw_table_column_kernel_added(
  kernel : RawTableColumnKernel,
  row : Int,
) -> @core.Tick {
  if row < 0 || row >= kernel.added_ticks.length() {
    return -1
  }
  kernel.added_ticks[row]
}

///|
fn raw_table_column_kernel_changed(
  kernel : RawTableColumnKernel,
  row : Int,
) -> @core.Tick {
  if row < 0 || row >= kernel.changed_ticks.length() {
    return -1
  }
  kernel.changed_ticks[row]
}

///|
fn raw_table_column_kernel_changed_caller_id(
  kernel : RawTableColumnKernel,
  row : Int,
) -> Int {
  if row < 0 || row >= kernel.changed_caller_ids.length() {
    return 0
  }
  kernel.changed_caller_ids[row]
}

///|
fn raw_table_column_kernel_swap_remove(
  kernel : RawTableColumnKernel,
  row : Int,
) -> Bool {
  if row < 0 || row >= kernel.added_ticks.length() {
    return false
  }
  let last_index = kernel.added_ticks.length() - 1
  if row != last_index {
    kernel.added_ticks[row] = kernel.added_ticks[last_index]
    kernel.changed_ticks[row] = kernel.changed_ticks[last_index]
    kernel.changed_caller_ids[row] = kernel.changed_caller_ids[last_index]
  }
  ignore(kernel.added_ticks.pop())
  ignore(kernel.changed_ticks.pop())
  ignore(kernel.changed_caller_ids.pop())
  true
}
