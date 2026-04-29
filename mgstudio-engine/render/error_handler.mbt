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
let ecs_key_render_state_resource : @ecs.ResourceKey[RenderState] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderState",
)

///|
pub fn render_state_resource_key() -> @ecs.ResourceKey[RenderState] {
  ecs_key_render_state_resource
}

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
  let state = match
    (try world.get_resource(render_state_resource_key()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(value) => Some(value)
    None => None
  }
  if state is None {
    world.insert_resource(
      render_state_resource_key(),
      RenderState::initializing(),
    )
  }
}

///|
pub fn renderer_is_ready(world : @ecs.World) -> Bool {
  match
    (try world.get_resource(render_state_resource_key()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(state) => state.is_ready()
    None => false
  }
}

///|
pub fn mark_renderer_ready(world : @ecs.World) -> Unit {
  world.insert_resource(render_state_resource_key(), RenderState::ready())
}

///|
pub fn render_runtime_error() -> @app.RenderRuntimeError? {
  @app.render_runtime_error()
}

///|
pub fn app_rendering_enabled() -> Bool {
  @app.app_rendering_enabled()
}

///|
pub fn app_rendering_stop() -> Unit {
  @app.app_rendering_stop()
}

///|
pub fn app_rendering_resume() -> Unit {
  @app.app_rendering_resume()
}

///|
pub fn set_render_error_handler(handler : @app.RenderErrorHandler) -> Unit {
  @app.set_render_error_handler(handler)
}

///|
pub fn reset_render_error_handler() -> Unit {
  @app.reset_render_error_handler()
}

///|
pub fn report_render_runtime_error(error : @app.RenderRuntimeError) -> Unit {
  @app.report_render_runtime_error(error)
}

///|
pub fn render_error_policy_recover() -> @app.RenderErrorPolicy {
  @app.RenderErrorPolicy::Recover
}
