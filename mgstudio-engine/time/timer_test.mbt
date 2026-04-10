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
test "timer once mode: transitions to finished only once" {
  let t0 = Timer::from_seconds(1.0F, TimerMode::Once)
  let t1 = t0.tick(@core.Duration::from_millis(500L))
  debug_inspect(t1.just_finished(), content="false")
  debug_inspect(t1.is_finished(), content="false")
  debug_inspect(t1.fraction(), content="0.5")
  debug_inspect(t1.remaining().as_millis(), content="500")

  let t2 = t1.tick(@core.Duration::from_millis(600L))
  debug_inspect(t2.just_finished(), content="true")
  debug_inspect(t2.is_finished(), content="true")
  debug_inspect(t2.fraction(), content="1")
  debug_inspect(t2.elapsed().as_millis(), content="1000")

  let t3 = t2.tick(@core.Duration::from_millis(200L))
  debug_inspect(t3.just_finished(), content="false")
  debug_inspect(t3.is_finished(), content="true")
  debug_inspect(t3.remaining().as_millis(), content="0")
}

///|
test "timer repeating mode: wraps and finishes on each crossing" {
  let t0 = Timer::from_seconds(1.0F, TimerMode::Repeating)
  let t1 = t0.tick(@core.Duration::from_millis(250L))
  debug_inspect(t1.just_finished(), content="false")
  debug_inspect(t1.is_finished(), content="false")
  debug_inspect(t1.fraction(), content="0.25")

  let t2 = t1.tick(@core.Duration::from_millis(800L))
  debug_inspect(t2.just_finished(), content="true")
  debug_inspect(t2.is_finished(), content="true")
  debug_inspect(t2.times_finished_this_tick(), content="1")
  debug_inspect(t2.elapsed().as_millis(), content="50")
}

///|
test "timer pause/unpause: paused timer does not advance" {
  let t0 = Timer::from_seconds(2.0F, TimerMode::Once).pause()
  let t1 = t0.tick(@core.Duration::from_millis(1500L))
  debug_inspect(t1.just_finished(), content="false")
  debug_inspect(t1.is_finished(), content="false")
  debug_inspect(t1.fraction(), content="0")

  let t2 = t1.unpause().tick(@core.Duration::from_millis(1500L))
  debug_inspect(t2.just_finished(), content="false")
  debug_inspect(t2.is_finished(), content="false")
  debug_inspect(t2.fraction(), content="0.75")
}

///|
test "timer finish helpers match bevy behavior" {
  let once = Timer::from_seconds(1.5F, TimerMode::Once).almost_finish()
  debug_inspect(once.is_finished(), content="false")
  debug_inspect(once.remaining().as_nanos(), content="1")

  let finished = once.finish()
  debug_inspect(finished.is_finished(), content="true")
  debug_inspect(finished.just_finished(), content="true")
  debug_inspect(finished.elapsed().as_millis(), content="1500")
}
