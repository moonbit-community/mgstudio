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
