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
pub struct ParamSet2[P0, P1] {
  param0 : P0
  param1 : P1
  state0 : SystemParamState[P0]
  state1 : SystemParamState[P1]
}

///|
pub fn[P0, P1] ParamSet2::p0(self : ParamSet2[P0, P1]) -> P0 {
  self.param0
}

///|
pub fn[P0, P1] ParamSet2::p1(self : ParamSet2[P0, P1]) -> P1 {
  self.param1
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with fn init_state(
  world,
) {
  let state0 = P0::init_state(world)
  let state1 = P1::init_state(world)
  SystemParamState::new(
    fn() raise {
      { param0: P0::get(state0), param1: P1::get(state1), state0, state1 }
    },
    fn(value : ParamSet2[P0, P1]) {
      P0::store(value.param0, value.state0)
      P1::store(value.param1, value.state1)
    },
  )
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with fn get(
  state,
) {
  state.get()
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with fn store(
  self,
  state,
) {
  state.store(self)
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with fn access(
  world,
) {
  let access = SystemAccess::new()
  system_access_merge_unchecked(access, P0::access(world))
  system_access_merge_unchecked(access, P1::access(world))
  access
}
