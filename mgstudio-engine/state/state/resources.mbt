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
// Bevy source: `bevy/crates/bevy_state/src/state/resources.rs`.

///|
pub type StateResource[S] = @state_root.State[S]

///|
pub type NextStateResource[S] = @state_root.NextState[S]

///|
pub fn[S : @app.States] state_resource_component_key(
  state : S,
) -> @ecs.ResourceKey[StateResource[S]] {
  @state_root.state_resource_key(state)
}
