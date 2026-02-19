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
/// Marker component aligned with Bevy's `Wireframe`.
///
/// Meshes with this marker render in wireframe regardless of
/// `WireframeConfig::global`.
#ecs.component
pub struct Wireframe {}

///|
pub fn Wireframe::default() -> Wireframe {
  Wireframe::{  }
}

///|
/// Marker component aligned with Bevy's `NoWireframe`.
///
/// Meshes with this marker never render in wireframe regardless of
/// `WireframeConfig::global`.
#ecs.component
pub struct NoWireframe {}

///|
pub fn NoWireframe::default() -> NoWireframe {
  NoWireframe::{  }
}

///|
/// Per-mesh wireframe color aligned with Bevy's `WireframeColor`.
#ecs.component
pub struct WireframeColor {
  color : @render2d.Color
}

///|
pub fn WireframeColor::default() -> WireframeColor {
  WireframeColor::{ color: @render2d.Color::white() }
}

///|
pub fn WireframeColor::new(color : @render2d.Color) -> WireframeColor {
  WireframeColor::{ color, }
}

///|
pub fn WireframeColor::with_color(
  self : WireframeColor,
  color : @render2d.Color,
) -> WireframeColor {
  self |> ignore
  WireframeColor::{ color, }
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct WireframeConfig {
  global : Bool
  default_color : @render2d.Color
}

///|
pub fn WireframeConfig::default() -> WireframeConfig {
  WireframeConfig::{ global: false, default_color: @render2d.Color::white() }
}

///|
pub fn WireframeConfig::new(
  global : Bool,
  default_color : @render2d.Color,
) -> WireframeConfig {
  WireframeConfig::{ global, default_color }
}

///|
pub fn WireframeConfig::with_global(
  self : WireframeConfig,
  global : Bool,
) -> WireframeConfig {
  WireframeConfig::{ ..self, global, }
}

///|
pub fn WireframeConfig::with_default_color(
  self : WireframeConfig,
  default_color : @render2d.Color,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_color, }
}
