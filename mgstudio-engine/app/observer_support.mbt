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
fn run_registered_observer_system(
  world : @ecs.World,
  last_run_sequence_ref : Ref[@core.Sequence],
  observer_system : SystemFn[@ecs.World],
) -> Unit {
  let this_run = world.advance_sequence()
  let sys_ticks = @core.SystemSequence::new(last_run_sequence_ref.val, this_run)
  ignore(sys_ticks)
  let ctx = world.get_sequence_context()
  ctx.set(sys_ticks)
  world.set_sequence_context(ctx)
  let previous_world = current_world_ref.val
  let previous_sequence = current_system_sequence_ref.val
  current_world_ref.val = Some(world)
  current_system_sequence_ref.val = Some(sys_ticks)
  observer_system(world)
  current_system_sequence_ref.val = previous_sequence
  current_world_ref.val = previous_world
  last_run_sequence_ref.val = this_run
}

///|
pub impl[E : @ecs.ObserverEvent, C : @ecs.Component] SystemParam for @ecs.On[
  E,
  C,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[E : @ecs.ObserverEvent, C : @ecs.Component] SystemParam for @ecs.On[
  E,
  C,
] with get(_state) {
  let event : @ecs.On[E, C] = @ecs.current_observer()
  event
}

///|
pub impl[E : @ecs.ObserverEvent, C : @ecs.Component] SystemParam for @ecs.On[
  E,
  C,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub fn[E : @ecs.ObserverEvent, C : @ecs.Component] SubApp::add_observer(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E, C]) -> Unit,
) -> SubApp[@ecs.World] {
  let observer_system = system_param(observer)
  let last_run_sequence_ref : Ref[@core.Sequence] = Ref::new(0)
  ignore(
    self
    .world()
    .add_observer(fn(_event : @ecs.On[E, C]) {
      run_registered_observer_system(
        @ecs.current_observer_world_abort_missing(),
        last_run_sequence_ref,
        observer_system,
      )
    }),
  )
  self
}

///|
pub fn[E : @ecs.ObserverEvent, C : @ecs.Component] App::add_observer(
  self : App[@ecs.World],
  observer : (@ecs.On[E, C]) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer(observer)
  self
}

///|
pub fn[E : @ecs.ObserverEvent, C : @ecs.Component, P2 : SystemParam] SubApp::add_observer2(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E, C], P2) -> Unit,
) -> SubApp[@ecs.World] {
  let observer_system = system_param2(observer)
  let last_run_sequence_ref : Ref[@core.Sequence] = Ref::new(0)
  ignore(
    self
    .world()
    .add_observer(fn(_event : @ecs.On[E, C]) {
      run_registered_observer_system(
        @ecs.current_observer_world_abort_missing(),
        last_run_sequence_ref,
        observer_system,
      )
    }),
  )
  self
}

///|
pub fn[E : @ecs.ObserverEvent, C : @ecs.Component, P2 : SystemParam] App::add_observer2(
  self : App[@ecs.World],
  observer : (@ecs.On[E, C], P2) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer2(observer)
  self
}

///|
pub fn[
  E : @ecs.ObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
] SubApp::add_observer3(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E, C], P2, P3) -> Unit,
) -> SubApp[@ecs.World] {
  let observer_system = system_param3(observer)
  let last_run_sequence_ref : Ref[@core.Sequence] = Ref::new(0)
  ignore(
    self
    .world()
    .add_observer(fn(_event : @ecs.On[E, C]) {
      run_registered_observer_system(
        @ecs.current_observer_world_abort_missing(),
        last_run_sequence_ref,
        observer_system,
      )
    }),
  )
  self
}

///|
pub fn[
  E : @ecs.ObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
] App::add_observer3(
  self : App[@ecs.World],
  observer : (@ecs.On[E, C], P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer3(observer)
  self
}

///|
pub fn[
  E : @ecs.ObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] SubApp::add_observer4(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E, C], P2, P3, P4) -> Unit,
) -> SubApp[@ecs.World] {
  let observer_system = system_param4(observer)
  let last_run_sequence_ref : Ref[@core.Sequence] = Ref::new(0)
  ignore(
    self
    .world()
    .add_observer(fn(_event : @ecs.On[E, C]) {
      run_registered_observer_system(
        @ecs.current_observer_world_abort_missing(),
        last_run_sequence_ref,
        observer_system,
      )
    }),
  )
  self
}

///|
pub fn[
  E : @ecs.ObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_observer4(
  self : App[@ecs.World],
  observer : (@ecs.On[E, C], P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer4(observer)
  self
}
