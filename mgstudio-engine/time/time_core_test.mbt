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
test "time core: advance and wrap semantics follow bevy shape" {
  let t0 = Time::new()
  inspect(t0.wrap_period().as_secs_f32(), content="3600")
  inspect(t0.delta().as_millis(), content="0")
  inspect(t0.elapsed().as_millis(), content="0")
  inspect(t0.elapsed_wrapped().as_millis(), content="0")

  let t1 = t0.advance_by(@core.Duration::from_millis(250L))
  inspect(t1.delta().as_millis(), content="250")
  inspect(t1.elapsed().as_millis(), content="250")
  inspect(t1.elapsed_wrapped().as_millis(), content="250")

  let t2 = t1.set_wrap_period(@core.Duration::from_secs(1L))
  inspect(t2.elapsed_wrapped().as_millis(), content="250")

  let t3 = t2.advance_by(@core.Duration::from_millis(1500L))
  inspect(t3.delta().as_millis(), content="1500")
  inspect(t3.elapsed().as_millis(), content="1750")
  inspect(t3.elapsed_wrapped().as_millis(), content="750")

  let t4 = t3.advance_to(@core.Duration::from_secs(2L))
  inspect(t4.delta().as_millis(), content="250")
  inspect(t4.elapsed().as_millis(), content="2000")
  inspect(t4.elapsed_wrapped().as_millis(), content="0")
}

///|
test "time core: real update keeps first delta zero and then advances" {
  let r0 = Real::new(@core.Instant::from_secs_f32(5.0F))
  inspect(r0.delta().as_millis(), content="0")
  inspect(r0.elapsed().as_millis(), content="0")
  inspect(r0.first_update_seconds(), content="None")

  let r1 = r0.update_with_duration(@core.Duration::from_secs(2L))
  inspect(r1.first_update_seconds(), content="Some(7)")
  inspect(r1.last_update_seconds(), content="Some(7)")
  inspect(r1.delta().as_millis(), content="0")
  inspect(r1.elapsed().as_millis(), content="0")

  let r2 = r1.update_with_instant(@core.Instant::from_secs_f32(9.5F))
  inspect(r2.last_update_seconds(), content="Some(9.5)")
  inspect(r2.delta().as_millis(), content="2500")
  inspect(r2.elapsed().as_millis(), content="2500")
}

///|
test "time core: virtual pause speed and max delta semantics" {
  let v0 = Virtual::new().set_max_delta(@core.Duration::from_millis(500L))
  let v1 = v0.advance_with_raw_delta(@core.Duration::from_secs(1L))
  inspect(v1.delta().as_millis(), content="500")
  inspect(v1.elapsed().as_millis(), content="500")
  inspect(v1.effective_speed(), content="1")
  inspect(v1.was_paused(), content="false")

  let v2 = v1.set_relative_speed(2.0F)
  let v3 = v2.advance_with_raw_delta(@core.Duration::from_millis(250L))
  inspect(v3.delta().as_millis(), content="500")
  inspect(v3.elapsed().as_millis(), content="1000")
  inspect(v3.effective_speed(), content="2")

  let v4 = v3.pause().advance_with_raw_delta(@core.Duration::from_millis(250L))
  inspect(v4.delta().as_millis(), content="0")
  inspect(v4.elapsed().as_millis(), content="1000")
  inspect(v4.effective_speed(), content="0")
  inspect(v4.was_paused(), content="true")
}

///|
test "time core: fixed constructors and overstep helpers" {
  let f0 = Fixed::from_hz(2.0F)
  inspect(f0.timestep().as_millis(), content="500")
  inspect(f0.overstep().as_millis(), content="0")

  let f1 = f0.accumulate_overstep(@core.Duration::from_millis(750L))
  inspect(f1.overstep().as_millis(), content="750")
  inspect(f1.overstep_fraction(), content="1.5")

  let f2 = f1.discard_overstep(@core.Duration::from_millis(500L))
  inspect(f2.overstep().as_millis(), content="250")
  inspect(f2.overstep_fraction(), content="0.5")
}
