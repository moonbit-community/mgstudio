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
test "bench time: tick repeating timers" (b : @bench.T) {
  let timer_count = 20_000
  let timers = Array::make(
    timer_count,
    Timer::from_seconds(1.0F, TimerMode::Repeating),
  )
  let delta = @core.Duration::from_millis(16L)
  b.bench(name="tick repeating timers x20000", count=100U, () => {
    for index in 0..<timers.length() {
      timers[index] = timers[index].tick(delta)
    }
    b.keep(timers[0].elapsed().as_nanos())
  })
}
