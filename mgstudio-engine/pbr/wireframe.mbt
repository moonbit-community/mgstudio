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
pub struct Wireframe {} derive(ToJson, FromJson)

///|
pub fn Wireframe::default() -> Wireframe {
  Wireframe::{  }
}

///|
/// Marker component aligned with Bevy's `NoWireframe`.
///
/// Meshes with this marker never render in wireframe regardless of
/// `WireframeConfig::global`.
pub struct NoWireframe {} derive(ToJson, FromJson)

///|
pub fn NoWireframe::default() -> NoWireframe {
  NoWireframe::{  }
}

///|
/// Per-mesh wireframe color aligned with Bevy's `WireframeColor`.
pub struct WireframeColor {
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn WireframeColor::default() -> WireframeColor {
  WireframeColor::{ color: @sprite.Color::white() }
}

///|
pub fn WireframeColor::new(color : @sprite.Color) -> WireframeColor {
  WireframeColor::{ color, }
}

///|
pub fn WireframeColor::with_color(
  self : WireframeColor,
  color : @sprite.Color,
) -> WireframeColor {
  self |> ignore
  WireframeColor::{ color, }
}

///|
pub struct WireframeConfig {
  global : Bool
  default_color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn WireframeConfig::default() -> WireframeConfig {
  WireframeConfig::{ global: false, default_color: @sprite.Color::white() }
}

///|
pub fn WireframeConfig::new(
  global : Bool,
  default_color : @sprite.Color,
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
  default_color : @sprite.Color,
) -> WireframeConfig {
  WireframeConfig::{ ..self, default_color, }
}

///|
pub impl @app.Resource for WireframeConfig with resource() {
  ecs_key_wireframe_config
}
