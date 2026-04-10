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
fn setup(_world : @ecs.World) -> Unit {
  println("Press O/V/D/L to trigger render runtime errors")
  println(
    "Press 1: Ignore, 2: Panic, 3: Exit app, 4: Stop rendering, 5: Recover",
  )
}

///|
fn set_ignore_policy(
  _error : @app.RenderRuntimeError,
) -> @app.RenderErrorPolicy {
  @app.RenderErrorPolicy::Ignore
}

///|
fn set_panic_policy(_error : @app.RenderRuntimeError) -> @app.RenderErrorPolicy {
  @app.RenderErrorPolicy::Panic
}

///|
fn set_exit_policy(_error : @app.RenderRuntimeError) -> @app.RenderErrorPolicy {
  @app.RenderErrorPolicy::ExitApp
}

///|
fn set_stop_policy(_error : @app.RenderRuntimeError) -> @app.RenderErrorPolicy {
  @app.RenderErrorPolicy::StopRendering
}

///|
fn set_recover_policy(
  _error : @app.RenderRuntimeError,
) -> @app.RenderErrorPolicy {
  @app.RenderErrorPolicy::Recover
}

///|
fn input_system(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Digit1) {
    @app.set_render_error_handler(set_ignore_policy)
    println("render policy: Ignore")
  }
  if @input.key_just_pressed(@window.KeyCode::Digit2) {
    @app.set_render_error_handler(set_panic_policy)
    println("render policy: Panic")
  }
  if @input.key_just_pressed(@window.KeyCode::Digit3) {
    @app.set_render_error_handler(set_exit_policy)
    println("render policy: ExitApp")
  }
  if @input.key_just_pressed(@window.KeyCode::Digit4) {
    @app.set_render_error_handler(set_stop_policy)
    println("render policy: StopRendering")
  }
  if @input.key_just_pressed(@window.KeyCode::Digit5) {
    @app.set_render_error_handler(set_recover_policy)
    println("render policy: Recover")
  }

  if @input.key_just_pressed(@window.KeyCode::KeyO) {
    @app.report_render_runtime_error(@app.RenderRuntimeError::OutOfMemory)
  }
  if @input.key_just_pressed(@window.KeyCode::KeyV) {
    @app.report_render_runtime_error(@app.RenderRuntimeError::Validation)
  }
  if @input.key_just_pressed(@window.KeyCode::KeyD) {
    @app.report_render_runtime_error(@app.RenderRuntimeError::DeviceLost)
  }
  if @input.key_just_pressed(@window.KeyCode::KeyL) {
    @app.report_render_runtime_error(@app.RenderRuntimeError::Loop)
  }
}

///|
fn report_status(_world : @ecs.World) -> Unit {
  if @app.render_runtime_error() is Some(error) {
    println(
      "last render runtime error: \{to_repr(error).to_string()}, rendering_enabled=\{@app.app_rendering_enabled().to_string()}",
    )
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(input_system))
  .add_systems(@app.Update, @app.system(report_status))
  .run()
}
