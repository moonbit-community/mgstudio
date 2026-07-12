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
priv struct WorldResourceTickRegistry {
  check_change_ticks_by_key_id : Map[Int, (@core.Tick) -> Unit]
}

///|
fn world_resource_tick_registry_new() -> WorldResourceTickRegistry {
  { check_change_ticks_by_key_id: Map([]) }
}

///|
fn WorldResourceTickRegistry::track(
  self : WorldResourceTickRegistry,
  key_id : Int,
  check_change_ticks : (@core.Tick) -> Unit,
) -> Unit {
  self.check_change_ticks_by_key_id.set(key_id, check_change_ticks)
}

///|
fn WorldResourceTickRegistry::untrack(
  self : WorldResourceTickRegistry,
  key_id : Int,
) -> Unit {
  self.check_change_ticks_by_key_id.remove(key_id)
}

///|
fn WorldResourceTickRegistry::check_change_ticks(
  self : WorldResourceTickRegistry,
  present_tick : @core.Tick,
) -> Unit {
  for entry in self.check_change_ticks_by_key_id.iter() {
    (entry.1)(present_tick)
  }
}
