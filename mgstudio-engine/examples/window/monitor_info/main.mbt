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
// Bevy source: `bevy/examples/window/monitor_info.rs`.

///|
pub struct MonitorRef {
  monitor : @core.Entity
}

///|
let monitor_ref_component_key : @ecs.ComponentKey[MonitorRef] = @ecs.register_component(
  debug_name="examples.window.monitor_info.MonitorRef",
)

///|
pub impl @ecs.Component for MonitorRef with component() {
  monitor_ref_component_key
}

///|
fn spawn_window_for_monitor(
  commands : @app.Commands,
  monitor_entity : @core.Entity,
  monitor : @window.Monitor,
) -> Unit {
  let title = match monitor.name {
    Some(name) => name
    None => "<no name>"
  }
  @window.host_debug_string(
    value="[monitor_info] monitor=\{title} size=\{monitor.physical_width.to_string()}x\{monitor.physical_height.to_string()} scale=\{monitor.scale_factor.to_string()}",
  )

  let window_entity = commands.spawn(
    (
      @window.Window::{
        ..@window.Window::default(),
        title,
        mode: @window.WindowMode::Fullscreen(
          @window.MonitorSelection::Entity(monitor_entity),
          @window.VideoModeSelection::Current,
        ),
        position: @window.WindowPosition::Centered(
          @window.MonitorSelection::Entity(monitor_entity),
        ),
      },
      MonitorRef::{ monitor: monitor_entity },
    ),
  )

  ignore(
    commands.spawn(
      @sprite.Camera2dBundle::new_with_target(
        @sprite.Camera::default(),
        @transform.Transform::identity(),
        @sprite.RenderTarget::Window(@window.WindowRef::Entity(window_entity)),
      ),
    ),
  )
}

///|
fn update(
  commands : @app.Commands,
  monitors_added : @ecs.Query[
    (@core.Entity, @ecs.Comp[@window.Monitor]),
    @ecs.Added[@window.Monitor],
  ],
) -> Unit {
  try! monitors_added.view(fn(_query_entity, pair) {
    let (entity, monitor) = pair
    spawn_window_for_monitor(commands, entity, monitor.value())
  })
}

///|
fn close_on_esc(
  commands : @app.Commands,
  keyboard : @input.ButtonInput[@window.KeyCode],
  windows : @ecs.Query[(@core.Entity, @ecs.Comp[@window.Window]), @ecs.All],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Escape) {
    return
  }
  try! windows.view(fn(_query_entity, pair) {
    let (entity, window) = pair
    if window.value().focused {
      commands.entity(entity).despawn()
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set_window(@window.WindowPlugin::{
      ..@window.WindowPlugin::default(),
      primary_window: None,
      exit_condition: @window.ExitCondition::DontExit,
    })
  })
  .add_systems(@app.Update, @app.system(@app.system_param2(update)))
  .add_systems(@app.Update, @app.system(@app.system_param3(close_on_esc)))
  .run()
}
