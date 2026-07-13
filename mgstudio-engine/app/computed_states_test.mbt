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
} derive(Eq, Debug)

///|
pub(all) enum PairState {
  Disabled
  Enabled
} derive(Eq, Debug)

///|
pub(all) enum OptionalParentState {
  Disabled
  Enabled
} derive(Eq, Debug)

///|
pub(all) enum OptionalChildState {
  Present
} derive(Eq, Debug)

///|
pub(all) enum MultiSourceDerivedState {
  Ready
} derive(Eq, Debug)

///|
pub(all) enum OptionalDerivedState {
  Missing
  Present
} derive(Eq, Debug)

///|
impl States for DerivedState with fn type_debug_name() {
  "DerivedState"
}

///|
impl States for DerivedState with fn debug_name(self) {
  ignore(self)
  "DerivedState"
}

///|
let derived_state_resource_keys : StateResourceKeys[DerivedState] = register_state_resource_keys(
  "DerivedState",
)

///|
impl States for DerivedState with fn state_resource_keys() {
  derived_state_resource_keys
}

///|
impl States for PairState with fn type_debug_name() {
  "PairState"
}

///|
impl States for PairState with fn debug_name(self) {
  ignore(self)
  "PairState"
}

///|
let pair_state_resource_keys : StateResourceKeys[PairState] = register_state_resource_keys(
  "PairState",
)

///|
impl States for PairState with fn state_resource_keys() {
  pair_state_resource_keys
}

///|
impl States for OptionalParentState with fn type_debug_name() {
  "OptionalParentState"
}

///|
impl States for OptionalParentState with fn debug_name(self) {
  ignore(self)
  "OptionalParentState"
}

///|
let optional_parent_state_resource_keys : StateResourceKeys[OptionalParentState] = register_state_resource_keys(
  "OptionalParentState",
)

///|
impl States for OptionalParentState with fn state_resource_keys() {
  optional_parent_state_resource_keys
}

///|
impl States for OptionalChildState with fn type_debug_name() {
  "OptionalChildState"
}

///|
impl States for OptionalChildState with fn debug_name(self) {
  ignore(self)
  "OptionalChildState"
}

///|
let optional_child_state_resource_keys : StateResourceKeys[OptionalChildState] = register_state_resource_keys(
  "OptionalChildState",
)

///|
impl States for OptionalChildState with fn state_resource_keys() {
  optional_child_state_resource_keys
}

///|
impl FreelyMutableState for OptionalChildState

///|
impl SubStates for OptionalChildState

///|
impl States for MultiSourceDerivedState with fn type_debug_name() {
  "MultiSourceDerivedState"
}

///|
impl States for MultiSourceDerivedState with fn debug_name(self) {
  ignore(self)
  "MultiSourceDerivedState"
}

///|
let multi_source_derived_state_resource_keys : StateResourceKeys[
  MultiSourceDerivedState,
] = register_state_resource_keys("MultiSourceDerivedState")

///|
impl States for MultiSourceDerivedState with fn state_resource_keys() {
  multi_source_derived_state_resource_keys
}

///|
impl States for OptionalDerivedState with fn type_debug_name() {
  "OptionalDerivedState"
}

///|
impl States for OptionalDerivedState with fn debug_name(self) {
  ignore(self)
  "OptionalDerivedState"
}

///|
let optional_derived_state_resource_keys : StateResourceKeys[
  OptionalDerivedState,
] = register_state_resource_keys("OptionalDerivedState")

///|
impl States for OptionalDerivedState with fn state_resource_keys() {
  optional_derived_state_resource_keys
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
  let lifecycle_world_221_0 = @ecs.World::new()
  defer lifecycle_world_221_0.close()
  let app = App::new(lifecycle_world_221_0)
    .add_plugins(@app.StatesPlugin::StatesPlugin())
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
  debug_inspect(
    world_state(app.world(), DerivedState::Active),
    content="Some({ value: Active })",
  )
  debug_inspect(
    last_transition(app.world(), DerivedState::Active),
    content="Some(\n  {\n    exited: None,\n    entered: Some(Active),\n    allow_same_state_transitions: true,\n  },\n)",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_state(app.world(), DerivedState::Active),
    content="Some({ value: Active })",
  )

  app.run_once() |> ignore
  debug_inspect(world_state(app.world(), DerivedState::Active), content="None")
  debug_inspect(
    last_transition(app.world(), DerivedState::Active),
    content="Some(\n  {\n    exited: Some(Active),\n    entered: None,\n    allow_same_state_transitions: true,\n  },\n)",
  )
}

///|
test "app computed state: supports two source states" {
  let lifecycle_world_261_0 = @ecs.World::new()
  defer lifecycle_world_261_0.close()
  let app = App::new(lifecycle_world_261_0)
    .add_plugins(@app.StatesPlugin::StatesPlugin())
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
  debug_inspect(
    world_state(app.world(), MultiSourceDerivedState::Ready),
    content="None",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_next_state(app.world(), PairState::Disabled),
    content="Some(Pending(Enabled))",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_state(app.world(), MultiSourceDerivedState::Ready),
    content="Some({ value: Ready })",
  )
}

///|
test "app computed state: supports optional source states" {
  let lifecycle_world_298_0 = @ecs.World::new()
  defer lifecycle_world_298_0.close()
  let app = App::new(lifecycle_world_298_0)
    .add_plugins(@app.StatesPlugin::StatesPlugin())
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
  debug_inspect(
    world_state(app.world(), OptionalDerivedState::Missing),
    content="Some({ value: Missing })",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_next_state(app.world(), OptionalParentState::Disabled),
    content="Some(Pending(Enabled))",
  )

  app.run_once() |> ignore
  debug_inspect(
    world_state(app.world(), OptionalDerivedState::Missing),
    content="Some({ value: Present })",
  )
}
