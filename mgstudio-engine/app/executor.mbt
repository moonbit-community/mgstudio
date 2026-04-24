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
  systems : Array[SystemConfig[@ecs.World]],
  execution_order : Array[ScheduleExecutionNode],
  execution_batches : Array[Array[ScheduleExecutionNode]],
  stage : ScheduleStage?,
  system_accesses? : Array[SystemAccess] = [],
  apply_final_deferred? : Bool = true,
  set_run_conditions? : @hashmap.HashMap[
    SystemSet,
    Ref[ScheduleSetRunConditions[@ecs.World]],
  ] = @hashmap.HashMap::new(),
) -> Unit {
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
              "\{set}#\{fallback_index.to_string()}"
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
  fn apply_deferred_boundary() -> Unit {
    end_deferred_command_batch(world)
    begin_deferred_command_batch()
  }
  fn system_validation_error(system_i : Int) -> String? {
    if system_i >= 0 && system_i < system_accesses.length() {
      system_accesses[system_i].validation_error()
    } else {
      None
    }
  }
  begin_deferred_command_batch()
  let set_run_if_results : @hashmap.HashMap[SystemSet, Bool] = @hashmap.HashMap::new()
  fn evaluate_set_run_if_once(set : SystemSet) -> Bool {
    match set_run_if_results.get(set) {
      Some(cached) => cached
      None => {
        let should_run = match set_run_conditions.get(set) {
          None => true
          Some(run_conditions_ref) => {
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
            matches
          }
        }
        set_run_if_results.set(set, should_run)
        should_run
      }
    }
  }
  let execution_i_ref = Ref::new(0)
  for batch in execution_batches {
    for node in batch {
      let execution_i = execution_i_ref.val
      execution_i_ref.val = execution_i + 1
      if !stepping_should_run_system(
          stepping_ref, stage, systems, node, execution_i,
        ) {
        continue
      }
      match node {
        AutoApplyDeferred(_) => {
          apply_deferred_boundary()
          stepping_record_system_run(
            stepping_ref, stage, systems, node, execution_i,
          )
          continue
        }
        ScheduledSystem(system_i) => {
          let cfg = systems[system_i]
          let mut should_run_system = true
          let checked_sets : Array[SystemSet] = []
          let set_conditions_passed = Ref::new(true)
          fn check_set_run_conditions(set : SystemSet) -> Unit {
            if checked_sets.contains(set) {
              return
            }
            checked_sets.push(set)
            if !evaluate_set_run_if_once(set) {
              set_conditions_passed.val = false
            }
          }
          for set in cfg.member_sets {
            check_set_run_conditions(set)
          }
          match cfg.set {
            Some(set) =>
              if !set.has_prefix("__chain__:") {
                check_set_run_conditions(set)
              }
            None => ()
          }
          should_run_system = should_run_system && set_conditions_passed.val
          for cond_i in 0..<cfg.run_ifs.length() {
            let cond = cfg.run_ifs[cond_i]
            let cond_this_run = world.advance_sequence()
            let cond_ticks = @core.SystemSequence::new(
              cfg.run_if_last_run_sequences[cond_i],
              cond_this_run,
            )
            let cond_ctx = world.get_sequence_context()
            cond_ctx.set(cond_ticks)
            world.set_sequence_context(cond_ctx)
            let prev_world = current_world_ref.val
            current_world_ref.val = Some(world)
            current_system_sequence_ref.val = Some(cond_ticks)
            let should_run = cond(world, cfg.run_if_states[cond_i])
            current_system_sequence_ref.val = None
            current_world_ref.val = prev_world
            systems[system_i].run_if_last_run_sequences[cond_i] = cond_this_run
            should_run_system = should_run_system && should_run
          }
          if !should_run_system {
            continue
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
              continue
            }
            None => ()
          }
          if cfg.is_apply_deferred_node {
            apply_deferred_boundary()
            stepping_record_system_run(
              stepping_ref, stage, systems, node, execution_i,
            )
            continue
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
              stepping_record_system_run(
                stepping_ref, stage, systems, node, execution_i,
              )
            }
            Skipped(_) => continue
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
              continue
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
  }
  if apply_final_deferred {
    end_deferred_command_batch(world)
  }
  stepping_finish_stage(stepping_ref, stage, execution_order.length())
}
