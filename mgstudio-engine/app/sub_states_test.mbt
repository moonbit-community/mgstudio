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
pub(all) enum TestSubState {
  Setup
  Battle
} derive(Eq, Debug)

///|
impl States for TestSubState with debug_name(self) {
  ignore(self)
  "TestSubState"
}

///|
impl FreelyMutableState for TestSubState

///|
impl SubStates for TestSubState

///|
fn test_sub_state_should_exist(source : TestState) -> TestSubState? {
  match source {
    TestState::A => Some(TestSubState::Setup)
    TestState::B => None
  }
}

///|
test "app sub state: source transition creates and removes sub state" {
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_sub_state(
      TestState::A,
      TestSubState::Setup,
      test_sub_state_should_exist,
    )
    .add_system_config(
      system(fn(_world : @ecs.World) { set_state(TestState::B) }).run_if(
        in_state(TestState::A),
      ),
    )

  app.run_startup() |> ignore
  debug_inspect(
    world_state(app.world(), TestSubState::Setup),
    content="Some({value: Setup})",
  )
  debug_inspect(
    last_transition(app.world(), TestSubState::Setup),
    content="Some({exited: None, entered: Some(Setup), allow_same_state_transitions: false})",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_state(app.world(), TestSubState::Setup),
    content="Some({value: Setup})",
  )

  app.run_once() |> ignore
  debug_inspect(world_state(app.world(), TestSubState::Setup), content="None")
  debug_inspect(
    last_transition(app.world(), TestSubState::Setup),
    content="Some({exited: Some(Setup), entered: None, allow_same_state_transitions: false})",
  )
}

///|
test "app sub state: queued next state mutates while parent still exists" {
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_sub_state(
      TestState::A,
      TestSubState::Setup,
      test_sub_state_should_exist,
    )
    .add_system(fn(world : @ecs.World) {
      match world_state(world, TestSubState::Setup) {
        Some(current) =>
          if current.get() == TestSubState::Setup {
            set_state(TestSubState::Battle)
          }
        None => ()
      }
    })

  app.run_startup() |> ignore
  debug_inspect(
    world_state(app.world(), TestSubState::Setup),
    content="Some({value: Setup})",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_next_state(app.world(), TestSubState::Setup),
    content="Some(Pending(Battle))",
  )
  debug_inspect(
    world_state(app.world(), TestSubState::Setup),
    content="Some({value: Setup})",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_state(app.world(), TestSubState::Setup),
    content="Some({value: Battle})",
  )
  debug_inspect(
    last_transition(app.world(), TestSubState::Setup),
    content="Some({exited: Some(Setup), entered: Some(Battle), allow_same_state_transitions: true})",
  )
}
