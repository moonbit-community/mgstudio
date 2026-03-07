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
pub(all) enum DerivedState {
  Active
} derive(Eq, Show)

///|
impl States for DerivedState with debug_name(self) {
  ignore(self)
  "DerivedState"
}

///|
fn compute_derived_state(source : TestState) -> DerivedState? {
  match source {
    TestState::A => Some(DerivedState::Active)
    TestState::B => None
  }
}

///|
test "app computed state: follows source transitions" {
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_computed_state(
      TestState::A,
      DerivedState::Active,
      compute_derived_state,
    )
    .add_system_config(
      system(fn(_world : @ecs.World) { set_state(TestState::B) }).run_if(
        in_state(TestState::A),
      ),
    )

  app.run_startup() |> ignore
  inspect(
    world_state(app.world(), DerivedState::Active),
    content="Some({value: Active})",
  )
  inspect(
    last_transition(app.world(), DerivedState::Active),
    content="Some({exited: None, entered: Some(Active), allow_same_state_transitions: true})",
  )

  app.run_once() |> ignore
  inspect(
    world_state(app.world(), DerivedState::Active),
    content="Some({value: Active})",
  )

  app.run_once() |> ignore
  inspect(world_state(app.world(), DerivedState::Active), content="None")
  inspect(
    last_transition(app.world(), DerivedState::Active),
    content="Some({exited: Some(Active), entered: None, allow_same_state_transitions: true})",
  )
}
