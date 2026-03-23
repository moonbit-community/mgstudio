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
pub(all) enum PairState {
  Disabled
  Enabled
} derive(Eq, Show)

///|
pub(all) enum OptionalParentState {
  Disabled
  Enabled
} derive(Eq, Show)

///|
pub(all) enum OptionalChildState {
  Present
} derive(Eq, Show)

///|
pub(all) enum MultiSourceDerivedState {
  Ready
} derive(Eq, Show)

///|
pub(all) enum OptionalDerivedState {
  Missing
  Present
} derive(Eq, Show)

///|
impl States for DerivedState with debug_name(self) {
  ignore(self)
  "DerivedState"
}

///|
impl States for PairState with debug_name(self) {
  ignore(self)
  "PairState"
}

///|
impl States for OptionalParentState with debug_name(self) {
  ignore(self)
  "OptionalParentState"
}

///|
impl States for OptionalChildState with debug_name(self) {
  ignore(self)
  "OptionalChildState"
}

///|
impl FreelyMutableState for OptionalChildState

///|
impl SubStates for OptionalChildState

///|
impl States for MultiSourceDerivedState with debug_name(self) {
  ignore(self)
  "MultiSourceDerivedState"
}

///|
impl States for OptionalDerivedState with debug_name(self) {
  ignore(self)
  "OptionalDerivedState"
}

///|
fn compute_derived_state(source : TestState) -> DerivedState? {
  match source {
    TestState::A => Some(DerivedState::Active)
    TestState::B => None
  }
}

///|
fn compute_pair_state(
  inputs : (TestState, PairState),
) -> MultiSourceDerivedState? {
  match inputs {
    (TestState::A, PairState::Enabled) => Some(MultiSourceDerivedState::Ready)
    _ => None
  }
}

///|
fn optional_child_should_exist(
  source : OptionalParentState,
) -> OptionalChildState? {
  match source {
    OptionalParentState::Enabled => Some(OptionalChildState::Present)
    OptionalParentState::Disabled => None
  }
}

///|
fn compute_optional_state(
  inputs : (TestState, PairState, OptionalChildState?),
) -> OptionalDerivedState? {
  match inputs {
    (TestState::A, PairState::Enabled, Some(OptionalChildState::Present)) =>
      Some(OptionalDerivedState::Present)
    (TestState::A, PairState::Enabled, None) =>
      Some(OptionalDerivedState::Missing)
    _ => None
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

///|
test "app computed state: supports two source states" {
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .insert_state(PairState::Disabled)
    .add_computed_state2(
      TestState::A,
      PairState::Disabled,
      MultiSourceDerivedState::Ready,
      compute_pair_state,
    )
    .add_system_config(
      system(fn(_world : @ecs.World) { set_state(PairState::Enabled) }).run_if(
        in_state(PairState::Disabled),
      ),
    )

  app.run_startup() |> ignore
  inspect(
    world_state(app.world(), MultiSourceDerivedState::Ready),
    content="None",
  )

  app.run_once() |> ignore
  inspect(
    world_next_state(app.world(), PairState::Disabled),
    content="Some(Pending(Enabled))",
  )

  app.run_once() |> ignore
  inspect(
    world_state(app.world(), MultiSourceDerivedState::Ready),
    content="Some({value: Ready})",
  )
}

///|
test "app computed state: supports optional source states" {
  let app = App::new(@ecs.World::new())
    .add_plugins([states_plugin(StatesPlugin::default())])
    .insert_state(TestState::A)
    .insert_state(PairState::Enabled)
    .insert_state(OptionalParentState::Disabled)
    .add_sub_state(
      OptionalParentState::Enabled,
      OptionalChildState::Present,
      optional_child_should_exist,
    )
    .add_computed_state3_optional(
      TestState::A,
      PairState::Enabled,
      optional_state(OptionalChildState::Present),
      OptionalDerivedState::Missing,
      compute_optional_state,
    )
    .add_system_config(
      system(fn(_world : @ecs.World) { set_state(OptionalParentState::Enabled) }).run_if(
        in_state(OptionalParentState::Disabled),
      ),
    )

  app.run_startup() |> ignore
  inspect(
    world_state(app.world(), OptionalDerivedState::Missing),
    content="Some({value: Missing})",
  )

  app.run_once() |> ignore
  inspect(
    world_next_state(app.world(), OptionalParentState::Disabled),
    content="Some(Pending(Enabled))",
  )

  app.run_once() |> ignore
  inspect(
    world_state(app.world(), OptionalDerivedState::Missing),
    content="Some({value: Present})",
  )
}
