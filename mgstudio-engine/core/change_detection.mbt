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
/// Bevy source: `bevy_ecs::change_detection::{Tick, ComponentTicks}`.
/// MoonBit keeps `Tick` as an `Int64` payload so existing ECS storage can remain
/// value-oriented while using Bevy's relative tick comparison semantics.

///|
pub type Tick = Int64

///|
pub let check_tick_threshold : Tick = 518_400_000

///|
pub let max_change_age : Tick = 3_258_167_296

///|
let tick_modulus : Tick = 4_294_967_296

///|
pub fn tick_normalize(tick : Tick) -> Tick {
  let normalized = tick % tick_modulus
  if normalized < 0 {
    normalized + tick_modulus
  } else {
    normalized
  }
}

///|
pub fn tick_wrapping_add(tick : Tick, delta : Tick) -> Tick {
  tick_normalize(tick + delta)
}

///|
pub fn tick_relative_to(tick : Tick, other : Tick) -> Tick {
  tick_normalize(tick_normalize(tick) - tick_normalize(other))
}

///|
pub fn tick_is_newer_than(
  tick : Tick,
  last_run : Tick,
  this_run : Tick,
) -> Bool {
  let ticks_since_insert = tick_relative_to(this_run, tick).min(max_change_age)
  let ticks_since_system = tick_relative_to(this_run, last_run).min(
    max_change_age,
  )
  ticks_since_system > ticks_since_insert
}

///|
pub fn tick_check(tick : Tick, present_tick : Tick) -> Tick {
  let age = tick_relative_to(present_tick, tick)
  if age > max_change_age {
    tick_wrapping_add(present_tick, -max_change_age)
  } else {
    tick
  }
}

///|
pub struct ComponentTicks {
  added : Tick
  changed : Tick
}

///|
pub fn ComponentTicks::new(change_tick : Tick) -> ComponentTicks {
  { added: change_tick, changed: change_tick }
}

///|
pub fn ComponentTicks::is_added(
  self : ComponentTicks,
  last_run : Tick,
  this_run : Tick,
) -> Bool {
  tick_is_newer_than(self.added, last_run, this_run)
}

///|
pub fn ComponentTicks::is_changed(
  self : ComponentTicks,
  last_run : Tick,
  this_run : Tick,
) -> Bool {
  tick_is_newer_than(self.changed, last_run, this_run)
}

///|
pub fn ComponentTicks::check_ticks(
  self : ComponentTicks,
  present_tick : Tick,
) -> ComponentTicks {
  {
    added: tick_check(self.added, present_tick),
    changed: tick_check(self.changed, present_tick),
  }
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
pub fn SystemTicks::contains(self : SystemTicks, tick : Tick) -> Bool {
  tick_is_newer_than(tick, self.last_run, self.this_run)
}

///|
pub struct SystemTickContext {
  mut last_run : Tick
  mut this_run : Tick
}

///|
pub fn SystemTickContext::new() -> SystemTickContext {
  { last_run: 0, this_run: 0 }
}

///|
pub fn SystemTickContext::set(
  self : SystemTickContext,
  system : SystemTicks,
) -> Unit {
  self.last_run = system.last_run
  self.this_run = system.this_run
}

///|
pub fn SystemTickContext::ticks(self : SystemTickContext) -> SystemTicks {
  { last_run: self.last_run, this_run: self.this_run }
}
