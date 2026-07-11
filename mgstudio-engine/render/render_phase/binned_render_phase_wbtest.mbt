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
test "render_phase: phase item extra indices preserve direct and indirect forms" {
  debug_inspect(PhaseItemExtraIndex::none(), content="None")
  debug_inspect(
    PhaseItemExtraIndex::dynamic_offset(64),
    content="DynamicOffset(64)",
  )
  debug_inspect(
    PhaseItemExtraIndex::maybe_dynamic_offset(Some(65)),
    content="DynamicOffset(65)",
  )
  debug_inspect(PhaseItemExtraIndex::maybe_dynamic_offset(None), content="None")
  let indirect = PhaseItemExtraIndex::indirect_parameters_index(
    7,
    10,
    batch_set_index=Some(3),
  )
  debug_inspect(indirect, content="IndirectParametersIndex(7, 10, Some(3))")
  debug_inspect(
    indirect.indirect_parameters_range(),
    content="Some((7, 10, Some(3)))",
  )
  debug_inspect(
    PhaseItemExtraIndex::maybe_indirect_parameters_index(Some(11)),
    content="IndirectParametersIndex(11, 12, None)",
  )
}

///|
test "render_phase: phase item batch range preserves valid u32-like bounds" {
  let range = PhaseItemBatchRange::new(4, 9)
  debug_inspect(range, content="{ start: 4, end: 9 }")
  inspect(range.count(), content="5")
  let empty = PhaseItemBatchRange::new(9, 4)
  debug_inspect(empty, content="{ start: 9, end: 4 }")
  inspect(empty.count(), content="0")
}
