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
  inspect(t0.wrap_period_seconds(), content="3600")
  inspect(t0.delta_seconds(), content="0")
  inspect(t0.elapsed_seconds(), content="0")
  inspect(t0.elapsed_wrapped_seconds(), content="0")

  let t1 = t0.advance_by(0.25F)
  inspect(t1.delta_seconds(), content="0.25")
  inspect(t1.elapsed_seconds(), content="0.25")
  inspect(t1.elapsed_wrapped_seconds(), content="0.25")

  let t2 = t1.set_wrap_period_seconds(1.0F)
  inspect(t2.elapsed_wrapped_seconds(), content="0.25")

  let t3 = t2.advance_by(1.5F)
  inspect(t3.delta_seconds(), content="1.5")
  inspect(t3.elapsed_seconds(), content="1.75")
  inspect(t3.elapsed_wrapped_seconds(), content="0.75")

  let t4 = t3.advance_to(2.0F)
  inspect(t4.delta_seconds(), content="0.25")
  inspect(t4.elapsed_seconds(), content="2")
  inspect(t4.elapsed_wrapped_seconds(), content="0")
}

///|
test "time core: real update keeps first delta zero and then advances" {
  let r0 = Real::new(5.0F)
  inspect(r0.delta_seconds(), content="0")
  inspect(r0.elapsed_seconds(), content="0")
  inspect(r0.first_update_seconds(), content="None")

  let r1 = r0.update_with_duration(2.0F)
  inspect(r1.first_update_seconds(), content="Some(7)")
  inspect(r1.last_update_seconds(), content="Some(7)")
  inspect(r1.delta_seconds(), content="0")
  inspect(r1.elapsed_seconds(), content="0")

  let r2 = r1.update_with_instant(9.5F)
  inspect(r2.last_update_seconds(), content="Some(9.5)")
  inspect(r2.delta_seconds(), content="2.5")
  inspect(r2.elapsed_seconds(), content="2.5")
}

///|
test "time core: virtual pause speed and max delta semantics" {
  let v0 = Virtual::new().set_max_delta_seconds(0.5F)
  let v1 = v0.advance_with_raw_delta(1.0F)
  inspect(v1.delta_seconds(), content="0.5")
  inspect(v1.elapsed_seconds(), content="0.5")
  inspect(v1.effective_speed(), content="1")
  inspect(v1.was_paused(), content="false")

  let v2 = v1.set_relative_speed(2.0F)
  let v3 = v2.advance_with_raw_delta(0.25F)
  inspect(v3.delta_seconds(), content="0.5")
  inspect(v3.elapsed_seconds(), content="1")
  inspect(v3.effective_speed(), content="2")

  let v4 = v3.pause().advance_with_raw_delta(0.25F)
  inspect(v4.delta_seconds(), content="0")
  inspect(v4.elapsed_seconds(), content="1")
  inspect(v4.effective_speed(), content="0")
  inspect(v4.was_paused(), content="true")
}

///|
test "time core: fixed constructors and overstep helpers" {
  let f0 = Fixed::from_hz(2.0F)
  inspect(f0.timestep_seconds(), content="0.5")
  inspect(f0.overstep_seconds(), content="0")

  let f1 = f0.accumulate_overstep(0.75F)
  inspect(f1.overstep_seconds(), content="0.75")
  inspect(f1.overstep_fraction(), content="1.5")

  let f2 = f1.discard_overstep(0.5F)
  inspect(f2.overstep_seconds(), content="0.25")
  inspect(f2.overstep_fraction(), content="0.5")
}
