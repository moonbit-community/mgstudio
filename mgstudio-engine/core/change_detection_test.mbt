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
test "change_detection: system context stores execution tick window" {
  let ctx = SystemTickContext::new()
  ctx.set(SystemTicks::new(2, 5))
  let tick = ctx.ticks()
  debug_inspect(tick.last_run == 2 && tick.this_run == 5, content="true")
}

///|
test "change_detection: tick newer-than matches Bevy window semantics" {
  debug_inspect(tick_is_newer_than(5, 2, 5), content="true")
  debug_inspect(tick_is_newer_than(2, 2, 5), content="false")
  debug_inspect(tick_is_newer_than(1, 1_999_999_998, 2), content="true")
}

///|
test "change_detection: component ticks use added and changed ticks" {
  let ticks = ComponentTicks::new(5)
  debug_inspect(ticks.is_added(2, 5), content="true")
  debug_inspect(ticks.is_changed(5, 6), content="false")
}
