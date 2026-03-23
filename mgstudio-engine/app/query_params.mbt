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
pub impl FromWorld for @ecs.All with from_world(_world) {
  @ecs.All::new()
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.With[T] with from_world(_world) {
  @ecs.With::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Without[T] with from_world(
  _world,
) {
  @ecs.Without::new(@ecs.Component::component())
}

///|
pub impl[F : FromWorld] FromWorld for @ecs.Or[F] with from_world(world) {
  @ecs.Or::new(F::from_world(world))
}

///|
pub impl[A : FromWorld, B : FromWorld] FromWorld for (A, B) with from_world(
  world,
) {
  (A::from_world(world), B::from_world(world))
}

///|
pub impl[A : FromWorld, B : FromWorld, C : FromWorld] FromWorld for (A, B, C) with from_world(
  world,
) {
  (A::from_world(world), B::from_world(world), C::from_world(world))
}

///|
pub impl[F : FromWorld] SystemParam for @ecs.EntityQuery[F] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[F : FromWorld] SystemParam for @ecs.EntityQuery[F] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query_entities_filtered(F::from_world(world))
}

///|
pub impl[F : FromWorld] SystemParam for @ecs.EntityQuery[F] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[A : @ecs.Component] SystemParam for @ecs.Query1[A] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component] SystemParam for @ecs.Query1[A] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query1(@ecs.Component::component())
}

///|
pub impl[A : @ecs.Component] SystemParam for @ecs.Query1[A] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[A : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query1Filtered[
  A,
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query1Filtered[
  A,
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query1_filtered(@ecs.Component::component(), F::from_world(world))
}

///|
pub impl[A : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query1Filtered[
  A,
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for @ecs.Query2[
  A,
  B,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for @ecs.Query2[
  A,
  B,
] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query2(@ecs.Component::component(), @ecs.Component::component())
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for @ecs.Query2[
  A,
  B,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2Filtered[
  A,
  B,
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2Filtered[
  A,
  B,
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query2_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    F::from_world(world),
  )
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2Filtered[
  A,
  B,
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, C : @ecs.Component] SystemParam for @ecs.Query3[
  A,
  B,
  C,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, C : @ecs.Component] SystemParam for @ecs.Query3[
  A,
  B,
  C,
] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query3(
    @ecs.Component::component(),
    @ecs.Component::component(),
    @ecs.Component::component(),
  )
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, C : @ecs.Component] SystemParam for @ecs.Query3[
  A,
  B,
  C,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3Filtered[A, B, C, F] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3Filtered[A, B, C, F] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query3_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    @ecs.Component::component(),
    F::from_world(world),
  )
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3Filtered[A, B, C, F] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2RefMutFiltered[
  A,
  B,
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2RefMutFiltered[
  A,
  B,
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query2_ref_mut_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    F::from_world(world),
  )
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2RefMutFiltered[
  A,
  B,
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2ValueMutFiltered[
  A,
  B,
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2ValueMutFiltered[
  A,
  B,
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query2_value_mut_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    F::from_world(world),
  )
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, F : FromWorld] SystemParam for @ecs.Query2ValueMutFiltered[
  A,
  B,
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3ValueRefMutFiltered[A, B, C, F] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3ValueRefMutFiltered[A, B, C, F] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query3_value_ref_mut_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    @ecs.Component::component(),
    F::from_world(world),
  )
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3ValueRefMutFiltered[A, B, C, F] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3RefMutOptionalFiltered[A, B, C, F] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3RefMutOptionalFiltered[A, B, C, F] with get(_state) {
  let world = system_param_abort_missing_world()
  world.query3_ref_mut_optional_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    @ecs.Component::component(),
    F::from_world(world),
  )
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  F : FromWorld,
] SystemParam for @ecs.Query3RefMutOptionalFiltered[A, B, C, F] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}
