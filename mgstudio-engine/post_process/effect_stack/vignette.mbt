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
// Bevy source: `bevy/crates/bevy_post_process/src/effect_stack/vignette.rs`.
// Host-side uniform packing for the stable root `Vignette` runtime.

///|
pub struct Vignette {
  intensity : Float
  radius : Float
  smoothness : Float
  roundness : Float
  center : @math.Vec2
  edge_compensation : Float
  color : @color.Color
} derive(ToJson, FromJson)

///|
pub fn Vignette::default() -> Vignette {
  Vignette::{
    intensity: 1.0F,
    radius: 0.75F,
    smoothness: 5.0F,
    roundness: 1.0F,
    center: @math.Vec2::new(0.5F, 0.5F),
    edge_compensation: 1.0F,
    color: @color.Color::black(),
  }
}

///|
pub fn Vignette::new(
  intensity : Float,
  radius : Float,
  smoothness : Float,
  roundness : Float,
) -> Vignette {
  let safe_intensity = if intensity < 0.0F { 0.0F } else { intensity }
  let safe_radius = if radius < 0.0F { 0.0F } else { radius }
  let safe_smoothness = if smoothness <= 0.01F { 0.01F } else { smoothness }
  let safe_roundness = if roundness <= 0.01F { 0.01F } else { roundness }
  Vignette::{
    ..Vignette::default(),
    intensity: safe_intensity,
    radius: safe_radius,
    smoothness: safe_smoothness,
    roundness: safe_roundness,
  }
}

///|
pub fn Vignette::with_intensity(self : Vignette, intensity : Float) -> Vignette {
  Vignette::{
    ..self,
    intensity: if intensity < 0.0F {
      0.0F
    } else {
      intensity
    },
  }
}

///|
pub fn Vignette::with_radius(self : Vignette, radius : Float) -> Vignette {
  Vignette::{ ..self, radius: if radius < 0.0F { 0.0F } else { radius } }
}

///|
pub fn Vignette::with_smoothness(
  self : Vignette,
  smoothness : Float,
) -> Vignette {
  Vignette::{
    ..self,
    smoothness: if smoothness <= 0.01F {
      0.01F
    } else {
      smoothness
    },
  }
}

///|
pub fn Vignette::with_roundness(self : Vignette, roundness : Float) -> Vignette {
  Vignette::{
    ..self,
    roundness: if roundness <= 0.01F {
      0.01F
    } else {
      roundness
    },
  }
}

///|
pub fn Vignette::with_center(self : Vignette, center : @math.Vec2) -> Vignette {
  Vignette::{ ..self, center, }
}

///|
pub fn Vignette::with_edge_compensation(
  self : Vignette,
  edge_compensation : Float,
) -> Vignette {
  let safe = if edge_compensation < 0.0F {
    0.0F
  } else if edge_compensation > 1.0F {
    1.0F
  } else {
    edge_compensation
  }
  Vignette::{ ..self, edge_compensation: safe }
}

///|
pub fn Vignette::with_color(self : Vignette, color : @color.Color) -> Vignette {
  Vignette::{ ..self, color, }
}

///|
pub let ecs_key_vignette : @ecs.ComponentKey[Vignette] = @ecs.register_component(
  debug_name="render3d.vignette",
)

///|
pub impl @ecs.Component for Vignette with component() {
  ecs_key_vignette
}

///|
pub struct VignetteUniform {
  intensity : Float
  radius : Float
  smoothness : Float
  roundness : Float
  center : @math.Vec2
  edge_compensation : Float
  color : @color.Color
} derive(ToJson, FromJson)

///|
pub fn VignetteUniform::from_settings(settings : Vignette) -> VignetteUniform {
  VignetteUniform::{
    intensity: settings.intensity,
    radius: settings.radius,
    smoothness: settings.smoothness,
    roundness: settings.roundness,
    center: settings.center,
    edge_compensation: settings.edge_compensation,
    color: settings.color,
  }
}

///|
pub fn vignette_screen_centered(settings : Vignette) -> Bool {
  (settings.center.x - 0.5F).abs() <= 0.000001F &&
  (settings.center.y - 0.5F).abs() <= 0.000001F
}
