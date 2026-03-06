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
pub(all) enum TestState {
  A
  B
} derive(Eq, Show, ToJson, FromJson)

///|
impl States for TestState with debug_name(self) {
  ignore(self)
  "TestState"
}

///|
fn read_test_state(world : @ecs.World) -> TestState? {
  match world_state(world, TestState::A) {
    Some(state) => Some(state.get())
    None => None
  }
}

///|
fn current_stage_label() -> String {
  match current_schedule_stage() {
    Some(StateTransition) => "StateTransition"
    Some(Startup) => "Startup"
    Some(PreUpdate) => "PreUpdate"
    Some(FixedUpdate) => "FixedUpdate"
    Some(Update) => "Update"
    Some(PostUpdate) => "PostUpdate"
    Some(Last) => "Last"
    None => "None"
  }
}

///|
test "app state: queued next state applies on next frame after PreUpdate" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_system_config(
      system(fn(_world : @ecs.World) {
        log.push("A")
        set_state(TestState::B)
      }).run_if(in_state(TestState::A)),
    )
    .add_system_config(
      system(fn(_world : @ecs.World) { log.push("B") }).run_if(
        in_state(TestState::B),
      ),
    )

  app.run_once() |> ignore
  inspect(log.join(","), content="A")
  inspect(read_test_state(app.world), content="Some(A)")
  inspect(world_next_state(app.world, TestState::A), content="Some(Pending(B))")

  app.run_once() |> ignore
  inspect(log.join(","), content="A,B")
  inspect(read_test_state(app.world), content="Some(B)")
  inspect(
    world_previous_state(app.world, TestState::A),
    content="Some({value: A})",
  )
}

///|
test "app state: exit transition enter hooks run in bevy order" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_system_config(
      system(fn(_world : @ecs.World) { set_state(TestState::B) }).run_if(
        in_state(TestState::A),
      ),
    )
    .add_on_exit_system(TestState::A, fn(_world : @ecs.World) {
      log.push("exit@" + current_stage_label())
    })
    .add_on_transition_system(TestState::A, TestState::B, fn(
      _world : @ecs.World,
    ) {
      log.push("transition@" + current_stage_label())
    })
    .add_on_enter_system(TestState::B, fn(_world : @ecs.World) {
      log.push("enter@" + current_stage_label())
    })

  app.run_once() |> ignore
  inspect(log.length(), content="0")

  app.run_once() |> ignore
  inspect(
    log.join(","),
    content="exit@StateTransition,transition@StateTransition,enter@StateTransition",
  )
  inspect(
    last_transition(app.world, TestState::A),
    content="Some({exited: Some(A), entered: Some(B), allow_same_state_transitions: true})",
  )
}

///|
test "app state: startup enter hook runs in state transition stage" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_on_enter_system(TestState::A, fn(_world : @ecs.World) {
      log.push("enter@" + current_stage_label())
    })

  app.run_startup() |> ignore
  inspect(log.join(","), content="enter@StateTransition")
  inspect(
    last_transition(app.world, TestState::A),
    content="Some({exited: None, entered: Some(A), allow_same_state_transitions: true})",
  )
}

///|
test "app state: state_changed matches bevy resource change detection" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .add_system_config(
      system(fn(world : @ecs.World) {
        match read_test_state(world) {
          Some(A) => log.push("A")
          Some(B) => log.push("B")
          None => log.push("None")
        }
      }).run_if(state_changed(TestState::A)),
    )

  app.run_once() |> ignore
  inspect(log.join(","), content="A")

  app.run_once() |> ignore
  inspect(log.join(","), content="A")

  app.insert_state(TestState::B) |> ignore
  app.run_once() |> ignore
  inspect(log.join(","), content="A,B")

  app.run_once() |> ignore
  inspect(log.join(","), content="A,B")
}
