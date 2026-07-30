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
priv enum ExampleRenderError {
  None
  OutOfMemory
  Validation
  DeviceLost
  Loop
} derive(Eq)

///|
let example_render_error_resource_key : @ecs.ResourceKey[ExampleRenderError] = @ecs.register_resource(
  debug_name="examples.app.render_recovery.ExampleRenderError",
)

///|
impl @app.Resource for ExampleRenderError with fn resource() {
  example_render_error_resource_key
}

///|
fn example_error_to_render_error(
  error : ExampleRenderError,
) -> @render.RenderError {
  match error {
    None => @render.RenderError::new(Unknown("none"), "no render error")
    OutOfMemory =>
      @render.RenderError::new(
        OutOfMemory,
        "requested out-of-memory render error",
      )
    Validation =>
      @render.RenderError::new(Validation, "requested validation render error")
    DeviceLost =>
      @render.RenderError::new(DeviceLost, "requested device-lost render error")
    Loop =>
      @render.RenderError::new(
        DeviceLost,
        "requested infinite shader loop render error",
      )
  }
}

///|
fn setup() -> Unit {
  println("Press O/V/D/L to trigger render runtime errors")
  println(
    "Press 1: Ignore, 2: Panic, 3: Exit app, 4: Stop rendering, 5: Recover",
  )
}

///|
fn set_ignore_policy(
  _error : @render.RenderError,
  _main_world : @ecs.World,
  _render_world : @ecs.World,
) -> @render.RenderErrorPolicy {
  Ignore
}

///|
fn set_panic_policy(
  error : @render.RenderError,
  _main_world : @ecs.World,
  _render_world : @ecs.World,
) -> @render.RenderErrorPolicy {
  abort("Rendering error \{Repr(error).to_string()}")
}

///|
fn set_exit_policy(
  _error : @render.RenderError,
  main_world : @ecs.World,
  _render_world : @ecs.World,
) -> @render.RenderErrorPolicy {
  let key = @app.AppExit::message()
  if !main_world.contains_message(key) {
    main_world.init_message(key)
  }
  ignore(main_world.send_message(key, @app.AppExit::error()))
  StopRendering
}

///|
fn set_stop_policy(
  _error : @render.RenderError,
  _main_world : @ecs.World,
  _render_world : @ecs.World,
) -> @render.RenderErrorPolicy {
  StopRendering
}

///|
fn set_recover_policy(
  _error : @render.RenderError,
  _main_world : @ecs.World,
  _render_world : @ecs.World,
) -> @render.RenderErrorPolicy {
  Recover(@render.RenderCreation::default())
}

///|
fn input_system(
  error : @app.ResMut[ExampleRenderError],
  handler : @app.ResMut[@render.RenderErrorHandler],
) -> Unit {
  error.set(None)
  if @input.key_just_pressed(Digit1) {
    handler.set(@render.RenderErrorHandler::new(set_ignore_policy))
    println("render policy: Ignore")
  }
  if @input.key_just_pressed(Digit2) {
    handler.set(@render.RenderErrorHandler::new(set_panic_policy))
    println("render policy: Panic")
  }
  if @input.key_just_pressed(Digit3) {
    handler.set(@render.RenderErrorHandler::new(set_exit_policy))
    println("render policy: ExitApp")
  }
  if @input.key_just_pressed(Digit4) {
    handler.set(@render.RenderErrorHandler::new(set_stop_policy))
    println("render policy: StopRendering")
  }
  if @input.key_just_pressed(Digit5) {
    handler.set(@render.RenderErrorHandler::new(set_recover_policy))
    println("render policy: Recover")
  }

  if @input.key_just_pressed(KeyO) {
    error.set(OutOfMemory)
  }
  if @input.key_just_pressed(KeyV) {
    error.set(Validation)
  }
  if @input.key_just_pressed(KeyD) {
    error.set(DeviceLost)
  }
  if @input.key_just_pressed(KeyL) {
    error.set(Loop)
  }
}

///|
fn report_status(error : @app.Res[ExampleRenderError]) -> Unit {
  if error.get() != None {
    let render_error = example_error_to_render_error(error.get())
    println("requested render runtime error: \{Repr(render_error).to_string()}")
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .insert_resource(ExampleRenderError::None)
  .add_systems_fn(Startup, setup)
  .add_systems_param2(Update, input_system)
  .add_systems_param(Update, report_status)
  .run()
}
