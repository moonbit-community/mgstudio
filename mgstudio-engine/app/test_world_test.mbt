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

// Shared test-only world implementation for the app scheduler tests.
// This keeps `App` generic but still satisfies change detection constraints.
///|
struct TestWorld {
  mut tick : @core.Tick
  mut ctx : @core.SystemContext
}

///|
fn TestWorld::new() -> TestWorld {
  { tick: 0, ctx: @core.SystemContext::new() }
}

///|
impl @core.ChangeTickWorld for TestWorld with read_change_tick(self) {
  self.tick
}

///|
impl @core.ChangeTickWorld for TestWorld with increment_change_tick(self) {
  self.tick = self.tick + 1
  self.tick
}

///|
impl @core.SystemContextWorld for TestWorld with get_system_context(self) {
  self.ctx
}

///|
impl @core.SystemContextWorld for TestWorld with set_system_context(self, ctx) {
  self.ctx = ctx
}
