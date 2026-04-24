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
fn run_systems(
  world : @ecs.World,
  schedule : SystemSchedule[@ecs.World],
  execution_batches : Array[Array[ScheduleExecutionNode]],
  stage : ScheduleStage?,
  executor_kind? : ExecutorKind = SingleThreaded,
  apply_final_deferred? : Bool = true,
  executor_state_ref? : Ref[SingleThreadedExecutorState]? = None,
) -> Unit {
  let systems = schedule.systems
  let system_conditions = schedule.system_conditions
  let execution_order = schedule.execution_order
  let system_accesses = schedule.system_accesses
  let set_ids = schedule.set_ids
  let set_run_conditions = schedule.set_run_conditions
  let sets_with_conditions_of_systems = schedule.sets_with_conditions_of_systems
  let systems_in_sets_with_conditions = schedule.systems_in_sets_with_conditions
  let timeline_enabled = timeline_trace_enabled()
  current_system_sequence_ref.val = None
  current_world_ref.val = None
  let stepping_ref = stepping_resource_mut(world)
  stepping_prepare_stage(stepping_ref, stage, systems, execution_order)
  fn system_default_trace_name(
    cfg : SystemConfig[@ecs.World],
    stage : ScheduleStage?,
    fallback_index : Int,
  ) -> String {
    match cfg.debug_name {
      Some(debug_name) => "\{debug_name}#\{fallback_index.to_string()}"
      None =>
        match stage {
          Some(stage_name) =>
            "\{to_repr(stage_name).to_string()}::__system#\{fallback_index.to_string()}"
          None => "__system#\{fallback_index.to_string()}"
        }
    }
  }
  fn system_trace_name(
    cfg : SystemConfig[@ecs.World],
    stage : ScheduleStage?,
    fallback_index : Int,
  ) -> String {
    match cfg.name {
      Some(name) => name
      None =>
        match cfg.set {
          Some(set) =>
            if set.has_prefix("__chain__:") {
              system_default_trace_name(cfg, stage, fallback_index)
            } else {
              "\{set}::\{system_default_trace_name(cfg, stage, fallback_index)}"
            }
          None => system_default_trace_name(cfg, stage, fallback_index)
        }
    }
  }
  fn should_trace_system(
    cfg : SystemConfig[@ecs.World],
    stage : ScheduleStage?,
    system_count : Int,
  ) -> Bool {
    match stage {
      Some(Main) => !(system_count == 1 && cfg.name is None && cfg.set is None)
      _ => true
    }
  }
  fn system_validation_error(system_i : Int) -> String? {
    if system_i >= 0 && system_i < system_accesses.length() {
      system_accesses[system_i].validation_error()
    } else {
      None
    }
  }
  begin_deferred_command_batch()
  let executor_state = match executor_state_ref {
    Some(state_ref) => {
      state_ref.val.prepare_run(
        systems.length(),
        set_ids.length(),
        apply_final_deferred,
      )
      state_ref.val
    }
    None =>
      single_threaded_executor_state_new(
        systems.length(),
        set_ids.length(),
        apply_final_deferred,
      )
  }
  let set_run_if_results : Array[Bool] = []
  for _ in 0..<set_ids.length() {
    set_run_if_results.push(true)
  }
  fn evaluate_set_run_if_once(set_i : Int) -> Bool {
    if set_i < 0 || set_i >= set_run_conditions.length() {
      return true
    }
    if set_i < executor_state.evaluated_sets.length() &&
      executor_state.evaluated_sets[set_i] {
      return set_run_if_results[set_i]
    }
    let run_conditions_ref = set_run_conditions[set_i]
    let mut matches = true
    for cond_i in 0..<run_conditions_ref.val.run_ifs.length() {
      let cond = run_conditions_ref.val.run_ifs[cond_i]
      let cond_this_run = world.advance_sequence()
      let cond_ticks = @core.SystemSequence::new(
        run_conditions_ref.val.run_if_last_run_sequences[cond_i],
        cond_this_run,
      )
      let cond_ctx = world.get_sequence_context()
      cond_ctx.set(cond_ticks)
      world.set_sequence_context(cond_ctx)
      let prev_world = current_world_ref.val
      current_world_ref.val = Some(world)
      current_system_sequence_ref.val = Some(cond_ticks)
      let cond_result = cond(
        world,
        run_conditions_ref.val.run_if_states[cond_i],
      )
      current_system_sequence_ref.val = None
      current_world_ref.val = prev_world
      run_conditions_ref.val.run_if_last_run_sequences[cond_i] = cond_this_run
      matches = matches && cond_result
    }
    set_run_if_results[set_i] = matches
    if !matches && set_i < systems_in_sets_with_conditions.length() {
      for skip_system_i in systems_in_sets_with_conditions[set_i] {
        executor_state.mark_completed(skip_system_i)
      }
    }
    if set_i < executor_state.evaluated_sets.length() {
      executor_state.evaluated_sets[set_i] = true
    }
    matches
  }
  fn run_execution_node(node : ScheduleExecutionNode, execution_i : Int) -> Unit {
    if !stepping_should_run_system(
        stepping_ref, stage, systems, node, execution_i,
      ) {
      return
    }
    match node {
      ScheduledSystem(system_i) => {
        if executor_state.is_completed(system_i) {
          return
        }
        let cfg = systems[system_i]
        let mut should_run_system = true
        if system_i >= 0 &&
          system_i < sets_with_conditions_of_systems.length() {
          for set_i in sets_with_conditions_of_systems[system_i] {
            if set_i >= 0 && set_i < set_ids.length() {
              let set_conditions_met = evaluate_set_run_if_once(set_i)
              should_run_system = should_run_system && set_conditions_met
            }
          }
        }
        if system_i >= 0 && system_i < system_conditions.length() {
          let conditions = system_conditions[system_i]
          for cond_i in 0..<conditions.run_ifs.length() {
            let cond = conditions.run_ifs[cond_i]
            let cond_this_run = world.advance_sequence()
            let cond_ticks = @core.SystemSequence::new(
              conditions.run_if_last_run_sequences[cond_i],
              cond_this_run,
            )
            let cond_ctx = world.get_sequence_context()
            cond_ctx.set(cond_ticks)
            world.set_sequence_context(cond_ctx)
            let prev_world = current_world_ref.val
            current_world_ref.val = Some(world)
            current_system_sequence_ref.val = Some(cond_ticks)
            let should_run = cond(world, conditions.run_if_states[cond_i])
            current_system_sequence_ref.val = None
            current_world_ref.val = prev_world
            conditions.run_if_last_run_sequences[cond_i] = cond_this_run
            should_run_system = should_run_system && should_run
          }
        }
          executor_state.mark_completed(system_i)
          if !should_run_system {
            return
          }
          match system_validation_error(system_i) {
            Some(message) => {
              report_world_error(
                world,
                @ecs.Invalid(message),
                system_context(
                  systems[system_i],
                  ErrorContextKind::Validation,
                  current_schedule_stage(),
                ),
              )
              return
            }
            None => ()
          }
          if cfg.is_apply_deferred_node {
            executor_state.apply_deferred(world)
            stepping_record_system_run(
              stepping_ref, stage, systems, node, execution_i,
            )
            return
          }

          let trace_name = system_trace_name(cfg, stage, execution_i)
          let system_trace_start_us = if timeline_enabled &&
            should_trace_system(cfg, stage, systems.length()) {
            timeline_trace_begin_span(TimelineTraceCategory::System, trace_name)
          } else {
            -1L
          }

          // Align with Bevy: increment global change tick once per executed system
          // and expose SystemSequence via World-backed context for change detection.
          let this_run = world.advance_sequence()
          let sys_ticks = @core.SystemSequence::new(
            cfg.last_run_sequence,
            this_run,
          )
          let ctx = world.get_sequence_context()
          ctx.set(sys_ticks)
          world.set_sequence_context(ctx)
          let prev_world = current_world_ref.val
          current_world_ref.val = Some(world)
          let prev_ticks = current_system_sequence_ref.val
          current_system_sequence_ref.val = Some(sys_ticks)
          let prev_outcome = current_system_execution_outcome()
          reset_system_execution_outcome()
          (cfg.system)(world)
          let outcome = current_system_execution_outcome()
          current_system_execution_outcome_ref.val = prev_outcome
          current_system_sequence_ref.val = prev_ticks
          current_world_ref.val = prev_world
          match outcome {
            Success => {
              if timeline_enabled && system_trace_start_us >= 0L {
                timeline_trace_end_span(
                  TimelineTraceCategory::System,
                  trace_name,
                  system_trace_start_us,
                )
              }
              systems[system_i].last_run_sequence = this_run
              executor_state.mark_unapplied(system_i)
              stepping_record_system_run(
                stepping_ref, stage, systems, node, execution_i,
              )
            }
            Skipped(_) => return
            Invalid(message) => {
              if timeline_enabled && system_trace_start_us >= 0L {
                timeline_trace_end_span(
                  TimelineTraceCategory::System,
                  trace_name,
                  system_trace_start_us,
                )
              }
              report_world_error(
                world,
                @ecs.Invalid(message),
                system_context(
                  systems[system_i],
                  ErrorContextKind::Validation,
                  current_schedule_stage(),
                ),
              )
              return
            }
            Error(err) => {
              if timeline_enabled && system_trace_start_us >= 0L {
                timeline_trace_end_span(
                  TimelineTraceCategory::System,
                  trace_name,
                  system_trace_start_us,
                )
              }
              systems[system_i].last_run_sequence = this_run
              executor_state.mark_unapplied(system_i)
              stepping_record_system_run(
                stepping_ref, stage, systems, node, execution_i,
              )
              match systems[system_i].error_handler {
                Some(handler) =>
                  handler(
                    err,
                    system_context(
                      systems[system_i],
                      ErrorContextKind::System,
                      current_schedule_stage(),
                    ),
                  )
                None =>
                  report_world_error(
                    world,
                    err,
                    system_context(
                      systems[system_i],
                      ErrorContextKind::System,
                      current_schedule_stage(),
                    ),
                  )
              }
            }
          }
        }
      }
  }
  let execution_i_ref = Ref::new(0)
  match executor_kind {
    SingleThreaded =>
      for system_i in 0..<systems.length() {
        let execution_i = execution_i_ref.val
        execution_i_ref.val = execution_i + 1
        run_execution_node(ScheduledSystem(system_i), execution_i)
      }
    MultiThreaded =>
      for batch in execution_batches {
        for node in batch {
          let execution_i = execution_i_ref.val
          execution_i_ref.val = execution_i + 1
          run_execution_node(node, execution_i)
        }
      }
    }
  if executor_state.apply_final_deferred {
    executor_state.apply_deferred(world, restart_batch=false)
  }
  executor_state.clear_run_state()
  stepping_finish_stage(stepping_ref, stage, execution_order.length())
}
