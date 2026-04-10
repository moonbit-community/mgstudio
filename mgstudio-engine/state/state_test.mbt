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
pub(all) enum TestState {
  Idle
  Running
} derive(Eq, Debug)

///|
pub impl @app.States for TestState with dependency_depth(self) {
  ignore(self)
  0
}

///|
pub impl @app.States for TestState with debug_name(self) {
  ignore(self)
  "TestState"
}

///|
test "state boundary re-exports state resources and transitions" {
  let world = @ecs.World::new()
  let app = @app.App::new(world).add_plugin(
    @state.states_plugin(@state.StatesPlugin::default()),
  )
  let app = @state.insert_state_app(app, TestState::Idle)
  let world = app.world()
  let key = @state.state_resource_key(TestState::Idle)
  let current = try! world.get_resource(key)
  debug_inspect(current is Some(_), content="true")
  let in_idle = @state.in_state(TestState::Idle)
  debug_inspect(in_idle(world), content="true")
}
