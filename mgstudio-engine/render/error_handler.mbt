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
// Bevy source: `bevy/crates/bevy_render/src/error_handler.rs`.

///|
pub(all) enum RenderState {
  Initializing
  Ready
  Errored(@app.RenderRuntimeError)
  Reinitializing
}

///|
pub(all) enum RenderErrorPolicy {
  Ignore
  StopRendering
  Recover(RenderCreation)
}

///|
pub(all) struct RenderErrorHandler {
  handler : (@app.RenderRuntimeError, @ecs.World, @ecs.World) -> RenderErrorPolicy
}

///|
fn default_render_error_handler(
  _error : @app.RenderRuntimeError,
  _main_world : @ecs.World,
  _render_world : @ecs.World,
) -> RenderErrorPolicy {
  RenderErrorPolicy::StopRendering
}

///|
pub fn RenderErrorHandler::RenderErrorHandler() -> RenderErrorHandler {
  RenderErrorHandler::{ handler: default_render_error_handler }
}

///|
pub fn RenderErrorHandler::new(
  handler : (@app.RenderRuntimeError, @ecs.World, @ecs.World) -> RenderErrorPolicy,
) -> RenderErrorHandler {
  RenderErrorHandler::{ handler, }
}

///|
pub let render_error_handler_resource_key : @ecs.ResourceKey[RenderErrorHandler] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderErrorHandler",
)

///|
fn RenderErrorHandler::handle(
  self : RenderErrorHandler,
  error : @app.RenderRuntimeError,
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  match (self.handler)(error, main_world, render_world) {
    Ignore => mark_renderer_ready(render_world)
    StopRendering => ()
    Recover(render_creation) => {
      if !insert_future_render_resources(render_creation, main_world) {
        abort(
          "RenderErrorPolicy::Recover could not insert future render resources",
        )
      }
      render_world.insert_resource(
        render_state_resource_key,
        RenderState::reinitializing(),
      )
    }
  }
}

///|
pub let render_state_resource_key : @ecs.ResourceKey[RenderState] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderState",
)

///|
pub fn RenderState::initializing() -> RenderState {
  Initializing
}

///|
pub fn RenderState::ready() -> RenderState {
  Ready
}

///|
pub fn RenderState::reinitializing() -> RenderState {
  Reinitializing
}

///|
pub fn RenderState::errored(error : @app.RenderRuntimeError) -> RenderState {
  Errored(error)
}

///|
pub fn RenderState::is_ready(self : RenderState) -> Bool {
  self is Ready
}

///|
pub fn init_render_state(world : @ecs.World) -> Unit {
  let state = match world.get_resource(render_state_resource_key) {
    Some(value) => Some(value)
    None => None
  }
  if state is None {
    world.insert_resource(
      render_state_resource_key,
      RenderState::initializing(),
    )
  }
}

///|
fn render_resources_ready_for_startup(world : @ecs.World) -> Bool {
  world.resource(render_device_resource_key).is_present() &&
  world.resource(render_queue_resource_key).is_present() &&
  world.resource(render_adapter_resource_key).is_present() &&
  world.resource(render_adapter_info_resource_key).is_present() &&
  world.resource(render_instance_resource_key).is_present() &&
  world.resource(pipeline_cache_resource_key).is_present()
}

///|
pub fn renderer_is_ready(world : @ecs.World) -> Bool {
  match world.get_resource(render_state_resource_key) {
    Some(state) => state.is_ready()
    None => false
  }
}

///|
pub fn mark_renderer_ready(world : @ecs.World) -> Unit {
  world.insert_resource(render_state_resource_key, RenderState::ready())
}

///|
fn update_render_state(
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> Unit {
  let state = match render_world.get_resource(render_state_resource_key) {
    Some(value) => value
    None => RenderState::initializing()
  }
  match state {
    Initializing =>
      if render_resources_ready_for_startup(render_world) {
        @app.run_current_schedule_stage(
          render_world,
          render_startup_schedule_stage(),
        )
        mark_renderer_ready(render_world)
      } else if render_world.resource(render_state_resource_key).is_present() {
        ()
      } else {
        render_world.insert_resource(
          render_state_resource_key,
          RenderState::initializing(),
        )
      }
    Ready => ()
    Reinitializing =>
      match take_future_render_resources(main_world) {
        Some(resources) => {
          resources.unpack_into(main_world, render_world)
          render_world.insert_resource(
            render_state_resource_key,
            RenderState::initializing(),
          )
        }
        None => ()
      }
    Errored(error) => {
      let handler = match
        render_world.get_resource(render_error_handler_resource_key) {
        Some(value) => value
        None => RenderErrorHandler::RenderErrorHandler()
      }
      handler.handle(error, main_world, render_world)
    }
  }
}
