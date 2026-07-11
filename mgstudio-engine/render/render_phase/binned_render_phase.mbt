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
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::PhaseItemExtraIndex`.
pub(all) enum PhaseItemExtraIndex {
  None
  DynamicOffset(Int)
  IndirectParametersIndex(Int, Int, Int?)
} derive(Eq, Debug)

///|
pub fn PhaseItemExtraIndex::none() -> PhaseItemExtraIndex {
  PhaseItemExtraIndex::None
}

///|
pub fn PhaseItemExtraIndex::dynamic_offset(offset : Int) -> PhaseItemExtraIndex {
  DynamicOffset(offset)
}

///|
pub fn PhaseItemExtraIndex::maybe_dynamic_offset(
  dynamic_offset : Int?,
) -> PhaseItemExtraIndex {
  match dynamic_offset {
    Some(offset) => DynamicOffset(offset)
    None => PhaseItemExtraIndex::None
  }
}

///|
pub fn PhaseItemExtraIndex::indirect_parameters_index(
  range_start : Int,
  range_end : Int,
  batch_set_index? : Int? = None,
) -> PhaseItemExtraIndex {
  IndirectParametersIndex(range_start, range_end, batch_set_index)
}

///|
pub fn PhaseItemExtraIndex::maybe_indirect_parameters_index(
  indirect_parameters_index : Int?,
) -> PhaseItemExtraIndex {
  match indirect_parameters_index {
    Some(index) => IndirectParametersIndex(index, index + 1, None)
    None => PhaseItemExtraIndex::None
  }
}

///|
pub fn PhaseItemExtraIndex::indirect_parameters_range(
  self : PhaseItemExtraIndex,
) -> (Int, Int, Int?)? {
  match self {
    IndirectParametersIndex(range_start, range_end, batch_set_index) =>
      Some((range_start, range_end, batch_set_index))
    _ => None
  }
}

///|
// MoonBit representation of the `Range<u32>` stored by Bevy phase items.
pub struct PhaseItemBatchRange {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn PhaseItemBatchRange::new(start : Int, end : Int) -> PhaseItemBatchRange {
  if start < 0 || end < 0 {
    abort("phase item batch range bounds must be non-negative")
  }
  PhaseItemBatchRange::{ start, end }
}

///|
pub fn PhaseItemBatchRange::start(self : PhaseItemBatchRange) -> Int {
  self.start
}

///|
pub fn PhaseItemBatchRange::end(self : PhaseItemBatchRange) -> Int {
  self.end
}

///|
pub fn PhaseItemBatchRange::count(self : PhaseItemBatchRange) -> Int {
  if self.end <= self.start {
    0
  } else {
    self.end - self.start
  }
}
