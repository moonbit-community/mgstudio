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
/// Per-system execution sequence primitives used by message readers.

///|
pub type Sequence = Int

///|
pub struct SystemSequence {
  last_run : Sequence
  this_run : Sequence
}

///|
pub fn SystemSequence::new(
  last_run : Sequence,
  this_run : Sequence,
) -> SystemSequence {
  { last_run, this_run }
}

///|
pub struct SystemSequenceContext {
  mut last_run : Sequence
  mut this_run : Sequence
}

///|
pub fn SystemSequenceContext::new() -> SystemSequenceContext {
  { last_run: 0, this_run: 0 }
}

///|
pub fn SystemSequenceContext::set(
  self : SystemSequenceContext,
  system : SystemSequence,
) -> Unit {
  self.last_run = system.last_run
  self.this_run = system.this_run
}

///|
pub fn SystemSequenceContext::sequence(
  self : SystemSequenceContext,
) -> SystemSequence {
  { last_run: self.last_run, this_run: self.this_run }
}

///|
pub fn SystemSequence::contains(
  self : SystemSequence,
  sequence : Sequence,
) -> Bool {
  let last_run = self.last_run
  let this_run = self.this_run
  if this_run >= last_run {
    sequence > last_run && sequence <= this_run
  } else {
    sequence > last_run || sequence <= this_run
  }
}
