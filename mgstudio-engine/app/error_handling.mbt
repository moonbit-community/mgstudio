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
pub(all) enum ErrorContextKind {
  System
  Command
  Observer
  Validation
} derive(Eq, Show)

///|
pub struct ErrorContext {
  kind : ErrorContextKind
  source : String
  stage : ScheduleStage?
}

///|
pub fn ErrorContext::new(
  kind : ErrorContextKind,
  source : String,
  stage? : ScheduleStage? = None,
) -> ErrorContext {
  { kind, source, stage }
}

///|
pub fn ErrorContext::kind(self : ErrorContext) -> ErrorContextKind {
  self.kind
}

///|
pub fn ErrorContext::source(self : ErrorContext) -> String {
  self.source
}

///|
pub fn ErrorContext::stage(self : ErrorContext) -> ScheduleStage? {
  self.stage
}

///|
pub type ErrorHandler = (Error, ErrorContext) -> Unit

///|
pub struct ErrorHandlers {}

///|
priv struct DefaultErrorHandlerResource {
  handler : ErrorHandler
}

///|
let ecs_res_key_default_error_handler : @ecs.ResourceKey[
  DefaultErrorHandlerResource,
] = @ecs.register_resource(debug_name="bevy_app::DefaultErrorHandler")

///|
fn error_context_prefix(context : ErrorContext) -> String {
  let base = match context.kind {
    ErrorContextKind::System => "Encountered an error in system"
    ErrorContextKind::Command => "Encountered an error in command"
    ErrorContextKind::Observer => "Encountered an error in observer"
    ErrorContextKind::Validation => "Encountered a validation error"
  }
  let stage_suffix = match context.stage {
    Some(stage) => " during \{stage.to_string()}"
    None => ""
  }
  "\{base} `\{context.source}`\{stage_suffix}"
}

///|
pub fn ErrorHandlers::panic(error : Error, context : ErrorContext) -> Unit {
  abort("\{error_context_prefix(context)}: \{error.to_string()}")
}

///|
pub fn ErrorHandlers::error(error : Error, context : ErrorContext) -> Unit {
  log_error("\{error_context_prefix(context)}: \{error.to_string()}")
}

///|
pub fn ErrorHandlers::warn(error : Error, context : ErrorContext) -> Unit {
  log_warn("\{error_context_prefix(context)}: \{error.to_string()}")
}

///|
pub fn ErrorHandlers::info(error : Error, context : ErrorContext) -> Unit {
  log_info("\{error_context_prefix(context)}: \{error.to_string()}")
}

///|
pub fn ErrorHandlers::debug(error : Error, context : ErrorContext) -> Unit {
  log_debug("\{error_context_prefix(context)}: \{error.to_string()}")
}

///|
pub fn ErrorHandlers::trace(error : Error, context : ErrorContext) -> Unit {
  log_trace("\{error_context_prefix(context)}: \{error.to_string()}")
}

///|
pub fn ErrorHandlers::ignore(_error : Error, _context : ErrorContext) -> Unit {
  ()
}

///|
fn default_error_handler_impl(error : Error, context : ErrorContext) -> Unit {
  ignore(ErrorHandlers::{  })
  ErrorHandlers::panic(error, context)
}

///|
fn ensure_default_error_handler(world : @ecs.World) -> Unit {
  let existing = try
    world.get_resource(ecs_res_key_default_error_handler)
  catch {
    _ => None
  } noraise {
    value => value
  }
  if existing is None {
    world.insert_resource(ecs_res_key_default_error_handler, {
      handler: default_error_handler_impl,
    })
  }
}

///|
pub fn set_default_error_handler(
  world : @ecs.World,
  handler : ErrorHandler,
) -> Unit {
  ensure_default_error_handler(world)
  world.insert_resource(ecs_res_key_default_error_handler, { handler, })
}

///|
pub fn default_error_handler(world : @ecs.World) -> ErrorHandler {
  ensure_default_error_handler(world)
  match
    (try world.get_resource(ecs_res_key_default_error_handler) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(resource) => resource.handler
    None => default_error_handler_impl
  }
}

///|
pub fn App::set_error_handler(
  self : App[@ecs.World],
  handler : ErrorHandler,
) -> App[@ecs.World] {
  set_default_error_handler(self.sub_apps.main.world, handler)
  for sub_app_entry in self.sub_apps_mut() {
    let (_, sub_app_ref) = sub_app_entry
    set_default_error_handler(sub_app_ref.val.world, handler)
  }
  self
}

///|
pub fn report_world_error(
  world : @ecs.World,
  error : Error,
  context : ErrorContext,
) -> Unit {
  default_error_handler(world)(error, context)
}

///|
priv enum SystemExecutionOutcome {
  Success
  Skipped(String)
  Invalid(String)
  Error(Error)
}

///|
let current_system_execution_outcome_ref : Ref[SystemExecutionOutcome] = Ref::new(
  Success,
)

///|
fn reset_system_execution_outcome() -> Unit {
  current_system_execution_outcome_ref.val = Success
}

///|
fn mark_system_execution_skipped(message : String) -> Unit {
  current_system_execution_outcome_ref.val = Skipped(message)
}

///|
fn mark_system_execution_invalid(message : String) -> Unit {
  current_system_execution_outcome_ref.val = Invalid(message)
}

///|
fn mark_system_execution_error(error : Error) -> Unit {
  current_system_execution_outcome_ref.val = Error(error)
}

///|
fn current_system_execution_outcome() -> SystemExecutionOutcome {
  current_system_execution_outcome_ref.val
}

///|
fn system_source_label(config : SystemConfig[@ecs.World]) -> String {
  match config.name {
    Some(name) => name
    None =>
      match config.set {
        Some(set_name) => set_name
        None => "<anonymous system>"
      }
  }
}

///|
fn system_context(
  config : SystemConfig[@ecs.World],
  kind : ErrorContextKind,
  stage : ScheduleStage?,
) -> ErrorContext {
  ErrorContext::new(kind, system_source_label(config), stage~)
}
