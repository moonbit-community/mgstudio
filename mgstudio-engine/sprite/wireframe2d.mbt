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
/// Marker component aligned with Bevy's `Wireframe2d`.
///
/// Meshes with this marker render wireframes regardless of
/// `Wireframe2dConfig::global`.
pub struct Wireframe2d {}

///|
pub fn Wireframe2d::default() -> Wireframe2d {
  Wireframe2d::{  }
}

///|
/// Marker component aligned with Bevy's `NoWireframe2d`.
///
/// Meshes with this marker never render wireframes regardless of
/// `Wireframe2dConfig::global`.
pub struct NoWireframe2d {}

///|
pub fn NoWireframe2d::default() -> NoWireframe2d {
  NoWireframe2d::{  }
}

///|
/// Per-mesh wireframe color aligned with Bevy's `Wireframe2dColor`.
pub struct Wireframe2dColor {
  color : Color
}

///|
pub fn Wireframe2dColor::default() -> Wireframe2dColor {
  Wireframe2dColor::{ color: Color::white() }
}

///|
pub fn Wireframe2dColor::new(color : Color) -> Wireframe2dColor {
  Wireframe2dColor::{ color, }
}

///|
pub fn Wireframe2dColor::with_color(
  self : Wireframe2dColor,
  color : Color,
) -> Wireframe2dColor {
  self |> ignore
  Wireframe2dColor::{ color, }
}

///|
pub struct Wireframe2dConfig {
  global : Bool
  default_color : Color
} derive(ToJson, FromJson)

///|
pub fn Wireframe2dConfig::default() -> Wireframe2dConfig {
  Wireframe2dConfig::{ global: false, default_color: Color::white() }
}

///|
pub fn Wireframe2dConfig::new(
  global : Bool,
  default_color : Color,
) -> Wireframe2dConfig {
  Wireframe2dConfig::{ global, default_color }
}

///|
pub fn Wireframe2dConfig::with_global(
  self : Wireframe2dConfig,
  global : Bool,
) -> Wireframe2dConfig {
  Wireframe2dConfig::{ ..self, global, }
}

///|
pub fn Wireframe2dConfig::with_default_color(
  self : Wireframe2dConfig,
  default_color : Color,
) -> Wireframe2dConfig {
  Wireframe2dConfig::{ ..self, default_color, }
}

///|
pub impl @app.Resource for Wireframe2dConfig with resource() {
  ecs_key_wireframe2d_config
}

///|
fn init_wireframe2d_resources(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let wireframe_config = get_wireframe2d_config_resource(world)
  if !wireframe_config.is_present() {
    wireframe_config.insert(Wireframe2dConfig::default(), tick)
  }
}

///|
pub fn wireframe2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_startup_system(init_wireframe2d_resources)
}

///|
fn wireframe2d_mesh_should_draw(
  has_wireframe : Bool,
  has_no_wireframe : Bool,
  wireframe_config : Wireframe2dConfig?,
) -> Bool {
  guard wireframe_config is Some(config) else { return false }
  if has_no_wireframe {
    false
  } else if has_wireframe {
    true
  } else {
    config.global
  }
}

///|
fn wireframe2d_mesh_color(
  mesh_color : Wireframe2dColor?,
  wireframe_config : Wireframe2dConfig?,
) -> Color {
  if mesh_color is Some(component) {
    component.color
  } else if wireframe_config is Some(config) {
    config.default_color
  } else {
    Color::white()
  }
}
