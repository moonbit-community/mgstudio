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
