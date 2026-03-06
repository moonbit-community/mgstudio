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
test "app state: queued next state applies on next frame after PreUpdate" {
  let log : Array[String] = []
  let app = insert_state_app(App::new(@ecs.World::new()), TestState::A)
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
