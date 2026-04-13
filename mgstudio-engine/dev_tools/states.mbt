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
// Bevy source: `bevy/crates/bevy_dev_tools/src/states.rs`.

///|
pub fn[S : @app.States] log_transitions(world : @ecs.World, state : S) -> Unit {
  guard @app.last_transition(world, state) is Some(transition) else { return }
  let skip_text = if transition.exited == transition.entered &&
    !transition.allow_same_state_transitions {
    " (disallowing same-state transitions)"
  } else {
    ""
  }
  let state_name = @app.States::debug_name(state)
  println(
    "\{state_name} transition: \{to_repr(transition.exited).to_string()} => \{to_repr(transition.entered).to_string()}\{skip_text}",
  )
}
