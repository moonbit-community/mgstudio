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
pub fn[S : States] insert_state_app(
  app : App[@ecs.World],
  state : S,
) -> App[@ecs.World] {
  register_state_transition(state)
  app.world.insert_resource(state_resource_key(state), State::new(state))
  app.world.insert_resource(
    next_state_resource_key(state),
    NextState::Unchanged,
  )
  let _ : Result[PreviousState[S]?, @ecs.EcsError] = try? app.world.remove_resource(
    previous_state_resource_key(state),
  )
  app
}

///|
pub fn[S : States] App::insert_state(
  self : App[@ecs.World],
  state : S,
) -> App[@ecs.World] {
  insert_state_app(self, state)
}
