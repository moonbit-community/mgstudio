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
// Bevy source: `bevy/crates/bevy_render/src/view/mod.rs::ColorGrading*`.

///|
/// Midtone range controls aligned with Bevy's `Range<f32>`-based surface.
pub(all) struct ColorGradingRange {
  mut start : Float
  mut end_ : Float
} derive(ToJson, FromJson)

///|
pub fn ColorGradingRange::ColorGradingRange() -> ColorGradingRange {
  ColorGradingRange::{ start: 0.2F, end_: 0.7F }
}

///|
fn color_grading_range_copy(value : ColorGradingRange) -> ColorGradingRange {
  let out = ColorGradingRange::ColorGradingRange()
  out.start = value.start
  out.end_ = value.end_
  out
}

///|
/// Global color-grading controls aligned with Bevy's `ColorGradingGlobal`.
pub(all) struct ColorGradingGlobal {
  mut exposure : Float
  mut temperature : Float
  mut tint : Float
  mut hue : Float
  mut post_saturation : Float
  mut midtones_range : ColorGradingRange
} derive(ToJson, FromJson)

///|
pub fn ColorGradingGlobal::ColorGradingGlobal() -> ColorGradingGlobal {
  ColorGradingGlobal::{
    exposure: 0.0F,
    temperature: 0.0F,
    tint: 0.0F,
    hue: 0.0F,
    post_saturation: 1.0F,
    midtones_range: ColorGradingRange::ColorGradingRange(),
  }
}

///|
fn color_grading_global_copy(value : ColorGradingGlobal) -> ColorGradingGlobal {
  let out = ColorGradingGlobal::ColorGradingGlobal()
  out.exposure = value.exposure
  out.temperature = value.temperature
  out.tint = value.tint
  out.hue = value.hue
  out.post_saturation = value.post_saturation
  out.midtones_range = color_grading_range_copy(value.midtones_range)
  out
}

///|
/// Sectional color-grading controls aligned with Bevy's `ColorGradingSection`.
pub(all) struct ColorGradingSection {
  mut saturation : Float
  mut contrast : Float
  mut gamma : Float
  mut gain : Float
  mut lift : Float
} derive(ToJson, FromJson)

///|
pub fn ColorGradingSection::ColorGradingSection() -> ColorGradingSection {
  ColorGradingSection::{
    saturation: 1.0F,
    contrast: 1.0F,
    gamma: 1.0F,
    gain: 1.0F,
    lift: 0.0F,
  }
}

///|
fn color_grading_section_copy(
  value : ColorGradingSection,
) -> ColorGradingSection {
  let out = ColorGradingSection::ColorGradingSection()
  out.saturation = value.saturation
  out.contrast = value.contrast
  out.gamma = value.gamma
  out.gain = value.gain
  out.lift = value.lift
  out
}

///|
/// Camera color grading settings aligned with Bevy's `ColorGrading`.
pub(all) struct ColorGrading {
  mut global : ColorGradingGlobal
  mut shadows : ColorGradingSection
  mut midtones : ColorGradingSection
  mut highlights : ColorGradingSection
} derive(ToJson, FromJson)

///|
pub fn ColorGrading::ColorGrading() -> ColorGrading {
  ColorGrading::{
    global: ColorGradingGlobal::ColorGradingGlobal(),
    shadows: ColorGradingSection::ColorGradingSection(),
    midtones: ColorGradingSection::ColorGradingSection(),
    highlights: ColorGradingSection::ColorGradingSection(),
  }
}

///|
pub fn ColorGrading::with_identical_sections(
  global : ColorGradingGlobal,
  section : ColorGradingSection,
) -> ColorGrading {
  let color_grading = ColorGrading::ColorGrading()
  color_grading.global = color_grading_global_copy(global)
  color_grading.shadows = color_grading_section_copy(section)
  color_grading.midtones = color_grading_section_copy(section)
  color_grading.highlights = color_grading_section_copy(section)
  color_grading
}

///|
pub fn ColorGrading::all_sections(
  self : ColorGrading,
) -> Iter[ColorGradingSection] {
  [self.shadows, self.midtones, self.highlights].iter()
}

///|
pub fn ColorGrading::all_sections_mut(
  self : ColorGrading,
) -> Iter[ColorGradingSection] {
  [self.shadows, self.midtones, self.highlights].iter()
}

///|
pub let ecs_key_color_grading : @ecs.ComponentKey[ColorGrading] = @ecs.register_component(
  debug_name="render.view.color_grading",
)

///|
pub impl @ecs.Component for ColorGrading with fn component() {
  ecs_key_color_grading
}
