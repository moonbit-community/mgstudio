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
pub(open) trait FreelyMutableState: States {}

///|
pub fn[S] NextState::set(_self : NextState[S], state : S) -> NextState[S] {
  Pending(state)
}

///|
pub fn[S : Eq] NextState::set_if_neq(
  self : NextState[S],
  state : S,
) -> NextState[S] {
  match self {
    Pending(existing) =>
      if existing == state {
        self
      } else {
        PendingIfNeq(state)
      }
    PendingIfNeq(existing) =>
      if existing == state {
        self
      } else {
        PendingIfNeq(state)
      }
    Unchanged => PendingIfNeq(state)
  }
}

///|
pub fn[S] NextState::reset(_self : NextState[S]) -> NextState[S] {
  Unchanged
}

///|
fn[S] take_next_state(next_state : NextState[S]) -> (S, Bool)? {
  match next_state {
    Pending(state) => Some((state, true))
    PendingIfNeq(state) => Some((state, false))
    Unchanged => None
  }
}
