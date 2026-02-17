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
  let t1 = t0.tick(0.5F)
  inspect(t1.just_finished(), content="false")
  inspect(t1.is_finished(), content="false")
  inspect(t1.fraction(), content="0.5")

  let t2 = t1.tick(0.6F)
  inspect(t2.just_finished(), content="true")
  inspect(t2.is_finished(), content="true")
  inspect(t2.fraction(), content="1")

  let t3 = t2.tick(0.2F)
  inspect(t3.just_finished(), content="false")
  inspect(t3.is_finished(), content="true")
}

///|
test "timer repeating mode: wraps and finishes on each crossing" {
  let t0 = Timer::from_seconds(1.0F, TimerMode::Repeating)
  let t1 = t0.tick(0.25F)
  inspect(t1.just_finished(), content="false")
  inspect(t1.is_finished(), content="false")
  inspect(t1.fraction(), content="0.25")

  let t2 = t1.tick(0.80F)
  inspect(t2.just_finished(), content="true")
  inspect(t2.is_finished(), content="true")
  inspect(t2.fraction() > 0.049F && t2.fraction() < 0.051F, content="true")
}

///|
test "timer pause/unpause: paused timer does not advance" {
  let t0 = Timer::from_seconds(2.0F, TimerMode::Once).pause()
  let t1 = t0.tick(1.5F)
  inspect(t1.just_finished(), content="false")
  inspect(t1.is_finished(), content="false")
  inspect(t1.fraction(), content="0")

  let t2 = t1.unpause().tick(1.5F)
  inspect(t2.just_finished(), content="false")
  inspect(t2.is_finished(), content="false")
  inspect(t2.fraction(), content="0.75")
}
