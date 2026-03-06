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
test "time_core fixed: expend follows bevy-style one-step consumption" {
  let fixed0 = Fixed::from_seconds(0.2F).accumulate_overstep(0.45F)
  inspect(fixed0.overstep_seconds(), content="0.44999998807907104")
  inspect(fixed0.elapsed_seconds(), content="0")

  let fixed1 = fixed0.expend().unwrap()
  inspect(fixed1.overstep_seconds(), content="0.2499999850988388")
  inspect(
    fixed1.elapsed_seconds(),
    content=(
      #|0.20000000298023224
    ),
  )
  inspect(
    fixed1.delta_seconds(),
    content=(
      #|0.20000000298023224
    ),
  )

  let fixed2 = fixed1.expend().unwrap()
  inspect(fixed2.overstep_seconds(), content="0.04999998211860657")
  inspect(
    fixed2.elapsed_seconds(),
    content=(
      #|0.4000000059604645
    ),
  )

  inspect(fixed2.expend() is None, content="true")
}

///|
test "time_core fixed: runtime state rewrite preserves wrap semantics" {
  let fixed0 = Fixed::new().set_runtime_state(0.125F, 0.05F, 1.3F)
  inspect(fixed0.timestep_seconds(), content="0.125")
  inspect(fixed0.overstep_seconds(), content="0.05000000074505806")
  inspect(
    fixed0.elapsed_seconds(),
    content=(
      #|1.2999999523162842
    ),
  )
  inspect(
    fixed0.as_generic().elapsed_wrapped_seconds(),
    content=(
      #|1.2999999523162842
    ),
  )

  let fixed1 = fixed0.set_runtime_state(0.25F, 0.1F, 3601.3F)
  inspect(fixed1.timestep_seconds(), content="0.25")
  inspect(
    fixed1.overstep_seconds(),
    content=(
      #|0.10000000149011612
    ),
  )
  inspect(
    fixed1.elapsed_seconds(),
    content=(
      #|3601.300048828125
    ),
  )
  inspect(
    fixed1.as_generic().elapsed_wrapped_seconds(),
    content="1.300048828125",
  )
}
