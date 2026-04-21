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
  state0 : Ref[Json]
  state1 : Ref[Json]
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
fn param_set2_decode_state(state : Ref[Json]) -> (Json, Json) {
  try @json.from_json(state.val) catch {
    _ => (Json::null(), Json::null())
  } noraise {
    value => value
  }
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with init_state(
  world,
) {
  (P0::init_state(world), P1::init_state(world)).to_json()
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with get(
  state,
) {
  let (state0, state1) = param_set2_decode_state(state)
  let state0_ref = Ref::new(state0)
  let state1_ref = Ref::new(state1)
  ParamSet2::{
    param0: P0::get(state0_ref),
    param1: P1::get(state1_ref),
    state0: state0_ref,
    state1: state1_ref,
  }
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with store(
  self,
  state,
) {
  P0::store(self.param0, self.state0)
  P1::store(self.param1, self.state1)
  state.val = (self.state0.val, self.state1.val).to_json()
}

///|
pub impl[P0 : SystemParam, P1 : SystemParam] SystemParam for ParamSet2[P0, P1] with access(
  world,
) {
  let access = SystemAccess::new()
  system_access_merge_unchecked(access, P0::access(world))
  system_access_merge_unchecked(access, P1::access(world))
  access
}
