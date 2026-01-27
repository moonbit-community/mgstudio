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
/// Change detection primitives aligned with Bevy's `bevy_ecs::change_detection`.

///|
pub type Tick = Int

///|
pub struct ComponentTicks {
  mut added : Tick
  mut changed : Tick
}

///|
pub fn ComponentTicks::new(change_tick : Tick) -> ComponentTicks {
  { added: change_tick, changed: change_tick }
}

///|
pub fn ComponentTicks::set_changed(
  self : ComponentTicks,
  change_tick : Tick,
) -> Unit {
  self.changed = change_tick
}

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
fn tick_in_range(tick : Tick, last_run : Tick, this_run : Tick) -> Bool {
  // Simplified, non-wrapping tick comparison.
  tick > last_run && tick <= this_run
}

///|
pub fn ComponentTicks::is_added(
  self : ComponentTicks,
  system : SystemTicks,
) -> Bool {
  tick_in_range(self.added, system.last_run, system.this_run)
}

///|
pub fn ComponentTicks::is_changed(
  self : ComponentTicks,
  system : SystemTicks,
) -> Bool {
  tick_in_range(self.changed, system.last_run, system.this_run)
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

///|
pub(open) trait ChangeTickWorld {
  read_change_tick(self : Self) -> Tick
  increment_change_tick(self : Self) -> Tick
}

///|
pub(open) trait SystemContextWorld {
  get_system_context(self : Self) -> SystemContext
  set_system_context(self : Self, ctx : SystemContext) -> Unit
}
