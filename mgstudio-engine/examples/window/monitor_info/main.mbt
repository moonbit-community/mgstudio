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
pub impl @ecs.Component for MonitorRef with fn component() {
  monitor_ref_component_key
}

///|
fn format_two_decimals(value : Double) -> String {
  let scaled = (value * 100.0).round().to_int()
  let magnitude = if scaled < 0 { -scaled } else { scaled }
  let whole = magnitude / 100
  let fractional = magnitude % 100
  let sign = if scaled < 0 { "-" } else { "" }
  let frac = if fractional < 10 {
    "0\{fractional.to_string()}"
  } else {
    fractional.to_string()
  }
  "\{sign}\{whole.to_string()}.\{frac}"
}

///|
fn refresh_rate_text(monitor : @window.Monitor) -> String {
  match monitor.refresh_rate_millihertz {
    Some(value) => "\{(Float::from_int(value) / 1000.0F).to_string()}Hz"
    None => "<unknown>"
  }
}

///|
fn monitor_info_text(title : String, monitor : @window.Monitor) -> String {
  "Monitor: \{title}\nSize: \{monitor.physical_height.to_string()}x\{monitor.physical_width.to_string()}px\nRefresh rate: \{refresh_rate_text(monitor)}\nPosition: x=\{monitor.physical_position.x.to_string()} y=\{monitor.physical_position.y.to_string()}\nScale: \{format_two_decimals(monitor.scale_factor)}\n\n"
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
    value="[monitor_info] \{monitor_info_text(title, monitor)}",
  )

  let window_entity = commands.spawn(
    (
      @window.Window::{
        ..Window(),
        title,
        mode: Fullscreen(Entity(monitor_entity), Current),
        position: Centered(Entity(monitor_entity)),
      },
      MonitorRef::{ monitor: monitor_entity },
    ),
  )

  let info_camera = commands.spawn(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera(),
      @transform.Transform::identity(),
      @camera_camera.RenderTarget::Window(Entity(window_entity)),
    ),
  )

  ignore(
    commands.spawn(
      (
        @text.Text::new(monitor_info_text(title, monitor)),
        @ui.Node::Node()
        .with_position_type(Relative)
        .with_height(Percent(100.0F))
        .with_width(Percent(100.0F)),
        @ui.UiTargetCamera::new(info_camera),
      ),
    ),
  )
}

///|
fn update(
  commands : @app.Commands,
  monitors_added : @ecs.Query[
    (@core.Entity, @ecs.Read[@window.Monitor]),
    @ecs.Added[@window.Monitor],
  ],
  monitors_removed : @ecs.RemovedComponents[@window.Monitor],
  windows : @ecs.Query[(@core.Entity, @ecs.Read[MonitorRef]), @ecs.All],
) -> Unit {
  let added : Array[(@core.Entity, @window.Monitor)] = []
  try! monitors_added.view(fn(_query_entity, pair) {
    let (entity, monitor) = pair
    added.push((entity, monitor.value()))
  })
  for item in added {
    spawn_window_for_monitor(commands, item.0, item.1)
  }

  let removed = monitors_removed.read()
  if removed.length() == 0 {
    return
  }
  let windows_to_close : Array[@core.Entity] = []
  try! windows.view(fn(_query_entity, pair) {
    let (window_entity, monitor_ref) = pair
    for monitor_entity in removed {
      if monitor_ref.value().monitor == monitor_entity {
        windows_to_close.push(window_entity)
      }
    }
  })
  for entity in windows_to_close {
    commands.entity(entity).despawn()
  }
}

///|
fn close_on_esc(
  commands : @app.Commands,
  keyboard : @input.ButtonInput[@window.KeyCode],
  windows : @ecs.Query[(@core.Entity, @ecs.Read[@window.Window]), @ecs.All],
) -> Unit {
  if !keyboard.just_pressed(Escape) {
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
  .add_plugins(
    @mgstudio.DefaultPlugins::set_window({
      ..WindowPlugin(),
      primary_window: None,
      exit_condition: DontExit,
    }),
  )
  .add_systems_param4(Update, update)
  .add_systems_param3(Update, close_on_esc)
  .run()
}
