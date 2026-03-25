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
type ObserverRunner = (@ecs.World) -> Unit

///|
type SubAppObserverRegistrar = (SubApp[@ecs.World], ObserverRunner) -> SubApp[
  @ecs.World,
]

///|
type EntityObserverRegistrar = (@ecs.World, @core.Entity, ObserverRunner) -> Unit

///|
pub fn run_registered_observer_system(
  world : @ecs.World,
  last_run_sequence_ref : Ref[@core.Sequence],
  observer_system : SystemFn[@ecs.World],
  context_kind? : ErrorContextKind = ErrorContextKind::Observer,
  source? : String = "<observer>",
) -> Unit {
  let this_run = world.advance_sequence()
  let sys_ticks = @core.SystemSequence::new(last_run_sequence_ref.val, this_run)
  let ctx = world.get_sequence_context()
  ctx.set(sys_ticks)
  world.set_sequence_context(ctx)
  let previous_world = current_world_ref.val
  let previous_sequence = current_system_sequence_ref.val
  let previous_outcome = current_system_execution_outcome()
  current_world_ref.val = Some(world)
  current_system_sequence_ref.val = Some(sys_ticks)
  reset_system_execution_outcome()
  observer_system(world)
  let outcome = current_system_execution_outcome()
  current_system_execution_outcome_ref.val = previous_outcome
  current_system_sequence_ref.val = previous_sequence
  current_world_ref.val = previous_world
  match outcome {
    Success => last_run_sequence_ref.val = this_run
    Skipped(_) => ()
    Invalid(message) =>
      report_world_error(
        world,
        @ecs.Invalid(message),
        ErrorContext::new(
          ErrorContextKind::Validation,
          source,
          stage=current_schedule_stage(),
        ),
      )
    Error(err) => {
      last_run_sequence_ref.val = this_run
      report_world_error(
        world,
        err,
        ErrorContext::new(context_kind, source, stage=current_schedule_stage()),
      )
    }
  }
}

///|
fn register_observer_system_in_sub_app(
  sub_app : SubApp[@ecs.World],
  source : String,
  register : SubAppObserverRegistrar,
  system : SystemFn[@ecs.World],
) -> SubApp[@ecs.World] {
  let observer_system = system
  let last_run_sequence_ref : Ref[@core.Sequence] = Ref::new(0)
  register(sub_app, fn(world : @ecs.World) {
    run_registered_observer_system(
      world,
      last_run_sequence_ref,
      observer_system,
      source~,
    )
  })
}

///|
fn register_entity_observer_command(
  entity_commands : EntityCommands,
  source : String,
  register : EntityObserverRegistrar,
  system : SystemFn[@ecs.World],
) -> EntityCommands {
  let entity = entity_commands.entity
  entity_commands.commands.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) raise {
      guard world.is_alive(entity) else { return }
      let observer_system = system
      let last_run_sequence_ref : Ref[@core.Sequence] = Ref::new(0)
      register(world, entity, fn(observer_world : @ecs.World) {
        run_registered_observer_system(
          observer_world,
          last_run_sequence_ref,
          observer_system,
          source~,
        )
      })
    },
    error_handler: None,
    source,
  })
  entity_commands
}

///|
pub impl[E : @ecs.TriggerEvent] SystemParam for @ecs.On[E] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[E : @ecs.TriggerEvent] SystemParam for @ecs.On[E] with get(_state) {
  @ecs.current_observer()
}

///|
pub impl[E : @ecs.TriggerEvent] SystemParam for @ecs.On[E] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub impl[E : @ecs.ComponentObserverEvent, C : @ecs.Component] SystemParam for @ecs.ComponentOn[
  E,
  C,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[E : @ecs.ComponentObserverEvent, C : @ecs.Component] SystemParam for @ecs.ComponentOn[
  E,
  C,
] with get(_state) {
  @ecs.current_component_observer()
}

///|
pub impl[E : @ecs.ComponentObserverEvent, C : @ecs.Component] SystemParam for @ecs.ComponentOn[
  E,
  C,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub fn[E : @ecs.TriggerEvent] SubApp::add_observer(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E]) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent] App::add_observer(
  self : App[@ecs.World],
  observer : (@ecs.On[E]) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer(observer)
  self
}

///|
pub fn[E : @ecs.TriggerEvent] SubApp::add_observer_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E]) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent] App::add_observer_fallible(
  self : App[@ecs.World],
  observer : (@ecs.On[E]) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer_fallible(observer)
  self
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam] SubApp::add_observer2(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E], P2) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param2(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam] App::add_observer2(
  self : App[@ecs.World],
  observer : (@ecs.On[E], P2) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer2(observer)
  self
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam] SubApp::add_observer2_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E], P2) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param2(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam] App::add_observer2_fallible(
  self : App[@ecs.World],
  observer : (@ecs.On[E], P2) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer2_fallible(observer)
  self
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam, P3 : SystemParam] SubApp::add_observer3(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E], P2, P3) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param3(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam, P3 : SystemParam] App::add_observer3(
  self : App[@ecs.World],
  observer : (@ecs.On[E], P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer3(observer)
  self
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam, P3 : SystemParam] SubApp::add_observer3_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E], P2, P3) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param3(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam, P3 : SystemParam] App::add_observer3_fallible(
  self : App[@ecs.World],
  observer : (@ecs.On[E], P2, P3) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer3_fallible(observer)
  self
}

///|
pub fn[
  E : @ecs.TriggerEvent,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] SubApp::add_observer4(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E], P2, P3, P4) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param4(observer),
  )
}

///|
pub fn[
  E : @ecs.TriggerEvent,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_observer4(
  self : App[@ecs.World],
  observer : (@ecs.On[E], P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer4(observer)
  self
}

///|
pub fn[
  E : @ecs.TriggerEvent,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] SubApp::add_observer4_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.On[E], P2, P3, P4) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_observer(fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param4(observer),
  )
}

///|
pub fn[
  E : @ecs.TriggerEvent,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_observer4_fallible(
  self : App[@ecs.World],
  observer : (@ecs.On[E], P2, P3, P4) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_observer4_fallible(observer)
  self
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component] SubApp::add_component_observer(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C]) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param(observer),
  )
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component] App::add_component_observer(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C]) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer(observer)
  self
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component] SubApp::add_component_observer_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C]) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param(observer),
  )
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component] App::add_component_observer_fallible(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C]) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer_fallible(
    observer,
  )
  self
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component, P2 : SystemParam] SubApp::add_component_observer2(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param2(observer),
  )
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component, P2 : SystemParam] App::add_component_observer2(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer2(observer)
  self
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component, P2 : SystemParam] SubApp::add_component_observer2_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param2(observer),
  )
}

///|
pub fn[E : @ecs.ComponentObserverEvent, C : @ecs.Component, P2 : SystemParam] App::add_component_observer2_fallible(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer2_fallible(
    observer,
  )
  self
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
] SubApp::add_component_observer3(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param3(observer),
  )
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
] App::add_component_observer3(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer3(observer)
  self
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
] SubApp::add_component_observer3_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param3(observer),
  )
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
] App::add_component_observer3_fallible(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer3_fallible(
    observer,
  )
  self
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] SubApp::add_component_observer4(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3, P4) -> Unit,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    system_param4(observer),
  )
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_component_observer4(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3, P4) -> Unit,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer4(observer)
  self
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] SubApp::add_component_observer4_fallible(
  self : SubApp[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3, P4) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_observer_system_in_sub_app(
    self,
    "<component-observer>",
    fn(sub_app, run) {
      ignore(
        sub_app
        .world()
        .add_component_observer(fn(_event : @ecs.ComponentOn[E, C]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
      sub_app
    },
    fallible_system_param4(observer),
  )
}

///|
pub fn[
  E : @ecs.ComponentObserverEvent,
  C : @ecs.Component,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_component_observer4_fallible(
  self : App[@ecs.World],
  observer : (@ecs.ComponentOn[E, C], P2, P3, P4) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_component_observer4_fallible(
    observer,
  )
  self
}

///|
pub fn[E : @ecs.TriggerEvent] EntityCommands::observe(
  self : EntityCommands,
  observer : (@ecs.On[E]) -> Unit raise,
) -> EntityCommands {
  register_entity_observer_command(
    self,
    "EntityCommands::observe",
    fn(world, entity, run) {
      ignore(
        world.add_entity_observer(entity, fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
    },
    fallible_system_param(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam] EntityCommands::observe2(
  self : EntityCommands,
  observer : (@ecs.On[E], P2) -> Unit raise,
) -> EntityCommands {
  register_entity_observer_command(
    self,
    "EntityCommands::observe2",
    fn(world, entity, run) {
      ignore(
        world.add_entity_observer(entity, fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
    },
    fallible_system_param2(observer),
  )
}

///|
pub fn[E : @ecs.TriggerEvent, P2 : SystemParam, P3 : SystemParam] EntityCommands::observe3(
  self : EntityCommands,
  observer : (@ecs.On[E], P2, P3) -> Unit raise,
) -> EntityCommands {
  register_entity_observer_command(
    self,
    "EntityCommands::observe3",
    fn(world, entity, run) {
      ignore(
        world.add_entity_observer(entity, fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
    },
    fallible_system_param3(observer),
  )
}

///|
pub fn[
  E : @ecs.TriggerEvent,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] EntityCommands::observe4(
  self : EntityCommands,
  observer : (@ecs.On[E], P2, P3, P4) -> Unit raise,
) -> EntityCommands {
  register_entity_observer_command(
    self,
    "EntityCommands::observe4",
    fn(world, entity, run) {
      ignore(
        world.add_entity_observer(entity, fn(_event : @ecs.On[E]) {
          run(@ecs.current_observer_world_abort_missing())
        }),
      )
    },
    fallible_system_param4(observer),
  )
}
