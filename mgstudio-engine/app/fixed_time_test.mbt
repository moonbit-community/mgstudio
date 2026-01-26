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
test "fixed update: accumulates time and may run multiple ticks per frame" {
  fixed_time_reset()
  fixed_time_set_timestep_seconds(0.2F)
  fixed_time_set_max_delta_seconds(0.25F)
  let first : Ref[Bool] = Ref::new(true)
  set_delta_seconds_provider(fn() {
    if first.val {
      first.val = false
      0.0F
    } else {
      0.101F
    }
  })
  let counter : Ref[Int] = Ref::new(0)
  let mut app = App::new().add_fixed_update_system(fn() {
    counter.val = counter.val + 1
  })

  // Frame 0: first delta is 0
  app = app.run_once()
  inspect(counter.val, content="0")

  // Frame 1: +0.101 < 0.2
  app = app.run_once()
  inspect(counter.val, content="0")

  // Frame 2: +0.101 accumulates to > 0.2 => run once
  app = app.run_once()
  inspect(counter.val, content="1")

  // Frame 3: still < 0.2
  app = app.run_once()
  inspect(counter.val, content="1")

  // Frame 4: should run twice total
  app = app.run_once()
  inspect(counter.val, content="2")
  clear_delta_seconds_provider()
}
