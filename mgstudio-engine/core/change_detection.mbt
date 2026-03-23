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
pub type Tick = Int

///|
pub struct SystemTicks {
  last_run : Tick
  this_run : Tick
}

///|
pub fn SystemTicks::new(last_run : Tick, this_run : Tick) -> SystemTicks {
  { last_run, this_run }
}

///|
pub struct SystemContext {
  mut last_run : Tick
  mut this_run : Tick
}

///|
pub fn SystemContext::new() -> SystemContext {
  { last_run: 0, this_run: 0 }
}

///|
pub fn SystemContext::set(self : SystemContext, system : SystemTicks) -> Unit {
  self.last_run = system.last_run
  self.this_run = system.this_run
}

///|
pub fn SystemContext::ticks(self : SystemContext) -> SystemTicks {
  { last_run: self.last_run, this_run: self.this_run }
}
